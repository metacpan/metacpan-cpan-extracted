use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publication_date);
use Test::More 'tests' => 17;
use Test::NoWarnings;

# Test.
my $input_publication_date = '2010';
my ($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, 2010, "Publication date '$input_publication_date' after cleanup.");
is($ret_option, undef, "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = 'foo';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, undef, "Publication date '$input_publication_date' after cleanup.");
is($ret_option, undef, "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = 'c2020';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, 2020, "Publication date '$input_publication_date' after cleanup.");
is($ret_option, 'circa', "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = '2020?';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, 2020, "Publication date '$input_publication_date' after cleanup.");
is($ret_option, 'circa', "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = '[2020?]';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, 2020, "Publication date '$input_publication_date' after cleanup.");
is($ret_option, 'circa', "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = '1950-1960';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, '1950-1960', "Publication date '$input_publication_date' after cleanup.");
is($ret_option, undef, "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = '1950-';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, '1950-', "Publication date '$input_publication_date' after cleanup.");
is($ret_option, undef, "Publication date '$input_publication_date' option.");

# Test.
$input_publication_date = '1994-[2002]';
($ret, $ret_option) = clean_publication_date($input_publication_date);
is($ret, '1994-2002', "Publication date '$input_publication_date' after cleanup.");
is($ret_option, undef, "Publication date '$input_publication_date' option.");
