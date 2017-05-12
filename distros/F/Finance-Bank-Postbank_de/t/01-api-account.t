#!/usr/bin/perl -w
use strict;

use vars qw(@accessors);

BEGIN { @accessors = qw( name number balance transactions_future iban account_type )};

use Test::More tests => 13 + scalar @accessors * 2;

use_ok("Finance::Bank::Postbank_de::Account");

my $account = Finance::Bank::Postbank_de::Account->new( number => '9999999999' );
can_ok($account, qw(
  new
  parse_date
  parse_amount
  slurp_file
  parse_statement
  trade_dates
  value_dates
  ), @accessors );

sub test_scalar_accessor {
  my ($name,$newval) = @_;

  # Check our accessor methods
  my $oldval = $account->$name();
  $account->$name($newval);
  is($account->$name(),$newval,"Setting new value via accessor $name");
  $account->$name($oldval);
  is($account->$name(),$oldval,"Resetting new value via accessor $name");
};

for (@accessors) {
  test_scalar_accessor($_,"0999999999")
};

$account = Finance::Bank::Postbank_de::Account->new( name => "Heinz Huber" );
is($account->name,"Heinz Huber","Constructor accepts 'name' argument");

$account = Finance::Bank::Postbank_de::Account->new( number => 12345 );
is($account->number,"12345","Constructor accepts 'number' argument");
is($account->kontonummer,"12345","Kontonummer is an alias for number");

$account = Finance::Bank::Postbank_de::Account->new( kontonummer => 12345 );
is($account->number,"12345","Constructor accepts 'kontonummer' argument");
is($account->kontonummer,"12345","Number is an alias for kontonummer");

$account = Finance::Bank::Postbank_de::Account->new( kontonummer => 12345, number => 12345 );
is($account->number,"12345","Constructor accepts 'kontonummer' and number argument");
is($account->kontonummer,"12345","Number is an alias for kontonummer");

$account = eval {Finance::Bank::Postbank_de::Account->new( kontonummer => 12345, number => 67890 ); };
like( $@, "/^'kontonummer' is '12345' and 'number' is '67890' at /", "If both, kontonummer and number are specified, they must be 'eq'ual");

$account = eval {Finance::Bank::Postbank_de::Account->new( kontonummer => 12345, number => "012345" ); };
like( $@, "/^'kontonummer' is '12345' and 'number' is '012345' at /", "If both, kontonummer and number are specified, they must be 'eq'ual");

$account = Finance::Bank::Postbank_de::Account->new( number => 12345, name => "Heinz Huber" );
is($account->name,"Heinz Huber","Constructor accepts 'name' argument");
is($account->number,"12345","Constructor accepts 'number' argument");
