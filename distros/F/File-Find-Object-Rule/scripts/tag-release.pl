#!/usr/bin/env perl

use strict;
use warnings;

use IO::All qw/ io /;

my ($version) =
    ( map { m{\Aversion * = *(\S+)} ? ($1) : () }
        io->file("./dist.ini")->getlines() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my @cmd = (
    "git", "tag", "-m",
    "Tagging the File-Find-Object-Rule release as $version",
    "File-Find-Object-Rule/releases/$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
