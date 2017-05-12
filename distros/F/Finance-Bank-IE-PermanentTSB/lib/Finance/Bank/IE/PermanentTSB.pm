=head1 NAME

Finance::Bank::IE::PermanentTSB - Perl Interface to the PermanentTSB
Open24 homebanking on L<http://www.open24.ie>

=head1 DESCRIPTION

This is a set of functions that can be used in your Perl code to perform
some operations with a Permanent TSB homebanking account.

Features:

=over

=item * B<account(s) balance>: retrieves the balance for all the accounts
you have set up (current account, visa card, etc.) 

=item * B<account(s) statement>: retrieves the
statement for a particular account, in a range of date. 

=item * B<mobile phone top-up> (to be implemented): top up your mobile
phone! 

=item * B<funds transfer> (to be implemented): transfer money between your
accounts or third party accounts. 

=back

=cut

package Finance::Bank::IE::PermanentTSB;

our $VERSION = '0.4';

use strict;
use warnings;
use Data::Dumper;
use WWW::Mechanize;
use HTML::TokeParser;
use Carp qw(croak carp);
use Date::Calc qw(check_date Delta_Days);

use base 'Exporter';
# export by default the check_balance function and the constants
our @EXPORT = qw(check_balance ALL WITHDRAWAL DEPOSIT VISA_ACCOUNT SWITCH_ACCOUNT);
our @EXPORT_OK = qw(mobile_topup account_statement);

my %cached_cfg;
my $agent;
my $lastop = 0;

my $BASEURL = "https://www.open24.ie/";

my $error = 0;

=head1 CONSTANTS

The constants below are used with the account_statement() function:

=over

=item * C<ALL>: shortcut for (WITHDRAWAL and DEPOSIT);

=item * C<WITHDRAWAL>: shows only the WITHDRAWALs;

=item * C<DEPOSIT>: shows only the DEPOSITs;

=item * C<VISA_ACCOUNT>: the account refers to a Visa Card;

=item * C<SWITCH_ACCOUNT>: the account is a normal Current Account;

=back

=cut

# constant to be used with the account_statement() function
use constant {

    # statement types
    ALL            => 0, # prints all the transactions 
                         # (WITHDRAWAL and DEPOSIT)
    WITHDRAWAL     => 1, # shows only the WITHDRAWALs
    DEPOSIT        => 2, # shows only the DEPOSITs

    # account types
    VISA_ACCOUNT   => 'Visa Card', # visa card account
    SWITCH_ACCOUNT => 'Switch Current A/C', # switch current account

};

=head1 METHODS / FUNCTIONS

Every function in this module requires, as the first argument, a reference 
to an hash which contains the configuration:

    my %config = (
        "open24numba" => "your open24 number",
        "password" => "your internet password",
        "pan" => "your personal access number",
        "debug" => 1,
    );

=head2 C<$boolean = login($config_ref)> - B<private>

B<This is a private function used by other function within the module.
You don't need to call it directly from you code!>

This function performs the login. It takes just one required argument,
which is an hash reference for the configuration.
The function returns true (1) if success or undef for any other
state.
If debug => 1 then it will dump the html page on the current working
directory. 
Please be aware that this has a security risk. The information will
persist on your filesystem until you reboot your machine (and /var/tmp
get clean at boot time).

=cut

