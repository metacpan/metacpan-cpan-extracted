#!/usr/bin/perl
use warnings; use strict;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

my $kwalitee = join('::', qw(Test Kwalitee));

eval "require $kwalitee; $kwalitee->import(tests => ['-use_strict'])";
print "1..0 # SKIP $kwalitee not installed; skipping\n"
    if $@;
