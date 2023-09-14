#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

BEGIN {
    use_ok 'JIP::Spy::Events';
}

subtest 'Require some module' => sub {
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
    my $sut = JIP::Spy::Events->new();
    ok $sut, 'got instance of JIP::Spy::Events';

    isa_ok $sut, 'JIP::Spy::Events';

    can_ok $sut, qw(
        new
        events
        times
        want_array
        skip_methods
        clear
        on_spy_event
        _handle_event
    );

    is_deeply $sut->events(), [];
    is_deeply $sut->times(),        {};
    is_deeply $sut->on_spy_event(), {};

    is $sut->want_array(), 0;
};

subtest '_handle_event' => sub {
    my $sut = JIP::Spy::Events->new();

    my $result = $sut->_handle_event(
        method_name => 'tratata',
        arguments   => ['42'],
        want_array  => 1,
    );

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => ['42'],
        },
    ];

    is_deeply $sut->times(), { tratata => 1 };

    is $result, $sut;
};

subtest 'AUTOLOAD() as class method' => sub {
    eval { JIP::Spy::Events->AUTOLOAD } or do {
        like $EVAL_ERROR, qr{
            ^
            Can't \s call \s "AUTOLOAD" \s as \s a \s class \s method
        }x;
    };
};

subtest 'AUTOLOAD()' => sub {
    my $sut = JIP::Spy::Events->new();

    {
        $sut->tratata();

        is_deeply $sut->events(), [
            {
                method    => 'tratata',
                arguments => [],
            },
        ];

        is_deeply $sut->times(), { tratata => 1 };
    }

    {
        my $result = $sut->tratata('42');

        is_deeply $sut->events(), [
            {
                method    => 'tratata',
                arguments => [],
            },
            {
                method    => 'tratata',
                arguments => ['42'],
            },
        ];

        is_deeply $sut->times(), { tratata => 2 };

        is_deeply $result, $sut;
    }

    {
        my @results = $sut->tratata('100500');

        is_deeply $sut->events(), [
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

        is_deeply $sut->times(), { tratata => 3 };

        is_deeply \@results, [$sut];
    }
};

subtest 'AUTOLOAD() with want_array' => sub {
    my $sut = JIP::Spy::Events->new( want_array => 1 );

    is $sut->want_array(), 1;

    {
        $sut->tratata();

        is_deeply $sut->events(), [
            {
                method     => 'tratata',
                arguments  => [],
                want_array => undef,
            },
        ];

        is_deeply $sut->times(), { tratata => 1 };
    }

    {
        my $result = $sut->tratata('42');

        is_deeply $sut->events(), [
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

        is_deeply $sut->times(), { tratata => 2 };

        is_deeply $result, $sut;
    }

    {
        my @results = $sut->tratata('100500');

        is_deeply $sut->events(), [
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

        is_deeply $sut->times(), { tratata => 3 };

        is_deeply \@results, [$sut];
    }
};

subtest 'AUTOLOAD() with skip_methods' => sub {
    my $sut = JIP::Spy::Events->new(
        skip_methods => [qw(tratata)],
    );

    is_deeply $sut->skip_methods(), { tratata => undef };

    is $sut->tratata(), $sut;
    is $sut->ololo(),   $sut;

    is_deeply $sut->events(), [
        {
            method    => 'ololo',
            arguments => [],
        },
    ];

    is_deeply $sut->times(), { ololo => 1 };
};

subtest 'clear()' => sub {
    my $sut = JIP::Spy::Events->new();

    $sut->tratata->clear();

    is_deeply $sut->events(), [];
    is_deeply $sut->times(), {};
};

subtest 'on_spy_event' => sub {
    my $sut = JIP::Spy::Events->new();

    $sut->on_spy_event(
        tratata => 'not a callback',
    );

    eval { $sut->tratata() } or do {
        like $EVAL_ERROR, qr{
            ^
            "tratata" \s is \s not \s a \s callback
        }x;
    };

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => [],
        },
    ];

    is_deeply $sut->times(), { tratata => 1 };

    $sut->clear();

    $sut->on_spy_event(
        tratata => sub {
            my ( $spy, $event ) = @ARG;

            is $spy, $sut;

            is $event->method(),     'tratata';
            is $event->want_array(), q{};
            is $event->times(),      1;

            is_deeply $event->arguments(), ['42'];

            return '100500';
        },
    );

    my $result = $sut->tratata('42');

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => ['42'],
        },
    ];

    is_deeply $sut->times(), { tratata => 1 };

    is $result, '100500';
};

subtest 'called()' => sub {
    my $sut = JIP::Spy::Events->new();

    is $sut->called(), 0;

    $sut->tratata();

    is $sut->called(), 1;
};

subtest 'not_called()' => sub {
    my $sut = JIP::Spy::Events->new();

    is $sut->not_called(), 1;

    $sut->tratata();

    is $sut->not_called(), 0;
};

done_testing();
