#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark qw/cmpthese/;

my (@sub1, @sub2);

for (1 .. 10)
{
    push(@sub1, 'foo');
    push(@sub1, 'bar');
}

for (1 .. 10)
{
    push(@sub2, 'foo_d');
    push(@sub2, 'bar_d');
}

no strict 'refs';

cmpthese(-1, {
    'a' => sub { my $text = 'aaa' x 999; $text = $_->($text) for @sub1; },
    'b' => sub { my $text = 'aaa' x 999; $_->(\$text)        for @sub2; },
});

sub foo
{
    my $text = shift;
    $text =~ tr/a/b/;
    return $text;
}

sub bar
{
    my $text = shift;
    $text =~ tr/b/a/;
    return $text;
}

sub foo_d
{
    my $text_ref = shift;
    $$text_ref =~ tr/a/b/;
}

sub bar_d
{
    my $text_ref = shift;
    $$text_ref =~ tr/b/a/;
}
