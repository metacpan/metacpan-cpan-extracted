package File::Headerinfo::MP3;

use strict;
use base qw(File::Headerinfo);
use MP3::Info;

=head1 NAME

File::Headerinfo::MP3 - an extractor of useful information from mp3 files.

=head1 DESCRIPTION

I<File::Headerinfo::MP3> uses MP3::Info to read the headers of .mp3 files and extract descriptive information and metadata.

=cut

sub parse_file {
    my $self = shift;
    my $mp3 = MP3::Info::get_mp3info($self->path);
    my $tags = MP3::Info::get_mp3tag($self->path);
    
    $self->filetype('mp3');
    $self->duration($mp3->{SECS});
    $self->datarate($mp3->{BITRATE});
    $self->freq($mp3->{FREQUENCY});
    $self->filesize($mp3->{SIZE});
    $self->metadata($tags)
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Headerinfo>, L<MP3::Info>

=cut

1;