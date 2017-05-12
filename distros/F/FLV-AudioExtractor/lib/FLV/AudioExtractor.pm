package FLV::AudioExtractor;

use strict;
use warnings;

use Moose;
use Carp;

our $VERSION = '0.01';

has filename => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

sub extract {
    my ($self, $output) = @_;

    open my $fh, '<', $self->filename or croak('Can\'t open ' . $self->filename . ': '  . $!);
    open my $mp3, '>', $output or croak('Cant\'t open ' . $output . ': ' . $!);
    binmode $fh;
    binmode $mp3;

    my $offset    = 13;
    my $data_size = 0;
    my $data      = undef;

    read($fh, $data, $offset);

    while(((-s $self->filename) - $offset) > $data_size) {
        read($fh, $data, 12);

        my @unpacked = unpack('C1 C3 C3 C1 C3 C1', $data);
        $data_size = ($unpacked[1] << 16) | ($unpacked[2] << 8) | $unpacked[3];

        read($fh, $data, ($data_size - 1));

        my $previous_tag_size = undef;
        read($fh, $previous_tag_size, 4);

        if($unpacked[0] == 8) {
            print $mp3 $data
              if ($unpacked[11] >> 4) == 2;
        }

        $offset += $data_size + 15;
    }
    close $fh;
    close $mp3;
}

1;

__END__

=encoding utf8

=head1 NAME

FLV::AudioExtractor - Extract audio from Flash Videos

=head1 SYNOPSIS

    my $ae = new FLV::AudioExtractor(filename => 'video.flv');
    $ae->extract('music.mp3');

=head1 DESCRIPTION

Module to extract the audio from the flash video file (*.flv).

=head1 METHODS

=head2 extract($output)

Extract audio from flv files and writes a new file.

=head2 SEE ALSO

L<Flash Video at Wikipedia|http://en.wikipedia.org/wiki/Flash_Video>
L<FLV Format Specification|http://www.adobe.com/devnet/f4v.html>.

=head1 AUTHOR

Junior Moraes <fvox@cpan.org>. Special thanks to Elsio Antunes.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Junior Moraes

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.4 or, at your option, any later version of Perl 5 you may have available.

=cut
