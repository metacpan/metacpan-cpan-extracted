use Test2::V0;

# ============================================================================
# Acceptance tests: end-to-end parsing of realistic command lines
# ============================================================================

# --- Shared option definitions used across multiple tests ---

BEGIN { $INC{'AcceptLib.pm'} = __FILE__ }
package AcceptLib;
use Getopt::Yath;

option_group {category => 'Display', group => 'display', no_module => 1} => sub {
    option verbose => (
        type        => 'Count',
        short       => 'v',
        initialize  => 0,
        description => 'Increase verbosity',
    );

    option color => (
        type        => 'Bool',
        default     => 1,
        alt_no      => ['no-colour'],
        description => 'Enable colored output',
    );

    option formatter => (
        type        => 'Auto',
        short       => 'F',
        autofill    => 'Default',
        default     => undef,
        description => 'Output formatter',
    );
};

option_group {category => 'Runner', group => 'runner', no_module => 1} => sub {
    option jobs => (
        type           => 'Scalar',
        short          => 'j',
        default        => 1,
        allowed_values => qr/^\d+$/,
        description    => 'Number of parallel jobs',
    );

    option includes => (
        type        => 'List',
        short       => 'I',
        split_on    => ',',
        description => 'Include paths',
    );

    option env_vars => (
        type        => 'Map',
        short       => 'E',
        description => 'Environment variables to set',
    );

    option timeout => (
        type        => 'Scalar',
        default     => 60,
        description => 'Test timeout in seconds',
        normalize   => sub { $_[0] + 0 },
    );

    option retry => (
        type        => 'Bool',
        default     => 0,
        description => 'Retry failed tests',
    );

    option tags => (
        type        => 'List',
        description => 'Tags to filter by',
    );
};

BEGIN { $INC{'AcceptPluginLib.pm'} = __FILE__ }
package AcceptPluginLib;
use Getopt::Yath;

option_group {category => 'Plugin', group => 'plugin', no_module => 1} => sub {
    option plugin_opt => (
        type        => 'Scalar',
        default     => 'none',
        description => 'Plugin option',
    );
};

package main;

# ============================================================================
# Test: Typical CI pipeline command line
# yath test -j4 -vv --no-color --retry --timeout 120 --include lib,blib/lib t/
# ============================================================================

subtest 'CI pipeline: parallel, verbose, no-color, retry, custom timeout' => sub {
    my $res = AcceptLib::parse_options(
        ['-j4', '-vv', '--no-color', '--retry', '--timeout', '120', '--includes', 'lib,blib/lib', 't/'],
        skip_non_opts => 1,
        stops         => ['--'],
    );

    is($res->settings->{runner}->{jobs},     4,                  'jobs = 4');
    is($res->settings->{display}->{verbose}, 2,                  'verbosity = 2');
    is($res->settings->{display}->{color},   0,                  'color disabled');
    is($res->settings->{runner}->{retry},    1,                  'retry enabled');
    is($res->settings->{runner}->{timeout},  120,                'timeout = 120');
    is($res->settings->{runner}->{includes}, ['lib', 'blib/lib'], 'includes split on comma');
    is($res->skipped,                         ['t/'],             'test path skipped as non-opt');
};

# ============================================================================
# Test: Developer workflow with short flags combined
# yath test -vvvj8 -Ilib -Iblib/lib -E HOME=/tmp -E USER=test
# ============================================================================

subtest 'Developer workflow: combined short flags and repeated options' => sub {
    my $res = AcceptLib::parse_options(
        ['-vvvj', '8', '-I', 'lib', '-I', 'blib/lib', '-E', 'HOME=/tmp', '-E', 'USER=test'],
    );

    is($res->settings->{display}->{verbose}, 3,                  'three v flags counted');
    is($res->settings->{runner}->{jobs},     '8',                'jobs from short after count expansion');
    is($res->settings->{runner}->{includes}, ['lib', 'blib/lib'], 'two -I flags collected');
    is(
        $res->settings->{runner}->{env_vars},
        {HOME => '/tmp', USER => 'test'},
        'repeated -E flags build map',
    );
};

