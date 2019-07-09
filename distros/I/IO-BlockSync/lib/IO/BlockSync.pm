package IO::BlockSync;

# Basic
use 5.010;
use strict;
use warnings FATAL => 'all';

# Build in
use Carp;
use Fcntl qw(:DEFAULT :seek);
use POSIX qw(ceil);
use Scalar::Util qw(reftype);

# CPAN
use Log::Log4perl;
use Log::Log4perl::Level;
use Moo;
use Try::Tiny;

# These two come last - in that order
use namespace::clean;
use Exporter qw(import);

################################################################

# Moo roles to implement
with('MooseX::Log::Log4perl');

# Make sure log4perl doesn't come with errors
if ( not Log::Log4perl->initialized() ) {
    Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('OFF') );
}

################################################################

=head1 NAME

IO::BlockSync - Syncronize changed blocks

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

################################################################

=head1 SYNOPSIS

BlockSync can some of the same stuff that bigsync (by Egor Egorov) can
- it's just written in perl.

BlockSync copies data from source file to destination file (can be a block
device) and calculates checksum on each block it copies.
On all runs after the first only the changed blocks will be copied.

    use IO::BlockSync;

    # OOP way
    my $bs = IO::BlockSync->new(
        src => '/path/to/source/file',
        dst => '/path/to/destination/file',
        chk => '/path/to/chk/file',
    );
    $bs->run;

    # Non OOP way
    BlockSync(
        src => '/path/to/source/file',
        dst => '/path/to/destination/file',
        chk => '/path/to/chk/file',
    );

=cut

################################################################

=head1 INSTALLATION

Look in C<README.pod>

Can also be found on
L<GitHub|https://github.com/thordreier/perl-IO-BlockSync/blob/master/README.pod>
or L<meta::cpan|https://metacpan.org/pod/distribution/IO-BlockSync/README.pod>

=cut

################################################################

=head1 EXPORT

=cut

our @EXPORT = qw(BlockSync);

################################################################

=head2 BlockSync

Run BlockSync non-object-oriented

=cut

sub BlockSync {
    return __PACKAGE__->new(@_)->run;
}

################################################################

=head1 ATTRIBUTES

=cut

################################################################

=head2 src

Path to source file.

mandatory - string (containing path) or filehandle

=cut

has 'src' => (
    is       => 'ro',
    required => 1,
);

################################################################

=head2 dst

Destination file. If not set, then only checksum file will be updated.

optional - string (containing path) or filehandle

=cut

has 'dst' => ( is => 'ro', );

################################################################

=head2 chk

Path to checksum file.

mandatory - string (containing path) or filehandle

=cut

has 'chk' => (
    is       => 'ro',
    required => 1,
);

################################################################

=head2 bs

Block size to use in bytes.

optional - integer - defaults to 1_048_576 B (1 MB)

=cut

has 'bs' => (
    is      => 'ro',
    default => 1_048_576,
);

################################################################

=head2 hash

Sub that retrurn hashed data.

optional - sub - defaults to sub that return MD5 hash followed by newline

=cut

has 'hash' => (
    is      => 'ro',
    default => sub {
        require Digest::MD5;
        sub {
            Digest::MD5::md5_hex(shift) . "\n";
        }
    },
);

################################################################

=head2 sparse

Seek in dst file, instead of writing blocks only containing \0

optional - boolean - defaults to 0 (false)

=cut

has 'sparse' => (
    is      => 'ro',
    default => 0,
);

################################################################

=head2 truncate

Truncate the destination file to same size as source file. Does not work on block devices. Will only be tried if C<data> has default value (whole file is copied).

optional - boolean - defaults to 0 (false)

=cut

has 'truncate' => (
    is      => 'ro',
    default => 0,
);

################################################################

=head2 data

List of areas (in bytes) inside the source file that should be looked at.
Usefull if you know excactly which blocks in src that could have changed.

