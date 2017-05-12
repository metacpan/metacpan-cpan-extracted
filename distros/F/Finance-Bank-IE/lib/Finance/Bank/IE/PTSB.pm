=head1 NAME

Finance::Bank::IE::PTSB - Finance::Bank interface for Permanent TSB (Ireland)

=head1 DESCRIPTION

This module implements the Finance::Bank 'API' for Permanent TSB
(Ireland)'s Open24 online banking service.

=over

=cut
package Finance::Bank::IE::PTSB;

use base qw( Finance::Bank::IE );

our $VERSION = "0.30";

use warnings;
use strict;

use Carp;
use File::Path;

use constant BASEURL => 'https://www.open24.ie/online/';

my %pages = (
             login => {
                       url => 'https://www.open24.ie/online/login.aspx',
                       sentinel => 'LOGIN STEP 1 OF 2',
                      },
             login2 => {
                        url => 'https://www.open24.ie/online/Login2.aspx',
                        sentinel => 'LOGIN STEP 2 OF 2',
                       },
             accounts => {
                          url => 'https://www.open24.ie/online/Account.aspx',
                          sentinel => 'CLICK ACCOUNT NAME FOR A MINI STATEMENT',
                         },
             accountdetails => {
                                url => 'https://www.open24.ie/online/StateMini.aspx?ref=0',
                                sentinel => 'MINI STATEMENT',
                               },
             payandtransfer => {
                                url => "https://www.open24.ie/online/PayAndTransfer.aspx",
                                sentinel => "Payments &amp; Transfers",
                               },
    );

sub _pages {
    return \%pages;
}

sub _submit_first_login_page {
    my $self = shift;
    my $confref = shift||$self->cached_config();

    $self->_add_event_fields();

    return
      $self->_agent()->submit_form( fields => {
                                               txtLogin => $confref->{user},
                                               txtPassword => $confref->{password},
                                               '__EVENTTARGET' => 'lbtnContinue',
                                               '__EVENTARGUMENT' => '',
                                              }
                                  );
}

