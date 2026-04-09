use Test2::V0;

# Tests targeting specific uncovered code paths identified by Devel::Cover.

# ============================================================================
# Instance: add_option, add_post_process, have_group, option_groups,
#           check_cache, option_map cache, include with posts
# ============================================================================

subtest 'Instance: add_option and add_post_process' => sub {
    my $inst = Getopt::Yath::Instance->new();

    $inst->add_option(
        type      => 'Bool',
        title     => 'inst-flag',
        group     => 'ig',
        no_module => 1,
        trace     => [__PACKAGE__, __FILE__, __LINE__],
    );

    is(scalar @{$inst->options}, 1, 'add_option adds one option');
    is($inst->options->[0]->title, 'inst-flag', 'correct option added');

    my $ran = 0;
    $inst->add_post_process(0, undef, sub { $ran++ });
    ok(exists $inst->posts->{0}, 'add_post_process registers post');

    my $state = $inst->process_args([]);
    ok($ran, 'post-processor added via add_post_process ran');
};

subtest 'Instance: have_group and option_groups' => sub {
    my $inst = Getopt::Yath::Instance->new();
    $inst->add_option(
        type => 'Bool', title => 'hg-a', group => 'grp_x',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );
    $inst->add_option(
        type => 'Bool', title => 'hg-b', group => 'grp_y',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );

    ok($inst->have_group('grp_x'),  'have_group true for grp_x');
    ok($inst->have_group('grp_y'),  'have_group true for grp_y');
    ok(!$inst->have_group('grp_z'), 'have_group false for grp_z');

    my $groups = $inst->option_groups;
    is($groups, {grp_x => 1, grp_y => 1}, 'option_groups returns all groups');

    # Call again to exercise cache path
    my $groups2 = $inst->option_groups;
    is($groups2, $groups, 'option_groups returns cached result');
};

subtest 'Instance: option_map caching' => sub {
    my $inst = Getopt::Yath::Instance->new();
    $inst->add_option(
        type => 'Bool', title => 'cm-a', group => 'cm',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );

    # First call builds the map and primes the cache key
    my $map1 = $inst->option_map;
    # Second call: check_cache sees key mismatch (0 vs 1), clears and rebuilds
    my $map2 = $inst->option_map;
    # Third call: cache key matches, returns cached ref
    my $map3 = $inst->option_map;
    ok($map2 == $map3, 'option_map returns cached ref after cache is primed');

    # Adding another option invalidates the cache
    $inst->add_option(
        type => 'Bool', title => 'cm-b', group => 'cm',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );
    my $map4 = $inst->option_map;
    ok($map4 != $map3, 'option_map regenerated after adding option');
    ok(exists $map4->{'--cm-b'}, 'new option in regenerated map');
};

subtest 'Instance: include with posts' => sub {
    my $src = Getopt::Yath::Instance->new();
    $src->add_option(
        type => 'Bool', title => 'ip-a', group => 'ip',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );
    my $post_ran = 0;
    $src->add_post_process(0, undef, sub { $post_ran++ });

    my $dst = Getopt::Yath::Instance->new();
    $dst->include($src);

    is(scalar @{$dst->options}, 1, 'option included');

    my $state = $dst->process_args([]);
    ok($post_ran, 'post-processor from included instance ran');
};

subtest 'Instance: include propagates nested included instances' => sub {
    my $inner = Getopt::Yath::Instance->new();
    $inner->add_option(
        type => 'Bool', title => 'ni-a', group => 'ni',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );

    my $middle = Getopt::Yath::Instance->new();
    $middle->include($inner);

    my $outer = Getopt::Yath::Instance->new();
    $outer->include($middle);

    ok(scalar @{$outer->options} >= 1, 'option from nested include available');
    my $included = $outer->included;
    ok(keys %$included > 0, 'included hash populated');
};

