# This does only one job, exporting the functions below.

package JSON::Tokenize;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
use JSON::Parse;
our @EXPORT_OK = qw/tokenize_json tokenize_start tokenize_next tokenize_start tokenize_end tokenize_type tokenize_child/;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
use Carp;
our $VERSION = '0.49';
1;
