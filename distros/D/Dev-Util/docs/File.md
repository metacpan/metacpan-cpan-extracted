# NAME

Dev::Util::File - General utility functions for files and directories.

# VERSION

Version v2.19.35

# SYNOPSIS

Dev::Util::File - provides functions to assist working with files and dirs, menus and prompts.

    use Dev::Util::File;

    my $fexists   = file_exists('/path/to/somefile');
    my $canreadf  = file_readable('/path/to/somefile');
    my $canwritef = file_writable('/path/to/somefile');
    my $canexecf  = file_executable('/path/to/somefile');

    my $isemptyfile = file_is_empty('/path/to/somefile');
    my $fileissize = file_size_equals('/path/to/somefile', $number_of_bytes);

    my $isplainfile = file_is_plain('/path/to/somefile');
    my $issymlink = file_is_symbolic_link('/path/to/somefile');
    ...

    my $dexists  = dir_exists('/path/to/somedir');
    my $canreadd  = dir_readable('/path/to/somedir');
    my $canwrited = dir_writable('/path/to/somedir');

    my $slash_added_dir = dir_suffix_slash('/dir/path/no/slash');

    my $td = mk_temp_dir();
    my $tf = mk_temp_file($td);

    my $file_date     = stat_date( $test_file, 0, 'daily' );    # 20240221
    my $file_date     = stat_date( $test_file, 1, 'monthly' );  # 2024/02

    my $mtime =  status_for($file)->{mtime}

    my $scalar_list = read_list(FILE);
    my @array_list  = read_list(FILE);

# EXPORT\_TAGS

- **:fattr**
    - file\_exists
    - file\_readable
    - file\_writable
    - file\_executable
    - file\_is\_empty
    - file\_size\_equals
    - file\_owner\_effective
    - file\_owner\_real
    - file\_is\_setuid
    - file\_is\_setgid
    - file\_is\_sticky
    - file\_is\_ascii
    - file\_is\_binary
- **:ftypes**
    - file\_is\_plain
    - file\_is\_symbolic\_link
    - file\_is\_pipe
    - file\_is\_socket
    - file\_is\_block
    - file\_is\_character
- **:dirs**
    - dir\_exists
    - dir\_readable
    - dir\_writable
    - dir\_executable
    - dir\_suffix\_slash
- **:misc**
    - mk\_temp\_dir
    - mk\_temp\_file
    - stat\_date
    - status\_for
    - read\_list

# SUBROUTINES

## **file\_exists(FILE)**

Tests for file existence.  Returns true if the file exists, false if it does not.

**All of the subroutines return 1 for true and 0 for false.**

`FILE` a string or variable pointing to a file.

    my $fexists  = file_exists('/path/to/somefile');

## **file\_readable(FILE)**

Tests for file existence and is readable.  Returns true if file is readable, false if not.

    my $canreadf  = file_readable('/path/to/somefile');

## **file\_writable(FILE)**

Tests for file existence and is writable. Returns true if file is writable, false if not.

    my $canwritef = file_writable('/path/to/somefile');

## **file\_executable(FILE)**

Tests for file existence and is executable.  Returns true if file is executable, false if not.

    my $canexecf  = file_executable('/path/to/somefile');

## **file\_is\_empty(FILE)**

Check if the file is zero sized. Returns true if file is zero bytes, false if not.

    my $isemptyfile = file_is_empty('/path/to/somefile');

## **file\_size\_equals(FILE, BYTES)**

Check if the file size equals given size. Returns true if file is the given number of bytes, false if not.

`BYTES` The number of bytes to test for.

    my $fileissize = file_size_equals('/path/to/somefile', $number_of_bytes);

## **file\_owner\_effective(FILE)**

Check if the file is owned by the effective uid. Returns true if file is owned by the effective user, false if not.

    my $effectiveuserowns = file_owner_effective('/path/to/somefile');

## **file\_owner\_real(FILE)**

Check if the file is owned by the real uid. Returns true if file is owned by the real user, false if not.

    my $realuserowns = file_owner_real('/path/to/somefile');

## **file\_is\_setuid(FILE)**

Check if the file has setuid bit set.  Returns true if file is setuid, for example: `.r-Sr--r--`

    my $isfilesuid = file_is_setuid('/path/to/somefile');

## **file\_is\_setgid(FILE)**

Check if the file has setgid bit set.  Returns true if file is setgid, for example: `.r--r-Sr--`

    my $isfileguid = file_is_setgid('/path/to/somefile');

## **file\_is\_sticky(FILE)**

