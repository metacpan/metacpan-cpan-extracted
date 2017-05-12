## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Compat::v0_08.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: compatibility modules: v0.08.x

package DiaColloDB::Compat::v0_08;
use DiaColloDB::Compat::v0_08::MultiMapFile;
use Carp;
use strict;

##==============================================================================
## Globals

our @ISA = qw(DiaColloDB::Compat);

##==============================================================================
## Footer
1; ##-- be happy
