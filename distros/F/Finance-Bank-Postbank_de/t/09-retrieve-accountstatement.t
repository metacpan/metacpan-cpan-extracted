#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use Test::MockObject;
use FindBin;

use_ok("Finance::Bank::Postbank_de::Account");

my @new_args;
my $postbank = Test::MockObject->new();
$postbank->fake_module("Finance::Bank::Postbank_de", new => sub { @new_args = @_; $postbank; } );
$postbank->set_always( get_account_statement =>  "get_account_statement called");

# Check that the parameter validation works :
eval {
  my $account = Finance::Bank::Postbank_de::Account->parse_statement();
};
like($@,"/^Need an account number if I have to retrieve the statement online/","Check for login parameter");
$postbank->clear;

eval {
  my $account = Finance::Bank::Postbank_de::Account->parse_statement(
                  number => '9999999999',
                );
};
like($@,"/^Need a password if I have to retrieve the statement online/","Check for password parameter");
$postbank->clear;

my $account = Finance::Bank::Postbank_de::Account->parse_statement(
                number => '9999999999',
                password => '11111',
              );
is_deeply(\@new_args, [ 'Finance::Bank::Postbank_de', login => '9999999999', password => '11111', past_days => undef ], "Check for number => login conversion");
my ($func,$args) = $postbank->next_call();
is_deeply([$func,$args], [ "get_account_statement",[$postbank]], "get_account_statement() was called");
$postbank->clear;

$account = Finance::Bank::Postbank_de::Account->parse_statement(
                number => '0999999999',
                login => '9999999999',
                password => '11111',
              );
is_deeply(\@new_args, [ 'Finance::Bank::Postbank_de', login => '9999999999', password => '11111', past_days => undef ], "Check for login parameter");
($func,$args) = $postbank->next_call();
is_deeply([$func,$args], [ "get_account_statement",[$postbank]], "get_account_statement() was called");
$postbank->clear;
