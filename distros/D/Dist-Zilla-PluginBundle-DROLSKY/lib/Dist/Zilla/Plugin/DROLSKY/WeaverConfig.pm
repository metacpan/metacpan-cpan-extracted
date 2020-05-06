package Dist::Zilla::Plugin::DROLSKY::WeaverConfig;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.08';

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

Dist::Zilla::Plugin::DROLSKY::WeaverConfig - A plugin that exists solely to hold Pod::Weaver config

=head1 VERSION

version 1.08

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
