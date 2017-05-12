## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Compat::v0_11.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: compatibility modules: v0.11.x

package DiaColloDB::Compat::v0_11;
use DiaColloDB::Compat::v0_11::Relation::Cofreqs;
use DiaColloDB::Compat::v0_11::Relation::Unigrams;
#use DiaColloDB::Compat::v0_11::Relation::TDF; ##-- must be loaded on demand!
use Carp;
use strict;

##==============================================================================
## Globals

our @ISA = qw(DiaColloDB::Compat);

##==============================================================================
## Footer
1; ##-- be happy
