#!/usr/bin/env perl

use strict;
use warnings;

use Lingua::EUS::Numbers qw(cardinal2alpha ordinal2alpha);
use Test::More tests => 12;

$SIG{__WARN__} = sub { }; # Discard warnings, we expect them.

my %list = (
   ''    => undef,
   'foo' => undef,
   '13A' => undef,
   1.23  => undef,
   -4    => undef,
   1_000_000_000_000_000 => undef,
);


while( my( $key, $value) = each(%list) ) {
   my $cardiresult = &cardinal2alpha($key) ;
   my $ordiresult = &ordinal2alpha($key) ;
   is($cardiresult, $value, "Value of cardinal '$key'") ;
   is($ordiresult, $value, "Value of ordinal '$key'") ;
}
