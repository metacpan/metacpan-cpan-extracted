use v5.44;
use Test2::V1;
use LibTmux::Server;
use LibTmux::CommandResult;

package VerificationServer {
    use parent 'LibTmux::Server';
    sub _binary_op  ($self) { LibTmux::Operation->value(undef) }
    sub _capture_op ($self) { LibTmux::Operation->request(argv => ['capture']) }

    sub _cmd_op ($self, $argv) {
        $self->_checked(LibTmux::Operation->request(argv => $argv));
    }
}

my $snapshot = LibTmux::Snapshot->from_records(
    server_id  => 'query-fixture',
    generation => 'generation-7',
    metadata   => {version => '3.8', capture_start => 10, capture_end => 11},
    panes      => [
        {id => '%2', active => true,  title => 'match'},
        {id => '%0', active => false, title => ''},
        {id => '%1', active => true,  title => 'other'},
    ],
);
my $server = VerificationServer->new;

sub run_query ($native, $args, $capture_error = undef) {
    my ($value, $error, @requests);
    try {
        $server->operation('query_panes', %$args)->run(
            sub ($request, $done, $fail) {
                push @requests, $request->{argv};
                if ($request->{argv}[0] eq 'capture') {
                    defined($capture_error)
                        ? $fail->($capture_error)
                        : $done->($snapshot);
                }
                elsif (ref $native) { $fail->($native) }
                else {
                    $done->(
                        bless {
                            stdout     => $native,
                            stderr     => '',
                            exit_code  => 0,
                            signal     => 0,
                            raw_status => 0
                        },
                        'LibTmux::CommandResult'
                    );
                }
                return sub { };
            },
            sub ($result) { $value = $result },
            sub ($caught) { $error = $caught },
        );
    }
    catch ($caught) { $error = $caught }
    return ($value, $error, \@requests);
}

