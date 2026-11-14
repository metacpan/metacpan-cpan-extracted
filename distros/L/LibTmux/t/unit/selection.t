use v5.44;
use Test2::V1;
use Scalar::Util qw(blessed refaddr weaken);

my $loaded = eval { require LibTmux::Snapshot; require LibTmux::Filter; 1 };
T2->ok($loaded, 'captured graphs and filters are loadable');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }

sub error_is ($code, $type) {
    my $error;
    try { $code->() } catch ($caught) {
        $error = $caught
    }
    T2->ok(blessed($error) && $error->isa("LibTmux::X::$type"), $type);
    return $error;
}

sub graph (%overrides) {
    return LibTmux::Snapshot->from_records(
        server_id  => 'fixture',
        generation => 'generation-1',
        sessions   =>
            [{id => '$1', name => 'main'}, {id => '$2', name => 'other'}],
        windows =>
            [{id => '@3', name => 'api-one'}, {id => '@4', name => 'other'}],
        window_links => [
            {session_id => '$1', window_id => '@3', index => 0, active => true},
            {
                session_id => '$1',
                window_id  => '@3',
                index      => 2,
                active     => false
            },
            {session_id => '$2', window_id => '@3', index => 0, active => true},
            {
                session_id => '$1',
                window_id  => '@4',
                index      => 1,
                active     => false
            },
        ],
        panes => [
            {
                id              => '%0',
                window_id       => '@3',
                width           => 140,
                active          => true,
                current_command => 'nvim',
                title           => 'build.v2',
                current_path    => '/src',
                exit_status     => undef
            },
            {
                id              => '%1',
                window_id       => '@3',
                width           => 80,
                active          => false,
                current_command => 'bash',
                title           => '',
                current_path    => '/tmp',
                exit_status     => 0
            },
            {
                id              => '%2',
                window_id       => '@4',
                width           => 0,
                active          => false,
                current_command => '0',
                title           => 'buildXv2',
                current_path    => '',
                exit_status     => undef
            },
        ],
        clients => [],
        %overrides,
    );
}

my $snapshot = graph();
my $panes    = $snapshot->panes;
T2->ok($panes isa LibTmux::PaneSelection, 'pane selection kind');
T2->is([map { $_->id } $panes->@*], ['%0', '%1', '%2'],
    'native ordered arrays');
my $selected = $panes->where(
    {
        active          => true,
        current_command => {-in => [qw(nvim vim)]},
        window          => {-is => {name => {-starts_with => 'api-'}}},
    }
)->grep(sub ($pane) { $pane->width >= 120 });
T2->is($selected->one->id, '%0',
    'nested criteria compose with one-argument predicates');
my @result = $panes->where({active => false});
T2->is(scalar @result, 1, 'list context returns a selection object');
T2->ok(
    $result[0] isa LibTmux::PaneSelection,
    'concrete selection in list context'
);
my $empty = $panes->where({width => {-gt => 1000}});
T2->ok(!!$empty, 'empty selection retains ordinary reference truthiness');
T2->is($empty->count,  0,     'explicit count');
T2->is($empty->exists, false, 'explicit existence');
T2->is($empty->first,  undef, 'first on empty');
error_is(sub { $empty->one },          'NoMatch');
error_is(sub { $panes->one },          'MultipleMatches');
error_is(sub { $panes->one_or_undef }, 'MultipleMatches');
T2->is($empty->one_or_undef, undef, 'optional cardinality');
my $copy = $panes->to_array;
T2->is(ref $copy, 'ARRAY', 'compatibility conversion is unblessed');
pop $copy->@*;
pop $panes->@*;
T2->is($snapshot->panes->count,
    3, 'membership mutation cannot change the graph');
T2->is(scalar @$copy, 2, 'independent shallow conversion');
$panes = $snapshot->panes;
my $cursor = $panes->iterator;
$panes->[0] = undef;
T2->is($cursor->next->id, '%0', 'cursor captures its own membership');
error_is(sub { $panes->exists }, 'InvalidSelection');
$panes = $snapshot->panes;
delete $panes->[1];
error_is(sub { $panes->count }, 'InvalidSelection');

{
    local $_ = 'caller';
    my $filtered = $snapshot->panes->grep(
        sub {
            T2->is(scalar @_, 1,     'callback has exactly one argument');
            T2->is(wantarray, false, 'predicate runs in scalar context');
            $_[0] = 'replacement';
            $_ = 'localized replacement';
            return true;
        }
    );
    T2->is($_, 'caller', 'caller topic restored');
    T2->is($filtered->first->id, '%0',
        'callback assignment does not replace membership');
    my $thrown = bless {}, 'TestThrown';
    my $caught;
    try {
        $filtered->grep(sub { die $thrown })
    }
    catch ($e) { $caught = $e }
    T2->is(refaddr($caught), refaddr($thrown),
        'original thrown object propagates');
    T2->is($_, 'caller', 'topic restored after exception');
}

