#!perl

use strict;
use warnings;

use Test::More;
use Digest::MD6;

my @len = ( 224, 256, 384, 512 );

plan tests => @len * 2 * 3;

my $msg = 'abc';

for my $len ( @len ) {
  for my $mode (
    [ '',        'digest' ],
    [ '_hex',    'hexdigest' ],
    [ '_base64', 'b64digest' ]
   ) {
    my ( $sfx, $meth ) = @$mode;
    my $md6 = Digest::MD6->new( $len );
    $md6->add( $msg );
    my $want = $md6->$meth;
    my $func = "md6_${len}${sfx}";
    my $got  = eval "Digest::MD6::$func('$msg')";
    ok !$@, "$func: no error";
    is $got, $want, "$func: expected value";
  }
}

# vim:ts=2:sw=2:et:ft=perl

