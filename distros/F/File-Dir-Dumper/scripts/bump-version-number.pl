#!/usr/bin/perl

use strict;
use warnings;

use File::Find::Object;
use IO::All;

my $tree = File::Find::Object->new({}, 'lib/');

my $new_version = shift(@ARGV)
    or die "Usage: perl scripts/bump-version-number.pl 0.0.1";
my $version_re = qr{\d+\.\d+\.\d+};

while (my $r = $tree->next()) {
    if ($r =~ m{/\.svn\z})
    {
        $tree->prune();
    }
    elsif ($r =~ m{\.pm\z})
    {
        my @lines = io->file($r)->getlines();
        LINES_LOOP:
        foreach (@lines)
        {
            s#(\$VERSION = ')$version_re(')#$1 . $new_version . $2#e;
            s#\A(Version )$version_re(\s*\n?\z)#$1 . $new_version . $2#e;
        }
        io->file($r)->print(
            @lines
        );
    }
}

