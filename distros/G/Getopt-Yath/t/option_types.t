use Test2::V0;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;

use Getopt::Yath;

# Clean env
delete $ENV{$_} for qw/OT_TEST_A OT_TEST_B/;

subtest 'BoolMap pattern matching' => sub {
    package BoolMapTest;
    use Getopt::Yath;

    option_group {category => 'BoolMap Tests', group => 'boolmap', no_module => 1} => sub {
        option features => (
            type        => 'BoolMap',
            pattern     => qr/feature-(.+)/,
            description => 'Feature flags',
        );
    };

    package main;

    my $res = BoolMapTest::parse_options(['--feature-foo', '--feature-bar', '--no-feature-baz']);
    is(
        $res->settings->{boolmap}->{features},
        {foo => 1, bar => 1, baz => 0},
        'BoolMap matches patterns and respects --no- prefix',
    );

    $res = BoolMapTest::parse_options(['--no-features']);
    is(
        $res->settings->{boolmap}->{features},
        {},
        'BoolMap --no clears all values',
    );
};

subtest 'PathList glob expansion' => sub {
    my $dir = tempdir(CLEANUP => 1);
    for my $name (qw/alpha.txt beta.txt gamma.log/) {
        open my $fh, '>', "$dir/$name" or die "Cannot create $dir/$name: $!";
        close $fh;
    }

    package PathListTest;
    use Getopt::Yath;

    option_group {category => 'PathList Tests', group => 'pathlist', no_module => 1} => sub {
        option files => (
            type        => 'PathList',
            description => 'File list',
        );
    };

    package main;

    my $res = PathListTest::parse_options(['--files', "$dir/*.txt"]);
    my @files = sort @{$res->settings->{pathlist}->{files}};
    is(\@files, ["$dir/alpha.txt", "$dir/beta.txt"], 'PathList expands globs');

    $res = PathListTest::parse_options(['--files', "$dir/gamma.log"]);
    is($res->settings->{pathlist}->{files}, ["$dir/gamma.log"], 'PathList passes non-glob through');
};

subtest 'List JSON parsing' => sub {
    package ListJsonTest;
    use Getopt::Yath;

    option_group {category => 'List JSON', group => 'listjson', no_module => 1} => sub {
        option items => (
            type        => 'List',
            description => 'Items list',
        );
    };

    package main;

    my $res = ListJsonTest::parse_options(['--items', '["aaa","bbb","ccc"]']);
    is(
        $res->settings->{listjson}->{items},
        ['aaa', 'bbb', 'ccc'],
        'List parses JSON array input',
    );
};

subtest 'Map JSON parsing' => sub {
    package MapJsonTest;
    use Getopt::Yath;

    option_group {category => 'Map JSON', group => 'mapjson', no_module => 1} => sub {
        option kvs => (
            type        => 'Map',
            description => 'Key-value pairs',
        );
    };

    package main;

    my $res = MapJsonTest::parse_options(['--kvs', '{"x":"1","y":"2"}']);
    is(
        $res->settings->{mapjson}->{kvs},
        {x => '1', y => '2'},
        'Map parses JSON object input',
    );
};

subtest 'Map custom key_on delimiter' => sub {
    package MapKeyOnTest;
    use Getopt::Yath;

    option_group {category => 'Map KeyOn', group => 'mapkeyon', no_module => 1} => sub {
        option pairs => (
            type        => 'Map',
            key_on      => ':',
            description => 'Colon-separated pairs',
        );
    };

    package main;

    my $res = MapKeyOnTest::parse_options(['--pairs', 'host:localhost']);
    is(
        $res->settings->{mapkeyon}->{pairs},
        {host => 'localhost'},
        'Map uses custom key_on delimiter',
    );
};

subtest 'Bool set_env_vars' => sub {
    package BoolEnvTest;
    use Getopt::Yath;

    option_group {category => 'Bool Env', group => 'boolenv', no_module => 1} => sub {
        option loud => (
            type         => 'Bool',
            set_env_vars => ['OT_TEST_A'],
            description  => 'Loud mode',
        );
    };

    package main;

    local $ENV{OT_TEST_A};
    my $res = BoolEnvTest::parse_options(['--loud']);
    is($res->env->{OT_TEST_A}, 1, 'Bool set_env_vars sets env to 1 when true');
    is($ENV{OT_TEST_A}, 1, 'ENV actually set');

    local $ENV{OT_TEST_A};
    $res = BoolEnvTest::parse_options(['--loud'], no_set_env => 1);
    is($res->env->{OT_TEST_A}, 1, 'env recorded in state');
    ok(!$ENV{OT_TEST_A}, 'ENV not set with no_set_env');
};

