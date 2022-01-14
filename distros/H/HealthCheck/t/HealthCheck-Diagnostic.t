use Test2::V0 -target => 'HealthCheck::Diagnostic',
    qw< ok is like note context done_testing >;

my $nl = Carp->VERSION >= 1.25 ? ".\n" : "\n";

{ note "Object check with no run method defined";
    local $@;
    my $diagnostic = eval { My::HealthCheck::Diagnostic->new };
    ok !$@, "No exception from ->new";

    eval { $diagnostic->check };
    my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
    is $@, qq{My::HealthCheck::Diagnostic does not implement a 'run' method $at$nl},
        "Trying to run a check with no run method results in exception";
}

{ note "Class check with no run method defined";
    local $@;
    eval { My::HealthCheck::Diagnostic->check };
    my $at = "at " . __FILE__ . " line " . ( __LINE__ - 1 );
    is $@, qq{My::HealthCheck::Diagnostic does not implement a 'run' method $at$nl},
        "Trying to run a check with no run method results in exception";
}

my @results;
no warnings 'once';
*My::HealthCheck::Diagnostic::run = sub { @results };
use warnings 'once';

{ note "Results as different types";
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $warning_is = sub {
        my ($message) = @_;
        my $ctx = context();

        my $line = ( caller(0) )[2] - 2;
        my $at = 'at ' . __FILE__ . " line $line";

        my $warning = shift @warnings;
        $warning =~ s/0x[[:xdigit:]]+/0xHEX/g if $warning;
        my $res = is $warning, "$message $at$nl";

        $ctx->release;
        return $res;
    };

    @results = ({ label => 'As Class', status => 'WARNING' });
    my $expect = $results[0];

    is( My::HealthCheck::Diagnostic->check, $expect,
        "Called as a class has expected results from hashref");
    is( My::HealthCheck::Diagnostic->new->check, $expect,
        "Called as an object has expected results from hashref");

    ok !@warnings, "No warnings generated with hashref results";

    @results = %{ $results[0] };
    is( My::HealthCheck::Diagnostic->check, $expect,
        "Called as a class has expected results from even-sized-list");
    is( My::HealthCheck::Diagnostic->new->check, $expect,
        "Called as an object has expected results from even-sized-list");

    ok !@warnings, "No warnings generated with even-sized-list results";

    @results = ( 'broken' );
    $expect = { status => 'UNKNOWN' };
    is( My::HealthCheck::Diagnostic->check, $expect,
        "Called as a class has expected string result");
    $warning_is->(
        "Invalid return from My::HealthCheck::Diagnostic->run (broken)");
    is( My::HealthCheck::Diagnostic->new->check, $expect,
        "Called as an object has expected results from string result");
    $warning_is->(
        "Invalid return from My::HealthCheck::Diagnostic->run (broken)");

    ok !@warnings, "No unexpected warnings generated";

    @results = ( [ { status => 'broken' } ] );
    $expect = { status => 'UNKNOWN' };
    is( My::HealthCheck::Diagnostic->check, $expect,
        "Called as a class has expected arrayref result");
    $warning_is->(
        "Invalid return from My::HealthCheck::Diagnostic->run (ARRAY(0xHEX))");
    is( My::HealthCheck::Diagnostic->new->check, $expect,
        "Called as an object has expected results from arrayref result");
    $warning_is->(
        "Invalid return from My::HealthCheck::Diagnostic->run (ARRAY(0xHEX))");

    ok !@warnings, "No unexpected warnings generated";
}

{ note "Exception in 'run'";
    no warnings 'redefine';
    local *My::HealthCheck::Diagnostic::run = sub { die 'ded' };
    use warnings 'redefine';
    my $at = "at " . __FILE__ . " line " . ( __LINE__ - 2 );
    is( My::HealthCheck::Diagnostic->check, {
            status => 'CRITICAL',
            info   => "ded $at.\n",
        }, "Exception in run was caught with CRITICAL consequences" );
}

{ note "Override 'check'";
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    no warnings 'once';
    local *My::HealthCheck::Diagnostic::check = sub { 'invalid' };
    use warnings 'once';

    is( My::HealthCheck::Diagnostic->check, 'invalid',
        "Called as a class has expected invalid result");
    ok !@warnings, "No validation, no warnings as overridden class method";
    is( My::HealthCheck::Diagnostic->new->check, 'invalid',
        "Called as an object has expected results from arrayref result");
    ok !@warnings, "No validation, no warnings as overridden instance method";
}

