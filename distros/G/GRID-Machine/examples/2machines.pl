#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host1 = 'casiano@orion.pcg.ull.es';
my $host2 = 'casiano@beowulf.pcg.ull.es';
my $host3 = 'casiano@miranda.deioc.ull.es';

my $orion = GRID::Machine->new(host => $host1);

$orion->sub( one => q{ print "one\n" });
print "<orion:".$orion->exists(q{one}).">\n";

my $beowulf = GRID::Machine->new(host => $host2);
$beowulf->sub( one => q{ print "one\n" });
print "<beowulf:".$beowulf->exists(q{one}).">\n";

print "<beowulf:".$beowulf->exists(q{two}).">\n";

my $miranda = GRID::Machine->new(host => $host3);
$miranda->sub( one => q{ print "one\n" });
print "<miranda:".$beowulf->exists(q{one}).">\n";

print "<miranda:".$beowulf->exists(q{two}).">\n";
