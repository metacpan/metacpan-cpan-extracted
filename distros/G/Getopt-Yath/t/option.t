use Test2::V0;

use Getopt::Yath::Option;

subtest 'create factory' => sub {
    my $opt = Getopt::Yath::Option->create(
        type        => 'Bool',
        title       => 'test-opt',
        group       => 'testing',
        no_module   => 1,
        trace       => [__PACKAGE__, __FILE__, __LINE__],
        description => 'a test option',
    );
    isa_ok($opt, 'Getopt::Yath::Option::Bool');
    is($opt->title, 'test-opt', 'title set');
    is($opt->field, 'test_opt', 'field derived from title (dashes to underscores)');
    is($opt->name,  'test-opt', 'name derived from title (underscores to dashes)');
    is($opt->group, 'testing',  'group set');
};

subtest 'create requires type' => sub {
    like(
        dies { Getopt::Yath::Option->create(title => 'x', group => 'g', no_module => 1, trace => [caller]) },
        qr/No 'type' specified/,
        'create dies without type',
    );
};

subtest 'create cannot be called on subclass' => sub {
    like(
        dies { Getopt::Yath::Option::Bool->create(type => 'Bool', title => 'x', group => 'g', no_module => 1, trace => [caller]) },
        qr/create\(\) cannot be called on an option subclass/,
        'create dies on subclass',
    );
};

subtest 'trace_string' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'ts',
        group     => 'g',
        no_module => 1,
        trace     => ['main', 'myfile.pl', 42],
    );
    is($opt->trace_string, 'myfile.pl line 42', 'trace_string formatted correctly');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'ts2',
        group     => 'g',
        no_module => 1,
        trace     => ['main', 'other.pl', 99],
    );
    $opt2->{trace} = undef;
    is($opt2->trace_string, '[UNKNOWN]', 'trace_string with no trace');
};

subtest 'forms' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'my-val',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        short     => 'V',
        alt       => ['val'],
    );

    my $forms = $opt->forms;
    is($forms->{'--my-val'},    1,  '--name is positive');
    is($forms->{'--no-my-val'}, -1, '--no-name is negative');
    is($forms->{'--val'},       1,  '--alt is positive');
    is($forms->{'--no-val'},    -1, '--no-alt is negative');
    is($forms->{'-V'},          1,  '-short is positive');
};

subtest 'forms with prefix' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'verbose',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        prefix    => 'runner',
    );

    my $forms = $opt->forms;
    ok($forms->{'--runner-verbose'},    'prefixed positive form');
    ok($forms->{'--no-runner-verbose'}, 'prefixed negative form');
    ok(!$forms->{'--verbose'},          'unprefixed form not present');
};

subtest 'forms with alt_no' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'color',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        alt_no    => ['no-colour'],
    );

    my $forms = $opt->forms;
    is($forms->{'--no-colour'}, -1, 'alt_no form is negative');
    is($forms->{'--color'},      1, 'primary form is positive');
};

subtest 'is_applicable' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Bool',
        title      => 'cond',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        applicable => sub { 0 },
    );
    ok(!$opt->is_applicable(undef, undef), 'applicable returns false');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'always',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    ok($opt2->is_applicable(undef, undef), 'no applicable callback means always applicable');
};

subtest 'normalize_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'norm',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        normalize => sub { uc $_[0] },
    );
    is(($opt->normalize_value('hello'))[0], 'HELLO', 'normalize callback applied');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'no-norm',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    is(($opt2->normalize_value('hello'))[0], 'hello', 'no normalize is passthrough');
};

subtest 'check_value with arrayref allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'av',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => ['red', 'green', 'blue'],
    );

    my @bad = $opt->check_value(['red']);
    is(\@bad, [], 'valid value passes');

    @bad = $opt->check_value(['purple']);
    is(\@bad, ['purple'], 'invalid value returned');

    @bad = $opt->check_value(['red', 'purple', 'orange']);
    is(\@bad, ['purple', 'orange'], 'multiple invalid values returned');
};

subtest 'check_value with regex allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'avr',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => qr/^\d+$/,
    );

    my @bad = $opt->check_value(['123']);
    is(\@bad, [], 'numeric value passes regex');

    @bad = $opt->check_value(['abc']);
    is(\@bad, ['abc'], 'non-numeric value fails regex');
};

subtest 'check_value with coderef allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'avc',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => sub { $_[1] > 0 },
    );

    my @bad = $opt->check_value([5]);
    is(\@bad, [], 'positive value passes code check');

    @bad = $opt->check_value([-1]);
    is(\@bad, [-1], 'negative value fails code check');
};

