#!/usr/bin/perl
use Syntax::Construct qw{ // };
use Test::Spec;
use Test::Exception;

use Karel::Util qw{ positive_int m_to_n };

describe positive_int => sub {
    describe 'accepts' => sub {
        it one => sub {
            ok positive_int(1);
        };
    };

    describe 'rejects' => sub {

        my %failures = ( zero  => 0,
                         float => 1.5,
                         undef => undef,
                       );
        while (my ($name, $number) = each %failures) {
            it $name => sub {
                dies_ok { positive_int($number) };
            };
        }
    };
};

describe m_to_n => sub {
    describe confirms => sub {
        for my $triple ( [ 2, 1, 3 ],
                         [ 2, 2, 3 ],
                         [ 3, 2, 3 ],
                       ) {
            it join (' <= ', @$triple[ 1, 0, 2 ]) => sub {
                ok m_to_n(@$triple);
            };
        }
    };

    describe rejects => sub {
        for my $triple ( [ 3, 1, 2 ],
                         [ 1, 2, 3 ],
                         [ 0, 1, 2 ],
                         [ 1.5, 1, 2 ],
                         [ undef, 0, 1 ],
                       ) {
            it join(' <= ', map $_ // 'undef', @$triple[ 1, 0, 2 ]) => sub {
                dies_ok { m_to_n(@$triple) };
            };
        }
    };
};

runtests();
