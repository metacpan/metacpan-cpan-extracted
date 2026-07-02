#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use HTML::Composer;
use List::Util qw(reduce);

# Requested as an example by u/roXplosion on reddit

my $list = {
    'Syd'   => 2.8,
    'Yin'   => 7.5,
    'Ringo' => 8,
    'GoGo'  => 80
};

my $h = HTML::Composer->new;

# Imperative solution

my $headers = [];
my $data    = [];
for ( keys(%$list) ) {
    push @$headers, ( th => [$_] );
    push @$data,    ( td => [ $list->{$_} ] );
}

my $html;
my $html_head = [ head => [ title => ['My table'] ] ];

$html = $h->html(
    [
        @$html_head,
        body => [
            table => [
                tr => $headers,
                tr => $data,
            ]
        ]
    ]
);

say 'Imperative solution';
say $html;

# Functional solution

$html = $h->html(
    [
        head => [ title => ['My table'] ],
        body => [
            table => [
                map { ( tr => $_ ) } @{
                    (
                        reduce {
                            push @{ $a->[0] }, th => [$b];
                            push @{ $a->[1] }, td => [ $list->{$b} ];
                            $a;    # make sure to return $a
                        } [ [], [] ],
                        keys(%$list)
                    )
                }
            ]
        ]
    ]
);

say 'Functional solution';
say $html;
