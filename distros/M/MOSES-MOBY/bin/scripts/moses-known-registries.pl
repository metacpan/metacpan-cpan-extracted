#!/usr/bin/perl -w
#
# List of known BioMoby registries.
#
# $Id: moses-known-registries.pl,v 1.3 2008/02/21 00:12:55 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

use MOSES::MOBY::Cache::Registries;
use Data::Dumper;
use strict;

sub say { print @_, "\n"; }

say join (", ", MOSES::MOBY::Cache::Registries->list);
say (Data::Dumper->Dump ( [ MOSES::MOBY::Cache::Registries->all ], ['Registries']));


__END__

