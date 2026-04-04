package File::Raw;

use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('File::Raw', $VERSION);

1;

__END__

=head1 NAME

File::Raw - Fast IO operations using direct system calls

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

Fast IO operations using direct system calls, bypassing PerlIO overhead.
This module provides significantly faster file operations compared to
Perl's built-in IO functions.

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

Returns a line iterator object for memory-efficient line processing.

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

=head2 register_line_callback

    File::Raw::register_line_callback($name, \&predicate);

Register a custom predicate for use with grep_lines, count_lines, etc.

    File::Raw::register_line_callback('has_error', sub { /ERROR/ });
    my $errors = File::Raw::grep_lines($path, 'has_error');

=head2 list_line_callbacks

    my $names = File::Raw::list_line_callbacks();

Returns arrayref of registered predicate names.

=head1 HOOKS

File::Raw supports read/write hooks for data transformation.

=head2 register_read_hook

    File::Raw::register_read_hook(\&hook);

Register a hook that transforms data after reading.

    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        return uc($data);  # uppercase all content
    });

=head2 register_write_hook

    File::Raw::register_write_hook(\&hook);

Register a hook that transforms data before writing.

=head2 clear_hooks

    File::Raw::clear_hooks($phase);

Clear all hooks for a phase. Phase can be: read, write, open, close.

=head2 has_hooks

    if (File::Raw::has_hooks('read')) { ... }

Check if hooks are registered for a phase.

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
