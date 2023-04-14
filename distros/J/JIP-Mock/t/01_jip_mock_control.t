#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

BEGIN {
    use_ok 'JIP::Mock::Control';
}

## no critic (TestingAndDebugging::RequireTestLabels)

use constant ORIGINAL_ANSWER => 42;
use constant NEW_ANSWER      => reverse ORIGINAL_ANSWER;

package TestMe;

use strict;
use warnings;

use English qw(-no_match_vars);

sub new {
    my ($class) = @ARG;

    return bless {}, $class;
}

sub tratata {
    return main->ORIGINAL_ANSWER;
}

package main;

subtest 'Require some module' => sub {
    require_ok 'JIP::Mock::Control';

    diag(
        sprintf(
            'Testing JIP::Mock::Control %s, Perl %s, %s',
            $JIP::Mock::Control::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'new() when package is not present' => sub {
    my @cases = (
        {
            args  => [],
            error => qr{Cannot instantiate: package name is not present!},
            name  => 'parameter is not exists',
        },
        {
            args  => [ package => undef ],
            error => qr{Cannot instantiate: package name is not present!},
            name  => 'parameter is not defined',
        },
        {
            args  => [ package => q{} ],
            error => qr{Cannot instantiate: package name is not present!},
            name  => 'parameter is empty',
        },
    );

    foreach my $case (@cases) {
        eval {
            JIP::Mock::Control->new( @{ $case->{args} } );

            return;
        };

        like $EVAL_ERROR, $case->{error}, $case->{name};
    }
};

subtest 'new() when package is not loaded' => sub {
    eval {
        JIP::Mock::Control->new( package => 'PackageNameIsNotLoaded' );

        return;
    };

    like $EVAL_ERROR, qr{
        ^
        Cannot \s instantiate:
        \s
        package \s "PackageNameIsNotLoaded" \s is \s not \s loaded!
    }x;
};

subtest 'new()' => sub {
    my $sut = init_sut();

    ok $sut, 'got instance of JIP::Mock::Control';

    isa_ok $sut, 'JIP::Mock::Control';

    can_ok $sut, qw(
        new
        package
        times
        events
        want_array
        override
    );
};

subtest 'override() when arguments are not present' => sub {
    my $sut = init_sut();

    is $sut->override(), undef;
};

subtest 'override() when validation failed' => sub {
    my @cases = (
        {
            args  => [ q{} => undef ],
            error => qr{^Cannot \s override: \s name \s is \s not \s present!}x,
            name  => 'sub name is not present',
        },
        {
            args  => [ q{SubNameIsNotImplemented} => undef ],
            error => qr{
                ^
                Cannot \s override:
                \s
                cannot \s override \s non-existent \s sub \s "SubNameIsNotImplemented"!
            }x,
            name => 'sub is not implemented in package TestMe',
        },
        {
            args  => [ tratata => undef ],
            error => qr{
                ^
                Cannot \s override:
                \s
                new \s sub \s of \s "tratata" \s is \s not \s present!
            }x,
            name => 'Replacement of "tratata" is not defined',
        },
        {
            args  => [ tratata => q{} ],
            error => qr{
                ^
                Cannot \s override:
                \s
                new \s sub \s of \s "tratata" \s is \s not \s present!
            }x,
            name => 'Replacement of "tratata" is an empty string',
        },
        {
            args  => [ tratata => {} ],
            error => qr{
                ^
                Cannot \s override:
                \s
                new \s sub \s of \s "tratata" \s is \s not \s CODE \s reference!
            }x,
            name => 'Replacement of "tratata" is not CODE reference',
        },
    );

    foreach my $case (@cases) {
        my $sut = init_sut();

        eval {
            $sut->override( @{ $case->{args} } );

            return;
        };

        like $EVAL_ERROR, $case->{error}, $case->{name};
    }
};

subtest 'override() when applied to module' => sub {
    my $sut = init_sut();

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    is TestMe::tratata(), NEW_ANSWER;
};

subtest 'override() when applied to class' => sub {
    my $test_me = TestMe->new();

    my $sut = init_sut();

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    is $test_me->tratata(), NEW_ANSWER;
};

subtest 'DESTROY() when applied to module' => sub {
    {
        my $sut = init_sut();

        $sut->override(
            tratata => sub {
                pass 'tratata()';

                return NEW_ANSWER;
            },
        );
    }

    is TestMe::tratata(), ORIGINAL_ANSWER;
};

subtest 'DESTROY() when applied to class' => sub {
    my $test_me = TestMe->new();

    {
        my $sut = init_sut();

        $sut->override(
            tratata => sub {
                pass 'tratata()';

                return NEW_ANSWER;
            },
        );
    }

    is $test_me->tratata(), ORIGINAL_ANSWER;
};

subtest 'times()' => sub {
    my $test_me = TestMe->new();

    $test_me->tratata();

    my $sut = init_sut();

    is_deeply $sut->times(), {};

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    $test_me->tratata();

    is_deeply $sut->times(), { tratata => 1 };

    $test_me->tratata();

    is_deeply $sut->times(), { tratata => 2 };
};

subtest 'events() when applied to class' => sub {
    my $sut = init_sut();

    is_deeply $sut->events(), [];

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    my $tratata = 'tratata';

    TestMe::tratata($tratata);

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => [$tratata],
        },
    ];

    my $ololo = 'ololo';

    TestMe::tratata( $tratata, $ololo );

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => [$tratata],
        },
        {
            method    => 'tratata',
            arguments => [ $tratata, $ololo ],
        },

    ];
};

