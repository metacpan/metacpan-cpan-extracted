#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use Data::Dumper;

use_ok("Finance::Bank::Postbank_de");

# Check that we have SSL installed :
SKIP: {

  skip "Need SSL capability to access the website",6
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
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)",5;
    };
    is($status,200,"We got a HTML page back");
    skip "Banking is unavailable due to maintenance", 4
      if $account->maintenance;

    my @forms = $account->agent->forms();
    is( scalar(grep({ ($_->attr('id')||"") eq 'id4' } @forms)), 1, "Found form 'id4'")
      or do {
        diag $account->agent->content;
        diag "Found forms:";
        diag sprintf "'%s'", $_->attr('id') for @forms;
      };
    $account->agent->form_id('id4');

    # Check that the expected form fields are available :
    my @fields = ('id4_hf_0','nutzernameStateEnclosure:nutzername','kennwortStateEnclosure:kennwort');
    my $field;
    for $field (@fields) {
      diag $account->agent->current_form->dump
        unless ok(defined $account->agent->current_form->find_input($field),"Login form has field '$field'");
    };
  };

  # Now fake the maintenance message :
  {
    no warnings;
    $account->agent(undef);
    local *Finance::Bank::Postbank_de::maintenance = sub { 1 };
    local *Finance::Bank::Postbank_de::get_login_page = sub { 200 };
    eval { $account->new_session(); };
    like($@,"/Banking unavailable due to maintenance/","Maintenance handling");
  };

};
