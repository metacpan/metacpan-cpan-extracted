package Dist::Zilla::Plugin::DROLSKY::Role::MaybeFileWriter;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.20';

use Path::Tiny qw( path );

use Moose::Role;

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _maybe_write_file {
    my $self          = shift;
    my $path          = shift;
    my $content       = shift;
    my $is_executable = shift;

    my $file = path($path);

    return if $file->exists;

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros )
    $file->parent->mkpath( 0, 0755 );
    $file->spew_utf8($content);
    $file->chmod(0755) if $is_executable;

    return;
}

1;

# ABSTRACT: Knows how to maybe write files

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::Role::MaybeFileWriter - Knows how to maybe write files

=head1 VERSION

version 1.20

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