# ============================================================================
# BoolMap: doc_forms, default_*_examples, no_arg_value, notes, requires_arg true
# ============================================================================

subtest 'BoolMap: doc_forms and doc generation' => sub {
    package BoolMapDocTest;
    use Getopt::Yath;

    option_group {category => 'BM Docs', group => 'bmdoc', no_module => 1} => sub {
        option bm_doc => (
            type        => 'BoolMap',
            pattern     => qr/bmdoc-(.+)/,
            description => 'BoolMap doc test',
        );
    };

    package main;

    my $docs = BoolMapDocTest::options->docs('cli');
    ok(defined $docs, 'BoolMap CLI docs generated');
    like($docs, qr/bmdoc/, 'docs contain option name');

    my $pod = BoolMapDocTest::options->docs('pod', head => 3);
    ok(defined $pod, 'BoolMap POD docs generated');
    like($pod, qr/bmdoc/, 'POD contains option name');
    like($pod, qr{/\^--}, 'POD contains pattern form');
};

subtest 'BoolMap: no_arg_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type        => 'BoolMap',
        title       => 'bm-nav',
        group       => 'g',
        no_module   => 1,
        trace       => [caller],
        pattern     => qr/bmnav-(.+)/,
    );

    my @val = $opt->no_arg_value;
    is($val[0], 'bm_nav', 'no_arg_value returns field name');
    is($val[1], 1,         'no_arg_value returns 1');
};

subtest 'BoolMap: notes' => sub {
    my $opt = Getopt::Yath::Option->create(
        type        => 'BoolMap',
        title       => 'bm-notes',
        group       => 'g',
        no_module   => 1,
        trace       => [caller],
        pattern     => qr/bmnotes-(.+)/,
    );

    my @notes = $opt->notes;
    ok((grep { defined $_ && /multiple times/ } @notes), 'notes includes multiple times message');
};

subtest 'BoolMap: requires_arg true branch' => sub {
    my $opt = Getopt::Yath::Option->create(
        type         => 'BoolMap',
        title        => 'bm-ra',
        group        => 'g',
        no_module    => 1,
        trace        => [caller],
        pattern      => qr/bmra-(.+)/,
        requires_arg => 1,
    );

    ok($opt->requires_arg, 'requires_arg returns true when set');
};

# ============================================================================
# PathList: default_long_examples, default_short_examples
# ============================================================================

subtest 'PathList: doc generation exercises example methods' => sub {
    package PathListDocTest;
    use Getopt::Yath;

    option_group {category => 'PL Docs', group => 'pldoc', no_module => 1} => sub {
        option pl_doc => (
            type        => 'PathList',
            short       => 'P',
            description => 'PathList doc test',
        );
    };

    package main;

    my $docs = PathListDocTest::options->docs('cli');
    ok(defined $docs, 'PathList CLI docs generated');
    like($docs, qr/\*\.\*/, 'docs contain glob example');

    my $pod = PathListDocTest::options->docs('pod', head => 3);
    ok(defined $pod, 'PathList POD docs generated');
    like($pod, qr/\*\.\*/, 'POD contains glob example');
};

# ============================================================================
# Auto: get_env_value (both branches)
# ============================================================================

subtest 'Auto: get_env_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Auto',
        title     => 'auto-env',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        autofill  => 'x',
    );

    my $val = 'hello';
    is(($opt->get_env_value('VAR', \$val))[0], 'hello', 'Auto get_env_value returns value');
    is(($opt->get_env_value('!VAR', \$val))[0], 0,      'Auto get_env_value negated truthy');

    $val = 0;
    is(($opt->get_env_value('!VAR', \$val))[0], 1,      'Auto get_env_value negated falsy');
};

# ============================================================================
# Count: get_env_value negated, autofill //= 0 path
# ============================================================================

