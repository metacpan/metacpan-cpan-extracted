#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    use_ok('File::PerlMove');
}
diag( "Testing File::PerlMove $File::PerlMove::VERSION, Perl $], $^X" );

-d "t" && chdir("t");

require_ok("./00common.pl");

our $tf = "01basic.dat";

# Make sure there's no uc variant lying around.
unlink(uc($tf));

our $sz = create_testfile($tf);

# If the uc variant tests ok, we have a case insensitive file system.
my $ci = -s uc($tf);

try_move('s/\.dat$/.tmp/', "01basic.tmp", "move1");

# Skip uc/lc tests on case insensitive file systems.
SKIP: {
    skip "Case insensitive file system", 4 if $ci;
    try_move('uc', "01BASIC.TMP", "move2");
    try_move('lc', "01basic.tmp", "move3");
}

try_move(sub { s/^(\d+)/sprintf("%03d", 32+$1)/e; },
	 "033basic.tmp", "move4");

cleanup();

sub try_move {
    my ($code, $new, $tag) = @_;
    is(File::PerlMove::move($code, [ $tf ]), 1, $tag);
    $tf = verify($new, $tag);
}
