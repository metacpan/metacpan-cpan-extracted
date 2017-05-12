# -*- mode: cperl -*-
use strict;
use warnings;
use t::Utils;

use Test::More;
plan tests => 2;

use FindBin;
use IO::File::AtomicChange;

my $basedir     = $FindBin::Bin; # t/
my $target_file = "$basedir/file/70_not-close";
my(@data, @wrote, $f, $testee);
END { unlink $target_file; cleanup_backup("$basedir/file", "70_not-close"); }

### first, write data
@data = map $_."\n", qw(ichi ni);
@wrote = ();
unlink $target_file if -f $target_file;
$testee = write_and_read([$target_file, "w"], \@data);
push @wrote, @data;
is($testee, join("",@data), "create truncate write");

### die before close and check whether read data is same as previous data (not wrote data).
@data = map $_."\n", qw(blah blah);
eval {
$testee = write_and_read([$target_file, "w"], \@data,
                         {
                             before_close => sub {
                                 my($f) = @_;
                                 die "abort";
                             },
                         });
};
is(slurp($target_file), join("",@wrote), "same as data before write");

