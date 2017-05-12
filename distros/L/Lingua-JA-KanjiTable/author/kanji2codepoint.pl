#!/usr/bin/env perl

# Usage: perl kanji2codepoint.pl < input.txt > output.txt

use strict;
use warnings;
use Encode qw/decode_utf8/;

my @codepoint_list;

while(<>)
{
    chomp;
    $_ = decode_utf8($_);
    push(@codepoint_list, ord);
}

@codepoint_list = sort { $a <=> $b } @codepoint_list;

my $line;

my $state = 0;
# 0: 初期状態  1: コードポイントが連続するか探っている  2: コードポイントの連続が確定
# 3: コードポイントが２個以上連続している

my $codepoint_prev = -1;

for my $codepoint (@codepoint_list)
{
    if ($state == 0 || $state == 1 || $state == 2)
    {
        if ($codepoint - 1 == $codepoint_prev) # コードポイントが連続している
        {
            $codepoint_prev = $codepoint;
            $state = 2;
        }
        else
        {
            $state = 3 if $state != 0 && $codepoint_prev - hex($line) > 1;

               if ($state == 1) { $line .= "\n"; }
            elsif ($state == 2) { $line .= "\n" . sprintf("%04X", $codepoint_prev) . "\n"; }
            elsif ($state == 3) { $line .= '\t' . sprintf("%04X", $codepoint_prev) . "\n"; }

            print $line unless $state == 0;

            $line = sprintf("%04X", $codepoint);
            $codepoint_prev = $codepoint;
            $state = 1;
        }
    }
    else { die; }
}

$state = 3 if $state != 0 && $codepoint_prev - hex($line) > 1;

   if ($state == 1) { $line .= "\n"; }
elsif ($state == 2) { $line .= "\n" . sprintf("%04X", $codepoint_prev) . "\n"; }
elsif ($state == 3) { $line .= '\t' . sprintf("%04X", $codepoint_prev) . "\n"; }

print $line unless $state == 0;
