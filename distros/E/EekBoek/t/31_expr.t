#! perl
# $Id: 31_expr.t,v 1.4 2010/03/17 10:51:33 jv Exp $

use strict;
use warnings;

use EB;
use EB::Format;

EB->app_init( { app => "Test", nostdconf => 1 } );

my @tests;
BEGIN {
    @tests =
      (
       '12345+98765'	 => '11111000',
       '3*2'		 => '600',
       '4.12+5,25'	 => '937',
       '+123+123'	 => '24600',
       '-123+123'	 => '0',
       '123.45*0.1253'	 => '1547',
       # 0.005 should not be treated as 0<thsep>005, but as 0<decsep>005.
       '25.50*1.19+0.005' => '3035',
       # Mix . and ,
       '25,50*1.19+0.005+0,05' => '3040',
       # Disallow anything fancy
       '7.123,45*0.12'	 => '<undef>'
      );
}

use Test::More tests => @tests/2;

# Test numers (amount) parsing.
while ( @tests ) {
    my $amt = shift(@tests);
    my $exp = shift(@tests);

    my $res = eval { amount($amt) };
    $res = '<undef>' unless defined $res;
    diag($@) if $@;
    is($res, $exp, "amount $amt");
}
