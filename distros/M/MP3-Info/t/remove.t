#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 22 }

use MP3::Info 1.02;

use File::Copy 'copy';
use File::Spec::Functions 'catfile';

my %mp3s = (
	'v1'     => 'testv1.mp3',
	'v1.1'   => 'testv1.1.mp3',
	'v2.2.0' => 'testv2.2.0.mp3',
	'v2.3.0' => 'testv2.3.0.mp3',
	'v2.4.0' => 'testv2.4.0.mp3',
);

my %sizes = (
	'v1'     => 128,
	'v1.1'   => 128,
	'v2.2.0' => 106,
	'v2.3.0' => 130,
	'v2.4.0' => 130,
);


if ( ! -e $mp3s{v1} && (-e catfile('t', $mp3s{v1})) ) {
	for (keys %mp3s) {
		$mp3s{$_} = catfile('t', $mp3s{$_});
	}
}


SKIP: {
#	skip "MP3::Info", 10;

	for my $id3 (keys %mp3s) {
		my $n = $mp3s{$id3} . 'r';
		copy($mp3s{$id3}, $n);
		$mp3s{$id3} = $n;
	}

	for my $id3 (sort keys %mp3s) {
		my $bytes = remove_mp3tag($mp3s{$id3}, 'ALL');
		is($bytes, $sizes{$id3}, "Remove tag from ID3$id3");

		$bytes = remove_mp3tag($mp3s{$id3}, 'ALL');
		is($bytes, -1, "Remove no tag from ID3$id3");

		unlink $mp3s{$id3};
	}
}

SKIP: {
#	skip "MP3::Info", 12;

	for my $id3 (keys %mp3s) {
		next if $id3 =~ /v1/;
		(my $o = $mp3s{$id3}) =~ s/r$//;
		copy($o, $mp3s{$id3});
	}

	for my $id3 (sort keys %mp3s) {
		next if $id3 =~ /v1/;
		ok(my $tag = get_mp3tag($mp3s{$id3}), "Get tag for ID3$id3");
		ok(set_mp3tag($mp3s{$id3}, $tag), "Set new ID3v1.1 tag for ID3$id3 file");

		my $bytes = remove_mp3tag($mp3s{$id3}, 'ALL');
		is($bytes, $sizes{$id3} + $sizes{'v1.1'}, "Remove tag from ID3$id3 + ID3v1.1");

		$bytes = remove_mp3tag($mp3s{$id3}, 'ALL');
		is($bytes, -1, "Remove no tag from ID3$id3");

		unlink $mp3s{$id3};
	}
}

__END__