my @cases = (
    [
        'disabled', {where => {active => true}, pushdown => 'never'},
        '', 'none', undef, undef, [], [], []
    ],
    [
        'local', {where => {title => {-contains => 'match'}}},
        '', 'none', false, undef, [], [], []
    ],
    [
        'agreed', {where => {active => true}},
        "%1\n%2\n%1\n", 'exact_ids', true, ['%1', '%2'],
        [], [], []
    ],
    [
        'disagreed', {where => {active => true}},
        "%0\n%9\n",   'exact_ids',
        true,         ['%0', '%9'],
        ['%2', '%1'], ['%0', '%9'],
        ['%9']
    ],
    [
        'agreed', {where => {active => true, title => {-contains => 'match'}}},
        "%1\n%2\n", 'candidate_superset', false, ['%1', '%2'],
        [], [], []
    ],
    [
        'disagreed',
        {where => {active => true, title => {-contains => 'match'}}},
        "%1\n", 'candidate_superset', false, ['%1'], ['%2'], [], []
    ],
    [
        'native', {native_filter => '#{pane_active}'},
        "%1\n%2\n%1\n", 'captured_membership', undef, ['%1', '%2'],
        [], [], []
    ],
    ['agreed', {where => {id => '%99'}}, '', 'exact_ids', true, [], [], [], []],
);
for my $case (@cases) {
    my ($status,    $args,     $native, @expected) = @$case;
    my (@reports,   @contexts, @arities);
    my ($selection, $error,    $requests) = run_query(
        $native,
        {
            %$args,
            on_verification => sub {
                push @contexts, wantarray;
                push @arities,  scalar @_;
                push @reports,  $_[0];
                return 'ignored';
            },
        }
    );
    T2->is($error, undef, "$status query succeeds");
    next if $error;
    T2->is(
        [scalar @reports, \@contexts, \@arities],
        [1,               [undef],    [1]],
        'observer runs once with one argument in void context'
    );
    my $report = $reports[0];
    T2->is(
        [
            @$report{
                qw(status comparison translation_exact native_ids
                    missing_ids unexpected_ids uncaptured_ids)
            }
        ],
        [$status, @expected],
'comparison distinguishes exact, partial, absent and empty native results'
    );
    T2->is(
        [
            @$report{
                qw(server_id generation daemon_version capture_start capture_end captured_ids)
            }
        ],
        ['query-fixture', 'generation-7', '3.8', 10, 11, ['%2', '%0', '%1']],
        'report describes the captured observation'
    );
    T2->is(
        $report->{native_checked},
        scalar(@$requests == 2),
        'checked means a native request ran'
    );
    T2->is(
        $report->{policy},
        exists($args->{native_filter}) ? 'native' : $args->{pushdown} // 'auto',
        'policy identifies the expert escape hatch'
    );
    T2->is(
        $report->{native_filter},
        @$requests == 2 ? $requests->[1][3] : undef,
        'report carries only the actually executed lowering'
    );
    T2->ok(
        $selection isa LibTmux::PaneSelection,
        'selection return is unchanged'
    );
    T2->is(
        $report->{local_ids},
        exists($args->{native_filter})
        ? undef
        : [map { $_->id } $snapshot->panes->where($args->{where} // {})->@*],
        'local comparison is absent only for expert queries'
    );
    my @before = map { $_->id } @$selection;
    $report->{captured_ids}->@* = ();
    $report->{local_ids}->@*    = () if defined $report->{local_ids};
    T2->is([map { $_->id } @$selection],
        \@before, 'report mutation cannot change the result');
    T2->is($snapshot->panes->count,
        3, 'report mutation cannot change captured membership');
}
{
    my $called = false;
    my ($value, $error) = run_query(
        "%2\ninvalid\n",
        {
            on_verification => sub { $called = true }
        }
    );
    T2->ok($error isa LibTmux::X::Codec,
        'malformed native IDs remain decoding failures');
    T2->is($called, false,
        'malformed native output never reaches the observer');
}

for my $args ({where => {active => true}, pushdown => 'require'},
    {native_filter => '#{pane_active}'})
{
    my $called = false;
    my ($value, $error) = run_query(
        "%9\n",
        {
            %$args,
            on_verification =>
                sub { $called = true; die 'must not replace mismatch' }
        }
    );
    T2->ok($error isa LibTmux::X::QueryMismatch, 'mismatch is cause-neutral');
    T2->is($error->details->{verification}{uncaptured_ids},
        ['%9'], 'mismatch retains comparison details');
    T2->is(
        [$value, $called],
        [undef,  false],
        'query failure does not invoke observer'
    );
}

my $thrown = bless {}, 'VerificationFailure';
my ($value, $error) = run_query(
    '',
    {
        pushdown        => 'never',
        on_verification => sub { die $thrown }
    }
);
T2->is(refaddr($error), refaddr($thrown),
    'observer exception retains identity');
for my $stage ('capture', 'native') {
    my $failure = LibTmux::X::Timeout->new(
        message    => "$stage failed",
        dispatched => true
    );
    my $called = false;
    my ($value, $error) = run_query(
        $stage eq 'native' ? $failure : '',
        {on_verification => sub { $called = true }},
        $stage eq 'capture' ? $failure : undef
    );
    T2->is(refaddr($error), refaddr($failure),
        'operational exception retains identity');
    T2->is($called, false,
        'operational failure never reports a successful decision');
}
for my $args (
    {on_verification => undef},
    {on_verification => {}},
    {where => {title        => {-contains => 'x'}}, pushdown => 'require'},
    {where => {cursor_shape => 'block'}}
    )
{
    my $called = false;
    my %input  = (%$args);
    $input{on_verification} = sub { $called = true }
        unless exists $input{on_verification};
    my ($value, $error, $requests) = run_query('', \%input);
    T2->ok(defined($error) && !$called,
        'invalid input, unavailable data and policy failure skip observer');
    T2->is(scalar @$requests,
        0, 'invalid callback is rejected before acquisition')
        if exists $args->{on_verification};
}
T2->done_testing;
