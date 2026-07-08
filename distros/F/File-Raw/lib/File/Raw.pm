package File::Raw;

use strict;
use warnings;

our $VERSION = '0.14';

use DynaLoader;

our @ISA = ('DynaLoader');

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=head1 NAME

File::Raw - File operations using direct system calls

=head1 SYNOPSIS

    use File::Raw qw(import);

    # Slurp entire file
    my $content = file_slurp('/path/to/file');

    # Write to file
    file_spew('/path/to/file', $content);

    # Append to file
    file_append('/path/to/file', "more data\n");

    # Get all lines as array
    my $lines = file_lines('/path/to/file');

    # Process lines efficiently with callback (line via $_)
    file_each_line('/path/to/file', sub {
        print "Line: $_\n";
    });

    # Memory-mapped file access
    my $mmap = file_mmap_open('/path/to/file');
    my $data = $mmap->data;  # Zero-copy access
    $mmap->close;

    # Line iterator (memory efficient)
    my $iter = file_lines_iter('/path/to/file');
    while (!$iter->eof) {
        my $line = $iter->next;
        # process line
    }
    $iter->close;

    # File stat operations
    my $size   = file_size('/path/to/file');
    my $mtime  = file_mtime('/path/to/file');
    my $exists = file_exists('/path/to/file');

    # Type checks
    file_is_file('/path/to/file');
    file_is_dir('/path/to/dir');
    file_is_readable('/path/to/file');
    file_is_writable('/path/to/file');

=head1 DESCRIPTION

File::Raw provides file operations using direct system calls, bypassing PerlIO overhead. It includes functions for
reading/writing files, iterating lines efficiently, memory-mapped access, and file metadata operations. The module
also supports a plugin system for custom read/write/transform operations.

=head2 Performance

The module uses:

=over 4

=item * Direct read(2)/write(2) syscalls

=item * Pre-allocated buffers based on file size

=item * Memory-mapped file access for zero-copy reads

=item * Efficient line iteration without loading entire file

=item * MULTICALL optimization for callback-based functions

=back

=head1 FUNCTIONS

All functions are available with a C<file_> prefix when imported, e.g. C<file_slurp>, C<file_spew>, etc.

    use File::Raw qw(slurp spew);

    file_spew('/path/to/file', "data");  # Write data
    my $content = file_slurp('/path/to/file');  # Read data

=head2 slurp

    my $content = File::Raw::slurp($path);

Read entire file into a scalar. Returns undef on error.
Pre-allocates the buffer based on file size for optimal performance.

=head2 slurp_raw

    my $content = File::Raw::slurp_raw($path);

Same as slurp, explicit binary mode.

=head2 spew

    my $ok = File::Raw::spew($path, $data);

Write data to file (creates or truncates). Returns true on success.

=head2 append

    my $ok = File::Raw::append($path, $data);

Append data to file. Returns true on success.

=head2 lines

    my $lines = File::Raw::lines($path);

Returns arrayref of all lines (without newlines).

=head2 each_line

    File::Raw::each_line($path, sub {
        print "Line: $_\n";  # line available via $_
    });

Process each line with a callback. Memory efficient - doesn't load
entire file into memory.

=head2 lines_iter

    my $iter = File::Raw::lines_iter($path);
    while (!$iter->eof) {
        my $line = $iter->next;
    }
    $iter->close;

Returns a line iterator object. Without a plugin tail, the iterator
streams bytes lazily and is memory-efficient. With a plugin tail
(C<lines_iter($path, plugin =E<gt> 'csv', ...)>) the iterator is eager:
the file is slurped and parsed into an AoA at construction time, and
C<next> walks the array; the C<header =E<gt> 1> and
C<header =E<gt> [names]> options are honoured. For memory-bounded
streaming through a plugin use C<each_line> instead.

B<Note:> For maximum performance, prefer C<each_line()> which uses
MULTICALL optimization and is significantly faster. Use C<lines_iter()>
when you need iterator control (e.g., early exit, multiple iterators).

=head2 mmap_open

    my $mmap = File::Raw::mmap_open($path);
    my $mmap = File::Raw::mmap_open($path, 1);  # writable

Memory-map a file. Returns a File::Raw::mmap object.

