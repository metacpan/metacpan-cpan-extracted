#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Field008::L10N;
use Unicode::UTF8 qw(encode_utf8);

if (@ARGV < 1) {
        print STDERR "Usage: $0 lang_code\n";
        exit 1;
}
my $lang_code = $ARGV[0];

my $lh = MARC::Field008::L10N->get_handle($lang_code);

print encode_utf8($lh->maketext('Date entered on file'))."\n";

# Output for cs.
# Datum uložení do souboru

# Output for en.
# Date entered on file