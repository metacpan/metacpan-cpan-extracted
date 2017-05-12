use strict;
use warnings;

use Test::More tests => 6;                      # last test to print
use Geo::IATA;
my $iata=Geo::IATA->new("lib/Geo/IATA/iata_sqlite.db");
is($iata->iata2icao("SXF"),'EDDB', "SXF => EDDB iata2icao");
is($iata->icao2iata("EDDB"),'SXF', "EDDB => SXF icao2iata");
like($iata->icao2airport("EDDB"),qr{Berlin}, "EDDB => Schoenefeld");
like($iata->iata2airport("SXF"),qr{Berlin}, "SXF => Schoenefeld");
like($iata->iata2location("SXF"),qr{Berlin}, "SXF => Berlin");
like($iata->icao2location("EDDB"),qr{Berlin}, "EDDB => Berlin");

