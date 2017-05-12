#!/usr/bin/perl -w
use strict;
use FindBin;

use Test::More tests => 13;

BEGIN { use_ok("Finance::Bank::Postbank_de"); };

sub save_content {
  my ($account,$name) = @_;
  local *F;
  my $filename = "$0-$name.html";
  open F, "> $filename"
    or diag "Couldn't dump current page to '$filename': $!";
  binmode F;
  print F $account->agent->content;
  close F;
  diag "Current page saved to '$filename'";
};

my @accounts = (
  ['Login with wrong password', Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => 'xxxxx',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
  )],
  ["Login with too short account number", Finance::Bank::Postbank_de->new(
                    login => '999999999', # One nine too few
                    password => '11111',
                    status => sub {
                                shift;
                                diag join " ",@_
                                  if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                              },
                  )],
  ["Login with too long account number", Finance::Bank::Postbank_de->new(
                    login => '99999999999', # One nine too many
                    password => '11111',
                    status => sub {
                                shift;
                                diag join " ",@_
                                  if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                              },
                  )],
);

# Check that we have SSL installed :
SKIP: {
  skip "Need SSL capability to access the website",4*scalar @accounts
    unless LWP::Protocol::implementor('https');

  for my $test (@accounts) {
    my ($name,$account) = @$test;

    # Get the login page:
    my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

    # Check that we got a wellformed page back
    SKIP: {
      unless ($status == 200) {
        diag $account->agent->res->as_string;
        skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)", 4;
      };
      skip "Test $name: Banking is unavailable due to maintenance", 4
        if $account->maintenance;

      $account->agent(undef);
      $account->new_session();
      ok($account->error_page(),"We got an error page (Test $name)")
        or save_content($account,"error-password-$name");
      ok($account->access_denied(),"Access denied ($name)")
        or do {
          diag "Error message: ", $account->error_message;
          save_content($account,"wrong-password");
        };
      is($account->close_session(),'Never logged in',"Session is silently discarded if never logged in");
      is($account->agent(),undef,"agent was discarded");

    };
  };
};
