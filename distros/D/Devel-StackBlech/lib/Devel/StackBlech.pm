package Devel::StackBlech;

use strict;
use warnings;
use DynaLoader ();
use Sub::Exporter -setup => { exports => [qw[ dumpStacks dumpStack ]] };

sub dl_load_flags { 0x01 }

our $VERSION = '0.06';

our @ISA = 'DynaLoader';
DynaLoader::bootstrap( __PACKAGE__ );

q[With this tiny hammer of Doom, I hereby commence the festivities!];
