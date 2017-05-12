#/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use HTML::WikiConverter;

# Test without base_uri.

{
    my $wc = HTML::WikiConverter->new(
        dialect => 'FreeStyleWiki',
    );

    my @testcases = (
        [qw#http://example.com Example [Example|http://example.com]#],
        [qw#http://example.com/ Example [Example|http://example.com/]#],
        [qw#http://example.com/foo Example-foo [Example-foo|http://example.com/foo]#],
        [qw#http://example.com http://example.com http://example.com#],
    );
    t1($wc, \@testcases);
}


sub t1 {
    my ($t1, $testcases) = @_;
    my $fmt = '<a href="%s">%s</a>';
    for my $c (@$testcases) {
        is($t1->html2wiki(sprintf $fmt, @$c[0,1]), $c->[2]);
    }
}

done_testing;