# ============================================================================
# Test: Mixed long and short forms with = and space separators
# ============================================================================

subtest 'Mixed long/short with = and space separators' => sub {
    my $res = AcceptLib::parse_options(
        ['--jobs=2', '-v', '--timeout=30', '--includes=src', '-Ivendor', '--retry'],
    );

    is($res->settings->{runner}->{jobs},     '2',             'long= form');
    is($res->settings->{display}->{verbose}, 1,               'short flag');
    is($res->settings->{runner}->{timeout},  30,              'long= with normalize');
    is($res->settings->{runner}->{includes}, ['src', 'vendor'], 'mixed long= and short');
    is($res->settings->{runner}->{retry},    1,               'long bool');
};

# ============================================================================
# Test: Clearing and re-setting options
# Simulates: user sets defaults in config, then overrides on command line
# ============================================================================

subtest 'Clear and re-set: override defaults and config' => sub {
    my $res = AcceptLib::parse_options(
        [
            '--includes', 'from_config',    # initial set
            '--no-includes',                # clear all
            '--includes', 'actual_path',    # re-set
            '--no-retry',                   # explicitly disable
            '--color',                      # re-enable after default
        ],
    );

    is(
        $res->settings->{runner}->{includes},
        ['actual_path'],
        'list cleared then re-populated',
    );
    is($res->settings->{runner}->{retry},  0, 'retry explicitly disabled');
    is($res->settings->{display}->{color}, 1, 'color explicitly enabled');
};

# ============================================================================
# Test: Stop processing at -- and pass remaining to test runner
# ============================================================================

subtest 'Double-dash stop: pass remaining args through' => sub {
    my $res = AcceptLib::parse_options(
        ['-v', '--jobs', '2', '--', '--some-test-flag', 'testfile.t', '--another'],
        stops => ['--'],
    );

    is($res->settings->{display}->{verbose}, 1,     'option before -- parsed');
    is($res->settings->{runner}->{jobs},     '2',   'option with arg before -- parsed');
    is($res->stop,                            '--',  'stopped at --');
    is(
        $res->remains,
        ['--some-test-flag', 'testfile.t', '--another'],
        'everything after -- preserved verbatim',
    );
};

# ============================================================================
# Test: Environment variable integration
# ============================================================================

subtest 'Environment variable integration: from_env, clear_env, set_env' => sub {
    package EnvAcceptLib;
    use Getopt::Yath;

    option_group {category => 'Env', group => 'env', no_module => 1} => sub {
        option log_level => (
            type          => 'Scalar',
            from_env_vars => ['ACCEPT_LOG_LEVEL'],
            set_env_vars  => ['ACCEPT_LOG_LEVEL'],
            default       => 'warn',
            description   => 'Log level',
        );

        option token => (
            type           => 'Scalar',
            from_env_vars  => ['ACCEPT_TOKEN'],
            clear_env_vars => ['ACCEPT_TOKEN'],
            description    => 'Auth token (cleared from env after reading)',
        );

        option quiet => (
            type          => 'Bool',
            from_env_vars => ['!ACCEPT_VERBOSE'],
            set_env_vars  => ['!ACCEPT_VERBOSE'],
            description   => 'Quiet mode (inverse of VERBOSE)',
        );
    };

    package main;

    # Scenario: env vars set before parsing
    local $ENV{ACCEPT_LOG_LEVEL} = 'debug';
    local $ENV{ACCEPT_TOKEN}     = 'secret123';
    local $ENV{ACCEPT_VERBOSE}   = '1';

    my $res = EnvAcceptLib::parse_options([], no_set_env => 1);

    is($res->settings->{env}->{log_level}, 'debug',  'log_level from env');
    is($res->settings->{env}->{token},     'secret123', 'token from env');
    is($res->settings->{env}->{quiet},     0,           'quiet=0 because VERBOSE=1');
    is($res->env->{ACCEPT_TOKEN},          undef,       'token env cleared');
    is($res->env->{ACCEPT_LOG_LEVEL},      'debug',     'log_level env would be set');
    is($res->env->{ACCEPT_VERBOSE},        1,           '!VERBOSE negated: quiet=0 -> VERBOSE=1');

    # Scenario: command line overrides env
    local $ENV{ACCEPT_LOG_LEVEL} = 'debug';
    local $ENV{ACCEPT_TOKEN}     = 'old_token';
    local $ENV{ACCEPT_VERBOSE}   = '1';

    $res = EnvAcceptLib::parse_options(
        ['--log-level', 'error', '--token', 'new_token', '--quiet'],
        no_set_env => 1,
    );

    is($res->settings->{env}->{log_level}, 'error',     'command line overrides env');
    is($res->settings->{env}->{token},     'new_token', 'command line overrides env token');
    is($res->settings->{env}->{quiet},     1,           'quiet explicitly set');
    is($res->env->{ACCEPT_VERBOSE},        0,           '!VERBOSE negated: quiet=1 -> VERBOSE=0');
};

