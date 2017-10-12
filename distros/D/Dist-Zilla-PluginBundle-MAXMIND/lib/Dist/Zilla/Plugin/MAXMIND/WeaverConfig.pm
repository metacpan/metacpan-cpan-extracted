package Dist::Zilla::Plugin::MAXMIND::WeaverConfig;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.83';

use Moose;

with 'Dist::Zilla::Role::Plugin';

has include_donations_pod => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A plugin that exists solely to hold Pod::Weaver config

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MAXMIND::WeaverConfig - A plugin that exists solely to hold Pod::Weaver config

=head1 VERSION

version 0.83

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
