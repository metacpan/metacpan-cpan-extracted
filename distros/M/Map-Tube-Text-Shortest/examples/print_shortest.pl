#!/usr/bin/env perl

use strict;
use warnings;

use English;
use Encode qw(decode_utf8 encode_utf8);
use Error::Pure qw(err);
use Map::Tube::Text::Shortest;

# Arguments.
if (@ARGV < 3) {
        print STDERR "Usage: $0 metro from to\n";
        exit 1;
}
my $metro = $ARGV[0];
my $from = decode_utf8($ARGV[1]);
my $to = decode_utf8($ARGV[2]);

# Load metro object.
my $class = 'Map::Tube::'.$metro;
eval "require $class;";
if ($EVAL_ERROR) {
        err "Cannot load '$class' class.",
                'Error', $EVAL_ERROR;
}

# Metro object. 
my $tube = eval "$class->new";
if ($EVAL_ERROR) {
        err "Cannot create object for '$class' class.",
                'Error', $EVAL_ERROR;
}

# Table object.
my $table = Map::Tube::Text::Shortest->new(
        'tube' => $tube,
);

# Print out.
print encode_utf8(scalar $table->print($from, $to))."\n";

# Output without arguments like:
# Usage: /tmp/O0s_2qtAuB metro from to

# Output with 'Budapest', 'Fővám tér', 'Opera' arguments like:
# 
# From Fővám tér to Opera
# =======================
# 
# -- Route 1 (cost ?) ----------
# [   M4 ] Fővám tér
# [   M3 ] Kálvin tér
# [ * M4 ] Kálvin tér
# [   M3 ] Ferenciek tere
# [   M1 ] Deák Ferenc tér
# [ * M2 ] Deák Ferenc tér
# [   M3 ] Deák Ferenc tér
# [   M1 ] Bajcsy-Zsilinszky út
# [   M1 ] Opera
# 
# M1  Linia M1
# M3  Linia M3
# M2  Linia M2
# M4  Linia M4
# 
# *: Transfer to other line
# +: Transfer to other station
# 