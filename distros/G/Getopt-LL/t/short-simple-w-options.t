use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 2;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

BEGIN {
@ARGV = qw( The --quick 10 brown fox -jumps over -- --the lazy -dawg );
}

use Getopt::LL::Simple qw(
    --quick=d 
    --the=s
    -dawg
    -j
    -u
    -m
    -p
    -s=s
), { style => 'GNU' };

is_deeply(\%ARGV, {
    '--quick' => 10,
    '-j'      => 1,
    '-u'      => 1,
    '-m'      => 1,
    '-p'      => 1,
    '-s'      => 'over',
}, '%ARGV set correctly.');

is_deeply([@ARGV],
    [qw(The brown fox --the lazy -dawg)],
    '@ARGV set correctly'
);
