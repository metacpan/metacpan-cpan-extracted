=head1 NAME

Finance::Bank::IE::BankOfIreland - Interface to Bank of Ireland online banking

=head1 SYNOPSIS

 use Finance::Bank::IE::BankOfIreland;

 # config
 my $conf = { user => '', pin => '', contact => '', dob => '' };

 # get balance from all accounts
 my @accounts = Finance::Bank::IE::BankOfIreland->check_balance( $conf );

 # get account transaction details
 my @details = Finance::Bank::IE::BankOfIreland->account_details( $acct );

 # list beneficiaries for an account
 my $bene = Finance::Bank::IE::BankOfIreland->list_beneficiaries( $acct );

 # transfer money to a beneficiary
 my $tx = Finance::Bank::IE::BankOfIreland->funds_transfer( $from, $to, $amt );

=head1 DESCRIPTION

Module to interact with BoI's 365 Online service.

=head1 FUNCTIONS

Note that all functions are set up to act as methods (i.e. they all need to be invoked using F:B:I:B->method()). All functions also take an optional configuration hash as a final parameter.

=over

=cut
package Finance::Bank::IE::BankOfIreland;


use strict;
use warnings;

our $VERSION = "0.30";

use base qw( Finance::Bank::IE );
use POSIX;

# headers for account summary page
use constant {
    BALANCE  => "Balance Information: Balance",
      ACCTTYPE => "Account Type",
        NICKNAME => "Nickname Information: Nickname",
          CURRENCY => "Currency",
            ACCTNUM  => "Account Number",
        };

# headers for transaction list page
use constant {
    DATE => "Date",
      DETAIL => "Details",
        DEBIT => "Debit",
          CREDIT => "Credit",
            DETBAL => "Balance Information: Balance",
        };

# headers for payments page
use constant {
    BENNAME => 'Beneficiary Name Information: Beneficiary Name',
      BENACCT => 'Account Number',
        BENNSC =>
          'National Sort Code (NSC) Information: National Sort Code (NSC)',
            BENREF => 'Reference Number Information: Reference Number',
              BENDESC =>
                'Beneficiary Description Information: Beneficiary Description',
                  BENSTATUS => 'Status Information: Status',
              };

my $BASEURL = "https://www.365online.com/";

my %pages = (
             login => {
                       url => 'https://www.365online.com/online365/spring/authentication',
                       sentinel => 'Login.*Step 1 of 2',
                      },
             login2 => {
                       url => 'https://www.365online.com/online365/spring/authentication',
                       sentinel => 'Login.*Step 2 of 2',
                      },
             accessDenied => {
                              url => 'https://www.365online.com/online365/spring/accessDenied',
                              sentinel => '<h1>Access Denied',
                             },
             badcreds => {
                          url => 'https://www.365online.com/online365/spring/authentication',
                          sentinel => 'Your login details are incorrect, please try again',
                         },
             expired => {
                         url => 'https://www.365online.com/online365/spring/sessionExpired',
                         sentinel => 'The system has logged you out',
                        },
             # generic interstitial
             interstitial => {
                              url => 'not important',
                              sentinel => 'Continue to 365 Home',
                             },
             termsandconds => {
                               url => 'not important',
                               sentinel => '<h1>Terms and Conditions</h1>',
                              },
             accounts => {
                          url => 'https://www.365online.com/online365/spring/accountSummary?execution=e2s1',
                          sentinel => '>Your Accounts\b',
                         },
             statements => {
                            url => 'https://www.365online.com/online365/spring/statements?execution=e1s1',
                            sentinel => 'Recent Transactions',
                           },
             moneyTransfer => {
                               url => 'https://www.365online.com/online365/spring/moneyTransfer?execution=e7s1',
                               sentinel => 'Money Transfer</h1>',
                              },
             manageaccounts => {
                                url => 'https://www.365online.com/online365/spring/manageAccounts?execution=e5s1',
                                sentinel => 'Manage Your Accounts</title>',
                               },
             managepayees => {
                              url => 'https://www.365online.com/online365/spring/managePayees?execution=e6s1',
                              sentinel => 'Manage Payees</title>',
                             },
            );

