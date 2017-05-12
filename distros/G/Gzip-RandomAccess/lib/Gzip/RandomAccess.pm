package Gzip::RandomAccess;

use strict;
use warnings;
use Carp;
use XSLoader;

our $VERSION = '0.92';
XSLoader::load 'Gzip::RandomAccess', $VERSION;

my $DEFAULT_INDEX_SPAN = 1024 * 1024;

sub new {
    my $class = shift;
    my $args = $class->_parse_arguments(@_);

    my $self = _new(
        $args->{file},
        $args->{index_file},
        $args->{index_span} || $DEFAULT_INDEX_SPAN,
        $args->{cleanup} || 0,
    );
    bless $self, $class;

    if (!$self->index_available) {
        $self->build_index;
    }

    return $self;
}

sub _parse_arguments {
    my $class = shift;
    my $args = (@_ == 1 && ref $_[0] eq 'HASH') ? $_[0]              # Hashref
             : (@_ == 1)                        ? { file => $_[0] }  # Filename
             : (@_ % 2 == 0)                    ? { @_ }             # Hash
             : croak "Pass either a filename or a hash of arguments";

    exists $args->{file} or croak "Missing filename";
    defined $args->{file} or croak "Undefined filename";
    !ref $args->{file} or croak "Filename must be a scalar";

    my %valid = map { $_ => 1 } qw(file index_file index_span cleanup);

    for my $key (keys %$args) {
        croak "Invalid argument '$key'" if !$valid{$key};
    }

    return $args;
}

sub DESTROY {
    my $self = shift;
    my $index = $self->index_file;
    my $cleanup = $self->cleanup;
    $self->_free;
    if ($cleanup) {
        unlink($index);
    }
    return;
}

1;

__END__

=head1 NAME

Gzip::RandomAccess - extract arbitrary bits of a gzip stream

=head1 SYNOPSIS

  use Gzip::RandomAccess;

  my $gzip = Gzip::RandomAccess->new($filename);  # short version
  my $gzip = Gzip::RandomAccess->new(
    file => 'foo.gz',
    index_file => '.foo.gz.idx',
    cleanup => 1,  # delete index when out of scope
  );

  # Extract 1024 bytes from the 128th byte in
  print $gzip->extract(127, 1024), "\n";

=head1 DESCRIPTION

This module allows you to randomly access a gzip deflate stream
as if it were a regular file, even though gzip is not designed
to be random-access. This is achieved by streaming the gzip file
in advance, building an index mapping compressed byte offsets to
uncompressed offsets, and at each point storing the 32KB of data
gzip needs to prime its decompression engine from that point.

The mechanism is taken from zran.c, an example in the zlib
distribution; this module wraps it up in a nice XS Perl API and
provides index creation and cleanup mechanisms.

=head1 METHODS

=head2 new ($filename)

=head2 new (%args)

Create a new L<Gzip::RandomAccess> object. A single filename is
accepted, otherwise the following options as a hash or hashref:

=over

=item file (required)

Path to the gzip file you want to access.

=item index_file (default: "$file.idx")

Path to the index file to use, or create if it does not already
exist. If not provided, defaults to adding '.idx' to the filename.

=item index_span (default: 1024*1024)

Override the number of bytes between indexing points. A smaller
number creates a larger index but allows you to random-access
larger files faster.

=item cleanup (default: 0)

If set to a true value, automatically deletes the index file
when the object is destroyed.

=back

=head2 extract ($offset, $length)

Return uncompressed content from the gzip stream of length
C<$length> from offset C<$offset> (starting at 0).

=head2 build_index

Builds the gzip index, rebuilding if necessary. (Uncompresses
the whole file - may be slow).

=head2 index_available

Returns a boolean indicating if the gzip index has been created.

=head2 uncompressed_size

Returns the total number of uncompressed bytes in the gzip stream.
Unlike C<zcat --list> the value is not modulo 4GB.

=head2 file

=head2 index_file

=head2 cleanup

Accessors for constructor arguments.

=head1 CAVEATS

Not tested on Windows, or with any compression method other than
deflate.

=head1 AUTHOR

Richard Harris <richardjharris@gmail.com>

The libzran library included in this distribution is based on
work by Iain Wade, subsequently based on zran.c by Mark Alder.

=head1 ZLIB LICENSE

 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.

 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

=cut
