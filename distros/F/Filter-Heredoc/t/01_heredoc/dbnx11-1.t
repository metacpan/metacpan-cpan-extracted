#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 13;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Bug DBNX#11: pipe on ingress line confuse egress state change.
# Note that last ingress test place the pipe (|) just behind '<<'  

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
S]echo replacing all a with o
I]cat <<EOF |
H]aj
H]haj
E]EOF
S]sed 's/a/o/'
S]echo and back again, o with a
I]cat <<EOF|
H]oj
H]hoj
E]EOF
S]sed 's/o/a/'

