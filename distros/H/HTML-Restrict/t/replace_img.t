#!perl

use strict;
use warnings;

use HTML::Restrict ();
use Test::More;

my @texts = (
    {
        label => '<img ... />',
        html  => q{<img alt="foo bar" src="http://example.com/foo.jpg" />},
    },
    {
        label => '<img ... ></img>',
        html => q{<img alt="foo bar" src="http://example.com/foo.jpg"></img>},
    },
);

my @cases = (
    {
        label  => 'default args',
        args   => {},
        expect => undef,
    },
    {
        label  => 'replace_img => 0',
        args   => { replace_img => 0 },
        expect => undef,
    },
    {
        label  => 'replace_img => 1',
        args   => { replace_img => 1 },
        expect => '[IMAGE: foo bar]',
    },
    {
        label  => 'replace_img => CODE',
        args   => { replace_img => \&replacer },
        expect => '[IMAGE REMOVED: foo bar]',
    },
);

sub replacer {
    my ( $tag, $attr, $text ) = @_;
    return "[IMAGE REMOVED: $attr->{alt}]";
}

for my $c (@cases) {
    ok(
        my $hr = HTML::Restrict->new( debug => 0, %{ $c->{args} } ),
        "$c->{label}: HTML::Restrict->new(...)"
    );
    for my $t (@texts) {
        is(
            $hr->process( $t->{html} ), $c->{expect},
            "$c->{label}: $t->{label}"
        );
    }
}

done_testing();
