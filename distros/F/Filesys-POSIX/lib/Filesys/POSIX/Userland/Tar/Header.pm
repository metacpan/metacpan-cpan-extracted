# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Userland::Tar::Header;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Path ();

use Carp ();

our $BLOCK_SIZE = 512;

my %TYPES = (
    0 => $S_IFREG,
    2 => $S_IFLNK,
    3 => $S_IFCHR,
    4 => $S_IFBLK,
    5 => $S_IFDIR,
    6 => $S_IFIFO
);

sub inode_linktype {
    my ($inode) = @_;

    foreach ( keys %TYPES ) {
        return $_ if ( $inode->{'mode'} & $S_IFMT ) == $TYPES{$_};
    }

    return 0;
}

sub from_inode {
    my ( $class, $inode, $path ) = @_;

    my $parts     = Filesys::POSIX::Path->new($path);
    my $cleanpath = $parts->full;
    $cleanpath .= '/' if $inode->dir;

    my $path_components = split_path_components( $parts, $inode );
    my $size = $inode->file ? $inode->{'size'} : 0;

    my $major = 0;
    my $minor = 0;

    if ( $inode->char || $inode->block ) {
        $major = $inode->major;
        $minor = $inode->minor;
    }

    return bless {
        'path'      => $cleanpath,
        'prefix'    => $path_components->{'prefix'},
        'suffix'    => $path_components->{'suffix'},
        'truncated' => $path_components->{'truncated'},
        'mode'      => $inode->{'mode'},
        'uid'       => $inode->{'uid'},
        'gid'       => $inode->{'gid'},
        'size'      => $size,
        'mtime'     => $inode->{'mtime'},
        'linktype'  => inode_linktype($inode),
        'linkdest'  => $inode->link ? $inode->readlink : '',
        'user'      => '',
        'group'     => '',
        'major'     => $major,
        'minor'     => $minor
    }, $class;
}

sub decode {
    my ( $class, $block ) = @_;

    my $suffix = read_str( $block, 0,   100 );
    my $prefix = read_str( $block, 345, 155 );
    my $checksum = read_oct( $block, 148, 8 );

    validate_block( $block, $checksum );

    return bless {
        'suffix'   => $suffix,
        'mode'     => read_oct( $block, 100, 8 ),
        'uid'      => read_oct( $block, 108, 8 ),
        'gid'      => read_oct( $block, 116, 8 ),
        'size'     => read_oct( $block, 124, 12 ),
        'mtime'    => read_oct( $block, 136, 12 ),
        'linktype' => read_oct( $block, 156, 1 ),
        'linkdest' => read_str( $block, 157, 100 ),
        'user'     => read_str( $block, 265, 32 ),
        'group'    => read_str( $block, 297, 32 ),
        'major'    => read_oct( $block, 329, 8 ),
        'minor'    => read_oct( $block, 337, 8 ),
        'prefix'   => $prefix
    }, $class;
}

sub encode_longlink {
    my ($self) = @_;

    my $pathlen = length $self->{'path'};

    my $longlink_header = bless {
        'prefix'   => '',
        'suffix'   => '././@LongLink',
        'mode'     => 0,
        'uid'      => 0,
        'gid'      => 0,
        'size'     => $pathlen,
        'mtime'    => 0,
        'linktype' => 'L',
        'linkdest' => '',
        'user'     => '',
        'group'    => '',
        'major'    => 0,
        'minor'    => 0
      },
      ref $self;

    my $path_blocks = "\x00" x ( $pathlen + $BLOCK_SIZE - ( $pathlen % $BLOCK_SIZE ) );
    substr( $path_blocks, 0, $pathlen ) = $self->{'path'};

    return $longlink_header->encode . $path_blocks;
}

sub _compute_posix_header {
    my ( $self, $key, $value ) = @_;
    my $header = " $key=$value\n";
    my $len    = length $header;
    my $hdrlen = length($len) + $len;
    my $curlen = length($hdrlen);

    # The length field includes everything up to and including the newline and
    # the length field itself.  Compute the proper value if adding the length
    # would push us to a larger number of digits.
    $hdrlen = $curlen + $len if $curlen > length($len);

    return "$hdrlen$header";
}

sub encode_posix {
    my ($self) = @_;

    my $linklen = length $self->{'linkdest'};
    my $encoded = $self->_compute_posix_header( 'path', $self->{'path'} );
    $encoded .= $self->_compute_posix_header( 'linkpath', $self->{'linkdest'} ) if $linklen;

    my $encodedlen = length $encoded;

    my $posix_header = bless {
        'prefix'   => "./PaxHeaders.$$",
        'suffix'   => substr( $self->{'path'}, 0, 100 ),
        'mode'     => 0,
        'uid'      => 0,
        'gid'      => 0,
        'size'     => $encodedlen,
        'mtime'    => 0,
        'linktype' => 'x',
        'linkdest' => '',
        'user'     => '',
        'group'    => '',
        'major'    => 0,
        'minor'    => 0
      },
      ref $self;

    my $path_blocks = "\x00" x ( $encodedlen + $BLOCK_SIZE - ( $encodedlen % $BLOCK_SIZE ) );
    substr( $path_blocks, 0, $encodedlen ) = $encoded;

    return $posix_header->encode . $path_blocks;
}

