#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 0.94;
use Encode qw(:fallbacks encode decode);

BEGIN {
    chdir 't' if -d 't';
    use lib qw(. ../lib);
    require "./test-common.pl";
}

BEGIN {
    use_ok("Encode::Guess::Educated")
        || BAIL_OUT("can't run any tests without the module available");
}

my @data_files = glob("data/utfs/*.utf*");
cmp_ok(scalar @data_files, ">", 0, "glob utfs data files")
    || BAIL_OUT("can't find any utfs/utf* files");

my $obj = Encode::Guess::Educated->new();

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

for my $file (@data_files) {
    my($ext) = $file =~ /\.(utf(?:8|16|32))$/;
    die "wrong extension in $file" unless $ext;

    my($guess,$reason) = $obj->guess_file_encoding($file);

    $guess = lc($guess);
    $guess =~ s/-//;

    is($guess, $ext, "make sure $file guesses $ext");
}

done_testing();