subtest 'check_value with no allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'avn',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );

    my @bad = $opt->check_value(['anything']);
    is(\@bad, [], 'no allowed_values means everything passes');
};

subtest 'trigger' => sub {
    my @calls;
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'trig',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        trigger   => sub { push @calls, {@_[1..$#_]} },
    );

    $opt->trigger(action => 'set', val => 1);
    is(scalar @calls, 1, 'trigger called once');
    is($calls[0]->{action}, 'set', 'trigger received action');
};

subtest 'long_args' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'main-arg',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        alt       => ['alias-one', 'alias-two'],
    );

    is([$opt->long_args], ['main-arg', 'alias-one', 'alias-two'], 'long_args returns name + alts');
};

subtest 'init validation' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type  => 'Bool',
                group => 'g',
                trace => [caller],
                no_module => 1,
                # no title, field, or name
            )
        },
        qr/You must specify 'title' or both 'field' and 'name'/,
        'dies without title or field+name',
    );

    like(
        dies {
            Getopt::Yath::Option->create(
                type  => 'Bool',
                title => 'x',
                trace => [caller],
                # no module and no no_module
            )
        },
        qr/You must provide either 'module'/,
        'dies without module or no_module',
    );

    like(
        dies {
            Getopt::Yath::Option->create(
                type  => 'Bool',
                title => 'x',
                # no group
                trace     => [caller],
                no_module => 1,
            )
        },
        qr/The 'group' attribute is required/,
        'dies without group',
    );
};

subtest 'alt with underscore rejected' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Bool',
                title     => 'x',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                alt       => ['bad_alt'],
            )
        },
        qr/alt option form 'bad_alt' contains an underscore/,
        'underscore in alt rejected',
    );

    ok(
        lives {
            Getopt::Yath::Option->create(
                type                     => 'Bool',
                title                    => 'x2',
                group                    => 'g',
                no_module                => 1,
                trace                    => [caller],
                alt                      => ['ok_alt'],
                allow_underscore_in_alt  => 1,
            )
        },
        'underscore allowed when allow_underscore_in_alt is set',
    );
};

subtest 'title to field and name conversion' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'my-dashed-title',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    is($opt->field, 'my_dashed_title', 'dashes in title become underscores in field');
    is($opt->name,  'my-dashed-title', 'name keeps dashes');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'my_under_title',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    is($opt2->field, 'my_under_title', 'field keeps underscores');
    is($opt2->name,  'my-under-title', 'underscores in title become dashes in name');
};

subtest 'explicit field and name override title' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'orig',
        field     => 'custom_field',
        name      => 'custom-name',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    is($opt->field, 'custom_field', 'explicit field used');
    is($opt->name,  'custom-name',  'explicit name used');
};

subtest 'field and name without title' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        field     => 'my_field',
        name      => 'my-name',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    is($opt->field, 'my_field', 'field set directly');
    is($opt->name,  'my-name',  'name set directly');
};

subtest 'set_env_vars on non-env type' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type         => 'List',
                title        => 'sev',
                group        => 'g',
                no_module    => 1,
                trace        => [caller],
                set_env_vars => ['FOO'],
            )
        },
        qr/'set_env_vars' is not supported/,
        'set_env_vars on type where can_set_env is false',
    );
};

subtest 'autofill not allowed on wrong type' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Scalar',
                title     => 'af',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                autofill  => 'x',
            )
        },
        qr/'autofill' is not allowed/,
        'autofill rejected on Scalar type',
    );
};

subtest 'default not allowed on Count type' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Count',
                title     => 'df',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                default   => 5,
            )
        },
        qr/'default' is not allowed/,
        'default rejected on Count type',
    );
};

subtest 'invalid attribute key' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type           => 'Bool',
                title          => 'iak',
                group          => 'g',
                no_module      => 1,
                trace          => [caller],
                bogus_nonsense => 42,
            )
        },
        qr/'bogus_nonsense' is not a valid option attribute/,
        'invalid attribute key in constructor',
    );
};

subtest 'alt must be arrayref' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Bool',
                title     => 'aa',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                alt       => 'not-an-array',
            )
        },
        qr/The 'alt' attribute must be an array-ref/,
        'alt as string rejected',
    );
};

subtest 'alt_no must be arrayref' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Bool',
                title     => 'ano',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                alt_no    => 'not-an-array',
            )
        },
        qr/The 'alt_no' attribute must be an array-ref/,
        'alt_no as string rejected',
    );
};

