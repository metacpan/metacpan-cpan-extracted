package Media::Convert::Normalizer::Ffmpeg;

use Moose;

extends 'Media::Convert::Normalizer';

use JSON::MaybeXS qw/decode_json/;
use Symbol 'gensym';
use IPC::Open3;
use Media::Convert::CodecMap qw/detect_to_write/;

=head1 NAME

Media::Convert::Normalizer::Ffmpeg - normalize the audio of a video asset using the ffmpeg 'loudnorm' filter

=head1 SYNOPSIS

  Media::Convert::Normalizer::Ffmpeg->new(input => Media::Convert::Asset->new(...), output => Media::Convert::Asset->new(...))->run();

=head1 DESCRIPTION

C<Media::Convert::Normalizer> is a class to normalize the audio of a given
C<Media::Convert::Asset>. This class is an implementation of the API using
the ffmpeg "loudnorm" filter.

=head1 ATTRIBUTES

C<Media::Convert::Normalizer::Ffmpeg> supports all the attributes of
L<Media::Convert::Normalizer>

=head1 METHODS

=head2 run

Performs the normalization

=cut

sub run {
	my $self = shift;

	my $input = $self->input;

	my @command = ("ffmpeg", "-y", "-i", $input->url, "-af", "loudnorm=i=-23.0:print_format=json", "-f", "null", "-");
	print "Running: '" . join("' '", @command) . "'\n";
	open3 (my $in, my $out, my $ffmpeg = gensym, @command);
	my $json = "";
	my $reading_json = 0;
	while(<$ffmpeg>) {
		if(/{/) {
			$reading_json++;
		}
		if($reading_json) {
			$json .= $_;
		}
                if(/}/) {
                        $reading_json--;
                }
	}
	$json = decode_json($json);

	# TODO: abstract filters so they can be applied to an
	# Media::Convert::Pipe. Not now.
	my $codec = $self->output->audio_codec;
	if(!defined($codec)) {
		$codec = detect_to_write($input->audio_codec);
	}
	@command = ("ffmpeg", "-loglevel", "warning", "-y", "-i", $input->url, "-af", "loudnorm=i=-23.0:dual_mono=true:measured_i=" . $json->{input_i} . ":measured_tp=" . $json->{input_tp} . ":measured_lra=" . $json->{input_lra} . ":measured_thresh=" . $json->{input_thresh}, "-c:v", "copy", "-c:a", $codec, $self->output->url);
	print "Running: '" . join("' '", @command) . "'\n";
	system(@command);
}
