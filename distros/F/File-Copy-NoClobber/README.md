# NAME

File::Copy::NoClobber - Rename copied files safely if destination exists

# SYNOPSIS

    use File::Copy::NoClobber;

    copy( "file.txt", "elsewhere/" ); # elsewhere/file.txt
    copy( "file.txt", "elsewhere/" ); # elsewhere/file (01).txt

    # similar with move
    move( "file.txt", "elsewhere/" ); # elsewhere/file (02).txt

    use File::Copy::NoClobber -warn => 1; # warns when name is changed

    use File::Copy::NoClobber -pattern => "[%04d]" # custom noclobber

# DESCRIPTION

The module exports copy() and move(). They are wrappers around `copy`
and `move` in [File::Copy](https://metacpan.org/pod/File::Copy).

# INTERFACE

## copy( $from, $to \[, $buffersize\] )

Supports the same arguments as [File::Copy](https://metacpan.org/pod/File::Copy).

Checks if the operation would overwrite an existing file, if so adds a
counter to the destination filename as shown in the SYNOPSIS.

The module uses sysopen with O\_EXCL and an increasing counter to
determine a working filename. The second argument is then replaced
with this filehandle and passed to `File::Copy::copy`.

The counter inserted to filenames is `" (%02d)"` by default, but can
be changed on import.

It returns the filename written to or undef if unsuccessful.

## move( $from, $to )

Supports the same arguments as [File::Copy](https://metacpan.org/pod/File::Copy).

Determines destination filename in the same way as `copy`, but the
move operation is used on the filename rather than the filehandle, to
allow rename to be used.

# DEPENDENCIES

This module does not introduce dependencies. It does not use modules
not already in use in File::Copy.

# AUTHOR

Torbjørn Lindahl `torbjorn.lindahl@gmail.com`

# CONTRIBUTORS

Core ideas from _Botje_, _huf_ and _tm604_ in #perl@freenode

# LICENSE AND COPYRIGHT

Copyright (c) 2016, Torbjørn Lindahl `torbjorn.lindahl@gmail.com`.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
