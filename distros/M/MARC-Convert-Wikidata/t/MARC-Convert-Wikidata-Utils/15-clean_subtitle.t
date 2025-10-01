use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_subtitle);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $input_subtitle = 'Subtitle /';
my $ret = clean_subtitle($input_subtitle);
is($ret, 'Subtitle', "Subtitle '$input_subtitle' after cleanup.");

# Test.
$input_subtitle = 'Subtitle ';
$ret = clean_subtitle($input_subtitle);
is($ret, 'Subtitle', "Subtitle '$input_subtitle' after cleanup.");

# Test.
$input_subtitle = 'Subtitle / ';
$ret = clean_subtitle($input_subtitle);
is($ret, 'Subtitle', "Subtitle '$input_subtitle' after cleanup.");

# Test.
$input_subtitle = 'Subtitle,';
$ret = clean_subtitle($input_subtitle);
is($ret, 'Subtitle', "Subtitle '$input_subtitle' after cleanup.");
