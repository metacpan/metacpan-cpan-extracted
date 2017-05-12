#!/usr/bin/perl -w
use strict;

use vars qw( @numbers @dates );

BEGIN {
  @numbers = (
    [ "1,00",                1.0 ],
    [ "1,10",                1.1 ],
    [ "1.000,00",         1000.0 ],
    [ "1.000,00",         1000.0 ],
    [ "9.999.999,00",  9999999.0 ],
    [ "9.999.999,01",  9999999.01 ],
    [ "0,00",                0.0 ],
    [ "1,10",                1.10 ],
    ["-1,10",               -1.10 ],
    ["-99,00",             -99.00 ],
    ["-1.000,15",         -1000.15 ],
  );
  @dates = (
    [qw( 01.01.1999 19990101 )],
    [qw( 01.01.9999 99990101 )],
    [qw( 09.01.1111 11110109 )],
    [qw( 99.01.1000 10000199 )],
  );
};

use Test::More tests => 7 + scalar @numbers + scalar @dates;

use_ok("Finance::Bank::Postbank_de::Account");

my $account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
              );

for ( @numbers ) {
  cmp_ok($account->parse_amount($_->[0]),'==',$_->[1],"Parsing ".$_->[0]." works");
};

eval { $account->parse_amount("foo") };
like($@,"/^String 'foo' does not look like a number/","Checking for invalid numbers");
eval { $account->parse_amount("9") };
like($@,"/^String '9' does not look like a number/","Checking for invalid numbers");
eval { $account->parse_amount("10,000.00") };
like($@,"/^String '10,000.00' does not look like a number/","Checking for invalid numbers");

for (@dates) {
  is($account->parse_date($_->[0]),$_->[1],"Parsing ".$_->[0]." works");
};

eval { $account->parse_date("foo") };
like($@,"/^Unknown date format 'foo'. A date must be in the format 'DD\\.MM\\.YYYY'/","Checking for invalid dates");
eval { $account->parse_date("01/01/1999") };
like($@,"/^Unknown date format '01\\/01\\/1999'. A date must be in the format 'DD\\.MM\\.YYYY'/","Checking for invalid dates");
eval { $account->parse_date("01.01.99") };
like($@,"/^Unknown date format '01\\.01\\.99'. A date must be in the format 'DD\\.MM\\.YYYY'/","Checking for invalid dates");

