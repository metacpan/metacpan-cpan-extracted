#!/usr/local/bin/booking-perl
use 5.010;
use strict;
use warnings;
use FindBin qw( $Bin);
use lib "$Bin/lib";

use SequenceFileReader;

my $uri;

# change the protocol to tell which streaming lib to use
#$uri = 'file:///some/local/path/tmp/000000_0';
$uri = 'hdfs:///tmp/000000_0';

# or get it from the command line

$uri = shift || die "No uri specified!";

SequenceFileReader->new->read( $uri );
