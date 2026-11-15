use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Sugar: pipelines named as the program compiles, each
# with a function of its name (roadmap 2026-0010).

use experimental qw(builtin);
use builtin      qw(weaken);

use Ekorn::Pipeline;
use Ekorn::Pipeline::Factories    qw(pipeline);
use Ekorn::Pipeline::Sinks        qw(count_items keep_all);
use Ekorn::Pipeline::Sources      qw(from_array);
use Ekorn::Pipeline::Stages::Flow qw(take);

my $class = 'Ekorn::Pipeline';

# A pipeline named before a use, which a definition can name.
BEGIN {
    Ekorn::Pipeline->named(doubled => sub { $_ * 2 });
}

# The definitions in an array of pairs, top first, though it names
# plus_one, defined after it.
use Ekorn::Pipeline::Sugar pipeline => [
    top      => ['plus_one', 'doubled', take(2)],
    plus_one => [sub { $_ + 1 }],
];

# And in a hash, with a sink, and a name alone.
use Ekorn::Pipeline::Sugar pipeline => {
    counted => [sub { $_ }, count_items],
    kept    => [sub { $_ }, keep_all],
    again   => ['plus_one'],
    failing => ['plus_one', sub { die "no\n" }],    ## no critic (ErrorHandling::RequireCarping)
};

# Return the message of the error a use of Sugar dies with, compiled
# from $code, as the file "use" at line 1, or nothing if it doesn't.
sub use_error ($code) {
    my $lived = eval "#line 1 \"use\"\n$code; 1";    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    return if $lived;
    return $@ =~ s( (?<= \n ) BEGIN\ failed .* )()xsr;
}

my $n = 0;


# Return the name of a package of its own, for a use to define in.
sub fresh () {
    return 'My::Fresh' . ++$n;
}

subtest 'A function of each name runs values through its pipeline' => sub {
    is [plus_one(1, 2, 3)], [2, 3, 4], 'values in, a list out';
    is [top(1, 2, 3)],      [4, 6],    'through the pipelines it names, in order';
    is [again(1)],          [2],       'a name alone';
};

subtest 'in the caller\'s context, as calling the pipeline does' => sub {
    is scalar plus_one(1, 2, 3), 3, 'how many came out';
    is scalar counted(1, 2),     2, 'a sink of one: its result';
    is scalar kept(1, 2), [1, 2],
        'a sink of many: its list, as an array reference';
    is [kept(1, 2)], [1, 2], 'and a list, in list context';
};

subtest 'Given a pipeline last, it runs the values through that too' => sub {
    is [plus_one(1, 2, pipeline(sub { $_ * 10 }))], [20, 30], 'after its own';
    is [top(1, 2, 3, pipeline('plus_one'))],        [5,  7],  'a named one too';
    my $code = sub { $_ };
    is [kept(1, $code)], [1, exact_ref($code)],
        'any other value is a value, a code reference too';
};