use HTML::TokeParser;
use Carp;
use Date::Parse;
use POSIX;
use File::Path;
use Data::Dumper;

sub _pages {
    return \%pages;
}

# =item * login_dance( $config );

# Logs in or refreshes the current session. The config parameter is a hash reference which is cached the first time it is used, so can be omitted thereafter. The contents of the hash are the login details for your 365 Online account:

# =over

# =item * user: your six-digit BoI user ID

# =item * pin: your six-digit PIN

# =item * contact: the last four digits of your contact number

# =item * dob: your date of birth in DD/MM/YYYY format

# =back

# No validation is currently done on the format of the config items. The function returns true or false. Note that this function should rarely need to be directly used as it's invoked by the other functions as a first step.

# =cut
# sub login_dance {
#     my $self = shift;
#     my $confref = shift;

#     confess();

#     $confref ||= $self->cached_config();

#     for my $required ( "user", "pin", "contact", "dob" ) {
#         if ( !defined( $confref->{$required} )) {
#             $self->_dprintf( "$required not specified\n" );
#             return;
#         }
#     }

#     $self->cached_config( $confref );

#     if ( !$self->_get( $pages{login}->{url}, $confref )) {
#         croak( "Failed to get login page." );
#     }

#     # TODO check sentinel & form name
#     my $form = $self->_agent()->current_form();
#     $self->_agent()->field( "form:userId", $confref->{user} );
#     $self->_set_creds_fields( $confref );
#     my $res = $self->_agent()->submit_form();
#     $self->_identify_page();
#     $self->_save_page();

#     if ( !$res->is_success ) {
#         croak( "Failed to submit login form" );
#     }

#     $self->_set_creds_fields( $confref );
#     $res = $self->_agent()->submit_form();
#     $self->_identify_page();
#     $self->_save_page();

#     if ( !$res->is_success ) {
#         croak( "Failed to submit login form" );
#     }

#     if ( $res->content() =~ /$pages{badcreds}->{sentinel}/s ) {
#         croak "Your login details are incorrect";
#     } elsif ( $res->content() =~ /$pages{login}->{sentinel}/s ) {
#         croak( "Looping, bailing out to avoid lockout\n" );
#     }

#     # one other fail string: You did not enter the 3 requested digits of your PIN!

#     # GAH INTERSTITIALS
#     if ( $self->_identify_page eq 'interstitial' ) {
#         $self->_agent()->field( "form:continue", "form:continue" );
#         $res = $self->_agent()->submit_form();
#         $self->_identify_page();
#         $self->_save_page();
#     }

#     return 1;
# }

sub _submit_first_login_page {
    my $self = shift;
    my $confref = shift||$self->cached_config();

    my $form = $self->_agent()->current_form();
    $self->_agent()->field( "form:userId", $confref->{user} );
    $self->_set_creds_fields( $confref );
    return $self->_agent()->submit_form();
}

sub _submit_second_login_page {
    my $self = shift;
    my $confref = shift||$self->cached_config();

    $self->_set_creds_fields( $confref );
    return $self->_agent()->submit_form();
}

=item * $self->check_balance()

Fetch all account balances from the account summary page. Returns an array of Finance::Bank::IE::BankOfIreland::Account objects.

=cut