data => [
    {start => 0, end => 9999},
    {start => 88888, end => 777777},
]

optional - array of hashes - defaults to "whole file"

=cut

has 'data' => (
    is      => 'ro',
    default => sub {
        [
            {
                start => 0,
                end   => 0
            }
        ]
    },
);

################################################################

=head2 status

Sub that will be run everytime a block has been read (and written).

optional - sub - default to sub doing nothing

=cut

has 'status' => (
    is      => 'ro',
    default => sub {
        sub { }
    },
);

################################################################

=head1 METHODS

=cut

################################################################

=head2 run

This is the method that starts copying data.

=cut

sub run {    ## no critic (Subroutines::ProhibitExcessComplexity)
    my $self = shift;

    my ( $srcFh, $srcClose, $dstFh, $dstClose, $chkFh, $chkClose );

    try {
        # Get file handles for source, destination and checksum files
        $srcFh = $self->_getFh( 'src', $self->src, \$srcClose, O_RDONLY );
        $chkFh =
          $self->_getFh( 'chk', $self->chk, \$chkClose, O_RDWR | O_CREAT );
        if ( $self->dst ) {
            $dstFh = $self->_getFh( 'dst', $self->dst, \$dstClose,
                O_WRONLY | O_CREAT );
        }
        else {
            $self->logger->debug('No dst file, only calculating checksums');
        }

        # Calculate hash for a block only containing ASCII 0
        my $nullHash = &{ $self->hash }( "\0" x $self->bs );

        # Get number of bytes that a hash takes up
        my $hashSize = length($nullHash);

        my $srcSeek;

        # Loop through "areas" that should be copied
        # Default i one area containing the whole source file
        foreach my $dataBlocks ( @{ $self->data } ) {

            # Start and end of this "area" (default is $start=0, $end=0)
            my $start = $dataBlocks->{start};
            my $end   = $dataBlocks->{end};

            $self->logger->debug(
                "Going to process data from <$start> to <$end>");

            # Seek to $start
            # (or the beginning of the block that $start is in,
            # if $start is not aligned with bs)
            $srcSeek = int( $start / $self->bs ) * $self->bs;
            sysseek( $srcFh, $srcSeek, SEEK_SET )
              || $self->logger->logcroak(
                "Cannot seek to block <$srcSeek> in src file");

            # Just die! Muhahaha. Or not
            my $die = 0;

            # Can be either sparse, new, unchanged or changed
            my $status;

            # Read block from source
            while ( my $srcReadSize = sysread( $srcFh, my $data, $self->bs ) ) {

                # It's ok to read a block smaller than bs if it's the last
                # block. But it's not ok if it's not the last.
                if ($die) {
                    croak 'not reading full block';
                }
                $die = $srcReadSize != $self->bs;

                # $block = block number in source with the specified block size
                my $block = $srcSeek / $self->bs;

                # We start by assuming that we should write to dst
                # - if dst is set (= we are not just calculating checksum)
                my $writeData = 1 && $dstFh;

                # We start be assuming that we should write checksum to chk
                my $writeHash = 1;

                # Calculate hash for data read from src
                my $newHash = &{ $self->hash }($data);

                # Get old hash for the same block
                sysseek( $chkFh, $block * $hashSize, SEEK_SET )
                  || $self->logger->logcroak('Cannot seek in chk file');
                my $oldHashSize = sysread( $chkFh, my $oldHash, $hashSize );

                # Test source against checksum
                if ( $oldHashSize != $hashSize || $oldHash eq "\0" x $hashSize )
                {
                    if ( $self->sparse && $newHash eq $nullHash ) {

                        # Sparse is only for new blocks
                        # Blocks that have been nulled out in source will
                        # also get nulled out in destination
                        $status    = 'sparse';
                        $writeData = 0;
                    }
                    else {
                        $status = 'new';
                    }
                }
                elsif ( $newHash eq $oldHash ) {
                    $status    = 'unchanged';
                    $writeData = 0;
                    $writeHash = 0;
                }
                else {
                    $status = 'changed';
                }

                # Write data to destination
                if ($writeData) {
                    sysseek( $dstFh, $srcSeek, SEEK_SET )
                      || $self->logger->logcroak('Cannot seek in dst file');
                    syswrite( $dstFh, $data );
                }

                # Update hash in checksum
                if ($writeHash) {
                    sysseek( $chkFh, $block * $hashSize, SEEK_SET )
                      || $self->logger->logcroak('Cannot seek in chk file');
                    syswrite( $chkFh, $newHash );
                }

                $self->logger->debug(
                    sprintf 'Block <%u> was <%s> (<%u> to <%u>)',
                    $block, $status, $srcSeek, $srcSeek + $srcReadSize - 1 );
                &{ $self->status }
                  ( $block, $status, $srcSeek, $srcSeek + $srcReadSize - 1 );

                # Next block will start here
                $srcSeek += $srcReadSize;

                # Was this the last block in this batch
                if ( $end && $srcSeek > $end ) {
                    last;
                }
            }

            # If last block is sparse, it is not enough to seek to where the
            # EOF should be. We need to at least write a single \0
            if ( $dstFh && $status eq 'sparse' ) {
                sysseek( $dstFh, $srcSeek - 1, SEEK_SET )
                  || $self->logger->logcroak('Cannot seek in dst file');
                syswrite( $dstFh, "\0" );
            }
        }

        if (   $self->truncate
            && $dstFh
            && $srcSeek
            && @{ $self->data } == 1
            && $self->data->[0]->{start} == 0
            && $self->data->[0]->{end} == 0 )
        {
            $self->logger->debug("Truncating dst file at <$srcSeek>");
            truncate( $dstFh, $srcSeek );

            my $chkSeek = ceil( $srcSeek / $self->bs ) * $hashSize;
            $self->logger->debug("Truncating chk file at <$chkSeek>");
            truncate( $chkFh, $chkSeek );
        }

    }
    catch {
        croak $_;
    }
    finally {
        # If we opened the files (we got string with path), then we close them
        # if we got a filehandle then we do nothing
        if ($srcClose) {
            $self->logger->debug( sprintf 'closing src file <%s>', $self->src );
        }
        if ($dstClose) {
            $self->logger->debug( sprintf 'closing dst file <%s>', $self->dst );
        }
        if ($chkClose) {
            $self->logger->debug( sprintf 'closing chk file <%s>', $self->chk );
        }
    };

    # Make Perl::Critic happy
    return;
}

################################################################

=begin comment

Private
Get file handle

=end comment

=cut

sub _getFh {
    my ( $self, $name, $file, $closeFile, $mode ) = @_;

    if ( my $t = reftype($file) ) {
        if ( $t eq 'GLOB' ) {
            $self->logger->debug(
                sprintf '%s is a file handle, using that directly', $name );
            return $file;
        }
        else {
            $self->logger->logcroak(
                sprintf '<%s> is not a supported type for %s',
                $t, $name );
        }
    }
    else {
        $self->logger->debug( sprintf 'opening %s file <%s>', $name, $file );
        sysopen( my $fh, $file, $mode )
          || $self->logger->logcroak( sprintf 'error opening <%s>', $file );
        ${$closeFile} = 1;
        return $fh;
    }

    # Make Perl::Critic happy
    croak 'We should never end here!';
}

################################################################

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Thor Dreier-Hansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself:

=over

=item * the 
        L<GNU General Public License|http://dev.perl.org/licenses/gpl1.html>
        as published by the Free Software Foundation; either
        L<version 1|http://dev.perl.org/licenses/gpl1.html>,
        or (at your option) any later version, or

=item * the L<"Artistic License"|http://dev.perl.org/licenses/artistic.html>

=back

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of IO::BlockSync
