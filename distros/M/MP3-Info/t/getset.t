#!/usr/local/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 96 }

use MP3::Info 1.02;

use File::Copy;
use File::Spec::Functions;

use_winamp_genres();

my($tf1, $tf2, $tf3, $tf4, $tt1, $tt2, $ti1, $ti2,
    $ttd1, $ttd2, $tti1, $tti2);
$tf1 = 'test1.mp3';
$tf2 = 'test2.mp3';
$tf3 = 'test3.mp3';
$tf4 = 'test4.mp3';

if ( (! -e $tf1 && ! -e $tf2) && (-e catfile('t', $tf1) && -e catfile('t', $tf2)) ) {
	for ($tf1, $tf2, $tf3, $tf4) {
		$_ = catfile('t', $_);
	}
}

@{$ttd1}{qw(ALBUM ARTIST GENRE COMMENT YEAR TITLE TRACKNUM)} = (
	'', 'Pudge', 'Sound Clip', 'All Rights Reserved',
	'1998', 'Test 1', 1
);

@{$ttd2}{qw(ALBUM ARTIST GENRE COMMENT YEAR TITLE TRACKNUM)} = (
	'', 'Pudge', 'Sound Clip', 'All Rights Reserved',
	'1998', 'Test 2', 2
);

@{$tti1}{qw(FREQUENCY STEREO BITRATE LAYER MM SS VERSION TIME)} = (
	qw(44.1 1 128 3 0 0 1 00:00)
);

@{$tti2}{qw(FREQUENCY STEREO BITRATE LAYER MM SS VERSION TIME)} = (
	qw(22.05 0 128 3 0 1 2 00:01)
);

sub test_fields {
	my($f1, $f2, $f, $not, $note) = @_;

	if ($not) {
		isnt($f1->{$f}, $f2->{$f}, $note);
	} else {
		is($f1->{$f}, $f2->{$f}, $note);
	}
}

SKIP: {
#	skip "MP3::Info", 4;

	ok($tt1 = get_mp3tag ($tf1), 'get_mp3tag 1');
	ok($tt2 = get_mp3tag ($tf2), 'get_mp3tag 2');
	ok($ti1 = get_mp3info($tf1), 'get_mp3info 1');
	ok($ti2 = get_mp3info($tf2), 'get_mp3info 2');
}

SKIP: {
#	skip "MP3::Info", 14;

	for my $f (qw(ALBUM ARTIST GENRE COMMENT YEAR TITLE TRACKNUM)) {
		test_fields($tt1, $ttd1, $f, 0, "tag $f 1");
		test_fields($tt2, $ttd2, $f, 0, "tag $f 2");
	}
}

SKIP: {
#	skip "MP3::Info", 16;

	for my $f (qw(FREQUENCY STEREO BITRATE LAYER MM SS VERSION TIME)) {
		test_fields($ti1, $tti1, $f, 0, "info $f 1");
		test_fields($ti2, $tti2, $f, 0, "info $f 2");
	}
}

SKIP: {
#	skip "MP3::Info", 0;

	copy($tf1, $tf3) or die "Can't copy '$tf1' to '$tf3': $!";
	copy($tf2, $tf4) or die "Can't copy '$tf2' to '$tf4': $!";

	my %th = (ALBUM=>'hrmmm', ARTIST=>'hummmm', GENRE=>'Power Ballad');
	while (my($k, $v) = each %th) {
		$tt1->{$k} = $ttd1->{$k} = $tt2->{$k} = $ttd2->{$k} = $v;
	}
}

SKIP: {
#	skip "MP3::Info", 4;

	ok($tt1 = get_mp3tag ($tf3), 'get_mp3tag 3');
	ok($tt2 = get_mp3tag ($tf4), 'get_mp3tag 4');
	ok($ti1 = get_mp3info($tf3), 'get_mp3info 3');
	ok($ti2 = get_mp3info($tf4), 'get_mp3info 4');
}

SKIP: {
#	skip "MP3::Info", 6;

	for my $f (qw(ALBUM ARTIST GENRE)) {
		test_fields($tt1, $ttd1, $f, 1, "tag $f 1 != 3");
		test_fields($tt2, $ttd2, $f, 1, "tag $f 2 != 4");
	}
}

SKIP: {
#	skip "MP3::Info", 16;

	for my $f (qw(FREQUENCY STEREO BITRATE LAYER MM SS VERSION TIME)) {
		test_fields($ti1, $tti1, $f, 0, "info $f 1 == 3");
		test_fields($ti2, $tti2, $f, 0, "info $f 2 == 4");
	}
}

SKIP: {
#	skip "MP3::Info", 6;

	ok(set_mp3tag($tf3, $ttd1), 'set tag 3');
	ok(set_mp3tag($tf4, $ttd2), 'set tag 4');

	ok($tt1 = get_mp3tag ($tf3), 'get_mp3tag 3');
	ok($tt2 = get_mp3tag ($tf4), 'get_mp3tag 4');
	ok($ti1 = get_mp3info($tf3), 'get_mp3info 3');
	ok($ti2 = get_mp3info($tf4), 'get_mp3info 4');
}

SKIP: {
#	skip "MP3::Info", 14;

	for my $f (qw(ALBUM ARTIST GENRE COMMENT YEAR TITLE TRACKNUM)) {
		test_fields($tt1, $ttd1, $f, 0, "tag $f 1");
		test_fields($tt2, $ttd2, $f, 0, "tag $f 2");
	}
}

SKIP: {
#	skip "MP3::Info", 16;

	for my $f (qw(FREQUENCY STEREO BITRATE LAYER MM SS VERSION TIME)) {
		test_fields($ti1, $tti1, $f, 0, "info $f 1");
		test_fields($ti2, $tti2, $f, 0, "info $f 2");
	}
}


SKIP: {
#	skip "MP3::Info", 0;

	unlink($tf3) or warn "Can't unlink '$tf3': $!";
	unlink($tf4) or warn "Can't unlink '$tf4': $!";
}

__END__
