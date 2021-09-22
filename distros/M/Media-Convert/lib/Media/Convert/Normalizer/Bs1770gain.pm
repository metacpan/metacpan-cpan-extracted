package Media::Convert::Normalizer::Bs1770gain;

use Moose;
use File::Basename;
use File::Temp qw/tempdir/;
use Media::Convert::CodecMap qw/detect_to_write/;
use Media::Convert::Map;
use Media::Convert::Asset;
use Media::Convert::Pipe;

extends 'Media::Convert::Normalizer';

=head1 NAME

Media::Convert::Normalizer::Bs1770gain - normalize the audio of a video asset using bs1770gain

=head1 SYNOPSIS

  Media::Convert::Normalizer::Bs1770gain->new(input => Media::Convert::Asset->new(...), output => Media::Convert::Asset->new(...))->run();

=head1 DESCRIPTION

C<Media::Convert::Normalizer::Bs1770gain> is a class to normalize the
audio of a given Media::Convert::Asset asset using bs1770gain.

=head1 ATTRIBUTES

C<Media::Convert::Normalizer::Bs1770gain> supports all the attributes of
L<Media::Convert::Normalizer>, plus the following extra options:

=head2 tempdir

The directory in which to write temporary files.

=cut

has 'tempdir' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	builder => '_probe_tempdir',
);

sub _probe_tempdir {
	my $self = shift;

	return tempdir("normXXXXXX", CLEANUP => 1);
}

has '_bs1770gain_version' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_probe_bs1770gain_version',
);

sub _probe_bs1770gain_version {
	my $self = shift;

	open my $pipe, "-|", "bs1770gain", "--version";

	my $rv = "0.5";
	while(<$pipe>) {
		if(/^bs1770gain ([0-9]+\.[0-9]+\.)/i) {
			$rv = $1;
			last;
		}
	}
	close $pipe;
	return $rv;
}

=head1 METHODS

=head2 run

Performs the normalization.

=cut

sub run {
	my $self = shift;

	my $exten;

	$self->input->url =~ /(.*)\.[^.]+$/;
	my $base = $1;
	if(!defined($self->input->video_codec)) {
		$exten = "flac";
	} else {
		$exten = "mkv";
	}
	my @command = ("bs1770gain", "-a", "-o", $self->_tempdir);
	if($self->_bs1770gain_version ne "0.5") {
		$exten = "mkv";
		push @command, "--suffix=mkv";
	}
	push @command, $self->input->url;
	print "Running: '" . join("' '", @command) . "'\n";
	system(@command);

	my $intermediate = $self->_tempdir . "/" . basename($base) . ".$exten";
	my $check = Media::Convert::Asset->new(url => $intermediate);

	if($check->audio_codec eq $self->input->audio_codec) {
		Media::Convert::Pipe->new(inputs => [Media::Convert::Asset->new(url => $intermediate)], output => $self->output, vcopy => 1, acopy => 1)->run();
	} else {
		$self->output->audio_codec($self->input->audio_codec);
		Media::Convert::Pipe->new(inputs => [Media::Convert::Asset->new(url => $intermediate)], output => $self->output, vcopy => 1, acopy => 0)->run();
	}
}

1;
