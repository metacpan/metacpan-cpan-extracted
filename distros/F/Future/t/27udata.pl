use v5.10;
use strict;
use warnings;

use Test2::V0;

use Future;

my $f = Future->new;

my $datum = [ "the datum" ];

ref_is( $f->set_udata( a_field => $datum ), $f, '->set_udata returns $f' );

ref_is( $f->udata( "a_field" ), $datum, '->udata returns the datum' );

$f->cancel;

done_testing;