subtest 'Count set_env_vars' => sub {
    package CountEnvTest;
    use Getopt::Yath;

    option_group {category => 'Count Env', group => 'cntenv', no_module => 1} => sub {
        option verbosity => (
            type         => 'Count',
            short        => 'V',
            set_env_vars => ['OT_TEST_B'],
            initialize   => 0,
            description  => 'Verbosity level',
        );
    };

    package main;

    local $ENV{OT_TEST_B};
    my $res = CountEnvTest::parse_options(['-VVV']);
    is($res->env->{OT_TEST_B}, 3, 'Count set_env_vars captures counter value');
};

subtest 'Scalar with allowed_values at parse time' => sub {
    package ScalarAVTest;
    use Getopt::Yath;

    option_group {category => 'Scalar AV', group => 'sav', no_module => 1} => sub {
        option level => (
            type           => 'Scalar',
            allowed_values => ['low', 'medium', 'high'],
            description    => 'Level setting',
        );
    };

    package main;

    my $res = ScalarAVTest::parse_options(['--level', 'medium']);
    is($res->settings->{sav}->{level}, 'medium', 'valid allowed_values accepted');

    like(
        dies { ScalarAVTest::parse_options(['--level', 'extreme']) },
        qr/Invalid value.*'extreme'/,
        'invalid allowed_values rejected at parse time',
    );
};

subtest 'Scalar with normalize' => sub {
    package NormTest;
    use Getopt::Yath;

    option_group {category => 'Norm', group => 'norm', no_module => 1} => sub {
        option mode => (
            type        => 'Scalar',
            normalize   => sub { lc $_[0] },
            description => 'Mode',
        );
    };

    package main;

    my $res = NormTest::parse_options(['--mode', 'UPPER']);
    is($res->settings->{norm}->{mode}, 'upper', 'normalize callback applied during parsing');
};

subtest 'maybe option attribute' => sub {
    package MaybeTest;
    use Getopt::Yath;

    option_group {category => 'Maybe', group => 'maybe', no_module => 1} => sub {
        option optional => (
            type        => 'Bool',
            maybe       => 1,
            description => 'An optional bool',
        );

        option opt_list => (
            type        => 'List',
            maybe       => 1,
            description => 'An optional list',
        );
    };

    package main;

    my $res = MaybeTest::parse_options([]);
    is($res->settings->{maybe}->{optional}, undef, 'maybe Bool has no default');
    is($res->settings->{maybe}->{opt_list}, undef, 'maybe List has no initial value');
};

subtest 'List JSON parse error' => sub {
    package ListJsonErrTest;
    use Getopt::Yath;

    option_group {category => 'LJSON Err', group => 'ljerr', no_module => 1} => sub {
        option bad_json_list => (
            type        => 'List',
            description => 'Bad JSON list',
        );
    };

    package main;

    # Input must match /^\s*\[.*\]\s*$/s to trigger JSON parsing
    like(
        dies { ListJsonErrTest::parse_options(['--bad-json-list', '[invalid json]']) },
        qr/Could not decode JSON string/,
        'List dies on invalid JSON array',
    );
};

subtest 'Map JSON parse error' => sub {
    package MapJsonErrTest;
    use Getopt::Yath;

    option_group {category => 'MJSON Err', group => 'mjerr', no_module => 1} => sub {
        option bad_json_map => (
            type        => 'Map',
            description => 'Bad JSON map',
        );
    };

    package main;

    like(
        dies { MapJsonErrTest::parse_options(['--bad-json-map', '{invalid json}']) },
        qr/Could not decode JSON string/,
        'Map dies on invalid JSON object',
    );
};

subtest 'Map normalize_value with multiple inputs' => sub {
    package MapMultiInputTest;
    use Getopt::Yath;

    option_group {category => 'Map Multi', group => 'mapmulti', no_module => 1} => sub {
        option multi_map => (
            type        => 'Map',
            normalize   => sub { @_ },
            description => 'Multi-input map',
        );
    };

    package main;

    # When normalize_value gets >1 args, it calls SUPER::normalize_value directly
    my $opt = MapMultiInputTest::options->options->[0];
    my %result = $opt->normalize_value('key', 'val');
    is(\%result, {key => 'val'}, 'Map normalize_value with >1 inputs passes through to SUPER');
};

