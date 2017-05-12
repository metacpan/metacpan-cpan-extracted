package Flv::Info::Lite;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( flv_info );
our @EXPORT    = qw();
our $VERSION   = '0.03';

sub flv_info {
    my %tag_type = (
        8  => 'audio',
        9  => 'video',
        18 => 'script',
    );

    my %audio_format = (
        0  => 'uncompressed',
        1  => 'ADPCM',
        2  => 'MP3',
        3  => 'Linear_PCM_little_endian',
        4  => 'Nellymoser_16kHz_mono',
        5  => 'Nellymoser_8kHz_mono',
        6  => 'Nellymoser',
        7  => 'G.711_A-law',
        8  => 'G.711_mu-law',
        10 => 'AAC',
        11 => 'Speex',
        14 => 'MP3_8kHz',
        15 => 'Device-specific_sound',
    );

    my %audio_rate = (
        0 => '5518Hz',
        1 => '11025Hz',
        2 => '22050Hz',
        3 => '44100Hz',
    );

    my %audio_size = (
        0 => '8bit',
        1 => '16bit',
    );

    my %audio_type = (
        0 => 'mono',
        1 => 'stereo',
    );

    my %video_codec = (
        1 => 'JPEG',
        2 => 'Sorenson_H.263',
        3 => 'Screen_video',
        4 => 'On2_VP6',
        5 => 'On2_VP6_alpha',
        6 => 'Screen_video_v2',
        7 => 'AVC',
    );

    my %video_type = (
        1 => 'keyframe',
        2 => 'interframe',
        3 => 'disposable_interframe',
        4 => 'generated_keyframe',
        5 => 'video_info/command_frame',
    );

    my %avc_packet_type = (
        0 => 'avc_seq_header',
        1 => 'avc_nalu',
        2 => 'avc_seq_end',
    );

    my $input = shift;
    my %flv_info;
    $flv_info{frame_count} = 0;

    if ( $input eq '-' ) {
        open FH, "<-";
    }
    else {
        open FH, "<", $input;
    }
    binmode FH;
    my $buf;

    read( FH, $buf, 3 );    #File Header

    read( FH, $buf, 1 );    #Version

    read( FH, $buf, 1 );    # jump Type Flags
    my $flags = unpack 'C', substr( $buf, 0, 1 );
    my $type_flags_audio = ( ( $flags >> 2 ) & 0x01 );
    my $type_flags_video = $flags & 0x01;
    $flv_info{have_audio} = $type_flags_audio;
    $flv_info{have_video} = $type_flags_video;

    read( FH, $buf, 4 );    #Header Size

    read( FH, $buf, 4 );    # jump PreviousTagSize0

    my $tag_id = 0;

    while ( read( FH, $buf, 8 ) ) {
        $tag_id++;

        my ( $tag_type, $data_size, $ts, @datasize, @timestamp );
        (
            $tag_type,     $datasize[0],  $datasize[1],  $datasize[2],
            $timestamp[1], $timestamp[2], $timestamp[3], $timestamp[0]
        ) = unpack 'CCCCCCCC', $buf;

        $data_size = ( $datasize[0] * 256 + $datasize[1] ) * 256 + $datasize[2];
        $ts =
          ( ( $timestamp[0] * 256 + $timestamp[1] ) * 256 + $timestamp[2] ) *
          256 + $timestamp[3];

        read( FH, $buf, 3 );            # jump SteamID, Always 0.
        read( FH, $buf, $data_size );

        $tag_type = $tag_type{$tag_type};

        if ( $tag_type eq 'audio' ) {
            my $flags = unpack 'C', substr( $buf, 0, 1 );
            my $format = ( ( $flags >> 4 ) & 0x0f );
            my $rate   = ( ( $flags >> 2 ) & 0x03 );
            my $size   = ( ( $flags >> 1 ) & 0x01 );
            my $type   = $flags & 0x01;
            my $audio_format = $audio_format{$format};
            my $audio_rate   = $audio_rate{$rate};       # Always 44100 when AAC
            my $audio_size   = $audio_size{$size};
            my $audio_type   = $audio_type{$type};
        }
        elsif ( $tag_type eq 'video' ) {
            my $flags         = unpack 'C', substr( $buf, 0, 1 );
            my $type          = ( $flags >> 4 ) & 0x0f;
            my $codec         = $flags & 0x0f;
            my $video_type    = $video_type{$type};
            my $video_codec   = $video_codec{$codec};
            my $if_real_frame = 1;
            if ( $video_codec eq 'AVC' ) {
                my @avc_time;
                my $avc_header = substr( $buf, 1, 4 );
                my $avc_packet_type;
                ( $avc_packet_type, $avc_time[0], $avc_time[1], $avc_time[2] )
                  = unpack 'CCCC', $avc_header;
                my $composition_time =
                  ( $avc_time[0] * 256 + $avc_time[1] ) * 256 + $avc_time[2];
                $avc_packet_type = $avc_packet_type{$avc_packet_type};
                $if_real_frame   = 0
                  if $avc_packet_type eq 'avc_seq_header'
                  or $avc_packet_type eq 'avc_seq_end';
            }
            $flv_info{frame_count}++ if $if_real_frame;
        }
        elsif ( $tag_type eq 'script' ) {
            my %meta_info = extract_amf0($buf);
            foreach ( keys %meta_info ) {
                $flv_info{$_} = $meta_info{$_};
            }
        }
        else {
        }

        read( FH, $buf, 4 );    # jump PreviousTagSize
    }
    return %flv_info;
}

