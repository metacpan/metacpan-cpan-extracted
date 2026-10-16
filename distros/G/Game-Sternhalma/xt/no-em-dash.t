#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

# NOTHING THAT SHIPS HAS AN EM DASH, AN EN DASH OR A CURLY QUOTE IN IT, as
# bytes or as an escape. The bytes are looked for in the raw file, so this does
# not depend on how the file is decoded.

open my $manifest, '<', 'MANIFEST' or die "MANIFEST: $!";
my @files = grep { length && -f } map { (split ' ', $_)[0] // '' } <$manifest>;
close $manifest;
cmp_ok(scalar(@files), '>=', 50, scalar(@files) . ' files of the manifest read');

my %bytes = (
    'an em dash'             => "\xE2\x80\x94",
    'an en dash'             => "\xE2\x80\x93",
    'a curly single quote'   => "\xE2\x80[\x98\x99]",
    'a curly double quote'   => "\xE2\x80[\x9C\x9D]",
    'an em dash as an escape' => '\\\\x\\{2014\\}|\\\\N\\{EM DASH\\}|&mdash;',
);
for my $file (sort @files) {
    next if $file eq 'xt/no-em-dash.t';
    open my $fh, '<:raw', $file or die "$file: $!";
    my @found;
    while (my $line = <$fh>) {
        for my $what (sort keys %bytes) {
            push @found, "$what (line $.)" if $line =~ /$bytes{$what}/;
        }
    }
    is("@found", '', "$file");
}

done_testing();
