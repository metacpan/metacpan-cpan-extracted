#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use JSON::Parse 'json_file_to_perl';
my $in = json_file_to_perl ("$Bin/string-bug-44.json");
cmp_ok (length ($in->{x}), '==', 4080, "Length as expected");
done_testing ();
