#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use MS::CV qw/:MS :MI :MOD is_a regex_for units_for cv_name print_tree/;

require_ok ("MS::CV");

ok( my $a = is_a( MS_EXPECT_VALUE,
    MS_SPECTRUM_IDENTIFICATION_RESULT_DETAILS), "is_a() 1" );
ok( $a, "parent-child true" );
ok( defined (my $b = is_a( MS_EXPECT_VALUE, MS_MS_LEVEL )), "is_a() 2" );
ok( ! $b, "parent-child false" );

ok( my $tryp_re = regex_for(MS_TRYPSIN), "regex_for()" );

my $pep = 'PEPTIDERPEPTIDEKRAPPLE';
my @parts = split $tryp_re, $pep;
ok( scalar(@parts) == 3, "tryptic digest 1" );
ok( $parts[2] eq 'APPLE', "tryptic digest 2" );

my $units = units_for( MS_TIME_ARRAY );
ok( scalar(@{$units}) == 2, "number of term units" );
ok( cv_name( $units->[1] ) eq 'minute', "correct units name" );

# test tree printing
my $tree;
close STDOUT;
open STDOUT, '>', \$tree;
print_tree('MS');
close STDOUT;
my $re = qr/\-\-\-\-\-\-MS\:1001117\s*theoretical mass\s*MS_THEORETICAL_MASS/;
ok( $tree =~ /$re/s, "tree contents check" );

done_testing();
