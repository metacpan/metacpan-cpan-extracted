package EBook::Ishmael::EBook::XHTML;
use 5.016;
our $VERSION = '0.07';
use strict;
use warnings;

use parent 'EBook::Ishmael::EBook::HTML';

my $XHTML_NS = 'http://www.w3.org/1999/xhtml';

sub heuristic {

	my $class = shift;
	my $file  = shift;

	return 1 if $file =~ /\.xhtml?$/;
	return 0 unless -T $file;

	open my $fh, '<', $file
		or die "Failed to open $file for reading: $!\n";
	read $fh, my ($head), 1024;
	close $fh;

	return 0 unless $head =~ /<[^<>]+xmlns\s*=\s*"$XHTML_NS"[^<>]*>/;

	return $head =~ /<\s*html[^<>]+>/;

}

1;