# ============================================================================
# Test: Argument groups for passing structured data
# ============================================================================

subtest 'Argument groups: structured args with :{ }:' => sub {
    my $res = AcceptLib::parse_options(
        [
            '--tags', ':{', 'smoke', 'regression', 'integration', '}:',
            '--jobs', '4',
            '--tags', 'unit',
        ],
        groups => {':{' => '}:'},
    );

    is(
        $res->settings->{runner}->{tags},
        ['smoke', 'regression', 'integration', 'unit'],
        'group args expanded into list, then additional value appended',
    );
    is($res->settings->{runner}->{jobs}, '4', 'non-group option still works');
};

# ============================================================================
# Test: JSON values inline
# ============================================================================

subtest 'JSON values: inline JSON arrays and objects' => sub {
    my $res = AcceptLib::parse_options([
        '--includes', '["src/lib","vendor/lib"]',
        '--env-vars', '{"PERL5LIB":"/opt/lib","HOME":"/tmp"}',
    ]);

    is(
        $res->settings->{runner}->{includes},
        ['src/lib', 'vendor/lib'],
        'JSON array parsed into list',
    );
    is(
        $res->settings->{runner}->{env_vars},
        {PERL5LIB => '/opt/lib', HOME => '/tmp'},
        'JSON object parsed into map',
    );
};

# ============================================================================
# Test: Defaults, autofill, and unset options
# ============================================================================

subtest 'Defaults and autofill: no args produces correct defaults' => sub {
    my $res = AcceptLib::parse_options([]);

    is($res->settings->{display}->{verbose},   0,     'count defaults to 0');
    is($res->settings->{display}->{color},     1,     'bool default true');
    is($res->settings->{display}->{formatter}, undef, 'auto with no default stays undef');
    is($res->settings->{runner}->{jobs},       1,     'scalar default');
    is($res->settings->{runner}->{includes},   [],    'list defaults to empty');
    is($res->settings->{runner}->{env_vars},   undef, 'map with no default stays undef');
    is($res->settings->{runner}->{timeout},    60,    'scalar default with normalize');
    is($res->settings->{runner}->{retry},      0,     'bool default false');
};

subtest 'Autofill: auto option without value uses autofill' => sub {
    my $res = AcceptLib::parse_options(['-F']);
    is($res->settings->{display}->{formatter}, 'Default', 'autofill used for -F without arg');

    $res = AcceptLib::parse_options(['-F=Custom']);
    is($res->settings->{display}->{formatter}, 'Custom', '-F=Custom uses explicit value');
};

# ============================================================================
# Test: alt_no forms (--no-colour as alias for --no-color)
# ============================================================================

subtest 'alt_no: --no-colour as alias for disabling color' => sub {
    my $res = AcceptLib::parse_options(['--no-colour']);
    is($res->settings->{display}->{color}, 0, '--no-colour disables color via alt_no');
};

# ============================================================================
# Test: Allowed values validation
# ============================================================================

