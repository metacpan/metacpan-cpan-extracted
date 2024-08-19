package Media::Convert::KeyframeFinder;

use Moose;

use JSON::MaybeXS qw/decode_json/;
use autodie qw/:all/;

has 'asset' => (
	is => 'ro',
	isa => 'Media::Convert::Asset',
	required => 1,
);

has 'keyframes' => (
	is => 'ro',
	isa => 'ArrayRef[Num]',
	lazy => 1,
	builder => '_build_keyframes',
);

sub _build_keyframes {
	my $self = shift;

	local $/ = "";
	open my $jsonpipe, "-|:encoding(UTF-8)", "ffprobe", "-loglevel", "quiet", "-print_format", "json", "-select_streams", "v", "-skip_frame", "nokey", "-show_frames", "-show_entries", "frame=pts_time,pict_type,best_effort_timestamp_time", $self->asset->url;
	my $data = decode_json(<$jsonpipe>);
	my $rv = [];
	foreach my $frame(@{$data->{frames}}) {
		next unless $frame->{pict_type} eq "I";
		push @$rv, ($frame->{pts_time} // $frame->{best_effort_timestamp_time}) + 0;
	}
	return $rv;
}

no Moose;

1;
