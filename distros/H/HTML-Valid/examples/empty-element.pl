#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Valid::Tagset '%emptyElement';
for my $tag (qw/hr dl br snakeeyes/) {
    if ($emptyElement{$tag}) {
	print "<$tag> is empty.\n";
    }
    else {
	print "<$tag> is not empty.\n";
    }
}

