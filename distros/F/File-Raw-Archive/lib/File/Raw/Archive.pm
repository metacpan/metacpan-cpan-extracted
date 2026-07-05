package File::Raw::Archive;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

use base 'File::Raw';

require XSLoader;
XSLoader::load('File::Raw::Archive', $VERSION);

1;

__END__

=head1 NAME

File::Raw::Archive - Archive container reader/writer

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use File::Raw::Archive;

    # iterate
    my $ar = File::Raw::Archive->open("foo.tar");
    while (my $entry = $ar->next) {
        next if $entry->is_dir;
        my $bytes = $entry->slurp;
    }
    $ar->close;

    # one-liner each (last arg is the callback)
    File::Raw::Archive->each("logs.tar.gz",
        compression => 'gzip',
        sub {
            my $e = shift;
            return if $e->is_dir;
            print $e->name, " (", $e->size, " bytes)\n";
        });

    # list everything as an arrayref of metadata snapshots
    my $rows = File::Raw::Archive->list("foo.tar");

    # extract everything
    File::Raw::Archive->extract_all("foo.tar.gz", "/tmp/out",
        compression => 'gzip');

    # extract one entry by name
    File::Raw::Archive->extract("foo.tar", "path/inside", "/tmp/out.txt");

    # build a tarball
    my $w = File::Raw::Archive->create("out.tar.gz",
        compression => 'gzip', level => 9);
    $w->add(name => 'README', content => $readme, mode => 0644);
    $w->add(name => 'src/');                                # dir
    $w->add(name => 'src/main.c', content => $main_c);
    $w->close;

=head1 DESCRIPTION

C<File::Raw::Archive> handles archive containers with a streaming,
plugin-driven API. The built-in C<tar> plugin reads ustar (POSIX
1988), GNU C<././@LongLink>, and PAX extended-header tarballs, and
writes ustar / GNU / PAX / auto depending on the C<format> option.

Additional format plugins (zip, cpio, ar) can be loaded at run time
by installing the matching C<File::Raw::Archive::*> sister module.

=head1 METHODS

=head2 Reading

=over 4

=item C<< File::Raw::Archive->open($path, %opts) >>

Open C<$path> for sequential reading. Returns a
L<File::Raw::Archive::Reader>. The format and compression are
auto-detected unless overridden with C<plugin> / C<compression>.

    my $r = File::Raw::Archive->open("foo.tar.gz");
    while (my $e = $r->next) { ... }
    $r->close;

=item C<< File::Raw::Archive->list($path, %opts) >>

Read the entire archive and return an array-reference of metadata
snapshots. Each element is a plain hashref with keys C<name>, C<size>,
C<mode>, C<mtime>, C<mtime_ns>, C<uid>, C<gid>, C<type>,
C<link_target>, C<xattrs>, and C<is_sparse>.

    my $entries = File::Raw::Archive->list("foo.tar");
    printf "%s  %d\n", $_->{name}, $_->{size} for @$entries;

=item C<< File::Raw::Archive->each($path, %opts, \&callback) >>

Iterate the archive, calling C<\&callback> once per entry with a
L<File::Raw::Archive::Entry> as its sole argument. The callback is the
B<last> positional argument; options go between C<$path> and the
coderef. Returns nothing.

    File::Raw::Archive->each("logs.tar.gz",
        compression => 'gzip',
        sub {
            my $e = shift;
            return if $e->is_dir;
            print $e->name, " (", $e->size, " bytes)\n";
        });

Accepts C<entry_filter> to pre-screen entries before the callback runs.

=item C<< File::Raw::Archive->extract($path, $name, $dest, %opts) >>

Extract the single entry whose name exactly matches C<$name> from the
archive at C<$path>, writing it to the filesystem path C<$dest>.
Returns C<1> if the entry was found and written, C<0> if it was not
present in the archive.

    my $ok = File::Raw::Archive->extract(
        "foo.tar", "path/inside/archive", "/tmp/out.txt");

=item C<< File::Raw::Archive->extract_all($path, $dest, %opts) >>

Extract every entry from C<$path> under the directory C<$dest>,
creating it if necessary. Returns C<1> on success; croaks on error.

    File::Raw::Archive->extract_all("foo.tar.gz", "/tmp/out",
        compression => 'gzip');

