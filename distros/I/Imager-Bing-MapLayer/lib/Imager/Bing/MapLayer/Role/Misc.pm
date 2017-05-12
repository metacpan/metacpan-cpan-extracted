package Imager::Bing::MapLayer::Role::Misc;

use v5.10;

use Moose::Role;

use Moose::Util::TypeConstraints;

=head1 NAME

Imager::Bing::MapLayer::Role::Misc - misc shared attributions

=cut

use version 0.77; our $VERSION = version->declare('v0.1.9');

=head1 DESCRIPTION

This role is for internal use by L<Imager::Bing::MapLayer>.

=cut

has 'combine' => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_combine',
);

sub _build_combine {'darken'}

has 'in_memory' => (
    is      => 'ro',
    isa     => subtype( as 'Int', where { ( $_ >= 0 ) }, ),
    default => 0,
);

use namespace::autoclean;

1;