sub check_balance {
    my $self = shift;
    my $confref = shift;

    $confref ||= $self->cached_config();
    $self->_get( $self->_pages->{accounts}->{url}, $confref );

    if ( $self->_agent()->content() !~ /$pages{accounts}->{sentinel}/s ) {
        croak( "Failed to get account summary page" );
    }

    my $summary = $self->_agent()->content;
    my $parser = new HTML::TokeParser( \$summary );

    my ( @accounts, %account, @headings );
    my ( $getheadings, $col ) = ( 1, 0 );

    while ( my $tag = $parser->get_tag( "span" )) {
        if ( $self->_streq( $tag->[1]{class}, "acc_name" )) {
            # ugh. <span foo />accountname
            while ( my $token = $parser->get_token()) {
                if ( $token->[0] eq 'T' ) {
                    ( $account{+NICKNAME} = $token->[1] ) =~ s/\s+$//;
                    last;
                }
            }
            $account{+ACCTNUM} = $parser->get_trimmed_text( "/span");
        } elsif ( $self->_streq( $tag->[1]{class}, "acc_value" )) {
            $account{+CURRENCY} = $parser->get_trimmed_text( "/span" );
            $parser->get_tag( "span" );
            $account{+BALANCE} = $parser->get_trimmed_text;

            push @accounts,
              bless {
                     type => delete $account{+ACCTTYPE},
                     nick => delete $account{+NICKNAME},
                     account_no => delete $account{+ACCTNUM},
                     currency => delete $account{+CURRENCY},
                     balance => delete $account{+BALANCE},
                    }, "Finance::Bank::IE::BankOfIreland::Account";
        }
    }

    if ( !@accounts ) {
        $self->_dprintf( "No accounts found\n" );
    }

    return @accounts;
}

=item * $self->account_details( account [,config] )

 Return transaction details from the specified account

=cut
sub account_details {
    my $self = shift;
    my $account = shift;
    my $confref = shift;
    my ( @headings, @details );

    $confref ||= $self->cached_config();

    my $content = $self->_get( $pages{statements}->{url}, $confref );

    if ( !$content) {
        croak( "Failed to get account summary page" );
    }

    # account selector
    my $error = 'account not found';
    my $parser = new HTML::TokeParser( \$content );

    while ( my $tag = $parser->get_tag( "select" )) {
        if ( $self->_streq( "form:selectAccountDropDown", $tag->[1]{id})) {
            while ( my $optiontag = $parser->get_tag("/select", "option")) {
                last if $optiontag->[0] eq '/select';
                my $accountname = $parser->get_trimmed_text( "/option" );
                next if $accountname =~ /Select Account/;
                my ( $nick, $number ) = split( /\s*~\s*/, $accountname );
                $self->_dprintf( "Found account '$nick' = '$number'\n" );
                if ( $account eq $nick or $account eq $number or
                    $account eq '~'.$number ) {
                    if ( $self->_streq( $optiontag->[1]{selected}, "selected" )) {
                        $error = 'ok';
                    } else {
                        $error = 'account not selected';
                    }
                    last;
                }
            }
            last;
        }
    }

    if ( $error ne 'ok' ) {
        croak( "Account '$account': " . $error );
    }

    # now pull out the stuff we were looking for
    while ( my $tag = $parser->get_tag( "table" )) {
        if ( $self->_streq( "form:transactionDataTable" ), $tag->[1]{id}) {
            while ( my $row = $parser->get_tag( "/table", "tr" )) {
                last if $row->[0] eq '/table';
                my @row;
                while ( my $col = $parser->get_tag( "/tr", "th", "td" )) {
                    last if $col->[0] eq '/tr';
                    push @row, $parser->get_trimmed_text( "/" . $col->[0] );
                }
                if ( !@headings ) {
                    # Date, Details, Debit, Credit, Balance
                    @headings = @row;
                } else {
                    # fixups of raw data:
                    my ( $date, $details, $dr, $cr, $balance ) = @row;
                    if ( !$date ) {
                        if ( @details ) {
                            $date = $details[-1]->[0];
                        } else {
                            $date = 0; # can't be helped
                        }
                    } else {
                        my ( $d, $m, $y ) = split( "/", $date );
                        # strftime ilk
                        $date = strftime( "%s", 0, 0, 0, $d, $m - 1, $y - 1900, );
                    }

                    $dr ||= 0.0;
                    $cr ||= 0.0;

                    $balance ||= ( @details ? $details[-1]->[-1] : 0 ) - $dr + $cr;
                    push @details, [ $date, $details, $dr, $cr, $balance ];
                }
            }
            last;
        }
    }

    return \@headings, @details;
}

