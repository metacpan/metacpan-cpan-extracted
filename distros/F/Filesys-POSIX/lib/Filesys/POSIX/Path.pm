# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Path;

use strict;
use warnings;

use Filesys::POSIX::Error qw(throw);

=head1 NAME

Filesys::POSIX::Path - Pathname manipulation utility class

=head1 SYNOPSIS

    use Filesys::POSIX::Path;

    my $path = Filesys::POSIX::Path->new('/foo/bar/baz');

    printf("%s\n", $path->basename); # outputs 'baz'
    printf("%s\n", $path->dirname);  # outputs '/foo/bar'

    # outputs '/foo/bar/../baz'
    printf("%s\n", $path->full('/foo/./././bar/../baz'));

=head1 DESCRIPTION

This module provides an object-oriented approach to path cleanup and
introspection.

=head1 CREATING AN OBJECT

=over

=item C<Filesys::POSIX::Path-E<gt>new($path)>

Creates a new path object.

The path is split on the forward slash (/) character into tokens; empty and
redundant tokens are discarded.  Enough context is kept to help the methods
implemented in this module determine the nature of the path; if it is relative
to root, prefixed with './', or relative to the "current working directory".
An C<ARRAY> reference blessed into this package's namespace is returned upon
success.  An EINVAL is thrown if the path provided is empty.

=back

=cut

sub new {
    my ( $class, $path ) = @_;
    my @components = split( /\//, $path );
    my @ret;

    if ( @components && _non_empty( $components[0] ) ) {
        push @ret, $components[0];
    }

    if ( @components > 1 ) {
        push @ret, grep { _non_empty($_) && $_ ne '.' } @components[ 1 .. $#components ];
    }

    throw &Errno::EINVAL unless @components || _non_empty($path);

    my @hier = _non_empty( $components[0] ) ? @ret : ( '', @ret );

    if ( @hier == 1 && !_non_empty( $hier[0] ) ) {
        @hier = ('/');
    }

    return bless \@hier, $class;
}

sub _proxy {
    my ( $context, @args ) = @_;

    unless ( ref $context eq __PACKAGE__ ) {
        return $context->new(@args);
    }

    return $context;
}

sub _non_empty {
    my ($string) = @_;

    return 0 unless defined $string;
    return 0 if $string eq '';

    return 1;
}

=head1 PATH INTROSPECTION

=over

=item C<$path-E<gt>components>

Return a list of the components parsed at object construction time.

=cut

sub components {
    my $self = _proxy(@_);

    return @$self;
}

=item C<$path-E<gt>full>

Returns a string representation of the full path.  This is the same as:

    join('/', @$path);

=cut

sub full {
    my $self = _proxy(@_);
    my @hier = @$self;

    return join( '/', @$self );
}

=item C<$path-E<gt>dirname>

Returns a string representation of all of the leading path elements, of course
save for the final path element.

=cut

sub dirname {
    my $self = _proxy(@_);
    my @hier = @$self;

    if ( @hier > 1 ) {
        my @parts = @hier[ 0 .. $#hier - 1 ];

        if ( @parts == 1 && !_non_empty( $parts[0] ) ) {
            return '/';
        }

        return join( '/', @parts );
    }

    return $hier[0] eq '/' ? '/' : '.';
}

=item C<$path-E<gt>basename>

=item C<$path-E<gt>basename($ext)>

Returns the final path component.  If called with an extension, then the method
will return the path component with the extension chopped off, if found.

=cut

sub basename {
    my ( $self, $ext ) = ( _proxy( @_[ 0 .. 1 ] ), $_[2] );
    my @hier = @$self;

    my $name = $hier[$#hier];
    $name =~ s/$ext$// if _non_empty($ext);

    return $name;
}

=item C<$path-E<gt>shift>

Useful for iterating over the components of the path object.  Shifts the
internal start-of-array pointer by one, and returns the previous first value.

=cut

sub shift {
    my ($self) = @_;
    return shift @$self;
}

=item C<$path-E<gt>push(@parts)>

Push new components onto the current path object.  Each part will be tokenized
on the forward slash (/) character, and useless items will be discarded.

=cut

sub push {
    my ( $self, @parts ) = @_;

    return push @$self, grep { $_ && $_ ne '.' } map { split /\// } @parts;
}

=item C<$path-E<gt>concat($pathname)>

A new C<Filesys::POSIX::Path> object is created based on $pathname, and the
current path object's non-empty components are pushed onto that new instance.
The new path object is returned.

=cut

sub concat {
    my ( $self, $path ) = @_;
    $path = __PACKAGE__->new($path) unless ref $path eq __PACKAGE__;

    $path->push( grep { $_ && $_ ne '.' } $self->components );
    return $path;
}

=item C<$path-E<gt>concat($pathname)>

A new C<Filesys::POSIX::Path> object is created based on C<$pathname>, and the
new path object's non-empty components are pushed onto the current path object.
The current C<$path> reference is then returned.

=cut

sub append {
    my ( $self, $path ) = @_;
    $path = __PACKAGE__->new($path) unless ref $path eq __PACKAGE__;

    $self->push( grep { $_ ne '.' } $path->components );
    return $self;
}

=item C<$path-E<gt>pop>

Pops the final path component off of the path object list, and returns that
value.

=cut

sub pop {
    my ($self) = @_;
    return pop @$self;
}

=item C<$path-E<gt>count>

Returns the number of components in the current path object.

=cut

sub count {
    my ($self) = @_;
    return scalar @$self;
}

=item C<$path-E<gt>is_absolute>

Returns true if the current path object represents an absolute path.

=cut

sub is_absolute {
    my ($self) = @_;

    return 1 unless _non_empty( $self->[0] );
    return 0;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 CONTRIBUTORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
