package Filesys::Virtual::DAAP;
use strict;
use warnings;
use Net::DAAP::Client 0.4;
use Filesys::Virtual::Plain ();
use File::Temp qw( tempdir );
use IO::File;
use Scalar::Util qw( blessed );
use base qw( Filesys::Virtual Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( cwd root_path home_path host port _client _vfs _tmpdir ));
our $VERSION = '0.04';

=head1 NAME

Filesys::Virtual::DAAP - present a DAAP share as a VFS

=head1 SYNOPSIS

 use Filesys::Virtual::DAAP;
 my $fs = Filesys::Virtual::DAAP->new({
     host      => 'localhost',
     port      => 3689, # the default
     cwd       => '/',
     root_path => '/',
     home_path => '/home',
 });
 my @albums    = $fs->list("/Library");
 my @playlists = $fs->list("/Playlists");


=head1 DESCRIPTION

The module can be used to republish a DAAP share.  You'll probably
want to use Net::DAV::Server or POE::Component::Server::FTP to
re-export it in a browseable form.

=cut

# HACKY - mixin this from the ::Plain class, it only deals with the
# mapping of root_path, cwd, and home_path, so it should be safe
*_resolve_path   = \&Filesys::Virtual::Plain::_resolve_path;

sub new {
    my $ref = shift;
    my $self = $ref->SUPER::new(@_);
    $self->_tmpdir( tempdir( CLEANUP => 1 ) );

    $self->_client( Net::DAAP::Client->new( $self->host ) );
    push @{ $self->_client->{SONG_ATTRIBUTES} },
      qw( daap.songcompilation daap.songtracknumber daap.songtrackcount );
    $self->_client->{SERVER_PORT} = $self->port || 3689;
    $self->_client->connect;
    $self->_build_vfs;
    return $self;
}

sub _build_vfs {
    my $self = shift;
    my $daap = $self->_client;
    $self->_vfs( {} );
    for my $song (values %{ $daap->songs }) {
        bless $song, __PACKAGE__."::Song";
        $self->_vfs->{Library}
          { $self->_fs_safe(
              $song->{'daap.songcompilation'} ? 'Compilations'
                                              : $song->{'daap.songartist'}) }
          { $self->_fs_safe( $song->{'daap.songalbum'} || "Unknown album" ) }
          { $song->filename } = $song;
    }

    for my $playlist (values %{ $daap->playlists }) {
        my $i;
        for my $song (@{ $daap->playlist( $playlist->{'dmap.itemid'} ) } ) {
            next unless $song; # huh - how can this be false?  it is though.

            # clone the data from the Song object, only override the
            # daap.songtracknumber and the daap.songtrackcount, so the
            # cleverness in ::Song->filename for generating a filename
            # with the correct width prefix works
            $song = bless {
                %$song,
                'daap.songtracknumber' => ++$i,
                'daap.songtrackcount'  => $playlist->{'dmap.itemcount'},
            }, __PACKAGE__."::Song";
            $self->_vfs->{Playlists}
              { $self->_fs_safe( $playlist->{'dmap.itemname'} ) }
              { $song->filename } = $song;
        }
    }
    #print Dump $self->_vfs;
}

sub _get_leaf {
    my $self = shift;
    my $path = $self->_resolve_path( shift );
    my (undef, @chunks) = split m{/}, $path;
    my $walk = $self->_vfs;
    $walk = $walk->{$_} for @chunks;
    return $walk;
}

sub list {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    return unless $leaf;
    return blessed $leaf ? $leaf->filename : qw( . .. ), sort keys %{ $leaf };
}

sub list_details {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    return unless $leaf;

    return blessed $leaf ? $self->_ls_file( $leaf->filename => $leaf ) :
      map { $self->_ls_file( $_ => $leaf->{$_} ) } qw( . .. ), sort keys %{ $leaf };
}

