#! /usr/bin/perl
#
# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Mail::Alias::Reader;

my $reader = Mail::Alias::Reader->open(
    'file' => $ARGV[0],
    'mode' => 'aliases'
);

while (my ($name, $destinations) = $reader->read) {
    printf("%s: %s\n", $name, join(', ', map { $_->to_string } @{$destinations}));
}
