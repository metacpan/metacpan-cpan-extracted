# NAME

File::Slurp - Simple and Efficient Reading/Writing/Modifying of Complete Files

# SYNOPSIS

```perl
use File::Slurp;

# read in a whole file into a scalar
my $text = read_file( 'filename' ) ;

# read in a whole file into an array of lines
my @lines = read_file( 'filename' ) ;

# write out a whole file from a scalar
write_file( 'filename', $text ) ;

# write out a whole file from an array of lines
write_file( 'filename', @lines ) ;

# Here is a simple and fast way to load and save a simple config file
# made of key=value lines.
my %conf = read_file( $file_name ) =~ /^(\w+)=(.*)$/mg ;
write_file( $file_name, {atomic => 1}, map "$_=$conf{$_}\n", keys %conf ) ;

# insert text at the beginning of a file
prepend_file( 'filename', $text ) ;

# in-place edit to replace all 'foo' with 'bar' in file
edit_file { s/foo/bar/g } 'filename' ;

# in-place edit to delete all lines with 'foo' from file
edit_file_lines sub { $_ = '' if /foo/ }, 'filename' ;

# read in a whole directory of file names (skipping . and ..)
my @files = read_dir( '/path/to/dir' ) ;
```

# DESCRIPTION

This module provides subs that allow you to read or write entire files
with one simple call. They are designed to be simple to use, have
flexible ways to pass in or get the file contents and to be very
efficient.  There is also a sub to read in all the files in a
directory.

These slurp/spew subs work for files, pipes and sockets, stdio,
pseudo-files, and the `DATA` handle.

# FUNCTIONS

[File::Slurp](https://metacpan.org/pod/File::Slurp) implements the following functions.

## append\_file

```perl
    use File::Spec qw(append_file write_file);
    my $res = append_file('/path/to/file', "Some text");
    # same as
    my $res = write_file('/path/to/file', {append => 1}, "Some text");
```

The `append_file` function is simply a synonym for the
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) function, but ensures that the `append` option is
set.

## edit\_file

```perl
    use File::Slurp qw(edit_file);
    # perl -0777 -pi -e 's/foo/bar/g' filename
    edit_file { s/foo/bar/g } 'filename';
    edit_file sub { s/foo/bar/g }, 'filename';
    sub replace_foo { s/foo/bar/g }
    edit_file \&replace_foo, 'filename';
```

The `edit_file` function reads in a file into `$_`, executes a code block that
should modify `$_`, and then writes `$_` back to the file. The `edit_file`
function reads in the entire file and calls the code block one time. It is
equivalent to the `-pi` command line options of Perl but you can call it from
inside your program and not have to fork out a process.

The first argument to `edit_file` is a code block or a code reference. The
code block is not followed by a comma (as with `grep` and `map`) but a code
reference is followed by a comma.

The next argument is the filename.

The next argument(s) is either a hash reference or a flattened hash,
`key => value` pairs. The options are passed through to the
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) function. All options are described there.
Only the `binmode` and `err_mode` options are supported. The call to
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) has the `atomic` option set so you will always
have a consistent file.

## edit\_file\_lines

```perl
    use File::Slurp qw(edit_file_lines);
    # perl -pi -e '$_ = "" if /foo/' filename
    edit_file_lines { $_ = '' if /foo/ } 'filename';
    edit_file_lines sub { $_ = '' if /foo/ }, 'filename';
    sub delete_foo { $_ = '' if /foo/ }
    edit_file \&delete_foo, 'filename';
```

The `edit_file_lines` function reads each line of a file into `$_`, and
executes a code block that should modify `$_`. It will then write `$_` back
to the file. It is equivalent to the `-pi` command line options of Perl but
you can call it from inside your program and not have to fork out a process.

The first argument to `edit_file_lines` is a code block or a code reference.
The code block is not followed by a comma (as with `grep` and `map`) but a
code reference is followed by a comma.

The next argument is the filename.

The next argument(s) is either a hash reference or a flattened hash,
`key => value` pairs. The options are passed through to the
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) function. All options are described there.
Only the `binmode` and `err_mode` options are supported. The call to
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) has the `atomic` option set so you will always
have a consistent file.

## ef

```perl
    use File::Slurp qw(ef);
    # perl -0777 -pi -e 's/foo/bar/g' filename
    ef { s/foo/bar/g } 'filename';
    ef sub { s/foo/bar/g }, 'filename';
    sub replace_foo { s/foo/bar/g }
    ef \&replace_foo, 'filename';
```

