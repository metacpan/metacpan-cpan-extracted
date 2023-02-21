package Media::Convert::Pipe;

use JSON::MaybeXS qw(decode_json);
use Moose;
use Carp;

=head1 NAME

Media::Convert::Pipe - class to generate ffmpeg command lines with Media::Convert::Asset

=head1 SYNOPSIS

  use Media::Convert::Asset;
  use Media::Convert::Pipe;

  my $input_audio = Media::Convert::Asset->new(url => $input_filename_audio);
  my $input_video = Media::Convert::Asset->new(url => $input_filename_video);
  my $output = Media::Convert::Asset->new(url => $output_filename);
  my $map_audio = Media::Convert::Map->new(input => $input_audio, type => "stream", choice => "audio");
  my $map_video = Media::Convert::Map->new(input => $input_video, type => "stream", choice => "video");
  my $pipe = Media::Convert::Pipe->new(inputs => [$input_audio, $input_video], map => [ $map_audio, $map_video ], output => $output);
  $pipe->run();

  # Or, if progress information is wanted:
  sub print_progress {
    my $percentage = shift;
    print "Transcoding progress: $percentage\r";
  }
  $pipe->progress(\&print_progress);
  $pipe->run();

=head1 DESCRIPTION

C<Media::Convert::Pipe> is the class in the C<Media::Convert> package
which does most of the hard work inside C<Media::Convert>. It generates
and runs the ffmpeg command line, capturing the output where required.

C<Media::Convert::Pipe> will compare the properties of the input
C<Media::Convert::Asset> objects against those of the output
C<Media::Convert::Asset> object, and will add the necessary parameters
to the ffmpeg command line to convert the audio/video material in the
input file to the format required by the output file.

=head1 ATTRIBUTES

The following attributes are supported by C<Media::Convert::Pipe>.

=head2 inputs

The objects to read from. Must be C<Media::Convert::Asset> objects. If
more than one object is passed, a value for the C<map> attribute may be
required to tell ffmpeg which audio/video stream to read from which
file.

More input objects can be added using the C<add_input> method, and they
can all be removed using the C<clear_inputs> object.

=cut

has 'inputs' => (
	traits => ['Array'],
	is => 'ro',
	isa => 'ArrayRef[Media::Convert::Asset]',
	default => sub { [] },
	clearer => 'clear_inputs',
	handles => {
		add_input => 'push',
	},
);

=head2 output

The object to write to. Must be a C<Media::Convert::Asset> object.
Required.

If any properties differ between the input objects and the output
object (e.g., the codec, pixel format, audio sample frequency, video
resolution, etc etc etc), C<Media::Convert::Pipe> will add the necessary
command-line options to the ffmpeg command line to convert the video
from the input file to the output file.

=cut

has 'output' => (
	is => 'rw',
	isa => 'Media::Convert::Asset',
	required => 1,
);

=head2 map

Array of C<Media::Convert::Map> objects, used to manipulate which audio
and video streams exactly will be written to the output file (and in
which order, etc).

For more info: see L<Media::Convert::Map>.

Maps can be cleared with C<clear_map> and added to with C<add_map>.

=cut

has 'map' => (
	traits => ['Array'],
	is => 'ro',
	isa => 'ArrayRef[Media::Convert::Map]',
	default => sub {[]},
	clearer => 'clear_map',
	handles => {
		add_map => 'push',
	},
);

=head2 vcopy

Boolean. If true, explicitly tell C<Media::Convert> to copy video
without transcoding it.

Normally, C<Media::Convert> should not request a transcode if all
attributes of the input file and the output file are exactly the same.
Getting this right may sometimes be problematic, however. In such cases,
it can be good to explicitly say that the video should not be
transcoded. That's what this property is for.

=cut

has 'vcopy' => (
	isa => 'Bool',
	is => 'rw',
	default => 1,
);

=head2 acopy

The same as C<vcopy>, but for audio rather than video.

=cut

has 'acopy' => (
	isa => 'Bool',
	is => 'rw',
	default => 1,
);

=head2 vskip

Tell C<Media::Convert> that the output file should not contain any
video (i.e., that it should skip handling of any video). This is implied
if the output container does not support video streams (e.g., the .wav
format), but is required if it does.

=cut

has 'vskip' => (
	isa => 'Bool',
	is => 'rw',
	default => 0,
);

=head2 askip

The same as C<vskip>, but for audio rather than video.

=cut

has 'askip' => (
	isa => 'Bool',
	is => 'rw',
	default => 0,
);

=head2 multipass

Boolean. If true, the C<run> method performs a two-pass encode, rather
than a single-pass encode.

Two-pass encodes will generate a better end result, but require more
time to perform.

=cut

has 'multipass' => (
	isa => 'Bool',
	is => 'rw',
	default => 0,
);

=head2 progress

Normally, C<Media::Convert::Pipe> shows (and runs) the ffmpeg command.
Any output of the ffmpeg command is shown on stdout.

If this attribute is set to a coderef, then the following happens:

=over *