When C<parallel =E<gt> N> (N E<gt> 1) is given, file content is
dispatched round-robin to N forked worker processes. Falls back to
sequential on platforms without C<fork(2)>.

=back

=head2 Writing

=over 4

=item C<< File::Raw::Archive->create($path, %opts) >>

Open C<$path> for writing and return a L<File::Raw::Archive::Writer>.

    my $w = File::Raw::Archive->create("out.tar.gz",
        compression => 'gzip', level => 9);
    $w->add(name => 'README', content => $bytes, mode => 0644);
    $w->add(name => 'src/');
    $w->close;

=back

=head2 Exported functions

Importing one or more names installs the matching C<file_archive_*>
function into the caller's package. All six names can be requested at
once with C<import> or C<:all>.

    use File::Raw::Archive qw(open list each extract extract_all create);
    # or: all six at once
    use File::Raw::Archive qw(import);
    use File::Raw::Archive qw(:all);

Each exported function is identical to the class method of the same
name but takes no leading C<$class> argument.

=over 4

=item C<file_archive_open($path, %opts)>

=item C<file_archive_create($path, %opts)>

=item C<file_archive_list($path, %opts)>

=item C<file_archive_each($path, %opts, \&callback)>

=item C<file_archive_extract($path, $name, $dest, %opts)>

=item C<file_archive_extract_all($path, $dest, %opts)>

=back

=head1 OPTIONS

All options are passed as a flat key-value list after the mandatory
positional arguments.

=over 4

=item C<plugin>

Archive format name. C<tar> is always built in. Sister modules add
C<zip>, C<cpio>, and C<ar>. Default: C<tar>.

=item C<compression>

C<none>, C<gzip>, or C<auto>. On read, C<auto> sniffs the gzip magic
bytes C<1f 8b>; on write, C<auto> checks the path suffix (C<.gz>).
Default: C<auto>.

=item C<level>

Gzip compression level, C<0>-C<9>. Meaningful only when
C<compression =E<gt> 'gzip'> is in effect on a write. Default: C<6>.

=item C<format>

Write-side only. Tar emission strategy: C<auto>, C<pax>, C<gnu>, or
C<ustar>. See L</TAR FORMAT MODES>. Default: C<auto>.

=item C<global_meta>

Write-side only. A hashref of PAX key-value pairs emitted in a C<'g'>
(global) extended header at the start of the archive. Subsequent
entries inherit these values unless overridden per-entry.

=item C<entry_filter>

Read-side coderef used by C<each> and C<extract_all>. Receives the
L<File::Raw::Archive::Entry> before the main callback or extraction
step. Returning false causes the entry to be skipped.

=item C<xattrs>

C<extract> and C<extract_all> only. When true (the default), extended
attributes stored as C<SCHILY.xattr.*> PAX records are applied to
extracted files via the platform xattr API.

=item C<unsafe_paths>

C<extract_all> only. Default C<0>. When false, entry names containing
C<..> components or absolute paths are refused. Set to C<1> only for
trusted archives.

=item C<parallel>

C<extract_all> only. Number of forked worker processes for parallel
extraction. Default C<1> (sequential). Falls back to sequential on
platforms that lack C<fork(2)>.

=back

=head1 TAR FORMAT MODES

=over 4

=item C<auto> (default)

Emit ustar when every field fits; escalate to GNU C<@LongLink> for
long names; escalate to PAX for everything ustar/@LongLink cannot
carry (size E<gt> 8 GiB, large uid/gid, sub-second mtime, xattrs).

=item C<pax>

Emit a PAX C<'x'> header for every entry needing escalation, matching
GNU tar 1.30+ default behaviour. Slightly larger output but more
uniform and portable.

=item C<gnu>

Keep C<@LongLink> for long names; croak on fields that require PAX.

=item C<ustar>

Strict ustar only. Croaks on any field that does not fit.

=back

=head1 PLUGIN API

C<File::Raw::Archive> publishes its C plugin API (C<archive_plugin.h>)
via L<ExtUtils::Depends>. Sister dists call C<archive_register_plugin>
at C<BOOT> time to add new formats; C<archive_lookup_plugin> and
C<archive_probe_for> are available for probing.

=head1 SEE ALSO

L<File::Raw::Archive::Reader>, L<File::Raw::Archive::Writer>,
L<File::Raw::Archive::Entry>, L<File::Raw>, L<Archive::Tar>,
L<IO::Compress::Gzip>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