{ note "Set and retrieve tags";
    is [ My::HealthCheck::Diagnostic->new->tags ], [],
        "No tags set, no tags returned";

    is [
        My::HealthCheck::Diagnostic->new( tags => [qw(foo bar)] )->tags ],
        [qw( foo bar )], "Returns the tags passed in.";

    is [ My::HealthCheck::Diagnostic->tags ], [],
        "Class method 'tags' has no tags, but also no exception";
}

{
    note "Attributes are copied into the result";
    @results = (
        status  => 'OK',

        foo     => 1,

        multi   => { level => 1 },

        runbook => 'https://runbook.grantstreet.com',

        undef   => undef,
        empty   => '',
        zero    => 0,
    );

    my $diagnostic = My::HealthCheck::Diagnostic->new(
        id      => 'my_id',
        label   => 'My Label',
        runbook => 'https://runbook.grantstreet.com',
        status  => 'WARNING',
        tags    => [ 'foo', 'bar' ],

        foo => 1,
        bar => { baz => 2 },

        multi => { ignored => 1 },    # not a deep copy

        undef => 'ignored',
        empty => 'ignored',
        zero  => 'ignored',
    );
    $diagnostic->{qux} = ['u'];

    like(
        $diagnostic->check(
            id      => 'ignored',
            label   => 'ignored',
            status  => 'ignored',
            tags    => [ 'bar', 'baz' ],    # not copied
            foo     => 'ignored',
            runtime => 1,
        ),
        {   id      => "my_id",
            label   => "My Label",
            tags    => [ 'foo', 'bar' ],
            runtime => qr{^\d+\.\d\d\d$},

            @results,
        },
        "Copied only the expected attributes to the result"
    );

    # Test that runtime is enabled when passing in truthy args.
    my %runtime_args = (
        q{1}          => 1,
        q{'1'}        => '1',
        q{[]}         => [], # Empty arrayref is truthy.
    );
    like (
        $diagnostic->check(
            id      => 'ignored',
            label   => 'ignored',
            status  => 'ignored',
            runtime => $runtime_args{ $_ },
        )->{runtime},
        qr{^\d+\.\d{3}$},
        "Runtime is enabled with $_ input arg."
    ) foreach keys %runtime_args;

    # Test that runtime is disabled when passing in falsy args.
    %runtime_args = (
        q{undef} => undef,
        q{''}    => '',
        q{0}     => 0,
        q{'0'}   => '0',
    );
    is (
        $diagnostic->check(
            id      => 'ignored',
            label   => 'ignored',
            status  => 'ignored',
            runtime => $runtime_args{ $_ },
        )->{runtime},
        undef,
        "Runtime is disabled with $_ input arg."
    ) foreach keys %runtime_args;

    # Don't copy these if they exist, even if undef
    push @results, ( id => undef, label => undef, tags => undef );

    my @warnings;
    my $got = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $diagnostic->check(
            id     => 'ignored',
            label  => 'ignored',
            status => 'ignored',
            tags   => ['ignored'],    # not copied
            foo    => 'ignored',
        );
    };
    my $at = sprintf "at %s line %d", __FILE__, __LINE__ - 8;

    is $got, { @results, status => 'UNKNOWN', info => 'undefined id' },
        "Didn't copy anything that was returned in the result already";
    is \@warnings, ["Result 0 has undefined id $at$nl"],
        "Warned about undef id in result";
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $at = "at " . __FILE__ . " line " . ( __LINE__ + 1 );
    is( HealthCheck::Diagnostic->new( collapse_single_result => 1 )
            ->summarize( {   results => [ { results => [ { results => [ {
                results => [ { status => 'OK' }, { status => 'OK' } ]
            } ] } ] } ]
        } ),
        {   status  => 'OK',
            results => [ { status => 'OK' }, { status => 'OK' } ],
        },
        "Summarize looks at sub-results for a status when collapsing"
    );

    is( \@warnings, [], "No warnings generated" );
}

