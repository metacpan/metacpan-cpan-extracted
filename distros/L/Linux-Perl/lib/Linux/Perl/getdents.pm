package Linux::Perl::getdents;

=encoding utf-8

=head1 NAME

Linux:Perl::getdents - read full directory information

=head1 SYNOPSIS

    #Platform-specific invocation uses e.g.:
    #   Linux::Perl::getdents::arm->getdents(...)

    my @entities = Linux::Perl::getdents->getdents( $filehandle, $buffer_size );

=head1 DESCRIPTION

This module provides support for the kernel-level logic to read directories.

Directories store more than just the node names that Perl’s C<readdir()>
returns; for example, they store the file type and node number. By calling
the kernel’s C<getdents> logic directly, you can get this
information without making additional system calls.

=cut

use strict;
use warnings;

use parent qw( Linux::Perl::Base::BitsTest );

use Linux::Perl;
use Linux::Perl::Endian;
use Linux::Perl::EasyPack;

use constant {
    DT_UNKNOWN => 0,
    DT_FIFO => 1,
    DT_CHR => 2,
    DT_DIR => 4,
    DT_BLK => 6,
    DT_REG => 8,
    DT_LNK => 10,
    DT_SOCK => 12,
    DT_WHT => 14,
};

my ($lde64_keys, $lde64_pack, $lde64_start_size);
BEGIN {
    ($lde64_keys, $lde64_pack) = Linux::Perl::EasyPack::split_pack_list(
        ino => __PACKAGE__->_PACK_u64(), #ino64_t
        off => __PACKAGE__->_PACK_u64(), #off64_t
        reclen => 'S!',
        type => 'C',
        #name => 'a*',
    );

    $lde64_start_size = length pack $lde64_pack;
}

=head1 METHODS

In addition to the following, this module exposes the constants
C<DT_UNKNOWN()> et al. (cf. C<man 2 getdents>)

=head2 @ENTRIES = I<CLASS>->getdents( $FILEHANDLE_OR_FD, $READ_SIZE )

Reads from the given $FILEHANDLE_OR_FD using a buffer of $READ_SIZE bytes.
There’s no good way to know how many @ENTRIES you can receive given the
$READ_SIZE, unfortunately.

The return is a list of hash references; each hash contains the keys
C<ino>, C<off>, C<type>, and C<name>. These correspond with the relevant
parts of struct C<linux_dirent64> (cf. C<man 2 getdents>).

(In scalar context, this returns the number of hash references that would
be returned in list context.)

For now, this is implemented via the C<getdents64> system call.

B<NOTE:> Perl 5.20 and earlier doesn’t understand C<fileno()> on a directory
handle, so to use this function you’ll need to pass the file descriptor rather
than the handle. (To get the file descriptor, you can parse F</proc/$$/fd>
for the symlink that refers to the directory’s path. See this module’s tests
for an implementation of this.)

=cut

sub getdents {
    my ($class, $fh_or_fileno, $bufsize) = @_;

    if (!$class->can('NR_getdents64')) {
        require Linux::Perl::ArchLoader;
        $class = Linux::Perl::ArchLoader::get_arch_module($class);
    }

    my $buf = "\0" x $bufsize;

    my $fileno;

    if ( ref $fh_or_fileno ) {
        $fileno = fileno($fh_or_fileno);

        if (!defined $fileno) {
            die "Filehandle ($fh_or_fileno) has no underlying file descriptor!";
        }
    }
    else {
        $fileno = $fh_or_fileno;

        if (!defined $fileno) {
            die "Neither a filehandle nor a file descriptor was given!";
        }
    }

    my $bytes = Linux::Perl::call(
        0 + $class->NR_getdents64(),
        0 + $fileno,
        $buf,
        0 + $bufsize,
    );

    my @structs;
    while ($bytes > 0) {
        my %struct;
        @struct{ @$lde64_keys } = unpack $lde64_pack, substr( $buf, 0, $lde64_start_size, q<> );

        ( $struct{'name'} = substr( $buf, 0, $struct{'reclen'} - $lde64_start_size, q<> ) ) =~ tr<\0><>d;

        push @structs, \%struct;

        $bytes -= delete $struct{'reclen'};
    }

    return @structs;
}

1;
