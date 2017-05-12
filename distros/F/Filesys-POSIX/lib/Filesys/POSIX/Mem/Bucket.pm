# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Mem::Bucket;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Bits::System;
use Filesys::POSIX::IO::Handle ();
use Filesys::POSIX::Error qw(throw);

use Fcntl;
use Carp       ();
use File::Temp ();

=head1 NAME

Filesys::POSIX::Mem::Bucket - Regular file I/O handle

=head1 DESCRIPTION

C<Filesys::POSIX::Mem::Bucket> provides an implementation of the interface in
L<Filesys::POSIX::IO::Handle> that allows access to the regular file data of a
file in a L<Filesys::POSIX::Mem> filesystem hierarchy.

Internally, the bucket can store up to a specified maximum number of bytes until
said data is flushed to a temporary file on disk, backed by L<File::Temp>.

=cut

our @ISA = ('Filesys::POSIX::IO::Handle');

my $DEFAULT_MAX = 16384;
my $DEFAULT_DIR = '/tmp';

sub new {
    my ( $class, %opts ) = @_;

    return bless {
        'fh'    => undef,
        'buf'   => '',
        'max'   => defined $opts{'max'} ? $opts{'max'} : $DEFAULT_MAX,
        'dir'   => defined $opts{'dir'} ? $opts{'dir'} : $DEFAULT_DIR,
        'inode' => $opts{'inode'},
        'size'  => 0,
        'pos'   => 0
    }, $class;
}

sub DESTROY {
    my ($self) = @_;

    close $self->{'fh'} if $self->{'fh'};

    if ( $self->{'file'} && -f $self->{'file'} ) {
        unlink $self->{'file'};
    }
}

sub open {
    my ( $self, $flags ) = @_;
    $flags ||= 0;

    throw &Errno::EBUSY if $self->{'fh'};

    $self->{'pos'} = 0;

    if ( $flags & $O_APPEND ) {
        $self->{'pos'} = $self->{'size'};
    }
    elsif ( $flags & ( $O_CREAT | $O_TRUNC ) ) {
        $self->{'size'} = 0;
        $self->{'inode'}->{'size'} = 0;

        undef $self->{'buf'};
        $self->{'buf'} = '';
    }

    if ( $self->{'file'} ) {
        my $fcntl_flags = Filesys::POSIX::Bits::System::convertFlagsToSystem($flags);

        sysopen( my $fh, $self->{'file'}, $fcntl_flags ) or Carp::confess("$!");

        $self->{'fh'} = $fh;
    }

    return $self;
}

sub _flush_to_disk {
    my ( $self, $len ) = @_;

    throw &Errno::EALREADY if $self->{'file'};

    my ( $fh, $file ) =
      eval { File::Temp::mkstemp("$self->{'dir'}/.bucket-XXXXXX") };

    Carp::confess("mkstemp() failure: $@") if $@;

    my $offset = 0;

    for ( my $left = $self->{'size'}; $left > 0; $left -= $len ) {
        my $wrlen = $left > $len ? $len : $left;

        syswrite( $fh, substr( $self->{'buf'}, $offset, $wrlen ), $wrlen );

        $offset += $wrlen;
    }

    @{$self}{qw(fh file)} = ( $fh, $file );
}

sub write {
    my ( $self, $buf, $len ) = @_;
    my $ret = 0;

    #
    # If the current file position, plus the length of the intended write
    # is to exceed the maximum memory bucket threshold, then dump the file
    # to disk if it hasn't already happened.
    #
    if ( $self->{'pos'} + $len > $self->{'max'} ) {
        $self->_flush_to_disk($len) unless $self->{'fh'};
    }

    if ( $self->{'fh'} ) {
        Carp::confess("Unable to write to disk bucket")
          unless fileno( $self->{'fh'} );
        $ret = syswrite( $self->{'fh'}, $buf );
    }
    else {
        if ( ( my $gap = $self->{'pos'} - $self->{'size'} ) > 0 ) {
            $self->{'buf'} .= "\x00" x $gap;
        }

        substr( $self->{'buf'}, $self->{'pos'}, $len ) =
          substr( $buf, 0, $len );
        $ret = $len;
    }

    $self->{'pos'}  += $ret;
    $self->{'size'} += $ret;

    if ( $self->{'pos'} > $self->{'size'} ) {
        $self->{'size'} = $self->{'pos'};
    }

    $self->{'inode'}->{'size'} = $self->{'size'};

    return $ret;
}

sub read {
    my $self = shift;
    my $len  = pop;
    my $ret  = 0;

    if ( $self->{'fh'} ) {
        Carp::confess("Unable to read bucket: $!")
          unless fileno( $self->{'fh'} );
        $ret = sysread( $self->{'fh'}, $_[0], $len );
    }
    else {
        my $pos =
          $self->{'pos'} > $self->{'size'} ? $self->{'size'} : $self->{'pos'};
        my $maxlen = $self->{'size'} - $pos;
        $len = $maxlen if $len > $maxlen;

        unless ($len) {
            $_[0] = '';
            return 0;
        }

        $_[0] = substr( $self->{'buf'}, $self->{'pos'}, $len );
        $ret = $len;
    }

    $self->{'pos'} += $ret;

    return $ret;
}

sub seek {
    my ( $self, $pos, $whence ) = @_;
    my $newpos;

    if ( $self->{'fh'} ) {
        $newpos = sysseek( $self->{'fh'}, $pos, $whence );
    }
    elsif ( $whence == $SEEK_SET ) {
        $newpos = $pos;
    }
    elsif ( $whence == $SEEK_CUR ) {
        $newpos = $self->{'pos'} + $pos;
    }
    elsif ( $whence == $SEEK_END ) {
        $newpos = $self->{'size'} + $pos;
    }
    else {
        throw &Errno::EINVAL;
    }

    return $self->{'pos'} = $newpos;
}

sub tell {
    my ($self) = @_;

    if ( $self->{'fh'} ) {
        return sysseek $self->{'fh'}, 0, 1;
    }

    return $self->{'pos'};
}

sub close {
    my ($self) = @_;

    if ( $self->{'fh'} ) {
        close $self->{'fh'};
        undef $self->{'fh'};
    }

    $self->{'pos'} = 0;
}

=head1 SEE ALSO

=over

=item L<Filesys::POSIX::IO::Handle>

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