foreach (
    [ class   => 'HealthCheck::Diagnostic' ],
    [ default => HealthCheck::Diagnostic->new ],
    [   explicit =>
            HealthCheck::Diagnostic->new( collapse_single_result => 0 )
    ],
    )
{
    my ($type, $diagnostic) = @{ $_ };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $at = "at " . __FILE__ . " line " . ( __LINE__ + 1 );
    is( $diagnostic->summarize( {
            results => [ {
                results => [ {
                    results => [ {
                        results => [ { status => 'OK' }, { status => 'OK' } ]
                    } ]
                } ]
            } ]
        } ),
        {   status  => 'OK',
            results => [ {
                status  => 'OK',
                results => [ {
                    status  => 'OK',
                    results => [ {
                        status  => 'OK',
                        results => [ { status => 'OK' }, { status => 'OK' } ],
                    } ]
                } ]
            } ]
        },
        "[$type] Summarize looks at sub-results for a status"
    );

    is( \@warnings, [], "No warnings generated" );
}

is( HealthCheck::Diagnostic->new( collapse_single_result => 1 )->summarize(
        {   results => [
                { status  => "OK" },
                { status  => "OK", id => "foo" },
                { status  => "OK" },
                { status  => "OK", id => "bar" },
                { status  => "OK" },
                { status  => "OK", id => "foo" },
                { status  => "OK", id => "bar" },
                { results => [ { status => "OK", id => "foo" } ] },
                {   results => [
                        { status => "OK", id => "foo" },
                        { status => "OK", id => "foo" },
                        { status => "OK", id => "foo" }
                    ]
                },
            ]
        }
    ),
    {   status  => "OK",
        results => [
            { status => "OK" },
            { status => "OK", id => "foo" },
            { status => "OK" },
            { status => "OK", id => "bar" },
            { status => "OK" },
            { status => "OK", id => "foo_1" },
            { status => "OK", id => "bar_1" },
            { status => "OK", id => "foo_2" },
            {   status  => "OK",
                results => [
                    { status => "OK", id => "foo" },
                    { status => "OK", id => "foo_1" },
                    { status => "OK", id => "foo_2" },
                ]
            },
        ]
    },
    "Summarize appends numbers to make valid ids"
);

{ note "Complain about invalid ID but still make unique";
    my @warnings;

    my $at = "at " . __FILE__ . " line " . ( __LINE__ + 3 );
    my $results = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        My::HealthCheck::Diagnostic->summarize( {
            results => [
                { status => "OK", id => "" },
                { status => "OK", id => undef },
                { status => "OK", id => "" },
                { status => "OK", id => undef },
                { status => "OK", id => "" },
            ]
        } );
    };

    is $results, { status  => 'UNKNOWN', results => [
            { status => "UNKNOWN", id => "",  info => "invalid id ''" },
            { status => "UNKNOWN", id => "1", info => "undefined id" },
            { status => "UNKNOWN", id => "2", info => "invalid id ''" },
            { status => "UNKNOWN", id => "3", info => "undefined id" },
            { status => "UNKNOWN", id => "4", info => "invalid id ''" },
    ] }, "Summarized additional blank results with numbers";

    is( \@warnings, [ map {"Result $_ $at$nl"}
        "0- has invalid id ''",
        "0-1 has undefined id",
        "0- has invalid id ''",
        "0-3 has undefined id",
        "0- has invalid id ''",
    ], "Got warnings about the invalid ids" );
}

