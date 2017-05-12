package Dist::Zilla::Plugin::MAXMIND::VersionProvider;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.80';

use Parse::PMFile;

use Moose;

with 'Dist::Zilla::Role::VersionProvider';

sub provide_version {
    my $self = shift;

    ( my $module = $self->zilla->name ) =~ s{-}{/}g;
    my $file = "lib/$module.pm";
    $self->log_fatal("Cannot find $file to get \$VERSION from")
        unless -e $file;

    my ( $info, undef ) = Parse::PMFile->new->parse($file);
    ( my $package = $self->zilla->name ) =~ s/-/::/g;
    unless ( $info->{$package}{version} ) {
        $self->log_fatal(
            "Parse::PMFile could not find a \$VERSION for $package in $file");
    }

    return $info->{$package}{version};
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Gets the distribution version from the main module's $VERSION

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MAXMIND::VersionProvider - Gets the distribution version from the main module's $VERSION

=head1 VERSION

version 0.80

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
