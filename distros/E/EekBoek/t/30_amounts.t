#! perl
# $Id: 30_amounts.t,v 1.4 2010/03/17 10:51:33 jv Exp $

use strict;
use warnings;

use EB;
use EB::Format;

EB->app_init( { app => "Test", nostdconf => 1 } );

my @tests;
BEGIN {
    @tests =
      (
       # Integral
       '12345'		 => '1234500',
       # Fraction, EU + US
       '12345,66'	 => '1234566',
       '12345.66'	 => '1234566',
       # Too many fractional digits
       '12345,667'	 => '<undef>',
       '12345.667'	 => '<undef>',
       # Groups, EU + US
       '1.234.456'	 => '123445600',
       '1,234,456'	 => '123445600',
       # Illegal groups
       '1234.456'	 => '<undef>',
       '1234,456'	 => '<undef>',
       # Group + Fraction, EU + US
       '1.234,56'	 => '123456',
       '1,234.56'	 => '123456',
       # Illegal group/fract.
       '1.234.56'	 => '<undef>',
       '1.3'	 => '<undef>',
       '1,6'	 => '<undef>',
      );
}

use Test::More tests => @tests/2;

# Test numers (amount) parsing.
while ( @tests ) {
    my $amt = shift(@tests);
    my $exp = shift(@tests);

    my $res = amount($amt);
    $res = '<undef>' unless defined $res;

    is($res, $exp, "amount $amt");
}