subtest 'Count: get_env_value negated' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Count',
        title      => 'cnt-neg',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => 0,
    );

    my $val = 3;
    is(($opt->get_env_value('!VAR', \$val))[0], 0, 'Count negated env truthy');

    $val = 0;
    is(($opt->get_env_value('!VAR', \$val))[0], 1, 'Count negated env falsy');
};

subtest 'Count: add_value with no args bumps from autofill' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Count',
        title      => 'cnt-af',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => 0,
    );

    # Start with undef to exercise the //= autofill path
    my $val = undef;
    $opt->add_value(\$val);
    is($val, 1, 'add_value with undef starts at autofill (0) then increments to 1');
};

# ============================================================================
# Scalar: get_env_value negated
# ============================================================================

subtest 'Scalar: get_env_value negated' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'scl-neg',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );

    my $val = 'truthy';
    is(($opt->get_env_value('!VAR', \$val))[0], 0, 'Scalar negated env truthy');

    $val = '';
    is(($opt->get_env_value('!VAR', \$val))[0], 1, 'Scalar negated env falsy');
};

# ============================================================================
# Yath.pm: inherit parameter
# ============================================================================

subtest 'Getopt::Yath: inherit parameter' => sub {
    # inherit includes options from $class->options. When used on Getopt::Yath
    # directly, it's a no-op since Getopt::Yath doesn't have options(). But the
    # code path (line 23) is still exercised.
    package CovInheritTest;
    use Getopt::Yath(inherit => 1);

    option_group {category => 'Inherit', group => 'inh', no_module => 1} => sub {
        option inh_flag => (type => 'Bool', description => 'Inherited test');
    };

    package main;

    my $res = CovInheritTest::parse_options(['--inh-flag']);
    is($res->settings->{inh}->{inh_flag}, 1, 'inherit param does not break normal usage');
};

# ============================================================================
# Option.pm: cli_docs with color, base class abstract stubs
# ============================================================================

