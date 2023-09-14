#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

## no critic (TestingAndDebugging::RequireTestLabels)
## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

BEGIN {
    plan tests => 13;

    use_ok 'JIP::DataPath';
}

subtest 'Require some module' => sub {
    plan tests => 1;

    require_ok 'JIP::DataPath';

    diag(
        sprintf(
            'Testing JIP::DataPath %s, Perl %s, %s',
            $JIP::DataPath::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'new(). exceptions' => sub {
    plan tests => 2;

    my $done = eval { return JIP::DataPath->new(); };
    if ($EVAL_ERROR) {
        like $EVAL_ERROR, qr{^Mandatory \s argument \s "document" \s is \s missing}x;
    }

    ok !$done;
};

subtest 'new()' => sub {
    plan tests => 4;

    my $sut = init_sut(42);
    ok $sut, 'got instance of JIP::DataPath';

    isa_ok $sut, 'JIP::DataPath';

    can_ok $sut, qw(new get get_new contains set perform path default_value is_default_value);

    is $sut->document(), 42;
};

subtest 'get()' => sub {
    plan tests => 3;

    subtest 'when document is not defined' => sub {
        plan tests => 3;

        my $sut = init_sut(undef);

        is $sut->get( [qw()] ),    undef;
        is $sut->get( [qw(foo)] ), undef;
        is $sut->get( [qw(0)] ),   undef;
    };

    subtest 'when document is defined' => sub {
        plan tests => 6;

        my $document = {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        };

        my $sut = init_sut($document);

        is_deeply $sut->get( [qw()] ),          $document;
        is_deeply $sut->get( [qw(foo)] ),       $document->{foo};
        is_deeply $sut->get( [qw(foo bar)] ),   $document->{foo}->{bar};
        is_deeply $sut->get( [qw(foo bar 0)] ), $document->{foo}->{bar}->[0];

        is $sut->get( [qw(foo bar 0 wtf)] ), $document->{foo}->{bar}->[0]->{wtf};

        # side effects
        is_deeply $document, {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        };
    };

    subtest 'default value' => sub {
        plan tests => 9;

        my $document = { foo => 'bar' };

        my $sut = init_sut($document);

        is_deeply $sut->get( [qw()] ),                        $document;
        is_deeply $sut->get( [qw()], $sut->default_value() ), $document;

        is_deeply $sut->get( [qw(foo)] ),     $document->{foo};
        is_deeply $sut->get( [qw(foo)], 42 ), $document->{foo};

        is_deeply $sut->get( [qw(foo bar)] ),                        undef;
        is_deeply $sut->get( [qw(foo bar)], $sut->default_value() ), $sut->default_value();

        is_deeply $sut->get( [qw(foo bar 0)] ),                        undef;
        is_deeply $sut->get( [qw(foo bar 0)], $sut->default_value() ), $sut->default_value();

        # side effects
        is_deeply $document, { foo => 'bar' };
    };
};

subtest 'get_new()' => sub {
    plan tests => 4;

    subtest 'when document is not defined' => sub {
        plan tests => 4;

        my $document = undef;

        my $sut = init_sut($document)->get_new( [] );

        isa_ok $sut, 'JIP::DataPath';

        is $sut->get( [qw()] ),    undef;
        is $sut->get( [qw(foo)] ), undef;
        is $sut->get( [qw(0)] ),   undef;
    };

    subtest 'when document is defined' => sub {
        plan tests => 4;

        my $document = {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        };

        my $sut = init_sut($document)->get_new( [qw(foo bar)] );

        is_deeply $sut->get( [qw()] ),      $document->{foo}->{bar};
        is_deeply $sut->get( [qw(0)] ),     $document->{foo}->{bar}->[0];
        is_deeply $sut->get( [qw(0 wtf)] ), $document->{foo}->{bar}->[0]->{wtf};

        # side effects
        is_deeply $document, {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        };
    };

    subtest 'when path_parts is empty' => sub {
        plan tests => 3;

        my $document = { foo => 'bar' };

        my $sut = init_sut($document)->get_new( [] );

        isa_ok $sut, 'JIP::DataPath';

        is_deeply $sut->get( [] ),        $document;
        is_deeply $sut->get( [qw(foo)] ), $document->{foo};
    };

    subtest 'default value' => sub {
        plan tests => 3;

        my $document = { foo => 'bar' };

        my $sut = init_sut($document);

        is $sut->get_new( [qw(not exists)] ),     undef;
        is $sut->get_new( [qw(not exists)], 42 ), 42;

        # side effects
        is_deeply $document, { foo => 'bar' };
    };
};

subtest 'contains()' => sub {
    plan tests => 2;

    subtest 'when document is not defined' => sub {
        plan tests => 3;

        my $document = undef;

        my $sut = init_sut($document);

        is $sut->contains( [qw()] ),    1;
        is $sut->contains( [qw(foo)] ), 0;
        is $sut->contains( [qw(0)] ),   0;
    };

    subtest 'when document is defined' => sub {
        plan tests => 6;

        my $document = {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        };

        my $sut = init_sut($document);

        is $sut->contains( [qw()] ),              1;
        is $sut->contains( [qw(foo)] ),           1;
        is $sut->contains( [qw(foo bar)] ),       1;
        is $sut->contains( [qw(foo bar 0)] ),     1;
        is $sut->contains( [qw(foo bar 0 wtf)] ), 1;

        # side effects
        is_deeply $document, {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        };
    };
};

subtest 'set()' => sub {
    plan tests => 2;

    subtest 'when document is not defined' => sub {
        plan tests => 6;

        my $sut = init_sut(undef);

        is $sut->set( [] ),  1;
        is $sut->document(), undef;

        is $sut->set( [], undef ), 1;
        is $sut->document(),       undef;

        is $sut->set( [], 42 ), 1;
        is $sut->document(),    42;
    };

    subtest 'when document is a HASH' => sub {
        plan tests => 10;

        my $sut = init_sut(undef);

        {
            my $result = $sut->set( [], { foo => undef } );
            is $result, 1;

            is_deeply $sut->document(), { foo => undef };
        }
        {
            my $result = $sut->set( [qw(foo)], { bar => undef } );
            is $result, 1;

            is_deeply $sut->document(), {
                foo => {
                    bar => undef,
                },
            };
        }
        {
            my $result = $sut->set( [qw(foo bar)], [] );
            is $result, 1;

            is_deeply $sut->document(), {
                foo => {
                    bar => [],
                },
            };
        }
        {
            my $result = $sut->set( [qw(foo bar)], [ { wtf => undef } ] );
            is $result, 1;

            is_deeply $sut->document(), {
                foo => {
                    bar => [
                        { wtf => undef },
                    ],
                },
            };
        }
        {
            my $result = $sut->set( [qw(foo bar 0)], { wtf => 42 } );
            is $result, 1;

            is_deeply $sut->document(), {
                foo => {
                    bar => [
                        { wtf => 42 },
                    ],
                },
            };
        }
    };
};

subtest 'perform()' => sub {
    plan tests => 4;

    my $sut = init_sut(
        {
            foo => {
                bar => [
                    { wtf => 42 },
                ],
            },
        },
    );

    subtest 'perform get()' => sub {
        plan tests => 3;

        {
            my $result = $sut->perform( 'get', [qw(foo bar 0 wtf)] );
            is $result, 42;
        }
        {
            my $result = $sut->perform( 'get', [qw(tratata)] );
            is $result, undef;
        }
        {
            my $result = $sut->perform( 'get', [qw(tratata)], 42 );
            is $result, 42;
        }
    };

    subtest 'perform set()' => sub {
        plan tests => 1;

        my $result = $sut->perform( 'set', [qw(foo bar 0 wtf)], 100_500 );
        is $result, 1;
    };

    subtest 'perform contains()' => sub {
        plan tests => 1;

        my $result = $sut->perform( 'contains', [qw(foo bar 0 wtf)] );
        is $result, 1;
    };

    is_deeply $sut->document(), {
        foo => {
            bar => [
                { wtf => 100_500 },
            ],
        },
    };
};

subtest 'default_value()' => sub {
    my $sut = init_sut();

    is $sut->default_value(), 'JIP::DataPath::default_value', 'object method';
    is $sut->default_value(), JIP::DataPath::default_value(), 'class method';
};

subtest 'is_default_value()' => sub {
    my $sut = init_sut();

    my $default_value = $sut->default_value();

    my @tests = (
        { value => undef,  result => 0, name => 'undefined' },
        { value => q{},    result => 0, name => 'empty string' },
        { value => [],     result => 0, name => 'arrayref' },
        { value => {},     result => 0, name => 'hashref' },
        { value => \42,    result => 0, name => 'scalarref' },
        { value => qr{42}, result => 0, name => 'regexp' },
        { value => 42,     result => 0, name => 'random number' },
        { value => '42',   result => 0, name => 'random string' },

        { value => $default_value, result => 1, name => 'default_value' },
    );

    foreach my $test (@tests) {
        is(
            $sut->is_default_value( $test->{value} ),
            $test->{result},
            $test->{name},
        );
    }
};

subtest 'path()' => sub {
    plan tests => 2;

    my $sut = JIP::DataPath::path(42);

    isa_ok $sut, 'JIP::DataPath';

    is $sut->document(), 42;
};

subtest '_accessor()' => sub {
    plan tests => 19;

    my $build_document = sub {
        return {
            foo => {
                wtf => 42,
            },
            bar => [
                [ 11, 22 ],
            ],
        };
    };

    my $document = $build_document->();

    my $sut = init_sut($document);

    my @tests = (
        {
            path     => [],
            contains => 1,
            context  => $document,
        },
        {
            path     => [qw(foo)],
            contains => 1,
            context  => $document,
        },
        {
            path     => [qw(foo wtf)],
            contains => 1,
            context  => $document->{foo},
        },
        {
            path     => [qw(bar)],
            contains => 1,
            context  => $document,
        },
        {
            path     => [qw(bar 0)],
            contains => 1,
            context  => $document->{bar},
        },
        {
            path     => [qw(bar 0 0)],
            contains => 1,
            context  => $document->{bar}->[0],
        },
        {
            path     => [qw(bar 0 1)],
            contains => 1,
            context  => $document->{bar}->[0],
        },
        {
            path     => [qw(1 wtf 1 wtf)],
            contains => 0,
            context  => undef,
        },
        {
            path     => [qw(wtf 1 wtf 1)],
            contains => 0,
            context  => undef,
        },
    );

    foreach my $test (@tests) {
        my ( $contains, $context ) = $sut->_accessor( $test->{path} );

        is(
            $contains,
            $test->{contains},
            sprintf(
                'contains "%s"',
                join( q{/}, @{ $test->{path} } ),
            ),
        );

        is_deeply $context, $test->{context};
    }

    # side effects
    is_deeply $sut->document(), $build_document->();
};

sub init_sut {
    my ($document) = @ARG;

    return JIP::DataPath->new( document => $document );
}

