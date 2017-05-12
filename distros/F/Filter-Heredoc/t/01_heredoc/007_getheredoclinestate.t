#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 9;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Test 4h line with "inline-comment" (2nd '<<'should not trig ingress)

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
S]echo "Testing bash(now with inline comment - this is ok)"
S]echo "--------------------------------------------------"
I]cat <<eof1; # cat <<eof2
H]Hereline1,
H]hereline2
E]eof1
S]echo "Back in source"
S]echo "--------------"

