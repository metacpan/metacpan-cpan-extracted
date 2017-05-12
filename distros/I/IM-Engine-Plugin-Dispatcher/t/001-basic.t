#!/usr/bin/env perl
use strict;
use warnings;
use IM::Engine;
use Test::More tests => 2;

my @matched;
do {
    package MyTest::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on [['hello', 'hi']] => sub {
        push @matched, 'hello';
    };
};

my $engine = IM::Engine->new(
    interface => {
        protocol => 'CLI',
    },
    plugins => [
        Dispatcher => {
            dispatcher => 'MyTest::Dispatcher',
        },
    ],
);

$engine->run("hello");
is_deeply([splice @matched], ["hello"]);

$engine->run("hi");
is_deeply([splice @matched], ["hello"]);

