#! perl
use utf8;
use warnings;
use strict;

use Data::Dumper;
use Document::OOXML;

if (@ARGV != 1) {
    warn "Usage: $0 input.docx"
}

my $doc = Document::OOXML->read_document($ARGV[0]);

# Ensure all "matching" text is merged into single runs, so find/replace
# can actually find all the words.
$doc->merge_runs();

my $words = $doc->extract_words();

local $Data::Dumper::Indent = 1;
local $Data::Dumper::Terse = 1;
print Dumper($words);
