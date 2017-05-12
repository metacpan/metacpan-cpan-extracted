#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 9;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# Test an PERL ingress with an inline-comment 
# (despite this is not shell script, its similar enough and should pass)

while (<DATA>) {
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
}


__DATA__
S]#!/usr/bin/perl
S]use warnings;
S]use strict;
I]my $string = <<_END_OF_TEXT ;   # Not ok for perl: '<< _END_OF_TEXT'
H]Some text
H]Split into multiples lines
H]Is clearly defined
E]_END_OF_TEXT
S]print $string;



