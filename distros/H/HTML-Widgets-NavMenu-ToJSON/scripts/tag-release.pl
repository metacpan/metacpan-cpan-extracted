#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file("./lib/HTML/Widgets/NavMenu/ToJSON.pm")->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my @cmd = (
    "hg", "tag", "-m",
    "Tagging HTML-Widgets-NavMenu-ToJSON as $version",
    "cpan-releases/HTML-Widgets-NavMenu-ToJSON-v$version",
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);
