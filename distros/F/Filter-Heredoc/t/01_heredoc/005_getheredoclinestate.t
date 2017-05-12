#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 18;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# This is just egress line bug validation test (see comment below)

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/bin/bash
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
S] done    # this single q{ } before "done" caused egress to fail to switch state to S.