for my $criteria (
    {typo            => 1},
    {width           => {-contains => '1'}},
    {width           => {-gte      => 'wide'}},
    {-or             => [{active => true}, {unknown => 2}]},
    {width           => [1,                2]},
    {-and            => {}},
    {current_command => qr/vim/},
    )
{
    error_is(sub { $empty->where($criteria) }, 'InvalidFilter');
}
my @truth = (
    [{}, 3],
    [{-and            => []},                                            3],
    [{-or             => []},                                            0],
    [{current_command => {-in => []}},                                   0],
    [{current_command => {-not_in => []}},                               3],
    [{active          => false},                                         2],
    [{width           => '0'},                                           1],
    [{current_command => '0'},                                           1],
    [{title           => ''},                                            1],
    [{exit_status     => undef},                                         2],
    [{exit_status     => {-ne => undef}},                                1],
    [{title           => {-contains => 'build.v2'}},                     1],
    [{title           => {-starts_with => 'build', -ends_with => 'v2'}}, 2],
    [{-not            => {exit_status => {-gt => 0}}},                   3],
    [{window          => {-is_not => {name => 'other'}}},                2],
);
for my $case (@truth) {
    T2->is($snapshot->panes->where($case->[0])->count,
        $case->[1], 'schema-directed truth table');
}
my $unloaded =
    graph(panes => [{id => '%9', window_id => '@3', active => false}])->panes;
error_is(sub { $unloaded->where({width => {-gt => 1}}) }, 'Unloaded');
T2->is($unloaded->where({-and => [{active => true}, {width => 1}]})->count,
    0, 'ordered short circuit avoids unused fields');
error_is(sub { $unloaded->where({-and => [{width => 1}, {active => true}]}) },
    'Unloaded');
T2->is($unloaded->where({width => {-in => []}})->count,
    0, 'empty membership need not read data');

my $windows = $snapshot->windows;
T2->is(
    $windows->where(
        {panes => {-some => {active => true, current_command => 'bash'}}}
    )->count,
    0,
    'one existential means the same child'
);
T2->is(
    $windows->where(
        {
            -and => [
                {panes => {-some => {active          => true}}},
                {panes => {-some => {current_command => 'bash'}}},
            ]
        }
    )->count,
    1,
    'separate existential nodes may use different children'
);
T2->is(
    $snapshot->sessions->where(
        {
            window_links => {
                -some => {
                    window => {
                        -is => {panes => {-some => {current_command => 'nvim'}}}
                    },
                }
            }
        }
    )->count,
    2,
    'relations preserve linked-session graph'
);
T2->is($snapshot->window_links->count, 4,
    'repeated links are not deduplicated');
T2->is($snapshot->windows->count, 2, 'physical window identity is unique');
my $duplicates = LibTmux::PaneSelection->new(($snapshot->panes->[0]) x 2);
T2->is($duplicates->count, 2, 'selection occurrence multiplicity retained');
error_is(sub { $duplicates->one }, 'MultipleMatches');
my $other = graph(server_id => 'other-server');
error_is(
    sub {
        LibTmux::PaneSelection->new($snapshot->panes->[0], $other->panes->[0]);
    },
    'InvalidSelection'
);

my ($retained, $weak_store);
{
    my $temporary = graph();
    $retained   = $temporary->pane_by_id('%0');
    $weak_store = $temporary;
    weaken($weak_store);
}
T2->ok(defined $weak_store, 'handle retains graph store');
T2->is($retained->window->name, 'api-one', 'retained pane keeps relationships');
undef $retained;
T2->is($weak_store, undef, 'graph releases without a reference cycle');

my $criteria = {width => {-gte => '120'}, active => true};
my $filter   = LibTmux::Filter->new(entity => 'pane', where => $criteria);
$criteria->{width}{-gte} = 999;
T2->is($snapshot->panes->where($filter)->one->id,
    '%0', 'compiled filter owns its values');
my $data = $filter->to_data;
T2->is(
    $data,
    {
        schema => 'libtmux.where/v1',
        entity => 'pane',
        where  => {width => {gte => 120}, active => true}
    },
    'versioned normalized wire values'
);
$data->{where}{width}{gte} = 999;
T2->is($snapshot->panes->where($filter)->count,
    1, 'wire export is a defensive copy');
my $decoded = LibTmux::Filter->from_json($filter->to_json);
T2->is($snapshot->panes->where($decoded)->count,
    1, 'wire decode preserves semantics');
T2->is($filter->matches({width => 140, active => true}),
    true, 'plain hash record adapter');
my $cycle = {};
$cycle->{-not} = $cycle;
error_is(sub { LibTmux::Filter->new(entity => 'pane', where => $cycle) },
    'InvalidFilter');
error_is(sub { $snapshot->windows->where($filter) }, 'InvalidFilter');
my $byte_path =
    LibTmux::Filter->new(entity => 'pane', where => {current_path => "\xff"});
T2->ok($byte_path->matches({current_path => "\xff"}),
    'local opaque byte matching');
error_is(sub { $byte_path->to_json }, 'UnsupportedValue');

T2->done_testing;