sub login {
    my $self = shift;
    my $config_ref = shift;
    my $content;

    $config_ref ||= \%cached_cfg;

    my $croak = ($config_ref->{croak} || 1);

    for my $reqfield ("open24numba", "password", "pan") {
        if (! defined( $config_ref->{$reqfield})) {
            if ($croak) {
                carp("$reqfield not there!");
                return undef;
            } else {
                carp("$reqfield not there!");
                return undef;
            }
        }
    }

    if(!defined($agent)) {
        $agent = WWW::Mechanize->new( env_proxy => 1, autocheck => 1,
                                      keep_alive => 10);
        $agent->env_proxy;
        $agent->quiet(0);
        $agent->agent('Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.12) Gecko/20071126 Fedora/1.5.0.12-7.fc6 Firefox/1.5.0.12' );
        my $jar = $agent->cookie_jar();
        $jar->{hide_cookie2} = 1;
        $agent->add_header('Accept' =>
            'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5');
        $agent->add_header('Accept-Language' => 'en-US,en;q=0.5');
        $agent->add_header( 'Accept-Charset' =>
            'ISO-8859-1,utf-8;q=0.7,*;q=0.7' );
        $agent->add_header( 'Accept-Encoding' => 'gzip,deflate' );
    } else {
        # simple check to see if the login is live
        # this based on Waider Finance::Bank::IE::BankOfIreland.pm!
        if ( time - $lastop < 60 ) {
            carp "Last operation 60 seconds ago, reusing old session"
                if $config_ref->{debug};
            $lastop = time;
            return 1;
        }
        my $res = $agent->get( $BASEURL . '/online/Account.aspx' );
        if ( $res->is_success ) {
            $content = $agent->content;
            if($agent->content =~ /ACCOUNT SUMMARY/is) {
                $lastop = time;
                carp "Short-circuit: session still valid"
                    if $config_ref->{debug};
                return 1;
            }
        }
        carp "Session has timed out, redoing login"
            if $config_ref->{debug};
    }

    # retrieve the login page
    my $res = $agent->get($BASEURL . '/online/login.aspx');
    $agent->save_content('./loginpage.html') if $config_ref->{debug};

    # something wrong?
    if(!$res->is_success) {
        carp("Unable to get page!");
        return undef;
    }

    # 2nd agent->content call
    $content = $agent->content;
    if($content =~ /Interruption Page/is) {
        carp "Cannot authenticate on Open24.ie: site mantainance";
        $error = 1;
        return undef;
    }

    # page not found?
    if($content =~ /Page Not Found/is) {
        carp("HTTP ERROR 404: Page Not Found");
        return undef;
    }

    # Login - Step 1 of 2
    $agent->field('txtLogin', $config_ref->{open24numba});
    $agent->field('txtPassword', $config_ref->{password});
    # PermanentTSB website sucks...
    # there's no normal submit button, the "continue" button is a
    # <a href="javascript:__doPostBack('lbtnContinue','')"> link
    # that launches a Javascript function. This function sets
    # the __EVENTTARGET to 'lbtnContinue'. Here we are simulating this
    # bypassing the Javascript code :)
    $agent->field('__EVENTTARGET', 'lbtnContinue');
    $res = $agent->submit();
    # something wrong?
    if(!$res->is_success) {
        carp("Unable to get page!");
        return undef;
    }
    $agent->save_content("./step1_result.html") if $config_ref->{debug};

    # 3rd agent->content call
    $content = $agent->content;
    # Login - Step 2 of 2
    if($content !~ /LOGIN STEP 2 OF 2/is) {
        carp("Problem 1 while authenticating!\nPlease don't retry ".
                "this 3 times in a row or you account will be locked!");
        return undef;
    } else {
        if($content !~ /txtDigit/is) {
            carp("Problem 2 while authenticating!\nPlease don't retry ".
                "this 3 times in a row or you account will be locked!");
            return undef;
        }
        print $content if($config_ref->{debug});
        set_pan_fields($agent, $config_ref);
        $res = $agent->submit();
        $agent->save_content("./step2_pan_result.html") 
            if $config_ref->{debug};
        print $content if($config_ref->{debug});
    }

    return 1;
   
}

=head2 C<set_pan_fields($config_ref)> - B<private>

B<This is a private function used by other function within the module.
You don't need to call it directly from you code!>

This is used for the second step of the login process.
The web interface ask you to insert 3 of the 6 digits that form the PAN
code.
The PAN is a secret code that only the PermanentTSB customer knows.
If your PAN code is 123234 and the web interface is asking for this:

=over

=item Digit no. 2:

=item Digit no. 5:

=item Digit no. 6:

=back

The function will fill out the form providing 2,3,4 respectively.

This function doesn't return anything.

=cut

sub set_pan_fields {

    my $agent = shift;
    my $config_ref = shift;

    # 4th agent->content call
    my $p = HTML::TokeParser->new(\$agent->content());
    # convert the pan string into an array
    my @pan_digits = ();
    my @pan_arr = split('',$config_ref->{pan});
    # look for <span> with ids "lblDigit1", "lblDigit2" and "lblDigit3"
    # and build an array
    # the PAN, Personal Access Number is formed by 6 digits.
    while (my $tok = $p->get_tag("span")){
        if(defined $tok->[1]{id}) {
            if($tok->[1]{id} =~ m/lblDigit[123]/) {
                my $text = $p->get_trimmed_text("/span");
                # normally the webpage shows Digit No. x
                # where x is the position of the digit inside 
                # the PAN number assigne by the bank to the owner of the
                # account
                # here we are building the @pan_digits array
                push @pan_digits, $pan_arr[substr($text,10)-1];
            }
        }
    }
    $agent->field('txtDigitA', $pan_digits[0]);
    $agent->field('txtDigitB', $pan_digits[1]);
    $agent->field('txtDigitC', $pan_digits[2]);
    $agent->field('__EVENTTARGET', 'btnContinue');
}

