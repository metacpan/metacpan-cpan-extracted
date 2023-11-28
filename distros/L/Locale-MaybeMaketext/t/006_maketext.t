#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;
unload_mocks();
Locale::MaybeMaketext::maybe_maketext_reset();

my $package = get_test_data_by_index();

# load the localizer.
local @INC = ( $package->get_inc() );
Locale::MaybeMaketext::maybe_maketext_get_localizer();

my ( $handle, $error, $expected );

# not a reference check
$error = dies {
    Locale::MaybeMaketext::maketext( 'scalar', undef );
};
$expected = quotemeta('maketext must be called as a method');
like(
    $error, qr/^$expected/, 'Must be called as a method',
    $error
);

# calls with bad reference
$error = dies {
    my $ref = [];
    Locale::MaybeMaketext::maketext( $ref, undef );
};
$expected = quotemeta('maketext should only be called with class objects: provided a reference of ARRAY');
like(
    $error, qr/^$expected/,
    'Should protect against calls with non-object references',
    $error
);

# calls with self
$error = dies {
    my $ref = bless {}, 'Locale::MaybeMaketext';
    Locale::MaybeMaketext::maketext( $ref, undef );
};
$expected = quotemeta('maketext should be called on the translation file\'s parent class');
like(
    $error, qr/^$expected/,
    'Should protect against calls with self',
    $error
);

# calls with no maketext support
$error = dies {
    my $class = bless {}, 'Locale::MaybeMaketext::Tests::NoMethods';
    Locale::MaybeMaketext::maketext( $class, undef );
};
$expected = quotemeta(
    'Locale::MaybeMaketext::Tests::NoMethods was provided as a class to maketext but it does not support maketext');
like(
    $error, qr/^$expected/,
    'Check the class looks sane and supports maketext',
    $error
);

# now work on the handle
$handle = Locale::MaybeMaketext::Tests::Simple->get_handle();

# calls with undefined text to translate
$error = dies {
    $handle->maketext(undef);
};
$expected = quotemeta('maketext must be passed a scalar string to translate - it was passed an undefined item');
like(
    $error, qr/^$expected/,
    'Check that undefined text is rejected',
    $error
);

# calls with referenced text to translate
$error = dies {
    my $ref = [];
    $handle->maketext($ref);
};
$expected = quotemeta('maketext must be passed a scalar string to translate - it was passed a ARRAY reference');
like(
    $error, qr/^$expected/,
    'Check that referenced text is rejected',
    $error
);
done_testing();
