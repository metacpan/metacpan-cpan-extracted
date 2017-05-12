#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

################################################################################
# Create a new object
################################################################################

my $y = BrokenRenderYear->new();

isa_ok( $y, 'BrokenRenderYear' );

add_data( $y );

eval { $y->render( pixelsperyear => 30 ); };
like( $@, qr/^Timeline::GD->render\(\) key 'height' is not defined from render_year\(\) /, 'Broken render method' );

################################################################################
# Create a new object
################################################################################

my $i = BrokenRenderInterval->new();

isa_ok( $i, 'BrokenRenderInterval' );

add_data( $i );

eval { $i->render( pixelsperyear => 30 ); };
like( $@, qr/^Timeline::GD->render\(\) key 'height' is not defined from render_interval\(\) /, 'Broken render method' );

################################################################################
# Create a new object
################################################################################

my $p = BrokenRenderPoint->new();

isa_ok( $p, 'BrokenRenderPoint' );

add_data( $p );

eval { $p->render( pixelsperyear => 30 ); };
like( $@, qr/^Timeline::GD->render\(\) key 'height' is not defined from render_point\(\) /, 'Broken render method' );

################################################################################
# Add some data to an object
################################################################################

sub add_data {
    my ($object) = @_;

    $object->add_interval( label => 'Pius VI',  start => '1717/12/25', end => '1799/08/28', group => 'popes' );
    $object->add_interval( label => 'Pius VII', start => '1742/04/14', end => '1823/07/20', group => 'popes' );
    $object->add_interval( label => 'Leo XII',  start => '1760/08/22', end => '1829/02/10', group => 'popes' );

    $object->add_point( label => 'Albert Einstein born', start => '1879/03/14' );
    $object->add_point( label => 'Albert Einstein dies', start => '1955/04/18' );
}

package BrokenRenderPoint;

use base 'Graph::Timeline::GD';

sub render_year {
    my ( $self, $year ) = @_;

    $year->{height} = 15;
}

sub render_interval {
    my ( $self, $record ) = @_;

    $record->{height} = 30;
}

sub render_point {
}

1;

package BrokenRenderInterval;

use base 'Graph::Timeline::GD';

sub render_year {
    my ( $self, $year ) = @_;

    $year->{height} = 15;
}

sub render_interval {
}

1;

package BrokenRenderYear;

use base 'Graph::Timeline::GD';

sub render_year {
}

1;

# vim: syntax=perl:
