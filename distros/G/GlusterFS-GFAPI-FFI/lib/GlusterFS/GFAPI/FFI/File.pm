package GlusterFS::GFAPI::FFI::File;

BEGIN
{
    our $AUTHOR  = 'cpan:potatogim';
    our $VERSION = '0.4';
}

use strict;
use warnings;
use utf8;

use Moo;
use GlusterFS::GFAPI::FFI;
use GlusterFS::GFAPI::FFI::Util qw/libgfapi_soname/;
use Carp;


#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'fd' =>
(
    is => 'rwp',
);

has 'originalpath' =>
(
    is => 'rwp',
);

has 'mode' =>
(
    is => 'rwp',
);


#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->_set_fd($args->{fd});
    $self->_set_originalpath($args->{path} // undef);
    $self->_set_mode($args->{mode} // undef);

    $self->_validate_init();

    return;
}

sub DEMOLISH
{
    my $self = shift;

    if ($self->fd)
    {
        $self->close();
    }

    return;
}


#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub _validate_init
{
    my $self = shift;

    if (!defined($self->fd))
    {
        confess('I/O operation on invalid fd');
    }
    elsif ($self->fd !~ m/^\d+$/)
    {
        confess('I/O operation on invalid fd');
    }
}

sub fileno
{
    my $self = shift;
    my %args = @_;

    return $self->fd;
}

sub name
{
    my $self = shift;
    my %args = @_;

    return $self->originalpath;
}

sub closed
{
    my $self = shift;
    my %args = @_;

    return defined($self->fd) ? 0 : 1;
}

sub close
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_close($self->fd);

    if ($retval < 0)
    {
        confess($!);
    }

    $self->_set_fd(undef);

    return $retval;
}

sub discard
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_discard($self->fd, $args{offset}, $args{length});

    if ($retval < 0)
    {
        confess(sprintf('glfs_discard(%s, %d, %d) failed: %s'
                    , $self->fd
                    , $args{offset}
                    , $args{length}
                    , $!));
    }

    return $retval;
}

sub dup
{
    my $self = shift;
    my %args = @_;

    my $dupfd = GlusterFS::GFAPI::FFI::glfs_dup($self->fd);

    if (!defined($dupfd))
    {
        confess($!);
    }

    return __PACKAGE__->new(fd => $dupfd, path => $self->originalpath);
}

sub fallocate
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_fallocate($self->fd, $args{mode}, $args{offset}, $args{length});

    if ($retval < 0)
    {
        confess(sprintf('glfs_fallocate(%s, %s, %s, %s) failed: %s'
                , $self->fd
                , $args{mode} ? sprintf('0%o', $args{mode}) : '0'
                , $args{offset}
                , $args{length}
                , $!));
    }

    return $retval;
}

sub fchmod
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_fchmod($self->fd, $args{mode});

    if ($retval < 0)
    {
        confess(sprintf("glfs_fchmod(%s, %s) failed: %s"
                    , $self->fd
                    , $args{mode} ? sprintf('0%o', $args{mode}) : '0'
                    , $!));
    }

    return $retval;
}

sub fchown
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_fchown($self->fd, $args{uid}, $args{gid});

    if ($retval < 0)
    {
        confess("glfs_fchown(${\$self->fd}, $args{uid}, $args{gid}) failed: $!");
    }

    return $retval;
}

sub fdatasync
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_fdatasync($self->fd);

    if ($retval < 0)
    {
        confess("glfs_fdatasync(${\$self->fd}) failed: $!");
    }

    return $retval;
}

sub fgetsize
{
    my $self = shift;
    my %args = @_;

    return $self->fstat()->st_size;
}

sub fgetxattr
{
    my $self = shift;
    my %args = @_;

    $args{size} = 0 if (!defined($args{size}));

    if ($args{size} == 0)
    {
        $args{size} = GlusterFS::GFAPI::FFI::glfs_fgetxattr($self->fd, $args{key}, undef, $args{size});

        if ($args{size} < 0)
        {
            confess($!);
        }
    }

    my $buf    = "\0" x $args{size};
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_fgetxattr(
                    $self->fd,
                    $args{key},
                    unpack('L!', $ptr),
                    $args{size});

    if ($retval < 0)
    {
        confess($!);
    }

    return substr($buf, 0, $retval);
}

