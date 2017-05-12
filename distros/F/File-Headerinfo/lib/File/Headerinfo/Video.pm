package File::Headerinfo::Video;

use strict;
use base qw(File::Headerinfo);
use Video::Info;

=head1 NAME

File::Headerinfo::Video - an extractor of useful information from video files.

=head1 DESCRIPTION

I<File::Headerinfo::Video> uses Video::Info to read the headers of video clips (of various kinds) and a few audio files, and extract from them the useful information we crave. It can handle all the types that Video::Info can handle, including quicktime files, mpegs, DivX, AVI and ASF files.

=cut

sub parse_file {
    my $self = shift;
    my $info = Video::Info->new(-file => $self->path);
    return unless $info;
    $self->width( $info->width );
    $self->height( $info->height );
    $self->duration( $info->duration );
    $self->fps( $info->fps );
    $self->filesize( $info->filesize );
    $self->filetype( lc($info->type) );
    $self->vcodec( $info->vcodec );
    $self->datarate( $info->vrate );
    $self->freq( $info->afrequency );
    undef $info;
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Headerinfo>, L<Video::Info>

=cut

1;