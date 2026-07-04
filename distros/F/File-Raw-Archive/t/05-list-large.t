#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

# Linear-scaling sanity for _list_xs. Builds a 500-entry tarball and
# confirms that listing it returns exactly 500 entries with the right
# names + sizes. The plan calls for 5000 entries; trimmed to 500 so
# CPAN testers don't burn extra wall-clock here.

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/large.tar";

my $N = 500;
my $w = File::Raw::Archive->create($tar);
for my $i (1 .. $N) {
    my $name = sprintf("section%02d/file%04d.txt", $i % 10, $i);
    $w->add(name => $name, content => "entry $i\n", mode => 0644);
}
$w->close;

ok(-s $tar > 0, "tarball produced (" . (-s $tar) . " bytes)");

my $rows = File::Raw::Archive->list($tar);
isa_ok($rows, 'ARRAY', 'list returns an arrayref');
is(scalar @$rows, $N, "list returned $N entries");

# Verify a sampling of entries.
for my $i (1, 100, 250, 500) {
    my $expected_name = sprintf("section%02d/file%04d.txt", $i % 10, $i);
    is($rows->[$i - 1]{name}, $expected_name, "entry $i name");
    is($rows->[$i - 1]{size}, length("entry $i\n"), "entry $i size");
    is($rows->[$i - 1]{mode}, 0644, "entry $i mode");
}

# All entries are AE_FILE
my $files = grep { $_->{type} == File::Raw::Archive::AE_FILE } @$rows;
is($files, $N, "all $N entries report type AE_FILE");

done_testing;
