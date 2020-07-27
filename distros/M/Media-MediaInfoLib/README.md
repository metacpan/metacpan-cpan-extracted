[![Actions Status](https://github.com/spiritloose/Media-MediaInfoLib/workflows/test/badge.svg)](https://github.com/spiritloose/Media-MediaInfoLib/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Media-MediaInfoLib.svg)](https://metacpan.org/release/Media-MediaInfoLib)
# NAME

Media::MediaInfoLib - Perl interface to the MediaInfoLib

# SYNOPSIS

    use Media::MediaInfoLib qw(STREAM_VIDEO);
    my $info = Media::MediaInfoLib->open('/path/to/file.mp4');
    print $info->get(STREAM_VIDEO, 0, 'BitRate'), "\n";
    print $info->inform, "\n";

# DESCRIPTION

Media::MediaInfoLib module provides an interface to the MediaInfoLib.

# METHODS

## Media::MediaInfoLib->open($filename\_or\_content)

Open the file (Scalar) or content (ScalarRef).

## $info->inform()

Get all details about a file in one string.

## $info->get($stream\_kind, $stream\_number, $parameter \[,$info\_kind = INFO\_TEXT, $search\_kind = INFO\_NAME\])

Get a piece of information about a file.

## $info->option($option \[,$value = ""\])

Configure or get information about MediaInfoLib.

## $info->option\_static($option \[,$value = ""\])

Configure or get information about MediaInfoLib.

## $info->count\_get($stream\_kind \[,$stream\_number = -1\])

Count of streams of a stream kind, or count of piece of information in this stream.

# CONSTANTS

## STREAM\_GENERAL

## STREAM\_VIDEO

## STREAM\_AUDIO

## STREAM\_TEXT

## STREAM\_OTHER

## STREAM\_IMAGE

## STREAM\_MENU

## INFO\_NAME

## INFO\_TEXT

## INFO\_MEASURE

## INFO\_OPTIONS

## INFO\_NAME\_TEXT

## INFO\_MEASURE\_TEXT

## INFO\_INFO

## INFO\_HOWTO

## INFO\_DOMAIN

# SEE ALSO

[https://github.com/MediaArea/MediaInfoLib](https://github.com/MediaArea/MediaInfoLib)

# LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>
