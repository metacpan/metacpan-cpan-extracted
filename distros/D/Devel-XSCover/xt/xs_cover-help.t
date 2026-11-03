#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();

my $script = File::Spec->catfile('bin', 'xs_cover');
plan skip_all => "no $script here" unless -f $script;

my $help = `$^X -Ilib $script -h 2>&1`;
is($? >> 8, 0, '-h exits 0');
like($help, qr/xs_cover \[options\]/, '-h prints the synopsis');
like($help, qr/-plain t\/05-forks\.t/, 'the synopsis lists the plain option');

my $version = `$^X -Ilib $script -v 2>&1`;
is($? >> 8, 0, '-v exits 0');
like($version, qr/xs_cover version \d/, '-v prints the version');

my $bad = `$^X -Ilib $script -no_such_option 2>&1`;
is($? >> 8, 2, 'an unknown option exits 2');

done_testing;
