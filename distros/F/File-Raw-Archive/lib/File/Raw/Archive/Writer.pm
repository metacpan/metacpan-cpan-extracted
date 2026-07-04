package File::Raw::Archive::Writer;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use File::Raw::Archive;

1;

__END__

=head1 NAME

File::Raw::Archive::Writer - Archive entry emitter

=head1 SYNOPSIS

    my $w = File::Raw::Archive->create("out.tar.gz",
        compression => 'gzip', level => 9);
    $w->add(name => 'README',  content => $readme, mode => 0644);
    $w->add(name => 'src/');                       # directory
    $w->add(name => 'src/main.c', content => $main_c);
    $w->close;

=head1 DESCRIPTION

A C<File::Raw::Archive::Writer> is returned by
L<File::Raw::Archive/create>. It appends entries to an open archive
file one at a time.

=head1 METHODS

=over 4

=item C<< add(name => $name, %fields) >>

Append one entry to the archive. Returns true. The entry type is
inferred automatically from C<name> and C<link_target> when C<type>
is not supplied: a trailing C</> in C<name> gives C<AE_DIR>; a
C<link_target> gives C<AE_SYMLINK>; everything else is C<AE_FILE>.

Recognised fields:

=over 4

=item C<name>

Entry path as it should appear inside the archive. Required. A
trailing C</> marks a directory.

=item C<content>

Byte string payload. May be omitted for directories and symlinks.
When C<size> is not given it defaults to C<length($content)>.

=item C<type>

Integer entry type constant. Normally inferred; supply explicitly to
emit hardlinks (C<AE_HARDLINK>) or device nodes (C<AE_FIFO>,
C<AE_CHAR>, C<AE_BLOCK>).

=item C<mode>

POSIX permission bits. Defaults to C<0755> for directories, C<0777>
for symlinks, and C<0644> for all other types.

=item C<mtime>

Last-modification time as integer Unix seconds, or a floating-point
value to encode sub-second precision (e.g. C<1_700_000_000.5>).

=item C<mtime_ns>

Nanosecond component of the modification time. Ignored when C<mtime>
is already a floating-point value.

=item C<uid> / C<gid>

Numeric owner and group IDs. Default C<0>.

=item C<link_target>

Symlink or hardlink destination path. Setting this field implies
C<type =E<gt> AE_SYMLINK> unless C<type> is given explicitly.

=item C<xattrs>

Hashref of C<name =E<gt> bytes> pairs emitted as PAX
C<SCHILY.xattr.*> records. Binary values are base64-encoded
automatically when the format requires it.

=back

=item C<close>

Finalise the archive - for tar, writes the two mandatory trailing
zero-filled 512-byte blocks - and release all resources. Idempotent;
called automatically by C<DESTROY> if the caller forgets.

=back

=head1 SEE ALSO

L<File::Raw::Archive>, L<File::Raw::Archive::Entry>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0
(GPL Compatible).

=cut
