#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use FindBin;
use JSON::Parse 'json_file_to_perl';
my $p = json_file_to_perl ("$FindBin::Bin/test.json");
ok ($p->{distribution} eq 'Algorithm-NGram');
done_testing ();
