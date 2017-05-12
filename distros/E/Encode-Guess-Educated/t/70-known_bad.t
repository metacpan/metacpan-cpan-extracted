#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 0.94;

BEGIN {
    chdir 't' if -d 't';
    use lib qw(. ../lib);
    require "./test-common.pl";
}


my @common = qw(
    iso-8859-1
    iso-8859-2
    iso-8859-3
    iso-8859-5
    iso-8859-5
    iso-8859-7
    iso-8859-15
    cp1250
    cp1251
    cp1252
    MacRoman
);

use Encode qw(:fallbacks encode decode);

BEGIN {
    use_ok("Encode::Guess::Educated")
        || BAIL_OUT("can't run any tests without the module available");
}

my @data_files = glob("data/bad/*.utf8");
cmp_ok(scalar @data_files, ">", 0, "glob bad data files")
    || BAIL_OUT("can't find any sample utf8 files");

my $obj = Encode::Guess::Educated->new();
my @choices = Encode::Guess::Educated->get_suspects();

TODO: { 

    local $TODO = "These files are known to deceive the guesser.";

    for my $file (@data_files) {
	test_file($obj,$file, @common);
    } 

}

done_testing();