subtest 'List with from_env_vars' => sub {
    package ListEnvTest;
    use Getopt::Yath;

    option_group {category => 'List Env', group => 'listenv', no_module => 1} => sub {
        option env_list => (
            type          => 'List',
            from_env_vars => ['GETOPT_LIST_TEST_A', 'GETOPT_LIST_TEST_B'],
            description   => 'Env list',
        );
    };

    package main;

    local $ENV{GETOPT_LIST_TEST_A} = 'aval';
    local $ENV{GETOPT_LIST_TEST_B} = 'bval';
    my $res = ListEnvTest::parse_options([]);
    is($res->settings->{listenv}->{env_list}, ['aval', 'bval'], 'List collects from multiple env vars');
};

subtest 'Map with from_env_vars' => sub {
    package MapEnvTest;
    use Getopt::Yath;

    option_group {category => 'Map Env', group => 'mapenv', no_module => 1} => sub {
        option env_map => (
            type          => 'Map',
            from_env_vars => ['GETOPT_MAP_TEST_X'],
            description   => 'Env map',
        );
    };

    package main;

    local $ENV{GETOPT_MAP_TEST_X} = 'xval';
    my $res = MapEnvTest::parse_options([]);
    is($res->settings->{mapenv}->{env_map}, {GETOPT_MAP_TEST_X => 'xval'}, 'Map uses env var name as key');
};

subtest 'Bool negated from_env_vars' => sub {
    package BoolNegEnvTest;
    use Getopt::Yath;

    option_group {category => 'Bool Neg Env', group => 'boolnegenv', no_module => 1} => sub {
        option quiet => (
            type          => 'Bool',
            from_env_vars => ['!GETOPT_BOOL_VERBOSE'],
            description   => 'Quiet mode',
        );
    };

    package main;

    local $ENV{GETOPT_BOOL_VERBOSE} = 1;
    my $res = BoolNegEnvTest::parse_options([]);
    is($res->settings->{boolnegenv}->{quiet}, 0, 'negated env: VERBOSE=1 means quiet=0');

    local $ENV{GETOPT_BOOL_VERBOSE} = 0;
    $res = BoolNegEnvTest::parse_options([]);
    is($res->settings->{boolnegenv}->{quiet}, 1, 'negated env: VERBOSE=0 means quiet=1');
};

subtest 'Bool negated set_env_vars' => sub {
    package BoolNegSetTest;
    use Getopt::Yath;

    option_group {category => 'Bool Neg Set', group => 'boolnegset', no_module => 1} => sub {
        option be_quiet => (
            type         => 'Bool',
            set_env_vars => ['!GETOPT_BNEG_VERBOSE'],
            description  => 'Quiet',
        );
    };

    package main;

    local $ENV{GETOPT_BNEG_VERBOSE};
    my $res = BoolNegSetTest::parse_options(['--be-quiet']);
    is($ENV{GETOPT_BNEG_VERBOSE}, 0, 'negated set_env: --be-quiet (true) sets !VERBOSE to 0');

    local $ENV{GETOPT_BNEG_VERBOSE};
    $res = BoolNegSetTest::parse_options(['--no-be-quiet']);
    is($ENV{GETOPT_BNEG_VERBOSE}, 1, 'negated set_env: --no-be-quiet (false) sets !VERBOSE to 1');
};

subtest 'Scalar negated set_env_vars' => sub {
    package ScalarNegSetTest;
    use Getopt::Yath;

    option_group {category => 'Scl Neg Set', group => 'sclnegset', no_module => 1} => sub {
        option flag_val => (
            type         => 'Scalar',
            set_env_vars => ['!GETOPT_SNEG_FLAG'],
            description  => 'Flag value',
        );
    };

    package main;

    local $ENV{GETOPT_SNEG_FLAG};
    my $res = ScalarNegSetTest::parse_options(['--flag-val', 'truthy']);
    is($ENV{GETOPT_SNEG_FLAG}, 0, 'negated set_env: truthy scalar value negates to 0');

    local $ENV{GETOPT_SNEG_FLAG};
    $res = ScalarNegSetTest::parse_options(['--flag-val', '0']);
    is($ENV{GETOPT_SNEG_FLAG}, 1, 'negated set_env: falsy scalar value negates to 1');
};

