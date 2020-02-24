use strict;
use warnings;
use Test::More;

use HealthCheck;

my $nl = $] >= 5.016 ? ".\n" : "\n";

{ note "Require instance methods";
    foreach my $method (qw( register check )) {
        local $@;
        eval { HealthCheck->$method };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
        is $@, "$method cannot be called as a class method $at$nl",
            "> $method";
    }
}

{ note "Require check";
    {
        local $@;
        eval { HealthCheck->new->register('') };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
        is $@, "check parameter required $at$nl", "> register('')";
    }
    {
        local $@;
        eval { HealthCheck->new->register(0) };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
        is $@, "check parameter required $at$nl", "> register(0)";
    }
    {
        local $@;
        eval { HealthCheck->new->register({}) };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
        is $@, "check parameter required $at$nl", "> register(\\%check)";
    }
}

{ note "Results with no checks";
    local $@;
    eval { HealthCheck->new->check };
    my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
    is $@, "No registered checks $at$nl",
        "Trying to run a check with no checks results in exception";
}

{ note "Register coderef checks";
    my $expect = { status => 'OK' };
    my $check = sub {$expect};

    is_deeply( HealthCheck->new( checks => [$check] )->check,
        $expect, "->new(checks => [\$coderef])->check works" );

    is_deeply( HealthCheck->new->register($check)->check,
        $expect, "->new->register(\$coderef)->check works" );
}

{ note "Find default method on object or class";
    my $expect = { status => 'OK' };

    is_deeply( HealthCheck->new( checks => ['My::Check'] )->check,
        $expect, "Check a class name with a check method" );

    is_deeply( HealthCheck->new( checks => [ My::Check->new ] )->check,
        $expect, "Check an object with a check method" );
}

{ note "Find method on caller";
    my $expect = { status => 'OK', label => 'Other' };

    is_deeply(
        HealthCheck->new( checks => ['check'] )->check,
        { status => 'OK', label => 'Local' },
        "Found check method on main"
    );

    is_deeply(
        HealthCheck->new( checks => ['other_check'] )->check,
        { status => 'OK', label => 'Other Local' },
        "Found other_check method on main"
    );

    is_deeply( My::Check->new->register_check->check,
        $expect, "Found other check method on caller object" );

    is_deeply( My::Check->register_check->check,
        $expect, "Found other check method on caller class" );
}

{ note "Don't find method where caller doesn't have it";
    {
        local $@;
        eval { HealthCheck->new( checks => ['nonexistent'] ) };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
        is $@, "Can't determine what to do with 'nonexistent' $at$nl",
            "Add nonexistent check.";
    }
    {
        local $@;
        eval { My::Check->register_nonexistant };
        my $at = "at " . __FILE__ . " line " . My::Check->rne_line;
        is $@, "Can't determine what to do with 'nonexistent' $at$nl",
            "Add nonexestant check from class.";
    }
    {
        local $@;
        eval { My::Check->new->register_nonexistant };
        my $at = "at " . __FILE__ . " line " . My::Check->rne_line;
        is $@, "Can't determine what to do with 'nonexistent' $at$nl",
            "Add nonexistent check from object.";
    }
    {
        local $@;
        eval {
            HealthCheck->new->register(
                { invocant => 'My::Check', check => 'nonexistent' } );
        };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 3 );
        is $@, "'My::Check' cannot 'nonexistent' $at$nl",
            "Add nonexestant method on class.";
    }
    {
        local $@;
        my $invocant = My::Check->new;
        eval {
            HealthCheck->new->register(
                { invocant => $invocant, check => 'nonexistent' } );
        };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 3 );
        is $@, "'$invocant' cannot 'nonexistent' $at$nl",
            "Add nonexestant method on object.";
    }
}

{ note "Results as even-sized-list or hashref";
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    is_deeply(
        HealthCheck->new( checks => [
            sub { +{ id => 'hashref', status => 'OK' } },
            { invocant => 'My::Check', check => sub { 'broken' } },
            sub { id => 'even_size_list', status => 'OK' },
            sub { [ { status => 'broken' } ] },
        ] )->check,
        {
            'status' => 'OK',
            'results' => [
                { 'id' => 'hashref',        'status' => 'OK' },
                { 'id' => 'even_size_list', 'status' => 'OK' }
            ],
        },
        "Results as expected"
    );
    my $at = "at " . __FILE__ . " line " . ( __LINE__ - 10 );

    s/0x[[:xdigit:]]+/0xHEX/g for @warnings;

    is_deeply \@warnings, [
         "Invalid return from My::Check->CODE(0xHEX) (broken) $at$nl",
         "Invalid return from CODE(0xHEX) (ARRAY(0xHEX)) $at$nl",
    ], "Expected warnings";
}

