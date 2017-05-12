#!/usr/bin/env perl
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
# Tests that no backslashes found in the README.mkdn
#
# Pod::Markdown ~< v1.322 was escaping the code contained in the headers
# with backslashes. If this test fails then you are in the need to upgrade
# your Pod::Markdown module.
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Most;    # Continues till done_testing()

# Dies more nicely
use Carp;

# Loads main app module
# use Your::Module;

# Catches exceptions
use Test::Exception;

# Reads file into a scalar variable
eval "use Perl6::Slurp";    ## no critic
plan skip_all => "Perl6::Slurp required for testing" if $@;

### CONSTANTS ###
#
# Makes constants possible
# use Const::Fast;

# (Enter constant description here)
# const my $SOME_CONST => 1;

### MAIN ###
# Require   :   Test::Most, Test::Exception, Perl6::Slurp, Carp
#
# Check for file existence and readability
ok( ( -f 'README.mkdn' ) => 'README.mkdn exists' );
ok( ( -r 'README.mkdn' ) => 'README.mkdn is readable' );

# Read file into the array by paragraphs
my @mkdn;
lives_and {
    carp('No entires was read from README.mkdn!')
        unless @mkdn
        = Perl6::Slurp::slurp(
        'README.mkdn' => { 'irs' => qr/\r*\n\s*\n\r*/ } );
}
'Reading README.mkdn';

# Grep markdown for headers and code
ok( @mkdn = grep( /^#+\s/, @mkdn ) => 'README.mkdn contains headers' );
ok( @mkdn = grep( /`/, @mkdn ) =>
        'README.mkdn contains headers with the code enclosed' );

# Fetch code elements from headers
my @codes;
foreach my $header (@mkdn) {
    while ( $header =~ s/`([^`]*)`// ) {
        if ( length($1) ) { push @codes, $1 }
    }
}

# Check codes for backslashes
ok( +@codes => "Found " . @codes . " entries of code in the headers" );
ok( not( grep /\\/, @codes ) => "No backslashes in the headers' codes" );

# Continues till this point
done_testing();
