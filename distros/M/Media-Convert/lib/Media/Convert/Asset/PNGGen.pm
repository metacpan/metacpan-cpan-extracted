package Media::Convert::Asset::PNGGen;

use Moose;
use Carp;

extends 'Media::Convert::Asset';

=head1 NAME

Media::Convert::Asset::PNGGen - Generate a video from a (list of) PNG files

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Asset::PNGGen;
  use Media::Convert::Pipe;

  my $input = Media::Convert::Asset::PNGGen->new(url => $input_png_filename);
  my $output = Media::Convert::Asset->new(url => $output_filename);

  Media::Convert::Pipe->new(inputs => [$input], output => $output)->run;

=head1 DESCRIPTION

This module uses the lavfi (the "libavfilter input virtual device", you
figure out how that matches the abbreviation) functionality in ffmpeg to
convert an image file into a video.

It will automatically match the input framerate to the output framerate;
this means that the framerate on the output file I<must> be set, either
through a profile or by setting it explicitly.

=head1 ATTRIBUTES

=head2 audio_channels

The option to give to the C<channel_layout> attribute of the C<anullsrc>
audio source. Defaults to "mono".

=cut

has "audio_channels" => (
	is => "rw",
	isa => "Str",
	default => "mono",
);

=head2 loop

If truthy, loops over the PNG files given. Useful if there is only one
PNG file, but then a video length for the output file should be given.
If falsy, stops after all the input files are processed.

Defaults to true.

=cut

has "loop" => (
	is => "rw",
	isa => "Bool",
	default => 1,
);

=head1 BUGS

This module does not work correctly with L<Media::Convert::Map>. If you
need to create a map, first generate a video with this file and then
initialize a regular L<Media::Convert::Asset> object with it.

=cut

sub readopts {
	my $self = shift;
	my $output = shift;

	if(defined($output->video_size) && ($self->video_size ne $output->video_size)) {
		carp "Video resolution does not match image resolution. Will scale, but the result may be suboptimal...";

	}
	my @rv;
	if($self->loop) {
		push @rv, ("-loop", '1');
	}
	push @rv, ('-framerate', $output->video_framerate, '-i', $self->url, '-f', 'lavfi', '-i', 'anullsrc=channel_layout=' . $self->audio_channels);
	return @rv;
}

no Moose;

1;
