#!/usr/bin/perl

use strict;
use warnings;
use Test::Simple tests => 10;
use Eircode qw< split_eircode >;

my @t = (
    ['A65 B2CD' , 1, ['A65', 'B2CD'], 'Simple'],
    ['a65 b2cd', 1, ['a65', 'b2cd'], 'Don\'t transform'],
    ['a65b2cd', 1, ['a65', 'b2cd'], 'No space, lowercase'],
    ['a65b2cd2', 0, [], 'Invalid'],
    [' a65b2cd', 0, [], 'Invalid leading whitespace'],
    ['a65b2cd ', 0, [], 'Invalid trailing whitespace'],
    ['a65b2cd foo', 0, [], 'Invalid extra text after space'],
    [' a 6 5 b 2 c d', 0, [], 'wont fix crazy whitespace'],
    ['A65    B2CD' , 1, ['A65', 'B2CD'], 'But is tolerent of too much'],
    ["A65\tB2CD" , 1, ['A65', 'B2CD'], 'Tolerent of a tab'],
);

for( @t ){
    my( $input, $ok, $expect, $tn ) = @{ $_ };
    my $output;
    eval{
        my($a, $b) = split_eircode($input);
        $output = [$a, $b];
    };

    if( $@ || ! $ok){
        if( $ok && $@ ){
            warn("# ",$@);
        }
        ok( $ok ? $@ eq undef : $@, $tn) or warn "# $@";
    }
    else{
        ok( $output->[0] eq $expect->[0]
            && $output->[1] eq $expect->[1],
            $tn) or warn ( "# ", $output->[0] .' = '. $expect->[0]
                         .'&& '. $output->[1] .' = '. $expect->[1]);
    }
}