=head2 C<@accounts_balance = check_balance($config_ref)> - B<public>

This function require the configuration hash reference as argument.
It returns an reference to an array of hashes, one hash for each account. 
In case of error it return undef;
Each hash has these keys:

=over

=item * 'accname': account name, i.e. "Switch Current A/C".

=item * 'accno': account number. An integer representing the last 4 digits of the
account.

=item * 'accbal': account balance. In EURO.

=back

Here is an example:

    $VAR1 = {
            'availbal' => 'euro amount',
            'accno' => '0223',
            'accbal' => 'euro amount',
            'accname' => 'Switch Current A/C'
            };
    $VAR2 = {
            'availbal' => 'euro amount',
            'accno' => '2337',
            'accbal' => 'euro amount',
            'accname' => 'Visa Card'
            };

The array can be printed using, for example, a foreach loop like this
one:

    foreach my $acc (@$balance) {
        printf ("%s ending with %s: %s\n",
            $acc->{'accname'},
            $acc->{'accno'},
            $acc->{'accbal'}
        );
    }

=cut

sub check_balance {

    my $self = shift;
    my $config_ref = shift;
    my $res;

    $config_ref ||= \%cached_cfg;
    my $croak = ($config_ref->{croak} || 1);
 
    $self->login($config_ref) or return undef;

    my $p = HTML::TokeParser->new(\$agent->content());
    my $i = 0;
    my @array;
    my $hash_ref = {};
    while (my $tok = $p->get_tag("td")){
        if(defined $tok->[1]{style}) {
            if($tok->[1]{style} eq 'width:25%;') {
                my $text = $p->get_trimmed_text("/td");
                if($i == 0) {
                    $hash_ref = {};
                    $hash_ref->{'accname'} = $text;
                } 
                if($i == 1) {
                    $hash_ref->{'accno'} = $text;
                }
                if($i == 2) {
                    $hash_ref->{'accbal'} = $text;
                }
                if($i == 3) {
                    $hash_ref->{'availbal'} = $text;
                }
                $i++;
                if($i == 4) {
                    $i = 0;
                    push @array, $hash_ref;
                }
            }
        }
    }

    return \@array;

}

=head2 C<@account_statement = account_statement($config_ref, $acc_type,
$acc_no, $from, $to, [$type])> - B<public>

This function requires 4 mandatory arguments, the 5th is optional.

=over

=item 1. B<$config_ref>: the hash reference to the configuration

=item 2. B<$acc_type>: this is a constant: can be VISA_ACCOUNT or SWITCH_ACCOUNT

=item 3. B<$acc_no>: this is a 4 digits field representing the last 4
digits of the account number (or Visa card number)

=item 4. B<$from>: from date, in format dd/mm/yyyy

=item 5. B<$to>: to date, in format dd/mm/yyyy

=item 6. B<$type> (optional): type of statement (optional). Default: ALL.
It can be WITHDRAWAL, DEPOSIT or ALL.

=back

The function returns an reference to an array of hashes, one hash for each row of the statement.
The array of hashes can be printed using, for example, a foreach loop like 
this one:

    foreach my $row (@$statement) {
        printf("%s | %s | %s | %s \n",
            $row->{date},
            $row->{description},
            $row->{euro_amount},
            $row->{balance});
    }

Undef is returned in case of error;

=cut

