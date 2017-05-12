#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 0.94;

BEGIN {
    chdir 't' if -d 't';
    use lib qw(. ../lib);
    require "./test-common.pl";
}

use Encode qw(:fallbacks encode decode);

BEGIN {
    use_ok("Encode::Guess::Educated")
        || BAIL_OUT("can't run any tests without the module available");
}

my @data_files = glob("data/cp1252/*.cp1252");

my $obj = Encode::Guess::Educated->new();
$obj->add_suspects("cp1252");

if ( cmp_ok(scalar @data_files, ">", 0, "glob macroman files")) { 

    for my $file (@data_files) {

	my($guess,$reason) = $obj->guess_file_encoding($file);

	is($guess, 'cp1252', "make sure $file guesses cp1252")
	    || diag("failure details:\n$reason\n");
    }

}

done_testing();