sub extract_amf0 {
    my %amf0;
    $amf0{data} = shift;
    $amf0{pos}  = 0;

    my %data;

    my $type = ord( amf0_read( \%amf0, 1 ) );
    if ( $type == 2 ) {
        my $string = amf0_read_string( \%amf0 );
    }
    amf0_read_unit( \%amf0 );

    while ( length( $amf0{data} ) > $amf0{pos} ) {
        my $key   = amf0_read_string( \%amf0 );
        my $value = amf0_read_unit( \%amf0 );
        $data{$key} = $value;
    }
    return %data;
}

sub amf0_read_unit {
    my $amf0 = shift;

    my $type = ord( amf0_read( $amf0, 1 ) );
    if ( $type == 8 ) {
        amf0_read( $amf0, 4 );
        return 1;
    }
    elsif ( $type == 2 ) {
        my $string = amf0_read_string($amf0);
        return $string;
    }
    elsif ( $type == 1 ) {
        my $boolean = amf0_read_boolean($amf0);
        return $boolean;
    }
    elsif ( $type == 0 ) {
        my $double = amf0_read_double($amf0);
        return $double;
    }

}

sub amf0_read {
    my $amf0       = shift;
    my $read_bytes = shift;

    my $bytes = substr( $amf0->{data}, $amf0->{pos}, $read_bytes );
    $amf0->{pos} += $read_bytes;

    return $bytes;
}

sub amf0_read_int {
    my $amf0 = shift;

    my $first_byte  = amf0_read( $amf0, 1 );
    my $second_byte = amf0_read( $amf0, 1 );

    my $first_num  = defined($first_byte)  ? ord($first_byte)  : 0;
    my $second_num = defined($second_byte) ? ord($second_byte) : 0;

    my $amf0_int = ( ($first_num) << 8 ) | $second_num;
    return $amf0_int;
}

sub amf0_read_boolean {
    my $amf0 = shift;
    my $data = amf0_read( $amf0, 1 );
    no warnings 'numeric';
    my $boolean = $data == 1 ? 1 : 0;
    return $boolean;
}

sub amf0_read_string {
    my $amf0          = shift;
    my $string_length = amf0_read_int($amf0);
    my $string        = amf0_read( $amf0, $string_length );
    return $string;
}

sub amf0_read_double {
    my $amf0 = shift;
    my @data = split //, amf0_read( $amf0, 8 );
    my $data;
    foreach ( reverse @data ) {
        $_ = "0" unless $_;
        $data .= $_;
    }
    my @zz = unpack( "d", $data );
    return $zz[0];
}

1;
__END__

=head1 NAME

Flv::Info::Lite - Another FLV information extract module

=head1 SYNOPSIS

  use Flv::Info::Lite qw(flv_info);

  my %info = flv_info($my_flv_filename);
  print $info{'filesize'};
  print $info{'have_audio'};
  print $info{'have_video'};

  print $info{'stereo'};
  print $info{'audiocodecid'};
  print $info{'audiodatarate'};
  print $info{'audiosamplerate'};
  print $info{'audiosamplesize'};

  print $info{'width'};
  print $info{'height'};
  print $info{'encoder'};
  print $info{'duration'};
  print $info{'framerate'};
  print $info{'frame_count'};
  print $info{'videocodecid'};
  print $info{'videodatarate'};

  foreach (keys %info)
  {
    print "$_ => " . $info{$_} . "\n" if $_;
  }

=head1 DESCRIPTION

Extract information in Adobe 'FLV' media file for you.

Simple and fast, written in Perl.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<FLV::Info>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

