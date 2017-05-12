#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 12;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Bug DBNX#11: pipe and command on ingress line confuse egress state change

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
S]echo replacing all b with k
I]cat <<EOF | sed 's/b/k/'
H]bo
H]boj
E]EOF
S]echo replacing all b with k - now with pipe tight
I]cat <<EOF|sed 's/b/k/'
H]bo
H]boj
E]EOF
S]echo "all done"

