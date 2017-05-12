# -*- mode: cperl -*-
use strict;
use warnings;
use t::Utils;

use Test::More;
plan tests => 4;

use FindBin;
use IO::File::AtomicChange;

my $basedir     = $FindBin::Bin; # t/
my $target_file = "$basedir/file/11_append";
my(@data, $f, $testee);
my(@wrote);
END { unlink $target_file }

###
@data = map $_."\n", qw(ichi ni);
unlink $target_file if -f $target_file;
@wrote = ();
$testee = write_and_read([$target_file, "a"], \@data);
push @wrote, @data;
is($testee, join("",@data), "create truncate append");

###
@data = map $_."\n", qw(san shi);
# not unlink
$testee = write_and_read([$target_file, "a"], \@data);
push @wrote, @data;
is($testee, join("",@wrote), "truncate append");

###
@data = map $_."\n", qw(go rou);
unlink $target_file if -f $target_file;
@wrote = ();
$testee = write_and_read([$target_file, "a+"], \@data);
push @wrote, @data;
is($testee, join("",@data), "create truncate append readable");

###
@data = map $_."\n", qw(nana hachi);
# not unlink
$testee = write_and_read([$target_file, "a+"], \@data);
push @wrote, @data;
is($testee, join("",@wrote), "truncate append readable");