subtest 'A pipeline given last is used again while it is the one given' => sub {
    my $tens = pipeline(sub { $_ * 10 });
    my $neg  = pipeline(sub { -$_ });
    is [plus_one(1, $tens)], [20], 'the first';
    is [plus_one(2, $tens)], [30], 'the same again';
    is [plus_one(1, $neg)],  [-2], 'another, not the one before';
    is [plus_one(1, $tens)], [20], 'and the first again';

    my $boom = pipeline(sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line = __LINE__ + 1;
    is dies { plus_one(1, $boom) },
        "Pipeline stage #2.1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'its stages named as without it';
    $line = __LINE__ + 1;
    is dies { plus_one(1, $boom) },
        "Pipeline stage #2.1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'the second time too';

    my $kept = pipeline(sub { $_ });
    plus_one(1, $kept);
    my $weak = $kept;
    weaken($weak);
    undef $kept;
    ok defined $weak, 'the last one given is kept';
    plus_one(1, $tens);
    ok !defined $weak, 'until another is given';
};

subtest 'Each is named in the package that used the module' => sub {
    isa_ok pipeline('top'), [$class];
    is pipeline('top')->name, 'main::top', 'by its qualified name';
    is [pipeline('top')->iterator(from_array(1, 2, 3))->all], [4, 6],
        'so it can be pulled';
    ref_is pipeline('again'), pipeline('again'), 'one pipeline for each name';
    ok pipeline('again') != pipeline('plus_one'),
        'a name alone makes a pipeline of its own, not another name for one';
};

subtest 'A stage that dies is named within its pipeline' => sub {
    my $line = __LINE__ + 1;
    is dies { failing(1) },
        "Pipeline stage #2 (main::failing#2) failed at ${\ __FILE__ } line $line:\n    no\n";
};

subtest 'Definitions in a package of their own' => sub {
    my $package = fresh();
    is use_error(<<~"PERL"), undef, 'a use in another package';
        package $package;
        use Ekorn::Pipeline::Sugar pipeline => {
            tens => [sub { \$_ * 10 }],
            mine => ['tens', 'main::plus_one'],
        };
        PERL
    is [$package->can('mine')->(1)], [11],
        'names its own, and reaches others by their full names';
    ok !main->can('tens'), 'and gives main nothing';

    my $other = fresh();
    is use_error(<<~"PERL"), undef, 'its own by their full names too';
        package $other;
        use Ekorn::Pipeline::Sugar pipeline => {
            both => ['${other}::half', '${other}::half'],
            half => [sub { \$_ / 2 }],
        };
        PERL
    is [$other->can('both')->(8)], [2], 'defined in the order they need';
};

subtest 'import_into defines them for the package given' => sub {
    my $package = fresh();
    Ekorn::Pipeline::Sugar->import_into(
        $package,
        pipeline => {halves => [sub { $_ / 2 }]},
    );
    is [$package->can('halves')->(4)], [2], 'a function there';
    is pipeline("${package}::halves")->name, "${package}::halves",
        'and a name there';
    ok !main->can('halves'), 'not in its caller';
    ok lives { Ekorn::Pipeline::Sugar->import_into(fresh()) },
        'nothing given defines nothing';
};

subtest 'Mistakes croak at the use\'s line' => sub {
    my %error = (
        q(use Ekorn::Pipeline::Sugar statement => {}) =>
            'Expected pipeline, not statement',
        q(use Ekorn::Pipeline::Sugar pipeline => 'x') =>
            'Expected the pipelines after pipeline in a HASH or an ARRAY of pairs',
        q(use Ekorn::Pipeline::Sugar 'pipeline') =>
            'Expected the pipelines after pipeline in a HASH or an ARRAY of pairs',
        q(use Ekorn::Pipeline::Sugar pipeline => ['a']) =>
            'Expected the pipelines after pipeline in pairs of a name and an ARRAY',
        q(use Ekorn::Pipeline::Sugar pipeline => {'1a' => []}) =>
            'Expected a name for a pipeline (1a)',
        q(use Ekorn::Pipeline::Sugar pipeline => {'a::b' => []}) =>
            'Expected a name for a pipeline (a::b)',
        q(use Ekorn::Pipeline::Sugar pipeline => [a => [], a => []]) =>
            'Expected a pipeline defined once (a)',
        q(use Ekorn::Pipeline::Sugar pipeline => {a => sub {}}) =>
            'Expected the pipeline a in an ARRAY',
        q(sub a {} use Ekorn::Pipeline::Sugar pipeline => {a => []}) =>
            'Expected no function of the name in %s already (a)',
        q(use Ekorn::Pipeline::Sugar pipeline => {a => ['b'], b => ['a']}) =>
            q(Expected pipelines that don't name each other in a circle (a, b)),
        q(use Ekorn::Pipeline::Sugar pipeline => {a => ['a']}) =>
            q(Expected pipelines that don't name each other in a circle (a)),
        q(use Ekorn::Pipeline::Sugar pipeline => {a => ['nowhere']}) =>
            'No pipeline named %s::nowhere',
        q(use Ekorn::Pipeline::Sugar pipeline => {a => [42]}) =>
            q(Expected stage #1 to be a stage: a code reference, a pipeline or its name, or an object offering a stage's role method),
        q(use Ekorn::Pipeline::Sugar pipeline => {a => [undef]}) =>
            q(Expected stage #1 to be a stage: a code reference, a pipeline or its name, or an object offering a stage's role method),
        q(use Ekorn::Pipeline::Sugar undef) => 'Expected pipeline, not undef',
        q(use Ekorn::Pipeline::Sugar pipeline => [undef, []]) =>
            'Expected a name for a pipeline (undef)',
    );
    for my $code (sort keys %error) {
        my $package = fresh();
        is use_error("package $package; $code"),
            "$error{$code} at use line 1.\n" =~ s( %s )($package)xr,
            $error{$code} =~ s( %s )($package)xr;
    }
    my $package = fresh();
    Ekorn::Pipeline->named("${package}::taken" => sub { $_ });
    is use_error(
        "package $package; use Ekorn::Pipeline::Sugar pipeline => {taken => []}"),
        "A pipeline named ${package}::taken is already defined at use line 1.\n",
        'a name a pipeline has already';
};

subtest 'An inherited function counts as the package\'s own' => sub {
    my $package = fresh();
    is use_error(
        <<~"PERL"), "Expected no function of the name in $package already (inherited) at use line 4.\n";
        package ${package}::Parent { sub inherited {} }
        package $package;
        use parent -norequire, '${package}::Parent';
        use Ekorn::Pipeline::Sugar pipeline => {inherited => []};
        PERL
};

subtest 'Nothing given defines nothing' => sub {
    is use_error('package ' . fresh() . '; use Ekorn::Pipeline::Sugar'), undef;
};

done_testing;