subtest 'PathList empty glob' => sub {
    my $dir = tempdir(CLEANUP => 1);

    package PathListEmptyTest;
    use Getopt::Yath;

    option_group {category => 'PL Empty', group => 'plempty', no_module => 1} => sub {
        option no_match => (
            type        => 'PathList',
            description => 'No matches',
        );
    };

    package main;

    my $res = PathListEmptyTest::parse_options(['--no-match', "$dir/*.zzz_nonexistent"]);
    is($res->settings->{plempty}->{no_match}, [], 'PathList with no glob matches returns empty');
};

subtest 'BoolMap with custom_matches coderef' => sub {
    package BoolMapCustomTest;
    use Getopt::Yath;

    option_group {category => 'BM Custom', group => 'bmcustom', no_module => 1} => sub {
        option bm_custom => (
            type           => 'BoolMap',
            pattern        => qr/bmcflag-(.+)/,
            custom_matches => sub {
                my ($self, $input, $state) = @_;
                return unless $input =~ m/^--(?:no-)?bmcflag-(.+)$/;
                my $key = $1;
                my $no = $input =~ m/^--no-/;
                return ($self, 1, [$key => $no ? 0 : 1]);
            },
            description => 'BoolMap with custom matcher',
        );
    };

    package main;

    my $res = BoolMapCustomTest::parse_options(['--bmcflag-alpha', '--no-bmcflag-beta']);
    is(
        $res->settings->{bmcustom}->{bm_custom},
        {alpha => 1, beta => 0},
        'BoolMap custom_matches coderef works',
    );
};

subtest 'Count get_env_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type         => 'Count',
        title        => 'cntenv',
        group        => 'g',
        no_module    => 1,
        trace        => [caller],
        initialize   => 0,
    );
    my $val = 3;
    my @ev = $opt->get_env_value('SOME_VAR', \$val);
    is($ev[0], 3, 'Count get_env_value returns counter value');
};

subtest 'Scalar get_env_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'sclenv2',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    my $val = 'hello';
    my @ev = $opt->get_env_value('SOME_VAR', \$val);
    is($ev[0], 'hello', 'Scalar get_env_value returns value');
};

subtest 'Bool get_env_value negated' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'benv',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    my $val = 1;
    is(($opt->get_env_value('VAR', \$val))[0], 1, 'Bool env value for true');
    is(($opt->get_env_value('!VAR', \$val))[0], 0, 'Bool negated env value for true');
    $val = 0;
    is(($opt->get_env_value('VAR', \$val))[0], 0, 'Bool env value for false');
    is(($opt->get_env_value('!VAR', \$val))[0], 1, 'Bool negated env value for false');
};

subtest 'List split_on with regex' => sub {
    package ListSplitRegexTest;
    use Getopt::Yath;

    option_group {category => 'List Split', group => 'listsplit', no_module => 1} => sub {
        option split_items => (
            type        => 'List',
            split_on    => qr/[;,]/,
            description => 'Split list',
        );
    };

    package main;

    my $res = ListSplitRegexTest::parse_options(['--split-items', 'a,b;c']);
    is($res->settings->{listsplit}->{split_items}, [qw/a b c/], 'List splits on regex');
};

subtest 'Map split_on' => sub {
    package MapSplitTest;
    use Getopt::Yath;

    option_group {category => 'Map Split', group => 'mapsplit', no_module => 1} => sub {
        option split_pairs => (
            type        => 'Map',
            split_on    => ',',
            description => 'Split map',
        );
    };

    package main;

    my $res = MapSplitTest::parse_options(['--split-pairs', 'a=1,b=2']);
    is($res->settings->{mapsplit}->{split_pairs}, {a => 1, b => 2}, 'Map splits on delimiter');
};

subtest 'Count explicit value then increment' => sub {
    package CountMixTest;
    use Getopt::Yath;

    option_group {category => 'Count Mix', group => 'cntmix', no_module => 1} => sub {
        option cntm => (
            type        => 'Count',
            short       => 'C',
            initialize  => 0,
            description => 'Mixed counter',
        );
    };

    package main;

    my $res = CountMixTest::parse_options(['-C=10', '-C', '-C']);
    is($res->settings->{cntmix}->{cntm}, 12, 'Count: set to 10 then increment twice');
};

subtest 'maybe Map has no initial value' => sub {
    package MaybeMapTest;
    use Getopt::Yath;

    option_group {category => 'Maybe Map', group => 'maybemap', no_module => 1} => sub {
        option opt_map => (
            type        => 'Map',
            maybe       => 1,
            description => 'An optional map',
        );
    };

    package main;

    my $res = MaybeMapTest::parse_options([]);
    is($res->settings->{maybemap}->{opt_map}, undef, 'maybe Map has no initial value');
};

done_testing;
