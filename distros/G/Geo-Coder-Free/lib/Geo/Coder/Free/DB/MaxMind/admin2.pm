package Geo::Coder::Free::DB::MaxMind::admin2;

use strict;
use warnings;

=head1 NAME

Geo::Coder::Free::DB::MaxMind::admin2 - driver for http://download.geonames.org/export/dump/admin2Codes.txt

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

# It contains admin areas drilled down from the admin1 database such as US counties
# Note that GB has counties
# A typical line is:
#	GB.ENG.G5	Kent	Kent	3333158
# So a look up of 'Sittingbourne' with a Region set to 'G5' in the cities database will give:
#	gb,sittingbourne,Sittingbourne,G5,41148,51.333333,.75

use Geo::Coder::Free::DB::MaxMind::admin;

our @ISA = ('Geo::Coder::Free::DB::MaxMind::admin');

1;
