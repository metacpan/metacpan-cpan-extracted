#!/usr/bin/perl

# $Id$

use strict;
use warnings;

use Test::More tests => 4;

use File::Path qw(rmtree);

# TEST
use_ok('File::Find::Object', "Can use main File::Find::Object");

mkdir('t/dir');
mkdir('t/dir/a');
mkdir('t/dir/b');

open(my $h, ">", 't/dir/file');
close($h);

# symlink does not exists everywhere (windows)
# if it failed, this does not matter
eval {
    symlink('.', 't/dir/link');
};
my $symlink_created = ($@ eq "");

my (@res1, @res2);
my $tree = File::Find::Object->new(
    {
        callback => sub {
            push(@res1, $_[0]);
        },
        followlink => 1,
    },
    't/dir'
);

my @warnings;

local $SIG{__WARN__} = sub { my $w = shift; push @warnings, $w; };

# TEST
ok($tree, "Can get tree object");

while (my $r = $tree->next()) {
    push(@res2, $r);
}

# TEST
ok(scalar(@res1) == scalar(@res2), "Get same result from callback and next");

# TEST
if ($symlink_created)
{
    like($warnings[0], qr{\AAvoid loop (\S+) => \1\S+?link\r?\n?\z},
    "Avoid loop warning");
}
else
{
    pass("No symlink.");
}

# Cleanup
rmtree('t/dir', 0, 1);