subtest 'Option: cli_docs with color enabled' => sub {
    package ColorDocTest;
    use Getopt::Yath;

    option_group {category => 'Color', group => 'color', no_module => 1} => sub {
        option col_opt => (
            type        => 'Scalar',
            short       => 'C',
            description => 'Colored option',
        );
    };

    package main;

    my $docs = ColorDocTest::options->docs('cli', color => 1);
    ok(defined $docs, 'CLI docs with color=1 generated');
    # If Term::ANSIColor is available, docs will contain escape codes
    if (Getopt::Yath::Term::USE_COLOR()) {
        like($docs, qr/\e\[/, 'colored docs contain ANSI escapes');
    }
};

subtest 'Option: doc_sort_ops with group_first' => sub {
    package SortOpsTest;
    use Getopt::Yath;

    option_group {category => 'Cat A', group => 'grp_a', no_module => 1} => sub {
        option so_a1 => (type => 'Bool', description => 'A1');
        option so_a2 => (type => 'Bool', description => 'A2');
    };
    option_group {category => 'Cat B', group => 'grp_b', no_module => 1} => sub {
        option so_b1 => (type => 'Bool', description => 'B1');
    };

    package main;

    my $inst = SortOpsTest::options;
    my @opts = @{$inst->options};

    # Exercise the doc_sort_ops with group_first param
    my @sorted = sort { $inst->doc_sort_ops($a, $b, group_first => 1) } @opts;
    ok(@sorted > 0, 'doc_sort_ops with group_first works');
};

# ============================================================================
# Instance: option_map and option_groups with in_options parameter
# ============================================================================

subtest 'Instance: option_map with explicit options list' => sub {
    my $inst = Getopt::Yath::Instance->new();
    $inst->add_option(
        type => 'Bool', title => 'om-a', group => 'om',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );
    $inst->add_option(
        type => 'Scalar', title => 'om-b', group => 'om',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );

    # Pass a subset as in_options — bypasses cache
    my $subset = [$inst->options->[0]];
    my $map = $inst->option_map($subset);
    ok(exists $map->{'--om-a'}, 'subset map contains om-a');
    ok(!exists $map->{'--om-b'}, 'subset map does not contain om-b');

    my $groups = $inst->option_groups($subset);
    is($groups, {om => 1}, 'option_groups with in_options returns subset groups');
};

# ============================================================================
# Instance: process_args with pre-set settings
# ============================================================================

subtest 'Instance: process_args with pre-existing settings' => sub {
    package PresetSettingsTest;
    use Getopt::Yath;

    option_group {category => 'PS', group => 'ps', no_module => 1} => sub {
        option ps_flag => (type => 'Bool', description => 'Flag');
        option ps_val  => (type => 'Scalar', default => 'def', description => 'Val');
    };

    package main;

    my $settings = Getopt::Yath::Settings->new({ps => {ps_flag => 1, ps_val => 'preset'}});
    my $res = PresetSettingsTest::parse_options([], settings => $settings);

    # Pre-existing values should be preserved (not overwritten by defaults)
    is($res->settings->{ps}->{ps_flag}, 1,        'pre-set bool preserved');
    is($res->settings->{ps}->{ps_val},  'preset',  'pre-set scalar preserved');
};

# ============================================================================
# Instance: process_args with env and cleared params
# ============================================================================

subtest 'Instance: process_args with pre-set env/cleared/modules' => sub {
    package PresetEnvTest;
    use Getopt::Yath;

    option_group {category => 'PE', group => 'pe', no_module => 1} => sub {
        option pe_flag => (type => 'Bool', description => 'Flag');
    };

    package main;

    my %env = (EXISTING => 'val');
    my %cleared;
    my %modules;
    my $res = PresetEnvTest::parse_options(
        ['--pe-flag'],
        env     => \%env,
        cleared => \%cleared,
        modules => \%modules,
    );

    is($res->env->{EXISTING}, 'val', 'pre-set env preserved');
};

# ============================================================================
# List: condition coverage for split_on and maybe
# ============================================================================

subtest 'List: add_value with maybe and empty list' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'List',
        title     => 'lm',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        maybe     => 1,
    );

    my $ref = [];
    # maybe + no values = no-op
    $opt->add_value(\$ref);
    is($ref, [], 'maybe list add_value with no args is no-op');
};

# ============================================================================
# AutoPathList: doc generation
# ============================================================================

subtest 'AutoPathList: doc generation' => sub {
    package AutoPathListDocTest;
    use Getopt::Yath;

    option_group {category => 'APL Docs', group => 'apldoc', no_module => 1} => sub {
        option apl_doc => (
            type        => 'AutoPathList',
            short       => 'A',
            autofill    => sub { 'lib' },
            description => 'AutoPathList doc test',
        );
    };

    package main;

    my $docs = AutoPathListDocTest::options->docs('cli');
    ok(defined $docs, 'AutoPathList CLI docs generated');
    like($docs, qr/\*\.\*/, 'docs contain glob example');
};

# ============================================================================
# Option: allowed_values_text in docs
# ============================================================================

subtest 'Option: allowed_values_text in cli_docs' => sub {
    package AVTextTest;
    use Getopt::Yath;

    option_group {category => 'AV Text', group => 'avt', no_module => 1} => sub {
        option avt_opt => (
            type               => 'Scalar',
            allowed_values      => ['a', 'b', 'c'],
            allowed_values_text => 'a, b, or c',
            description        => 'Option with allowed values text',
        );
    };

    package main;

    my $docs = AVTextTest::options->docs('cli');
    like($docs, qr/Allowed Values: a, b, or c/, 'allowed_values_text appears in docs');
};

subtest 'Option: allowed_values array in cli_docs' => sub {
    package AVArrayTest;
    use Getopt::Yath;

    option_group {category => 'AV Array', group => 'ava', no_module => 1} => sub {
        option ava_opt => (
            type           => 'Scalar',
            allowed_values => ['x', 'y', 'z'],
            description    => 'Option with allowed values array',
        );
    };

    package main;

    my $docs = AVArrayTest::options->docs('cli');
    like($docs, qr/Allowed Values: x, y, z/, 'allowed_values array appears in docs');
};

