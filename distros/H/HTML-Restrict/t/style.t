#!perl

use strict;
use warnings;

use HTML::Restrict ();
use Test::More;

my $hr = HTML::Restrict->new( debug => 0 );

my $html = q[<style type="text/css">
hr {color:sienna;}
p {margin-left:20px;}
body {background-image:url("images/back40.gif");}
</style>];

is( $hr->process($html), undef, 'content of style tag removed by default' );

$hr->set_rules( { style => ['type'] } );

is( $hr->process($html), $html, 'content of style tag preserved' );

done_testing();
