#!/usr/bin/perl -w
use strict;
while (<>) {
    if (/<info>(.*)<\/info>/i) {
        my $foo = $1;
        $foo =~ s/\W+/-/g;
        print "<info>$foo<\/info>\n";
    }
    else {
        print;
    }
}
