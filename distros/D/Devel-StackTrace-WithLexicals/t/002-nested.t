#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Devel::StackTrace::WithLexicals;

sub outer {
    my $inner = \&inner;
    $inner->(@_);
}

sub inner {
    my $inside_inner = 1;
    Devel::StackTrace::WithLexicals->new(unsafe_ref_capture=>1);
}

my $main_program = 1;
my $trace = outer();
is($trace->frame_count, 3);

is_deeply($trace->frame(0)->lexicals, {
    '$inside_inner' => \1,
});

is_deeply($trace->frame(1)->lexicals, {
    '$inner' => \\&inner,
});

is_deeply($trace->frame(2)->lexicals, {
    '$main_program' => \1,
});

