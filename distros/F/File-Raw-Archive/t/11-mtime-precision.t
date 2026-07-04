#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/mtime.tar";

# Sub-second mtime: pass seconds and nanoseconds as separate integer
# fields to avoid double-precision rounding through the Perl <-> C
# boundary. The PAX `mtime=<sec>.<ns>` record carries them as decimal
# strings - exact down to 9 digits.
my $whole = 1735689600;
my $ns    = 123456789;

my $w = File::Raw::Archive->create($tar);
$w->add(name => 'frac.txt', content => 'data',
        mtime => $whole, mtime_ns => $ns);
$w->close;

my $r = File::Raw::Archive->open($tar);
my $e = $r->next;
is($e->name, 'frac.txt', 'name read back');
is($e->mtime, $whole, 'integer seconds preserved');
is($e->mtime_ns, $ns, 'nanoseconds preserved exactly');
$r->close;

done_testing;
