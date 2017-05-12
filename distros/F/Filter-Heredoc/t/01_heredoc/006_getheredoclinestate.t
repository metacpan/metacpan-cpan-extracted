#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 40;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Test with spaces and tab indentations

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
S]#
S]# Demonstration of << and <<- 
S]#
S]echo
S]cd /home
S]du -s *       |
S]   sort  -nr  |
S]      sed 10q |
S]          while read amount name
S]          do
I]             cat << EOF
H]Greeting you are one of the top consumer of diskspace
H]on the system. Your home directory uses $amount disk blocks.
H]Please clean up unneeded files, as soon as possible.
H]
H]Thanks
H]Your friendly sysadmin
E]EOF
S]          done
S]#
S]# Now with <<- (note that only tabs are removed, not multiple spaces)
S]#	
S]echo
S]cd /home
S]du -s *       |
S]   sort  -nr  |
S]      sed 10q |
S]          while read amount name
S]          do
I]            cat <<- END
H]		Greeting you are one of the top consumer of diskspace
H]		on the system. Your home directory uses $amount disk blocks.
H]		Please clean up unneeded files, as soon as possible.
H]
H]		Thanks
H]		Your friendly sysadmin (now with indent <<-)
E]		END
S]          done
S]# eof