=head3 File::Raw::mmap methods

=over 4

=item data() - Returns the mapped content as a scalar (zero-copy)

=item sync() - Flush changes to disk (for writable maps)

=item close() - Unmap the file

=back

=head2 size

    my $bytes = File::Raw::size($path);

Returns file size in bytes, or -1 on error.

=head2 mtime

    my $epoch = File::Raw::mtime($path);

Returns modification time as epoch seconds, or -1 on error.

=head2 exists

    if (File::Raw::exists($path)) { ... }

Returns true if path exists.

=head2 is_file

    if (File::Raw::is_file($path)) { ... }

Returns true if path is a regular file.

=head2 is_dir

    if (File::Raw::is_dir($path)) { ... }

Returns true if path is a directory.

=head2 is_readable

    if (File::Raw::is_readable($path)) { ... }

Returns true if path is readable.

=head2 is_writable

    if (File::Raw::is_writable($path)) { ... }

Returns true if path is writable.

=head2 stat

    my $st = File::Raw::stat($path);

Returns a hashref with all file attributes in one syscall. This is
much more efficient than calling multiple individual functions.

    my $st = File::Raw::stat($path);
    # $st = {
    #     size    => 12345,
    #     mtime   => 1234567890,
    #     atime   => 1234567890,
    #     ctime   => 1234567890,
    #     mode    => 0644,      # Permission bits only
    #     is_file => 1,
    #     is_dir  => '',
    #     dev     => 16777233,
    #     ino     => 12345,
    #     nlink   => 1,
    #     uid     => 501,
    #     gid     => 20,
    # }

Returns undef if stat fails.

File::Raw caches the last stat result for performance. When you call
multiple stat-like functions on the same file (size, mtime, is_readable,
etc.), only the first call hits the filesystem.

=head2 clear_stat_cache

    File::Raw::clear_stat_cache();        # Clear entire cache
    File::Raw::clear_stat_cache($path);   # Clear cache for specific path

Clear the internal stat cache. Use this when an external process may
have modified a file, or to force a fresh stat on the next call.

The cache is automatically invalidated when you use File::Raw functions
that modify files (spew, append, unlink, touch, chmod, etc.), but
external modifications require manual cache clearing.

    my $size1 = File::Raw::size($file);  # Cached stat
    # External process modifies $file...
    File::Raw::clear_stat_cache($file);  # Clear cache
    my $size2 = File::Raw::size($file);  # Fresh stat

=head2 copy

    my $ok = File::Raw::copy($src, $dst);

Copy a file. Uses native copy functions (copyfile on macOS, sendfile
on Linux) for optimal performance. Returns true on success.

=head2 move

    my $ok = File::Raw::move($src, $dst);

Move/rename a file. Uses rename() for same-filesystem moves, falls
back to copy+unlink for cross-device moves. Returns true on success.

=head2 unlink

    my $ok = File::Raw::unlink($path);

Delete a file. Returns true on success.

=head2 touch

    my $ok = File::Raw::touch($path);

Create an empty file or update timestamps. Returns true on success.

=head2 mkdir

    my $ok = File::Raw::mkdir($path);
    my $ok = File::Raw::mkdir($path, $mode);

Create a directory. Default mode is 0755. Returns true on success.

=head2 rmdir

    my $ok = File::Raw::rmdir($path);

Remove an empty directory. Returns true on success.

=head2 readdir

    my $entries = File::Raw::readdir($path);

Returns arrayref of directory entries (excludes . and ..).

=head2 basename

    my $name = File::Raw::basename($path);

Returns the filename portion of a path.

=head2 dirname

    my $dir = File::Raw::dirname($path);

Returns the directory portion of a path.

=head2 extname

    my $ext = File::Raw::extname($path);

Returns the file extension including the dot (e.g., ".txt").

=head2 join

    my $path = File::Raw::join($part1, $part2, ...);

Join path components with the appropriate separator. Handles
leading/trailing slashes correctly.

    my $path = File::Raw::join('/usr', 'local', 'bin');
    # Returns: /usr/local/bin

=head2 atime

    my $epoch = File::Raw::atime($path);

Returns access time as epoch seconds, or -1 on error.

