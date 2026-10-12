#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# EVERY TEXT FILE THAT SHIPS IS ASCII. The wide glyphs the terminal draws are
# written as byte escapes, so no source file needs an encoding. The sprite
# sheet is a PNG and is left out.

open my $manifest, '<', 'MANIFEST' or die "MANIFEST: $!";
my @files = grep { length && -f && !/\.png\z/ } map { (split ' ', $_)[0] // '' } <$manifest>;
close $manifest;
cmp_ok(scalar(@files), '>=', 30, scalar(@files) . ' text files of the manifest read');

for my $file (sort @files) {
	open my $fh, '<:raw', $file or die "$file: $!";
	my @found;
	while (my $line = <$fh>) {
		push @found, $. if $line =~ /[^\x09\x0A\x0D\x20-\x7E]/;
	}
	is("@found[0 .. ($#found > 4 ? 4 : $#found)]", '', "$file is ASCII");
}

done_testing();
