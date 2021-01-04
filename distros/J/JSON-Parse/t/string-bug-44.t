#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use JSON::Parse 'read_json';
my $in = read_json ("$Bin/string-bug-44.json");
cmp_ok (length ($in->{x}), '==', 4080, "Length as expected");
done_testing ();
