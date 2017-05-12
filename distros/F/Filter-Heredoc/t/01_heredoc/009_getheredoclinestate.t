#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 16;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Test that an ingress line terminated without ';' or with is ok

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
S]echo "Testing bash"
S]echo "-------------"
I]cat <<eof1
H]1st hereline without ;
E]eof1
S]echo "first done"
I]cat <<eof2;
H]2nd hereline with ingress with ;
E]eof2
S]echo "-------------"
I]cat <<eof3        	 ;
H]3nd hereline with ingress with \n and \t and ;
E]eof3
S]echo "Back in source"
S]echo "--------------"


