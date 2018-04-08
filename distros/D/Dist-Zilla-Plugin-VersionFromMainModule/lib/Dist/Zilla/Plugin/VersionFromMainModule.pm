package Dist::Zilla::Plugin::VersionFromMainModule;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.04';

use Moose;

with 'Dist::Zilla::Role::VersionProvider',
    'Dist::Zilla::Role::ModuleMetadata';

sub provide_version {
    my $self = shift;

    return $ENV{V} if exists $ENV{V};

    my $module = $self->zilla->main_module;
    my $name   = $module->name;
    my $metadata
        = $self->module_metadata_for_file( $module, collect_pod => 0 );

    my $ver = $metadata->version
        or $self->log_fatal("Unable to get version from $name");

    $self->log_debug("Setting dist version $ver from $name");

    # We need to stringify this since it can be a version object.
    return "$ver";
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Set the distribution version from your main module's $VERSION

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::VersionFromMainModule - Set the distribution version from your main module's $VERSION

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  [VersionFromMainModule]

=head1 DESCRIPTION

This plugin sets the distribution version from the C<$VERSION> found in the
distribution's main module, as defined by L<Dist::Zilla>.

This plugin is useful if you want to set the C<$VERSION> in your module(s)
manually or with some sort of post-release "increment the C<$VERSION>" plugin,
rather than letting dzil add the C<$VERSION> based on a setting in the
F<dist.ini>.

You can override the distribution version by setting the C<V> environment
variable, e.g.: C<V=1.23 dzil release>.

=head1 CREDITS

This code is mostly the same as what Christopher J. Madsen's
L<Dist::Zilla::Plugin::VersionFromModule> module does. Unfortunately, that
module is only shipped as part of a larger distribution, and that distribution
has not been updated despite the fact that it is failing tests with newer
versions of dzil.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-VersionFromMainModule> or via email to L<bug-dist-zilla-plugin-versionfrommainmodule@rt.cpan.org|mailto:bug-dist-zilla-plugin-versionfrommainmodule@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-Plugin-VersionFromMainModule can be found at L<https://github.com/houseabsolute/Dist-Zilla-Plugin-VersionFromMainModule>.

=head1 AUTHORS

=over 4

=item *

Christopher J. Madsen <perl@cjmweb.net>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 - 2018 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
