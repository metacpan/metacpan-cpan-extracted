#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Leader::L10N;
use Unicode::UTF8 qw(encode_utf8);

if (@ARGV < 1) {
        print STDERR "Usage: $0 lang_code\n";
        exit 1;
}
my $lang_code = $ARGV[0];

my $lh = MARC::Leader::L10N->get_handle($lang_code);

print encode_utf8($lh->maketext('Bibliographic level'))."\n";

# Output for cs.
# Bibliografická úroveň

# Output for en.
# Bibliographic level