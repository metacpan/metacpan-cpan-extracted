#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More;

BEGIN { plan tests => 1 }

use HTML::TreeBuilder;

sub same {
    my ( $code ) = @_;

    my $tree = HTML::TreeBuilder->new;
    $tree->store_comments(1);
	$tree->parse($code);
	$tree->eof;

    my $out = $tree->as_XML;

    my $rv = ($code eq $out);

    $tree->delete;
    return $rv;
}

ok same("<html><head></head><body><!-- a --></body></html>\n");