{ note "Summarize validates result status";
    my @tests = (
        {
            have => {
                id      => 'false',
                info    => 'False Info',
                results => [
                    { id => 'not_exists', info => 'Not Exists' },
                    { id => 'undef',      info => 'Undef', status => undef },
                    {   id     => 'empty_string',
                        info   => 'Empty String',
                        status => ''
                    },
                ]
            },
            expect => {
                'id'      => 'false',
                'status'  => 'UNKNOWN',
                'info'    => 'False Info',
                'results' => [
                    {   'id'     => 'not_exists',
                        'status' => 'UNKNOWN',
                        'info'   => "Not Exists\nmissing status"
                    },
                    {   'id'     => 'undef',
                        'status' => 'UNKNOWN',
                        'info'   => "Undef\nundefined status"
                    },
                    {   'id'     => 'empty_string',
                        'status' => 'UNKNOWN',
                        'info'   => "Empty String\ninvalid status ''"
                    }
                    ],
            },
            warnings => [
                "Result false-not_exists has missing status",
                "Result false-undef has undefined status",
                "Result false-empty_string has invalid status ''",
            ],
        },
        {
            # The extra results keep it from combining results
            # so we can see what it actually does
            have => {
                id        => 'by_number',
                'results' => [
                    {   id      => 'ok',
                        results => [
                            { id     => 'zero', status => 0 },
                            { status => 'OK' }
                        ]
                    },
                    {   id      => 'warning',
                        results => [
                            { id     => 'one', status => 1 },
                            { status => 'OK' }
                        ]
                    },
                    {   id      => 'critical',
                        results => [
                            { id     => 'two', status => 2 },
                            { status => 'OK' }
                        ]
                    },
                    {   id      => 'unknown',
                        results => [
                            { id     => 'three', status => 3 },
                            { status => 'OK' }
                        ]
                    },
                ]
            },
            expect => {
                id      => 'by_number',
                status  => 'CRITICAL',
                results => [
                    {   'id'      => 'ok',
                        'status'  => 'OK',
                        'results' => [
                            {   'id'     => 'zero',
                                'status' => 0,
                                'info'   => "invalid status '0'",
                            },
                            { 'status' => 'OK' }
                        ],
                    },
                    {   'id'      => 'warning',
                        'status'  => 'WARNING',
                        'results' => [
                            {   'id'     => 'one',
                                'status' => 1,
                                'info'   => "invalid status '1'",
                            },
                            { 'status' => 'OK' }
                        ],
                    },
                    {   'id'      => 'critical',
                        'status'  => 'CRITICAL',
                        'results' => [
                            {   'id'     => 'two',
                                'status' => 2,
                                'info'   => "invalid status '2'",
                            },
                            { 'status' => 'OK' }
                        ],
                    },
                    {   'id'      => 'unknown',
                        'status'  => 'UNKNOWN',
                        'results' => [
                            {   'id'     => 'three',
                                'status' => 3,
                                'info'   => "invalid status '3'",
                            },
                            { 'status' => 'OK' }
                        ],
                    },
                ],
            },
            warnings => [
                "Result by_number-ok-zero has invalid status '0'",
                "Result by_number-warning-one has invalid status '1'",
                "Result by_number-critical-two has invalid status '2'",
                "Result by_number-unknown-three has invalid status '3'",
            ],
        },
        {
            have => {
                id      => 'invalid',
                results => [
                    { id => 'four',  status => 4 },
                    { id => 'other', status => 'OTHER' },
                ]
            },
            expect => {
                'id'      => 'invalid',
                'status'  => 'UNKNOWN',
                'info' => 'missing status',
                'results' => [
                    {   'id'     => 'four',
                        'status' => 4,
                        'info'   => "invalid status '4'",
                    },
                    {   'id'     => 'other',
                        'status' => 'OTHER',
                        'info'   => "invalid status 'OTHER'",
                    }
                    ],
            },
            warnings => [
                "Result invalid-four has invalid status '4'",
                "Result invalid-other has invalid status 'OTHER'",
                "Result invalid has missing status",
            ],
        },
        {
            have => {
                id     => 'by_index',
                results => [
                    { status => '00' },
                    { status => '11' },
                    { status => '22' },
                    { status => '33' },
                ], },
            expect => {
                'id'      => 'by_index',
                'status'  => 'UNKNOWN',
                'info'    => 'missing status',
                'results' => [
                    { "status" => "00", "info" => "invalid status '00'" },
                    { "status" => "11", "info" => "invalid status '11'" },
                    { "status" => "22", "info" => "invalid status '22'" },
                    { "status" => "33", "info" => "invalid status '33'" }
                ],
            },
            warnings => [
                "Result by_index-0 has invalid status '00'",
                "Result by_index-1 has invalid status '11'",
                "Result by_index-2 has invalid status '22'",
                "Result by_index-3 has invalid status '33'",
                "Result by_index has missing status",
            ],
        },
    );

    foreach my $test (@tests) {
        my @warnings;
        my $name = $test->{have}->{id};

        my $got = do {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            My::HealthCheck::Diagnostic->summarize( $test->{have} );
        };
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 2 );

        is( $got, $test->{expect}, "$name Summarized statuses" );

        is(
            \@warnings,
            [ map {"$_ $at$nl"} @{ $test->{warnings} || [] } ],
            "$name: Warned about incorrect status"
        );
    }
}

{ note "Validate and complain results 'results' key";
    my @warnings;

    my $at = "at " . __FILE__ . " line " . ( __LINE__ + 3 );
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        My::HealthCheck::Diagnostic->summarize( {
            id      => 'fine',
            status  => 'OK',
            results => [
                { status => 'OK' },    # nonexistent is OK
                map +{ status => 'OK', results => $_ },
                    undef,
                    '',
                    'a-string',
                    {},
            ] } );
    }

    s/0x[[:xdigit:]]+/0xHEX/g for @warnings;
    is( \@warnings, [ map {"Result $_ $at$nl"} 
        "fine-1 has undefined results",
        "fine-2 has invalid results ''",
        "fine-3 has invalid results 'a-string'",
        "fine-4 has invalid results 'HASH(0xHEX)'",
    ], "Got warnings about invalid results");
}

