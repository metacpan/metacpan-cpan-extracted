#!/usr/bin/perl
use warnings;
use strict;

use File::ArchivableFormats;
use Data::Dumper;

my $af   = File::ArchivableFormats->new();
my $file = 'xt/pod.t';

my $result = $af->identify_from_path($file);
print Dumper $result;

# $result is something like this
# {
#     'DANS' => {
#         'types' => [
#             'Plain text (Unicode)',
#             'Plain text (Non-Unicode)',
#             'Statistical data (data (.csv) + setup)',
#             'Raspter GIS (ASCII GRID)',
#             'Raspter GIS (ASCII GRID)'
#         ],
#         'allowed_extensions' => ['.asc', '.txt'],
#         'archivable'         => 1
#     },
#     'mime_type' => 'text/plain'
# };
