# -*- mode: cperl -*-
use strict;
use warnings;
use t::Utils;

use Test::More;
plan tests => 4;

use FindBin;
use IO::File::AtomicChange;

my $basedir     = $FindBin::Bin; # t/
my $target_file = "$basedir/file/10_write";
my(@data, $f, $testee);
END { unlink $target_file }

###
@data = map $_."\n", qw(ichi ni);
unlink $target_file if -f $target_file;
$testee = write_and_read([$target_file, "w"], \@data);
is($testee, join("",@data), "create truncate write");

###
@data = map $_."\n", qw(san shi);
# not unlink
$testee = write_and_read([$target_file, "w"], \@data);
is($testee, join("",@data), "truncate write");

###
@data = map $_."\n", qw(go rou);
unlink $target_file if -f $target_file;
$testee = write_and_read([$target_file, "w+"], \@data);
is($testee, join("",@data), "create truncate write readable");

###
@data = map $_."\n", qw(nana hachi);
# not unlink
$testee = write_and_read([$target_file, "w+"], \@data);
is($testee, join("",@data), "truncate write readable");

