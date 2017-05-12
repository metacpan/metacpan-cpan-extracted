#!/usr/bin/perl -T

use warnings;
use strict;

# Testing of the incremental parsing.  Try to split a HTML document at
# every possible position and make sure that the result is the same as
# when parsing everything in one chunk.

# Now we use a shorter document, because we don't have all day on
# this.

my ( $HTML, $notests );

BEGIN {
    $HTML = <<'EOT';

<Title>Tittel
</title>

<H1>Overskrift</H1>

<!-- Comment -->

Text <b>bold</b>
<a href="..." name=foo bar>italic</a>
some &#101;ntities (&aring)
EOT

    $notests = length($HTML);    # A test for each char in the test doc
    $notests *= 3;               #  done twice
    $notests += 3;               #  plus more for the the rest of the tests
}

use Test::More tests => $notests;    # Tests

use HTML::TreeBuilder;

my $h = new HTML::TreeBuilder;
isa_ok( $h, "HTML::TreeBuilder" );
$h->parse($HTML)->eof;
my $html = $h->as_HTML;
$h->delete;

# Each test here tries to parse the doc when we split it in two.
for my $pos ( 0 .. length($HTML) - 1 ) {
    my $first = substr( $HTML, 0, $pos );
    my $last = substr( $HTML, $pos );
    is( $first . $last, $HTML, "File split okay" );
    my $h1;
    eval {
        $h1 = new HTML::TreeBuilder;
        isa_ok( $h1, 'HTML::TreeBuilder' );
        $h1->parse($first);
        $h1->parse($last);
        $h1->eof;
    };
    if ($@) {
        print "Died when splitting at position $pos:\n";
        my $before = 10;
        $before = $pos if $pos < $before;
        print "«", substr( $HTML, $pos - $before, $before );
        print "»\n«";
        print substr( $HTML, $pos, 10 );
        print "»\n";
        print "not ok $pos\n";
        $h1->delete;
        next;
    }
    my $new_html = $h1->as_HTML;
    my $before   = 10;
    $before = $pos if $pos < $before;
    is( $new_html, $html, "Still Parsing as the same after split at $pos" )
        or diag(
        "Something is different when splitting at position $pos:\n", "«",
        substr( $HTML, $pos - $before, $before ), "»\n«",
        substr( $HTML, $pos,           10 ),      "»\n",
        "\n$html$new_html\n",
        );
    $h1->delete;
}    # for

# Also try what happens when we feed the document one-char at a time
# print "#\n#\nNow parsing document once char at a time...\n";
my $perChar = new HTML::TreeBuilder;
isa_ok( $perChar, 'HTML::TreeBuilder' );
while ( $HTML =~ /(.)/sg ) {
    $perChar->parse($1);
}
$perChar->eof;
my $new_html = $perChar->as_HTML;
is( $new_html, $html, "Testing per Char parsing" );
$perChar->delete;
