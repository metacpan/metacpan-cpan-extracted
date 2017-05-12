#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my $text = io("-")->slurp;

# Space.
my $sp = ' ' x 4;
my $dq_s_re = qr/[\s\n]*"[^"]+"[\s\n]*(?:#[^\n]*[\s\n]*)?/ms;

$text =~ s/^ok *\([\s\n]*Lingua::IT::Ita2heb::ita_to_heb *\(*(?<ita>[^\)]+)\)[\s\n]*eq[\s\n]*(?<heb>(?:$dq_s_re)(?:\.[\s\n]*$dq_s_re)*),[\s\n]*(?<blurb>'[^']+')[\s\n]*,?[\s\n]*\)[\s\n]*;/
    "# TEST\ncheck_ita_tr(\n${sp}[$+{ita}],\n$sp$+{heb},\n$sp$+{blurb},\n);"
/egms;

print $text;
