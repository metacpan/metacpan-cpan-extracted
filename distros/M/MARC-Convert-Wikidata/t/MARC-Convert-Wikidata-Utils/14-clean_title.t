use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_title);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $input_title = 'Title :';
my $ret = clean_title($input_title);
is($ret, 'Title', "Title '$input_title' after cleanup.");

# Test.
$input_title = 'Title /';
$ret = clean_title($input_title);
is($ret, 'Title', "Title '$input_title' after cleanup.");

# Test.
$input_title = 'Title.';
$ret = clean_title($input_title);
is($ret, 'Title', "Title '$input_title' after cleanup.");
