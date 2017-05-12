#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:all);
use LucyX::Suggester;

my $ix = LucyX::Suggester->new( indexes => [@ARGV] );
my $re = LucyX::Suggester->new( indexes => [@ARGV], use_regex => 1 );

cmpthese(
    1000,
    {   'regex' => sub {
            $ix->suggest('quiK brwn fx running');
        },
        'index' => sub {
            $re->suggest('quiK brwn fx running');
        },
    }
);
