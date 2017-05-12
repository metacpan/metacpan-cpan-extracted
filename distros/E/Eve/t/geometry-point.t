# -*- mode: Perl; -*-
package GeometryPointTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::Geometry::Point;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'geo'} = Eve::Geometry::Point->new(data => [57.109, 33.123]);
}

sub test_object : Test(2) {
    my $self = shift;

    isa_ok($self->{'geo'}, 'Eve::Class');
    isa_ok($self->{'geo'}, 'Eve::Geometry');
}

sub test_constructor : Test(2) {
    my $self = shift;

    is($self->{'geo'}->latitude, 57.109);
    is($self->{'geo'}->longitude, 33.123);
}

sub test_export : Test {
    my $self = shift;

    is_deeply($self->{'geo'}->export(), [57.109, 33.123]);
}

sub test_serialize : Test {
    my $self = shift;

    is_deeply($self->{'geo'}->serialize(), 'POINT(33.123 57.109)');
}

sub test_clone : Test(3) {
    my $self = shift;

    my $geo = $self->{'geo'};

    $geo->latitude = 10.001;
    $geo->longitude = 90.999;

    my $new_geo = $geo->clone();

    is($geo->latitude, $new_geo->latitude);
    is($geo->longitude, $new_geo->longitude);

    isnt($geo, $new_geo);
}

1;
