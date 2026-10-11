#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# EVERY FILE THAT SHIPS IS ASCII. The stones the terminal draws as a ring and
# a disc are written as escapes, so no source file needs an encoding and no
# POD needs more than the =encoding line it has.

open my $manifest, '<', 'MANIFEST' or die "MANIFEST: $!";
my @files = grep { length && -f } map { (split ' ', $_)[0] // '' } <$manifest>;
close $manifest;
cmp_ok(scalar(@files), '>=', 50, scalar(@files) . ' files of the manifest read');

for my $file (sort @files) {
    open my $fh, '<:raw', $file or die "$file: $!";
    my @found;
    while (my $line = <$fh>) {
        push @found, $. if $line =~ /[^\x09\x0A\x0D\x20-\x7E]/;
    }
    is("@found[0 .. ($#found > 4 ? 4 : $#found)]", '', "$file is ASCII");
}

done_testing();
