package Google::Type::Latlng::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LatLng',
    as InstanceOf['Google::Type::Latlng::LatLng'];

coerce 'LatLng',
    from HashRef, via { 'Google::Type::Latlng::LatLng'->new($_) };

declare 'RepeatedLatLng',
    as ArrayRef[LatLng()];

coerce 'RepeatedLatLng',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Latlng::LatLng'->new($_) } @$_ ] };

declare 'MapStringLatLng',
    as HashRef[LatLng()];

1;
