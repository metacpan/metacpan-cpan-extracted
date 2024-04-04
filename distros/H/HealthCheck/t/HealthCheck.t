use Test2::V0 -target => 'HealthCheck',
    qw< ok is note done_testing >;

my $nl = Carp->VERSION >= 1.25 ? ".\n" : "\n";

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

    is( HealthCheck->new( checks => [$check] )->check,
        $expect, "->new(checks => [\$coderef])->check works" );

    is( HealthCheck->new->register($check)->check,
        $expect, "->new->register(\$coderef)->check works" );
}

{ note "Find default method on object or class";
    my $expect = { status => 'OK' };

    is( HealthCheck->new( checks => ['My::Check'] )->check,
        $expect, "Check a class name with a check method" );

    is( HealthCheck->new( checks => [ My::Check->new ] )->check,
        $expect, "Check an object with a check method" );
}

{ note "Find method on caller";
    my $expect = { status => 'OK', label => 'Other' };

    is(
        HealthCheck->new( checks => ['check'] )->check,
        { status => 'OK', label => 'Local' },
        "Found check method on main"
    );

    is(
        HealthCheck->new( checks => ['other_check'] )->check,
        { status => 'OK', label => 'Other Local' },
        "Found other_check method on main"
    );

    is( My::Check->new->register_check->check,
        $expect, "Found other check method on caller object" );

    is( My::Check->register_check->check,
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

    is(
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

    is \@warnings, [
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
        HealthCheck->new->register( {%check} )->check;

        delete @check{qw( invocant check )};
        $check{summarize_result} = 0;

        is( {@args}, {%check}, "Without an invocant, called as a function" );
    }
    {
        my @args;
        my %check = (
            invocant => 'My::Check',
            check    => sub { @args = @_; status => 'OK' },
            label    => "Method Label",
        );
        HealthCheck->new->register( {%check} )->check;

        delete @check{qw( invocant check )};
        $check{summarize_result} = 0;

        is( [ $args[0],    { @args[ 1 .. $#args ] } ],
            [ 'My::Check', {%check} ],
            "With an invocant, called as a method"
        );
    }
    {
        my @args;
        my %check = (
            check => sub { @args = @_; status => 'OK' },
            label => "CodeRef Label",
        );
        HealthCheck->new->register( {%check} )->check( custom => 'params' );

        delete @check{qw( invocant check )};
        $check{summarize_result} = 0;

        is( {@args},
            { %check, custom => 'params' },
            "Params passed to check merge with check definition"
        );
    }
    {
        my @args;
        my %check = (
            check => sub { @args = @_; status => 'OK' },
            label => "CodeRef Label",
        );
        HealthCheck->new->register( {%check} )->check( label => 'Check' );

        delete @check{qw( invocant check )};
        $check{summarize_result} = 0;

        is( {@args},
            { %check, label => 'Check' },
            "Params passed to check override check definition"
        );
    }
    {
        my @args;
        my %check = ( check => sub { @args = @_; status => 'OK' } );
        HealthCheck->new->register( {%check} )
            ->check( summarize_result => '' );

        delete @check{qw( invocant check )};
        $check{summarize_result} = 0;

        is( {@args},
            { %check, summarize_result => '' },
            "Overriding summarize_result with falsy value works"
        );
    }
    {
        my @args;
        my %check = ( check => sub { @args = @_; status => 'OK' } );
        HealthCheck->new->register( {%check} )
            ->check( summarize_result => 2 );

        delete @check{qw( invocant check )};
        $check{summarize_result} = 0;

        is( {@args},
            { %check, summarize_result => 2 },
            "Overriding summarize_result with truthy value works"
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

    is $run->(), [
        'Cheap and Easy',
        'Default',
        'Fast and Cheap',
        'Fast and Easy',
        'Hard',
        'Invocant Can',
    ], "Without specifying any desired tags, should run all checks";

    is $run->('default'), [ 'Default' ],
        'Default tag runs untagged checks';

    is $run->('fast'), [ 'Fast and Cheap', 'Fast and Easy', ],
        "Fast tag runs fast checks";

    is $run->(qw( hard default )), ['Default', 'Hard'],
        "Specifying hard and default tags runs checks that match either";

    is $run->(qw( invocant )), ['Invocant Can'],
        "Pick up tags if invocant can('tags')";

    is $run->('!hard'), [
        'Cheap and Easy',
        'Default',
        'Fast and Cheap',
        'Fast and Easy',
        'Invocant Can'
    ], "Not-hard tag runs not-hard checks";

    is $run->(qw(fast !easy)), [ 'Fast and Cheap' ],
        "Specyfying fast but not easy runs non-easy fast tests";

    is $run->(qw( nonexistent )), [],
        "Specifying a tag that doesn't match means no checks are run";
}

{ note "Check with tags";
    my $c = HealthCheck->new(
        id      => 'main',
        runbook => 'https://runbook-main.grantstreet.com',
        tags    => ['default'],
        checks  => [
            sub { +{ status => 'OK' } },
            {
                check => sub { +{ id => 'fast_cheap', status => 'OK' } },
                runbook => 'https://runbook1.grantstreet.com',
                tags => [qw( fast cheap )],
            },
            {
                check => sub { +{ id => 'fast_easy', status => 'OK' } },
                runbook => 'https://runbook2.grantstreet.com',
                tags => [qw( fast easy )],
            },
            HealthCheck->new(
                id      => 'subcheck',
                runbook => 'https://runbook3.grantstreet.com',
                tags    => [qw( subcheck easy )],
                checks  => [
                    sub { +{ id => 'subcheck_default', status => 'OK' } },
                    {
                        check => sub { +{ status => 'CRITICAL' } },
                        tags  => ['hard'],
                    },
                ]
            ),
            {
                id       => 'with_invocant',
                tags     => [qw( with invocant )],
                invocant => HealthCheck->new(
                    id    => 'from_invocant',
                    tags  => [qw( from invocant )],
                ),
                check => sub { +{ status => 'OK' } },
            },
        ] );

    is( [$c->get_registered_tags()],
        [qw( cheap default easy fast invocant subcheck with )],
        'got expected registered tags');

    is $c->check, {
        'id'      => 'main',
        'status'  => 'CRITICAL',
        'runbook' => 'https://runbook-main.grantstreet.com',
        'tags'    => ['default'],
        'results' => [
            {
                'status' => 'OK',
                'tags'   => [ 'default' ]
            },
            {
                'id'      => 'fast_cheap',
                'runbook' => 'https://runbook1.grantstreet.com',
                'status'  => 'OK',
                'tags'    => [ qw(fast cheap) ]
            },
            {
                'id'      => 'fast_easy',
                'runbook' => 'https://runbook2.grantstreet.com',
                'status'  => 'OK',
                'tags'    => [ qw(fast easy) ]
            },
            {
                'id'      => 'subcheck',
                'runbook' => 'https://runbook3.grantstreet.com',
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
                'tags' => [ 'subcheck', 'easy' ],
            },
            {
                'id'     => 'with_invocant',
                'status' => 'OK',
                'tags'   => [ 'with', 'invocant' ],
            },
        ],
    }, "Default check runs all checks";

    {
        local $c->{collapse_single_result} = 1;
        is $c->check( tags => ['default'] ), {
            'id'      => 'main',
            'runbook' => 'https://runbook-main.grantstreet.com',
            'tags'    => ['default'],
            'status'  => 'OK',
        }, "Check with 'default' tags collapses as requested";
    }

    is $c->check( tags => ['default'] ), {
        'id'      => 'main',
        'runbook' => 'https://runbook-main.grantstreet.com',
        'tags'    => ['default'],
        'status'  => 'OK',
        'results' => [ {
            'status' => 'OK',
            'tags'   => ['default'],
        } ],
    }, "Check with 'default' tags runs only untagged check";

    is $c->check( tags => ['easy'] ), {
        'id'      => 'main',
        'runbook' => 'https://runbook-main.grantstreet.com',
        'status'  => 'OK',
        'tags'    => ['default'],
        'results' => [
            {
                'id'      => 'fast_easy',
                'runbook' => 'https://runbook2.grantstreet.com',
                'tags'    => [ 'fast', 'easy' ],
                'status'  => 'OK' },
            {
                'id'      => 'subcheck',
                'runbook' => 'https://runbook3.grantstreet.com',
                'tags'    => [ 'subcheck', 'easy' ],
                'status'  => 'OK',
                'results' => [ {
                    'id'     => 'subcheck_default',
                    'tags'   => [ 'subcheck', 'easy' ],
                    'status' => 'OK',
                } ]
            }
        ],
    }, "Check with 'easy' tags runs checks tagged easy";

    { local $SIG{__WARN__} = sub { };
        # Because the "subcheck" doesn't have a "hard" tag
        # it doesn't get run, so none of its checks get run
        # so there are no results.
        is $c->check( tags => ['hard'] ), {
            'id'      => 'main',
            'runbook' => 'https://runbook-main.grantstreet.com',
            'tags'    => ['default'],
            'status'  => 'UNKNOWN',
            'info'    => 'missing status',
        }, "Check with 'hard' tags runs no checks, so no results";
    }

    is $c->check(tags => ['with']), {
        'id'      => 'main',
        'status'  => 'OK',
        'runbook' => 'https://runbook-main.grantstreet.com',
        'tags'    => ['default'],
        'results' => [
            {
                'id'     => 'with_invocant',
                'status' => 'OK',
                'tags'   => [ 'with', 'invocant' ],
            },
        ],
    }, "Uses outer tag when invocant is present";

    { local $SIG{__WARN__} = sub { };
        is $c->check(tags => ['from']), {
            'id'      => 'main',
            'runbook' => 'https://runbook-main.grantstreet.com',
            'tags'    => ['default'],
            'status'  => 'UNKNOWN',
            'info'    => 'missing status',
        }, "No checks to run when specifying inner invocant tag";
    }
}

{ note "Result inheritance";
    my $c = HealthCheck->new(
        id      => 'main',
        label   => 'Main',
        tags    => ['main'],
        checks  => [
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

    is( [$c->get_registered_tags()],
        [qw( check from invocant main with )],
        'got expected registered tags' );

    is $c->check, {
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
    is
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

    is [ $hc->get_registered_tags ], [], 'got expected (lack of) registered tags';
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
