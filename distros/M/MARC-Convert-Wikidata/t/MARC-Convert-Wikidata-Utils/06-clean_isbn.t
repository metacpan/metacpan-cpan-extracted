use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_isbn);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $input_isbn = '80-7011-077-5 :';
my $ret = clean_isbn($input_isbn);
is($ret, '80-7011-077-5', "ISBN '$input_isbn' after cleanup (80-7011-077-5).");
