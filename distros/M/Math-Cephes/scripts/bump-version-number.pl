#!/usr/bin/perl

use strict;
use warnings;

use File::Find::Object ();
use Path::Tiny         qw/ path /;

my $tree = File::Find::Object->new( {}, 'lib/' );

my $version_n = shift(@ARGV);

if ( !defined($version_n) )
{
    die "Specify version number as an argument! bump-version-number.pl '0.0.1'";
}

while ( my $r = $tree->next() )
{
    if ( $r =~ m{/\.svn\z} )
    {
        $tree->prune();
    }
    elsif ( $r =~ m{\.pm\z} )
    {
        path($r)->edit_lines_utf8(
            sub {
s#(\$VERSION = '|^Version )\d+\.\d+(?:\.\d+)?('|)#$1 . $version_n . $2#e;
            }
        );
    }
}
