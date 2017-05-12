package Filesys::Virtual::Async::Plain;

use strict;
use warnings;

our $VERSION = '0.02';

use Filesys::Virtual::Async;
use base qw( Filesys::Virtual::Async );

#use IO::AIO 2;
use IO::AIO;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{aio_max_group} ||= 4;

    return $self;
}

sub dirlist {
    my ( $self, $path, $withstat, $callback ) = @_;
    
    return $self->readdir( $path, sub {
        my $fl = shift;
        $fl = [ map { [ $_ ] } @$fl ] if ( ref $fl );
        $callback->( $fl );
    } ) unless ( $withstat );
    
    $self->readdir( $path, sub {
        my $list = shift;
        return $callback->() unless ( $list );
        
        my $root = $self->_path_from_root( $path );
        my $files = [];
        for my $i ( 0 .. $#{$list} ) {
            # file path, index
            $files->[ $i ] = [ $root.'/'.$list->[ $i ], $i ];
            $list->[ $i ] = [ $list->[ $i ] ];
        }
        
        my $grp = aio_group( $callback );
        # pass $list to the callback
        $grp->result( $list );
        limit $grp $self->{aio_max_group};
        # add files
        feed $grp sub {
            my $file = pop @$files or return;
            add $grp aio_stat $file->[ 0 ], sub {
                $_[ 0 ] and return;
                $list->[ $file->[ 1 ] ]->[ 1 ] = $_[ 1 ];
            };
        };
    } );

    return;
}

sub open {
    my $self = shift;

    aio_open( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ], $_[ 2 ] );
}

sub close {

    aio_close( $_[ 1 ], $_[ 2 ] );
}

# don't email me bitching about how this is done.  It had to be done this way due to the prototype
# on IO::AIO functions.  If you have an alternative, enlighten me.
sub read {

    aio_read( $_[ 1 ], $_[ 2 ], $_[ 3 ], $_[ 4 ], $_[ 5 ], $_[ 6 ] );
}

sub write {

    aio_write( $_[ 1 ], $_[ 2 ], $_[ 3 ], $_[ 4 ], $_[ 5 ], $_[ 6 ] );
}

sub sendfile {

    aio_sendfile( $_[ 1 ], $_[ 2 ], $_[ 3 ], $_[ 4 ], $_[ 5 ] );
}

sub readahead {

    aio_readahead( $_[ 1 ], $_[ 2 ], $_[ 3 ], $_[ 4 ] );
}

sub stat {
    my ( $self, $file, $callback ) = @_;

    # TODO reftype
    # TODO stuff _ with stat cache
    return aio_stat( $self->_path_from_root( $file ), sub { $callback->( -e _ ? [ (CORE::stat( _ )) ] : undef ); } )
        unless ( ref( $file ) eq 'ARRAY' );

    # multi-stat
    my $list = [];
    return $callback->( $list ) unless ( @$file );

    my $tostat = [];
    foreach my $i ( 0 .. $#{$file} ) {
        # file path, index
        $tostat->[ $i ] = [ $self->_path_from_root( $file->[ $i ] ), $i ];
        $list->[ $i ] = [ $file->[ $i ] ];
    }

    my $grp = aio_group( $callback );
    # pass $list to the callback
    $grp->result( $list );
    limit $grp $self->{aio_max_group};
    # add files
    feed $grp sub {
        my $f = pop @$tostat or return;
        add $grp aio_stat $f->[ 0 ], sub {
            $_[ 0 ] and return;
            # list[ idx ] = [ path, stat ]
            $list->[ $f->[ 1 ] ]->[ 1 ] = [ (CORE::stat( _ )) ];
        };
    };

    return;
}

sub lstat {
    my ( $fh, $callback ) = @_;

    aio_lstat( $fh, sub { $callback->( [ (CORE::stat( _ )) ] ) } );
}

sub utime {
    my $self = shift;

    aio_utime( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ], $_[ 2 ] );
}

sub chown {
    my $self = shift;

    aio_chown( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ], $_[ 2 ] );
}

sub truncate {
    my $self = shift;

    aio_truncate( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ] );
}

sub chmod {
    my $self = shift;

    aio_chmod( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ] );
}

sub unlink {
    my $self = shift;

    aio_unlink( $self->_path_from_root( shift ), $_[ 0 ] );
}

