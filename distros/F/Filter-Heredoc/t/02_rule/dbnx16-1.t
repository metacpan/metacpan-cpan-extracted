#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 9;
use Filter::Heredoc qw ( hd_getstate);
use Filter::Heredoc::Rule qw ( hd_syntax );

my %state;
my ( $state, $line );

# Bug DBNX#16-1: common POD lines and perl cause false ingress

hd_syntax ( 'pod' );  # enable the pod rule

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'get_heredoc_linestate()');
}


__DATA__
S]=over
S]
S]=item C<< Error message here, perhaps with %s placeholders >>
S]
S][Description of error here]
S]
S]=item C<< Another error message here >>
S]
S][Description of error here]



