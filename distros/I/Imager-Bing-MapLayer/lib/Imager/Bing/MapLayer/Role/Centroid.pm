package Imager::Bing::MapLayer::Role::Centroid;

use v5.10;

use Moose::Role;

use Const::Fast;

=head1 NAME

Imager::Bing::MapLayer::Role::Centroid - a centroid role

=cut

use version 0.77; our $VERSION = version->declare('v0.1.9');

=head1 DESCRIPTION

This role is for internal use by L<Imager::Bing::MapLayer>.

=cut

# We default to a centroid in London, because, this was originally
# developed for a London-based company.

const my $LONDON_LATITUDE  => 51.5171;
const my $LONDON_LONGITUDE => 0.1062;

has 'centroid_latitude' => (
    is      => 'ro',
    isa     => 'Num',
    builder => '_build_centroid_latitude',
);

has 'centroid_longitude' => (
    is      => 'ro',
    isa     => 'Num',
    builder => '_build_centroid_longitude',
);

sub _build_centroid_latitude  {$LONDON_LATITUDE}
sub _build_centroid_longitude {$LONDON_LONGITUDE}

use namespace::autoclean;

1;