=item * $self->list_beneficiaries( account )

 List beneficiaries of C<account>

=cut
sub list_beneficiaries {
    my $self = shift;
    my $account_from = shift;
    my $confref = shift;

    $self->_dprintf( "Fetching beneficiaries for %s\n", ref $account_from ? $account_from->{nick} : $account_from );

    $confref ||= $self->cached_config();

    # allow passing in of account objects
    if ( ref $account_from eq "Finance::Bank::IE::BankOfIreland::Account" ) {
        $account_from = $account_from->{nick};
    }

    my $res =
      $self->_get( $pages{manageaccounts}->{url}, $confref );
    $self->_save_page();
    if ( !$res ) {
        croak( "Failed to get " . $pages{manageaccounts}->{url} );
    }

    # now we have to pretend to be javascript again.
    $self->_agent()->field( "form:managePayees", "form:managePayees" );
    $res = $self->_agent()->submit_form();
    $self->_identify_page();
    $self->_save_page();

    if ( !$res->is_success ) {
        croak( "Failed to submit manageAccounts form" );
    }

    # it would be nice to have more payees to test this with
    my $content = $self->_agent()->content;
    my $parser = new HTML::TokeParser( \$content );
    my @beneficiaries;
    while ( my $tag = $parser->get_tag( "table" )) {
        next unless $tag->[1]{id};
        next unless $tag->[1]{id} =~ /payee/i;
        my %beneficiary;
        my @cols = qw( desc account_no nsc ref currency nick limit );
        while ( $tag = $parser->get_tag( "td", "/tr", "/table" )) {
            if ( $tag->[0] eq "/table" ) {
                last;
            }
            if ( $tag->[0] eq "/tr" and %beneficiary ) {
                # I don't currently know what an inactive beneficiary
                # looks like, so I'm flagging them all as Active.
                push @beneficiaries, bless {
                                            type => 'Beneficiary',
                                            status => 'Active',
                                           }, "Finance::Bank::IE::BankOfIreland::Account";
                for my $k ( keys %beneficiary ) {
                    $beneficiaries[-1]->{$k} = $beneficiary{$k};
                }

                %beneficiary = ();
            } else {
                while ( my $token = $parser->get_token()) {
                    if ( $token->[0] eq "E" and $token->[1] eq "td" ) {
                        last;
                    } elsif ( $token->[0] eq "S" and $token->[1] eq "label" ) {
                        $beneficiary{$cols[0]} = $parser->get_trimmed_text( "/label" );
                    } elsif ( $token->[0] eq "T" ) {
                        my $idx = scalar( keys %beneficiary ) - 1;
                        $beneficiary{$cols[$idx]} = $token->[1];
                    } elsif ( $token->[0] eq "S" and $token->[1] eq 'input' ) {
                        $beneficiary{input} = [ @{$token} ];
                    }
                }
            }
        }
    }

    \@beneficiaries;
}

=item * $self->funds_transfer( from, to, amount [,config] )

 Transfer C<amount> from C<from> to C<to>, optionally using C<config> as the config data.

=cut

