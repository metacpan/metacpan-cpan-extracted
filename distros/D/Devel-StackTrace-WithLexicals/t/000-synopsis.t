#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

my $ok = 0;

do {
    package Synopsis;
    sub oh_god_why { $ok = 1 }
};

my $sub = sub {
    use Devel::StackTrace::WithLexicals;
    my $trace = Devel::StackTrace::WithLexicals->new(unsafe_ref_capture=>1);
    ${ $trace->frame(1)->lexical('$self') }->oh_god_why();
};

my $self = bless {}, 'Synopsis';

$sub->();

ok($ok, "oh_god_why called");

