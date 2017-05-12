#!/usr/bin/perl 
#
# testing starter for development purposes
# starter for regular users is in bin/kephra
#
use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
    #chdir 'base';
}

require Kephra;

$Kephra::STANDALONE = 'dev';
Kephra->start;

#use FindBin;
#$ENV{KEPHRA_DEV_START} = 1;
#use File::Spec::Functions qw(catfile);
#my $lib = catfile( $FindBin::Bin, 'lib' );
#my $exe = catfile( $FindBin::Bin, 'bin', 'kephra' );
#system "$^X @ARGV -I$lib $exe";
