#============================================================= -*-perl-*-
#
# File::RsyncP::Digest package
#
# DESCRIPTION
#   File::RsyncP::Digest is a perl module that implements the
#   various message digests that rsync uses.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   File::RsyncP is Copyright (C) 2002-2015 Craig Barratt.
#
#   Rsync is Copyright (C) 1996-2001 by Andrew Tridgell, 1996 by Paul
#   Mackerras, 2001-2002 by Martin Pool, and 2003-2009 by Wayne Davison,
#   and others.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#========================================================================
#
# Version 0.74, released 17 Jan 2015.
#
# See http://perlrsync.sourceforge.net.
#
#========================================================================

package File::RsyncP::Digest;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.74';

bootstrap File::RsyncP::Digest $VERSION;

# Preloaded methods go here.

sub addfile
{
    no strict 'refs';	# Countermand any strct refs in force so that we
			# can still handle file-handle names.

    my ($self, $handle) = @_;
    my ($package, $file, $line) = caller;
    my ($data) = '';

    if (!ref($handle))
    {
	# Old-style passing of filehandle by name. We need to add
	# the calling package scope qualifier, if there is not one
	# supplied already.

	$handle = $package . '::' . $handle unless ($handle =~ /(\:\:|\')/);
    }

    while (read($handle, $data, 1024))
    {
	$self->add($data);
    }
    return $self;
}

sub hexdigest
{
    my ($self) = shift;

    unpack("H*", ($self->digest()));
}

sub hash
{
    my ($self, $data) = @_;

    if (ref($self))
    {
	# This is an instance method call so reset the current context

	$self->reset();
    }
    else
    {
	# This is a static method invocation, create a temporary MD4 context

	$self = new File::RsyncP::Digest;
    }

    # Now do the hash

    $self->add($data);
    $self->digest();
}

sub hexhash
{
    my ($self, $data) = @_;

    unpack("H*", ($self->hash($data)));
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

File::RsyncP::Digest - Perl interface to rsync message digest algorithms

=head1 SYNOPSIS

    use File::RsyncP::Digest;
    
    $rsDigest = new File::RsyncP::Digest;

    # specify rsync protocol version (default is <= 26 -> buggy digests).
    $rsDigest->protocol(version);
    
    # file MD4 digests
    $rsDigest->reset();
    $rsDigest->add(LIST);
    $rsDigest->addfile(HANDLE);

    $digest = $rsDigest->digest();
    $string = $rsDigest->hexdigest();

    # Return 32 byte pair of digests (protocol <= 26 and >= 27).
    $digestPair = $rsDigest->digest2();

    $digest = File::RsyncP::Digest->hash(SCALAR);
    $string = File::RsyncP::Digest->hexhash(SCALAR);
    
    # block digests
    $digests = $rsDigest->blockDigest($data, $blockSize, $md4DigestLen,
                                      $checksumSeed);

    $digests = $rsDigest->blockDigestUpdate($state, $blockSize,
                                $blockLastLen, $md4DigestLen, $checksumSeed);

    $digests2 = $rsDigest->blockDigestExtract($digests16, $md4DigestLen);

=head1 DESCRIPTION

The B<File::RsyncP::Digest> module allows you to compute rsync digests,
including the RSA Data Security Inc. MD4 Message Digest algorithm, and
Adler32 checksums from within Perl programs.

=head2 Rsync Digests

Rsync uses two main digests (or checksums), for checking with very high
probability that the underlying data is identical, without the need to
exchange the underlying data.

The server (remote) side of rsync generates a checksumSeed (usually unix
time()) that is exchanged during the protocol startup.  This seed is used
in both the file and MD4 checksum calculations.  This causes the block
and file checksums to change every time Rsync is run.

=over 4

=item File Digest

This is an MD4 digest of the checksum seed, followed by the entire
file's contents.  This digest is 128 bits long.  The file digest is
sent at the end of a file's deltas to ensure that the reconstructed
file is correct.  This digest is also optionally computed and sent as
part of the file list if the --checksum option is specified to rsync.

=item Block digest

Each file is divided into blocks of default length 700 bytes.  The digest
of each block is formed by computing the Adler32 checksum of the block,
and also the MD4 digest of the block followed by the checksum seed.
During phase 1, just the first two bytes of the MD4 digest are sent,
meaning the total digest is 6 bytes or 48 bits (4 bytes for Adler32
and the first 2 bytes of the MD4 digest).  During phase 2 (which is
necessary for received files that have an incorrect file digest),
the entire MD4 checksum is used (128 bits) meaning the block digest
is 20 bytes or 160 bits.  (Prior to rsync protocol XXX, the full
20 byte digest was sent every time and there was only a single phase.)

=back

This module contains routines for computing file and block digests in
a manner that is identical to rsync.

Incidentally, rsync contains two bugs in its implementation of MD4 (up
to and including rsync protocol version 26):

=over 4

=item *

MD4Final() is not called when the data size (ie: file or block size
plus 4 bytes for the checksum seed) is a multiple of 64.

=item *

MD4 is not correct for total data sizes greater than 512MB (2^32 bits).
Rsync's MD4 only maintains the data size using a 32 bit counter, so
it overflows for file sizes bigger than 512MB.

=back

The effects of these bugs are benign: the MD4 digest should not be
cryptographically weakened and both sides are consistent. 

This module implements both versions of the MD4 digest: the 
buggy version for protocol versions <= 26 and the correct
version for protocol versions >= 27.  The default mode is
the buggy version (protocol versions <= 26).

You can specify the rsync protocol version to determine which
MD4 version is used:

    # specify rsync protocol version (default is <= 26 -> buggy digests).
    $rsDigest->protocol(version);

Also, you can get both digests in a single call.  The result is
returned as a single 32 byte scalar: the first 16 bytes is the
buggy digest and the second 16 bytes is the correct digest:

    # Return 32 byte pair of digests (protocol <= 26 and >= 27).
    $digestPair = $rsDigest->digest2();

=head2 Usage

A new rsync digest context object is created with the B<new> operation.
Multiple simultaneous digest contexts can be maintained, if desired.

=head2 Computing Block Digests

After a context is created, the function to compute block checksums is:

    $digests = $rsDigest->blockDigest($data, $blockSize, $md4DigestLen,
                                      $checksumSeed)

The first argument is the data, which can contain as much raw data as you
wish (ie: multiple blocks).  Both the Adler32 checksum and the MD4
checksum are computed for each block in data.  The partial end block
(if present) is also processed.  The 4 bytes of the integer checksumSeed
is added at the end of each block digest calculation if it is non-zero.
The blockSize is specified in the second argument (default is 700).
The third argument, md4DigestLen, specifies how many bytes of the
MD4 digest are included in the returned data.  Rsync uses a value of
2 for the first pass (meaning 6 bytes of total digests are returned per
block), and all 16 bytes for the second pass (meaning 20 bytes of total
digests are returned per block).  The returned number of bytes is
the number of bytes in each digest (Alder32 + partial/compete MD4)
times the number of blocks:

    (4 + md4DigestLen) * ceil(length(data) / blockSize);

To allow block checksums to be cached (when checksumSeed is unknown),
and then quickly updated with the known checksumSeed, the checksum
data should be first computed with a digest length of -1 and a
checksumSeed of 0:

    $state = $rsDigest->blockDigest($data, $blockSize, -1, 0);

The returned $state should be saved for later retrieval, together with
the length of the last partial block (eg: length($data) % $blockSize).
The length of $state depends upon the number of blocks and the block size.
In addition to the 16 bytes of MD4 state, up to 63 bytes of unprocessed
data per block also is saved in $state.  For each block,

    16 + ($blockSize % 64)

bytes are saved in $state, so $state is most compact when $blockSize is
a multiple of 64.  (The last, partial, block might have a smaller block
size, requiring up to 63 bytes of state even if $blockSize is a multiple
of 64.)

Once the checksumSeed is known the updated checksums can then be computed
using:

    $digests = $rsDigest->blockDigestUpdate($state, $blockSize,
                                $blockLastLen, $md4DigestLen, $checksumSeed);

The first argument is the cached checksums from blockDigest.  The
third argument is the length of the (partial) last block.

Alternatively, I hope to add a --checksum-seed=n option to rsync that allows
the checksum seed to be set to 0.  This causes the checksum seed to be
omitted from the MD4 calculation and it makes caching the checksums much
easier.  A zero checksum seed does not weaken the block digest.
I'm not sure whether or not it weakens the file digest (the checksum
seed is applied at the start of the file digest and end of the block
digest).  In this case, the full 16 byte checksums should be computed
using:

    $digests16 = $rsDigest->blockDigest($data, $blockSize, 16, 0);

and for phase 1 the 2 byte MD4 substrings can be extracted with:

    $digests2  = $rsDigest->blockDigestExtract($digests16, 2);

The original $digests16 does not need any additional processing
for phase 2.

=head2 Computing File Digests

In addition, functions identical to B<Digest::MD4> are provided that
allow rsync's MD4 file digest to be computed.  The checksum seed,
if non-zero, is included at the start of the data, before the file's
contents are added.

The context is updated with the B<add> operation which adds the
strings contained in the I<LIST> parameter. Note, however, that
C<add('foo', 'bar')>, C<add('foo')> followed by C<add('bar')> and
C<add('foobar')> should all give the same result.

The final MD4 message digest value is returned by the B<digest> operation
as a 16-byte binary string. This operation delivers the result of
B<add> operations since the last B<new> or B<reset> operation. Note
that the B<digest> operation is effectively a destructive, read-once
operation. Once it has been performed, the context must be B<reset>
before being used to calculate another digest value.

Several convenience functions are also provided. The B<addfile>
operation takes an open file-handle and reads it until end-of file in
1024 byte blocks adding the contents to the context. The file-handle
can either be specified by name or passed as a type-glob reference, as
shown in the examples below. The B<hexdigest> operation calls
B<digest> and returns the result as a printable string of hexdecimal
digits. This is exactly the same operation as performed by the
B<unpack> operation in the examples below.

The B<hash> operation can act as either a static member function (ie
you invoke it on the MD4 class as in the synopsis above) or as a
normal virtual function. In both cases it performs the complete MD4
cycle (reset, add, digest) on the supplied scalar value. This is
convenient for handling small quantities of data. When invoked on the
class a temporary context is created. When invoked through an already
created context object, this context is used. The latter form is
slightly more efficient. The B<hexhash> operation is analogous to
B<hexdigest>.

=head1 EXAMPLES

    use File::RsyncP::Digest;
    
    my $rsDigest = new File::RsyncP::Digest;
    $rsDigest->add('foo', 'bar');
    $rsDigest->add('baz');
    my $digest = $rsDigest->digest();
    
    print("Rsync MD4 Digest is " . unpack("H*", $digest) . "\n");

The above example would print out the message

    Rsync MD4 Digest is 6df23dc03f9b54cc38a0fc1483df6e21

To compute the rsync phase 1 block checksums (4 + 2 = 6 bytes per
block) for a 2000 byte file containing 700 a's, 700 b's and 600 c's,
with a checksum seed of 0x12345678:

    use File::RsyncP::Digest;
    
    my $rsDigest = new File::RsyncP::Digest;
    my $data = ("a" x 700) . ("b" x 700) . ("c" x 600);
    my $digest = $rsDigest->rsyncChecksum($data, 700, 2, 0x12345678);
    
    print("Rsync block checksums are " . unpack("H*", $digest) . "\n");

This will print:

    Rsync block checksums are 3c09a624641bf80b0ce3abd208e8645d5b49

The same result can be achieved in two steps by saving the state,
and then finishing the calculation:

    my $state = $rsDigest->blockDigest($data, 700, -1, 0);

    my $digest = $rsDigest->blockDigestUpdate($state, 700,
                                    length($data) % 700, 2, 0x12345678);

or by computing full-length MD4 digests, and extracting the 2 byte
version:

    my $digest16 = $rsDigest->blockDigest($data, 700, 16, 0x12345678);
    my $digest   = $rsDigest->blockDigestExtract($digest16, 2);

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

The MD4 algorithm is defined in RFC1320. The basic C code implementing
the algorithm is derived from that in the RFC and is covered by the
following copyright:

=over 8

   MD4 is Copyright (C) 1990-2, RSA Data Security, Inc. All rights
   reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD4 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.

   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD4 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.

   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.

   These notices must be retained in any copies of any part of this
   documentation and/or software.

=back

This copyright does not prohibit distribution of any version of Perl
containing this extension under the terms of the GNU or Artistic
licences.

=head1 AUTHOR

File::RsyncP::Digest was written by Craig Barratt
<cbarratt@users.sourceforge.net> based on Digest::MD4 and
the Adler32 implementation was based on rsync 2.5.5.

Digest::MD4 was adapted by Mike McCauley (C<mikem@open.com.au>),
based entirely on MD5-1.7, written by Neil Winton
(C<N.Winton@axion.bt.co.uk>).

Rsync was written by Andrew Tridgell <tridge@samba.org>
and Paul Mackerras.  It is available under a GPL license.
See L<http://rsync.samba.org>.

=head1 SEE ALSO

See L<http://perlrsync.sourceforge.net> for File::RsyncP's SourceForge
home page.

See L<File::RsyncP>, L<File::RsyncP::FileIO> and L<File::RsyncP::FileList>.

=cut
