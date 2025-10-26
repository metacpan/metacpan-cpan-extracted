package Media::Convert::KeyframeFinder;

use v5.28;
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
        my @pipe = ("ffprobe", "-loglevel", "quiet", "-print_format", "json", "-show_format", "-select_streams", "v", "-skip_frame", "nokey", "-show_frames", "-show_entries", "frame=pts_time,pict_type,best_effort_timestamp_time", $self->asset->url);
        say "Running: '". join("' '", @pipe) . "'";
	open my $jsonpipe, "-|:encoding(UTF-8)", @pipe;
	my $data = decode_json(<$jsonpipe>);
	my $rv = [];
        my $offset = $data->{format}{start_time} // 0;
	foreach my $frame(@{$data->{frames}}) {
		next unless $frame->{pict_type} eq "I";
		push @$rv, ($frame->{pts_time} // $frame->{best_effort_timestamp_time}) - $offset;
	}
	return $rv;
}

no Moose;

1;
