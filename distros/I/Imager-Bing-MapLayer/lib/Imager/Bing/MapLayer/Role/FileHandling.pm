package Imager::Bing::MapLayer::Role::FileHandling;

use v5.10;

use Moose::Role;

use Cwd;
use Moose::Util::TypeConstraints;

=head1 NAME

Imager::Bing::MapLayer::Role::FileHandling - file handling attributes

=cut

use version 0.77; our $VERSION = version->declare('v0.1.9');

=head1 DESCRIPTION

This role is for internal use by L<Imager::Bing::MapLayer>.

=cut

has 'base_dir' => (
    is      => 'ro',
    isa     => subtype( as 'Str', where { -d $_ }, ),
    lazy    => 1,
    builder => '_build_base_dir',
);

sub _build_base_dir { getcwd() }

has 'overwrite' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'autosave' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

use namespace::autoclean;

1;