{ note "Calling Conventions";
    {
        my @args;
        my %check = (
            check => sub { @args = @_; status => 'OK' },
            label => "CodeRef Label",
        );
        HealthCheck->new->register( \%check )->check;

        delete @check{qw( invocant check )};

        is_deeply(
            \@args,
            [ %check ],
            "Without an invocant, called as a function"
        );
    }
    {
        my @args;
        my %check = (
            invocant => 'My::Check',
            check    => sub { @args = @_; status => 'OK' },
            label    => "Method Label",
        );
        HealthCheck->new->register( \%check )->check;

        delete @check{qw( invocant check )};
        is_deeply(
            \@args,
            [ 'My::Check', %check ],
            "With an invocant, called as a method"
        );
    }
    {
        my @args;
        my %check = (
            check => sub { @args = @_; status => 'OK' },
            label => "CodeRef Label",
        );
        HealthCheck->new->register( \%check )->check( custom => 'params' );

        delete @check{qw( invocant check )};

        is_deeply(
            \@args,
            [ %check, custom => 'params' ],
            "Params passed to check merge with check definition"
        );
    }
    {
        my @args;
        my %check = (
            check => sub { @args = @_; status => 'OK' },
            label => "CodeRef Label",
        );
        HealthCheck->new->register( \%check )->check( label => 'Check' );

        delete @check{qw( invocant check )};

        is_deeply(
            \@args,
            [ %check, label => 'Check' ],
            "Params passed to check override check definition"
        );
    }
}

{ note "Should run checks";
    my %checks = (
        'Default'        => {},
        'Fast and Cheap' => { tags => [qw(  fast cheap )] },
        'Fast and Easy'  => { tags => [qw(  fast  easy )] },
        'Cheap and Easy' => { tags => [qw( cheap  easy )] },
        'Hard'           => { tags => [qw( hard )] },
        'Invocant Can'   => HealthCheck->new( tags => ['invocant'] ),
    );
    my $c = HealthCheck->new( tags => ['default'] );

    my $run = sub {
        [ grep { $c->should_run( $checks{$_}, tags => \@_ ) }
                sort keys %checks ];
    };

    is_deeply $run->(), [
        'Cheap and Easy',
        'Default',
        'Fast and Cheap',
        'Fast and Easy',
        'Hard',
        'Invocant Can',
    ], "Without specifying any desired tags, should run all checks";

    is_deeply $run->('default'), [ 'Default' ],
        'Default tag runs untagged checks';

    is_deeply $run->('fast'), [ 'Fast and Cheap', 'Fast and Easy', ],
        "Fast tag runs fast checks";

    is_deeply $run->(qw( hard default )), ['Default', 'Hard'],
        "Specifying hard and default tags runs checks that match either";

    is_deeply $run->(qw( invocant )), ['Invocant Can'],
        "Pick up tags if invocant can('tags')";

    is_deeply $run->('!hard'), [
        'Cheap and Easy',
        'Default',
        'Fast and Cheap',
        'Fast and Easy',
        'Invocant Can'
    ], "Not-hard tag runs not-hard checks";

    is_deeply $run->(qw(fast !easy)), [ 'Fast and Cheap' ],
        "Specyfying fast but not easy runs non-easy fast tests";

    is_deeply $run->(qw( nonexistent )), [],
        "Specifying a tag that doesn't match means no checks are run";
}

{ note "Check with tags";
    my $c = HealthCheck->new(
        id     => 'main',
        tags   => ['default'],
        checks => [
            sub { +{ status => 'OK' } },
            {
                check => sub { +{ id => 'fast_cheap', status => 'OK' } },
                tags => [qw( fast cheap )],
            },
            {
                check => sub { +{ id => 'fast_easy', status => 'OK' } },
                tags => [qw( fast easy )],
            },
            HealthCheck->new(
                id     => 'subcheck',
                tags   => [qw( subcheck easy )],
                checks => [
                    sub { +{ id => 'subcheck_default', status => 'OK' } },
                    {
                        check => sub { +{ status => 'CRITICAL' } },
                        tags  => ['hard'],
                    },
                ]
            ),
        ] );

    is_deeply $c->check, {
        'id'      => 'main',
        'status'  => 'CRITICAL',
        'tags'    => ['default'],
        'results' => [
            {
                'status' => 'OK',
                'tags'   => [ 'default' ]
            },
            {
                'id'     => 'fast_cheap',
                'status' => 'OK',
                'tags'   => [ qw(fast cheap) ]
            },
            {
                'id'     => 'fast_easy',
                'status' => 'OK',
                'tags'   => [ qw(fast easy) ]
            },
            {
                'id'      => 'subcheck',
                'status'  => 'CRITICAL',
                'results' => [
                    {
                        'id'     => 'subcheck_default',
                        'status' => 'OK',
                        # inherit super-check's tags
                        'tags'   => [ qw(subcheck easy) ],
                    },
                    {
                        'status' => 'CRITICAL',
                        'tags'   => [qw(hard)],
                    }
                ],
                'tags' => [ 'subcheck', 'easy' ] }
        ],
    }, "Default check runs all checks";

    is_deeply $c->check( tags => ['default'] ), {
        'id'     => 'main',
        'tags'   => ['default'],
        'status' => 'OK',
    }, "Check with 'default' tags runs only untagged check";

    is_deeply $c->check( tags => ['easy'] ), {
        'id'      => 'main',
        'status'  => 'OK',
        'tags'    => ['default'],
        'results' => [
            {
                'id'     => 'fast_easy',
                'tags'   => [ 'fast', 'easy' ],
                'status' => 'OK' },
            {
                'id'     => 'subcheck_default',
                'tags'   => [ 'subcheck', 'easy' ],
                'status' => 'OK',
            }
        ],
    }, "Check with 'easy' tags runs checks tagged easy";

    { local $SIG{__WARN__} = sub { };
        # Because the "subcheck" doesn't have a "hard" tag
        # it doesn't get run, so none of its checks get run
        # so there are no results.
        is_deeply $c->check( tags => ['hard'] ),
            {
            'id'      => 'main',
            'tags'    => ['default'],
            'status'  => 'UNKNOWN',
            'info'    => 'missing status',
            'results' => [],
            },
            "Check with 'hard' tags runs no checks, so no results";
    }
}