subtest 'Allowed values: jobs must be numeric' => sub {
    like(
        dies { AcceptLib::parse_options(['--jobs', 'lots']) },
        qr/Invalid value.*'lots'/,
        'non-numeric jobs value rejected',
    );

    ok(
        lives { AcceptLib::parse_options(['--jobs', '16']) },
        'numeric jobs value accepted',
    );
};

# ============================================================================
# Test: Skip and stop behaviors combined
# ============================================================================

subtest 'Skip non-opts with stop: file args mixed with options' => sub {
    my $res = AcceptLib::parse_options(
        ['-v', 'test1.t', '--jobs', '4', 'test2.t', '--', 'extra'],
        skip_non_opts => 1,
        stops         => ['--'],
    );

    is($res->settings->{display}->{verbose}, 1,                   'option parsed');
    is($res->settings->{runner}->{jobs},     '4',                 'option with arg parsed');
    is($res->skipped,                         ['test1.t', 'test2.t'], 'non-opts skipped');
    is($res->stop,                            '--',                'stopped at --');
    is($res->remains,                         ['extra'],           'args after stop preserved');
};

# ============================================================================
# Test: include_options from another library
# ============================================================================

subtest 'Include options from external library' => sub {
    package AcceptWithPlugin;
    use Getopt::Yath;
    include_options('AcceptLib');
    include_options('AcceptPluginLib');

    package main;

    my $res = AcceptWithPlugin::parse_options(['-v', '--plugin-opt', 'custom', '--jobs', '8']);

    is($res->settings->{display}->{verbose},   1,        'included display option works');
    is($res->settings->{runner}->{jobs},       '8',      'included runner option works');
    is($res->settings->{plugin}->{plugin_opt}, 'custom', 'included plugin option works');
};

# ============================================================================
# Test: Multiple option groups with different prefixes
# ============================================================================

subtest 'Prefixed options: runner and display prefixes' => sub {
    package PrefixAcceptLib;
    use Getopt::Yath;

    option_group {category => 'Runner', group => 'runner', prefix => 'runner', no_module => 1} => sub {
        option timeout => (type => 'Scalar', default => 30, description => 'Runner timeout');
        option verbose => (type => 'Bool', description => 'Runner verbose');
    };

    option_group {category => 'Formatter', group => 'fmt', prefix => 'fmt', no_module => 1} => sub {
        option timeout => (type => 'Scalar', default => 10, description => 'Formatter timeout');
        option verbose => (type => 'Bool', description => 'Formatter verbose');
    };

    package main;

    my $res = PrefixAcceptLib::parse_options([
        '--runner-timeout', '60',
        '--fmt-verbose',
        '--runner-verbose',
        '--fmt-timeout', '5',
    ]);

    is($res->settings->{runner}->{timeout}, '60', 'runner-prefixed timeout');
    is($res->settings->{runner}->{verbose}, 1,    'runner-prefixed verbose');
    is($res->settings->{fmt}->{timeout},    '5',  'fmt-prefixed timeout');
    is($res->settings->{fmt}->{verbose},    1,    'fmt-prefixed verbose');
};

# ============================================================================
# Test: Complex Map usage with multiple forms
# ============================================================================

subtest 'Map: key=value, JSON, split_on, and clearing' => sub {
    my $res = AcceptLib::parse_options([
        '-E', 'PATH=/usr/bin',
        '-EHOME=/home/test',
        '--env-vars=SHELL=/bin/bash',
        '--no-env-vars',
        '-E', 'TERM=xterm',
    ]);

    is(
        $res->settings->{runner}->{env_vars},
        {TERM => 'xterm'},
        'map: set, set, set, clear all, then re-set produces only last value',
    );
};

# ============================================================================
# Test: BoolMap pattern matching in realistic scenario
# ============================================================================

