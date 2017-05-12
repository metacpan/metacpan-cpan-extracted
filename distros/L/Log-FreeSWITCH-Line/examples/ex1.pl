#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use Data::Printer;
use Log::FreeSWITCH::Line qw(parse);

# Log record.
my $data = '2014-07-01 13:37:53.973562 [DEBUG] sofia.c:4045 inbound-codec-prefs [PCMA]';

# Parse.
my $data_o = parse($data);

# Dump.
p $data_o;

# Output:
# Log::FreeSWITCH::Line::Data  {
#     Parents       Mo::Object
#     public methods (0)
#     private methods (1) : _datetime
#     internals: {
#         date        "2014-07-01",
#         file        "sofia.c",
#         file_line   4045,
#         message     "inbound-codec-prefs [PCMA]",
#         raw         "2014-07-01 13:37:53.973562 [DEBUG] sofia.c:4045 inbound-codec-prefs [PCMA]",
#         time        "13:37:53.973562",
#         type        "DEBUG"
#     }
# }