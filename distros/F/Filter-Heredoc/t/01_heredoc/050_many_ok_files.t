#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 163;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Test many bash files which are known to pass ok

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash --posix
I]cat <<eof1; cat <<eof2
H]Hi,
E]eof1
H]Helene.
E]eof2
S]
S]#!/bin/bash
S]echo "Testing bash with trailing space ingress lines"
S]echo "----------------------------------------------"
I]cat <<eof1; 
H]Hereline11
H]hereline12
E]eof1
S]echo need this line
I]cat << eof2 
H]Hereline21
H]hereline22
E]eof2
S]echo "Back in source"
S]echo "--------------"
S]#!/bin/bash
S]echo "Test matching specific delimiters"
I]cat << EOF1
H]Match EOF1 delimiter 1-line1
E]EOF1
S]echo "-----------------"
I]cat << EOF2
H]Match EOF2 delimiter 2-line1
H]Match EOF2 delimiter 2-line2  
E]EOF2
S]echo "----------------"
I]cat << EOF2
H]Match EOF2 delimiter 2-line1(second time)
H]Match EOF2 delimiter 2-line2(second time)  
E]EOF2
S]echo "-----------------" 
I]cat << EOF3
H]Match EOF3 delimiter 3-line1
H]Match EOF3 delimiter 3-line2  
E]EOF3
S]echo "-----------------" 
I]cat << EOF1
H]Match EOF1 delimiter 1-line1(second time)
E]EOF1
S]echo "-----------------"
S]echo "All done"
S]#!/bin/bash
S]echo "Testing bash(now with inline comment)"
S]echo "------------------------------------"
I]cat <<eof1; # cat <<eof2
H]Hereline1,
H]hereline2
E]eof1
S]Hereline1 and in second section after first egress
S]hereline2
S]eof2
S]echo "Back in source"
S]echo "--------------"
S]#!/bin/bash
S]echo "Testing bash(with ingress semicolon)"
S]echo "------------------------------------"
I]cat <<eof1;
H]Hereline1,
H]hereline2
E]eof1
S]echo "Back in source"
S]echo "--------------"
S]#!/bin/bash
S]echo "Testing bash with trailing 'space' after semicolon"
S]echo "-------------------------------------------------"
I]cat <<eof1; 
H]Hereline1,
H]hereline2
E]eof1
S]echo "Back in source"
S]echo "--------------"
S]#!/bin/bash
S]echo "Testing bash(now with inline comment - this is ok)"
S]echo "--------------------------------------------------"
I]cat <<eof1; # cat <<eof2
H]Hereline1,
H]hereline2
E]eof1
S]echo "Back in source"
S]echo "--------------"
S]#!/bin/bash
S]echo "Testing bash(now with dual egress - bash complains)"
S]echo "--------------------------------------------------"
I]cat <<eof1
H]First hereline1
H]Second hereline2
E]eof1
S]eof1
S]echo "Back in source"
S]echo "--------------"
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
S]
S]
S]#!/bin/bash
S]echo replacing all b with k
I]cat <<EOF | sed 's/b/k/'
H]bo
H]boj
E]EOF
S]echo now with tight pipe and back to b
I]cat <<EOF|sed 's/k/b/'
H]ko
H]koj
E]EOF
S]echo all as original
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
S]#!/bin/bash
S]echo "Testing bash"
S]echo "-------------"
I]cat <<eof1; cat <<eof2
H]Hereline1,
H]hereline2
E]eof1
H]Hereline1 and in second section after first egress
H]hereline2
E]eof2
S]echo "Back in source"
S]echo "--------------"
S]#!/bin/dash
S]echo "Testing dash"
S]echo "-------------"
I]cat <<eof1; cat <<eof2
H]Hereline1,
H]hereline2
E]eof1
H]Hereline1 and in second section after first egress
H]hereline2
E]eof2
S]echo "Back in source"
S]echo "--------------"
