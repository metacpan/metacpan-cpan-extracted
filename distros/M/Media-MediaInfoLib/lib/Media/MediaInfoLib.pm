package Media::MediaInfoLib;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.01";

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Media::MediaInfoLib - Perl interface to the MediaInfoLib

=head1 SYNOPSIS

    use Media::MediaInfoLib qw(STREAM_VIDEO);
    my $info = Media::MediaInfoLib->open('/path/to/file.mp4');
    print $info->get(STREAM_VIDEO, 0, 'BitRate'), "\n";
    print $info->inform, "\n";

=head1 DESCRIPTION

Media::MediaInfoLib module provides an interface to the MediaInfoLib.

=head1 METHODS

=head2 Media::MediaInfoLib->open($filename_or_content)

Open the file (Scalar) or content (ScalarRef).

=head2 $info->inform()

Get all details about a file in one string.

=head2 $info->get($stream_kind, $stream_number, $parameter [,$info_kind = INFO_TEXT, $search_kind = INFO_NAME])

Get a piece of information about a file.

=head2 $info->option($option [,$value = ""])

Configure or get information about MediaInfoLib.

=head2 $info->option_static($option [,$value = ""])

Configure or get information about MediaInfoLib.

=head2 $info->count_get($stream_kind [,$stream_number = -1])

Count of streams of a stream kind, or count of piece of information in this stream.

=head1 CONSTANTS

=head2 STREAM_GENERAL

=head2 STREAM_VIDEO

=head2 STREAM_AUDIO

=head2 STREAM_TEXT

=head2 STREAM_OTHER

=head2 STREAM_IMAGE

=head2 STREAM_MENU

=head2 INFO_NAME

=head2 INFO_TEXT

=head2 INFO_MEASURE

=head2 INFO_OPTIONS

=head2 INFO_NAME_TEXT

=head2 INFO_MEASURE_TEXT

=head2 INFO_INFO

=head2 INFO_HOWTO

=head2 INFO_DOMAIN

=head1 SEE ALSO

L<https://github.com/MediaArea/MediaInfoLib>

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
