#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Term::ANSIColor qw/:constants/;
use File::CodeSearch::Highlighter;

highlights();
regexes();
snip();
done_testing();

sub highlights {
    my $hl = File::CodeSearch::Highlighter->new(
        re             => ['test'],
        before_match   => '',
        after_match    => '',
        before_nomatch => '',
        after_nomatch  => '',
        snip           => 0,
    );
    $hl->make_highlight_re;
    is($hl->highlight('this test string'), 'this test string' . RESET . "\\N\n", 'no extra text gives back string');

    $hl = File::CodeSearch::Highlighter->new(
        re             => ['test'],
        before_match   => '-',
        after_match    => '=',
        before_nomatch => '*',
        after_nomatch  => '#',
        limit          => 90,
    );
    is($hl->highlight('this test string'), '*this #-test=* string#' . RESET . "\\N\n", 'the appropriate higlights are put in');
    is($hl->highlight("this test string\n"), "*this #-test=* string\n#" . RESET . "", 'no extra text gives back string');

    $hl = File::CodeSearch::Highlighter->new(
        re             => ['test'],
        before_match   => '-',
        after_match    => '=',
        before_nomatch => '*',
        after_nomatch  => '#',
        limit          => 212,
    );
    is($hl->highlight('this test string with test again'), '*this #-test=* string with #-test=* again#' . RESET . "\\N\n", 'the appropriate higlights are put in');
    is($hl->highlight('this test string with test again' . 'n' x 29), '*this #-test=* string with #-test=* again'.('n' x 29).'#' . RESET . "\\N\n", 'the appropriate higlights are put in');
    is($hl->highlight('this test string with test again' . 'n' x 60), '*this #-test=* string with #-test=* again'.('n' x 60).'#' . RESET . "\\N\n", 'the appropriate higlights are put in');
}

sub snip {
    my $hl = File::CodeSearch::Highlighter->new(
        re             => ['test'],
        before_match   => '',
        after_match    => '',
        before_nomatch => '',
        after_nomatch  => '',
        snip           => 1,
        before_snip    => '',
        after_snip     => '',
        limit          => 10,
    );
    $hl->make_highlight_re;
    is($hl->highlight('this test string'), '...test...' . RESET . "\\N\n", 'no extra text gives back string');

    $hl = File::CodeSearch::Highlighter->new(
        re             => ['test'],
        before_match   => '-',
        after_match    => '=',
        before_nomatch => '*',
        after_nomatch  => '#',
        snip           => 1,
        before_snip    => '^',
        after_snip     => '$',
        limit          => 10,
    );
    is($hl->highlight('this test string'), '*^...$*#-test=*^...$*#' . RESET . "\\N\n", 'the appropriate higlights are put in');

    $hl = File::CodeSearch::Highlighter->new(
        re             => ['test'],
        before_match   => '-',
        after_match    => '=',
        before_nomatch => '*',
        after_nomatch  => '#',
        snip           => 1,
        before_snip    => '^',
        after_snip     => '$',
        limit          => 13,
    );
    is($hl->highlight('this test string with test again'), '*^...$*#-test=*^...$*#-test=*^...$*#' . RESET . "\\N\n", 'the appropriate higlights are put in');
}

sub regexes {
    my $hl = File::CodeSearch::Highlighter->new( re => ['test'] );
    $hl->make_regex;
    $hl->make_highlight_re;
    is($hl->highlight_re, qr/test/, 'simple re returns simple string');
    is $hl->make_highlight_re, qr/test/, 'Simple high light regex unchanged';

    $hl = File::CodeSearch::Highlighter->new( re => ['(test)'] );
    $hl->make_highlight_re;
    is($hl->highlight_re, qr/(?:test)/, 'simple re returns simple string');

    $hl = File::CodeSearch::Highlighter->new( re => ['(?:test)'] );
    $hl->make_highlight_re;
    is($hl->highlight_re, qr/(?:test)/, 'simple re returns simple string');

    $hl = File::CodeSearch::Highlighter->new( re => ['(?xmsi:test)'] );
    $hl->make_highlight_re;
    is($hl->highlight_re, qr/(?xmsi:test)/, 'simple re returns simple string');

    return;
}
