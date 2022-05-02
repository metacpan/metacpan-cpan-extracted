#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'tests' => 22;
use Test::Fatal qw< exception >;
use Lib::PWQuality;

can_ok(
    Lib::PWQuality::,
    qw<
        new
        _default_settings
        _free_settings
        check
        generate
        read_config
        set_option
        set_str_value
        set_int_value
        get_str_value
        get_int_value
        _strerror
    >,
);

my $pwq = Lib::PWQuality->new();
isa_ok( $pwq, 'Lib::PWQuality' );

my $min_len = $pwq->get_int_value('MIN_LENGTH');
ok(
    $min_len < 10,
    "Default MIN_LENGTH is under 10 ($min_len)",
);

is(
    $pwq->set_option('minlen=10'),
    'SUCCESS',
    'set_option(minlen=10) works',
);

is(
    $pwq->get_int_value('MIN_LENGTH'),
    10, ## no critic
    'New MIN_LENGTH set correctly',
);

is(
    $pwq->get_int_value('MAX_REPEAT'),
    0,
    'MAX_REPEAT default is 0',
);

is(
    $pwq->set_int_value( 'MAX_REPEAT', 1 ),
    'SUCCESS',
    'set_int_value(MAX_REPEAT,1) works',
);

is(
    $pwq->get_int_value('MAX_REPEAT'),
    1,
    'MAX_REPEAT set to 1',
);

is(
    $pwq->get_str_value('BAD_WORDS'),
    undef,
    'BAD_WORDS default is empty',
);

is(
    $pwq->set_str_value( 'BAD_WORDS', 'foo' ),
    'SUCCESS',
    'set_str_value(BAD_WORDS,foo) works',
);

is(
    $pwq->get_str_value('BAD_WORDS'),
    'foo',
    'BAD_WORDS set to foo',
);

is(
    $pwq->settings->bad_words(),
    'foo',
    'bad_words setting is now foo',
);

{
    my $settings  = $pwq->settings();
    my $bad_words = $settings->{'bad_words'};

    is(
        $settings->{'bad_words'},
        'foo',
        'bad_words attribute set',
    );

    $settings->{'bad_words'} = 'bar';
    is(
        $settings->bad_words(),
        'bar',
        'bad_words attribute retrieval works',
    );

    my $dict_path = $settings->{'dict_path'};
    is( $dict_path, undef, 'Undefined dict_path attribute' );

    $pwq->set_value( 'DICT_PATH' => '/path' );

    my $path = $settings->dict_path();
    ok( exists $settings->{'dict_path'}, 'dict_path attribute created' );
    is(
        $settings->{'dict_path'},
        '/path',
        "dict_path attribute correct value: $path",
    );
}

like(
    exception( sub { $pwq->set_option('foo=bar') } ),
    qr/^\QUnrecognized option: 'foo'\E/xms,
    'Cannot set_option to non-supported key',
);

like(
    exception( sub { $pwq->set_int_value('foo', 'bar') } ),
    qr/^\QUnrecognized value: 'foo'\E/xms,
    'Cannot set_int_value to non-supported key',
);

like(
    exception( sub { $pwq->set_str_value('foo', 'bar') } ),
    qr/^\QUnrecognized value: 'foo'\E/xms,
    'Cannot set_str_value to non-supported key',
);

like(
    exception( sub { $pwq->get_int_value('foo') } ),
    qr/^\QUnrecognized value: 'foo'\E/xms,
    'Cannot get_int_value to non-supported key',
);

like(
    exception( sub { $pwq->get_str_value('foo') } ),
    qr/^\QUnrecognized value: 'foo'\E/xms,
    'Cannot get_str_value to non-supported key',
);