sub funds_transfer {
    my $self = shift;
    my $account_from = shift;
    my $account_to = shift;
    my $amount = shift;
    my $confref = shift;

    $self->_dprintf( "Funds transfer of %s from %s to %s\n", $amount,
                     ref $account_from ? $account_from->{nick} : $account_from,
                     ref $account_to ? $account_to->{nick} : $account_to );

    $confref ||= $self->cached_config();

    # allow passing in of account objects
    if ( ref $account_from eq "Finance::Bank::IE::BankOfIreland::Account" ) {
        $account_from = $account_from->{nick};
    }

    if ( ref $account_to eq "Finance::Bank::IE::BankOfIreland::Account" ) {
        $account_to = $account_to->{nick};
    }

    my $beneficiaries = $self->list_beneficiaries( $account_from, $confref );

    my $acct;
    for my $bene ( @{$beneficiaries} ) {
        if ((( $bene->{account_no} ||'' ) eq $account_to ) or
            (( $bene->{nick} ||'' ) eq $account_to )) {
            croak "Ambiguous destination account $account_to"
              if $acct;
            $acct = $bene;
        }
    }

    if ( !defined( $acct )) {
        croak( "Unable to find $account_to in list of accounts" );
    }

    if ( $acct->{status} eq "Inactive" ) {
        croak( "Inactive beneficiary" );
    }

    # now get the funds transfer page
    my $res = $self->_agent()->get( $pages{moneyTransfer}->{url} );
    $self->_save_page();
    if ( !$res->is_success ) {
        croak( "Failed to get funds transfer page." );
    }

    # fiddly bit. there are different types of transfer, and I don't
    # have test accounts to support all of them.
    # billPayment, ownAccountPayment, domesticPayment, internationalPayment
    # So, testing the bit I can test.
    $self->_agent()->field( "form:domesticPayment", "form:domesticPayment" );
    $res = $self->_agent()->submit_form();
    $self->_identify_page();
    $self->_save_page();
    croak( 'not on Origin page' ) unless $self->_agent()->content() =~ m@Domestic Transfer</h1>@;

    # select the origin account:
    # select > option > id='form:dt_select_acc_from'
    # defaults to the right account for me...

    # click on the continue button
    $res = $self->_agent()->submit_form( button => 'form:formActions:continue' );
    $self->_identify_page();
    $self->_save_page();
    croak( 'not on Details page' ) unless $self->_agent()->content() =~ m@Enter Details</h2>@;

    # on this page, there's a single_line_div containing the account name/no
    # then another one containing the available funds
    # format is <div class="single_line_div"><span class="show_label long_label">label</span><span class="pad_txt"></span>data</span</div>
    my $account_selector = '';
    my $content = $self->_agent()->content();
    my $parser = new HTML::TokeParser( \$content );
    my @valid_accounts;
    while ( my $selector = $parser->get_tag( "select" )) {
        if ( $self->_streq( $selector->[1]{id}, 'form:selectPayeeDomestic')) {
            while ( my $option = $parser->get_tag( "option", "/select" )) {
                last if $option->[0] eq '/select';
                my $accountname = $parser->get_trimmed_text( "/option" );
                next if $accountname =~ /Select Payee/;
                push @valid_accounts, $accountname;

                my ( $nick, $number ) = split( /\s*~\s*/, $accountname );
                if ( $account_to eq $nick or $account_to eq $number or
                     substr( $account_to, -4 ) eq $number ) {
                    $account_selector = $option->[1]{value};
                    last;
                }
            }
            last;
        }
    }

    if ( $account_selector eq '' ) {
        croak( sprintf( "Couldn't find payee '%s', valid accounts are '%s'", $account_to, join( "', '", @valid_accounts )));
    }

    $res = $self->_agent()->submit_form(
                                        fields => {
                                                   'form:selectPayeeDomestic' => $account_selector,
                                                   'form:amount' => $amount,
                                                  },
                                        button => 'form:formActions:continue',
                                       );
    $self->_identify_page();
    # also, the destination account number appears in full on this page.
    $self->_save_page();
    croak( 'not on PIN page' ) unless $self->_agent()->content() =~ m@Enter your PIN</h2>@;

    $self->_set_creds_fields( $confref );

    $res = $self->_agent()->submit_form( button => 'form:formActions:continue' );
    $self->_identify_page();
    $self->_save_page();
    croak( 'not on Confirmation page' ) unless $self->_agent()->content() =~ m@Confirmation</h2>@s;

    # return the 'receipt'
    # extraction:
    # <h2 class="section_title">Confirmation</h2>
    # <p><span class="highlight"><strong>eur AMOUNT
    # </strong></span>
    # has been paid from <span class="highlight"><strong>SOURCE</strong></span> to
    # <span class="highlight"><strong>DEST</strong></span>
    # </p>
    return $self->_agent()->content;
}


