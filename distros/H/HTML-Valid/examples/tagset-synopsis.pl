#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Valid::Tagset ':all';
for my $tag (qw/canvas a li moonshines/) {
    if ($isHTML5{$tag}) {
	print "<$tag> is ok\n";
    }
    else {
	print "<$tag> is not HTML5\n";
    }
}

