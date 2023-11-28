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

# undef check
$error = dies {
    Locale::MaybeMaketext::get_handle(undef);
};
$expected = quotemeta('get_handle should not be called without a class');
like(
    $error, qr/^$expected/, 'Undefined classes should be rejected',
    $error
);

# calls with bad reference
$error = dies {
    my $ref = [];
    Locale::MaybeMaketext::get_handle($ref);
};
$expected = quotemeta('get_handle should only be called with class objects: provided a reference of ARRAY');
like(
    $error, qr/^$expected/,
    'Should protect against calls with non-object references',
    $error
);

# calls with self
$error = dies {
    Locale::MaybeMaketext::get_handle('Locale::MaybeMaketext');
};
$expected = quotemeta('get_handle should be called on the translation file\'s parent class');
like(
    $error, qr/^$expected/,
    'Should protect against calls with self',
    $error
);

# calls with no get_handle support
$error = dies {
    my $class = bless {}, 'Locale::MaybeMaketext::Tests::NoMethods';
    Locale::MaybeMaketext::get_handle($class);
};
$expected = quotemeta(
    'Locale::MaybeMaketext::Tests::NoMethods was provided as a class to get_handle but it does not support get_handle');
like(
    $error, qr/^$expected/,
    'Check the class looks sane and supports get_handle',
    $error
);

# calls with class name
ok(
    lives {
        $handle = Locale::MaybeMaketext::get_handle('Locale::MaybeMaketext::Tests::Simple');
    },
    sprintf( 'Calling get_handle with string for package %s', $package->get_name() ),
    sprintf(
        'Failed to get handle for %s: %s (%s) from %s',  $package->get_name(), $@,
        isa_diagnose( 'errored', $package->get_name() ), join( q{, }, $package->get_inc() )
    )
);

# calls with class
ok(
    lives {
        my $class = bless {}, 'Locale::MaybeMaketext::Tests::Simple';
        $handle = Locale::MaybeMaketext::get_handle($class);
    },
    sprintf( 'Calling get_handle with class for package %s', $package->get_name() ),
    sprintf(
        'Failed to get handle for %s: %s (%s) from %s',  $package->get_name(), $@,
        isa_diagnose( 'errored', $package->get_name() ), join( q{, }, $package->get_inc() )
    )
);
done_testing();
