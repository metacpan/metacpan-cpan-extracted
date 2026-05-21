package File::Raw::Gzip;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.03';

use base 'File::Raw';

require XSLoader;
XSLoader::load('File::Raw::Gzip', $VERSION);

1;

__END__

=head1 NAME

File::Raw::Gzip - Gzip / zlib / raw deflate plugin for File::Raw

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Loading the module registers a single C<gzip> plugin with File::Raw.

    use File::Raw::Gzip;
    use File::Raw qw(import);

    # READ: decompress on the way in.
    my $bytes = file_slurp("nginx.access.log.gz", plugin => 'gzip');

    # WRITE: compress on the way out.
    file_spew("out.gz", $payload, plugin => 'gzip', level => 9);

    # zlib stream (RFC 1950) inside e.g. PNG files:
    my $raw = file_slurp("inner.zlib", plugin => 'gzip', mode => 'zlib');

    # Raw deflate (RFC 1951), no header:
    my $raw = file_slurp("blob.deflate", plugin => 'gzip', mode => 'raw');

    # STREAM: each_line over a gzip file without slurping it whole.
    File::Raw::each_line("nginx.access.log.gz",
        sub { print "saw: $_\n" },
        plugin => 'gzip');

    # CHAIN: read .csv.gz directly into AoA (with File::Raw::Separated).
    my $rows = file_slurp("metrics.csv.gz",
                          plugin => ['gzip', 'csv']);

=head1 OPTIONS

Every C<plugin =E<gt> 'gzip'> dispatch accepts these trailing keys:

=over 4

=item C<level>

Compression level (0=none, 1=fastest, 9=smallest). Default C<6>.
Encode-only; ignored on decode.

=item C<mode>

One of C<gzip>, C<zlib>, C<raw>, C<auto>. Selects the wbits value
handed to C<inflateInit2> / C<deflateInit2>:

=over 4

=item C<gzip> - full gzip header + trailer (the C<.gz> file format).
Default for encode.

=item C<zlib> - zlib stream (RFC 1950); the wrapper used inside e.g.
PNG.

=item C<raw> - raw deflate (RFC 1951); no header, used in zip
archives.

=item C<auto> - decode-only; zlib auto-detects gzip vs zlib headers.
Default for decode.

=back

=item C<chunk_size>

Output buffer growth chunk in bytes. Default 131072 (128 KiB). Raise
for very large inputs to reduce realloc churn; lower if memory is
tight. Capped at 64 MiB.

=item C<strategy>

Compression strategy. One of C<default>, C<filtered>, C<huffman_only>,
C<rle>, C<fixed>. Encode-only. Advanced; the default is correct for
nearly all use cases.

=item C<mem_level>

Memory level (1-9). Default C<8>. Encode-only. Advanced; trade memory
for speed.

=back

=head1 PLUGIN BEHAVIOUR

The READ phase pulls compressed bytes out of File::Raw's slurp buffer,
inflates them through C<libz>, and returns the decompressed bytes as
one SV. The WRITE phase deflates the user payload before File::Raw
writes it to disk.

The STREAM phase backs C<File::Raw::each_line($path, $cb, plugin =E<gt>
'gzip')>: File::Raw reads the compressed file in chunks, this plugin
inflates each chunk and emits decompressed lines through C<$cb> with
C<$_> bound to the line (no trailing newline). The inflate state and
the partial trailing line live in C<ctx-E<gt>call_state> across
chunks, so memory is bounded regardless of the compressed file's size.

The RECORD phase isn't implemented: a gzip stream has no record
boundaries to dispatch over.

=head2 Plugin chains

Because gzip is a pure byte transform, it composes cleanly through
File::Raw's plugin chain. Put C<'gzip'> first in a READ and WRITE chains

    # READ:  bytes -> inflate -> csv parse
    my $rows = file_slurp("data.csv.gz",
                          plugin => ['gzip', 'csv']);

    # WRITE: csv encode -> deflate -> bytes
    file_spew("out.csv.gz", $rows,
              plugin => ['gzip', 'csv']);

C<each_line> (the streaming path) is single-plugin only; chain
composition belongs to the slurp/spew/append/atomic_spew calls.

=head1 INSTALLATION REQUIREMENTS

C<File::Raw::Gzip> links against the system C<libz>. The development
package must be installed before C<perl Makefile.PL>:

=over 4

=item Debian / Ubuntu

  apt-get install zlib1g-dev

=item RHEL / Fedora / CentOS

  dnf install zlib-devel

=item macOS (Homebrew)

  brew install zlib

=item FreeBSD

  pkg install zlib-ng-compat

=item Strawberry Perl (Windows)

Already bundled; no extra install needed.

=back

=head1 SEE ALSO

L<File::Raw> - the underlying fast file IO layer.

L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip> - the in-memory and
streaming codecs we link against in tests for wire-compatibility.

L<Compress::Raw::Zlib> - the lower-level zlib binding;

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
