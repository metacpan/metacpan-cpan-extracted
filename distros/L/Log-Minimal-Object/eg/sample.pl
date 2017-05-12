#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Minimal::Object;

my $logger = Log::Minimal::Object->new(
    color => 1,
);
$logger->infof("This is info!");
$logger->warnf("This is warn!");
