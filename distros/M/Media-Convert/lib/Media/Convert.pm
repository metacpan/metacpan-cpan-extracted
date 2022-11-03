package Media::Convert;

use strict;
use warnings;

our $VERSION;
$VERSION = "1.0.3";

=head1 NAME

Media::Convert - a Moose-based library to work with media assets

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset->new(url => $input_filename);
  say "Input video codec is " . $input->video_codec;
  my $output = Media::Convert::Asset->new(url => "output.mkv", video_codec => "libvpx", audio_codec => "vorbis");
  my $pipe = Media::Convert::Pipe => new(inputs => [$input], output => $output);
  $pipe->run;

=head1 DESCRIPTION

Media::Convert is a library that allows one to inspect and work
with (edit, convert, transcode) media files. Behind the scenes,
Media::Convert generates and runs ffmpeg/ffprobe command lines to
perform the requested operations.

Media::Convert was originally a part of the SReview web-based video
review and transcoding tool, but it was split off for being useful
enough in its own right.

Media::Convert uses semver as explained at L<https://semver.org>

=head1 SEE ALSO

L<Media::Convert::Asset>, L<Media::Convert::Pipe>, L<Media::Convert::Asset::ProfileFactory>

=cut

1;