sub flistxattr
{
    my $self = shift;
    my %args = @_;

    $args{size} = 0 if (!defined($args{size}));

    if ($args{size} == 0)
    {
        $args{size} = GlusterFS::GFAPI::FFI::glfs_flistxattr($self->fd, undef, 0);

        if ($args{size} < 0)
        {
            confess($!);
        }
    }

    my $buf    = "\0" x $args{size};
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_flistxattr(
                    $self->fd,
                    unpack('L!', $ptr),
                    $args{size});

    if ($retval < 0)
    {
        confess($!);
    }

    return sort { $a cmp $b; } split("\0", $buf);
}

sub fsetxattr
{
    my $self = shift;
    my %args = @_;

    $args{flags} = 0 if (!defined($args{flags}));

    my $retval = GlusterFS::GFAPI::FFI::glfs_fsetxattr(
                    $self->fd,
                    $args{key},
                    $args{value},
                    length($args{value}),
                    $args{flags});

    if ($retval < 0)
    {
        confess($!);
    }

    return $retval;
}

sub fremovexattr
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_fremovexattr($self->fd, $args{key});

    if ($retval < 0)
    {
        confess($!);
    }

    return $retval;
}

sub fstat
{
    my $self = shift;
    my %args = @_;

    my $stat   = GlusterFS::GFAPI::FFI::Stat->new();
    my $retval = GlusterFS::GFAPI::FFI::glfs_fstat($self->fd, $stat);

    if ($retval < 0)
    {
        confess("glfs_fstat(${\$self->fd}, $stat) failed: $!");
    }

    return $stat;
}

sub fsync
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_fsync($self->fd);

    if ($retval < 0)
    {
        confess("glfs_fsync(${\$self->fd}) failed: $!");
    }

    return $retval;
}

sub ftruncate
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_ftruncate($self->fd, $args{length});

    if ($retval < 0)
    {
        confess($!);
    }

    return $retval;
}

sub lseek
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_lseek($self->fd, $args{pos}, $args{how});

    if ($retval < 0)
    {
        confess($!);
    }

    return $retval;
}

sub read
{
    my $self = shift;
    my %args = @_;

    $args{size} = -1 if (!defined($args{size}));

    if ($args{size} < 0)
    {
        $args{size} = $self->fgetsize();
    }

    my $buf    = "\0" x $args{size};
    my $ptr    = pack('P', $buf);
    my $retval = GlusterFS::GFAPI::FFI::glfs_read(
                    $self->fd,
                    unpack('L!', $ptr),
                    $args{size},
                    0);

    if ($retval > 0)
    {
        return substr($buf, 0, $retval);
    }
    elsif ($retval < 0)
    {
        confess("glfs_read(${\$self->fd}, \$buf, $args{size}, 0) failed: $!");
    }

    return $retval;
}

sub readinto
{
    my $self = shift;
    my %args = @_;

    my $ptr    = pack('P', $args{buf});
    my $retval = GlusterFS::GFAPI::FFI::glfs_read(
                    $self->fd,
                    unpack('L!', $ptr),
                    length($args{buf}),
                    0);

    if ($retval < 0)
    {
        confess(sprintf('glfs_read(%s, %s, %d, 0) failed: %s'
                    , $self->fd
                    , '$buf'
                    , length($args{buf})
                    , 0));
    }

    return $retval;
}

sub write
{
    my $self = shift;
    my %args = @_;

    $args{flags} = 0 if (!defined($args{flags}));

    my $ptr    = pack('P', $args{data});
    my $retval = GlusterFS::GFAPI::FFI::glfs_write(
                    $self->fd,
                    unpack('L!', $ptr),
                    length($args{data}),
                    $args{flags});

    if ($retval < 0)
    {
        confess(sprintf('glfs_write(%s, %s, %d, %s) failed: %s'
                    , $self->fd
                    , '$buf'
                    , length($args{data})
                    , !$args{flags} ? '0' : sprintf('0%o', $args{flags})
                    , $!));
    }

    return $retval;
}

