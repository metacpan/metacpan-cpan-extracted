use strict;
use warnings FATAL => 'all';
use utf8;

use Test::Mock::Guard qw/mock_guard/;

use lib '.';
use t::Util;
use HTTP::Command::Wrapper;

subtest basic => sub {
    my $guard_wrapper = mock_guard('HTTP::Command::Wrapper', {
        _detect_type => undef,
    });

    subtest curl => sub {
        isa_ok(
            HTTP::Command::Wrapper->create('curl'),
            'HTTP::Command::Wrapper::Curl'
        );

        my $curl = HTTP::Command::Wrapper->create('curl', { foo => 'bar' });
        isa_ok $curl, 'HTTP::Command::Wrapper::Curl';
        is $curl->{opt}->{foo}, 'bar';

        is $guard_wrapper->call_count('HTTP::Command::Wrapper', '_detect_type'), 0;
    };

    subtest wget => sub {
        isa_ok(
            HTTP::Command::Wrapper->create('wget'),
            'HTTP::Command::Wrapper::Wget'
        );

        my $wget = HTTP::Command::Wrapper->create('wget', { foo => 'bar' });
        isa_ok $wget, 'HTTP::Command::Wrapper::Wget';
        is $wget->{opt}->{foo}, 'bar';

        is $guard_wrapper->call_count('HTTP::Command::Wrapper', '_detect_type'), 0;
    };
};

subtest detect => sub {
    subtest curl => sub {
        my $guard_wrapper = mock_guard('HTTP::Command::Wrapper', {
            _detect_type => 'curl',
        });

        isa_ok(
            HTTP::Command::Wrapper->create,
            'HTTP::Command::Wrapper::Curl'
        );

        my $curl = HTTP::Command::Wrapper->create({ foo => 'bar' });
        isa_ok $curl, 'HTTP::Command::Wrapper::Curl';
        is $curl->{opt}->{foo}, 'bar';

        is $guard_wrapper->call_count('HTTP::Command::Wrapper', '_detect_type'), 2;
    };

    subtest wget => sub {
        my $guard_wrapper = mock_guard('HTTP::Command::Wrapper', {
            _detect_type => 'wget',
        });

        isa_ok(
            HTTP::Command::Wrapper->create,
            'HTTP::Command::Wrapper::Wget'
        );

        my $wget = HTTP::Command::Wrapper->create({ foo => 'bar' });
        isa_ok $wget, 'HTTP::Command::Wrapper::Wget';
        is $wget->{opt}->{foo}, 'bar';

        is $guard_wrapper->call_count('HTTP::Command::Wrapper', '_detect_type'), 2;
    };
};

subtest invalid => sub {
    dies_ok { HTTP::Command::Wrapper->create('invalid') };
};

done_testing;
