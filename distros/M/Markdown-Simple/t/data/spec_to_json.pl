#!/usr/bin/env perl
# Convert CommonMark-style spec.txt (markdown / . / html / ` fences) into spec.json.
# Used for the GFM extensions test file which is not published as JSON.
use strict;
use warnings;
use JSON::PP;

my ($in, $out) = @ARGV;
die "usage: spec_to_json.pl INPUT.txt OUTPUT.json\n" unless $in && $out;

open my $fh, '<', $in or die "open $in: $!";
local $/;
my $text = <$fh>;
close $fh;

my @examples;
my $section = '';
my $example = 0;
my $line_no = 0;
my @lines = split /\n/, $text, -1;

for (my $i = 0; $i < @lines; $i++) {
    my $l = $lines[$i];
    if ($l =~ /^#{1,6}\s+(.*)$/) {
        $section = $1;
        next;
    }
    if ($l =~ /^(`{32,}|~{32,})\s*example(?:\s+(\S+))?\s*$/) {
        my $fence = $1;
        my $info  = defined $2 ? $2 : '';
        my $start = $i + 1;
        my (@md, @html);
        my $in_html = 0;
        $i++;
        while ($i < @lines && $lines[$i] ne substr($fence,0,1) x length($fence)
               && $lines[$i] !~ /^\Q$fence\E\s*$/) {
            if ($lines[$i] eq '.') { $in_html = 1; $i++; next; }
            if ($in_html) { push @html, $lines[$i]; }
            else          { push @md,   $lines[$i]; }
            $i++;
        }
        $example++;
        push @examples, {
            markdown   => join("\n", @md)   . (@md   ? "\n" : ''),
            html       => join("\n", @html) . (@html ? "\n" : ''),
            example    => $example,
            start_line => $start,
            end_line   => $i + 1,
            section    => $section,
            ($info ? (extension => $info) : ()),
        };
    }
}

open my $ofh, '>', $out or die "open $out: $!";
print $ofh JSON::PP->new->pretty->canonical->encode(\@examples);
close $ofh;

print "wrote $out (", scalar(@examples), " examples)\n";
