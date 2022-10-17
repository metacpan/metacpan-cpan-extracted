use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Identity;

use Future;

my $f = Future->new;

identical( $f->set_label( "the label" ), $f, '->set_label returns $f' );

is( $f->label, "the label", '->label returns the label' );

$f->cancel;

done_testing;
