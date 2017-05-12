#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Valid::Tagset qw/%optionalEndTag %emptyElement/;
for my $tag (qw/li p a br/) {
    if ($optionalEndTag{$tag}) {
	print "OK to omit </$tag>.\n";
    }
    elsif ($emptyElement{$tag}) {
	print "<$tag> does not ever take '</$tag>'\n";
    }
    else {
	print "Cannot omit </$tag> after <$tag>.\n";
    }
}

