#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::EN::PluralToSingular 'to_singular';

print to_singular ('knives');
# "knife"

use Lingua::EN::PluralToSingular 'is_plural';

# Returns 1
is_plural ('sheep');
# Returns 0
is_plural ('dog');
# Returns 1
is_plural ('dogs');
# Returns 0
is_plural ('cannabis');
