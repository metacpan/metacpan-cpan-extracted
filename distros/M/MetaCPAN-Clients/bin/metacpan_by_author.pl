#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use MetaCPAN::Client;

my $name = shift or die "Usage: $0 PAUSEID\n";

my $mcpan  = MetaCPAN::Client->new();
my $author = eval { $mcpan->author($name) };
if ($@) {
    print "Could not find $name\n";
    exit 1;
}
my $rset = $author->releases;

while ( my $item = $rset->next ) {
    my $dist = $item->distribution;
    printf "%s %7s %s\n", $item->date, $item->version, $item->distribution;
    my @licenses = @{ $item->license };
    if (not @licenses) {
        print "   license field missing in $dist\n";
    } else {
        for my $license (@licenses) {
            if ($license eq 'unknown') {
                print "   unknown license in $dist\n";
            }
        }
    }
    my %resources = %{ $item->resources };
    if (not $resources{repository}) {
        print "    repository link missing from $dist\n";
    }
}

