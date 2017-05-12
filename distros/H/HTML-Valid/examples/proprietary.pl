#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use HTML::Valid::Tagset '%isProprietary';
my @tags = qw/a blink plaintext marquee/;
for my $tag (@tags) {
    if ($isProprietary{$tag}) {
	print "<$tag> is proprietary.\n";
    }
    else {
	print "<$tag> is not a proprietary tag.\n";
    }
}

