package Geo::Routing::Role::Route;
BEGIN {
  $Geo::Routing::Role::Route::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::Role::Route::VERSION = '0.11';
}
use Any::Moose '::Role';
use warnings FATAL => "all";
use Geo::Distance::XS;
use namespace::clean -except => "meta";

has points => (
    is            => 'ro',
    isa           => 'ArrayRef[ArrayRef[Num|Undef|Str]]',
    required      => 1,
    documentation => '',
);

has distance => (
    is            => 'ro',
    isa           => 'Num',
    documentation => '',
    lazy_build    => 1,
);

sub _build_distance {
    my ($self) = @_;

    my $points = $self->points;
    my $distance = 0;

    my $geo = Geo::Distance->new;

    for (my $i = 1; $i < @$points; $i++) {
        my $prev_point = $points->[$i - 1];
        my $curr_point = $points->[$i];
        my ($lon1, $lat1) = @$prev_point;
        my ($lon2, $lat2) = @$curr_point;

        my $prev_to_curr_distance = $geo->distance(
            kilometer => $lon1, $lat1, $lon2, $lat2,
        );

        $distance += $prev_to_curr_distance;
    }

    return $distance;
}

has travel_time => (
    is            => 'ro',
    isa           => 'Int',
    documentation => '',
    lazy_build    => 1,
);

requires '_build_travel_time';

1;
