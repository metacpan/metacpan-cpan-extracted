#! /usr/bin/perl

use strict;
use warnings;
use Test::More;

# Check whether we can reach the tile server first.  Otherwise it
# makes no sense to try testing the script.
use LWP::UserAgent;
eval {
    my $testurl = 'http://tile.openstreetmap.org/0/0/0.png';
    my $lwpua = LWP::UserAgent->new;
    $lwpua->env_proxy;
    my $res = $lwpua->get($testurl);
    die $res->status_line
	unless $res->is_success;
};
if ($@) {
    plan skip_all => "could not reach tile server: $@";
}
else {
    plan tests => 3 * 3 + 19;
}

use Config;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use File::Find;
use YAML qw( DumpFile LoadFile );

# you may switch off $cleanup for debugging this test script.
our $cleanup = 1;

# Hack 1:
# Problem in ExtUtils::Command::MM: the test_harness subroutine in
# ExtUtils::Command::MM fails to put the @test_libs arguments into
# $ENV{PERLLIB} in order to communicate this information to child
# processes.  Ugly, quick and dirty work around: Assume @test_libs to
# be ('blib/lib', 'blib/arch').
$ENV{PERLLIB} = abs_path('blib/lib') . ":" . abs_path('blib/arch') .
    ( $ENV{PERLLIB} ? ":$ENV{PERLLIB}" : "" );

# Hack 2:
# Is there any official way to know where the scripts will be placed
# during the test phase?
our $downloadosmtiles = abs_path('blib/script/downloadosmtiles.pl');

sub countpng;
sub cleantmp;

our $perl = $Config{perlpath};
our $testdir = tempdir( CLEANUP => $cleanup );
our $tilelistfile = File::Spec->catfile($testdir, "tilelist");
our $pngcount;
our $dubiouscount;


# check whether the script is properly placed where we expect it do be.
# 1 test
ok(-e $downloadosmtiles, "downloadosmtiles.pl is present");

# download single tiles for a bunch of positions
# 3 * 3 + 1 tests
{
    my $subtestdir = File::Spec->catdir($testdir, "t1");
    ok( mkdir($subtestdir), "create subtestdir" );

    my @positions = (
	{
	    LAT => "0",
	    LON => "0",
	    ZOOM => "0",
	},
	{
	    LAT => "5.0",
	    LON => "-10.0",
	    ZOOM => "2",
	},
	{
	    LAT => "-41.272",
	    LON => "174.863",
	    ZOOM => "9",
	},
    );

    for (@positions) {
	my $lat = $_->{LAT};
	my $lon = $_->{LON};
	my $zoom = $_->{ZOOM};
	my @args = ( $downloadosmtiles, 
		     "--latitude=$lat", "--longitude=$lon", "--zoom=$zoom",
		     "--quiet", "--destdir=$subtestdir" );
	@args = map { "\"$_\"" } @args
	    if $^O =~ /^mswin/i;
	my $res = system($perl, @args);
	is($res, 0, "return value from downloadosmtiles.pl");

	$pngcount = 0;
	find(\&countpng, File::Spec->catdir($subtestdir, $zoom));
	is($pngcount, 1, "number of dowloaded tiles");

	$dubiouscount = 0;
	find({ wanted => \&cleantmp, bydepth => 1, no_chdir => 1 }, $subtestdir)
	    if $cleanup;
	ok(!$dubiouscount, "dubious files found");
    }
}


# test --link option
# 9 tests
{
    my $subtestdir = File::Spec->catdir($testdir, "t2");
    ok( mkdir($subtestdir), "create subtestdir" );

    my $link = 'http://openstreetmap.org/?lat=14.692&lon=-17.448&zoom=11&layers=B000FTF';
    my @args = ( $downloadosmtiles, "--link=$link", "--zoom=11:13", 
		 "--quiet", "--destdir=$subtestdir" );
    @args = map { "\"$_\"" } @args
	if $^O =~ /^mswin/i;
    my $res = system($perl, @args);
    is($res, 0, "return value from downloadosmtiles.pl");

    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($subtestdir, "11"));
    cmp_ok($pngcount, '>=', 9, "number of dowloaded tiles");
    cmp_ok($pngcount, '<=', 16, "number of dowloaded tiles");

    my $oldcount = $pngcount;
    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($subtestdir, "12"));
    cmp_ok($pngcount, '>=', $oldcount, "number of dowloaded tiles");
    cmp_ok($pngcount, '<=', 4*$oldcount, "number of dowloaded tiles");

    $oldcount = $pngcount;
    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($subtestdir, "13"));
    cmp_ok($pngcount, '>=', $oldcount, "number of dowloaded tiles");
    cmp_ok($pngcount, '<=', 4*$oldcount, "number of dowloaded tiles");

    $dubiouscount = 0;
    find({ wanted => \&cleantmp, bydepth => 1, no_chdir => 1 }, $subtestdir)
	if $cleanup;
    ok(!$dubiouscount, "dubious files found");
}


# test --dumptilelist option
# 3 tests
{
    my @args = ( $downloadosmtiles, 
		 "--lat=51.5908:51.5974", "--lon=9.9537:9.9645", 
		 "--zoom=15:16", "--dumptilelist=$tilelistfile",
		 "--quiet" );
    @args = map { "\"$_\"" } @args
	if $^O =~ /^mswin/i;
    my $res = system($perl, @args);
    is($res, 0, "return value from downloadosmtiles.pl");

    my $expectedtilelist = {
	15 => [
	    {
		xyz => [ 17290, 10883, 15 ],
	    },
	],
	16 => [
	    {
		xyz => [ 34580, 21766, 16 ],
	    },
	    {
		xyz => [ 34580, 21767, 16 ],
	    },
	    {
		xyz => [ 34581, 21766, 16 ],
	    },
	    {
		xyz => [ 34581, 21767, 16 ],
	    },
	],
    };
    my $tilelist = LoadFile($tilelistfile);
    isa_ok( $tilelist, 'HASH', "loaded tile list" );
    is_deeply( $tilelist, $expectedtilelist, "loaded tile list" );
}


# test --loadtilelist option
# 5 tests
{
    my $subtestdir = File::Spec->catdir($testdir, "t4");
    ok( mkdir($subtestdir), "create subtestdir" );

    my @args = ( $downloadosmtiles, 
		 "--loadtilelist=$tilelistfile",
		 "--quiet", "--destdir=$subtestdir" );
    @args = map { "\"$_\"" } @args
	if $^O =~ /^mswin/i;
    my $res = system($perl, @args);
    is($res, 0, "return value from downloadosmtiles.pl");

    # We loaded the tile list created by the --dumptilelist test
    # above.  We should find the tiles as listed in $expectedtilelist
    # downloaded to $subtestdir now.
    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($subtestdir, 15));
    is($pngcount, 1, "number of dowloaded tiles");

    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($subtestdir, 16));
    is($pngcount, 4, "number of dowloaded tiles");

    $dubiouscount = 0;
    find({ wanted => \&cleantmp, bydepth => 1, no_chdir => 1 }, $subtestdir)
	if $cleanup;
    ok(!$dubiouscount, "dubious files found");
}


sub countpng
{
    if ($_ =~ /^\d+\.png$/) {
	unlink($_)
	    if $cleanup;
	$pngcount++;
    }
}


sub cleantmp
{
    if (-d $_) {
	rmdir($_)
	    if $_ ne $testdir;
    }
    else {
	diag("dubious file $File::Find::name");
	$dubiouscount++;
	unlink($_);
    }
}


# Local Variables:
# mode: perl
# End:
