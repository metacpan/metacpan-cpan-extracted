use Test2::V0;

subtest 'stop_at_non_opts' => sub {
    package StopNonOpt;
    use Getopt::Yath;

    option_group {category => 'Stop', group => 'stop', no_module => 1} => sub {
        option verbose => (
            type        => 'Bool',
            short       => 'v',
            description => 'Be verbose',
        );
    };

    package main;

    my $res = StopNonOpt::parse_options(['-v', 'somefile.txt', '--verbose'], stop_at_non_opts => 1);
    is($res->settings->{stop}->{verbose}, 1, 'options before stop parsed');
    is($res->stop, 'somefile.txt', 'stopped at non-option');
    is($res->remains, ['--verbose'], 'remaining args preserved');
};

subtest 'stop_at_invalid_opts' => sub {
    package StopInvalid;
    use Getopt::Yath;

    option_group {category => 'Stop2', group => 'stop2', no_module => 1} => sub {
        option debug => (
            type        => 'Bool',
            description => 'Debug mode',
        );
    };

    package main;

    my $res = StopInvalid::parse_options(['--debug', '--unknown-flag', '--debug'], stop_at_invalid_opts => 1);
    is($res->settings->{stop2}->{debug}, 1, 'valid option parsed before stop');
    is($res->stop, '--unknown-flag', 'stopped at invalid option');
    is($res->remains, ['--debug'], 'remaining args preserved');
};

subtest 'skip_non_opts' => sub {
    package SkipNonOpt;
    use Getopt::Yath;

    option_group {category => 'Skip', group => 'skip', no_module => 1} => sub {
        option active => (
            type        => 'Bool',
            description => 'Active',
        );
    };

    package main;

    my $res = SkipNonOpt::parse_options(['file1.txt', '--active', 'file2.txt'], skip_non_opts => 1);
    is($res->settings->{skip}->{active}, 1, 'option parsed');
    is($res->skipped, ['file1.txt', 'file2.txt'], 'non-opts collected in skipped');
};

subtest 'groups :{ }:' => sub {
    package GroupParse;
    use Getopt::Yath;

    option_group {category => 'Groups', group => 'grp', no_module => 1} => sub {
        option items => (
            type        => 'List',
            description => 'Item list',
        );
    };

    package main;

    my $res = GroupParse::parse_options(
        ['--items', ':{', 'a', 'b', 'c', '}:'],
        groups => {':{' => '}:'},
    );
    is($res->settings->{grp}->{items}, [qw/a b c/], 'group tokens collect into arrayref');
};

subtest 'groups unmatched end token' => sub {
    package GroupUnmatched;
    use Getopt::Yath;

    option_group {category => 'GU', group => 'gu', no_module => 1} => sub {
        option x => (type => 'List', description => 'x');
    };

    package main;

    like(
        dies { GroupUnmatched::parse_options(['--x', ':{', 'a', 'b'], groups => {':{' => '}:'}) },
        qr/Could not find end token/,
        'dies when group end token is missing',
    );
};

subtest 'standalone groups go to skipped' => sub {
    package StandaloneGroup;
    use Getopt::Yath;

    option_group {category => 'SG', group => 'sg', no_module => 1} => sub {
        option flag => (type => 'Bool', description => 'flag');
    };

    package main;

    my $res = StandaloneGroup::parse_options(
        [':{', 'hello', 'world', '}:', '--flag'],
        groups       => {':{' => '}:'},
        skip_non_opts => 1,
    );
    is($res->settings->{sg}->{flag}, 1, 'flag parsed');
    # Standalone group contents are collected as an arrayref in skipped
    is($res->skipped, [['hello', 'world']], 'standalone group contents go to skipped as arrayref');
};

subtest 'arg=val empty value' => sub {
    package ArgValTest;
    use Getopt::Yath;

    option_group {category => 'AV', group => 'av', no_module => 1} => sub {
        option thing => (type => 'Scalar', description => 'A thing');
    };

    package main;

    # --thing= with empty string is valid and sets to empty string
    my $res = ArgValTest::parse_options(['--thing=']);
    is($res->settings->{av}->{thing}, '', '--opt= sets empty string value');
};

