package File::Headerinfo::WAV;

use strict;
use base qw(File::Headerinfo);
use Audio::Wav;

=head1 NAME

File::Headerinfo::WAV - an extractor of useful information from WAV files.

=head1 DESCRIPTION

I<File::Headerinfo::WAV> uses Audio::WAV to read the headers of .wav files and extract useful information like their duration and filesize and, er, that's it at the moment.

=cut

sub parse_file {
    my $self = shift;
    my $w = Audio::Wav->new;
    my $info = $w->read($self->path);
    return unless $info;
    my $details = $info->details;

    $self->filetype( 'wav' );
    $self->filesize($info->length);
    $self->duration($info->length_seconds);
    $self->metadata($info->get_info);
    $self->freq($details->{sample_rate});
    $self->datarate($details->{bytes_sec});
    
    undef $info;
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Headerinfo>, L<Audio::WAV>

=cut

1;