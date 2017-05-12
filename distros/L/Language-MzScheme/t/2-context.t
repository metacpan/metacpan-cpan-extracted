#!/usr/bin/perl

use strict;
use Data::Dumper;
use Test::More tests => 72;

use_ok('Language::MzScheme');

my $env = Language::MzScheme->new;

my $sigils = {
    auto    => '',
    void    => '!',
    bool    => '?',
    scalar  => '$',
    string  => '~',
    number  => '+',
    char    => '.',
    list    => '@',
    vector  => '^',
    hash    => '%',
    alist   => '&',
};

my $plans = [
    sub { @_ } => [
        [] => {
            auto   => [],       void   => undef,    bool   => undef,
            scalar => 0,        string => "0",      number => 0,
            char   => '0',      list   => [],       vector => [],
            hash   => {},       alist  => [],
        },
        [2] => {
            auto   => 2,        void   => undef,    bool   => '#t',
            scalar => 1,        string => "1",      number => 1,
            char   => '1',      list   => [2],      vector => [2],
            hash   => { 2 => undef },
        },
        [1,2] => {
            auto   => [1,2],    void   => undef,    bool   => '#t',
            scalar => 2,        string => "2",      number => 2,
            char   => '2',      list   => [1,2],    vector => [1,2],
            hash   => { 1 => 2 },
        },
        ["a","b"] => {
            auto   => ["a","b"],void   => undef,    bool   => '#t',
            scalar => 2,        string => "2",      number => 2,
            char   => '2',      list   => ["a","b"],vector => ["a","b"],
            hash   => { a => "b" },
        },
    ],
    sub { 0 } => [ [] => {
            auto   => 0,        void   => undef,    bool   => undef,
            scalar => 0,        string => "0",      number => 0,
            char   => '0',      list   => [0],      vector => [0],
            hash   => { 0 => undef },
    }, ],
    sub { \&ok } => [ [] => {
            auto   => \&ok,     void   => undef,    bool   => '#t',
            scalar => \&ok.'',  string => \&ok.'',  number => \&ok+0,
            char   => 'C',      list   => [\&ok],   vector => [\&ok],
            hash   => { \&ok => undef },
    }, ],
    sub { "a", "b" } => [ [] => {
            auto   => ["a","b"],void   => undef,    bool   => '#t',
            scalar => "b",      string => "b",      number => 0,
            char   => 'b',      list   => ["a","b"],vector => ["a","b"],
            hash   => {"a","b"},
    }, ],
];

my ($sub, $plan);
my $subs = {
    map {
        ($_ => $env->define('perl-list'.$sigils->{$_}, sub { goto &$sub })),
    } keys %$sigils
};

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;
$Data::Dumper::Quotekeys = 0;
local $SIG{__WARN__} = sub { return }; # for nonnumeric casting
while (($sub, $plan) = splice(@$plans, 0, 2)) {
    while (my ($input, $output) = splice(@$plan, 0, 2)) {
        foreach my $context (sort keys %$output) {
            my $scheme_out = $subs->{$context}->(@$input);
            my $scheme_data = $scheme_out->as_perl_data;
            is_deeply(
                $scheme_data,
                $output->{$context},
                "$context context, ".
                    $scheme_out->as_write.
                    " => ".Dumper($scheme_data)
            );
        }
    }
}
