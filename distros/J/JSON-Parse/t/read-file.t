#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use JSON::Parse qw!read_json json_file_to_perl!;
my $p = json_file_to_perl ("$Bin/test.json");
ok ($p->{distribution} eq 'Algorithm-NGram');
my $q = read_json ("$Bin/test.json");
ok ($q->{distribution} eq 'Algorithm-NGram');
done_testing ();
