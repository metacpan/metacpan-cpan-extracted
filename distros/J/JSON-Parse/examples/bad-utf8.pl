#!/home/ben/software/install/bin/perl
use warnings;
use strict;
no utf8;
use JSON::Parse 'assert_valid_json';

# Error in first byte:

my $bad_utf8_1 = chr (hex ("81"));
eval { assert_valid_json ("[\"$bad_utf8_1\"]"); };
print "$@\n";

# Error in third byte:

my $bad_utf8_2 = chr (hex ('e2')) . chr (hex ('9C')) . 'b';
eval { assert_valid_json ("[\"$bad_utf8_2\"]"); };
print "$@\n";
