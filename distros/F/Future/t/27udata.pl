use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Identity;

use Future;

my $f = Future->new;

my $datum = [ "the datum" ];

identical( $f->set_udata( a_field => $datum ), $f, '->set_udata returns $f' );

identical( $f->udata( "a_field" ), $datum, '->udata returns the datum' );

$f->cancel;

done_testing;
