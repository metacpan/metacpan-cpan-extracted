#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny;

package MyApp::Test {
    use FormValidator::Tiny;
    our $lexical = validation_spec edit => [];
}

is $MyApp::Test::FORM_VALIDATOR_TINY_SPECIFICATION, {
    edit => [],
}, 'validation_spec sets the expected variable';
isa_ok $MyApp::Test::FORM_VALIDATOR_TINY_SPECIFICATION->{edit},
    'FormValidator::Tiny';
is $MyApp::Test::FORM_VALIDATOR_TINY_SPECIFICATION->{edit},
   $MyApp::Test::lexical, 'lexical is the same as internal global';

validation_spec 'MyApp::Test::another_edit' => [];

is $MyApp::Test::FORM_VALIDATOR_TINY_SPECIFICATION, {
    edit => [],
    another_edit => [],
}, 'validation_spec sets the expected variable';
isa_ok $MyApp::Test::FORM_VALIDATOR_TINY_SPECIFICATION->{another_edit},
    'FormValidator::Tiny';

like dies {
        validation_spec [];
    }, qr/useless call to validation_spec/,
    'dies when call is useless';

my $t;
like dies {
        $t = validation_spec {};
    }, qr/must be an array/,
    'dies when called with hash';

like dies {
        $t = validation_spec [
            name => [],
            name => [],
        ]
    }, qr/has been defined twice/,
    'dies when field mentioned twice';

like dies {
        $t = validation_spec [
            name => {},
        ]
    }, qr/must be in an array/,
    'dies when field decl is hash';

like dies {
        $t = validation_spec [
            'name',
        ],
    }, qr/odd number of elements/,
    'dies when odd number of elements in spec';

like dies {
        $t = validation_spec [
            'name' => [ 'must' ],
        ],
    }, qr/odd number of elements/,
    'dies when odd number of elements in decl';

subtest "$_ exceptions" => sub {
    like dies {
            $t = validation_spec [
                name => [
                    must => qr/./,
                    $_   => 1,
                ]
            ]
        }, qr/found \[$_\] after filter or validation/,
        "dies when $_ is mentioned late";

    like dies {
            $t = validation_spec [
                name => [
                    $_ => 1,
                    $_ => 0,
                ]
            ]
        }, qr/has more than one \[$_\]/,
        "dies when $_ is set twice";

} for qw( from multiple trim );

like dies {
        $t = validation_spec [
            name => [
                $_ => 1,
            ],
        ]
    }, qr/has unknown \[$_] declaration argument \[1]/,
    "dies when bad argument is given to $_"
    for qw( must each_must key_must value_must );

like dies {
        $t = validation_spec [
            name => [
                $_ => 1,
            ],
        ]
    }, qr/has unknown \[$_] declaration argument \[1]/,
    "dies when bad argument is given to $_"
    for qw( into each_into key_into value_into );

like dies {
        $t = validation_spec [
            name => [
                with_error => 'foo',
            ],
        ]
    }, qr/has \[with_error] before/,
    "dies when with_error is used toos oon";

like dies {
        $t = validation_spec [
            name => [
                weeble => 1,
            ],
        ]
    }, qr/has unknown \[weeble]/,
    "dies with unknown op";

done_testing;
