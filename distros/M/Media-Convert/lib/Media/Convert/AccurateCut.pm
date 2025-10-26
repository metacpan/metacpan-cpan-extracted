package Media::Convert::AccurateCut;

use Moose;
use Media::Convert::Asset;
use Media::Convert::Asset::Concat;
use Media::Convert::Asset::ProfileFactory;
use Media::Convert::KeyframeFinder;
use Media::Convert::Map;
use Media::Convert::Pipe;

has input => (
	is => 'rw',
	required => 1,
	isa => 'Media::Convert::Asset',
);

has output => (
	is => 'rw',
	required => 1,
	isa => 'Media::Convert::Asset',
);

has profile => (
	is => 'rw',
	isa => 'Media::Convert::Asset',
	builder => '_build_profile',
	lazy => 1,
);

sub _build_profile {
	my $self = shift;
	my $rv = Media::Convert::Asset::ProfileFactory->create("copy", $self->input);
	$rv->video_codec($self->input->video_codec);
	return $rv;
}

has start => (
	is => 'rw',
	isa => 'Num',
	required => 1,
);

has duration => (
	is => 'rw',
	isa => 'Num',
	predicate => 'has_duration',
);

has workdir => (
	is => 'rw',
	isa => 'Str',
	default => $ENV{TMPDIR} // '/tmp',
	lazy => 1,
);

sub run {
	my $self = shift;

	my $kfs = Media::Convert::KeyframeFinder->new(asset => $self->input)->keyframes;
	my $last = 0;
	my $next;
	my $workdir = $self->workdir;
	my $final_source;
	KF:
	foreach my $kf(@$kfs) {
		$next = $kf;
		last KF if $kf > $self->start;
		$last = $kf;
	}
	my @cleanups = ();
	my $half_frame = $self->input->video_frame_length / 2;
	if(($last - $half_frame < $self->start) && ($last + $half_frame > $self->start)) {
		$final_source = $self->input;
		$self->output->fragment_start($last);
	} elsif(($next - $half_frame < $self->start) && ($next + $half_frame > $self->start)) {
		$final_source = $self->input;
		$self->output->fragment_start($next);
	} else {
		my $tmp = Media::Convert::Asset->new(url => "$workdir/segment.mkv",
						fragment_start => $last,
						duration => $next - $last,
						video_codec => "yuv4",
		);
		push @cleanups, $tmp->url;
		Media::Convert::Pipe->new(inputs => [$self->input],
						output => $tmp,
						map => [Media::Convert::Map->new(input => $self->input, type => 'allcopy')],
						acopy => 1,
		)->run();
		my $convert = Media::Convert::Asset->new(url => "$workdir/concat1.mkv",
						reference => $self->profile, 
						fragment_start => $self->start - $last,
						audio_codec => 'copy',
		);
		push @cleanups, $convert->url;
		Media::Convert::Pipe->new(inputs => [$tmp],
						output => $convert,
						map => [Media::Convert::Map->new(input => $tmp, type => 'allcopy')],
						acopy => 1,
		)->run();
		my $rest = Media::Convert::Asset->new(url => "$workdir/concat2.mkv",
						fragment_start => $next,
						audio_codec => 'copy',
		);
		if($self->has_duration) {
			$rest->duration($self->duration);
		}
		push @cleanups, $rest->url;
		Media::Convert::Pipe->new(inputs => [$self->input],
						output => $rest,
						vcopy => 1,
						acopy => 1,
						map => [Media::Convert::Map->new(input => $self->input, type => 'allcopy')],
		)->run();
		$final_source = Media::Convert::Asset::Concat->new(
						url => "$workdir/concat.txt",
						components => [$convert, $rest],
						input_params => {fflags => "+nofillin"}
		);
		push @cleanups, $final_source->url;
	}
	if($self->has_duration) {
		$self->output->duration($self->duration);
	}
	$self->output->audio_codec('copy');
	Media::Convert::Pipe->new(inputs => [$final_source],
				output => $self->output,
				map => [Media::Convert::Map->new(input => $final_source, type => "allcopy")],
				vcopy => 1,
				acopy => 1,
	)->run();
	foreach my $cleanup(@cleanups) {
		unlink $cleanup;
	}
}

no Moose;

1;