=item * $self->_set_creds_fields( $config )

  Parse the last received page for credentials entry fields, and populate them with the data from C<$config>. Also injects the missing 'form:continue' hidden field.

=cut
sub _set_creds_fields {
    my $self = shift;
    my $confref = shift;

    my $form = $self->_agent()->current_form();
    # avoid having to restructure old config
    my @dob = split( '/', $confref->{dob} );
    my %fieldmapping = (
                        'form:dateOfBirth_year' => $dob[2],
                        'form:dateOfBirth_month' => $dob[1],
                        'form:dateOfBirth_date' => $dob[0],
                        'form:phoneNumber' => $confref->{contact},
                       );
    for my $i ( 1..6 ) {
        $fieldmapping{"form:security_number_digit$i"} = substr( $confref->{pin}, $i - 1, 1 );
        $fieldmapping{"form:pinFragment:security_number_digit$i"} = substr( $confref->{pin}, $i - 1, 1 );
    }

    for my $id ( keys %fieldmapping ) {
        my $field = $form->find_input( $id );
        if ( $field ) {
            $self->_agent()->field( $id, $fieldmapping{$id});
        }
    }

    # LOSERS.
    my $input = new HTML::Form::Input( type => 'hidden',
                                       name => 'form:continue',
                                       value => 'form:continue',
                                     );
    $input->add_to_form( $form );
}

=item * $scrubbed = $self->_scrub_page( $content )

 Scrub the supplied content for PII.

