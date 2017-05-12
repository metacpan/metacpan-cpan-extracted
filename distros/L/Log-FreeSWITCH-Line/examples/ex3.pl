#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use Log::FreeSWITCH::Line::Data;

# Object.
my $data_o = Log::FreeSWITCH::Line::Data->new(
        'date' => '2014-07-01',
        'file' => 'sofia.c',
        'file_line' => 4045,
        'message' => 'inbound-codec-prefs [PCMA]',
        'time' => '13:37:53.973562',
        'type' => 'DEBUG',
);

# Print out informations.
print 'Date: '.$data_o->date."\n";

# Output:
# Date: 2014-07-01