#!/usr/bin/perl

use strict;
use warnings;

use Debian::DEP12;
use Test::More tests => 1;

my $entry;
my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0]; $warning =~ s/\n$// };

my $input = <<END;
Bug-Database: https://github.com/merkys/Debian-DEP12/issues
Bug-Submit: https://github.com/merkys/Debian-DEP12/issues
Reference:
- Year: 2021
- DOI: search for my surname and year
END

$entry = Debian::DEP12->new( $input );
is( $entry->to_YAML, $input );
