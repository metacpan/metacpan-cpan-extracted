#!/usr/bin/perl
# a demo of Devel::DumpTrace. Run as perl -d:DumpTrace demo.pl
$a = 1;
$b = 3;
$c = 2 * $a + 7 * $b;
@d = ($a, $b, $c + $b);