=head2 ctime

    my $epoch = File::Raw::ctime($path);

Returns inode change time as epoch seconds, or -1 on error.

=head2 mode

    my $mode = File::Raw::mode($path);

Returns the file permission bits (e.g., 0644), or -1 on error.

=head2 is_link

    if (File::Raw::is_link($path)) { ... }

Returns true if path is a symbolic link.

=head2 is_executable

    if (File::Raw::is_executable($path)) { ... }

Returns true if path is executable.

=head2 chmod

    my $ok = File::Raw::chmod($path, $mode);

Change file permissions. Returns true on success.

    File::Raw::chmod($path, 0755);

=head2 head

    my $lines = File::Raw::head($path);      # First 10 lines
    my $lines = File::Raw::head($path, 20);  # First 20 lines

Returns arrayref of first N lines (default 10).

=head2 tail

    my $lines = File::Raw::tail($path);      # Last 10 lines
    my $lines = File::Raw::tail($path, 20);  # Last 20 lines

Returns arrayref of last N lines (default 10).

=head2 range_lines

    my $lines = File::Raw::range_lines($path, $from, $count);

Returns arrayref of C<$count> lines starting at line C<$from>.
1-based: C<range_lines($p, 5, 3)> returns lines 5, 6, 7.
C<range_lines($p, 1, 10)> is equivalent to C<head($p, 10)>.

If C<$from> is past EOF, or C<$count <= 0>, or C<$from < 1>, returns
an empty arrayref. If fewer than C<$count> lines remain after C<$from>,
returns whatever is available (no error).

Accepts the standard plugin tail; with C<plugin =E<gt> 'csv'> (or any
plugin returning AoA) the range is applied to the parsed records:

    # Rows 100..149 of a CSV
    my $page = File::Raw::range_lines($p, 100, 50,
                                      plugin => 'csv', header => 1);

Same eager trade-off as C<lines_iter> with a plugin: the file is
slurped and parsed in full before the slice is taken. For
memory-bounded streaming through a plugin use C<each_line> with a
counter and C<die> to bail.

=head2 atomic_spew

    my $ok = File::Raw::atomic_spew($path, $data);

Write data to a temporary file then atomically rename. This ensures
the file is never in a partial state. Returns true on success.

=head2 grep_lines

    my $lines = File::Raw::grep_lines($path, \&predicate);
    my $lines = File::Raw::grep_lines($path, 'not_blank');

Filter lines matching a predicate. The predicate can be a coderef
or a registered predicate name.

Built-in predicates: blank, not_blank, empty, not_empty, comment, not_comment

    # Using coderef
    my $lines = File::Raw::grep_lines($path, sub { /pattern/ });
    
    # Using built-in predicate
    my $lines = File::Raw::grep_lines($path, 'not_blank');

=head2 count_lines

    my $count = File::Raw::count_lines($path);
    my $count = File::Raw::count_lines($path, \&predicate);
    my $count = File::Raw::count_lines($path, 'not_blank');

Count lines in a file. Optionally filter by predicate.

=head2 find_line

    my $line = File::Raw::find_line($path, \&predicate);
    my $line = File::Raw::find_line($path, 'not_blank');

Find the first line matching a predicate. Returns undef if not found.

=head2 map_lines

    my $results = File::Raw::map_lines($path, \&transform);

Transform each line with a callback, returns arrayref of results.

    my $lengths = File::Raw::map_lines($path, sub { length($_) });

=head2 register_predicate

    File::Raw::register_predicate($name, \&predicate);

Register a custom named predicate for use with grep_lines / count_lines /
find_line. The coderef receives the line in C<$_>.

    File::Raw::register_predicate('has_error', sub { /ERROR/ });
    my $errors = File::Raw::grep_lines($path, 'has_error');

=head2 list_predicates

    my $names = File::Raw::list_predicates();

Returns arrayref of registered predicate names (built-ins plus any
custom ones).

=head1 PLUGINS

Most read / write / iteration functions accept a B<plugin tail>:

    File::Raw::slurp($path, plugin => 'csv', sep => ';', header => 1);
    File::Raw::spew ($path, $rows, plugin => 'csv');
    File::Raw::each_line($path, sub { ... }, plugin => 'csv');

