use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Select', 'foo' )->options( 1 => 'yes', 0 => 'no' )
    ->constrain_options(1);

my $f = $w->process();

my @constraints = $w->get_constraints;

is( scalar(@constraints), 1, '1 implicit IN constraint' );

my $keys = $constraints[0]->in;

is( $keys->[0], 1, 'constraint value' );

is( $keys->[1], 0, 'constraint value' );

