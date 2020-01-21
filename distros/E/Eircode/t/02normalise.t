#!/usr/bin/perl

use strict;
use warnings;
use Test::Simple tests => 4;
use Eircode qw< normalise_eircode >;

my @t = (
    ['A65 B2CD' , 1, 'A65 B2CD', 'Simple nothing'],
    ['a65b2cd', 1, 'A65 B2CD', 'Actually transform'],
    ['a65b2cd2', 0, '', 'Invalid'],
    [' a 6 5 b 2 c d', 1, 'A65 B2CD', 'Dont care for whitespace'],
);

for( @t ){
    my( $input, $ok, $expect, $tn ) = @{ $_ };
    my $output;
    eval{
        $output = normalise_eircode($input);
    };

    if( $@ || ! $ok){
        ok( $ok ? !$@ : $@, $tn);
        if( $ok && $@ ){
            warn("#",$@);
        }
    }
    else{
        ok( $output eq $expect, $tn);
    }
}
