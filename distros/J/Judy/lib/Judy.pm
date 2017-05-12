package Judy;

use strict;
use warnings;
use vars qw( $VERSION @ISA );

$VERSION = '0.41';

require Alien::Judy;
my $av_version = Alien::Judy->VERSION;
if ( $av_version < 0.18 ) {
    die "Alien::Judy version 0.18 required--this is only version $av_version";
}
Alien::Judy::dl_load_libjudy();

# Now load the Perl wrapper over libJudy
local @ISA = 'DynaLoader';
__PACKAGE__->bootstrap;

require Sub::Exporter;
Sub::Exporter->import(
    -setup => {
        exports => [qw[ PJERR JLAP_INVALID ]]
    }
);

# Load the OO interfaces.
#
require Judy::_obj;

# Load the tie interface.
# 
require Judy::_tie;
Judy::_tie->import;

# Load the functional interfaces.
require Judy::Mem::_impl;
require Judy::1::_impl;
require Judy::L::_impl;
require Judy::SL::_impl;
require Judy::HS::_impl;

1;