sub zerofill
{
    my $self = shift;
    my %args = @_;

    my $retval = GlusterFS::GFAPI::FFI::glfs_zerofill($self->fd, $args{offset}, $args{length});

    if ($retval < 0)
    {
        confess($!);
    }

    return $retval;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

GlusterFS::GFAPI::FFI::File - GFAPI File API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 fd

=head2 originalpath

=head2 mode

=head1 CONSTRUCTOR

=head2 new

=head3 options

=head1 METHODS

=head2 fileno

Return the internal file descriptor (glfd) that is used by the underlying implementation to request I/O operations.

=head2 mode

The I/O mode for the file. If the file was created using the C<Volume->fopen()> function, this will be the value of the mode parameter. This is a read-only attribute.

=head2 name

If the file object was created using C<Volume->fopen()>, the name of the file.

=head2 closed

Bool indicating the current state of the file object. This is a read-only attribute; the C<close()> method changes the value.

=head2 close

Close the file. A closed file cannot be read or written any more.

=head2 discard

This is similar to C<UNMAP> command that is used to return the unused/freed blocks back to the storage system.
In this implementation, fallocate with C<FALLOC_FL_PUNCH_HOLE> is used to eventually release the blocks to the filesystem.
If the brick has been mounted with 'C<-o discard>' option, then the discard request will eventually reach the SCSI storage if the storage device supports C<UNMAP>.

=head2 dup

Return a duplicate of File object. This duplicate File class instance encapsulates a duplicate glfd obtained by invoking C<glfs_dup()>.

=head2 fallocate

This is a Linux-specific sys call, unlike posix_fallocate()

Allows the caller to directly manipulate the allocated disk space for the file for the byte range starting at offset and continuing for length bytes.

=head2 fchmod

Change this file's mode

=head2 fchown

Change this file's owner and group id

=head2 fdatasync

Flush buffer cache pages pertaining to data, but not the ones pertaining to metadata.

=head2 fgetsize

Return the size of a file, as reported by C<fstat()>

=head2 fgetxattr

Retrieve the value of the extended attribute identified by key for the file.

=head3 parameters

=over

=item C<key>

Key of extended attribute

=item C<size>

If size is specified as zero, we first determine the size of xattr and then allocate a buffer accordingly.
If size is non-zero, it is assumed the caller knows the size of xattr.

=back

=head3 returns

Value of extended attribute corresponding to key specified.

=head2 flistxattr

Retrieve list of extended attributes for the file.

=head3 parameters

=over

=item C<size>

If size is specified as zero, we first determine the size of list and then allocate a buffer accordingly.
If size is non-zero, it is assumed the caller knows the size of the list.

=back

=head3 returns

List of extended attributes.

=head2 fsetxattr

Set extended attribute of file.

=head3 parameters

=over

=item C<key>

The key of extended attribute.

=item C<key>

The valiue of extended attribute.

=item C<key>

Possible values are 0 (default), 1 and 2.

If 0 - xattr will be created if it does not exist, or the value will be replaced if the xattr exists.
If 1 - it performs a pure create, which fails if the named attribute already exists.
If 2 - it performs a pure replace operation, which fails if the named attribute does not already exist.

=back

=head2 fremovexattr

Remove a extended attribute of the file.

=head3 parameters

=over

=item C<key>

The key of extended attribute.

=back

=head2 fstat

Returns Stat object for this file.

=head3 returns

Returns the stat information of the file.

=head2 fsync

Flush buffer cache pages pertaining to data and metadata.

=head2 ftruncate

Truncated the file to a size of length bytes.

If the file previously was larger than this size, the extra data is lost.

If the file previously was shorter, it is extended, and the extended part reads as null bytes.

=head3 parameters

=over

=item C<length>

Length to truncate the file to in bytes.

=back

=head2 lseek

Set the read/write offset position of this file.

The new position is defined by C<pos> relative to C<how>

=head3 parameters

=over

=item C<pos>

sets new offset position according to 'how'

=item C<how>

C<SEEK_SET> - sets offset position C<pos> bytes relative to beginning of file.
C<SEEK_CUR> - the position is set relative to the current position.
C<SEEK_END> - sets the position relative to the end of the file.

=back

=head3 returns

the new offset position

=head2 read

Read at most size bytes from the file.

=head3 parameters

=over

=item C<size>

length of read buffer. If less than 0, then whole file is read. Default is -1.

=back

=head3 returns

buffer of C<size> length

=head2 readinto

Read up to C<len(buf)> bytes into C<buf> which must be a bytearray.
This method is useful when you have to read a large file over multiple read calls.
While C<read()> allocates a buffer every time it's invoked, C<readinto()> copies data to an already allocated buffer passed to it.

=head3 parameters

=over

=item C<buf>

=back

=head3 returns

the number of bytes read (0 for EOF).

=head2 write

Write data to the file.

=head3 parameters

=over

=item C<data>

The data to be written to file.

=back

=head3 returns

The size in bytes actually written

=head2 zerofill

Fill C<length> number of bytes with zeroes starting from C<offset>.

=head3 parameters

=over

=item C<offset>

Start at offset location

=item C<length>

Size/length in bytes

=back

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright 2017-2018 by Ji-Hyeon Gim.

This is free software; you can redistribute it and/or modify it under the same terms as the GPLv2/LGPLv3.

=cut

