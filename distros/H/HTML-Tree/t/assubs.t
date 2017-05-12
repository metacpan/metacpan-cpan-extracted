#!/usr/bin/perl -T

use warnings;
use strict;

use Test::More;

use HTML::AsSubs;
use HTML::Tagset;

plan tests => scalar @HTML::AsSubs::TAGS + 3;

### verify all subroutines in HTML::AsSubs ;
map {

    my $h = eval "HTML::AsSubs::$_(\"$_\")";

    my $string
        = (    $HTML::Tagset::optionalEndTag{$_}
            || $HTML::Tagset::emptyElement{$_} )
        ? "<$_>$_"
        : "<$_>$_<\/$_>";

    is( $h->as_HTML, "$string", "Test of tag: $_" );

} (@HTML::AsSubs::TAGS);

### verify passing href to <a> tag.
{
    my $string = "<a href=\"http://cpan.org\">test</a>";
    my $h = HTML::AsSubs::a( { href => "http://cpan.org" }, "test" );
    is( $h->as_HTML, "$string", "Test of tag properties" );
}

### Improve coverage by passing undef as first parm to _elem via wrapper function.
{
    my $string = "<a>test</a>";
    my $h = HTML::AsSubs::a( undef, "test" );
    is( $h->as_HTML, "$string", "undef test" );
}

### Improve coverage by passing no parameters to _elem via wrapper function.
{
    my $string = "<a></a>";
    my $h      = HTML::AsSubs::a();
    is( $h->as_HTML, "$string", "empty tag test" );
}