subtest 'BoolMap: feature flags toggled by pattern' => sub {
    package FeatureFlagLib;
    use Getopt::Yath;

    option_group {category => 'Features', group => 'features', no_module => 1} => sub {
        option flags => (
            type        => 'BoolMap',
            pattern     => qr/feature-(.+)/,
            description => 'Feature flags',
        );
    };

    package main;

    my $res = FeatureFlagLib::parse_options([
        '--feature-fork',
        '--feature-preload',
        '--no-feature-preload',
        '--feature-timeout',
    ]);

    is(
        $res->settings->{features}->{flags},
        {fork => 1, preload => 0, timeout => 1},
        'BoolMap: features toggled on and off by pattern',
    );
};

# ============================================================================
# Test: Post-processors mutating state
# ============================================================================

subtest 'Post-processors: validate and transform after parsing' => sub {
    package PostProcLib;
    use Getopt::Yath;

    option_group {category => 'PP', group => 'pp', no_module => 1} => sub {
        option pp_jobs => (type => 'Scalar', default => 1, description => 'Jobs');
        option pp_mode => (type => 'Scalar', default => 'auto', description => 'Mode');
    };

    option_post_process -10 => sub {
        my ($instance, $state) = @_;
        my $jobs = $state->settings->pp->pp_jobs;
        # If mode is 'auto' and jobs > 1, switch to 'parallel'
        if ($state->settings->pp->pp_mode eq 'auto' && $jobs > 1) {
            $state->settings->pp->pp_mode = 'parallel';
        }
    };

    option_post_process 10 => sub {
        my ($instance, $state) = @_;
        # Verify mode was set by the earlier post-processor
        $state->settings->pp->create_option('mode_verified', 1)
            if $state->settings->pp->pp_mode eq 'parallel';
    };

    package main;

    my $res = PostProcLib::parse_options(['--pp-jobs', '4']);

    is($res->settings->{pp}->{pp_mode},       'parallel', 'post-processor changed mode');
    is($res->settings->{pp}->{mode_verified}, 1,          'second post-processor saw the change');
};

# ============================================================================
# Test: Applicable options: some options hidden based on state
# ============================================================================

subtest 'Applicable: options conditionally available' => sub {
    package ApplicableLib;
    use Getopt::Yath;

    option_group {category => 'Applicable', group => 'app', no_module => 1} => sub {
        option mode => (
            type        => 'Scalar',
            default     => 'simple',
            description => 'Run mode',
        );

        option workers => (
            type        => 'Scalar',
            default     => 4,
            applicable  => sub { my ($self, $opts, $settings) = @_; $settings && $settings->check_group('app') && $settings->app->check_option('mode') && $settings->app->mode eq 'parallel' },
            description => 'Number of workers (only in parallel mode)',
        );
    };

    package main;

    # In simple mode, --workers should not be recognized
    my $res = ApplicableLib::parse_options(['--mode', 'simple'], skip_invalid_opts => 1);
    is($res->settings->{app}->{mode}, 'simple', 'mode set');
    ok(!exists $res->settings->{app}->{workers}, 'workers not populated in simple mode');

    # Rebuild with parallel mode pre-set
    my $settings = Getopt::Yath::Settings->new({app => {mode => 'parallel'}});
    $res = ApplicableLib::parse_options(['--workers', '8'], settings => $settings);
    is($res->settings->{app}->{workers}, '8', 'workers available in parallel mode');
};

# ============================================================================
# Test: Realistic yath-like command: yath test -j4 -vvv -Ilib -D --retry t/
# ============================================================================

