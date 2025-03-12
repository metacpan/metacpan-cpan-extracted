#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Copy;
use File::Path qw(remove_tree);
use File::Spec;
use File::Temp qw(tempdir);

use EBook::Gutenberg;

# The tests here aren't very thorough. Only meta and search are tested, as they
# do not require a network connection. The output is also not tested for
# correctness, we only check to make sure they don't die.

my $CATPATH = File::Spec->catfile(qw/t data pg_catalog.csv/);
my $TMP_DATA = tempdir(CLEANUP => 1);

my @COMMON_OPTS = ('-d', $TMP_DATA);

sub newgut {

    my @args = @_;

    local @ARGV = (@COMMON_OPTS, @args);

    return EBook::Gutenberg->init;

}

copy($CATPATH, $TMP_DATA)
    or die "Failed to copy $CATPATH to $TMP_DATA: $!\n";

my $gut;

$gut = newgut('search', 1);
isa_ok($gut, 'EBook::Gutenberg');
ok($gut->run, "search w/ ID ok");

$gut = newgut('search', 'United States');
ok($gut->run, "search w/ string ok");

$gut = newgut('search', '/United.States/');
ok($gut->run, "search w/ regex ok");

$gut = newgut('search', '--author', 'Herman Melville');
ok($gut->run, "search w/ --author ok");

$gut = newgut('search', '--subject', 'United States');
ok($gut->run, "search w/ --subject ok");

$gut = newgut('search', '--language', 'en');
ok($gut->run, "search w/ --language ok");

$gut = newgut('search', '--shelf', 'Politics');
ok($gut->run, "search w/ --shelf ok");

for my $i (1 .. 20) {
    $gut = newgut('meta', $i);
    ok($gut->run, "meta w/ book #$i ok");

    $gut = newgut('meta', '--json', $i);
    ok($gut->run, "meta --json w/ book #$i ok");
}

done_testing;

END {
    remove_tree($TMP_DATA, { safe => 1 }) if -d $TMP_DATA;
}

# vim: expandtab shiftwidth=4
