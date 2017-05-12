#!/usr/bin/perl

use strict;
use warnings;

my @stmts;
open(my $ifh, "<", "create_tables.sql") or die($!);
open(my $ofh, ">", "create_tables.pm") or die($!);
print $ofh "
use strict;
use warnings;

package CreateTables;

sub getStmts {
    
    my \@stmts = (
";

my $stmt = "";
my $isfunction = 0;
my $cnt = 0;
while((my $line = <$ifh>)) {
    chomp $line;
    $line =~ s/^\s+//go;
    $line =~ s/\s+$//go;
    $line =~ s/\"/\\"/go;
    if($line =~ /CREATE FUNCTION/i) {
        $isfunction = 1;
    } elsif($line =~ /\$\$\;/) {
        $isfunction = 0;
    }
    $line =~ s/\$\$/\\\$\\\$/go;
    $stmt .= "$line ";
    if(!$isfunction && $line =~ /\;$/) {
        $stmt =~ s/\;\ $//go;
        print $ofh "        \"$stmt\",\n";
        $stmt = "";
        $cnt++;
    }
}
close $ifh;

print $ofh "    );

return \@stmts;
}
1;
";
close $ofh;
print "$cnt statements packed to pm file\n";
