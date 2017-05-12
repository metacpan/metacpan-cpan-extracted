#!/usr/local/bin/perl -w
use Test::More;
use strict;

use MP3::Info 1.02;

use File::Path;
use File::Spec::Functions qw(catfile catdir devnull);

# this test takes a long time -- even up to an hour -- so it is
# turned off by default.  if you want to run it, just comment
# this block out.
BEGIN {
	plan tests => 1;
	pass("Test disabled; see source for more information");
	exit;
}


### NOTE
# sometimes lame pukes on an MP3.  if you get a few errors in the test, run
# with `make test TEST_VERBOSE=1` (if you are running via make test) and
# find out which file(s) are not working; delete those manually, and re-run
# the tests.  the files currently are not deleted when the tests complete;
# you may wish to manually delete them later.

my($lame, @mp3s, %files);
my @lamedirs = qw(/sw/bin /usr/local/bin /usr/bin);
my @lopts = qw(--silent);  # this is in newer versions of lame
my $file  = 'test.aiff';
my $dir   = 'lamemp3s';
my $tdir  = 't';
my %hopts  = (
	v		=> [undef, 'true'],
#	c		=> [undef, 'true'],
	b		=> [  8,  16,  24,  32,  40,  48,  56,  64,  80,
			     96, 112, 128, 144, 160, 192, 224, 256, 320],
	resample	=> [ 16, 22.05, 24, 32, 44.1, 48], # 8, 11.025, 12,
	'm'		=> [qw(m s j f d)],
);
my %mmap = ( 'm' => 3, 's' => 0, j => 1, d => 2, f => 1 );
my %fmap = (
	1 => { map { ($_, 1) } (32, 44.1,  48) },
	2 => { map { ($_, 1) } (16, 22.05, 24) },
);

for my $lamedir (@lamedirs) {
	last if -x ($lame = catfile($lamedir, 'lame'));
}

unless (-x $lame) {
	plan tests => 1;
	pass("No lame found");
	exit;
}


if ( ! -e $file && (-e catfile($tdir, $file)) ) {
	$file = catfile($tdir, $file);
	$dir  = catdir($tdir, $dir);
}

exit if ! -e $file;  # hrm

mkpath $dir;

{ # define MP3s to create
	for my $opt (sort keys %hopts) {
		if (! @mp3s) {
			for (@{$hopts{$opt}}) {
				push @mp3s, { $opt => $_ };
			}
		} else {
			my @newmp3s;
			for my $mp3 (@mp3s) {
				for (@{$hopts{$opt}}) {
					push @newmp3s, { %$mp3, $opt => $_ };
				}
			}
			@mp3s = @newmp3s;
		}
	}
}

{ # create MP3s
	my($done, $total) = (0, scalar @mp3s);
	diag("Creating $total MP3s, this could take a long time");
	print "# $done of $total\n";
	for my $set (@mp3s) {
		my(@nopts, @output);
		for my $nopt (sort keys %$set) {
			if (defined $set->{$nopt}) {
				push @output, $nopt;
				push @nopts, length($nopt) > 1 ? "--$nopt" : "-$nopt";
				if ($set->{$nopt} ne 'true') {
					push @nopts, $set->{$nopt};
					push @output, $set->{$nopt};
				}
			}
		}
		my $output = sprintf 'test-%s.mp3', join '_', @output;
		$files{$output}++;
		my $ofile = catfile($dir, $output);
		qx($lame @lopts @nopts $file $ofile 2>/dev/null) unless -e $ofile;

		print "# $done of $total\n" if ++$done =~ /00$/;
	}
}

print "# Deleting empty MP3s\n";
{ # delete empty files
	for my $file (keys %files) {
		my $f = catfile($dir, $file);
		if (-z $f) {
			unlink $f;
			delete $files{$file};
		}
	}
}

my $numtests = 8;
plan tests => $numtests * scalar keys %files;

MP3S: for my $file (sort keys %files) {
	my $info = get_mp3info(catfile($dir, $file));
	if (!$info) {
		my $err = $@;
		for (1..$numtests) {
			fail("$file: $err");
		}
		next MP3S;
	}

	my($b, $c, $m, $f, $v) =
		$file =~ /^test-b_(\d+)(_c)?_m_(\w)_resample_([\d.]+)(_v)?\.mp3$/
		or do {
			for (1..$numtests) {
				fail("$file: name incorrect");
			}
			next MP3S;
		};

	$v = $v ? $b == 320 ? 0 : 1 : 0;
	my $ver = $fmap{1}{$f} ? 1 : $fmap{2}{$f} ? 2 : 3;

	is($info->{VBR},       $v,        "VBR : $file");
	is($info->{FREQUENCY}, $f,        "FREQ: $file");
	is($info->{MODE},      $mmap{$m}, "MODE: $file");
	is($info->{VERSION},   $ver,      "VERS: $file");
	is($info->{LAYER},     3,         "LAYR: $file");
	is($info->{TIME},      "00:01",   "SECS: $file");
	is($info->{COPYRIGHT}, $c?1:0,    "COPY: $file");

	if ($v) {
		ok($info->{BITRATE} >= ($b - 10), "BITR: $file, $info->{BITRATE} >= $b");
	} else {
		is($info->{BITRATE}, $b,          "BITR: $file");
	}
}

if (0) { # clean up files, but honestly ... it takes so long to do it, just leave them
	for my $file (keys %files) {
		my $f = catfile($dir, $file);
		unlink $f;
	}
}

__END__
