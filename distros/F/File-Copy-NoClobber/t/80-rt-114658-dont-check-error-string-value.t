#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Test::Warnings;

use t::lib::TestUtils;
use Fcntl;
use File::Basename;

use File::Copy::NoClobber;

# some common other locales
my @locales = map $_.".UTF-8",
    qw(
          zh_CN ru_RU fr_FR es_ES de_DE pt_BR it_IT ja_JP
  );

for my $l (@locales) {

    local $ENV{LC_MESSAGES} = $l;

    my($fh,$fn) = testfile;
    my $d = testdir;

    # verify that we get something weird in the error message
    sysopen my $fh2, $fn, O_EXCL|O_CREAT;

  SKIP: {

        skip "$l: Skipping - error message not different enough", 1
            if $l =~ /File exists/i;

        my $new1 = copy( $fn, $d );
        my $new2 = copy( $fn, $d );

        isnt basename( $new1 ), basename( $new2 ),
            "works under $l";

    }

}

done_testing;
