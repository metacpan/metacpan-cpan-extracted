#!/usr/bin/perl
########################################################################
# misc.t:
#   v0.042: add reduce_hand() to miscFunctions
#       make sure that it will shrink the hand_tile string
########################################################################

use 5.008;

use warnings;
use strict;
use Test::More; # tests => 3;

use IO::String;
use File::Basename qw/dirname/;
use Cwd qw/abs_path chdir/;
BEGIN: { chdir(dirname($0)); }

use Games::Literati 0.042 qw/:infoFunctions/;

# test coverage: need to run this legacy subroutine _init()
{
    Games::Literati::var_init(15,15,7);
    Games::Literati::_init();
}

# verify legacy _init works properly
{
    my $exp = 'a1b3c3d2e1f4g2h4i1j8k5l1m3n1o1p3q10r1s1t1u1v4w4x8y4z10';
    my $got = join('', map { "$_$Games::Literati::values{$_}"} ('a'..'z'));
    is( $got, $exp, "check legacy _init() by checking: Scrabble letter-scores");
    is( n_rows,         15 , "... and Scrabble n_rows");
    is( n_cols,         15 , "... and Scrabble n_cols");
    is( numTilesPerHand, 7 , "... and Scrabble numTilesPerHand");
}

# verify legacy check() works properly
for ( [ [qw/assure comment/] => 1], [[qw/ensure comet/] => undef] ) {
    my $stringify = '';
    my $fhString = IO::String->new($stringify);
    select $fhString;
    $| = 1;
    Games::Literati::check($_->[0]);
    select STDOUT;
    close $fhString;
    for my $word ( @{$_->[0]} ) {
        my $cmp = qq{"$word" is };
        $cmp .= ( $_->[1] ) ? 'valid.' : 'invalid.';
        like $stringify, qr/^\Q$cmp\E$/ms, "check() $cmp";
    }
}

# verify legacy find() works properly
for (
    [{letters => 'ant', re => '/a./'}, [qw/an ant/]],
    [{letters => 'a?t', re => '/a../', internal=>0}, [qw/ant/]],
    [{letters => 'ant', re => '/a./', internal=>1}, [], [qw/an ant/]],
)
{
    my ($h, $r, $t) = (@$_, ([])x3);
    my $stringify = '';
    my $fhString = IO::String->new($stringify);
    select $fhString;
    $| = 1;
    my $results = Games::Literati::find($h);
    select STDOUT;
    close $fhString;

    # diag "stringify => >>", $stringify, "<<\n";

    for my $match ( @$r ) {
        like $stringify, qr/\b$match\b/m, sprintf "find({ %s }) vs /%s/", join(', ', map "$_=>$h->{$_}", sort keys %$h), $match;
    }
    if( @$t ) {
        is_deeply [sort @$results], [sort @$t], sprintf "find({ %s }) array-ref (internal) check", join(', ', map "$_=>$h->{$_}", sort keys %$h);
    }

}

done_testing;
