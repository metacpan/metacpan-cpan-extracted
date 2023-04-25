#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Restrict ();
use Test::More;

my $hr = HTML::Restrict->new();

{
    my $html      = q[Line 1<p>Line 2<br>Line 3];
    my $processed = $hr->process($html);
    is $processed, 'Line 1Line 2Line 3', 'off by default';
}

$hr->create_newlines(1);

{
    my $html = q[
Line 1<br>Line 2<br/>Line 3<br />Line 4
];
    my $processed = $hr->process($html);
    is $processed, "Line 1\nLine 2\nLine 3\nLine 4",
        'replace <br> by a newline';
}

{
    my $html = q[
Paragraph 1<p>Paragraph 2<p>Paragraph 3</p><p>Paragraph 4];
    my $processed = $hr->process($html);
    is $processed, "Paragraph 1\n\nParagraph 2\n\nParagraph 3\n\nParagraph 4",
        'replace <p> by 2 newlines';
}

{
    my $html = q[Line 1<p>Line 2<br>Line 3];
    $hr->set_rules( { p => [] } );
    my $processed = $hr->process($html);
    is $processed, "Line 1<p>Line 2\nLine 3", 'rules have precedence';
}

done_testing();
