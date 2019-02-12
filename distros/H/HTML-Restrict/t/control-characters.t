use strict;
use warnings;

use Test::More;

use HTML::Restrict ();

my $hr = HTML::Restrict->new(
    rules       => { a => ['href'] },
    uri_schemes => [undef],
);

my $expected = '<a>click me</a>';

for my $i ( 0 .. 31 ) {
    subtest "control char $i" => sub {
        my $dec = "&#$i;";
        my $hex = sprintf( "&#x%X;", $i );

        for my $prefix ( $dec, $hex ) {
            my $type = $prefix =~ m{x} ? 'hex' : 'decimal';

            my $single = $hr->process( make_link($prefix) );
            is(
                $single, $expected,
                "single control char removed ($type)"
            );

            my $double = $hr->process( make_link( $prefix, $prefix ) );
            is(
                $double, $expected,
                "double control char removed ($type)"
            );
        }
    };
}

is(
    $hr->process( make_link("&#000;") ), $expected,
    'null byte (decimal) with more padding'
);
is(
    $hr->process( make_link("&#x000;") ), $expected,
    'null byte (hex) with more padding'
);

sub make_link {
    my $prefix = join q{}, @_;
    return
        sprintf( q{<a href="%sjavascript:alert(1);">click me</a>}, $prefix, );
}

done_testing;
