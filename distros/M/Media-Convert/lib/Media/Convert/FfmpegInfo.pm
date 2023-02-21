package Media::Convert::FfmpegInfo;

use MooseX::Singleton;

has 'codecs' => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	builder => '_build_codecs',
);

sub _build_codecs {
	local $/ = "";
	open my $ffmpeg, "-|", "ffmpeg -codecs 2>/dev/null";
	my $codeclist = <$ffmpeg>;
	close $ffmpeg;
	my $parsing = 0;
	my $rv = {};
	foreach my $line(split /\n/, $codeclist) {
		if(!$parsing) {
			if($line =~ /^ ---+/) {
				$parsing = 1;
			}
			next;
		}
		my ($decode, $encode, $type, $intra, $lossy, $lossless, $name, $desc) = unpack("xAAAAAAxA20xA*", $line);
		my $h = {};
		$h->{decode} = ($decode eq "D") ? 1 : 0;
		$h->{encode} = ($encode eq "E") ? 1 : 0;
		$h->{type} = $type;
		$h->{is_video} = ($type eq "V") ? 1 : 0;
		$h->{is_audio} = ($type eq "A") ? 1 : 0;
		$h->{is_subtitle} = ($type eq "S") ? 1 : 0;
		$h->{is_data} = ($type eq "D") ? 1 : 0;
		$h->{is_attachment} = ($type eq "T") ? 1 : 0;
		$h->{is_intra_only} = ($intra eq "I") ? 1 : 0;
		$h->{is_lossy} = ($lossy eq "L") ? 1 : 0;
		$h->{is_lossless} = ($lossless eq "S") ? 1 : 0;
		$h->{name} = $name;
		$h->{description} = $desc;
		$rv->{$name} = $h;
	};
	return $rv;
}

1;
