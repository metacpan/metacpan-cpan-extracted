#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

plan tests => 9;

use_ok 'JIP::Spy::Events', 'v0.0.1';

subtest 'Require some module' => sub {
    plan tests => 1;

    require_ok 'JIP::Spy::Events';

    diag(
        sprintf(
            'Testing JIP::Spy::Events %s, Perl %s, %s',
            $JIP::Spy::Events::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'new()' => sub {
    plan tests => 7;

    my $o = JIP::Spy::Events->new;
    ok $o, 'got instance of JIP::Spy::Events';

    isa_ok $o, 'JIP::Spy::Events';

    can_ok $o, qw(
        new
        events
        times
        want_array
        clear
        on_spy_event
        _handle_event
    );

    is_deeply $o->events,       [];
    is_deeply $o->times,        {};
    is_deeply $o->on_spy_event, {};

    is $o->want_array, 0;
};

subtest '_handle_event' => sub {
    plan tests => 3;

    my $o = JIP::Spy::Events->new;

    my $result = $o->_handle_event(
        method_name => 'tratata',
        arguments   => ['42'],
        want_array  => 1,
    );

    is_deeply $o->events, [
        {
            method     => 'tratata',
            arguments  => ['42'],
        },
    ];

    is_deeply $o->times, {
        tratata => 1,
    };

    is $result, $o;
};

subtest 'AUTOLOAD() as class method' => sub {
    plan tests => 1;

    eval { JIP::Spy::Events->AUTOLOAD } or do {
        like $EVAL_ERROR, qr{
            ^
            Can't \s call \s "AUTOLOAD" \s as \s a \s class \s method
        }x;
    };
};

subtest 'AUTOLOAD()' => sub {
    plan tests => 8;

    my $o = JIP::Spy::Events->new;

    {
        $o->tratata;

        is_deeply $o->events, [
            {
                method    => 'tratata',
                arguments => [],
            },
        ];

        is_deeply $o->times, {
            tratata => 1,
        };
    }

    {
        my $result = $o->tratata('42');

        is_deeply $o->events, [
            {
                method    => 'tratata',
                arguments => [],
            },
            {
                method    => 'tratata',
                arguments => ['42'],
            },
        ];

        is_deeply $o->times, {
            tratata => 2,
        };

        is_deeply $result, $o;
    }

    {
        my @results = $o->tratata('100500');

        is_deeply $o->events, [
            {
                method    => 'tratata',
                arguments => [],
            },
            {
                method    => 'tratata',
                arguments => ['42'],
            },
            {
                method    => 'tratata',
                arguments => ['100500'],
            },
        ];

        is_deeply $o->times, {
            tratata => 3,
        };

        is_deeply \@results, [$o];
    }
};

subtest 'AUTOLOAD() with want_array' => sub {
    plan tests => 9;

    my $o = JIP::Spy::Events->new(want_array => 1);

    is $o->want_array, 1;

    {
        $o->tratata;

        is_deeply $o->events, [
            {
                method     => 'tratata',
                arguments  => [],
                want_array => undef,
            },
        ];

        is_deeply $o->times, {
            tratata => 1,
        };
    }

    {
        my $result = $o->tratata('42');

        is_deeply $o->events, [
            {
                method     => 'tratata',
                arguments  => [],
                want_array => undef,
            },
            {
                method     => 'tratata',
                arguments  => ['42'],
                want_array => q{},
            },
        ];

        is_deeply $o->times, {
            tratata => 2,
        };

        is_deeply $result, $o;
    }

    {
        my @results = $o->tratata('100500');

        is_deeply $o->events, [
            {
                method     => 'tratata',
                arguments  => [],
                want_array => undef,
            },
            {
                method     => 'tratata',
                arguments  => ['42'],
                want_array => q{},
            },
            {
                method     => 'tratata',
                arguments  => ['100500'],
                want_array => 1,
            },
        ];

        is_deeply $o->times, {
            tratata => 3,
        };

        is_deeply \@results, [$o];
    }
};

subtest 'clear()' => sub {
    plan tests => 2;

    my $o = JIP::Spy::Events->new;

    $o->tratata->clear;

    is_deeply $o->events, [];
    is_deeply $o->times,  {};
};

subtest 'on_spy_event' => sub {
    plan tests => 11;

    my $o = JIP::Spy::Events->new;

    $o->on_spy_event(
        tratata => 'not a callback',
    );

    eval { $o->tratata } or do {
        like $EVAL_ERROR, qr{
            ^
            "tratata" \s is \s not \s a \s callback
        }x;
    };

    is_deeply $o->events, [
        {
            method     => 'tratata',
            arguments  => [],
        },
    ];

    is_deeply $o->times, {
        tratata => 1,
    };

    $o->clear;

    $o->on_spy_event(
        tratata => sub {
            my ($spy, $event) = @ARG;

            is $spy, $o;

            is $event->method,     'tratata';
            is $event->want_array, q{};
            is $event->times,      1;

            is_deeply $event->arguments, ['42'];

            return '100500';
        },
    );

    my $result = $o->tratata('42');

    is_deeply $o->events, [
        {
            method    => 'tratata',
            arguments => ['42'],
        },
    ];

    is_deeply $o->times, {
        tratata => 1,
    };

    is $result, '100500';
};