# ============================================================================
# Option: default_text and autofill_text in docs
# ============================================================================

subtest 'Option: default_text in cli_docs' => sub {
    package DTextTest;
    use Getopt::Yath;

    option_group {category => 'DT', group => 'dt', no_module => 1} => sub {
        option dt_opt => (
            type         => 'Bool',
            default      => 1,
            default_text => 'enabled by default',
            description  => 'With default text',
        );
    };

    package main;

    my $docs = DTextTest::options->docs('cli');
    like($docs, qr/default: enabled by default/, 'default_text appears in docs');
};

# ============================================================================
# Instance: docs returning empty when no options
# ============================================================================

subtest 'Instance: docs with no options' => sub {
    my $inst = Getopt::Yath::Instance->new();
    my $docs = $inst->docs('cli');
    ok(!$docs, 'docs returns falsy when no options');
};

# ============================================================================
# Instance: clear_cache
# ============================================================================

subtest 'Instance: clear_cache' => sub {
    my $inst = Getopt::Yath::Instance->new();
    $inst->add_option(
        type => 'Bool', title => 'cc-a', group => 'cc',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );

    # Populate caches
    $inst->option_map;
    $inst->option_groups;

    $inst->clear_cache;

    # After clear, re-generating should work
    my $map = $inst->option_map;
    ok(exists $map->{'--cc-a'}, 'option_map works after clear_cache');
};

# ============================================================================
# Yath.pm condition coverage: option_post_process error, inst_class param
# ============================================================================

subtest 'Getopt::Yath: option_post_process without coderef' => sub {
    package PostProcErr;
    use Getopt::Yath;

    option_group {category => 'PPE', group => 'ppe', no_module => 1} => sub {
        option ppe_flag => (type => 'Bool', description => 'Flag');
    };

    package main;

    like(
        dies { PostProcErr::option_post_process("not a coderef") },
        qr/You must provide a callback coderef/,
        'option_post_process rejects non-coderef',
    );
};

# ============================================================================
# Instance: doc_sort_ops prefix comparison
# ============================================================================

subtest 'Instance: doc_sort_ops with prefixes' => sub {
    package PrefixSortTest;
    use Getopt::Yath;

    option_group {category => 'Same Cat', group => 'same', prefix => 'aaa', no_module => 1} => sub {
        option ps_opt1 => (type => 'Bool', description => 'Opt1');
    };
    option_group {category => 'Same Cat', group => 'same', prefix => 'zzz', no_module => 1} => sub {
        option ps_opt2 => (type => 'Bool', description => 'Opt2');
    };

    package main;

    # Generate docs — this exercises the prefix sort comparison
    my $docs = PrefixSortTest::options->docs('cli');
    ok(defined $docs, 'docs with mixed prefixes generated');
    my $pos1 = index($docs, 'aaa-ps-opt1');
    my $pos2 = index($docs, 'zzz-ps-opt2');
    ok($pos1 < $pos2, 'prefix aaa sorts before zzz');
};

# ============================================================================
# Count: get_autofill_value with explicit autofill set
# ============================================================================

subtest 'Count: get_autofill_value with explicit autofill' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Count',
        title      => 'cnt-af2',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => 0,
    );

    # get_autofill_value calls SUPER which returns undef, then // 0
    my @af = $opt->get_autofill_value;
    is($af[0], 0, 'Count autofill defaults to 0');
};

subtest 'Count: add_value when ref already defined' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Count',
        title      => 'cnt-ad',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => 0,
    );

    my $val = 5;
    $opt->add_value(\$val);  # No args — increments
    is($val, 6, 'add_value increments when already defined');
};