sub encode {
    my ($self) = @_;
    my $block = "\x00" x $BLOCK_SIZE;

    write_str( $block, 0, 100, $self->{'suffix'} );
    write_oct( $block, 100, 8,  $self->{'mode'} & $S_IPERM, 7 );
    write_oct( $block, 108, 8,  $self->{'uid'},             7 );
    write_oct( $block, 116, 8,  $self->{'gid'},             7 );
    write_oct( $block, 124, 12, $self->{'size'},            11 );
    write_oct( $block, 136, 12, $self->{'mtime'},           11 );
    write_str( $block, 148, 8, '        ' );

    if ( $self->{'linktype'} =~ /^[0-9]$/ ) {
        write_oct( $block, 156, 1, $self->{'linktype'}, 1 );
    }
    else {
        write_str( $block, 156, 1, $self->{'linktype'} );
    }

    write_str( $block, 157, 100, $self->{'linkdest'} );
    write_str( $block, 257, 6,   'ustar' );
    write_str( $block, 263, 2,   '00' );
    write_str( $block, 265, 32,  $self->{'user'} );
    write_str( $block, 297, 32,  $self->{'group'} );

    if ( $self->{'major'} || $self->{'minor'} ) {
        write_oct( $block, 329, 8, $self->{'major'}, 7 );
        write_oct( $block, 337, 8, $self->{'minor'}, 7 );
    }

    write_str( $block, 345, 155, $self->{'prefix'} );

    my $checksum = checksum($block);

    write_oct( $block, 148, 8, $checksum, 7 );

    return $block;
}

sub split_path_components {
    my ( $parts, $inode ) = @_;

    my $truncated = 0;

    $parts->[-1] .= '/' if $inode->dir;

    my $got = 0;
    my ( @prefix_items, @suffix_items );

    while ( @{$parts} ) {
        my $item = pop @{$parts};
        my $len  = length $item;

        #
        # If the first item found is greater than 100 characters in length,
        # truncate it so that it may fit in the standard tar path header field.
        #
        if ( $got == 0 && $len > 100 ) {
            my $truncated_len = $inode->dir ? 99 : 100;

            $item = substr( $item, 0, $truncated_len );
            $item .= '/' if $inode->dir;

            $len       = 100;
            $truncated = 1;
        }

        $got++ if $got;
        $got += $len;

        if ( $got <= 100 ) {
            push @suffix_items, $item;
        }
        elsif ( $got > 100 ) {
            push @prefix_items, $item;
        }
    }

    my $prefix = join( '/', reverse @prefix_items );
    my $suffix = join( '/', reverse @suffix_items );

    if ( length($prefix) > 155 ) {
        $prefix = substr( $prefix, 0, 155 );
        $truncated = 1;
    }

    return {
        'prefix'    => $prefix,
        'suffix'    => $suffix,
        'truncated' => $truncated
    };
}

sub read_str {
    my ( $block, $offset, $len ) = @_;
    my $template = "Z$len";

    return unpack( $template, substr( $block, $offset, $len ) );
}

sub write_str {
    my ( $block, $offset, $len, $string ) = @_;

    if ( length($string) == $len ) {
        substr( $_[0], $offset, $len ) = $string;
    }
    else {
        substr( $_[0], $offset, $len ) = pack( "Z$len", $string );
    }

    return;
}

sub read_oct {
    my ( $block, $offset, $len ) = @_;
    my $template = "Z$len";

    return oct( unpack( $template, substr( $block, $offset, $len ) ) );
}

sub write_oct {
    my ( $block, $offset, $len, $value, $digits ) = @_;
    my $string     = sprintf( "%.${digits}o", $value );
    my $sub_offset = length($string) - $digits;
    my $substring  = substr( $string, $sub_offset, $digits );

    if ( $len == $digits ) {
        substr( $_[0], $offset, $len ) = $substring;
    }
    else {
        substr( $_[0], $offset, $len ) = pack( "Z$len", $substring );
    }

    return;
}

sub checksum {
    my ($block) = @_;
    my $sum = 0;

    foreach ( unpack 'C*', $block ) {
        $sum += $_;
    }

    return $sum;
}

sub validate_block {
    my ( $block, $checksum ) = @_;
    my $copy = "$block";

    write_str( $block, 148, 8, ' ' x 8 );

    my $calculated_checksum = checksum($copy);

    Carp::confess('Invalid block') unless $calculated_checksum == $checksum;

    return;
}

sub file {
    my ($self) = @_;

    return $TYPES{ $self->{'linktype'} } == $S_IFREG;
}

sub link {
    my ($self) = @_;

    return $self->{'linktype'} == 1;
}

sub symlink {
    my ($self) = @_;

    return $TYPES{ $self->{'linktype'} } == $S_IFLNK;
}

sub char {
    my ($self) = @_;

    return $TYPES{ $self->{'linktype'} } == $S_IFCHR;
}

sub block {
    my ($self) = @_;

    return $TYPES{ $self->{'linktype'} } == $S_IFBLK;
}

sub dir {
    my ($self) = @_;

    return $TYPES{ $self->{'linktype'} } == $S_IFDIR;
}

sub fifo {
    my ($self) = @_;

    return $TYPES{ $self->{'linktype'} } == $S_IFIFO;
}

sub contig {
    my ($self) = @_;

    return $self->{'linktype'} == 7;
}

1;
