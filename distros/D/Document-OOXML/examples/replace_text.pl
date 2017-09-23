#! perl
use utf8;
use warnings;
use strict;

use Document::OOXML;

if (@ARGV != 4) {
    warn "Usage: $0 input.docx output.docx search replacement"
}

my $doc = Document::OOXML->read_document($ARGV[0]);

# Ensure all "matching" text is merged into single runs, so find/replace
# can actually find all the words.
$doc->merge_runs();

# Do the actual replacing
$doc->replace_text($ARGV[2], $ARGV[3]);

$doc->save_to_file($ARGV[1]);