=cut
sub _scrub_page {
    my ( $self, $content ) = @_;

    my $output = "";

    my $parser = new HTML::TokeParser( \$content );
    my $page = $self->_identify_page( $content );
    my $payee_acct = 0;

    while ( my $token = $parser->get_token()) {
        my $token_string = $token->[0] eq 'T' ? $token->[1] : $token->[-1];

        if ( $token->[0] eq 'T') {
            $token_string =~ s@(Last Login.*?)\d+/\d+/\d+ \d+:\d+@${1}01/01/1970 00:00@;
            $token_string =~ s@(Last Payee Added.*?)\d+/\d+/\d+@${1}01/01/1970@;
        }

        if ( $token->[0] eq 'S' ) {
            if ( $token->[1] eq 'h2' ) {
                my $tpage = "";
                while ( my $h2_token = $parser->get_token()) {
                    my $h2_string = $h2_token->[0] eq 'T' ? $h2_token->[1] : $h2_token->[-1];
                    $token_string .= $h2_string;
                    if ( $h2_token->[0] eq 'E' and $h2_token->[1] eq 'h2' ) {
                        last;
                    }
                    $tpage .= $h2_string;
                }
                if ( $tpage ne $page ) {
                    $page = $tpage;
                }

                # XXX these should use sentinels from %pages
                if ( $page eq 'Enter your PIN' or $page eq 'Confirmation' ) {
                    # first para contains all the PII, so just nuke it outright
                    $parser->get_tag( "/p" );
                } elsif ( $page eq 'Enter Details' ) {
                    # now process until we get past the PII
                    my @replacements = ( 'Nickname ~ 9999', 'eur 99.99' );
                    while ( @replacements and my $innertoken = $parser->get_token()) {
                        my $itstring = $innertoken->[0] eq 'T' ? $innertoken->[1] : $innertoken->[-1];
                        if ( $innertoken->[0] eq 'S' and
                             $innertoken->[1] eq 'span' and 
                             $self->_streq( $innertoken->[2]{class},
                                            'pad_txt' )) {
                            my $tag = $parser->get_tag( '/span' );
                            $itstring .= $tag->[-1];
                            $parser->get_trimmed_text( '/div' );
                            $itstring .= shift @replacements;
                            $itstring .= "</div>";
                        }
                        $token_string .= $itstring;
                    }
                }
            }

            if ( $token->[1] eq 'span' ) {
                if (( $token->[2]{id}||"") =~ /:detailsColumn$/ or
                    ( $self->_streq( $token->[2]{class}, "acc_name" ))) {
                    while ( my $account_token = $parser->get_token()) {
                        if ( $account_token->[0] eq 'T' ) {
                            $token_string .= "Nickname";
                            last;
                        } else {
                            $token_string .= $account_token->[-1];
                        }
                    }
                    $parser->get_trimmed_text( "/span");
                    while ( my $account_token = $parser->get_token()) {
                        if ( $account_token->[0] eq 'T' ) {
                            if ( $account_token->[1] =~ /^(~ *)/ ) {
                                $token_string .= $1;
                            }
                            $token_string .= '9999';
                            last;
                        } else {
                            $token_string .= $account_token->[-1];
                        }
                    }
                    $parser->get_trimmed_text( "/span" );
                }
            } elsif ( $self->_streq( $token->[2]{class}, "acc_value" )) {
                # a bit more destructive than I'd like...
                $token_string .= "<span class=\"acc_value\"><span class=\"blue\">" . $parser->get_trimmed_text( "/span" ) . "</span>";
                $token_string .= "<span id=\"form:retailAccountSummarySubView0:balance\">";
                $parser->get_tag( "span" );
                $token_string .= "99999.99";
                $parser->get_trimmed_text;
                $token_string .= "</span>";
            }

            # manage payees
            if ( $token->[1] eq 'td' and
                 $token->[2]{id} and
                 $token->[2]{id} =~ /payee/i ) {
                if ( $token->[2]{id} =~ /id109/ ) {
                    $token_string .= "reference $payee_acct";
                } elsif ( $token->[2]{id} =~ /id105/ ) {
                    $token_string .= "account_no $payee_acct";
                } elsif ( $token->[2]{id} =~ /id113/ ) {
                    $token_string .= "nick $payee_acct";
                } elsif ( $token->[2]{id} =~ /id107/) {
                    $token_string .= "nsc $payee_acct";
                } elsif ( $token->[2]{id} =~ /id111/) {
                    $token_string .= "currency $payee_acct";
                } elsif ( $token->[2]{id} =~ /radiobutton/i ) {
                    $payee_acct++;
                    $token_string .= "<input name='input' value='$payee_acct'><label>&#160;LABEL</label>";
                }
                $parser->get_tag( "/td" );
                $token_string .= "</td>";
            }

            if ( $token->[1] eq 'select' and
                 ( $self->_streq( $token->[2]{class}, "acc_select" ) or
                   ( $self->_streq( $token->[2]{id}, "form:selectAccountDropDown")))) {
                my $added_nickname = 0;

                while ( my $account_token = $parser->get_token()) {
                    my $string = $account_token->[0] eq 'T' ? $account_token->[1] : $account_token->[-1];
                    if ( $account_token->[0] eq 'S' and $account_token->[1] eq 'option' ) {
                        my $val = $account_token->[2]{value};
                        if ( $val ne 'From Account..' and
                             $val ne 'defaultItem' and
                             $val !~ /^\d+$/ ) {
                            $account_token->[2]{value} = "0";
                            $string = $self->_rebuild_tag( $account_token );
                            $val = '0';
                        }
                        if ( $val ne 'From Account..' and
                             $val ne 'defaultItem' ) {
                            $added_nickname++;
                            if ( $added_nickname == 1 ) {
                                $string .= "Nickname ~ 9999";
                            } else {
                                $string .= "nick $added_nickname ~ $val";
                            }
                        } else {
                            $string .= $parser->get_trimmed_text();
                        }
                        my $tag = $parser->get_tag( "/option" );
                        if ( $tag ) {
                            $string .= $tag->[-1];
                        }
                    }
                    $token_string .= $string;
                    last if ( $account_token->[0] eq 'E' and $account_token->[1] eq 'select' );
                }
            }
        }

        $output .= $token_string;
    }

    return $output;
}

=back

=cut

package Finance::Bank::IE::BankOfIreland::Account;

# magic (pulled directly from other code, which I now understand)
no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

1;
