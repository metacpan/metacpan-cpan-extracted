#!/usr/bin/perl -w

use strict;
use warnings;
use feature "say";
use JSON::MaybeXS;

use Test::More;

sub get_start_times {
        my $values = shift;
        my %rv;
        foreach my $stream(@{$values->{streams}}) {
                next unless defined($stream->{codec_type});
                next unless defined($stream->{start_time});
                $rv{$stream->{codec_type}} = 0 + $stream->{start_time};
        }
        return \%rv;
}

sub get_values {
        my $fn = shift;
        my @cmd = ("ffprobe", "-loglevel", "quiet", "-show_entries", "stream=codec_type,start_time", "-print_format", "json", $fn);
        say "'" . join("' '", @cmd) . "'";
        open my $jsonpipe, "-|:encoding(UTF-8)", @cmd;
        my $json = "";
        while(my $line = <$jsonpipe>) {
                $json .= $line;
        }
        $json = decode_json($json);
        close $jsonpipe;
        return $json;
}

sub debug_values {
        my $values = shift;
        foreach my $stream(@{$values->{streams}}) {
                say "codec with type " . $stream->{codec_type} . " and start time " . $stream->{start_time};
        }
}

use_ok("Media::Convert::Asset");
use_ok("Media::Convert::AccurateCut");

my $asset = Media::Convert::Asset->new(url => "t/testvids/bbb.mp4");
isa_ok($asset, "Media::Convert::Asset");

my $values = get_values($asset->url);

debug_values($values);

my $output = Media::Convert::Asset->new(url => "./bbb.mkv");
my $cut = Media::Convert::AccurateCut->new(input => $asset, output => $output, start => 0.1);
$cut->run;

$values = get_values($output->url);

debug_values($values);

my $starts = get_start_times($values);
ok(exists($starts->{audio}), 'output has audio stream');
ok(exists($starts->{video}), 'output has video stream');
my $delta = abs($starts->{audio} - $starts->{video});
cmp_ok($delta, '<=', 0.03, 'audio/video start times are close enough');

done_testing()