The tail is parsed as C<key =E<gt> value> pairs; the C<plugin> key is
mandatory whenever options are supplied. The named plugin must be
registered via L</register_plugin> (Perl) or
C<file_register_plugin()> (C, see L</XS API>) before the call.

The following functions are plugin-aware:

=over 4

=item * Read: C<slurp>, C<lines>, C<head>, C<tail>, C<range_lines>

=item * Write: C<spew>, C<append>, C<atomic_spew>

=item * Streaming: C<each_line>

=item * Iterator: C<lines_iter>

=item * Record-derived: C<grep_lines>, C<count_lines>, C<find_line>, C<map_lines>

=back

C<slurp_raw> and the stat / dir / path families are intentionally
plugin-free.

C<lines_iter> with a plugin tail is B<eager> (it slurps the file once
into an AoA at construction time and the iterator walks that array).
The iterator interface is preserved so callers can still store the
handle, call C<next>/C<eof>/C<close>, etc., but it is not
memory-bounded: for true streaming over huge files use C<each_line>
with the same plugin tail.

=head2 Plugin chains

The C<plugin> value can be an arrayref of plugin names instead of a
single name. The chain describes the file's encoding stack from
outermost wrapper to innermost format; same spelling for both
directions.

    # data.csv.gz: gzip wraps csv. Slurp unwraps left-to-right -
    # gunzip first, then parse csv - and returns an AoA.
    my $rows = File::Raw::slurp($path,
        plugin => ['gzip', 'csv']);

    # spew applies right-to-left: csv-encode the AoA into bytes,
    # then gzip the bytes, then write the result.
    File::Raw::spew($path, $rows,
        plugin => ['gzip', 'csv']);

The single-plugin scalar form (C<plugin =E<gt> 'csv'>) keeps its
current semantics exactly; chains are purely additive.

=head3 Per-plugin options

When the chain has more than one plugin, give each one its own
sub-hash. Keys outside any sub-hash are shared across the whole chain
(visible to every plugin); per-plugin keys win on conflict.

    File::Raw::slurp($path,
        plugin => ['gzip', 'csv'],
        gzip   => { level => 9 },         # only gzip sees this
        csv    => { sep => ';' },         # only csv sees this
        strict => 1,                      # both gzip and csv see this
    );

The single-plugin scalar form takes a flat options bag (top-level
keys go straight to the lone plugin) - no sub-hash required.

=head3 Type contract

File::Raw doesn't statically enforce the chain's type contract; each
plugin sees its predecessor's return value verbatim. The convention
is:

=over 4

=item *

For READ: every plugin except the last must return bytes. The last
plugin can return any shape (bytes, AoA, AoH, ...).

=item *

For WRITE: every plugin except the first must accept bytes; the
first sees the user's payload (which may itself be structured).

=back

In practice that means structured-output plugins (C<csv>, C<json>,
C<yaml>) belong B<last> in a READ chain and B<first> in a WRITE
chain. Byte-transform plugins (C<gzip>, C<base64>, C<encoding>) are
chain-friendly anywhere.

=head3 Phase coverage

Chains are supported for B<READ> and B<WRITE> only. The record-derived
helpers (C<grep_lines>, C<count_lines>, C<find_line>, C<map_lines>)
get chain support transparently because they slurp + transform via
READ before iterating records.

C<each_line> (the true streaming path) rejects arrayref C<plugin>
values: composing two streams needs a record-to-chunk adapter that's
its own design problem. Pass a single plugin name there. C<record>
phase is also single-plugin only - chaining record functions would
require records to keep the same shape across links.

=head3 Plugin-author notes

Existing plugins keep working without recompilation: C<FilePlugin> and
C<FilePluginContext> are unchanged. A plugin's C<read>/C<write>
callback is invoked the same way whether it's standalone or part of a
chain; the dispatcher builds a per-iteration C<ctx-E<gt>options> HV
that contains the shared keys overlaid with the plugin's own sub-hash
(if any).

=head2 register_plugin

    File::Raw::register_plugin($name, \%phases);
    File::Raw::register_plugin($name, \%phases, $override);

