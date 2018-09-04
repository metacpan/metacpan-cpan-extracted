#!/usr/bin/perl -w
use strict;
use FindBin;

use Test::More tests => 1;

use Finance::Bank::Postbank_de;

sub save_content {
  my ($account,$name) = @_;
  local *F;
  my $filename = "$0-$name.html";
  open F, "> $filename"
    or diag "Couldn't dump current page to '$filename': $!";
  binmode F;
  my $agent = $account->agent;
  print F $agent->content if $agent;
  close F;
  diag "Current page saved to '$filename'";
};


# Check that we have SSL installed :
SKIP: {
  skip "Need SSL capability to access the website",2
    unless LWP::Protocol::implementor('https');

  my $account = Finance::Bank::Postbank_de->new(
                  login => 'Petra.Pfiffig',
                  password => '12345678',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );

  # Get the login page:
  #my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

  # Check that we got a wellformed page back
  SKIP: {
    #unless ($status == 200) {
    #  diag $account->agent->res->as_string;
    #  skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)",2;
    #};
    #skip "Banking is unavailable due to maintenance", 4
    #  if $account->maintenance;
    #$account->agent(undef);
    $account->new_session();

    # Check that all functions are available
    #for (sort keys %Finance::Bank::Postbank_de::functions) {
    #    isn't undef,
    #        $account->agent->find_link(@{ $Finance::Bank::Postbank_de::functions{ $_ }}),
    #        "Function '$_' available";
    #};

    #eval {
    #    $status = $account->select_function("accountstatement");
    #};
    #unless ($status == 200) {
    #  diag $account->agent->res->as_string;
    #  skip "Couldn't get to account statement (LWP: $status)", 2;
    #};

    ok($account->close_session(),"Closed session")
      or save_content($account,"error-login-logout-close-session");
    #is($account->agent(),undef,"agent was discarded");
  };
};
