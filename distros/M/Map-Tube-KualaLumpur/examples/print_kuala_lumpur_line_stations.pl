#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::KualaLumpur;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 line\n";
        exit 1;
}
my $line = $ARGV[0];

# Object.
my $obj = Map::Tube::KualaLumpur->new;

# Get stations for line.
my $stations_ar = $obj->get_stations($line);

# Print out.
map { print encode_utf8($_->name)."\n"; } @{$stations_ar};

# Output:
# Usage: __PROG__ line

# Output with 'foo' argument.
# Map::Tube::get_stations(): ERROR: Invalid Line Name [foo]. (status: 105) file __PROG__ on line __LINE__

# Output with 'Ampang Line' argument.
# Sentul Timur
# Sentul
# Titiwangsa
# PWTC
# Sultan Ismail
# Bandaraya
# Masjid Jamek
# Plaza Rakyat
# Hang Tuah
# Pudu
# Chan Sow Lin
# Miharja
# Maluri
# Pandan Jaya
# Pandan Indah
# Cempaka
# Cahaya
# Ampang