{ note "Complain about invalid ID";
    my @warnings;

    my $at = "at " . __FILE__ . " line " . ( __LINE__ + 3 );
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        My::HealthCheck::Diagnostic->summarize({
            id      => 'fine',
            status  => 'OK',
            results => [
                { status => 'OK' }, # nonexistent is OK
                map +{ status => 'OK', id => $_ },
                    'ok',
                    'ok_with_underscores',
                    'ok_with_1_number',
                    'ok_1_with_2_numbers_3_intersperced',
                    '_ok_with_leading_underscore',
                    '1_ok_with_leading_number',
                    undef,
                    '', # empty string
                    'Not_OK_With_Capital_Letters',
                    'Not_ok_with_capitols_like_Washington',
                    'not-ok-with-dashes',
                    'not ok with spaces',
                    'not/ok/with/slashes',
                    'not_ok_"quoted"',
            ]
        } );
    }

    is( \@warnings, [ map { "Result $_ $at$nl" }
        "fine-7 has undefined id",
        "fine- has invalid id ''",
        "fine-Not_OK_With_Capital_Letters has invalid id 'Not_OK_With_Capital_Letters'",
        "fine-Not_ok_with_capitols_like_Washington has invalid id 'Not_ok_with_capitols_like_Washington'",
        "fine-not-ok-with-dashes has invalid id 'not-ok-with-dashes'",
        "fine-not ok with spaces has invalid id 'not ok with spaces'",
        "fine-not/ok/with/slashes has invalid id 'not/ok/with/slashes'",
        q{fine-not_ok_"quoted" has invalid id 'not_ok_"quoted"'},
    ], "Got warnings about invalid IDs" );
}

{ note "Timestamp must be ISO8601";
    my $warnings_ok = sub {
        my $ctx = context();
        my ($timestamp, $num_warnings, $message) = @_;
        $message ||= $timestamp;

        my @warnings;
        {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            My::HealthCheck::Diagnostic->summarize({ status => 'OK', timestamp => $timestamp });
        }
        my $at = "at " . __FILE__ . " line " . ( __LINE__ - 2 );
        my @expect = ("Result 0 has invalid timestamp '$timestamp' $at$nl")
            x ( $num_warnings || 0 );

        my $res = is \@warnings, \@expect, "$message: Expected warnings";

        $ctx->release;
        return $res;
    };

    my @tests = (
        '2017-12-25 12:34:56z',    '2017-12-25T12:34:56Z',
        '2017-12-25 12:34:60+01:30', '2017-12-25t12:34:60-01:30',
    );
    my %ok = map { $_ => 1 } @tests;

    foreach my $ok (@tests) {
        $warnings_ok->( $ok );

        #use Data::Dumper 'Dumper'; warn Dumper \%+;

        $warnings_ok->( "1${ok}", 1 );
        $warnings_ok->( "${ok}1", 1 ) unless $ok =~ /\./;

        foreach my $i ( 0 .. length($ok) - 1 ) {
            my $nok = $ok;
            my $removed = substr( $nok, $i, 1, '' );
            last if $removed eq '.';    # can have shorter ms.
            next if $ok{$nok};
            $warnings_ok->( $nok, 1 );
        }
    }

    foreach my $nok (
        '2017',                    '0001',
        '201712',                  '2017-12',
        '20171225',                '2017-12-25',
        '2017-12-25 12:34:56',     '2017-12-25T12:34:56',
        '20171225 123456',         '20171225T123456',
        '2017-12-25 12:34:56.001', '2017-12-25t12:34:56.001',
        '20171225 123456.001',     '20171225T123456.001',
        '20171225 123456+0130', '20171225T123456-0130',
        '20171225 123456Z',        '20171225T123456z',
        '2017-12-25 12:34:56.', '2017-12-25T12:34:56.',
        '20171225 123456.',     '20171225T123456.',
        '',
        )
    {
        $warnings_ok->( $nok, 1 );
    }
}

done_testing;

package My::HealthCheck::Diagnostic;
use parent 'HealthCheck::Diagnostic';

1;