sub _submit_second_login_page {
    my $self = shift;
    my $confref = shift;

    my @pins = grep /(Digit No. \d+)/, split( /[\r\n]+/, $self->_agent()->content );
    my %submit;
    my @secrets = split( //, $confref->{pin} );
    for my $pin ( @pins ) {
        my ( $digit, $field ) = $pin =~
          m{Digit No. (\d+).*input name="(.*?)"};
        my $secret = $secrets[$digit - 1];
        $submit{$field} = $secret;
    }
    $submit{'__EVENTTARGET'} = 'btnContinue';
    $submit{'__EVENTARGUMENT'} = '';
    $self->_add_event_fields();
    return $self->_agent()->submit_form( fields => \%submit );
}

=item * check_balance( [config] )

 Check the balances on all accounts. Optional config hashref.

=cut

sub check_balance {
    my $self = shift;
    my $confref = shift;

    $confref ||= $self->cached_config();
    my $res = $self->_get( $pages{accounts}->{url}, $confref );

    return unless $res;

    # find table class="statement"
    # first is headers (account name, number-ending-with, balance, available
    # each subsequent one is an account
    my @headers;
    my @accounts;
    my $parser = new HTML::TokeParser( \$res );
    while( my $tag = $parser->get_tag( "table" )) {
        next unless $self->_streq( $tag->[1]{class}, "statement" );

        my @account;
        while( $tag = $parser->get_tag( "th", "td", "/tr", "/table" )) {
            last if $tag->[0] eq "/table";
            if ( $tag->[0] =~ /^t[hd]$/ ) {
                my $closer = "/" . $tag->[0];
                my $text = $parser->get_trimmed_text( $closer );
                if ( $tag->[0] eq "th" ) {
                    push @headers, $text;
                } else {
                    push @account, $text;
                }
            } else { # ( $tag->[0] eq "/tr" ) {
                if ( @account ) {
                    push @accounts, [ @account ];
                    @account = ();
                }
            }
        }
    }

    # match headers to data
    my @return;
    for my $account ( @accounts ) {
        my %account;

        for my $header ( @headers ) {
            my $data = shift @{$account};

            if ( $header =~ /Account Name/ ) {
                $account{type} = $data;
                $account{nick} = $data;
            } elsif ( $header =~ /Account No\./ ) {
                $account{account_no} = $data;
            } elsif ( $header =~ /Account Balance \((\w+)\)/ ) {
                $account{currency} = $1;
                $account{balance} = $data;
            }
        }
        # prune stuff we can't identify
        next if !defined( $account{balance} );
        push @return, bless \%account, "Finance::Bank::IE::PTSB::Account";
    }

    return @return;
}

=item * account_details( $account [, config] )

 Return transaction details from the specified account

=cut

sub account_details {
    my $self = shift;
    my $wanted = shift;
    my $confref = shift;

    my @details;

    $confref ||= $self->cached_config();

    my $res = $self->_get( $pages{accounts}->{url}, $confref );

    return unless $res;
    return unless $wanted;

    # this is pretty brutal
    my @likely = grep {m{(StateMini.aspx\?ref=\d+).*?$wanted}} split( /[\r\n]/, $res );
    if ( scalar( @likely ) == 1 ) {
        my ( $url ) = $likely[0] =~ m/^.*(StateMini[^"]+)".*$/;
        # convert to an absolute URL so that the _get pagelookup works
        my $uri = new_abs URI( $url, $self->_agent()->response()->request->uri());
        $res = $self->_get( $uri->as_string(), $confref );

        # parse!
        # there's a header table which is untagged
        # and then there's this (tblTransactions):
        # <tr>
        #       <td class="Content" align="left" valign="middle" colspan="1" width="18%">DD/MM/YYYY</td><td class="Content" align="left" valign="middle" colspan="1" width="46%">DESC</td><td class="Content" align="right" valign="middle" colspan="1" width="18%">- AMT (withdrawal) or + AMT (deposit)</td><td class="Content" align="right" valign="middle" colspan="1" width="18%">BALANCE +/-</td>
        #   </tr>

        my $parser = new HTML::TokeParser( \$res );
        while( my $tag = $parser->get_tag( "table" )) {
            if ( $self->_streq( $tag->[1]{id}, "tblTransactions" )) {
                $self->_dprintf( "Found transaction table\n" );
                my @fields;
                while( my $tag = $parser->get_tag( "td", "/tr", "/table" )) {
                    if ( $tag->[0] eq "td" ) {
                        push @fields, $parser->get_trimmed_text( "/td" );
                    } elsif ( $tag->[0] eq "/tr" ) {
                        if ( @fields ) { # there are spurious blank lines
                            my ( $dr, $cr ) = ( 0, 0 );
                            if ( $fields[2] =~ /^-/ ) {
                                ( $dr = $fields[2] ) =~ s/^- //;
                            } else {
                                ( $cr = $fields[2] ) =~ s/^\+ //;
                            }

                            my ( $bal, $sign ) = $fields[3] =~ /^(.*) (.)$/;

                            push @details,
                            [
                             $fields[0],
                             $fields[1],
                             $dr,
                             $cr,
                             $sign.$bal,
                             ]
                             ;
                            @fields = ();
                        }
                    } else {
                        last;
                    }
                }
                last;
            }
        }

    } else {
        $self->_dprintf( "Found " . scalar(@likely) . " matches\n" );
        return;
    }

    unshift @details, [ 'Date', 'Desc', 'DR', 'CR', 'Balance' ];

    return @details;
}

=item * $self->_get_payments_page( account [, config ] )

 Get the third-party payments page for account

=cut

sub _get_payments_page {
    my $self = shift;
    my $account_from = shift;
    my $confref = shift;

    return unless $account_from;

    # allow passing in of account objects
    if ( ref $account_from eq "Finance::Bank::IE::PTSB::Account" ) {
        $account_from = $account_from->{nick};
    }

    $confref ||= $self->cached_config();
    my $res = $self->_get( $pages{accounts}->{url}, $confref );

    return unless $res;

    $self->_get( $pages{payandtransfer}->{url} )
      or return 0;
    $self->_save_page();

    if ( $self->_agent()->content() !~ /Payments &amp; Transfers/is ) {
        $self->_dprintf( "PayAndTransfer.aspx doesn't contain sentinel\n" );
        return 0;
    }

    return 1;
}

=item * $self->list_beneficiaries( account )

 List beneficiaries of C<account>

=cut
sub list_beneficiaries {
    my $self = shift;
    my $account_from = shift;
    my $confref = shift;

    return unless $self->_get_payments_page( $account_from, $confref );

    # follow link to 'manage accounts'
    $self->_add_event_fields();
    my $res = $self->_agent()->submit_form(
                                        fields => {
                                                   '__EVENTTARGET' => 'ctl00$cphBody$lbManageMyPayeeAccounts',
                                                   '__EVENTARGUMENT' => '',
                                                  }
                                       );

    $self->_save_page();
    return unless $res->is_success();

    my @beneficiaries;

    for my $ddlPaymentType ( 0..3 ) {
        if ( $ddlPaymentType > 0 ) {
            $self->_add_event_fields();
            $res = $self->_agent()->submit_form(
                                                fields => {
                                                           '__EVENTTARGET' => 'ctl00$cphBody$ddlPaymentType',
                                                           '__EVENTARGUMENT' => '',
                                                           'ctl00$cphBody$ddlPaymentType' => $ddlPaymentType,
                                                          }
                                               );
            $self->_save_page( "ddlPaymentType=$ddlPaymentType" );
            return unless $res->is_success();
        }

        my $page = $self->_agent()->content;
        my $parser = new HTML::TokeParser( \$page );

        my @beneficiary;
        my $found = 0;
        while ( my $tag = $parser->get_tag( "table" )) {
            if ( $self->_streq( $tag->[1]{class}, 'transfereeList' )) {
                $found = 1;
                last;
            }
        }

        # no transferees of this type
        if ( !$found ) {
            $self->_dprintf( "No category $ddlPaymentType beneficiaries found\n" );
            next;
        }

        while ( my $tag = $parser->get_tag( "td", "/tr", "/table" )) {
            last if ( $tag->[0] eq "/table" );
            if ( $tag->[0] eq "/tr" ) {
                if ( @beneficiary ) {
                    push @beneficiaries,
                      bless {
                             type => 'Beneficiary',
                             nick => $beneficiary[0],
                             lastused => $beneficiary[1],
                             ref => $beneficiary[2],
                             source => $beneficiary[3],
                             input => $beneficiary[4],
                             type => $ddlPaymentType,
                             account_no => 'hidden',
                             status => 'Active',
                            }, "Finance::Bank::IE::PTSB::Account";
                    @beneficiary = ();
                    $self->_dprintf( "Found beneficiary " . $beneficiaries[-1]->{nick} . "\n" );
                }
            } else {
                if ( $self->_streq( $tag->[1]{class}, 'transfereeListAction' )) {
                    $tag = $parser->get_tag( "input" );
                    push @beneficiary, $tag->[1]{id};
                } else {
                    push @beneficiary, $parser->get_trimmed_text( "/td" );
                }
            }
        }
    }

    \@beneficiaries;
}

=item * $self->add_beneficiary( $from_account, $to_account_details, $config )

 Add a beneficiary to $from_account.

=cut

sub add_beneficiary {
    my ( $self, $account_from, $to_account_no, $to_nsc, $to_ref, $to_nick,
         $confref ) =
      @_;

    return unless $to_nick;
    return unless $self->_get_payments_page( $account_from, $confref );

    # Create a new Third Party Transfer
    $self->_agent()->follow_link( text => 'Create a new Third Party Transfer' );
    $self->_save_page();

    return unless $self->_agent()->content() =~
      /CREATE A NEW THIRD PARTY TRANSFER/is;

    $self->_add_event_fields();
    $self->_agent()->submit_form(
                                 fields => {
                                            txtSortCode => $to_nsc,
                                            txtAccountCode => $to_account_no,
                                            txtBillRef => $to_ref,
                                            txtBillName => $to_nick,
                                            # if you have multiple accounts, ddlAccounts probably needs setting. Option value = NSC+Account_no!
                                            '__EVENTTARGET' => 'lbtnContinue',
                                            '__EVENTARGUMENT' => '',
                                           },
                                );
    $self->_save_page();

    return unless $self->_agent()->content() =~
      /CREATE A NEW THIRD PARTY TRANSFER.*STEP 2/si;

    $self->_add_event_fields();
    $self->_agent()->submit_form(
                                 fields => {
                                            'txtSMSCode' => '11111',
                                            '__EVENTTARGET' => 'lbtnContinue',
                                            '__EVENTARGUMENT' => '',
                                           },
                                );

    return unless $self->_agent()->content() =~
      /CREATE A NEW THIRD PARTY TRANSFER.*STEP 3/si;

    return 1;
}

=item * $receipt = $self->funds_transfer( $from, $to, $amt )

 Transfer C<$amt> from C<$from> to C<$to>. C<$from> has to match one
 of your account nicknames; C<$to> has to match a configured
 beneficiary.

=cut

sub funds_transfer {
    my $self = shift;
    my $account_from = shift;
    my $account_to = shift;
    my $amount = shift;
    my $confref = shift;

    # allow passing account object as destination. source is handled
    # by list_beneficiaries.
    if ( ref $account_to eq __PACKAGE__ . "::Account" ) {
        $account_to = $account_to->{nick};
    }

    $self->_dprintf( " funds_transfer: listing beneficiaries\n" );
    my $beneficiaries = $self->list_beneficiaries( $account_from, $confref );

    my $found;
    for my $beneficiary ( @{$beneficiaries}) {
        if ( $beneficiary->{ref} eq $account_to or
             $beneficiary->{nick} eq $account_to ) {
            if ( $found ) {
                $found = "ambiguous";
                last;
            }
            $found = $beneficiary;
        }
    }

    my $receipt;
    if ( !$found ) {
        $self->_dprintf( "no beneficiaries found for specified account" );
    } elsif ( ref $found ne "Finance::Bank::IE::PTSB::Account" ) {
        $self->_dprintf( "multiple matching beneficiaries found" );
    } else {
        if ( $found->{status} ne "Active" ) {
            $self->_dprintf( "found an account but it's not active" );
        } else {
            $self->_agent()->submit_form( fields => {
                                                     grpTransOther => $found->{input},
                                                     txtAmount => $amount,
                                                     '__EVENTTARGET' => 'lbtnPay',
                                                     '__EVENTARGUMENT' => '',
                                                    },
                                        );
            $self->_save_page();

            $receipt = $self->_agent()->content();

            if ( $receipt =~ /lbtnConfirm/s ) {
                $self->_agent()->submit_form( fields => {
                                                         '__EVENTTARGET' => 'lbtnConfirm',
                                                         '__EVENTARGUMENT' => '',
                                                        });
                $self->_save_page();
                $receipt = $self->_agent()->content();
                if ( $receipt !~ /successfully processed/si ) {
                    $self->_dprintf( "did not get transaction confirmation" );
                    $receipt = undef;
                }
            } else {
                $self->_dprintf( "did not get confirmation request page" );
                $receipt = undef;
            }
        }
    }

    return $receipt;
}

=item * $scrubbed = $self->_scrub_page( $content )

 Scrub the supplied content for PII.

=cut
sub _scrub_page {
    my ( $self, $content ) = @_;

    # This would be nicer with XPath. Alas, I tried XML::Xpath and the
    # world ended - it wanted to fetch a DTD from the web, which
    # didn't exist, and it took an awfully long time to figure that
    # out.
    my $output = "";
    my $parser = new HTML::TokeParser( \$content );
    while( my $token = $parser->get_token()) {
        my $token_string = $token->[-1];
        if ( $token->[0] eq 'T' ) {
            $token_string = $token->[1];
            if ( $token_string =~ /Your last successful logon/ ) {
                $token_string = "Your last successful logon was on 01 January 1970 at 00:00";
            }
        }

        if ( $token->[0] eq 'S' ) {
            # ASP state
            if ( $token->[1] eq 'input' ) {
                if ( $self->_streq( $token->[2]{name}, "__VIEWSTATE" ) or
                     $self->_streq( $token->[2]{name}, "__EVENTVALIDATION" ) or
                     $self->_streq( $token->[2]{name}, "PtsbCifNumber" ) or
                     $self->_streq( $token->[2]{name}, "PtsbBranchNumber" )
                   ) {
                    $token->[2]{value} = "";
                    $token_string = $self->_rebuild_tag( $token );
                }
            }

            if ( $token->[1] eq 'select' ) {
                if ( $self->_streq( $token->[2]{name}, 'ctl00$cphBody$ddlDestinationAccount' ) or
                   ( $self->_streq( $token->[2]{name}, 'ctl00$cphBody$ddlSourceAccount' ))) {
                    while ( my $account_token = $parser->get_token()) {
                        my $string = $account_token->[0] eq 'T' ? $account_token->[1] : $account_token->[-1];
                        if ( $account_token->[0] eq 'S' and $account_token->[1] eq 'option' ) {
                            my $val = $account_token->[2]{value};
                            if ( $val ne 'Please select' and $val !~ /^\d+$/ ) {
                                $account_token->[2]{value} = "0";
                                $string = $self->_rebuild_tag( $account_token );
                                $val = '0';
                            }
                            if ( $val ne 'Please select' ) {
                                $string .= "Account Type $val - 9999";
                            } else {
                                $string .= $parser->get_trimmed_text();
                            }
                            my $tag = $parser->get_tag( "/option" );
                            $string .= $tag->[-1];

                        }
                        $token_string .= $string;
                        last if ( $account_token->[0] eq 'E' and $account_token->[1] eq 'select' );
                    }
                }
            }

            if ( $token->[1] eq 'table' and $self->_streq( $token->[2]{class}, "transfereeList" )) {
                my $col = 0;
                while ( my $account_token = $parser->get_token()) {
                    my $string = $account_token->[0] eq 'T' ? $account_token->[1] : $account_token->[-1];
                    if ( $account_token->[1] eq 'td' and $account_token->[0] eq 'S' ) {
                        my $replacement = "";
                        if ( $col == 0 ) {
                            $replacement = "Recipient";
                        } elsif ( $col == 1 ) {
                            $replacement = "01/01/1970";
                        } elsif ( $col == 2 ) {
                            $replacement = "Reference";
                        } elsif ( $col == 3 ) {
                            $replacement = "Source A/C";
                        }
                        $string .= $replacement;
                        $parser->get_text();
                        $col++;
                    }
                    if ( $account_token->[0] eq 'E' and $account_token->[1] eq 'tr' ) {
                        $col = 0;
                    }
                    $token_string .= $string;
                    last if ( $account_token->[0] eq 'E' and $account_token->[1] eq 'table' );
                }
            }

            if ( $token->[1] eq 'span' ) {
                if ( $self->_streq( $token->[2]{id}, "lblTransferTo" )) {
                    $token_string .= "Recipient";
                    $parser->get_text();
                } elsif ( $self->_streq( $token->[2]{id}, "lblTranRef" )) {
                    $token_string .= "Reference";
                    $parser->get_text();
                } elsif ( $self->_streq( $token->[2]{id}, "lblFrAcc" )) {
                    $token_string .= "Source A/C";
                    $parser->get_text();
                } elsif ( $self->_streq( $token->[2]{id}, "lblAmount" )) {
                    $token_string .= "9999";
                    $parser->get_text();
                }
            }

            # should possibly do this within table class="statement"
            if ( $token->[1] eq 'a' and
                 defined( $token->[2]{href}) and
                 $token->[2]{href} =~ /^StateMini.aspx/ ) {

                # winging it a little here.
                my @replacements = ( "Account Type",
                                     9999, # account number
                                     99999.99, # balance
                                     99999.99, # balance
                                   );

                while ( my $account_token = $parser->get_token()) {
                    my $string = $account_token->[0] eq 'T' ? $account_token->[1] : $account_token->[-1];
                    if ( $account_token->[0] eq 'E' and $account_token->[1] eq 'tr' ) {
                        $token_string .= $string;
                        last;
                    }
                    if ( $account_token->[0] eq 'T' and $string !~ /^\s+$/ ) {
                        $string = shift @replacements;
                    }
                    if ( $account_token->[0] eq 'S' and
                         defined( $account_token->[2]{title} )) {
                        $account_token->[2]{title} = "";
                        $string = $self->_rebuild_tag( $account_token );
                    }
                    $token_string .= $string;
                }
            }
        }

        $output .= $token_string;
    }

    return $output;
}

sub _add_event_fields {
    my $self = shift;

    # these get added by javascript on the page
    my $form = $self->_agent()->current_form();
    for my $name (qw( __EVENTTARGET __EVENTARGUMENT )) {
        if ( my $input = $form->find_input( $name )) {
            $input->readonly( 0 );
        } else {
            $input = new HTML::Form::Input( type => 'text',
                                            name => $name );
            $input->add_to_form( $form );
        }
    }
}

=back

=cut

package Finance::Bank::IE::PTSB::Account;

no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

1;
