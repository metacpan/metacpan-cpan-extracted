# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 7;
use Cwd qw/abs_path/;

#01
BEGIN { use_ok( 'Filesys::Type', qw(fstype case diagnose) ); }

my $curdir = abs_path('.');
my $fst = fstype($curdir);

diag(diagnose()) unless $fst;

#02
ok(defined $fst, "Returned an FS type");

#03
ok(defined case($fst), "Case returned something - fstype");

#04
ok(defined case($curdir), "Case returned something - path");

$fst = fstype('^%$£/~&&@@@'); # not a valid file spec on any OS I believe

#05
ok(!defined $fst, "Garbage path rejected");

#06
ok(diagnose(),"Diagnose said something");

#07
ok(fstype('t/001_load.t'),"Handles file path")
