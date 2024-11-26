use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_issn);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $input_issn = '0585-5675 ;';
my $ret = clean_issn($input_issn);
is($ret, '0585-5675', "ISSN '$input_issn' after cleanup.");
