#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use XML::Parser;
use Image::SVG::Path 'extract_path_info';
my $file = "$Bin/Home_for_the_aged.svg";
my $p = XML::Parser->new (Handlers => {Start => \& start});
$p->parsefile ($file) or die "Error $file: ";

sub start
{
    my ($expat, $element, %attr) = @_;

    if ($element eq 'path') {
	my $d = $attr{d};
	my @r = extract_path_info ($d);
	for (@r) {
	    if ($_->{svg_key} =~ /^[mM]$/i) {
		print "MOVE TO @{$_->{point}}.\n";
	    }
	}
    }
}
