#! perl
use utf8;
use warnings;
use strict;

use Document::OOXML;

if (@ARGV != 3) {
    warn "Usage: $0 input.docx output.docx word_to_style"
}

my $doc = Document::OOXML->read_document($ARGV[0]);

# Ensure all "matching" text is merged into single runs, so find/replace
# can actually find all the words.
$doc->merge_runs();

my $words = $doc->style_text(qr/\Q$ARGV[2]\E/, bold => 1, italic => 1, color => '00FFFF');

$doc->save_to_file($ARGV[1]);