subtest 'events() when applied to module' => sub {
    my $test_me = TestMe->new();

    my $sut = init_sut();

    is_deeply $sut->events(), [];

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    my $tratata = 'tratata';

    $test_me->tratata($tratata);

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => [$tratata],
        },
    ];

    my $ololo = 'ololo';

    $test_me->tratata( $tratata, $ololo );

    is_deeply $sut->events(), [
        {
            method    => 'tratata',
            arguments => [$tratata],
        },

        {
            method    => 'tratata',
            arguments => [ $tratata, $ololo ],
        },
    ];
};

subtest 'event when want_array is not present' => sub {
    my $test_me = TestMe->new();

    my $sut = init_sut();

    my $tratata = 'tratata';

    my @arguments;
    $sut->override(
        $tratata => sub {
            @arguments = @ARG;

            pass( $tratata . '()' );

            return NEW_ANSWER;
        },
    );

    $test_me->$tratata($tratata);

    my $event = $arguments[0];

    isa_ok $event, 'JIP::Mock::Event';

    is $event->method(), $tratata;

    is_deeply $event->arguments(), [$tratata];

    is $event->want_array(), undef;

    is $event->times(), 1;
};

subtest 'event when want_array is present' => sub {
    my $test_me = TestMe->new();

    my $want_array = !!1;

    my $sut = init_sut( want_array => $want_array );

    my $tratata = 'tratata';

    my @arguments;
    $sut->override(
        $tratata => sub {
            @arguments = @ARG;

            pass( $tratata . '()' );

            return NEW_ANSWER;
        },
    );

    my @results = $test_me->$tratata($tratata);

    my $event = $arguments[0];

    isa_ok $event, 'JIP::Mock::Event';

    is $event->method(), $tratata;

    is_deeply $event->arguments(), [$tratata];

    is $event->want_array(), $want_array;

    is $event->times(), 1;

    is_deeply $sut->events(), [
        {
            method     => $tratata,
            arguments  => [$tratata],
            want_array => $want_array,
        },
    ];
};

subtest 'list context' => sub {
    my $want_array = !!1;

    my $sut = init_sut( want_array => $want_array );

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    my @results = TestMe::tratata();

    is_deeply \@results, [NEW_ANSWER];

    is_deeply $sut->events(), [
        {
            method     => 'tratata',
            arguments  => [],
            want_array => $want_array,
        },
    ];
};

subtest 'scalar context' => sub {
    my $want_array = !!1;

    my $sut = init_sut( want_array => $want_array );

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    my $result = TestMe::tratata();

    is $result, NEW_ANSWER;

    is_deeply $sut->events(), [
        {
            method     => 'tratata',
            arguments  => [],
            want_array => q{},
        },
    ];
};

subtest 'void context' => sub {
    my $want_array = !!1;

    my $sut = init_sut( want_array => $want_array );

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    TestMe::tratata();

    is_deeply $sut->events(), [
        {
            method     => 'tratata',
            arguments  => [],
            want_array => undef,
        },
    ];
};

subtest 'FizzBuzz example' => sub {
    my $test_me = TestMe->new();

    my $sut = init_sut();

    $sut->override(
        tratata => sub {
            my ($event) = @ARG;

            my $times = $event->times();

            return 'Fizz' if $times % 3 == 0;
            return 'Buzz' if $times % 5 == 0;
            return $times;
        },
    );

    my @results = map { $test_me->tratata() } 1 .. 5;

    is_deeply \@results, [
        1,
        2,
        'Fizz',
        4,
        'Buzz',
    ];

    is_deeply $sut->times(), { tratata => scalar @results };
};

subtest 'call_original() when validation failed' => sub {
    my @cases = (
        {
            args  => [],
            error => qr{Cannot call original: name is not present!},
            name  => 'name is not exists',
        },
        {
            args  => [undef],
            error => qr{Cannot call original: name is not present!},
            name  => 'name is not defined',
        },
        {
            args  => [q{}],
            error => qr{Cannot call original: name is not present!},
            name  => 'name is an empty string',
        },
        {
            args  => ['ololo'],
            error => qr{Cannot call original: cannot find sub "ololo" by name!},
            name  => 'name is unknown',
        },
    );

    foreach my $case (@cases) {
        my $sut = init_sut();

        $sut->override(
            tratata => sub {
                pass 'tratata()';

                return NEW_ANSWER;
            },
        );

        eval {
            $sut->call_original( @{ $case->{args} } );

            return;
        };

        like $EVAL_ERROR, $case->{error}, $case->{name};
    }
};

subtest 'call_original() in void context' => sub {
    my $sut = init_sut();

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    $sut->call_original('tratata');

    is_deeply $sut->times(), {};
    is_deeply $sut->events(), [];
};

subtest 'call_original() in list context' => sub {
    my $sut = init_sut();

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    my @results = $sut->call_original('tratata');

    is_deeply \@results, [ORIGINAL_ANSWER];

    is_deeply $sut->times(), {};
    is_deeply $sut->events(), [];
};

subtest 'call_original() in scalar context' => sub {
    my $sut = init_sut();

    $sut->override(
        tratata => sub {
            pass 'tratata()';

            return NEW_ANSWER;
        },
    );

    my $result = $sut->call_original('tratata');

    is $result, ORIGINAL_ANSWER;

    is_deeply $sut->times(), {};
    is_deeply $sut->events(), [];
};

done_testing();

sub init_sut {
    my %args = @ARG;

    return JIP::Mock::Control->new(
        package => 'TestMe',
        %args,
    );
}
