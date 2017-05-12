#!/usr/bin/perl -T
#
# Test basic operations of FTN::Log

use Test::More tests => 1;
use FTN::Log();

use strict;
use warnings;

BEGIN {

    my $log = 't/TEST.LOG';
    my $id = 'TEST';
    my $text = 'Logging to TEST.LOG file was successful.';

    ok( FTN::Log::logging( $log, $id, $text ) );

}

