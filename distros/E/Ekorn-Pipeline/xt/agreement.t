use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# A run gives the same values however it's run: pushed, pulled a value
# at a time, read with all, or fed a value at a time and closed, as the
# reference promises. Random pipelines of the canned stages, gathers,
# stops carrying values, flatMaps and filters, ending in a sink or not,
# are run each way, from a fixed seed, so a failure can be run again
# (roadmap 2026-0053's F16).

use Ekorn::Pipeline;
use Ekorn::Pipeline::Tooling qw(:all);

my $CASES = $ENV{EKORN_AGREEMENT_CASES} // 3000;
my $SEED  = $ENV{EKORN_AGREEMENT_SEED}  // 20260053;
srand $SEED;

# Each makes a stage, and says what it is, for a failure's message.
my @makers = (
    sub { my $n = int rand 6;     (take($n),  "take($n)") },
    sub { my $n = int rand 4;     (drop($n),  "drop($n)") },
    sub { my $n = 1 + int rand 3; (batch($n), "batch($n)") },
    sub { (collect { scalar @_ }, 'collect { scalar @_ }') },
    sub { (sub { ($_, _number($_) + 100, _number($_) + 200) }, 'three of it') },
    sub { (sub { _number($_) % 2 ? $_ : () },                  'the odd') },
    sub {
        my $at = int rand 8;
        (sub { _number($_) == $at ? Stop($_, -1) : $_ }, "a stop at $at");
    },
    sub { (take_last, 'take_last') },
    sub {
        my $n      = int rand 4;
        my $gather = gather {
            Ekorn::Pipeline->new(take($n), sub { $_ })
        };
        ($gather, "a gather of take($n)");
    },
    sub { (tee(take(2), batch(2)), 'a tee') },
    sub { (sub { _number($_) },    'as a number') },
);
my @sinks = (
    sub { (keep_all,    'keep_all') },
    sub { (count_items, 'count_items') },
    sub { (keep_first,  'keep_first') },
    sub { (keep(2),     'keep(2)') },
);

# A value as a number: a batch's or a collection's size.
sub _number ($value) {
    return ref $value ? scalar @$value : $value;
}

# A value, or a list of them, as text to compare.
sub _shown (@values) {
    return join ',',
        map { ref $_ ? '[' . _shown(@$_) . ']' : $_ // 'undef' } @values;
}

my $failed = 0;
for my $case (1 .. $CASES) {
    my(@stages, @named);
    for (1 .. 1 + int rand 4) {
        my($stage, $name) = $makers[rand @makers]->();
        push @stages, $stage;
        push @named,  $name;
    }
    if (rand > 0.4) {
        my($sink, $name) = $sinks[rand @sinks]->();
        push @stages, $sink;
        push @named,  $name;
    }
    my @values   = map { int rand 10 } 1 .. int rand 8;
    my $pipeline = Ekorn::Pipeline->new(@stages);
    my $source   = sub (@from) {
        sub { @from ? shift @from : () }
    };

    my %got = (pushed => _shown($pipeline->(@values)));
    $got{all} = _shown($pipeline->iterator($source->(@values))->all);
    my $next = $pipeline->iterator($source->(@values));
    my @pulled;
    while (my($value) = $next->()) { push @pulled, $value }
    $got{pulled} = _shown(@pulled);
    my $feed = $pipeline->feed;
    my @fed;
    for my $value (@values) {
        push @fed, $feed->push($value);
        last if defined $feed->ended;
    }
    push @fed, $feed->close unless defined $feed->ended;
    $got{fed} = _shown(@fed);

    next unless grep { $got{$_} ne $got{pushed} } keys %got;
    $failed++;
    fail "case $case: (@values) through " . join ', ', @named;
    diag "    $_: $got{$_}" for sort keys %got;
    last if $failed >= 5;
}
ok !$failed, "$CASES pipelines give the same values every way, from seed $SEED";

done_testing;
