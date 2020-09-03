# NAME

File::LibMagic - Determine MIME types of data or files using libmagic

# VERSION

version 1.23

# SYNOPSIS

    use File::LibMagic;

    my $magic = File::LibMagic->new;

    my $info = $magic->info_from_filename('path/to/file');
    # Prints a description like "ASCII text"
    print $info->{description};
    # Prints a MIME type like "text/plain"
    print $info->{mime_type};
    # Prints a character encoding like "us-ascii"
    print $info->{encoding};
    # Prints a MIME type with encoding like "text/plain; charset=us-ascii"
    print $info->{mime_with_encoding};

    my $file_content = read_file('path/to/file');
    $info = $magic->info_from_string($file_content);

    open my $fh, '<', 'path/to/file' or die $!;
    $info = $magic->info_from_handle($fh);

# DESCRIPTION

The `File::LibMagic` module is a simple perl interface to libmagic from the
file package (version 4.x or 5.x). You will need both the library
(`libmagic.so`) and the header file (`magic.h`) to build this Perl module.

## Installing libmagic

On Debian/Ubuntu run:

    sudo apt-get install libmagic-dev

on Red Hat run:

    sudo yum install file-devel

On Mac you can use homebrew (https://brew.sh/):

    brew install libmagic

## Specifying lib and/or include directories

On some systems, you may need to pass additional lib and include directories
to the Makefile.PL. You can do this with the \`--lib\` and \`--include\`
parameters:

    perl Makefile.PL --lib /usr/local/lib --include /usr/local/include

You can pass these parameters multiple times to specify more than one
location.

# API

This module provides an object-oriented API with the following methods:

## File::LibMagic->new

Creates a new File::LibMagic object.

Using the object oriented interface only opens the magic database once, which
is probably most efficient for repeated uses.

Each `File::LibMagic` object loads the magic database independently of other
`File::LibMagic` objects, so you may want to share a single object across
many modules.

This method takes the following named parameters:

- `magic_file`

    This should be a string or an arrayref containing one or more magic files.

    If a file you provide doesn't exist the constructor will throw an exception,
    but only with libmagic 4.17+.

    If you don't set this parameter, the constructor will throw an exception if it
    can't find any magic files at all.

    Note that even if you're using a custom file, you probably _also_ want to use
    the standard file (`/usr/share/misc/magic` on my system, yours may vary).

- `follow_symlinks`

    If this is true, then calls to `$magic->info_from_filename` will follow
    symlinks to the real file.

- `uncompress`

    If this is true, then compressed files (such as gzip files) will be
    uncompressed, and the various `info_from_*` methods will return info
    about the uncompressed file.

- Processing limits

    Newer versions of the libmagic library have a number of limits order to
    prevent malformed or malicious files from causing resource exhaustion or other
    errors.

    If your libmagic support it, you can set the following limits through
    constructor parameters. If your version does not support setting these limits,
    passing these options will cause the constructor to croak. In addition, the
    specific limits were introduced over a number of libmagic releases, and your
    version of libmagic may not support every parameter. Using a parameter that is
    not supported by your libmagic will also cause the constructor to cloak.

    - `max_indir`

        This limits recursion for indirection when processing entries in the
        magic file.

    - `max_name`

        This limits the maximum number of levels of name/use magic that will be
        processed in the magic file.

    - `max_elf_notes`

        This limits the maximum number of ELF notes that will be processed when
        determining a file's mime type.

    - `max_elf_phnum`

        This limits the maximum number of ELF program sections that will be processed
        when determining a file's mime type.

    - `max_elf_shnum`

        This limits the maximum number of ELF sections that will be processed when
        determining a file's mime type.

    - `max_regex`

        This limits the maximum size of regexes when processing entries in the magic
        file.

    - `max_bytes`

        This limits the maximum number of bytes read from a file when determining a
        file's mime type.

    The values of these parameters should be integer limits.

- `max_future_compat`

    For compatibility with future additions to the libmagic processing limit
    parameters, you can pass a `max_future_compat` parameter. This is a hash
    reference where the keys are constant values (integers defined by libmagic,
    not names) and the values are the limit you want to set.

## $magic->info\_from\_filename('path/to/file')

This method returns info about the given file. The return value is a hash
reference with four keys:

- `description`

    A textual description of the file content like "ASCII C program text".

- `mime_type`

    The MIME type without a character encoding, like "text/x-c".

- `encoding`

    Just the character encoding, like "us-ascii".

- `mime_with_encoding`

    The MIME type with a character encoding, like "text/x-c;
    charset=us-ascii". Note that if no encoding was found, this will be the same
    as the `mime_type` key.

## $magic->info\_from\_string($string)

This method returns info about the contents of the given string. The string
can be passed as a reference to save memory.

The return value is the same as that of `$mime->info_from_filename`.

## $magic->info\_from\_handle($fh)

This method returns info about the contents read from the given filehandle. It
will read data starting from the handle's current position, and leave the
handle at that same position after reading.

## File::LibMagic->max\_param\_constant

This method returns the maximum value that can be passed as a processing limit
parameter to the constructor. You can use this to determine if passing a
particular value in the `max_future_compat` constructor parameter will work.

This may include constant values that do not have corresponding `max_X`
constructor keys if your version of libmagic is newer than the one used to
build this distribution.

Conversely, if your version is older than it's possible that not all of the
defined keys will be supported.

## File::LibMagic->limit\_key\_is\_supported($key)

This method takes a processing limit key like `max_indir` or `max_name` and
returns a boolean indicating whether the linked version of libmagic supports
that processing limit.

# DISCOURAGED APIS

This module offers two different procedural APIs based on optional exports,
the "easy" and "complete" interfaces. There is also an older OO API still
available. All of these APIs are discouraged, but will not be removed in the
near future, nor will using them cause any warnings.

I strongly recommend you use the new OO API. It's simpler than the complete
interface, more efficient than the easy interface, and more featureful than
the old OO API.

## The Old OO API

This API uses the same constructor as the current API.

- $magic->checktype\_contents($data)

    Returns the MIME type of the data given as the first argument. The data can be
    passed as a plain scalar or as a reference to a scalar.

    This is the same value as would be returned by the `file` command with the
    `-i` switch.

- $magic->checktype\_filename($filename)

    Returns the MIME type of the given file.

    This is the same value as would be returned by the `file` command with the
    `-i` switch.

- $magic->describe\_contents($data)

    Returns a description (as a string) of the data given as the first argument.
    The data can be passed as a plain scalar or as a reference to a scalar.

    This is the same value as would be returned by the `file` command with no
    switches.

- $magic->describe\_filename($filename)

    Returns a description (as a string) of the given file.

    This is the same value as would be returned by the `file` command with no
    switches.

## The "easy" interface

This interface is exported by:

    use File::LibMagic ':easy';

This interface exports two subroutines:

- MagicBuffer($data)

    Returns the description of a chunk of data, just like the `describe_contents`
    method.

- MagicFile($filename)

    Returns the description of a file, just like the `describe_filename` method.

## The "complete" interface

This interface is exported by:

    use File::LibMagic ':complete';

This interface exports several subroutines:

- magic\_open($flags)

    This subroutine opens creates a magic handle. See the libmagic man page for a
    description of all the flags. These are exported by the `:complete` import.

        my $handle = magic_open(MAGIC_MIME);

- magic\_load($handle, $filename)

    This subroutine actually loads the magic file. The `$filename` argument is
    optional. There should be a sane default compiled into your `libmagic`
    library.

- magic\_buffer($handle, $data)

    This returns information about a chunk of data as a string. What it returns
    depends on the flags you passed to `magic_open`, a description, a MIME type,
    etc.

- magic\_file($handle, $filename)

    This returns information about a file as a string. What it returns depends on
    the flags you passed to `magic_open`, a description, a MIME type, etc.

- magic\_close($handle)

    Closes the magic handle.

# EXCEPTIONS

This module can throw an exception if your system runs out of memory when
trying to call `magic_open` internally.

# BUGS

This module is totally dependent on the version of file on your system. It's
possible that the tests will fail because of this. Please report these
failures so I can make the tests smarter. Please make sure to report the
version of file on your system as well!

# DEPENDENCIES/PREREQUISITES

This module requires file 4.x or file 5x and the associated libmagic library
and headers (https://darwinsys.com/file/).

# RELATED MODULES

Andreas created File::LibMagic because he wanted to use libmagic (from
file 4.x) [File::MMagic](https://metacpan.org/pod/File%3A%3AMMagic) only worked with file 3.x.

[File::MimeInfo::Magic](https://metacpan.org/pod/File%3A%3AMimeInfo%3A%3AMagic) uses the magic file from freedesktop.org which is
encoded in XML, and is thus not the fastest approach. See
[https://mail.gnome.org/archives/nautilus-list/2003-December/msg00260.html](https://mail.gnome.org/archives/nautilus-list/2003-December/msg00260.html)
for a discussion of this issue.

[File::Type](https://metacpan.org/pod/File%3A%3AType) uses a relatively small magic file, which is directly hacked
into the module code. It is quite fast but the database is quite small
relative to the file package.

# SUPPORT

Please submit bugs to the CPAN RT system at
https://rt.cpan.org/Public/Dist/Display.html?Name=File-LibMagic or via email at
bug-file-libmagic@rt.cpan.org.

Bugs may be submitted at [https://github.com/houseabsolute/File-LibMagic/issues](https://github.com/houseabsolute/File-LibMagic/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for File-LibMagic can be found at [https://github.com/houseabsolute/File-LibMagic](https://github.com/houseabsolute/File-LibMagic).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [https://www.urth.org/fs-donation.html](https://www.urth.org/fs-donation.html).

# AUTHORS

- Andreas Fitzner
- Michael Hendricks <michael@ndrix.org>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- E. Choroba <choroba@matfyz.cz>
- Mithun Ayachit <mayachit@amfam.com>
- Olaf Alders <olaf@wundersolutions.com>
- Paul Wise <pabs3@bonedaddy.net>
- Tom Wyant <wyant@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andreas Fitzner, Michael Hendricks, Dave Rolsky, and Paul Wise.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
