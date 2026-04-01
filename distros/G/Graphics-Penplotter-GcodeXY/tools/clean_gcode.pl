#!/usr/bin/env perl
use strict;
use warnings;

my $infile = shift // '18-box-ana.gcode';
my $outfile = shift // "$infile.clean";
open my $in, '<', $infile or die "cannot open $infile: $!";
open my $out, '>', $outfile or die "cannot open $outfile: $!";

my ($curx, $cury);
my $last_line = '';
while (my $ln = <$in>) {
    chomp $ln;
    (my $line = $ln) =~ s/^\s+|\s+$//g;
    next if $line eq '' && $last_line eq '';
    # Skip exact duplicate lines
    if ($line eq $last_line) { next }
    # Skip fast moves to the same position
    if ($line =~ /^G00\s+X\s*([+-]?\d+(?:\.\d+)?)(?:\s+Y\s*([+-]?\d+(?:\.\d+)?))?/i) {
        my $x = 0+$1; my $y = defined $2 ? 0+$2 : undef;
        if (defined $x && defined $curx && defined $y && defined $cury) {
            if (sprintf("%.5f", $x) == sprintf("%.5f", $curx) && sprintf("%.5f", $y) == sprintf("%.5f", $cury)) { $last_line = $line; next }
        }
        $curx = $x if defined $x;
        $cury = $y if defined $y;
    }
    # Update current position on slow moves
    if ($line =~ /^G01\s+X\s*([+-]?\d+(?:\.\d+)?)(?:\s+Y\s*([+-]?\d+(?:\.\d+)?))?/i) {
        $curx = 0+$1 if defined $1;
        $cury = 0+$2 if defined $2;
    }
    print $out $line, "\n";
    $last_line = $line;
}
close $in;
close $out;
print "Wrote $outfile\n";