Check if the file has sticky bit set.  Returns true if file is sticky, for example: `.r--r--r-T`

    my $isfilesticky = file_is_sticky('/path/to/somefile');

## **file\_is\_ascii(FILE)**

Check if the file is an ASCII or UTF-8 text file (heuristic guess).  Returns true if file is ascii, false if binary.

    my $isfileascii = file_is_ascii('/path/to/somefile');

## **file\_is\_binary(FILE)**

Check if the file is a "binary" file (opposite of `file_is_ascii`). Returns true if file is binary, false if ascii.

    my $isfilebinary = file_is_binary('/path/to/somefile');

## **file\_is\_plain(FILE)**

Tests that file is a regular file.  Returns true if file is a plain file, false if not.

    my $isplainfile = file_is_plain('/path/to/somefile');

## **file\_is\_symbolic\_link(FILE)**

Tests that file is a symbolic link.  Returns true if file is a symbolic link, for example: `lr--r--r--`

    my $issymlink = file_is_symbolic_link('/path/to/somefile');

## **file\_is\_pipe(FILE)**

Tests that file is a named pipe. Returns true if file is a pipe, for example: `|rw-rw-rw-`

    my $ispipe = file_is_pipe('/path/to/somefile');

## **file\_is\_socket(FILE)**

Tests that file is a socket. Returns true if file is a socket, for example: `srw-------`

    my $issocket = file_is_socket('/path/to/somefile');

## **file\_is\_block(FILE)**

Tests that file is a block special file. Returns true if file is a block file, for example: `brw-r-----`

    my $isblock = file_is_block('/path/to/somefile');

## **file\_is\_character(FILE)**

Tests that file is a block character file. Returns true if file is a block character file, for example: `crw-r-----`

    my $ischarf = file_is_character('/path/to/somefile');

## **dir\_exists(DIR)**

Tests for dir existence.  Returns true if the directory exists, false if not.

`DIR` a string or variable pointing to a directory.

    my $dexists  = dir_exists('/path/to/somedir');

## **dir\_readable(DIR)**

Tests for dir existence and is readable. Returns true if the directory is readable, false if not.

    my $canreadd  = dir_readable('/path/to/somedir');

## **dir\_writable(DIR)**

Tests for dir existence and is writable. Returns true if the directory is writable, false if not.

    my $canwrited = dir_writable('/path/to/somedir');

## **dir\_executable(DIR)**

Tests for dir existence and is executable. Returns true if the directory is executable, false if not.

    my $canenterdir = dir_executable('/path/to/somedir');

## **dir\_suffix\_slash(DIR)**

Ensures a dir ends in a slash by adding one if necessary.

    my $slash_added_dir = dir_suffix_slash('/dir/path/no/slash');

## **mk\_temp\_dir(DIR)**

Create a temporary directory in the supplied parent dir. `/tmp` is the default if no dir given.

`DIR` a string or variable pointing to a directory.

    my $td = mk_temp_dir();

## **mk\_temp\_file(DIR)**

Create a temporary file in the supplied dir. `/tmp` is the default if no dir given.

    my $tf = mk_temp_file($td);

## **stat\_date(FILE, DIR\_FORMAT, DATE\_FORMAT)**

Return the stat date of a file

`DIR_FORMAT` Style of date, include slashes? 0: YYYYMMDD, 1: YYYY/MM/DD 

`DATE_FORMAT` Granularity of date: daily: YYYYMMDD, monthly: YYYY/MM 

    my $file_date     = stat_date( $test_file, 0, 'daily' );    # 20240221
    my $file_date     = stat_date( $test_file, 1, 'monthly' );  # 2024/02

       format: YYYYMMDD,
    or format: YYYY/MM/DD if dir_format is true
    or format: YYYYMM or YYYY/MM if date_type is monthly

## **status\_for**

Return hash\_ref of file stat info.

    my $stat_info_ref = status_for($file);
    my $mtime = $stat_info_ref->{mtime};

Available keys:

    dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks

## **read\_list**

Read a list from an input file return an array of lines if called in list context.
If called by scalar context it will slurp the whole file and return it as a scalar.
Comments (begins with #) and blank lines are skipped.

    my $scalar_list = read_list(FILE);
    my @array_list  = read_list(FILE);

**Note**: The API for this function is maintained to support the existing code base that uses it.
It would probably be better to use `Perl6::Slurp` or `File::Slurper` for new code.

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::File

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- Search CPAN

    [https://metacpan.org/release/Dev-Util](https://metacpan.org/release/Dev-Util)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2019-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