sub account_statement {
    
    my ($self, $config_ref, $acc_type, $acc_no, $from, $to, $type) = @_;
    my ($res, @ret_array);

    $config_ref ||= \%cached_cfg;
    my $croak = ($config_ref->{croak} || 1);

    if(defined $acc_type) { 
        if($acc_type ne SWITCH_ACCOUNT and $acc_type ne VISA_ACCOUNT) {
            carp("Account type is invalid");
            return undef;
        }
    } else {
        carp("Account type not defined");
        return undef;
    }

    if(not defined $acc_no) {
        carp("Account number not defined.");
        return undef;
    }

    my $account = $acc_type." - ".$acc_no;

    if(defined $from and defined $to) {

        # $from should be > of $to
        my @d_from = split "/", $from;
        my @d_to   = split "/", $to;
        if (Delta_Days($d_from[0],$d_from[1],$d_from[2],
                       $d_to[0],$d_to[1],$d_to[2]) <= 0) {

            carp("Date range $from -> $to invalid.");
            return undef;

        }

        # check date_from, date_to
        foreach my $date ($from, $to) {
            # date should be in format yyyy/mm/dd
            if(not $date  =~ /^\d{4}\/\d{2}\/\d{2}$/) {
                carp("Date $date should be in format 'yyyy/mm/dd'");
                return undef;
            }
            # date should be valid, this is using Date::Calc->check_date()
            my @d = split "/", $date;
            if (not check_date($d[0],$d[1],$d[2])) {
                carp("Date $date is not valid!");
                return undef;
            }
        }
    } else {
        carp("Date range not defined");
        return undef;
    }

    if(defined $account) {
        if(not $account =~ m/.+ - \d{4}$/) {
            carp("$account is invalid");
            return undef;
        }
    }

    # verify if the account exists inside the homebanking
    my $acc = $self->check_balance($config_ref);
    if(not defined $acc) { return undef; }
    my $found = 0;
    foreach my $c (@$acc) {
        if($account  eq $c->{'accname'}." - ".$c->{'accno'}) {
            $found = 1;
            last;   
        }
    }

    if($found) {

        $self->login($config_ref) or return undef;

        # go to the Statement page
        $res = $agent->get($BASEURL . '/online/Statement.aspx');
        $agent->save_content("./statement_page.html") 
            if $config_ref->{debug};

        $agent->field('ddlAccountName', $account);
        $agent->field('__EVENTTARGET', 'lbtnShow');
        $res = $agent->submit();
        # something wrong?
        if(!$res->is_success) {
            carp("Unable to get page!");
            return undef;
        }
        $agent->save_content("./statement_page2.html") 
            if $config_ref->{debug};

        # fill out the "from" date
        my @d = split "/", $from;
        $agent->field('ddlFromDay', $d[2]);
        $agent->field('ddlFromMonth', $d[1]);
        $agent->field('ddlFromYear', $d[0]);

        # fill out the "to" date
        @d = split "/", $to;
        $agent->field('ddlToDay', $d[2]);
        $agent->field('ddlToMonth', $d[1]);
        $agent->field('ddlToYear', $d[0]);

        if(defined $type) {
            $agent->field('grpTransType', 'rbWithdrawal') 
                if($type == WITHDRAWAL);
            $agent->field('grpTransType', 'rbDeposit') 
                if($type == DEPOSIT);
        }

        $agent->field('__EVENTTARGET', 'lbtnShow');
        $res = $agent->submit();
        # something wrong?
        if(!$res->is_success) {
            carp("Unable to get page!");
            return undef;
        }
        $agent->save_content("./statement_page1.html") 
            if $config_ref->{debug};

        my $content = $agent->content;
        # PermanentTSB doesn't support statements that include data
        # older than 6 months... in this case the interface will reset
        # to the default date range. We just need to print an warning
        # and submit the current form as is
        if($content =~ /YOU HAVE REQUESTED DATA OLDER THAN 6 MONTHS/is) {

            carp("PermanentTSB doesn't support queries older than 6".
                 " months! Resetting to the default date.");
            $agent->field('__EVENTTARGET', 'lbtnShow');
            $res = $agent->submit();
            if(!$res->is_success) {
                carp("Unable to get page!");
                return undef;
            }
            $agent->save_content("./statement_res_after_6months.html")
                if $config_ref->{debug};
        }

        if($content =~ /INCORRECT DATE CRITERIA ENTERED: 'TO DATE' WAS IN THE FUTURE./is) {

            carp("Incorrect date criteria entered: 'to date' was in the".
                 " future! Resetting to the default date. ");
        }
        
        # parse output page clicking "next" button until the
        # button "another statement" is present. all the data must
        # be inserted into an array of hashes.
        # the array should contain an hash per row.
        # every hash contains [date, description, euro_amount, balance]
        my $hash_ref = {};
        my $visa = 0;
        my $page = 1;
        my $i = 1;
        while (1) {
            my $p = HTML::TokeParser->new(\$agent->content());
            while (my $tok = $p->get_tag('table')) {
                if(defined $tok->[1]{id}) {
                    if($tok->[1]{id} eq 'tblTransactions'){
                        while(my $tok2 = $p->get_tag('tr')) {
                            $hash_ref = {};
                            my $text = $p->get_trimmed_text('/tr');
                            #TODO: improve regexp!
                            # this matches the html row
                            # dd/mm/yyyy description [-/+] amount balance [-/+]
                            # example -> 29/09/2008 DUNNES STEPHEN 29/09 - 45.00 25000.00 +
                            if($text =~ /^(\d{2}\/\d{2}\/\d{4}) (.+) ([-\+] [\d\.]+) ([\d\.]+ [-\+])$/) {
                                # this is a normal current account
                                # statement 
                                $hash_ref->{date} = $1;
                                $hash_ref->{description} = $2;
                                $hash_ref->{euro_amount} = $3;
                                $hash_ref->{balance} = $4;
                                $hash_ref->{euro_amount} =~ s/\s//g;
                                if($hash_ref->{balance} =~ /^([\d\.]+) ([-\+])$/) {
                                    if($2 eq '+') {
                                        $hash_ref->{balance} = "+".$1;
                                    }
                                    if($2 eq '-') {
                                        $hash_ref->{balance} = "-".$1;
                                    }
                                }
                                push @ret_array, $hash_ref 
                                    if(($i==1 and $page == 1) or ($i>1 and $page>=1));
                                $i++;
                            }
                            if($text =~ /^(\d{2}\/\d{2}\/\d{4}) (\d{2}\/\d{2}\/\d{4}) (.+) ([-\+] [\d\.]+)$/) {
                                # this is a visa card statement
                                $visa = 1;
                                $hash_ref->{date} = $1;
                                $hash_ref->{description} = $3;
                                $hash_ref->{euro_amount} = $4;
                                $hash_ref->{euro_amount} =~ s/\s//g;
                                push @ret_array, $hash_ref;
                                #    if(($i==1 and $page == 1) or ($i>1 and $page>=1));
                                $i++;
                            }
                        }
                    }
                }
            }
            # if we are at the last page we will find a button called
            # Another Statement, exit from the while loop
            if($agent->content =~ /Another Statement/is) {
                last;
            } else {
                # the "next" buttons have different target names
                # it depdends if we are watching a visa card or a normal
                # current account
                if($visa) {
                    $agent->field('__EVENTTARGET', 'lBtnAnother1');
                } else {
                    $agent->field('__EVENTTARGET', 'lbtnShow');
                }
                $page++;
                $i = 1;
            }
            $res = $agent->submit();
            $agent->save_content("./statement_page".($page-1).".html") 
                if $config_ref->{debug};
            # something wrong?
            if(!$res->is_success) {
                carp("Unable to get page!");
                return undef;
            }
        }

    } else {

        # account doesn't exist in the homebanking interface
        # return undef
        carp("Account $account not found!");
        return undef;

    }

    return \@ret_array;

}