=item The ffmpeg command line that is executed gains "-progress /dev/stdout" parameters

=item The output of the ffmpeg command is parsed, and the completion percentage calculated (and all other output suppressed),

=item The coderef that was passed to this attribute is executed with the completion percentage as the only parameter whenever the percentage changes.

=back

=cut

has 'progress' => (
	isa => 'CodeRef',
	is => 'ro',
	predicate => 'has_progress',
);

has 'has_run' => (
	isa => 'Bool',
	is => 'rw',
	default => 0,
	traits => ['Bool'],
	handles => {
		run_complete => 'set',
	}
);

sub run_progress {
	my $self = shift;
	my $command = shift;
	my $pass = shift;
	my $multipass = shift;
	my ($in, $out, $err);
	my $running;
	my @lines;
	my $old_perc = -1;
	my %vals;

	my $length = $self->output->duration * 1000000;
	if($length == 0) {
		foreach my $input(@{$self->inputs}) {
			my $dur = $input->duration * 1000000;
			if($length == 0) {
				$length = $dur;
				next;
			}
			$length = $length < $dur ? $length : $dur;
		}
	}
	shift @$command;
	unshift @$command, ('ffmpeg', '-progress', '/dev/stdout');
	open my $ffmpeg, "-|", @{$command};
	while(<$ffmpeg>) {
		/^(\w+)=(.*)$/;
		$vals{$1} = $2;
		if($1 eq 'progress') {
			my $perc = int($vals{out_time_ms} / $length * 100);
			if($vals{progress} eq 'end') {
				$perc = 100;
			}
			if($multipass) {
				$perc = int($perc / 2);
			}
			if($pass == 2) {
				$perc += 50;
			}
			if($perc != $old_perc) {
				$old_perc = $perc;
				&{$self->progress}($perc);
			}
		}
	}
	$self->run_complete;
}

=head1 METHODS

=head2 run

Run the ffmpeg command.

If this method is not run at least once, the object's destructor will
issue a warning.

=cut

sub run {
	my $self = shift;
	my $pass;
	my @attrs = (
		'video_codec' => 'vcopy',
		'video_size' => 'vcopy',
		'video_width' => 'vcopy',
		'video_height' => 'vcopy',
		'video_bitrate' => 'vcopy',
		'video_framerate' => 'vcopy',
		'pix_fmt' => 'vcopy',
		'audio_codec' => 'acopy',
		'audio_bitrate' => 'acopy',
		'audio_samplerate' => 'acopy',
	);
	my @video_attrs = ('video_codec', 'video_size', 'video_width', 'video_height', 'video_bitrate', 'video_framerate', 'pix_fmt');
	my @audio_attrs = ('audio_codec', 'audio_bitrate', 'audio_samplerate');

	for($pass = 1; $pass <= ($self->multipass ? 2 : 1); $pass++) {
		my @command = ("ffmpeg", "-loglevel", "warning", "-y");
		foreach my $input(@{$self->inputs}) {
			if($self->multipass) {
				$input->pass($pass);
				$self->output->pass($pass);
			}
			while(scalar(@attrs) > 0) {
				my $attr = shift @attrs;
				my $target = shift @attrs;
				next unless $self->meta->get_attribute($target)->get_value($self);
				my $oval = $self->output->meta->find_attribute_by_name($attr)->get_value($self->output);
				my $ival = $input->meta->find_attribute_by_name($attr)->get_value($input);
				if(defined($oval) && $ival ne $oval) {
					$self->meta->get_attribute($target)->set_value($self, 0);
				}
			}
			push @command, $input->readopts($self->output);
		}
		if(!$self->vcopy() && !$self->vskip()) {
			my $isize = $self->inputs->[0]->video_size;
			my $osize = $self->output->video_size;
			if(defined($isize) && defined($osize) && $isize ne $osize) {
				push @command, ("-vf", "scale=" . $osize);
			}
		}
		foreach my $map(@{$self->map}) {
			my $in_map = $map->input;
			my $index;
			for(my $i=0; $i<=$#{$self->inputs}; $i++) {
				if($in_map == ${$self->inputs}[$i]) {
					$index = $i;
				}
			}
			push @command, $map->arguments($index);
		}
		if($self->vcopy) {
			push @command, ('-c:v', 'copy');
		}
		if($self->acopy) {
			push @command, ('-c:a', 'copy');
		}
		if($self->vskip) {
			push @command, ('-vn');
		}
		if($self->askip) {
			push @command, ('-an');
		}
		push @command, $self->output->writeopts($self);

		print "Running: '" . join ("' '", @command) . "'\n";
		if($self->has_progress) {
			$self->run_progress(\@command, $pass, $self->multipass);
		} else {
			system(@command);
		}
	}
	foreach my $input(@{$self->inputs}) {
		$input->clear_pass;
	}
	$self->output->clear_pass;
	$self->run_complete;
}

sub DESTROY {
	if(!(shift->has_run)) {
		confess "object destructor for Media::Convert::Pipe object entered without having seen a run!";
	}
}

no Moose;

1;
