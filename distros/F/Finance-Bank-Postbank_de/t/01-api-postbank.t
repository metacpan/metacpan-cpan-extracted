#!/usr/bin/perl -w
use strict;
use Test::More tests => 2;

use_ok("Finance::Bank::Postbank_de");

my $account = Finance::Bank::Postbank_de->new(login => '9999999999',password => '12345678');
can_ok($account, qw(
  new
  new_session
  get_account_statement
  close_session
  error_page
  session_timed_out
  maintenance
  access_denied
  ));