# TODO: implement this
sub funds_transfer {

}

# TODO: implement this
sub mobile_topup {

}

sub logoff {
    my $self = shift;
    my $config_ref = shift;

    if(defined $agent and not $error) {

        my $res = $agent->get($BASEURL . '/online/DoLogOff.aspx');
        $agent->save_content("./logoff.html") if $config_ref->{debug};
        $agent->field('__EVENTTARGET', 'lbtnContinue');
        $agent->submit;
    }
}

END {
    logoff;
}

1;

__END__

=head1 INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:

    WWW::Mechanize
    HTML::TokeParser
    Date::Calc


=head1 MODULE HOMEPAGES

=over

=item * Project homepage on Google code (with SVN repository):

L<http://code.google.com/p/finance-bank-ie-permanenttsb>

=item * Project homepage on CPAN.org:

L<http://search.cpan.org/~pallotron/Finance-Bank-IE-PermanentTSB/>

=back

=head1 SYNOPSIS

    use Finance::Bank::IE::PermanentTSB;

    my %config = (
        "open24numba" => "your open24 number",
        "password" => "your internet password",
        "pan" => "your personal access number",
        "debug" => 1, # <- enable debug messages
        );

    my $balance = Finance::Bank::IE::PermanentTSB->check_balance(\%config);

    if(not defined $balance) {
        print "Error!\n"
        exit;
    }

    foreach my $acc (@$balance) {
        printf ("%s ending with %s: %s\n",
            $acc->{'accname'},
            $acc->{'accno'},
            $acc->{'accbal'}
        );
    }

    my $statement = Finance::Bank::IE::PermanentTSB->account_statement(
        \%config, SWITCH_ACCOUNT, '2667','2008/12/01','2008/12/31');

    if(not defined $statement) {
        print "Error!\n"
        exit;
    }

    foreach my $row (@$statement) {
        printf("%s | %s | %s | %s |\n",
            $row->{date},
            $row->{description},
            $row->{euro_amount},
             $row->{balance}
        );
    }

=head1 SEE ALSO

=over

=item * B<ptsb> - CLI tool to interact with your home banking
L<http://search.cpan.org/~pallotron/Finance-Bank-IE-PermanentTSB/ptsb>

=item * Ronan Waider's C<Finance::Bank::IE::BankOfIreland> -
L<http://search.cpan.org/~waider/Finance-Bank-IE/>

=back

=head1 AUTHOR

Angelo "pallotron" Failla, E<lt>pallotron@freaknet.orgE<gt> -
L<http://www.pallotron.net> - L<http://www.vitadiunsysadmin.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Angelo "pallotron" Failla

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
