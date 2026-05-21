package File::Raw::Separated;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

use base 'File::Raw';

require XSLoader;
XSLoader::load('File::Raw::Separated', $VERSION);

1;

__END__

=head1 NAME

File::Raw::Separated - CSV/TSV plugin for File::Raw

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use File::Raw::Separated qw(import);

    my $rows = file_parse_buf($scalar);                      # CSV
    my $rows = file_parse_buf($scalar, { dialect => 'tsv' });

    file_parse_buf_each($scalar, sub {
        my $row = $_[0];     # arrayref of fields (reused across calls;
                             # copy with [@$row] if you need to retain)
    });

    # Streaming for files larger than RAM
    file_parse_stream("huge.csv", sub { my $row = $_[0]; ... });

    my $rows = file_parse_buf("name,age\nalice,30\n", { header => 1 });
    # $rows = [ { name => 'alice', age => '30' } ]

...

    use File::Raw qw(import);
    use File::Raw::Separated;            # registers csv + tsv plugins
    
    my $rows = file_slurp("data.csv", plugin => 'csv');
    my $rows = file_slurp("data.csv", plugin => 'csv', sep => ';', strict => 1);
    my $rows = file_slurp("data.tsv", plugin => 'tsv');
    my $text = file_slurp("readme.txt"); # no plugin => raw bytes

=head1 OPTIONS

Every parse function and every C<plugin =E<gt> 'csv'|'tsv'> dispatch
accepts the same set of trailing keys.

=over 4

=item C<dialect>

C<csv> (default for the unified C<parse_*> functions) or C<tsv>.
Selects the seeded defaults for C<sep> and C<quote>; any explicit keys
you also set override the dialect's defaults. The C<plugin =E<gt> ...>
form picks the dialect by plugin name; C<dialect> in that case is
ignored.

=item C<sep>

Single-byte field separator. Default C<,> for CSV, C<\t> for TSV.

=item C<quote>

Single-byte quote character. Default C<"> for CSV, disabled for TSV.
Pass C<undef> to disable quoting (every quote becomes literal data).

=item C<escape>

Single-byte backslash-style escape character. When set, inside a
quoted field the escape char consumes the next byte literally. Default
C<undef> (RFC 4180 doubled-quote escape only).

=item C<strict>

If true, croaks on malformed input (stray quote mid-field, unbalanced
quotes, EOL mismatch under pinned C<eol>). Error message includes byte
offset (and file path for C<parse_stream>). Default false (lenient
recovery).

=item C<eol>

One of C<auto>, C<lf>, C<crlf>, C<cr>. Default C<auto>: locks to the
first detected terminator and stays in that mode for the rest of the
parse. Pinning a non-matching EOL under C<strict> croaks.

=item C<trim>

Strip leading/trailing ASCII space and tab from B<unquoted> fields
only. Quoted fields preserve all bytes. Default false.

=item C<empty_is_undef>

Empty unquoted field becomes C<undef>. Quoted empty (C<"">) stays the
empty string. Default false (always returns C<"">).

=item C<binary>

Skip UTF-8 BOM stripping and skip C<sv_utf8_decode> on each field.
Default false.

=item C<header>

Controls whether rows are emitted as arrayrefs (default) or hashrefs.
Two forms:

=over 4

=item C<< header => 1 >>

The first emitted row is consumed as field names; subsequent rows are
emitted as hashrefs keyed by those names. Use when the file has its
own header line.

=item C<< header => [qw(name age city)] >>

Caller supplies the names. The parser does B<not> consume any row as
a header - row 0 is treated as data and emitted as a hashref against
the supplied names. Use when the file has no header line of its own.
The arrayref must be non-empty, contain no C<undef> entries, and have
no duplicates (each is checked at call time and croaks otherwise).

=back

In either form: a row with more fields than the header croaks; a
shorter row pads missing keys with C<undef>. Default false (arrayref
rows).

=item C<max_field_len>

Cap on a single field's byte length. Exceeding the cap croaks with
C<field exceeds max length>. Default 16 MiB.

=back

=head1 IMPORT

C<import> is an XSUB (installed at BOOT). Each requested name is
stamped into the caller's package as C<file_E<lt>nameE<gt>> via
C<newXS> - the same mechanism L<File::Raw> uses, so the two modules
compose without colliding (C<file_slurp> from File::Raw,
C<file_parse_buf> from here, etc.).

The C<file_> prefix is added by the importer; you request names
B<without> it. Unknown names produce a warning, not a die.

=over 4

=item C<import>

Bareword shorthand for C<:all> - matches the L<File::Raw> idiom
C<use File::Raw qw(import)>.

=item C<:all>

All nine names. Equivalent to C<:unified :csv :tsv>.

=item C<:unified>

C<parse_buf>, C<parse_buf_each>, C<parse_stream> - dialect read from
the opts hash, defaults to csv.

=item C<:csv>

C<csv_parse_buf>, C<csv_parse_buf_each>, C<csv_parse_stream> - dialect
pinned to csv; the C<dialect> key in opts is ignored.

=item C<:tsv>

C<tsv_parse_buf>, C<tsv_parse_buf_each>, C<tsv_parse_stream>.

=item Individual names

Any of the nine bare names listed above can be requested directly;
each lands as C<file_E<lt>nameE<gt>>.

=back

=head1 ROW-AV ALIASING (callback variants)

C<file_parse_buf_each>, C<file_parse_stream> (and their dialect-pinned
counterparts) hand the callback the SAME arrayref every row, with its
contents replaced. Stash a copy if you need to retain the row across
calls:

    file_parse_buf_each($buf, sub {
        my $row = [@{$_[0]}];   # explicit copy
        push @keep, $row;
    });

Header mode uses a fresh hashref per row, so the aliasing only affects
the array-form callback path.

=head1 STREAMING

C<file_parse_stream> opens the file at the C level (PerlLIO_open) and
reads in 64 KiB chunks, feeding each to the parser's incremental API.
RSS is bounded by the read buffer + C<max_field_len> regardless of
total file size.

To abort mid-stream, C<die> from the callback. The exception
propagates; the file descriptor and parser state are cleaned up on
every exit path.

=head1 PLUGIN INTEGRATION WITH FILE::RAW

Loading C<File::Raw::Separated> registers two plugins with File::Raw
via C<file_register_plugin> (declared in C<include/file_plugin.h>):

=over 4

=item *

C<csv> plugin - CSV defaults (sep C<,>, quote C<">). READ phase fires
from C<File::Raw::slurp($p, plugin =E<gt> 'csv', ...)>, returning AoA
(or AoH under C<header =E<gt> 1>).

=item *

C<tsv> plugin - TSV defaults (sep C<\t>, no quoting).

=back

The plugins register at module load and stay registered for the life
of the process. Per-call options arrive through File::Raw's variadic
XSUB plumbing; there is no global state to mutate. To opt out for a
particular call, just don't pass C<plugin =E<gt>>.

The WRITE / RECORD / STREAM phases are not yet wired - they will land
once the parser core grows a serialiser and File::Raw teaches
C<each_line>, C<grep_lines>, etc. the plugin pipeline. In the meantime
use C<parse_stream> for streaming directly.

=head1 SEE ALSO

L<File::Raw> - the underlying fast file IO layer.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