subtest 'prefix on option_group' => sub {
    package PrefixTest;
    use Getopt::Yath;

    option_group {category => 'Prefixed', group => 'pfx', prefix => 'runner', no_module => 1} => sub {
        option timeout => (
            type        => 'Scalar',
            description => 'Timeout value',
        );
    };

    package main;

    my $res = PrefixTest::parse_options(['--runner-timeout', '30']);
    is($res->settings->{pfx}->{timeout}, '30', 'prefix + option name works');

    like(
        dies { PrefixTest::parse_options(['--timeout', '30']) },
        qr/is not a valid option/,
        'unprefixed form is not valid',
    );
};

subtest 'include_options' => sub {
    BEGIN { $INC{'IncludeSource.pm'} = __FILE__ }
    package IncludeSource;
    use Getopt::Yath;
    option_group {category => 'Source', group => 'src', no_module => 1} => sub {
        option alpha => (type => 'Bool', description => 'Alpha');
        option beta  => (type => 'Scalar', description => 'Beta');
    };

    BEGIN { $INC{'IncludeTarget.pm'} = __FILE__ }
    package IncludeTarget;
    use Getopt::Yath;
    include_options('IncludeSource');

    package main;

    my $res = IncludeTarget::parse_options(['--alpha', '--beta', 'hello']);
    is($res->settings->{src}->{alpha}, 1, 'included Bool option works');
    is($res->settings->{src}->{beta}, 'hello', 'included Scalar option works');
};

subtest 'include_options with filter list' => sub {
    BEGIN { $INC{'FilterSource.pm'} = __FILE__ }
    package FilterSource;
    use Getopt::Yath;
    option_group {category => 'FS', group => 'fs', no_module => 1} => sub {
        option one   => (type => 'Bool', description => 'One');
        option two   => (type => 'Bool', description => 'Two');
        option three => (type => 'Bool', description => 'Three');
    };

    BEGIN { $INC{'FilterTarget.pm'} = __FILE__ }
    package FilterTarget;
    use Getopt::Yath;
    include_options('FilterSource', ['one', 'three']);

    package main;

    my $res = FilterTarget::parse_options(['--one', '--three']);
    is($res->settings->{fs}->{one},   1, 'filtered option "one" included');
    is($res->settings->{fs}->{three}, 1, 'filtered option "three" included');

    like(
        dies { FilterTarget::parse_options(['--two']) },
        qr/is not a valid option/,
        'filtered-out option "two" not available',
    );
};

subtest 'option_group nesting' => sub {
    package NestTest;
    use Getopt::Yath;

    option_group {category => 'Outer', group => 'nest'} => sub {
        option_group {no_module => 1} => sub {
            option inner_opt => (
                type        => 'Bool',
                description => 'Inner option',
            );
        };
    };

    package main;

    my $res = NestTest::parse_options(['--inner-opt']);
    is($res->settings->{nest}->{inner_opt}, 1, 'nested option_group inherits outer group');
};

subtest 'invalid_opt_callback' => sub {
    package InvalidCB;
    use Getopt::Yath;

    option_group {category => 'ICB', group => 'icb', no_module => 1} => sub {
        option ok_opt => (type => 'Bool', description => 'OK');
    };

    package main;

    my @captured;
    like(
        dies {
            InvalidCB::parse_options(
                ['--ok-opt', '--bad-opt'],
                invalid_opt_callback => sub { push @captured, $_[0]; die "custom: $_[0]\n" },
            )
        },
        qr/custom: --bad-opt/,
        'invalid_opt_callback invoked with the bad option',
    );
    is(\@captured, ['--bad-opt'], 'callback received the invalid option');
};

subtest 'multiple stops' => sub {
    package MultiStop;
    use Getopt::Yath;

    option_group {category => 'MS', group => 'ms', no_module => 1} => sub {
        option mflag => (type => 'Bool', description => 'Flag');
    };

    package main;

    my $res = MultiStop::parse_options(
        ['--mflag', '::', 'remaining'],
        stops => ['--', '::'],
    );
    is($res->stop, '::', 'stopped at ::');
    is($res->remains, ['remaining'], 'remaining captured');
    is($res->settings->{ms}->{mflag}, 1, 'flag before stop parsed');
};