sub mknod {
    my $self = shift;

    aio_mknod( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ], $_[ 2 ] );
}

sub link {
    my $self = shift;

    aio_link( $self->_path_from_root( shift ), $self->_path_from_root( shift ), $_[ 0 ] );
}

sub symlink {
    my $self = shift;

    aio_symlink( $self->_path_from_root( shift ), $self->_path_from_root( shift ), $_[ 0 ] );
}

sub readlink {
    my $self = shift;

    aio_readlink( $self->_path_from_root( shift ), $_[ 0 ] );
}

sub rename {
    my $self = shift;

    aio_rename( $self->_path_from_root( shift ), $self->_path_from_root( shift ), $_[ 0 ] );
}

sub mkdir {
    my $self = shift;

    aio_mkdir( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ] );
}

sub rmdir {
    my $self = shift;

    aio_rmdir( $self->_path_from_root( shift ), $_[ 0 ] );
}

sub readdir {
    my $self = shift;

    aio_readdir( $self->_path_from_root( shift ), $_[ 0 ] );
}

sub load {
    my $self = shift;

    aio_load( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ] );
}

sub copy {
    my $self = shift;

    my $src = $self->_path_from_root( shift );
    my $dest = $self->_path_from_root( shift );
    # aio won't take an ending slash
    $dest =~ s/\/$//;

    aio_copy( $src, $dest, $_[ 0 ] );
}

sub move {
    my $self = shift;

    my $src = $self->_path_from_root( shift );
    my $dest = $self->_path_from_root( shift );
    # aio won't take an ending slash
    $dest =~ s/\/$//;

    aio_move( $src, $dest, $_[ 0 ] );
}

sub scandir { 
    my $self = shift;

    aio_scandir( $self->_path_from_root( shift ), $_[ 0 ], $_[ 1 ] );
}

sub rmtree {
    my $self = shift;

    aio_rmtree( $self->_path_from_root( shift ), $_[ 0 ] );
}

sub fsync {

    aio_fsync( $_[ 1 ], $_[ 2 ] );
}

sub fdatasync {

    aio_fdatasync( $_[ 1 ], $_[ 2 ] );
}

1;

__END__

=pod

=head1 NAME

Filesys::Virtual::Async::Plain -  A plain non-blocking virtual filesystem

=head1 SYNOPSIS

use Filesys::Virtual::Async::Plain;

my $fs = Filesys::Virtual::Async::Plain->new(
    root => '/home/foo',
);

$fs->mkdir( '/bar', $mode, sub {
    if ( $_[0] ) {
        print "success\n";
    } else {
        print "failure:$!\n";
    }
});

=head1 DESCRIPTION

Filesys::Virtual::Async::Plain provides non-blocking access to virtual
filesystem rooted in a real filesystem.  It's like a chrooted filesytem

=head1 WARNING

This module is still in flux to an extent.  It will change.  I released this
module early due to demand.  If you'd like to suggest changes, please drop in
the irc channel #poe on irc.perl.org and speak with xantus[] or Apocalypse

=head1 OBJECT METHODS

=over 4

=item new( root => $path );

root is optional, and defaults to /.  root is prepended to all paths after
resolution

=item cwd()

Returns the current working directory (virtual)

=item root() or root( $path )

Gets or sets the root path

=back

=head1 CALLBACK METHODS

All of these work exactly like the L<IO::AIO> methods of the same name.  Use
L<IO::AIO> as a reference for these functions.  This module is mostly a wrapper
around L<IO::AIO>.  All paths passed to these functions are resolved for you, so
pass virtual paths, not the full path on disk as you would pass to aio

=over 4

=item dirlist( $path, $withstat, $callback )

Not an aio method, but a helper that will fetch a list of files in a path, and
optionally stat each file.  The callback is called with an array.  The first
element is the file name and the second param is an array ref of the return value
of io_stat() if requested.

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

L<Filesys::Virtual::Async>

L<http://xant.us/>

=head1 BUGS

Probably.  Report 'em:
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filesys-Virtual-Async-Plain>

=head1 AUTHOR

David W Davis E<lt>xantus@cpan.orgE<gt>

=head1 RATING

You can rate this this module at
L<http://cpanratings.perl.org/rate/?distribution=Filesys::Virtual::Async::Plain>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by David W Davis, All rights reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut

