# -*- mode: cperl -*-
use strict;
use warnings;
use t::Utils;

use Test::More;
plan tests => 4;

use FindBin;
use IO::File::AtomicChange;

my $basedir     = $FindBin::Bin; # t/
my $target_file = "$basedir/file/12_read";
my(@data, $f, $testee);
my(@wrote);
END { unlink $target_file }

###
@data = map $_."\n", qw(ichi ni);
unlink $target_file if -f $target_file;
@wrote = ();
$testee = write_and_read([$target_file, "w"], \@data);
push @wrote, @data;
is($testee, join("",@wrote), "create truncate write");

###
$testee = write_and_read([$target_file, "r"], []);
is($testee, join("",@wrote), "read");

###
@data = map $_."\n", qw(san si);
$testee = write_and_read([$target_file, "r+"], \@data,
                         {
                             before_write => sub {
                                 my $f = shift;
                                 $f->seek(0,2); # SEEK_END
                             },
                         });
push @wrote, @data;
is($testee, join("",@wrote), "read writable");

###
$testee = write_and_read([$target_file, "r"], []);
is($testee, join("",@wrote), "read");