subtest 'skip_posts' => sub {
    package SkipPosts;
    use Getopt::Yath;

    my $post_ran = 0;
    option_group {category => 'SP', group => 'sp', no_module => 1} => sub {
        option sp_flag => (type => 'Bool', description => 'Flag');
    };
    option_post_process(sub { $post_ran++ });

    package main;

    $post_ran = 0;
    SkipPosts::parse_options([], skip_posts => 1);
    is($post_ran, 0, 'post-processor skipped with skip_posts');

    SkipPosts::parse_options([]);
    ok($post_ran, 'post-processor runs without skip_posts');
};

subtest 'nested groups' => sub {
    package NestedGroupParse;
    use Getopt::Yath;

    option_group {category => 'NG', group => 'ng', no_module => 1} => sub {
        option nlist => (type => 'List', description => 'Nested list');
    };

    package main;

    my $res = NestedGroupParse::parse_options(
        ['--nlist', ':{', 'a', ':{', 'inner1', 'inner2', '}:', 'b', '}:'],
        groups => {':{' => '}:'},
    );
    is(
        $res->settings->{ng}->{nlist},
        ['a', ['inner1', 'inner2'], 'b'],
        'nested groups produce nested arrayrefs',
    );
};

subtest 'applicable post-processor' => sub {
    package ApplicablePost;
    use Getopt::Yath;

    my $ran_yes = 0;
    my $ran_no  = 0;
    option_group {category => 'AP', group => 'ap', no_module => 1} => sub {
        option ap_flag => (type => 'Bool', description => 'Flag');
    };
    option_post_process(0, sub { 0 }, sub { $ran_no++ });
    option_post_process(0, sub { 1 }, sub { $ran_yes++ });

    package main;

    $ran_yes = 0;
    $ran_no  = 0;
    ApplicablePost::parse_options([]);
    is($ran_yes, 1, 'applicable post-processor ran');
    is($ran_no,  0, 'inapplicable post-processor skipped');
};

subtest 'process_args requires arrayref' => sub {
    package ReqArrayRef;
    use Getopt::Yath;

    option_group {category => 'RA', group => 'ra', no_module => 1} => sub {
        option ra_flag => (type => 'Bool', description => 'Flag');
    };

    package main;

    like(
        dies { ReqArrayRef::parse_options('not an arrayref') },
        qr/Must provide an argv arrayref/,
        'parse_options dies without arrayref',
    );
};

subtest 'requires_arg with no remaining args' => sub {
    package ReqArgEmpty;
    use Getopt::Yath;

    option_group {category => 'RAE', group => 'rae', no_module => 1} => sub {
        option need_val => (type => 'Scalar', description => 'Needs a value');
    };

    package main;

    like(
        dies { ReqArgEmpty::parse_options(['--need-val']) },
        qr/No argument provided to '--need-val'/,
        'dies when requires_arg but no args remain',
    );
};

subtest 'set=val not allowed on Bool' => sub {
    package SetValBool;
    use Getopt::Yath;

    option_group {category => 'SVB', group => 'svb', no_module => 1} => sub {
        option svb_flag => (type => 'Bool', description => 'Bool flag');
    };

    package main;

    like(
        dies { SetValBool::parse_options(['--svb-flag=1']) },
        qr/Arguments are not allowed for this option type/,
        'Bool rejects --flag=val form',
    );
};

