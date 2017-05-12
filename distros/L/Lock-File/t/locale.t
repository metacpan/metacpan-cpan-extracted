#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Lock::File qw(lockfile);

use autodie qw(fork);

use File::Path qw(remove_tree);
remove_tree('tfiles');
mkdir 'tfiles';

$ENV{LANG} = 'ru_RU.utf8';
if (!fork) {
    my $lock = lockfile("./tfiles/lock");
    sleep 2;
    exit(0);
} else {
    sleep 1;
    ok((not defined lockfile("./tfiles/lock", {blocking => 0})), 'returns undef when already locked');
}

done_testing;
