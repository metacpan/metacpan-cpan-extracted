#!/usr/bin/perl -w

use Test::More;
use Test::MockRandom 'Libravatar::URL';

BEGIN { use_ok 'Net::DNS';
        use_ok 'Libravatar::URL'; }

{
    my @email_domain_tests = (
        ['',
         undef,
        ],

        ['notanemail',
         undef,
        ],

        ['larry@example.com',
         'example.com',
        ],

        ['larry@example.com@example.org',
         'example.org',
        ],

        ['@example.org',
         'example.org',
        ],

        ['larry@@example.com',
         'example.com',
        ],
    );

    for my $test (@email_domain_tests) {
        my ($email, $domain) = @$test;
        is Libravatar::URL::email_domain($email), $domain;
    }

    my @openid_domain_tests = (
        ['',
         undef,
        ],

        ['notanopenid',
         undef,
        ],

        ['http://example.com',
         'example.com',
        ],

        ['https://a.example.com',
         'a.example.com',
        ],

        ['http://b.example.com/',
         'b.example.com',
        ],

        ['http://example.org/id/larry',
         'example.org',
        ],

        ['https://a.example.org/~larry/openid.html',
         'a.example.org',
        ],
    );

    for my $test (@openid_domain_tests) {
        my ($openid, $domain) = @$test;
        is Libravatar::URL::openid_domain($openid), $domain;
    }

    my @lowercase_openid = (
        ['',
         '',
        ],

        ['notanopenid',
         'notanopenid',
        ],

        ['http://Example.Com',
         'http://example.com',
        ],

        ['HTTPS://a.example.com',
         'https://a.example.com',
        ],

        ['http://b.eXample.com/',
         'http://b.example.com/',
        ],

        ['http://example.ORG/ID/Larry',
         'http://example.org/ID/Larry',
        ],

        ['Https://A.example.org/~Larry/OpenID.html',
         'https://a.example.org/~Larry/OpenID.html',
        ],
    );

    for my $test (@lowercase_openid) {
        my ($openid, $lc_openid) = @$test;
        is Libravatar::URL::lowercase_openid($openid), $lc_openid;
    }

    my @url_tests = (
        [undef, undef,
         undef,
        ],

        ['example.com', undef,
         'http://example.com/avatar',
        ],

        ['example.com', 80,
         'http://example.com/avatar',
        ],

        ['example.com', 81,
         'http://example.com:81/avatar',
        ],
    );

    for my $test (@url_tests) {
        my ($target, $port, $url) = @$test;
        is Libravatar::URL::build_url($target, $port), $url;
    }

    my @sanitization_tests = (
        [undef, undef,
         [undef, undef],
        ],

        ['example.com', undef,
         [undef, undef],
        ],

        ['example.com', 80,
         ['example.com', 80],
        ],

        ['example.org', 81,
         ['example.org', 81],
        ],
    );

    for my $test (@sanitization_tests) {
        my ($target, $port, $pair) = @$test;
        my @result = Libravatar::URL::sanitize_target($target, $port);
        is_deeply \@result, $pair;
    }

    my @srv_tests = (
        [[
         ],
         [undef, undef],
        ],

        [['_avatars._tcp.example.com. IN SRV 0 0 80 avatars.example.com',
         ],
         ['avatars.example.com', 80],
        ],

        [['_avatars._tcp.example.com. IN SRV 10 0 81 avatars2.example.com',
          '_avatars._tcp.example.com. IN SRV 0 0 80 avatars.example.com',
         ],
         ['avatars.example.com', 80],
        ],

        [['_avatars._tcp.example.com. IN SRV 10 0 83 avatars4.example.com',
          '_avatars._tcp.example.com. IN SRV 10 0 82 avatars3.example.com',
          '_avatars._tcp.example.com. IN SRV 1 0 81 avatars21.example.com',
          '_avatars._tcp.example.com. IN SRV 10 0 80 avatars.example.com',
         ],
         ['avatars21.example.com', 81],
        ],

        # The following ones are randomly selected which is why we
        # have to initialize the random number to a canned value

        # random_number = 49
        [['_avatars._tcp.example.com. IN SRV 10 1 83 avatars4.example.com',
          '_avatars._tcp.example.com. IN SRV 10 5 82 avatars3.example.com',
          '_avatars._tcp.example.com. IN SRV 10 10 8100 avatars2.example.com',
          '_avatars._tcp.example.com. IN SRV 10 50 800 avatars1.example.com',
          '_avatars._tcp.example.com. IN SRV 20 0 80 avatars.example.com',
         ],
         ['avatars1.example.com', 800],
        ],

        # random_number = 0
        [['_avatars._tcp.example.com. IN SRV 10 1 83 avatars4.example.com',
          '_avatars._tcp.example.com. IN SRV 10 0 82 avatars3.example.com',
          '_avatars._tcp.example.com. IN SRV 20 0 81 avatars2.example.com',
          '_avatars._tcp.example.com. IN SRV 20 0 80 avatars.example.com',
         ],
         ['avatars3.example.com', 82],
        ],

        # random_number = 1
        [['_avatars._tcp.example.com. IN SRV 10 0 83 avatars4.example.com',
          '_avatars._tcp.example.com. IN SRV 10 0 82 avatars3.example.com',
          '_avatars._tcp.example.com. IN SRV 10 10 601 avatars20.example.com',
          '_avatars._tcp.example.com. IN SRV 20 0 80 avatars.example.com',
         ],
         ['avatars20.example.com', 601],
        ],

        # random_number = 40
        [['_avatars._tcp.example.com. IN SRV 10 1 83 avatars4.example.com',
          '_avatars._tcp.example.com. IN SRV 10 5 82 avatars3.example.com',
          '_avatars._tcp.example.com. IN SRV 10 10 8100 avatars2.example.com',
          '_avatars._tcp.example.com. IN SRV 10 30 8 avatars10.example.com',
          '_avatars._tcp.example.com. IN SRV 10 50 800 avatars1.example.com',
          '_avatars._tcp.example.com. IN SRV 20 0 80 avatars.example.com',
         ],
         ['avatars10.example.com', 8],
        ],
    );

    srand(0.74,0,0.1,0.42); # to make these tests predictable

    for my $test (@srv_tests) {
        my ($srv_strings, $pair) = @$test;

        my @srv_records = ();
        for $str (@$srv_strings) {
            my $record = Net::DNS::RR->new($str);
            push @srv_records, $record;
        }

        my @result = Libravatar::URL::srv_hostname(@srv_records);

        is_deeply \@result, $pair;
    }

    $test_count = @email_domain_tests + @openid_domain_tests + @lowercase_openid + @url_tests + @sanitization_tests + @srv_tests + 2;
    done_testing($test_count);
}
