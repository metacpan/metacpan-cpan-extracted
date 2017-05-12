#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 127 }

use MP3::Info 1.02;

use File::Spec::Functions 'catfile';

my %mp3s = (
	'v1'     => 'testv1.mp3',
	'v1.1'   => 'testv1.1.mp3',
	'v2.2.0' => 'testv2.2.0.mp3',
	'v2.3.0' => 'testv2.3.0.mp3',
	'v2.4.0' => 'testv2.4.0.mp3',
);

my(%tags);

if ( ! -e $mp3s{v1} && (-e catfile('t', $mp3s{v1})) ) {
	for (keys %mp3s) {
		$mp3s{$_} = catfile('t', $mp3s{$_});
	}
}

SKIP: {
#	skip "MP3::Info", 15;

	for my $id3 (sort keys %mp3s) {
		ok(my $tag = get_mp3tag($mp3s{$id3}), "Get tag for ID3$id3");
		is($tag->{TAGVERSION}, "ID3$id3", "Check version for ID3$id3");
		is($tag->{TITLE}, "Test $id3", "Check title for ID3$id3");
		$tags{$id3} = $tag;
	}
}

SKIP: {
#	skip "MP3::Info", 112; # 120 - 8 = 112
	for my $id3 (keys %tags) {
		for my $tag (keys %{$tags{$id3}}) {
			# tag version wrong, of course
			next if $tag eq 'TAGVERSION' || $tag eq 'TITLE';
			for (keys %tags) {
				# no tracknum in v1
				next if $_ eq $id3;
				next if $tag eq 'TRACKNUM' && ($_ eq 'v1' || $id3 eq 'v1');
				is($tags{$id3}{$tag}, $tags{$_}{$tag}, "Compare $tag for ID3$id3 and ID3$_")
			}
		}
	}
}

__END__