subtest 'Realistic yath command line' => sub {
    package YathLike;
    use Getopt::Yath;

    option_group {category => 'Yath', group => 'yath', no_module => 1} => sub {
        option jobs => (type => 'Scalar', short => 'j', default => 1, description => 'Jobs');
        option verbose => (type => 'Count', short => 'v', initialize => 0, description => 'Verbose');
        option include => (type => 'List', short => 'I', description => 'Include paths');
        option dev_lib => (
            type     => 'AutoList',
            short    => 'D',
            autofill => sub { 'lib', 'blib/lib', 'blib/arch' },
            description => 'Dev libraries',
        );
        option retry => (type => 'Bool', default => 0, description => 'Retry failed');
        option color => (type => 'Bool', default => 1, description => 'Color output');
        option env_var => (type => 'Map', short => 'E', description => 'Env vars');
    };

    package main;

    my $res = YathLike::parse_options(
        ['-j4', '-vvv', '-Ilib', '-D', '--retry', '--no-color', '-E', 'HARNESS_ACTIVE=1', 't/', 'xt/'],
        skip_non_opts => 1,
        stops         => ['--'],
    );

    is($res->settings->{yath}->{jobs},    '4',                                'jobs=4');
    is($res->settings->{yath}->{verbose}, 3,                                  'verbose=3');
    is($res->settings->{yath}->{include}, ['lib'],                            'single include');
    is($res->settings->{yath}->{dev_lib}, ['lib', 'blib/lib', 'blib/arch'],   'autofill dev libs');
    is($res->settings->{yath}->{retry},   1,                                  'retry enabled');
    is($res->settings->{yath}->{color},   0,                                  'color disabled');
    is($res->settings->{yath}->{env_var}, {HARNESS_ACTIVE => '1'},            'env var set');
    is($res->skipped,                      ['t/', 'xt/'],                      'test dirs skipped');
};

# ============================================================================
# Test: Everything at once — the kitchen sink
# ============================================================================

subtest 'Kitchen sink: every feature in one command line' => sub {
    package KitchenSink;
    use Getopt::Yath;

    my @trigger_log;
    option_group {category => 'All', group => 'all', no_module => 1} => sub {
        option bool_opt => (type => 'Bool', short => 'b', default => 0, description => 'A bool');
        option count_opt => (type => 'Count', short => 'c', initialize => 0, description => 'A count');
        option scalar_opt => (
            type        => 'Scalar',
            short       => 's',
            default     => 'def',
            normalize   => sub { lc $_[0] },
            trigger     => sub { push @trigger_log, $_[2] },
            description => 'A scalar',
        );
        option list_opt => (type => 'List', short => 'l', split_on => ',', description => 'A list');
        option map_opt => (type => 'Map', short => 'm', description => 'A map');
        option auto_opt => (type => 'Auto', short => 'a', autofill => 'yes', default => 'no', description => 'An auto');
    };

    option_post_process(sub {
        my ($inst, $state) = @_;
        my $g = $state->settings->all;
        if ($g->count_opt > 2) {
            $g->create_option('was_very_verbose', 1);
        }
    });

    package main;

    @trigger_log = ();
    my $res = KitchenSink::parse_options(
        [
            '-b',                       # bool on
            '-ccc',                     # count = 3
            '-s=UPPER',                 # scalar with normalize
            '--no-scalar-opt',          # clear scalar
            '-s', 'Final',              # set scalar again
            '-l', 'x,y',               # list with split
            '-l', 'z',                  # append to list
            '-m', 'k=v',               # map entry
            '--map-opt', '{"a":"b"}',   # map JSON
            '-a',                       # auto with autofill
            'positional',               # non-opt
            '--', 'rest',               # stop
        ],
        skip_non_opts => 1,
        stops         => ['--'],
    );

    is($res->settings->{all}->{bool_opt},  1,                    'bool on');
    is($res->settings->{all}->{count_opt}, 3,                    'count = 3');
    is($res->settings->{all}->{scalar_opt}, 'final',             'scalar normalized, last wins');
    is($res->settings->{all}->{list_opt},  [qw/x y z/],         'list split and appended');
    is($res->settings->{all}->{map_opt},   {k => 'v', a => 'b'}, 'map from key=val and JSON merged');
    is($res->settings->{all}->{auto_opt},  'yes',                'auto used autofill');
    is($res->settings->{all}->{was_very_verbose}, 1,             'post-processor ran');
    is($res->skipped,  ['positional'],                           'positional skipped');
    is($res->stop,     '--',                                     'stopped at --');
    is($res->remains,  ['rest'],                                 'remaining preserved');

    # Trigger should have fired for: initialize, clear, two sets
    ok(@trigger_log >= 2, 'trigger fired multiple times');
};

done_testing;
