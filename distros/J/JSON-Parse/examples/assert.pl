#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse 'assert_valid_json';
eval {
    assert_valid_json ('["xyz":"b"]');
};
if ($@) {
    print "Your JSON was invalid: $@\n";
}
# Prints "Unexpected character ':' parsing array"
