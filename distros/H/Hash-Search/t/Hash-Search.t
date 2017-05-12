# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Hash-Search.t'

#########################

use Test::More tests => 15;
BEGIN { use_ok('Hash::Search') };

#########################

my $hs = new Hash::Search;

# Preform tests to see if the variables are the expected values when 
# Hash::Search is loaded.

is($hs->hash_search_resultcount, "0", "Result count is zero on module load");
is($hs->hash_search_resultdata, 0, "Result data hash is empty on module load");

# Check to see if the hash_search and hash_search_resultcount return
# the correct results (thus return the correct number).

%hashdata = (
      "one" => "orange", "two" => "banana", "three" => "apple",
      "four" => "pear", "five" => "pineapple"
);

# Search 1: Return a value and have three results while checking if
# the results themselves are correct.

is ($hs->hash_search("e\$", %hashdata), 1, "Search 1: Return true for search");

isnt ($hs->hash_search_resultdata, 0, "Search 1: Return a value");
is ($hs->hash_search_resultcount, 3, "Search 1: Return the number 3");

%hashfinal = $hs->hash_search_resultdata;

ok(
	$hashfinal{'one'} eq "orange" &&
	$hashfinal{'three'} eq "apple" &&
	$hashfinal{'five'} eq "pineapple", "Search 1: Search results match"
);

# Search 2: Return a value and have one result.

$hs->hash_search("r\$", %hashdata);

isnt ($hs->hash_search_resultdata, 0, "Search 2: Return a value");
is ($hs->hash_search_resultcount, 1, "Search 2: Return the number 1");

# Search 3: Return an empty hash with no results.

$hs->hash_search("x\$", %hashdata);

is ($hs->hash_search_resultdata, 0, "Search 3: Return a empty hash");
is ($hs->hash_search_resultcount, 0, "Search 3: Return the number 0");

# Search 4: Alternative search using specific letters.

$hs->hash_search("[f]", %hashdata);

isnt ($hs->hash_search_resultdata, 0, "Search 4: Return a value");
is ($hs->hash_search_resultcount, 2, "Search 4: Return the number 2");

# Search 5: Alternative search using a character at the beginning.

$hs->hash_search("^o", %hashdata);

isnt ($hs->hash_search_resultdata, 0, "Search 5: Return a value");
is ($hs->hash_search_resultcount, 1, "Search 5: Return the number 1");