subtest 'option with trigger on clear' => sub {
    package TriggerClear;
    use Getopt::Yath;

    my @trigger_actions;
    option_group {category => 'TC', group => 'tc', no_module => 1} => sub {
        option tc_val => (
            type        => 'Scalar',
            default     => 'x',
            description => 'Triggerable',
            trigger     => sub { my %p = @_[1..$#_]; push @trigger_actions, $p{action} },
        );
    };

    package main;

    @trigger_actions = ();
    TriggerClear::parse_options(['--tc-val', 'hello']);
    ok((grep { $_ eq 'set' } @trigger_actions), 'trigger fires with set action');

    @trigger_actions = ();
    TriggerClear::parse_options(['--no-tc-val']);
    ok((grep { $_ eq 'clear' } @trigger_actions), 'trigger fires with clear action');
};

subtest '--no-opt then --opt=val' => sub {
    package ClearThenSet;
    use Getopt::Yath;

    option_group {category => 'CTS', group => 'cts', no_module => 1} => sub {
        option cts_val => (type => 'Scalar', default => 'orig', description => 'Clear then set');
    };

    package main;

    my $res = ClearThenSet::parse_options(['--no-cts-val', '--cts-val=new']);
    is($res->settings->{cts}->{cts_val}, 'new', 'clear then set gives new value');
    ok(!$res->cleared->{cts}->{cts_val}, 'cleared state removed after re-set');
};

subtest 'cleared option skips default' => sub {
    package ClearNoDefault;
    use Getopt::Yath;

    option_group {category => 'CND', group => 'cnd', no_module => 1} => sub {
        option cnd_val => (type => 'Scalar', default => 'should_not_appear', description => 'Clear no default');
    };

    package main;

    my $res = ClearNoDefault::parse_options(['--no-cnd-val']);
    is($res->settings->{cnd}->{cnd_val}, undef, 'cleared option does not get default');
};

subtest 'skip_invalid_opts collects skipped' => sub {
    package SkipInvOpt;
    use Getopt::Yath;

    option_group {category => 'SIO', group => 'sio', no_module => 1} => sub {
        option sio_flag => (type => 'Bool', description => 'Flag');
    };

    package main;

    my $res = SkipInvOpt::parse_options(
        ['--sio-flag', '--invalid-one', '--invalid-two'],
        skip_invalid_opts => 1,
    );
    is($res->settings->{sio}->{sio_flag}, 1, 'valid option parsed');
    is($res->skipped, ['--invalid-one', '--invalid-two'], 'invalid opts collected in skipped');
};

subtest 'docs with group filter' => sub {
    package DocsGroupFilter;
    use Getopt::Yath;

    option_group {category => 'Cat A', group => 'grp_a', no_module => 1} => sub {
        option dg_a => (type => 'Bool', description => 'Option A');
    };
    option_group {category => 'Cat B', group => 'grp_b', no_module => 1} => sub {
        option dg_b => (type => 'Bool', description => 'Option B');
    };

    package main;

    my $docs = DocsGroupFilter::options->docs('cli', group => 'grp_a');
    like($docs, qr/dg-a/, 'filtered docs contain group_a option');
    unlike($docs, qr/dg-b/, 'filtered docs exclude group_b option');
};

subtest 'docs invalid format' => sub {
    package DocsInvFmt;
    use Getopt::Yath;

    option_group {category => 'DIF', group => 'dif', no_module => 1} => sub {
        option dif_flag => (type => 'Bool', description => 'Flag');
    };

    package main;

    like(
        dies { DocsInvFmt::options->docs('invalid_format') },
        qr/Invalid documentation format 'invalid_format'/,
        'docs dies with invalid format',
    );
};

subtest 'option_group error propagation' => sub {
    package GroupError;
    use Getopt::Yath;

    package main;

    like(
        dies {
            GroupError::option_group({group => 'gerr', no_module => 1} => sub {
                die "intentional error\n";
            })
        },
        qr/intentional error/,
        'option_group propagates exceptions from sub',
    );
};

subtest 'category_sort_map affects doc ordering' => sub {
    package SortMapTest;
    use Getopt::Yath;

    # set_category_sort_map is a HashBase setter, takes a single hashref value
    category_sort_map({'Zzzz' => 1, 'Aaaa' => 2});

    option_group {category => 'Aaaa', group => 'sma', no_module => 1} => sub {
        option sma_opt => (type => 'Bool', description => 'A opt');
    };
    option_group {category => 'Zzzz', group => 'smz', no_module => 1} => sub {
        option smz_opt => (type => 'Bool', description => 'Z opt');
    };

    package main;

    my $docs = SortMapTest::options->docs('cli');
    my $pos_z = index($docs, 'Zzzz');
    my $pos_a = index($docs, 'Aaaa');
    ok($pos_z < $pos_a, 'category_sort_map puts Zzzz (weight 1) before Aaaa (weight 2)');
};

done_testing;
