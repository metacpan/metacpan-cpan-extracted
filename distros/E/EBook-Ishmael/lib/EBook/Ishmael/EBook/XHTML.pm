package EBook::Ishmael::EBook::XHTML;
use 5.016;
our $VERSION = '1.03';
use strict;
use warnings;

use parent 'EBook::Ishmael::EBook::HTML';

my $XHTML_NS = 'http://www.w3.org/1999/xhtml';

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	return 1 if $file =~ /\.xhtml?$/;
	return 0 unless -T $fh;

	read $fh, my ($head), 1024;

	return 0 unless $head =~ /<[^<>]+xmlns\s*=\s*"\Q$XHTML_NS\E"[^<>]*>/;

	return $head =~ /<\s*html[^<>]+>/;

}

1;
