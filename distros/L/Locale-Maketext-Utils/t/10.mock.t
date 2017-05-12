use Test::Carp;

use Test::More tests => 35;

use Locale::Maketext::Utils::Mock ();

ok( defined *{'Locale::Maketext::Utils::Mock::en::Lexicon'},  'module creates en' );
ok( !defined *{'Locale::Maketext::Utils::Mock::fr::Lexicon'}, 'module does not create non-en' );

my $mock = Locale::Maketext::Utils::Mock->get_handle();
is( ref($mock), 'Locale::Maketext::Utils::Mock::en', 'basic object is correct subclass' );
ok( $mock->can('makethis'), 'Object subclassed properly' );

is( Locale::Maketext::Utils::Mock::init_mock_locales( "fr", "es" ), 2, 'init_mock_locales() returns count' );
ok( defined *{'Locale::Maketext::Utils::Mock::fr::Lexicon'}, 'init_mock_locales() function does create non-en 1' );
ok( defined *{'Locale::Maketext::Utils::Mock::es::Lexicon'}, 'init_mock_locales() function does create non-en 2' );

is( Locale::Maketext::Utils::Mock->init_mock_locales( "it", "$mock" ), 1, 'init_mock_locales() ignores bad ones' );
ok( defined *{'Locale::Maketext::Utils::Mock::es::Lexicon'}, 'init_mock_locales() class method does create non-en' );

$mock->init_mock_locales("ja");
ok( defined *{'Locale::Maketext::Utils::Mock::ja::Lexicon'}, 'init_mock_locales() object method does create non-en' );

is( ref( Locale::Maketext::Utils::Mock->get_handle("ja") ), 'Locale::Maketext::Utils::Mock::ja', 'get_handle() existing arg results in correct object' );
is( ref( Locale::Maketext::Utils::Mock->get_handle("ar") ), 'Locale::Maketext::Utils::Mock::en', 'get_handle() non-existant arg defaults to en object' );

is( Locale::Maketext::Utils::Mock->init_mock_locales('i-YODA'), 1, 'init_mock_locales() is ok w/ i_ tags' );
ok( defined *{'Locale::Maketext::Utils::Mock::i_yoda::Lexicon'}, 'init_mock_locales() class method does create i_ tag' );

is( Locale::Maketext::Utils::Mock->init_mock_locales(), 0, 'init_mock_locales() returns zero when non are loaded' );

# create_method()
my %type = (
    'non-code' => undef(),
    'code'     => 1,
);
for my $type ( sort keys %type ) {
    my $string = defined $type{$type} ? 'Custom' : 'I am';

    # this does not work the second time-around so we eval
    # ok(!defined *{'Locale::Maketext::Utils::Mock::mock_meth'}, "$type: mock_meth() does not exist before create_method()");
    eval { Locale::Maketext::Utils::Mock->mock_meth() };
    ok( $@, "$type: mock_meth() does not exist before create_method()" );

    my $code = __get_type_val( $type{$type}, 'mock_meth' );
    Locale::Maketext::Utils::Mock->create_method( { 'mock_meth' => $code } );
    ok( defined *{'Locale::Maketext::Utils::Mock::mock_meth'}, "$type: mock_meth() exists after create_method()" );
    is( Locale::Maketext::Utils::Mock->mock_meth(), "$string mock_meth().", "$type: correct code is used 1" );
    is( $mock->mock_meth(),                         "$string mock_meth().", "$type: effects subclass correctly" );

    $code = __get_type_val( $type{$type}, 'mock_meth_x' );
    $mock->create_method( { 'mock_meth_x' => $code } );
    ok( defined *{'Locale::Maketext::Utils::Mock::en::mock_meth_x'}, "$type: create_method() as object class works" );
    is( $mock->mock_meth_x(), "$string mock_meth_x().", "$type: correct code is used 2" );

    $code = __get_type_val( $type{$type}, 'mock_meth_y' );
    Locale::Maketext::Utils::Mock::create_method( { 'mock_meth_y' => $code } );
    ok( defined *{'Locale::Maketext::Utils::Mock::mock_meth_y'}, "$type: create_method() as function class works" );
    is( Locale::Maketext::Utils::Mock->mock_meth_y(), "$string mock_meth_y().", "$type: code is used 3" );

    $code = __get_type_val( $type{$type}, 'class_specific_meth' );
    Locale::Maketext::Utils::Mock::ja->create_method( { 'class_specific_meth' => $code } );
    ok( defined *{'Locale::Maketext::Utils::Mock::ja::class_specific_meth'}, "$type: create_method() under specific class works" );
    is( Locale::Maketext::Utils::Mock::ja->mock_meth_y(), "$string mock_meth_y().", "$type: code is used 4" );

    undef *{'Locale::Maketext::Utils::Mock::mock_meth'};
    undef *{'Locale::Maketext::Utils::Mock::en::mock_meth_x'};
    undef *{'Locale::Maketext::Utils::Mock::mock_meth_y'};
    undef *{'Locale::Maketext::Utils::Mock::ja::class_specific_meth'};
}

sub __get_type_val {
    return if !defined $_[0];
    my $out = "Custom $_[1]().";
    return sub { return $out };
}
