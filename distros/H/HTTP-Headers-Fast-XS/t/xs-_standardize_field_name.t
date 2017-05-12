use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('HTTP::Headers::Fast');
    use_ok('HTTP::Headers::Fast::XS');
}

can_ok( HTTP::Headers::Fast::XS::, '_standardize_field_name' );

{
    local $HTTP::Headers::Fast::TRANSLATE_UNDERSCORE = 1;
    is(
        HTTP::Headers::Fast::XS::_standardize_field_name('hello_world_'),
        'hello-world-',
        'All underscores are converted to dashes',
    );
}

{
    local $HTTP::Headers::Fast::TRANSLATE_UNDERSCORE = 0;
    is(
        HTTP::Headers::Fast::XS::_standardize_field_name('hello_world_'),
        'hello_world_',
        'Respect $TRANSLATE_UNDERCORE global',
    );
}

{
    local $HTTP::Headers::Fast::TRANSLATE_UNDERSCORE = 0;
    is(
        HTTP::Headers::Fast::XS::_standardize_field_name('Hello_WorlD_'),
        'hello_world_',
        'Test that caching works (as much as we can)',
    );

    is(
        $HTTP::Headers::Fast::standard_case{'hello_world_'},
        'Hello_world_',
        'Set up standard_case in original header value correctly',
    );
}

done_testing;
