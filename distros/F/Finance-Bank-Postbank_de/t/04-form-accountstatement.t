#!/usr/bin/perl -w
use strict;
use FindBin;

require './t/test_form.pm';

use vars qw(@fields);
BEGIN {
  @fields = ('selectForm:kontoauswahl', 'selectForm:kontoauswahlButton');
};
use Test::More tests => 8;

use_ok("Finance::Bank::Postbank_de");

# Check that we have SSL installed :
SKIP: {

  skip "Need SSL capability to access the website", 5 + scalar @fields
    unless LWP::Protocol::implementor('https');

  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => '11111',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );

  # Get the login page:
  my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

  # Check that we got a wellformed page back
  SKIP: {
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      diag $account->agent->title;
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)", 7;
    };
    skip "Banking is unavailable due to maintenance", 7
      if $account->maintenance;
    $account->agent(undef);
    $status = $account->new_session();

    $status = $account->select_function("accountstatement");
    if ($status != 200) {
      diag $account->agent->res->as_string;
      skip "Couldn't get to account statement (LWP: $status)",7;
    } elsif( $account->maintenance ) {
      skip "Couldn't get to account statement (maintenance)",7;
    }

    form_ok( $account->agent, '' => @fields );
    ok($account->close_session(),"Closed session");
    is($account->agent(),undef,"agent was discarded");

    my $canned_statement = do {local $/ = undef;
                               my $acctname = "$FindBin::Bin/accountstatement.txt";
                               open my $fh, "< $acctname"
                                 or die "Couldn't read $acctname : $!";
                               binmode $fh, ':encoding(CP-1252)';
                               <$fh>};

    eval { require File::Temp; File::Temp->import(); };
    SKIP: {
      skip "Need File::Temp to test download capabilities",4
        if $@;
      my ($fh,$tempname) = File::Temp::tempfile();
      close $fh;
      my $statement = $account->get_account_statement(file => $tempname, past_days => 100);
      is($statement->iban, 'DE31200100209999999999', "Got the correct IBAN");

      my $downloaded_statement = do {local $/ = undef;
                                     open my $fh, "< $tempname"
                                       or die "Couldn't read $tempname : $!";
                                     binmode $fh, ':encoding(CP-1252)';
                                     <$fh>};
      for ($downloaded_statement,$canned_statement) {
        s/\r\n/\n/g;
        s/\t/        /g;
        s/\s*$//mg;
        # Strip out all date references ...
        s/^"\d{2}\.\d{2}\.\d{4}";"\d{2}\.\d{2}\.\d{4}";//gm;
        s/^"\d{2}\.\d{2}\.\d{4}"//gm;

        # Clean out the EURO SIGN that might appear before or after the sign, or the amount
        s!\s*\x{20AC}\s*!!g;
      };
      is_deeply([ split /\n/, $downloaded_statement ],[ split /\n/, $canned_statement ],"Download to file works");
      ok($account->close_session(),"Closed session");
      is($account->agent(),undef,"agent was discarded");

      unlink $tempname
       or diag "Couldn't remove tempfile $tempname : $!";
    };
  };
};
