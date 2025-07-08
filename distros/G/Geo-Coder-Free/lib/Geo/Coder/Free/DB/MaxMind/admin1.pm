package Geo::Coder::Free::DB::MaxMind::admin1;

use strict;
use warnings;

=head1 NAME

Geo::Coder::Free::DB::MaxMind::admin1 - driver for http://download.geonames.org/export/dump/admin1CodesASCII.txt

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

# It contains admin areas such as counties, states and provinces
# Note that GB has England, Scotland and Wales at this level, not the counties
# A typical line is:
#	US.MD	Maryland	Maryland	4361885
# So a look up of 'Maryland' will get the code 'US.MD'

use Geo::Coder::Free::DB::MaxMind::admin;

our @ISA = ('Geo::Coder::Free::DB::MaxMind::admin');

1;
