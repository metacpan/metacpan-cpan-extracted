package Mediainfo;
use strict;
use warnings;
use IPC::Open3;

our $VERSION = '0.12';

sub new
{
    my $pkg  = shift;
    my $self = {@_};
    bless $self, $pkg;

    $self->mediainfo($self->{filename});
    return $self;
}

sub mediainfo
{
    my $self = shift;
    my $file = shift || return undef;

    my @PATH = split /:/, $ENV{PATH};
    push @PATH, "./";
    push @PATH, "/bin";
    push @PATH, "/sbin";
    push @PATH, "/usr/bin";
    push @PATH, "/usr/sbin";
    push @PATH, "/usr/local/bin";
    push @PATH, "/usr/local/sbin";
    my $mediainfo_exec;

    foreach (@PATH)
    {
        my $executable = $_ . '/mediainfo';
        if (-s $executable)
        {
            $mediainfo_exec = $executable;
            last;
        }
    }

    my $filesize = -s $file;
    my ($wtr, $rdr, $err, $mediainfo, $mediainfo_err);
    use Symbol 'gensym';
    $err = gensym;
    my $pid = open3($wtr, $rdr, $err, "$mediainfo_exec -f \"$file\"");
    close $wtr;
    while (<$rdr>) { $mediainfo     .= $_; }
    while (<$err>) { $mediainfo_err .= $_; }
    waitpid($pid, 0);

    $mediainfo =~ s/\r//g if $mediainfo;
    my ($genernal_info) = $mediainfo =~ /(^General\n.*?\n\n)/sm;
    return undef unless $genernal_info;

    my ($video_info) = $mediainfo =~ /(^Video[\s\#\d]*\n.*?\n\n)/sm;
    my ($audio_info) = $mediainfo =~ /(^Audio[\s\#\d]*\n.*?\n\n)/sm;

    my $container;
    my $length;
    my $bitrate;
    my $title;
    my $album;
    my $track_name;
    my $performer;
    ($container) = $genernal_info =~ /Format\s*:\s*([\w\_\-\\\/\. ]+)\n/;
    $container =~ s/\s//g if $container;
    ($length)     = $genernal_info =~ /Duration\s*:\s*(\d+)\.?\d*\n/;
    ($bitrate)    = $genernal_info =~ /Overall bit rate\s*:\s*(\d+)\n/;
    ($title)      = $genernal_info =~ /Title\s*:\s*(.+)\n/;
    ($album)      = $genernal_info =~ /Album\s*:\s*(.+)\n/;
    ($track_name) = $genernal_info =~ /Track name\s*:\s*(.+)\n/;
    ($performer)  = $genernal_info =~ /Performer\s*:\s*(.+)\n/;

    my $video_codec;
    my $video_codec_profile;
    my $video_format;
    my $video_format_profile;
    my $video_length;
    my $video_bitrate;
    my $width;
    my $height;
    my $fps;
    my $frame_count;
    my $fps_mode;
    my $dar;
    my $rotation;

    if ($video_info)
    {
        ($video_codec)  = $video_info =~ /Codec\s*:\s*([\w\_\-\\\/ ]+)\n/;
        ($video_format) = $video_info =~ /Format\s*:\s*([\w\_\-\\\/ ]+)\n/;
        ($video_codec_profile) =
          $video_info =~ /Codec profile\s*:\s*([\w\_\-\\\/\@\. ]+)\n/;
        ($video_format_profile) =
          $video_info =~ /Format profile\s*:\s*([\w\_\-\\\/\@\. ]+)\n/;
        $video_codec =~ s/\s//g          if $video_codec;
        $video_format =~ s/\s//g         if $video_format;
        $video_codec_profile =~ s/\s//g  if $video_codec_profile;
        $video_format_profile =~ s/\s//g if $video_format_profile;
        ($video_length)  = $video_info =~ /Duration\s*:\s*(\d+)\.?\d*\n/;
        ($video_bitrate) = $video_info =~ /Bit rate\s*:\s*(\d+)\n/;
        ($width)         = $video_info =~ /Original width\s*:\s*(\d+)\n/;
        ($width)         = $video_info =~ /Width\s*:\s*(\d+)\n/ unless $width;
        ($height)        = $video_info =~ /Original height\s*:\s*(\d+)\n/;
        ($height)        = $video_info =~ /Height\s*:\s*(\d+)\n/ unless $height;
        ($fps)           = $video_info =~ /Frame rate\s*:\s*([\d\.]+)\n/;
        ($fps)           = $video_info =~ /frame rate\s*:\s*([\d\.]+)\s*fps\n/
          unless $fps;
        ($frame_count) = $video_info =~ /Frame count\s*:\s*(\d+)\n/;
        ($fps_mode)    = $video_info =~ /Frame rate mode\s*:\s*([\w\.]+)\n/i;
        ($dar) = $video_info =~ /Display aspect ratio\s*:\s*([\d\.]+)\n/i;
        $frame_count = int($fps * $video_length / 1000)
          if (    $fps
              and $video_length
              and (!$frame_count or $frame_count <= 0));
        $fps = substr($frame_count / $video_length * 1000, 0, 6)
          if ((!$fps or $fps <= 0) and $video_length and $frame_count);
        $video_length = substr($frame_count / $fps * 1000, 0, 6)
          if (    $fps
              and (!$video_length or $video_length <= 0)
              and $frame_count);
        $video_length = $length
          if (!$video_length and $length and $video_info);
        ($rotation) = $video_info =~ /Rotation\s*:\s*([\d\.]+)\n/i;
        $rotation = 0 unless $rotation;
    }

    my $audio_codec;
    my $audio_format;
    my $audio_length;
    my $audio_bitrate;
    my $audio_rate;
    my $audio_language;
    my $audio_channel;
    my $audio_channel_original;

    if ($audio_info)
    {
        ($audio_codec)  = $audio_info =~ /Codec\s*:\s*([\w\_\-\\\/ ]+)\n/;
        ($audio_format) = $audio_info =~ /Format\s*:\s*([\w\_\-\\\/ ]+)\n/;
        $audio_codec =~ s/\s//g  if $audio_codec;
        $audio_format =~ s/\s//g if $audio_format;
        ($audio_length)  = $audio_info =~ /Duration\s*:\s*(\d+)\.?\d*\n/;
        ($audio_bitrate) = $audio_info =~ /Bit rate\s*:\s*(\d+)\n/;
        ($audio_rate)    = $audio_info =~ /Sampling rate\s*:\s*(\d+)\n/;
        $audio_length = $video_length
          if (    (!$audio_length or $audio_length <= 0)
              and $video_length
              and $audio_info);
        ($audio_language) = $audio_info =~ /Language\s*:\s*(\w+)\n/;

        #add by @owen 201401222 start

        ($audio_channel) = $audio_info =~ /Channel\(s\)\s*:\s*(\d+)\n/;
        ($audio_channel_original) =
          $audio_info =~ /Channel\(s\)_Original\s*:\s*(\d+)\n/;
        my ($channel_layout) = $audio_info =~ /ChannelLayout\s*:\s*([\w\s]+)/;
        my @layout = split(/ /, $channel_layout);
        if ($audio_channel_original)
        {
            if (    $audio_channel_original == scalar @layout
                and $audio_channel_original != $audio_channel)
            {
                $audio_channel = $audio_channel_original;
            }
        }

        #add by @owen 20141222 end
    }

    $self->{'filename'}     = $file             if $file;
    $self->{'filesize'}     = $filesize         if $filesize;
    $self->{'container'}    = lc($container)    if $container;
    $self->{'length'}       = $length           if $length;
    $self->{'bitrate'}      = $bitrate          if $bitrate;
    $self->{'title'}        = $title            if $title;
    $self->{'album'}        = $album            if $album;
    $self->{'track_name'}   = $track_name       if $track_name;
    $self->{'performer'}    = $performer        if $performer;
    $self->{'video_codec'}  = lc($video_codec)  if $video_codec;
    $self->{'video_format'} = lc($video_format) if $video_format;
    $self->{'video_codec_profile'} = lc($video_codec_profile)
      if $video_codec_profile;
    $self->{'video_format_profile'} = lc($video_format_profile)
      if $video_format_profile;
    $self->{'video_length'}   = $video_length     if $video_length;
    $self->{'video_bitrate'}  = $video_bitrate    if $video_bitrate;
    $self->{'width'}          = $width            if $width;
    $self->{'height'}         = $height           if $height;
    $self->{'fps'}            = $fps              if $fps;
    $self->{'fps_mode'}       = lc($fps_mode)     if $fps_mode;
    $self->{'dar'}            = $dar              if $dar;
    $self->{'frame_count'}    = $frame_count      if $frame_count;
    $self->{'rotation'}       = $rotation         if $rotation;
    $self->{'audio_codec'}    = lc($audio_codec)  if $audio_codec;
    $self->{'audio_format'}   = lc($audio_format) if $audio_format;
    $self->{'audio_length'}   = $audio_length     if $audio_length;
    $self->{'audio_bitrate'}  = $audio_bitrate    if $audio_bitrate;
    $self->{'audio_rate'}     = $audio_rate       if $audio_rate;
    $self->{'audio_language'} = $audio_language   if $audio_language;
    $self->{'audio_channel'}  = $audio_channel    if $audio_channel;
    $self->{'have_video'} = ($video_info) ? 1 : 0;
    $self->{'have_audio'} = ($audio_info) ? 1 : 0;
}

1;

__END__

=head1 NAME

Mediainfo - Perl interface to Mediainfo


=head1 SYNOPSIS

  use Mediainfo;
  my $foo_info = new Mediainfo("filename" => "/root/foo.mp4");
  print $foo_info->{video_format}, "\n";
  print $foo_info->{video_length}, "\n";
  print $foo_info->{video_bitrate}, "\n";


=head1 DESCRIPTION

This module is a thin layer above "Mediainfo" which supplies technical and tag information about a video or audio file.

L<http://mediainfo.sourceforge.net/>


=head1 EXAMPLES

  use Mediainfo;

  my $foo_info = new Mediainfo("filename" => "/root/foo.mp4");

  print $foo_info->{filename}, "\n";
  print $foo_info->{filesize}, "\n";
  print $foo_info->{container}, "\n";
  print $foo_info->{length}, "\n";
  print $foo_info->{bitrate}, "\n";
  print $foo_info->{title}, "\n";
  print $foo_info->{album}, "\n";
  print $foo_info->{track_name}, "\n";
  print $foo_info->{performer}, "\n";
  print $foo_info->{video_codec}, "\n";
  print $foo_info->{video_format}, "\n";
  print $foo_info->{video_length}, "\n";
  print $foo_info->{video_bitrate}, "\n";
  print $foo_info->{width}, "\n";
  print $foo_info->{height}, "\n";
  print $foo_info->{fps}, "\n";
  print $foo_info->{fps_mode}, "\n";
  print $foo_info->{dar}, "\n";
  print $foo_info->{frame_count}, "\n";
  print $foo_info->{audio_codec}, "\n";
  print $foo_info->{audio_format}, "\n";
  print $foo_info->{audio_length}, "\n";
  print $foo_info->{audio_bitrate}, "\n";
  print $foo_info->{audio_rate}, "\n";
  print $foo_info->{audio_language}, "\n";
  print $foo_info->{audio_channel}, "\n";
  print $foo_info->{have_video}, "\n";
  print $foo_info->{have_audio}, "\n";

  print $foo_info->{rotation}, "\n";
  print $foo_info->{video_codec_profile}, "\n";
  print $foo_info->{video_format_profile}, "\n";

             
             
=head1 AUTHOR

Written by ChenGang

yikuyiku.com@gmail.com

L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.

This library is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Video::Info>, L<Movie::Info>
