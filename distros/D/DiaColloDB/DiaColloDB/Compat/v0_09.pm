## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Compat::v0_09.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: compatibility modules: v0.09.x

package DiaColloDB::Compat::v0_09;
use DiaColloDB::Compat::v0_09::Relation;
use DiaColloDB::Compat::v0_09::Relation::Cofreqs;
use DiaColloDB::Compat::v0_09::Relation::Unigrams;
use DiaColloDB::Compat::v0_09::DiaColloDB;
use Carp;
use strict;

##==============================================================================
## Globals

our @ISA = qw(DiaColloDB::Compat);

##==============================================================================
## Footer
1; ##-- be happy
