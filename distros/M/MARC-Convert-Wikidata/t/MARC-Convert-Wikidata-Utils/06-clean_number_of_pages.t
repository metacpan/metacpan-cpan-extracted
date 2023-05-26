use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_number_of_pages);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $input_number_of_pages = '575 s. ;';
my $ret = clean_number_of_pages($input_number_of_pages);
is($ret, 575, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
$input_number_of_pages = '219 s. :';
$ret = clean_number_of_pages($input_number_of_pages);
is($ret, 219, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
$input_number_of_pages = '175 s.';
$ret = clean_number_of_pages($input_number_of_pages);
is($ret, 175, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
$input_number_of_pages = '75 stran :';
$ret = clean_number_of_pages($input_number_of_pages);
is($ret, 75, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
$input_number_of_pages = '[39] s. :';
$ret = clean_number_of_pages($input_number_of_pages);
is($ret, 39, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
$input_number_of_pages = '85 s., [6] l. barev. obr. příl. :';
$ret = clean_number_of_pages($input_number_of_pages);
is($ret, 85, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
# TODO Implement
## $input_number_of_pages = '65 nečíslovaných stran :';
## $ret = clean_number_of_pages($input_number_of_pages);
## is($ret, 65, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
# TODO Implement
## $input_number_of_pages = '85 s., [6] l. barev. obr. příl. :';
## $ret = clean_number_of_pages($input_number_of_pages);
## is($ret, 85, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
# TODO Implement
## $input_number_of_pages = '30 - [III] s. ;';
## $ret = clean_number_of_pages($input_number_of_pages);
## is($ret, 30, "Number of pages '$input_number_of_pages' after cleanup.");

# Test.
# TODO Check warning.
## $input_number_of_pages = '^^^svazků (199; 167; 177 stran) :';
## $ret = clean_number_of_pages($input_number_of_pages);
## is($ret, undef, "Number of pages '$input_number_of_pages' after cleanup.");