Register a plugin that will be invoked when callers pass
C<plugin =E<gt> $name>. C<%phases> is a hashref of coderefs keyed by
phase name. A plugin may implement any subset of phases; absent ones
cause a clear error if the user requests them.

    File::Raw::register_plugin('csv', {
        read   => sub { my ($path, $bytes,  $opts) = @_; ... },  # bytes -> AoA
        write  => sub { my ($path, $rows,   $opts) = @_; ... },  # rows  -> bytes
        record => sub { my ($path, $record, $opts) = @_; ... },  # transform/filter
    });

The C<stream> phase is intentionally not exposed from Perl - per-chunk
C<call_sv> overhead defeats the purpose of streaming. Plugins that need
record-by-record callbacks should implement C<record>; File::Raw drives
the iteration itself. Streaming plugins must be written in C.

Re-registering a name without C<$override> croaks; pass a true
C<$override> to replace.

=head2 unregister_plugin

    File::Raw::unregister_plugin($name);

Remove a previously-registered plugin.

=head2 list_plugins

    my $names = File::Raw::list_plugins();

Returns arrayref of currently registered plugin names. The built-in
C<'predicate'> plugin is always present.

=head2 The built-in 'predicate' plugin

Boot-time-registered C plugin that owns the eight built-in line
predicates (C<blank>/C<is_blank>, C<not_blank>/C<is_not_blank>,
C<empty>/C<is_empty>, C<not_empty>/C<is_not_empty>,
C<comment>/C<is_comment>, C<not_comment>/C<is_not_comment>) plus any
predicate added via L</register_predicate>. The legacy 2-arg form

    File::Raw::grep_lines($path, 'is_blank');

is sugar for going through this plugin.

=head1 IMPORT STYLE

    use File::Raw qw(:all);              # Import all functions as file_*
    use File::Raw qw(slurp spew lines);  # Import specific functions
    use File::Raw qw(import);            # Same as :all (backwards compat)

When imported, the functions are installed with `file_` prefix and use
custom ops for maximum performance (eliminating function call overhead).

    use File::Raw qw(slurp spew);
    
    my $content = file_slurp($path);
    file_spew($path, $data);

Available imports: slurp, slurp_raw, spew, append, atomic_spew, lines,
exists, size, mtime, atime, ctime, mode, is_file, is_dir, is_link,
is_readable, is_writable, is_executable, unlink, mkdir, rmdir, touch,
copy, move, chmod, readdir, basename, dirname, extname, clear_stat_cache.

=head1 PERFORMANCE NOTES

=head2 Platform Optimizations

=over 4

=item * macOS: Uses copyfile() for native file copying

=item * Linux: Uses sendfile() for zero-copy file transfer

=item * Linux/BSD: Uses posix_fadvise() to hint sequential reads

=back

=head2 When to use File::Raw::stat

If you need multiple attributes from a file (size, mtime, is_file, etc.),
use C<File::Raw::stat()> instead of calling individual functions:

    # SLOW: 5 syscalls
    my $size    = File::Raw::size($path);
    my $mtime   = File::Raw::mtime($path);
    my $is_file = File::Raw::is_file($path);
    
    # FAST: 1 syscall
    my $st = File::Raw::stat($path);
    my ($size, $mtime, $is_file) = @{$st}{qw(size mtime is_file)};

=head1 XS API

File::Raw exposes a plugin C API via C<include/file_plugin.h>. Downstream
XS modules can register C-level plugins that File::Raw's read / write /
streaming dispatch routes calls into - no per-record C<call_sv>
overhead. The shared object is loaded with C<RTLD_GLOBAL> so symbols
resolve at load time without an explicit link step on Linux/macOS.

=head2 Types

=over 4

=item B<FilePluginPhase>

    FILE_PLUGIN_PHASE_READ      /* whole-file slurp transform           */
    FILE_PLUGIN_PHASE_WRITE     /* whole-file spew/append transform     */
    FILE_PLUGIN_PHASE_RECORD    /* per-record dispatch                  */
    FILE_PLUGIN_PHASE_STREAM    /* chunked feed for streaming           */

=item B<FilePluginContext>

