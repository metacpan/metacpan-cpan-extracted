#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Gzip::Libdeflate;
my $gl = Gzip::Libdeflate->new (level => 12);
my $out = $gl->compress ("ABCDEFG" x 2);
print length ($out), "\n";
my $rt = $gl->decompress ($out);
print "$rt\n";

