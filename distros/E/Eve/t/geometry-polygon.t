# -*- mode: Perl; -*-
package GeometryPolygonTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::Geometry::Polygon;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'data'} = [[57.109, 33.123], [58.109, 34.123]];

    $self->{'geo'} = Eve::Geometry::Polygon->new(data => $self->{'data'});
}

sub test_object : Test(2) {
    my $self = shift;

    isa_ok($self->{'geo'}, 'Eve::Class');
    isa_ok($self->{'geo'}, 'Eve::Geometry');
}

sub test_constructor : Test {
    my $self = shift;

    is($self->{'geo'}->length, 2);
}

sub test_export : Test {
    my $self = shift;

    is_deeply($self->{'geo'}->export(), $self->{'data'});
}

sub test_serialize : Test {
    my $self = shift;

    is(
        $self->{'geo'}->serialize(),
        'POLYGON(('
        . join(
            ',',
            map {
                join(' ', reverse(@{$_}))
            } @{$self->{'data'}})
        . '))');
}

sub test_clone : Test {
    my $self = shift;

    my $new_geo = $self->{'geo'}->clone();

    isnt($self->{'geo'}, $new_geo);
}

1;
