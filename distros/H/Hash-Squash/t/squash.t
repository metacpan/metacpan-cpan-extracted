use strict;
use warnings;
use Test::More;

use_ok 'Hash::Squash' => 'squash', 'unnumber';

subtest squash => sub {
    my $hash = +{
        code => '200',
        subcode => '0',
        result => 'text goes here',
        time => '26.5',
        data => +{
            foo => +{
                '0' => '10000',
            },
            bar => +{
                '0' => '0',
            },
            buz => +{
                '0' => '10',
            },
            items => +{
                '0'  => 'example.com',
                '1'  => 'example.org',
                '2'  => 'example.net',
                '3'  => 'foobar.com',
                '4'  => 'buzhoge.com',
                '5'  => 'example.biz',
                '6'  => 'example.biz',
                '7'  => '0123456789.com',
                '8'  => 'example.jp',
                '9'  => 'example.cn',
                '10' => 'example.tw',
            },
            missing => +{
                '0'  => 'example.com',
                '1'  => 'example.org',
                '2'  => 'example.net',
                '3'  => 'foobar.com',
                '4'  => 'buzhoge.com',
                '5'  => 'example.biz',
                # oops!
                '7'  => '0123456789.com',
                '8'  => 'example.jp',
                '9'  => 'example.cn',
                '10' => 'example.tw',
            },
            empty_array => [],
            empty_hash => +{},
            nest => +{
                nest => +{
                    nest => +{
                        nest => 'nest',
                    },
                },
            },
        },
    };

    is_deeply squash($hash), +{
        code => '200',
        subcode => '0',
        result => 'text goes here',
        time => '26.5',
        data => +{
            foo => '10000',
            bar => '0',
            buz => '10',
            items => [
                'example.com',
                'example.org',
                'example.net',
                'foobar.com',
                'buzhoge.com',
                'example.biz',
                'example.biz',
                '0123456789.com',
                'example.jp',
                'example.cn',
                'example.tw',
            ],
            missing => [
                'example.com',
                'example.org',
                'example.net',
                'foobar.com',
                'buzhoge.com',
                'example.biz',
                undef,
                '0123456789.com',
                'example.jp',
                'example.cn',
                'example.tw',
            ],
            empty_array => undef,
            empty_hash => undef,
            nest => +{
                nest => +{
                    nest => +{
                        nest => 'nest',
                    },
                },
            },
        },
    };
};

subtest unnumber => sub {
    my $hash = unnumber(+{
        foo => +{
            '0' => 'numbered',
            '1' => 'hash',
            '2' => 'structures',
        },
        bar => +{
            '0' => 'obviously a single value',
        },
        buz => [
            +{
                nest => +{
                    '0' => 'nested',
                    '2' => 'partial',
                    '3' => 'array',
                },
            },
        ],
        empty_hash  => +{},
        empty_array => [],
        nest => [
            nest => [
                nest => [
                    undef
                ],
            ],
        ],
    });

    is_deeply $hash, +{
        foo => [
            'numbered',
            'hash',
            'structures',
        ],
        bar => ['obviously a single value'],
        buz => [
            +{
                nest => [
                    'nested',
                    undef,
                    'partial',
                    'array',
                ],
            },
        ],
        empty_hash  => +{},
        empty_array => [],
        nest => [
            nest => [
                nest => [
                    undef
                ],
            ],
        ],
    };
};

subtest synopsis => sub {
    my $hash = squash(+{
        foo => +{
            '0' => 'numbered',
            '1' => 'hash',
            '2' => 'structures',
        },
        bar => +{
            '0' => 'obviously a single value',
        },
        buz => [
            +{
                nest => +{
                    '0' => 'nested',
                    '2' => 'partial',
                    '3' => 'array',
                },
            },
            +{
                nest => +{
                    '0' => 'FOO',
                    '1' => 'BAR',
                    '2' => 'BUZ',
                },
            },
        ],
    });

    is_deeply $hash, +{
        foo => [
            'numbered',
            'hash',
            'structures',
        ],
        bar => 'obviously a single value',
        buz => [
            +{
                nest => [
                    'nested',
                    undef,
                    'partial',
                    'array',
                ],
            },
            +{
                nest => [
                    'FOO',
                    'BAR',
                    'BUZ',
                ],
            },
        ],
    };
};

done_testing();
