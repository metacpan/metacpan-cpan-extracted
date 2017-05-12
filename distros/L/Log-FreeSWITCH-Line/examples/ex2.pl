#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use Log::FreeSWITCH::Line qw(serialize);
use Log::FreeSWITCH::Line::Data;

# Data.
my $record = Log::FreeSWITCH::Line::Data->new(
        'date' => '2014-07-01',
        'file' => 'sofia.c',
        'file_line' => 4045,
        'message' => 'inbound-codec-prefs [PCMA]',
        'time' => '13:37:53.973562',
        'type' => 'DEBUG',
);

# Serialize and print to stdout.
print serialize($record)."\n";

# Output:
# 2014-07-01 13:37:53.973562 [DEBUG] sofia.c:4045 inbound-codec-prefs [PCMA]