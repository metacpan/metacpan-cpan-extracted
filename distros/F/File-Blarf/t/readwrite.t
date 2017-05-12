#!perl -w

use strict;
use warnings;

use File::Temp;
use File::Blarf;
use Test::More tests => 11;
use Fcntl qw( :flock );

my $tempdir = File::Temp::tempdir( CLEANUP => 1, );

my $tempfile = $tempdir.'/file1';

#
# Scalar
#
my $scalar = "SCALAR";
ok(File::Blarf::blarf($tempfile,$scalar),'Wrote scalar to file');
my $read;
ok($read = File::Blarf::slurp($tempfile),'Read scalar from file');
is($scalar,$read,'Read data is written data');

#
# Array in list context
#
my @array = qw(An array of some text);
my $joined = join("\n",@array);
ok(File::Blarf::blarf($tempfile,$joined),'Wrote array to file');
my @read_array;
ok(@read_array = File::Blarf::slurp($tempfile,{ Chomp => 1, }),'Read array from file (list context)');
is_deeply(\@array,\@read_array,'Read data is_deeply written data');

#
# Array in scalar context
#
ok(File::Blarf::blarf($tempfile,$joined),'Wrote array to file');
ok($read = File::Blarf::slurp($tempfile,{ Chomp => 1, }),'Read array from file (scalar context)');
is($read,$joined,'Read data is written data, even in scalar context');

#
# Try to write to a locked file
#
open(my $FH, '<', $tempfile);
flock $FH, LOCK_EX;
my $timedout = 0;
eval {
    local $SIG{ALRM} = sub { die "timeout\n"; };
    alarm 1;
    File::Blarf::blarf($tempfile,$joined, { Flock => 1, });
};
alarm 0;
if($@ && $@ eq "timeout\n") {
    $timedout = 1;
}
ok($timedout,'Write operation on locked file timed out');
flock $FH, LOCK_UN;
ok(File::Blarf::blarf($tempfile,$joined, { Flock => 1, }),'Wrote array to a, now unlocked, file');
close($FH);