The `ef` function is simply a synonym for the ["edit\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#edit_file)
function.

## efl

```perl
    use File::Slurp qw(efl);
    # perl -pi -e '$_ = "" if /foo/' filename
    efl { $_ = '' if /foo/ } 'filename';
    efl sub { $_ = '' if /foo/ }, 'filename';
    sub delete_foo { $_ = '' if /foo/ }
    efl \&delete_foo, 'filename';
```

The `efl` function is simply a synonym for the ["edit\_file\_lines" in File::Slurp](https://metacpan.org/pod/File::Slurp#edit_file_lines)
function.

## overwrite\_file

```perl
    use File::Spec qw(overwrite_file);
    my $res = overwrite_file('/path/to/file', "Some text");
```

The `overwrite_file` function is simply a synonym for the
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) function.

## prepend\_file

```perl
    use File::Slurp qw(prepend_file);
    prepend_file($file, $header);
    prepend_file($file, \@lines);
    prepend_file($file, { binmode => 'raw:'}, $bin_data);

    # equivalent to:
    use File::Slurp qw(read_file write_file);
    my $content = read_file('file_name');
    my $new_content = "hahahaha";
    write_file('file_name', $new_content . $content);
```

The `prepend_file` function is the opposite of ["append\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#append_file) as
it writes new contents to the beginning of the file instead of the end. It is a
combination of ["read\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#read_file) and ["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file). It
works by first using `read_file` to slurp in the file and then calling
`write_file` with the new data and the existing file data.

The first argument to `prepend_file` is the filename.

The next argument(s) is either a hash reference or a flattened hash,
`key => value` pairs. The options are passed through to the
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) function. All options are described there.

Only the `binmode` and `err_mode` options are supported. The
`write_file` call has the `atomic` option set so you will always have
a consistent file.

## read\_dir

```perl
    use File::Spec qw(read_dir);
    my @files = read_dir('/path/to/dir');
    # all files, even the dots
    my @files = read_dir('/path/to/dir', keep_dot_dot => 1);
    # keep the full file path
    my @paths = read_dir('/path/to/dir', prefix => 1);
    # scalar context
    my $files_ref = read_dir('/path/to/dir');
```

This function returns a list of the filenames in the supplied directory. In
list context, an array is returned, in scalar context, an array reference is
returned.

The first argument is the path to the directory to read.

The next argument(s) is either a hash reference or a flattened hash,
`key => value` pairs. The following options are available:

- err\_mode

    The `err_mode` option has three possible values: `quiet`, `carp`, or the
    default, `croak`. In `quiet` mode, all errors will be silent. In `carp` mode,
    all errors will be emitted as warnings. And, in `croak` mode, all errors will
    be emitted as exceptions. Take a look at [Try::Tiny](https://metacpan.org/pod/Try::Tiny) or
    [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax::Keyword::Try) to see how to catch exceptions.

- keep\_dot\_dot

    The `keep_dot_dot` option is a boolean option, defaulted to false (`0`).
    Setting this option to true (`1`) will also return the `.` and `..` files
    that are removed from the file list by default.

- prefix

    The `prefix` option is a boolean option, defaulted to false (`0`).
    Setting this option to true (`1`) add the directory as a prefix to the file.
    The directory and the filename are joined using `File::Spec->catfile()` to
    ensure the proper directory separator is used for your OS. See [File::Spec](https://metacpan.org/pod/File::Spec).

## read\_file

```perl
    use File::Slurp qw(read_file);
    my $text = read_file('filename');
    my $bin = read_file('filename', { binmode => ':raw' });
    my @lines = read_file('filename');
    my $lines_ref = read_file('file_name', array_ref => 1);
    my $lines_ref = [ read_file('file_name') ];

    # or we can read into a buffer:
    my $buffer;
    read_file('file_name', buf_ref => \$buffer);

    # or we can set the block size for the read
    my $text_ref = read_file(\*STDIN, blk_size => 10_000_000, array_ref => 1);

    # or we can get a scalar reference
    my $text_ref = read_file('file_name', scalar_ref => 1);
```

This function reads in an entire file and returns its contents to the
caller. In scalar context it returns the entire file as a single
scalar. In list context it will return a list of lines (using the
current value of `$/` as the separator, including support for paragraph
mode when it is set to `''`).

The first argument is the file to be slurped in. It can be a path to a file, an
open file handle (`\*DATA`, `\*STDIN`). Overloaded objects use the stringified
file path.

The next argument(s) is either a hash reference or a flattened hash,
`key => value` pairs. The following options are available:

- array\_ref

    The `array_ref` option is a boolean option, defaulted to false (`0`). Setting
    this option to true (`1`) will only have relevance if the `read_file` function
    is called in scalar context. When true, the `read_file` function will return
    a reference to an array of the lines in the file.

- binmode

    The `binmode` option is a string option, defaulted to empty (`''`). If you
    set the `binmode` option, then its value is passed to a call to `binmode` on
    the opened handle. You can use this to set the file to be read in binary mode,
    utf8, etc. See `perldoc -f binmode` for more.

- blk\_size

    You can use this option to set the block size used when slurping from
    an already open handle (like `\*STDIN`). It defaults to 1MB.

- buf\_ref

    The `buf_ref` option can be used in conjunction with any of the other options.
    You can use this option to pass in a scalar reference and the slurped
    file contents will be stored in the scalar. This saves an extra copy of
    the slurped file and can lower RAM usage vs returning the file. It is
    usually the fastest way to read a file into a scalar.

- chomp

    The `chomp` option is a boolean option, defaulted to false (`0`). Setting
    this option to true (`1`) will cause each line to have its contents `chomp`ed.
    This option works in list context or in scalar context with the `array_ref`
    option.

- err\_mode

    The `err_mode` option has three possible values: `quiet`, `carp`, or the
    default, `croak`. In `quiet` mode, all errors will be silent. In `carp` mode,
    all errors will be emitted as warnings. And, in `croak` mode, all errors will
    be emitted as exceptions. Take a look at [Try::Tiny](https://metacpan.org/pod/Try::Tiny) or
    [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax::Keyword::Try) to see how to catch exceptions.

- scalar\_ref

    The `scalar_ref` option is a boolean option, defaulted to false (`0`). It only
    has meaning in scalar context. The return value will be a scalar reference to a
    string which is the contents of the slurped file. This will usually be faster
    than returning the plain scalar. It will also save memory as it will not make a
    copy of the file to return.

## rf

```perl
    use File::Spec qw(rf);
    my $text = rf('/path/to/file');
```

The `rf` function is simply a synonym for the ["read\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#read_file)
function.

## slurp

```perl
    use File::Spec qw(slurp);
    my $text = slurp('/path/to/file');
```

The `slurp` function is simply a synonym for the ["read\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#read_file)
function.

## wf

```perl
    use File::Spec qw(wf);
    my $res = wf('/path/to/file', "Some text");
```

The `wf` function is simply a synonym for the
["write\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#write_file) function.

## write\_file

```perl
    use File::Slurp qw(write_file);
    write_file('filename', @data);
    write_file('filename', {append => 1}, @data);
    write_file('filename', {binmode => ':raw'}, $buffer);
    write_file('filename', \$buffer);
    write_file('filename', $buffer);
    write_file('filename', \@lines);
    write_file('filename', @lines);

    # binmode
    write_file($bin_file, {binmode => ':raw'}, @data);
    write_file($bin_file, {binmode => ':utf8'}, $utf_text);

    # buffered
    write_file($bin_file, {buf_ref => \$buffer});
    write_file($bin_file, \$buffer);
    write_file($bin_file, $buffer);

    # append
    write_file($file, {append => 1}, @data);

    # no clobbering
    write_file($file, {no_clobber => 1}, @data);
```

This function writes out an entire file in one call. By default `write_file`
returns `1` upon successfully writing the file or `undef` if it encountered
an error. You can change how errors are handled with the `err_mode` option.

The first argument to `write_file` is the filename.

The next argument(s) is either a hash reference or a flattened hash,
`key => value` pairs. The following options are available:

- append

    The `append` option is a boolean option, defaulted to false (`0`). Setting
    this option to true (`1`) will cause the data to be be written at the end of
    the current file. Internally this sets the `sysopen` mode flag `O_APPEND`.

    The ["append\_file" in File::Slurp](https://metacpan.org/pod/File::Slurp#append_file) function sets this option by default.

- atomic

    The `atomic` option is a boolean option, defaulted to false (`0`). Setting
    this option to true (`1`) will cause the file to be be written to in an
    atomic fashion. A temporary file name is created by appending the pid
    (`$$`) to the file name argument and that file is spewed to. After the
    file is closed it is renamed to the original file name (and `rename` is
    an atomic operation on most OSes). If the program using this were to
    crash in the middle of this, then the file with the pid suffix could
    be left behind.

- binmode

    The `binmode` option is a string option, defaulted to empty (`''`). If you
    set the `binmode` option, then its value is passed to a call to `binmode` on
    the opened handle. You can use this to set the file to be read in binary mode,
    utf8, etc. See `perldoc -f binmode` for more.

- buf\_ref

    The `buf_ref` option is used to pass in a scalar reference which has the
    data to be written. If this is set then any data arguments (including
    the scalar reference shortcut) in `@_` will be ignored.

- err\_mode

    The `err_mode` option has three possible values: `quiet`, `carp`, or the
    default, `croak`. In `quiet` mode, all errors will be silent. In `carp` mode,
    all errors will be emitted as warnings. And, in `croak` mode, all errors will
    be emitted as exceptions. Take a look at [Try::Tiny](https://metacpan.org/pod/Try::Tiny) or
    [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax::Keyword::Try) to see how to catch exceptions.

- no\_clobber

    The `no_clobber` option is a boolean option, defaulted to false (`0`). Setting
    this option to true (`1`) will ensure an that existing file will not be
    overwritten.

- perms

    The `perms` option sets the permissions of newly-created files. This value
    is modified by your process's `umask` and defaults to `0666` (same as
    `sysopen`).

    NOTE: this option is new as of File::Slurp version 9999.14;

# EXPORT

These are exported by default or with

```perl
    use File::Slurp qw(:std);
    # read_file write_file overwrite_file append_file read_dir
```

These are exported with

```perl
    use File::Slurp qw(:edit);
    # edit_file edit_file_lines
```

You can get all subs in the module exported with

```perl
    use File::Slurp qw(:all);
```

# AUTHOR

Uri Guttman, <`uri@stemsystems.com`>

# COPYRIGHT & LICENSE

Copyright (c) 2003 Uri Guttman. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
