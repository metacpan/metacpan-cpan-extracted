#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;


unless ($ENV {AUTHOR_TESTING}) {
    plan skip_all => "AUTHOR tests";
    exit;
}

sub version;

SKIP: {
    open my $fh, "<", "MANIFEST" or do {
        skip "Failed to open MANIFEST", 1;
    };
    while (my $file = <$fh>) {
        chomp $file;
        open my $fh2, "<", $file or do {
            fail "Cannot open $file: $!";
            next;
        };
        my $text = do {local $/; <$fh2>};
        my $r = $text =~ /[^\n\x20-\x7E]/;
        ok !$r, "$file only contains printable ASCII characters and newlines";
    }
    open $fh, "<", "MANIFEST.SKIP" or do {
        skip "Failed to open MANIFEST.SKIP", 1;
    };
    while (my $file = <$fh>) {
        chomp $file;
        next unless $file =~ /\.t$/;   # Only check test files.
        open my $fh2, "<", $file or do {
            fail "Cannot open $file: $!";
            next;
        };
        my $text = do {local $/; <$fh2>};
        my $r = $text =~ /[^\n\x20-\x7E]/;
        ok !$r, "$file only contains printable ASCII characters and newlines";
    }
}

done_testing ();

__END__