# ============================================================================
# List: condition coverage for clear and initialize with values
# ============================================================================

subtest 'List: get_clear_value with explicit clear' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'List',
        title     => 'lc',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        clear     => sub { ['sentinel'] },
    );

    my $cv = $opt->get_clear_value;
    is($cv, ['sentinel'], 'List get_clear_value uses explicit clear');
};

subtest 'List: get_initial_value with explicit initialize' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'List',
        title      => 'li',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => sub { ['pre'] },
    );

    delete local $ENV{NONEXISTENT_VAR_XYZ};
    my $iv = $opt->get_initial_value;
    is($iv, ['pre'], 'List get_initial_value uses explicit initialize');
};

subtest 'List: add_value with maybe=false and no values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'List',
        title     => 'lnm',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );

    my $ref = [];
    # Non-maybe list with no values still pushes (empty push is no-op)
    $opt->add_value(\$ref);
    is($ref, [], 'non-maybe list add_value with no args');
};

# ============================================================================
# Instance: process_args with multiple values error for non-list option
# ============================================================================

subtest 'Instance: group arg to non-list option errors' => sub {
    package GroupNonListTest;
    use Getopt::Yath;

    option_group {category => 'GNL', group => 'gnl', no_module => 1} => sub {
        option gnl_scalar => (type => 'Scalar', description => 'A scalar');
    };

    package main;

    like(
        dies {
            GroupNonListTest::parse_options(
                ['--gnl-scalar', ':{', 'a', 'b', '}:'],
                groups => {':{' => '}:'},
            )
        },
        qr/cannot take multiple values/,
        'group arg to non-list scalar option dies',
    );
};

# ============================================================================
# Instance: docs with color => 0 explicitly
# ============================================================================

subtest 'Instance: docs with color explicitly disabled' => sub {
    package ColorOffTest;
    use Getopt::Yath;

    option_group {category => 'CO', group => 'co', no_module => 1} => sub {
        option co_flag => (type => 'Bool', description => 'A flag');
    };

    package main;

    my $docs = ColorOffTest::options->docs('cli', color => 0);
    unlike($docs, qr/\e\[/, 'no ANSI escapes with color => 0');
};

# ============================================================================
# Instance: option_map duplicate form detection
# ============================================================================

subtest 'Instance: duplicate option form detection' => sub {
    my $inst = Getopt::Yath::Instance->new();

    $inst->add_option(
        type => 'Bool', title => 'dup-test', group => 'dup',
        no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
    );

    # Manually re-add the same option (bypassing dedup by using _option directly)
    # The dedup prevents this, so let's test the form collision with a different option
    # that has the same form via alt
    like(
        dies {
            $inst->add_option(
                type => 'Bool', title => 'dup-test2', group => 'dup',
                no_module => 1, trace => [__PACKAGE__, __FILE__, __LINE__],
                alt => ['dup-test'],  # Conflicts with --dup-test from first option
            );
            $inst->option_map;  # Force map rebuild to trigger collision
        },
        qr/Option form '.*dup-test' defined twice/,
        'duplicate option form detected',
    );
};

# ============================================================================
# Yath.pm: already-defined export error
# ============================================================================

# ============================================================================
# Count: get_autofill_value with explicit autofill to cover // 0 left side
# ============================================================================

subtest 'Count: add_value bump from 0 autofill' => sub {
    # Exercises the $$ref //= get_autofill_value path where autofill returns 0
    my $opt = Getopt::Yath::Option->create(
        type       => 'Count',
        title      => 'cnt-af3',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => 0,
    );

    # get_autofill_value should return 0 (SUPER returns undef, // 0 kicks in)
    my @af = $opt->get_autofill_value;
    is($af[0], 0, 'Count get_autofill_value returns 0');
};

# ============================================================================
# Map: get_initial_value and get_clear_value with explicit values
# ============================================================================

subtest 'Map: get_initial_value with explicit initialize' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Map',
        title      => 'mi',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        initialize => sub { {pre => 'set'} },
    );

    my $iv = $opt->get_initial_value;
    is($iv, {pre => 'set'}, 'Map get_initial_value uses explicit initialize');
};

