#/usr/bin/env perl
#===============================================================================
#Last Modified:  2015/06/16
#===============================================================================
use warnings;
use strict;
use Test::More;
use HTML::WikiConverter;

{
    my $wc = HTML::WikiConverter->new(
        dialect => 'FreeStyleWiki',
        preserve_tags => 1,
    );
    test1($wc, 1);
}
{
    my $wc = HTML::WikiConverter->new(
        dialect => 'FreeStyleWiki',
    );
    test1($wc, 0);
}

sub test1 {
    my ($wc, $preserve) = @_;
    for my $tag (qw/ big small tt abbr acronym cite code dfn kbd samp var sup sub /) {
        my $html = "<$tag>a</$tag>";
        my $wiki = $wc->html2wiki($html);
        is($wiki, $preserve ? $html : "a", ($preserve ? "preserve" : "strip") . " $tag");
    }
}

done_testing;
