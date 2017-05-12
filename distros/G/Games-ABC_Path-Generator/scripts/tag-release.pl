#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file('lib/Games/ABC_Path/Generator.pm')->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my $mini_repos_base = 'https://svn.berlios.de/svnroot/repos/fc-solve/abc-path';

my @cmd = (
    "hg", "tag", "-m",
    "Tagging the Games-ABC_Path-Generator release as $version",
    "Games-ABC_Path-Generator-$version"
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);