sub _ls_file {
    my $self = shift;
    my ($name, $leaf) = @_;
    if (blessed $leaf) {
#                       drwxr-xr-x  46 richardc  richardc  1564  5 May 10:03 Applications
        return sprintf "-r--r--r--   1 richardc  richardc %8s 7 May 12:41 %s",
          $leaf->size, $leaf->filename;
    }
    else {
        return sprintf "drwxr-xr-x   3 richardc  richardc %8s 7 May 12:41 %s",
          1024, $name;
    }
}

sub chdir {
    my $self = shift;
    my $to   = $self->_resolve_path( shift );
    my $leaf = $self->_get_leaf( $to );
    return undef unless ref $leaf eq 'HASH';
    return $self->cwd( $to );
}


# well if ::Plain can't be bothered, we can't be bothered either
sub modtime { return (0, "") }

sub stat {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    return unless $leaf;
    my $blocksize = 1024;
    if (blessed $leaf) {
        # dev, ino, mode, nlink, uid, gid, rdev, size, atime, mtime, ctime, blksize, blocks
        return (0+$self, 0+$leaf, 0100444, 1, 0, 0, 0, $leaf->size,
                $leaf->atime, $leaf->mtime, $leaf->ctime,
                $blocksize, ($leaf->size / $blocksize) + 1);
    }
    else {
        return (0+$self, 0+$leaf, 042555, 1, 0, 0, 0, $blocksize,
                0, 0, 0, $blocksize, 1);
    }
}

sub size {
    my $self = shift;
    return ( $self->stat( shift ))[7];
}

sub test {
    my $self = shift;
    my $test = shift;
    my $leaf = $self->_get_leaf( shift );
    return '' unless $leaf;

    local $_ = $test;
    return 1  if /r/i;
    return '' if /w/i;
    return 1  if /x/i && !blessed $leaf;
    return '' if /x/i;
    return 1  if /o/i;

    return 1  if /e/;
    return '' if /z/;
    return $leaf->size if /s/ && blessed $leaf;
    return 1024 if /s/;

    return 1  if /f/ && blessed $leaf;
    return '' if /f/;
    return 1  if /d/ && !blessed $leaf;
    return '' if /[dpSbctugkT]/;
    return 1  if /B/;
    return 0  if /[MAC]/;
    die "Don't understand -$test";
}

# Don't touch our filez
sub chmod { 0 }
sub mkdir { 0 }
sub delete { 0 }
sub rmdir { 0 }

sub login { 1 }

sub open_read {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    $self->_client->save( $self->_tmpdir, $leaf->id );
    return IO::File->new( $self->_tmpdir . "/". $leaf->downloadname );
}

sub close_read {
    my $self = shift;
    my $fh = shift;
    close $fh;
    return 1;
}

sub open_write { return }
sub close_write { 0 }

sub _fs_safe {
    my $self = shift;
    my $file = shift;
    $file =~ s{/}{_}g;
    return $file;
}

package Filesys::Virtual::DAAP::Song;
sub id { $_[0]->{'dmap.itemid'} }

# what DAAP::Client will save it as
sub downloadname {
    my $self = shift;
    return $self->id . "." . $self->{'daap.songformat'};
}

sub tracknumber {
    my $self = shift;
    # twistedness - set the width based on the length of the maximum
    # value, ensures alpha-sorting
    return sprintf "%0".length($self->{'daap.songtrackcount'})."d",
      $self->{'daap.songtracknumber'};
}

sub filename {
    my $self = shift;
    my $name = $self->tracknumber. " " . $self->{'dmap.itemname'} .
      "." . $self->{'daap.songformat'};
    return Filesys::Virtual::DAAP->_fs_safe( $name );
}

sub size { $_[0]->{'daap.songsize'} }

sub atime { 0 }
sub mtime { 0 }
sub ctime { 0 }

1;

__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::DAAP::Client::Auth>, L<Net::DAV::Server>, L<POE::Component::Server::FTP>

=cut

