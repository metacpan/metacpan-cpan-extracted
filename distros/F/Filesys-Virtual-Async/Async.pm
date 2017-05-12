package Filesys::Virtual::Async;

use strict;
use warnings;

use Carp qw( croak );
our $VERSION = '0.02';


sub new {
    my $class = shift;
    bless( {
        cwd => '/',
        root => '/',
        @_
    }, ref $class || $class );
}

sub open {
    croak 'subclass didn\'t define open';
}

sub close {
    croak 'subclass didn\'t define close';
}

sub read {
    croak 'subclass didn\'t define read';
}

sub write {
    croak 'subclass didn\'t define write';
}

sub sendfile {
    croak 'subclass didn\'t define sendfile';
}

sub readahead {
    croak 'subclass didn\'t define readahead';
}

sub stat {
    croak 'subclass didn\'t define stat';
}

sub lstat {
    croak 'subclass didn\'t define lstat';
}

sub utime {
    croak 'subclass didn\'t define utime';
}

sub chown {
    croak 'subclass didn\'t define chown';
}

sub truncate {
    croak 'subclass didn\'t define truncate';
}

sub chmod {
    croak 'subclass didn\'t define chmod';
}

sub unlink {
    croak 'subclass didn\'t define unlink';
}

sub mknod {
    croak 'subclass didn\'t define mknod';
}

sub link {
    croak 'subclass didn\'t define link';
}

sub symlink {
    croak 'subclass didn\'t define symlink';
}

sub readlink {
    croak 'subclass didn\'t define readlink';
}

sub rename {
    croak 'subclass didn\'t define rename';
}

sub mkdir {
    croak 'subclass didn\'t define mkdir';
}

sub rmdir {
    croak 'subclass didn\'t define rmdir';
}

sub readdir {
    croak 'subclass didn\'t define readdir';
}

sub load {
    croak 'subclass didn\'t define load';
}

sub copy {
    croak 'subclass didn\'t define copy';
}

sub move {
    croak 'subclass didn\'t define move';
}

sub scandir {
    croak 'subclass didn\'t define scandir';
}

sub rmtree {
    croak 'subclass didn\'t define rmtree';
}

sub fsync {
    croak 'subclass didn\'t define fsync';
}

sub fdatasync {
    croak 'subclass didn\'t define fdatasync';
}

sub cwd {
    my ( $self, $cwd, $callback ) = @_;

    return $callback->( $self->{cwd} = $cwd )
        if ( defined $cwd && defined $callback );

    return $self->{cwd} = ( $cwd ) ? $cwd : '/';
}

sub root {
    my $self = shift;

    if (@_) {
        my $root = shift;
        $root =~ s/\/$//;
        $self->{root} = $root;
    }

    return $self->{root};
}

sub _path_from_root {
    my $self = shift;

    return $self->{root}.$self->_resolve_path(@_);
}

# resolve a path from the current path
sub _resolve_path {
    my ( $self, $path ) = @_;

    # could be a file handle, return it
    # XXX wth?
    return $path if ( ref $path );

    $path ||= '';

    my $cwd = $self->{cwd};
    my $path_out = '';

    if ($path eq '') {
        $path_out = $cwd;
    } elsif ($path eq '/') {
        $path_out = '/';
    } else {
        my @real = split(/\//, $cwd);
        if ($path =~ m/^\//) {
            @real = ();
        }

        my @paths = split( /\//,$path );

        if (@paths && $paths[0] eq '~' && $self->{home_path}) {
            @real = split(/\//, $self->{home_path});
            shift @paths;
        }

        foreach (@paths) {
            if ($_ eq '..') {
                pop(@real) if ($#real);
            } elsif ($_ eq '.') {
                next;
            } else {
                push(@real, $_);
            }
        }
        $path_out = join('/', @real);
    }
    
    return (substr($path_out, 0, 1) eq '/') ? $path_out : '/'.$path_out;
}

1;

__END__

=pod

=head1 NAME

Filesys::Virtual::Async - Base class for non blocking virtual filesystems

=head1 SYNOPSIS

use base 'Filesys::Virtual::Async';

sub new {
    my $class = shift;
    $class->SUPER::new(@_);
}

# then override the various methods

=head1 DESCRIPTION

The goal of Filesys::Virtual::Async is to provide an interface like IO::AIO for a
non blocking virtual filesystem

This is a base class, see the L<SEE ALSO> section below

This module is still in flux to an extent.  If you'd like to suggest changes, please
drop in the irc channel #poe on irc.perl.org and speak with xantus[] or Apocalypse

=head1 WARNING

This is interface isn't solidified yet.  It will change.  I released this module
early due to demand.  You have been warned.

=head1 OBJECT METHODS

=over 4

=item new( root => $path );

root is optional, and defaults to /.  root is prepended to all paths after
resolution

=item cwd()

Returns the current working directory (virtual)

=item root() or root( $path )

Gets or sets the root path.  This path is prepended to the path returned
from _path_from_root

=item _path_from_root( $path )

Resolves a path, with the root path prepended.

This is a private method, do not document it in your subclass.

=item _resolve_path( $path )

Resolves a path to a normalized direct path based on the cwd, allowing .. 
traversal, and the ~ home directory shortcut (if home_path is defined)

For example, if the cwd is /foo/bar/baz, and $path is 
/../../../../foo/../foo/./bar/../foo then /foo will be returned

This is a private method, do not document it in your subclass.

=back

=head1 CALLBACK METHODS

All of these work exactly like the L<IO::AIO> methods of the same name.  Use IO::AIO 
as a reference for these functions, but note that this in no way requires you to use
IO::AIO.

=over 4

=item open()

=item close()

=item read()

=item write()

=item sendfile()

=item readahead()

=item stat()

=item lstat()

=item utime()

=item chown()

=item truncate()

=item chmod()

=item unlink()

=item mknod()

=item link()

=item symlink()

=item readlink()

=item rename()

=item mkdir()

=item rmdir()

=item readdir()

=item load()

=item copy()

=item move()

=item scandir()

=item rmtree()

=item fsync()

=item fdatasync()

=back

=head1 SEE ALSO

L<Filesys::Virtual::Async::Plain>

L<http://xant.us/>

=head1 AUTHOR

David W Davis E<lt>xantus@cpan.orgE<gt>

=head1 RATING

You can rate this this module at
L<http://cpanratings.perl.org/rate/?distribution=Filesys::Virtual::Async>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by David W Davis, All rights reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut

