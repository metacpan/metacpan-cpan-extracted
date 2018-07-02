package Elasticsearch::Model::Types;

use MooseX::Types -declare => [
    qw(
        Location
        )
];

use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Object/;

subtype Location,
    as ArrayRef,
    where { @$_ == 2 },
    message { "Location is an arrayref of longitude and latitude" };

coerce Location, from HashRef,
    via { [$_->{lon} || $_->{longitude}, $_->{lat} || $_->{latitude}] };
coerce Location, from Str, via { [reverse split(/,/)] };

1;