subtest 'Map: get_clear_value with explicit clear' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Map',
        title     => 'mc',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        clear     => sub { {cleared => 1} },
    );

    my $cv = $opt->get_clear_value;
    is($cv, {cleared => 1}, 'Map get_clear_value uses explicit clear');
};

# ============================================================================
# Option.pm: cli_docs with notes dedup and autofill_text
# ============================================================================

subtest 'Option: autofill_text in docs' => sub {
    package AutofillTextTest;
    use Getopt::Yath;

    option_group {category => 'AFT', group => 'aft', no_module => 1} => sub {
        option aft_opt => (
            type          => 'Auto',
            autofill      => 'x',
            autofill_text => 'uses x by default',
            description   => 'With autofill text',
        );
    };

    package main;

    my $docs = AutofillTextTest::options->docs('cli');
    like($docs, qr/autofill: uses x by default/, 'autofill_text appears in docs');
};

# ============================================================================
# Option.pm: pod_docs generation
# ============================================================================

subtest 'Option: pod_docs exercises env display and notes' => sub {
    package PodDocsTest;
    use Getopt::Yath;

    option_group {category => 'PodDoc', group => 'poddoc', no_module => 1} => sub {
        option pd_opt => (
            type           => 'Scalar',
            from_env_vars  => ['PD_TEST_VAR'],
            clear_env_vars => ['PD_CLEAR_VAR'],
            set_env_vars   => ['PD_SET_VAR'],
            description    => 'Pod doc test option',
        );

        # Use List type which overrides notes() to return a list
        option pd_list => (
            type        => 'List',
            description => 'A list option for notes test',
        );
    };

    package main;

    my $pod = PodDocsTest::options->docs('pod', head => 3);
    like($pod, qr/Can also be set.*PD_TEST_VAR/, 'POD shows from_env_vars');
    like($pod, qr/cleared.*PD_CLEAR_VAR/, 'POD shows clear_env_vars');
    like($pod, qr/set after.*PD_SET_VAR/, 'POD shows set_env_vars');
    like($pod, qr/Can be specified multiple times/, 'POD shows notes from List type');
};

# ============================================================================
# Instance: doc_sort_ops group_first with same category different groups
# ============================================================================

subtest 'Instance: doc_sort_ops exercises all sort branches' => sub {
    package SortBranchTest;
    use Getopt::Yath;

    # Same category, different groups — exercises group cmp after category cmp
    option_group {category => 'Common', group => 'z_group', no_module => 1} => sub {
        option sb_z => (type => 'Bool', description => 'Z');
    };
    option_group {category => 'Common', group => 'a_group', no_module => 1} => sub {
        option sb_a => (type => 'Bool', description => 'A');
    };
    # Different category — exercises category cmp
    option_group {category => 'Another', group => 'b_group', no_module => 1} => sub {
        option sb_b => (type => 'Bool', description => 'B');
    };

    package main;

    my $docs = SortBranchTest::options->docs('cli');
    ok(defined $docs, 'docs with same-category different-group options');

    # Also exercise group_first sort path
    my $inst = SortBranchTest::options;
    my @opts = @{$inst->options};
    my @sorted = sort { $inst->doc_sort_ops($a, $b, group_first => 1) } @opts;
    ok(@sorted > 0, 'group_first sort works');
};

subtest 'Getopt::Yath: error on existing method conflict' => sub {
    like(
        dies {
            package ExistingMethodPkg;
            sub options { 'already here' }
            Getopt::Yath->import();
        },
        qr/already has an 'options' method/,
        'import dies when method already exists',
    );
};

done_testing;
