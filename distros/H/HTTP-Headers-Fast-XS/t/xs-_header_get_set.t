use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('HTTP::Headers::Fast');
    use_ok('HTTP::Headers::Fast::XS');
}

can_ok( HTTP::Headers::Fast::, '_header_get' );

{
    my $headers = HTTP::Headers::Fast->new(foo => "bar", foo_multi => "baaaaz", foo_multi => "baz");

    is(
        $headers->header('foo'),
        'bar',
        'header_get for simple header',
    );
}

{
    my $headers = HTTP::Headers::Fast->new(foo => "bar", foo => "baaaaz", Foo => "baz");

    is(
        $headers->header('foo'),
        "bar, baaaaz, baz",
        'header_get multi and !want_array',
    );
}

{
    my $headers = HTTP::Headers::Fast->new();

    $headers->header('foo', [1, 2]);
    is(
        $headers->header('foo'),
        "1, 2",
        'header_get multi and !want_array',
    );
    is(
        $headers->as_string,
        "Foo: 1\nFoo: 2\n",
        'headers->as_string',
    );
}

done_testing;
