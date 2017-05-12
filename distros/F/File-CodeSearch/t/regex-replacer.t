#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Term::ANSIColor qw/:constants/;
use File::CodeSearch::Replacer;

highlights();
done_testing();

sub highlights {
    my $hl = File::CodeSearch::Replacer->new(
        re             => ['test'],
        replace        => 'replaced',
        before_match   => '',
        after_match    => '',
        before_nomatch => '',
        after_nomatch  => '',
    );
    $hl->make_replace_re;
    my $actual = [ $hl->highlight("this test string\n") ];
    my $expected = ['', "this test string\n", "this replaced string\n", "this replaced string\n"];
    is_deeply($actual, $expected, 'no extra text gives back string')
        or diag explain $actual, $expected;

    $hl = File::CodeSearch::Replacer->new(
        re             => ['test'],
        replace        => 'replaced',
        before_match   => '-',
        after_match    => '=',
        before_nomatch => '*',
        after_nomatch  => '#',
    );
    $actual = [ $hl->highlight('this test string') ];
    $expected = ['', "*this #-test=* string#\\N\n", "*this #-replaced=* string#\\N\n", 'this replaced string'];
    is_deeply($actual, $expected, 'the appropriate higlights are put in')
        or diag explain $actual, $expected;

    $hl = File::CodeSearch::Replacer->new(
        re             => ['test'],
        replace        => 'replaced',
        before_match   => '-',
        after_match    => '=',
        before_nomatch => '*',
        after_nomatch  => '#',
    );
    $actual = [ $hl->highlight('this test string with test again') ];
    $expected = ['', "*this #-test=* string with #-test=* again#\\N\n", "*this #-replaced=* string with #-replaced=* again#\\N\n", 'this replaced string with replaced again'];
    is_deeply($actual, $expected, 'the appropriate higlights are put in')
        or diag explain $actual, $expected;
}
