#!perl

use strict;
use warnings;

use Test::More;
use IO::All;

my $name = $ENV{IO_ALL_SECURFTP_NAME} || "securftp://localhost/path/to/file.txt";
my $io = io($name);

isa_ok($io, "IO::All::Securftp");

SKIP: {
    $ENV{IO_ALL_SECURFTP_NAME} or skip('Transfer test needs reasonable $ENV{IO_ALL_SECURFTP_NAME}', 1);

    my $cnt = join("", map { chr (rand(256-32)+32) } (0..(1<<16)));
    io($ENV{IO_ALL_SECURFTP_NAME})->print($cnt);
    my $cmp = $io->slurp();
    is($cnt, $cmp, "read back from randomly written data");
}

done_testing();
