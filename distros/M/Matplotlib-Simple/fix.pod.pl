#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';

sub file2string ($file) {
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

my $pod = file2string('README.pod');
my @pod = split /\n/, $pod;
foreach my $i ( grep {$pod[$_] =~ /^<img alt="/} reverse 0..$#pod) {
	next if $pod[$i-1] eq '<p>' eq $pod[$i+1]; # html paragraph
#	my @p = @pod[$i-3..$i+3];
#	p @p;
	splice @pod, $i+1, 0, '<p>';
	splice @pod, $i, 0, '=for html','<p>';
#	@p = @pod[$i-3..$i+3];
#	p @p;
}
open my $fh, '>', 'README.pod';
say $fh join ("\n", @pod);
