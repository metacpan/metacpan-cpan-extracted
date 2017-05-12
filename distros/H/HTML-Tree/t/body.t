#!/usr/bin/perl -T

use warnings;
use strict;

use Test::More tests => 18;

use HTML::TreeBuilder;

EMPTY: {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('');
    $root->eof();

    is( $root->as_HTML(), "<html><head></head><body></body></html>" );
}

BR_ONLY: {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('<br />');
    $root->eof();

    is( $root->as_HTML(),
        "<html><head></head><body><p><br /></body></html>" );
}

TEXT_ONLY: {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('text');
    $root->eof();

    is( $root->as_HTML(), "<html><head></head><body><p>text</body></html>" );
}

EMPTY_TABLE: {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('<table></table>');
    $root->eof();

    is( $root->as_HTML(),
        "<html><head></head><body><table></table></body></html>" );
}

ESCAPES: {
    my $root   = HTML::TreeBuilder->new();
    my $escape = 'This &#x17f;oftware has &#383;ome bugs';
    my $html   = $root->parse($escape)->eof->elementify();
TODO: {
        local $TODO = 'HTML::Parser::parse mucks with our escapes';
        is( $html->as_HTML(),
            "<html><head></head><body>$escape</body></html>" );
    }
}

OTHER_LANGUAGES: {
    my $root   = HTML::TreeBuilder->new();
    my $escape = 'Geb&uuml;hr vor Ort von &euro; 30,- pro Woche';   # RT 14212
    my $html   = $root->parse($escape)->eof;
    is( $html->as_HTML(),
        "<html><head></head><body>Geb&uuml;hr vor Ort von &euro; 30,- pro Woche</body></html>"
    );
}

RT_18570: {
    my $root   = HTML::TreeBuilder->new();
    my $escape = 'This &sim; is a twiddle';
    my $html   = $root->parse($escape)->eof->elementify();
    is( $html->as_HTML(), "<html><head></head><body>$escape</body></html>" );
}

RT_18571: {
    my $root = HTML::TreeBuilder->new();
    my $html = $root->parse('<b>$self->escape</b>')->eof->elementify();
    is( $html->as_HTML(),
        "<html><head></head><body><b>\$self-&gt;escape</b></body></html>" );
    is( $html->as_HTML(''),
        "<html><head></head><body><b>\$self->escape</b></body></html>" );
    is( $html->as_HTML("\0"),
        "<html><head></head><body><b>\$self->escape</b></body></html>" )
        ;    # 3.22 compatability
}

sub has_no_content
{
    my ($html, $name, $tag) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is( ok( $html =~ m!(<$tag>.*</$tag>)!s, "$name contains <$tag>" )
        ? $1 : undef,
        "<$tag></$tag>", "$name <$tag> contains nothing" );
} # end has_no_content

RT_70385: {
    my $root     = HTML::TreeBuilder->new();
    my $html     = $root->parse_content(
      "<html><head></head><body><pre></pre><textarea></textarea></body></html>"
    );
    my $unindented = $html->as_HTML;
    my $indented   = $html->as_HTML(undef, "  ");

    has_no_content($unindented, qw(unindented pre));
    has_no_content($unindented, qw(unindented textarea));
    has_no_content($indented,   qw(indented   pre));
    has_no_content($indented,   qw(indented   textarea));
}
