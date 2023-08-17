#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::NoTabs;

open my $fh, '<', 'MANIFEST' or die $!;
while ($_ = <$fh>) {
    chomp;
    s/\t.*//s;
    open my $fh2, '<', $_ or next;
    my $line = <$fh2>;
    close $fh2;
    next unless /\.(c|cc|cpp|md|pl|pm|psgi|sh|t|txt)$/i or $line =~ m{^#!.*\bperl};
    notabs_ok $_, "No tabs in '$_'", { trailing_whitespace => 1, all_reasons => 1 };
}
close $fh;

done_testing();
