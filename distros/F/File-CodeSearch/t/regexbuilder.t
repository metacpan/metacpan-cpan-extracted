#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Term::ANSIColor qw/:constants/;
use File::CodeSearch::RegexBuilder;

simple();
whole();
array();
array_all();
ignore();
shortcuts();
array_words();
match();
sub_match();
reset_file();
last_match();
done_testing();

sub simple {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test'],
    );
    $re->make_regex;
    is($re->regex, qr/test/, 'simple');

    $re = File::CodeSearch::RegexBuilder->new(
        re             => ['(test)'],
    );
    $re->make_regex;
    is($re->regex, qr/(test)/, 'simple');

}

sub whole {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test'],
        whole          => 1,
    );
    $re->make_regex;
    is($re->regex, qr/\btest\b/, 'whole');

}

sub array {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
    );
    $re->make_regex;
    is($re->regex, qr/test words/, 'words concatinated with spaces');

    $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
        whole          => 1,
    );
    $re->make_regex;
    is($re->regex, qr/\btest\b \bwords\b/, 'simple');

}

sub array_words {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
        words          => 1,
    );
    $re->make_regex;
    is($re->regex, qr/test.*words/, 'words');

    $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
        words          => 1,
        whole          => 1,
    );
    $re->make_regex;
    is($re->regex, qr/\btest\b.*\bwords\b/, 'simple');

}

sub array_all {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
        all            => 1,
    );
    $re->make_regex;
    is($re->regex, qr/test.*words|words.*test/, 'all');

    $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
        all            => 1,
        whole          => 1,
    );
    $re->make_regex;
    is($re->regex, qr/\btest\b.*\bwords\b|\bwords\b.*\btest\b/, 'simple');

    $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test'],
        all            => 1,
        whole          => 1,
    );
    $re->make_regex;
    is($re->regex, qr/\btest\b/, 'simple');

}

sub ignore {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'words'],
        ignore_case    => 1,
    );
    $re->make_regex;
    is($re->regex, qr/(?i:test words)/, 'ignore');

}

sub shortcuts {
    my $re = File::CodeSearch::RegexBuilder->new(
        re => ['b', 'test'],
    );
    $re->make_regex;
    is($re->regex, qr/sub\s+test/, 'shortcut b for sub');

    $re = File::CodeSearch::RegexBuilder->new(
        re => ['n', 'test'],
    );
    $re->make_regex;
    is($re->regex, qr/function(?:&?\s+|\s+&?\s*)test|test\s+=\s+function/, 'shortcut n for function');

    $re = File::CodeSearch::RegexBuilder->new(
        re => ['ss', 'test'],
    );
    $re->make_regex;
    is($re->regex, qr/class\s+test/, 'shortcut ss for class');

    $re = File::CodeSearch::RegexBuilder->new(
        re => [],
    );
    $re->make_regex;
    is($re->regex, qr//, 'empty');

}

sub match {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test'],
    );
    ok($re->match('this is a test'), 'matches "this is a test"');
    ok($re->match('testter'), 'matches "testter"');
    ok($re->match('intestter'), 'matches "intestter"');
    ok(!$re->match('intes'), 'matches "intes"');
    ok(!$re->match('estter'), 'matches "estter"');

    $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test', 'this'],
        all            => 1,
    );
    ok($re->match('test this'), 'test this');
    ok($re->match('this test'), 'this test');
    ok(!$re->match('test'), 'test');
    ok(!$re->match('this'), 'this');

    return;
}

sub sub_match {
    my $re = File::CodeSearch::RegexBuilder->new(
        re              => ['test'],
        sub_matches     => ['a'],
        sub_not_matches => ['q'],
    );

    $re->check_sub_matches('My test line');
    ok !$re->sub_match, 'No matches';

    $re->check_sub_matches('A test line for a');
    is $re->sub_match, 1, 'Matches';

    $re->check_sub_matches('An test line for a');
    is $re->sub_match, 1, 'Matches';

    $re->sub_match(0);
    ok !$re->sub_not_match, 'No not matches';

    $re->check_sub_matches('A test line for q');
    is $re->sub_not_match, 1, 'Not matches';

    $re->check_sub_matches('An test line for q');
    is $re->sub_not_match, 1, 'Not matches';

    return;
}

sub last_match {
    my $re = File::CodeSearch::RegexBuilder->new(
        re   => ['test'],
        last => ['sub'],
    );
    $re->match('my test match');

    is $re->get_last_found, '', 'No last found';

    $re->match("sub some_func {\n");
    $re->match("my test match\n");

    is $re->get_last_found, "sub some_func\n", 'last found as some_func';

    push @{ $re->last }, 'class';

    $re->match("class MyClass\n");
    $re->match("sub some_func {\n");
    $re->match("my test match\n");

    is $re->get_last_found, "class MyClass\nsub some_func\n", 'last found as some_func';

    $re->last([ 'class', 'function']);

    $re->reset_file('');
    $re->match("class MyClass\n");
    $re->match("function some_func {\n");
    $re->match("my test match\n");

    is $re->get_last_found, "class MyClass\nfunction some_func\n", 'last found as some_func';

    $re->reset_file('');
    $re->last(['other']);

    $re->match("class MyClass\n");
    $re->match("other to_be_known {\n");
    $re->match("my test match\n");

    is $re->get_last_found, "other to_be_known\n", 'last found as some_func';

    return;
}

sub reset_file {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test'],
    );
    $re->reset_file('');
    is($re->current_count, 0, 'count zero');
    $re->match('testter');
    is($re->current_count, 1, 'count one');
    $re->reset_file('');
    is($re->current_count, 0, 'reset count zero');

    return;
}