subtest 'non-CODE ref in default rejected' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Bool',
                title     => 'ncr',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                default   => [1, 2],
            )
        },
        qr/'default' must be a simple scalar, or a coderef/,
        'arrayref default rejected',
    );
};

subtest 'non-CODE ref in normalize rejected' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Scalar',
                title     => 'ncn',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                normalize => 'not a code ref',
            )
        },
        qr/'normalize' must be undef, or a coderef/,
        'string normalize rejected',
    );
};

subtest 'clear_field' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'clf',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    my $val = 1;
    $opt->clear_field(\$val);
    is($val, 0, 'Bool clear_field sets to 0');
};

subtest 'get_initial_value from env' => sub {
    my $opt = Getopt::Yath::Option->create(
        type          => 'Scalar',
        title         => 'giv',
        group         => 'g',
        no_module     => 1,
        trace         => [caller],
        from_env_vars => ['GETOPT_TEST_INIT_A', 'GETOPT_TEST_INIT_B'],
    );

    delete local $ENV{GETOPT_TEST_INIT_A};
    local $ENV{GETOPT_TEST_INIT_B} = 'from_b';
    is($opt->get_initial_value(), 'from_b', 'skips unset env, uses first set');

    local $ENV{GETOPT_TEST_INIT_A} = 'from_a';
    is($opt->get_initial_value(), 'from_a', 'uses first set env var');
};

subtest 'get_initial_value negated env' => sub {
    my $opt = Getopt::Yath::Option->create(
        type          => 'Scalar',
        title         => 'gine',
        group         => 'g',
        no_module     => 1,
        trace         => [caller],
        from_env_vars => ['!GETOPT_TEST_NEG'],
    );

    local $ENV{GETOPT_TEST_NEG} = 1;
    is($opt->get_initial_value(), 0, 'negated env: truthy becomes 0');

    local $ENV{GETOPT_TEST_NEG} = 0;
    is($opt->get_initial_value(), 1, 'negated env: falsy becomes 1');
};

subtest 'get_default_value and get_autofill_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Auto',
        title     => 'gdv',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        default   => 'def_val',
        autofill  => 'auto_val',
    );
    is(($opt->get_default_value())[0],  'def_val',  'get_default_value returns default');
    is(($opt->get_autofill_value())[0], 'auto_val', 'get_autofill_value returns autofill');
};

subtest 'get_default_value with coderef' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'gdvc',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        default   => sub { 1 },
    );
    is(($opt->get_default_value())[0], 1, 'coderef default evaluated');
};

subtest 'forms caching' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'fc',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    my $f1 = $opt->forms;
    my $f2 = $opt->forms;
    ok($f1 == $f2, 'forms returns cached result (same ref)');
};

subtest 'doc_forms' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'docf',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        short     => 'd',
        alt       => ['doc-alias'],
        alt_no    => ['no-doc-alias'],
    );
    my ($forms, $no_forms) = $opt->doc_forms;
    ok(scalar @$forms > 0, 'doc_forms returns positive forms');
    ok((grep { /--docf / } @$forms), 'primary name in forms');
    ok((grep { /--doc-alias / } @$forms), 'alt name in forms');
    ok((grep { /-d/ } @$forms), 'short flag in forms');
    ok((grep { /--no-docf/ } @$no_forms), 'no-name in no_forms');
    ok((grep { /--no-doc-alias/ } @$no_forms), 'alt_no in no_forms');
};

subtest 'module from trace when not explicitly set' => sub {
    # When module is not provided but no_module is also not set,
    # init requires module or no_module. The module is normally set
    # by option_group. Here we set it through the init flow.
    my $opt = Getopt::Yath::Option->create(
        type   => 'Bool',
        title  => 'mdt',
        group  => 'g',
        module => 'Explicit::Module',
        trace  => ['Some::Caller', 'file.pl', 1],
    );
    is($opt->module, 'Explicit::Module', 'explicit module takes precedence');

    # When no module is provided, no_module must be set
    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'mdt2',
        group     => 'g',
        no_module => 1,
        trace     => ['Some::Caller', 'file.pl', 1],
    );
    ok($opt2->no_module, 'no_module flag is set');
};

subtest 'check_value undef passes' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'cvu',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => ['a'],
    );
    my @bad = $opt->check_value(undef);
    is(\@bad, [], 'check_value with undef input returns empty');
};

done_testing;