Per-call dispatch context (lifetime: single dispatch call).

    typedef struct FilePluginContext {
        const char  *path;          /* file path                        */
        SV          *data;          /* read: bytes; write: payload      */
        SV          *callback;      /* per-record cb (stream phase)     */
        HV          *options;       /* per-call opts; mortal; never NULL*/
        int          phase;
        int          cancel;        /* set non-zero to cancel op        */
        void        *plugin_state;  /* opaque, copied from plugin->state*/
    } FilePluginContext;

=item B<FilePlugin>

Registration block; the caller owns the storage (typically a file-scope
static) and must keep it alive for as long as the plugin is registered.

    typedef struct FilePlugin {
        const char            *name;
        file_plugin_read_fn    read_fn;    /* NULL if not implemented */
        file_plugin_write_fn   write_fn;
        file_plugin_record_fn  record_fn;
        file_plugin_stream_fn  stream_fn;
        void                  *state;
    } FilePlugin;

Phase signatures:

    typedef SV*  (*file_plugin_read_fn)   (pTHX_ FilePluginContext *ctx);
    typedef SV*  (*file_plugin_write_fn)  (pTHX_ FilePluginContext *ctx);
    typedef SV*  (*file_plugin_record_fn) (pTHX_ FilePluginContext *ctx, SV *record);
    typedef int  (*file_plugin_stream_fn) (pTHX_ FilePluginContext *ctx,
                                           const char *chunk, size_t len, int eof);

=back

=head2 Functions

=over 4

=item B<file_register_plugin>

    int file_register_plugin(pTHX_ const FilePlugin *plugin);

Returns 1 on success, 0 if a plugin with the same name is already
registered (use C<file_unregister_plugin> first), -1 on invalid input
(NULL plugin, NULL/empty name). Call during module initialisation only
(not thread-safe).

=item B<file_unregister_plugin>

    int file_unregister_plugin(pTHX_ const char *name);

Remove a plugin by name. Returns 1 if found and removed.

=item B<file_lookup_plugin>

    const FilePlugin *file_lookup_plugin(pTHX_ const char *name);

Look up a plugin by name. Returns the registered struct or NULL.

=item B<file_plugin_dispatch_read> / B<file_plugin_dispatch_write> / B<file_plugin_dispatch_stream> / B<file_plugin_dispatch_record>

    SV*  file_plugin_dispatch_read  (pTHX_ HV *opts, const char *path, SV *bytes);
    SV*  file_plugin_dispatch_write (pTHX_ HV *opts, const char *path, SV *payload);
    SV*  file_plugin_dispatch_stream(pTHX_ HV *opts, const char *path, SV *cb);
    SV*  file_plugin_dispatch_record(pTHX_ HV *opts, const char *path, SV *record);

Each helper extracts the C<plugin> key from C<opts>, looks up the plugin
(croaks if unknown), confirms the requested phase function pointer is
non-NULL (croaks otherwise), builds a C<FilePluginContext> on the stack,
and invokes the phase function. These are the functions File::Raw's own
XSUBs call - downstream modules normally don't need to call them
directly.

=back

=head2 Example (downstream XS module)

    #include "EXTERN.h"
    #include "perl.h"
    #include "XSUB.h"
    #include <file_plugin.h>

    static SV* upper_read(pTHX_ FilePluginContext *ctx) {
        STRLEN len;
        char *src = SvPV(ctx->data, len);
        SV *out = newSVpvn(src, len);
        char *dst = SvPVX(out);
        STRLEN i;
        for (i = 0; i < len; i++)
            if (dst[i] >= 'a' && dst[i] <= 'z')
                dst[i] -= 32;
        return out;
    }

    static FilePlugin upper_plugin = {
        "upper",
        upper_read, NULL, NULL, NULL,
        NULL
    };

    MODULE = MyModule  PACKAGE = MyModule

    BOOT:
        file_register_plugin(aTHX_ &upper_plugin);

After C<use MyModule>, callers can write
C<File::Raw::slurp($path, plugin =E<gt> 'upper')> and File::Raw routes
the slurped bytes through C<upper_read>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-fast at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Fast>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Raw

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Fast>

=item * Search CPAN

L<https://metacpan.org/release/File-Fast>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of File::Raw