{ note "Result inheritance";
    my $c = HealthCheck->new(
        id     => 'main',
        label  => 'Main',
        tags   => ['main'],
        checks => [
            {   check => sub { +{ status => 'OK' } }
            },

            {   id    => 'from_check',
                label => 'From Check',
                tags  => [qw( from check )],
                check => sub { +{ status => 'OK' } },
            },
            {   id    => 'from_check',
                label => 'From Check',
                tags  => [qw( from check )],
                check => sub {
                    +{  id     => 'from_result',
                        label  => 'From Result',
                        tags   => [qw( from result )],
                        status => 'OK'
                    };
                },
            },

            {   invocant => HealthCheck->new,
                check    => sub { +{ status => 'OK' } },
            },

            HealthCheck->new(
                checks => [
                    sub { +{ status => 'OK' } },
                    sub { +{ status => 'OK' } },
                ],
            ),

            {   invocant => HealthCheck->new(
                    id    => 'from_invocant',
                    label => 'From Invocant',
                    tags  => [qw( from invocant )],
                ),
                check => sub { +{ status => 'OK' } },
            },
            {   id       => 'with_invocant',
                label    => 'With Invocant',
                tags     => [qw( with invocant )],
                invocant => HealthCheck->new(
                    id    => 'from_invocant',
                    label => 'from_Invocant',
                    tags  => [qw( from invocant )],
                ),
                check => sub { +{ status => 'OK' } },
            },

            {   id       => 'with_invocant',
                label    => 'With Invocant',
                tags     => [qw( with invocant )],
                invocant => HealthCheck->new(
                    id    => 'from_invocant',
                    label => 'from_Invocant',
                    tags  => [qw( from invocant )],
                ),
                check => sub {
                    +{  id     => 'invocant_result',
                        label  => 'Invocant Result',
                        tags   => [qw( invocant result )],
                        status => 'OK'
                    };
                },
            },
        ],
    );

    is_deeply $c->check, {
        'id'      => 'main',
        'label'   => 'Main',
        'tags'    => ['main'],
        'status'  => 'OK',
        'results' => [
            {   'tags'   => [ 'main' ],
                'status' => 'OK'
            },
            {   'id'     => 'from_check',
                'label'  => 'From Check',
                'tags'   => [ 'from', 'check' ],
                'status' => 'OK',
            },
            {   'id'     => 'from_result',
                'label'  => 'From Result',
                'tags'   => [ 'from', 'result' ],
                'status' => 'OK',
            },
            {   'tags'   => [ 'main' ],
                'status' => 'OK'
            },
            {   'tags'   => [ 'main' ],
                'status' => 'OK',
                results => [
                    { status => 'OK' },
                    { status => 'OK' },
                ],
            },
            {   'id'     => 'from_invocant',
                'label'  => 'From Invocant',
                'status' => 'OK',
                'tags'   => [ 'from', 'invocant' ],
            },
            {   'id'     => 'with_invocant',
                'label'  => 'With Invocant',
                'tags'   => [ 'with', 'invocant' ],
                'status' => 'OK',
            },
            {   'id'     => 'invocant_result',
                'label'  => 'Invocant Result',
                'tags'   => [ 'invocant', 'result' ],
                'status' => 'OK',
            }
        ],
    }, "Check that the inheritance of id, label, and tags as expected";
}

{ note "Check that throws exception";
    my $check = sub { die "ded\n" };
    my $hc = HealthCheck->new( checks => [ $check, sub { status => 'OK' } ] );
    is_deeply
        $hc->check,
        {
            results => [
                {
                    info => "ded\n",
                    status => "CRITICAL"
                },
                {
                    status => "OK"
                },
            ],
            status => "CRITICAL",
        },
        "Able to report mixed success/failures"
    ;
}

done_testing;

sub check       { +{ status => 'OK', label => 'Local' } }
sub other_check { +{ status => 'OK', label => 'Other Local' } }

package My::Check;

sub new { bless {}, $_[0] }
sub check       { +{ status => 'OK' } }
sub other_check { +{ status => 'OK', label => 'Other' } }

sub register_check       { HealthCheck->new->register('other_check') }
sub register_nonexistant { HealthCheck->new->register('nonexistent') }
sub rne_line { __LINE__ - 1 }
