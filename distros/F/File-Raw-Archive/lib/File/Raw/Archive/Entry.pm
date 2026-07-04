package File::Raw::Archive::Entry;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use File::Raw::Archive;

1;

__END__

=head1 NAME

File::Raw::Archive::Entry - Single archive entry (metadata + lazy content)

=head1 SYNOPSIS

    while (my $entry = $reader->next) {
        say $entry->name, "  ", $entry->size;
        next if $entry->is_dir;
        my $bytes = $entry->slurp;
    }

=head1 DESCRIPTION

A C<File::Raw::Archive::Entry> object represents one entry in an
archive - its header metadata and a lazy handle to the payload bytes.
Entries are returned by L<File::Raw::Archive::Reader/next> and by the
callback passed to L<File::Raw::Archive/each>.

The payload can be read at most once via C<slurp> or C<read>; after
the reader advances to the next entry any unread bytes are discarded.

=head1 METADATA ACCESSORS

All metadata accessors are read-only. String-typed accessors return
C<undef> when the field was absent in the archive header; integer-typed
accessors return C<0>.

=over 4

=item C<name>

Entry path as stored in the archive, e.g. C<src/main.c>. May include
directory components but never a leading C</>.

=item C<size>

Payload size in bytes. C<0> for directories and symlinks.

=item C<mode>

POSIX permission bits as an integer (e.g. C<0644>).

=item C<mtime>

Last-modification time as integer Unix seconds.

=item C<mtime_ns>

Sub-second nanosecond component of the modification time (C<0>-C<999_999_999>).
Non-zero only when the archive carried a PAX extended C<mtime> record.

=item C<uid>

Numeric user ID of the entry owner.

=item C<gid>

Numeric group ID of the entry owner.

=item C<type>

Integer entry type. Compare against the constants exported by
L<File::Raw::Archive>: C<AE_FILE>, C<AE_DIR>, C<AE_SYMLINK>,
C<AE_HARDLINK>, C<AE_FIFO>, C<AE_CHAR>, C<AE_BLOCK>, C<AE_OTHER>.

=item C<link_target>

Symlink or hardlink destination string. C<undef> for regular files and
directories.

=item C<xattrs>

Hashref of C<name =E<gt> bytes> pairs decoded from C<SCHILY.xattr.*>
PAX records, or C<undef> when none were present.

=item C<is_sparse>

True when the entry was recorded as a sparse file in the archive.

=back

=head1 TYPE PREDICATES

=over 4

=item C<is_file>

True when C<type> is C<AE_FILE>.

=item C<is_dir>

True when C<type> is C<AE_DIR>.

=item C<is_symlink>

True when C<type> is C<AE_SYMLINK>.

=item C<is_link>

True when C<type> is C<AE_SYMLINK> or C<AE_HARDLINK>.

=back

=head1 PAYLOAD METHODS

=over 4

=item C<slurp>

Read the entire entry payload into a byte string and return it.
Memoised: calling C<slurp> a second time returns the same scalar
without re-reading from the archive. Croaks if the underlying reader
has already been closed or advanced past this entry without consuming
the payload.

    my $bytes = $entry->slurp;

=item C<< read($n) >>

Read at most C<$n> bytes from the entry payload and return them.
Returns an empty string at end-of-entry. Unlike C<slurp>, each call
consumes bytes from the stream; the result is not memoised.

    while (length(my $chunk = $entry->read(65536))) {
        $fh->write($chunk);
    }

=back

=head1 SEE ALSO

L<File::Raw::Archive>, L<File::Raw::Archive::Reader>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0
(GPL Compatible).

=cut
