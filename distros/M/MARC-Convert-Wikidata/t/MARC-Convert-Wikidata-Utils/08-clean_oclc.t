use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_oclc);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $input_oclc = '(OCoLC)12345';
my $ret = clean_oclc($input_oclc);
is($ret, '12345', "OCLC control number '$input_oclc' after cleanup.");
