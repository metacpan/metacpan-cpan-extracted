#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;

use_ok("Finance::Bank::Postbank_de");

my $account = Finance::Bank::Postbank_de->new(login => '9999999999',password => '11111');
can_ok($account, qw(
  new
  agent
  new_session
  select_function
  get_account_statement
  close_session
  error_page
  session_timed_out
  maintenance
  access_denied
  ));

# Check our accessor methods
my $oldval = $account->agent();
$account->agent("foo");
is($account->agent(),"foo","Accessor agent()");
$account->agent($oldval);
is($account->agent(),$oldval,"Accessor agent()");