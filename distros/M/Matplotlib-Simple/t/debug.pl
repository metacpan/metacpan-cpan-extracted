#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Digest::SHA 'sha512_base64';
use Util;

sub simplify_file ($file) {
	my $text = file2string($file);
	my @text = split /\n/, $text;
	@text = grep {$_ !~ m/^\h*\<dc:title\>made.+\/Simple\.pm\<\/dc:title\>$/} @text;
	@text = grep {$_ !~ m/^\h*\<dc:date\>/}          @text;
	@text = grep {$_ !~ m/^\h*\<path\h+id="/}        @text;
	@text = grep {$_ !~ m/^\h*\<use\h*xlink:href="/} @text;
	@text = grep {$_ !~ m/clipPath/}                 @text;
	@text = grep {$_ !~ m/clip\-path="/}             @text;
	foreach my $line (@text) {
		$line =~ s/\h+id="image[a-z\d]+"//;
	}
	$text = join ("\n", @text);
	say "sha512_base64($file)\t= " . sha512_base64($text);
	return \@text;
}
my $new = simplify_file('/tmp/hist.sub.svg');
my $old = simplify_file('output.images/hist.sub.svg');
my @different_lines;
foreach my ($idx, $line) (indexed @{ $new }) {
	if ($new->[$idx] ne $old->[$idx]) {
		push @different_lines, [$old->[$idx], $line];
	}
	last if scalar @different_lines > 9;
}
p @different_lines;
