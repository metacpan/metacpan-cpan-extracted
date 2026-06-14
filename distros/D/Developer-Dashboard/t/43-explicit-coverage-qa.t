#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::XS qw(decode_json);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Complete ();
use Developer::Dashboard::CLI::Files ();
use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::CLI::Progress ();
use Developer::Dashboard::CLI::Skills ();
use Developer::Dashboard::File ();
use Developer::Dashboard::FileRegistry ();
use Developer::Dashboard::SkillManager ();

{
    package TestCoveragePaths;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub logs_root       { return $_[0]{logs_root}; }
    sub config_root     { return $_[0]{config_root}; }
    sub config_roots    { return ( $_[0]{config_root} ); }
    sub dashboards_root { return $_[0]{dashboards_root}; }
    sub state_root      { return $_[0]{state_root}; }
    sub cwd             { return $_[0]{cwd}; }
    sub current_project_root { return $_[0]{cwd}; }
    sub runtime_roots   { return @{ $_[0]{runtime_roots} || [] }; }
    sub installed_skill_roots { return (); }
    sub secure_file_permissions { return 1; }
}

{
    package TestCLIFileRegistry;

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            paths      => $args{paths},
            named      => {},
            located    => [],
            all_files  => { builtin => '/tmp/builtin.txt' },
        }, $class;
    }

    sub paths { return $_[0]{paths}; }

    sub register_named_files {
        my ( $self, $aliases ) = @_;
        %{$self->{named}} = ( %{$self->{named}}, %{ $aliases || {} } );
        return $self;
    }

    sub unregister_named_file {
        my ( $self, $name ) = @_;
        delete $self->{named}{$name};
        return $self;
    }

    sub named_files {
        my ($self) = @_;
        return { %{ $self->{named} } };
    }

    sub all_files {
        my ($self) = @_;
        return {
            %{ $self->{all_files} },
            %{ $self->{named} },
        };
    }

    sub resolve_file {
        my ( $self, $name ) = @_;
        die "Unknown file name '$name'" if !exists $self->{named}{$name};
        return $self->{named}{$name};
    }

    sub locate_files_under {
        my ( $self, $root, @terms ) = @_;
        return map { File::Spec->catfile( $root, $_ ) } @terms;
    }
}

{
    package TestCLIConfig;

    sub new { return bless {}, shift }

    sub file_aliases {
        return {
            alias_file => '/tmp/alias-file.txt',
            root_dir   => '/tmp/root-dir',
        };
    }

    sub save_global_file_alias {
        my ( $self, $name, $path ) = @_;
        return { name => $name, path => $path };
    }

    sub remove_global_file_alias {
        my ( $self, $name ) = @_;
        return { removed => $name };
    }
}

{
    package TestCLIPathRegistry;

    sub new { return bless {}, shift }

    sub _expand_home {
        my ( $self, $path ) = @_;
        $path =~ s{\A~}{$ENV{HOME} || ''}e if defined $path;
        return $path;
    }
}

{
    package TestCLICollector;

    sub new { return bless {}, shift }

    sub list_collectors {
        return (
            { name => 'collector-two' },
            { name => 'collector-three' },
            { name => 'collector-one' },
        );
    }
}

{
    package TestCLICompleteConfig;

    sub new { return bless {}, shift }

    sub collectors {
        return [
            { name => 'collector-one' },
            { name => 'collector-two' },
            { name => 'collector-one' },
            'junk',
        ];
    }
}

{
    package TestCLISuggest;

    sub new { return bless {}, shift }

    sub top_level_candidates { return qw(skills restart logs); }
    sub skill_commands       { return qw(demo.run); }
}

{
    package TestFileConfig;

    sub new { return bless {}, shift }

    sub file_aliases {
        return { cfg => '/tmp/from-config.txt' };
    }
}

{
    package TestSkillsManager;

    our %USAGE = (
        json_ok => {
            name    => 'demo',
            enabled => 1,
            path    => '/tmp/demo',
            config  => { root => '/tmp/config', file => '/tmp/config/config.json' },
            docker  => { root => '/tmp/docker', services => [ { name => 'web', files => ['compose.yml'] } ] },
            cli     => [ { name => 'hello', has_hooks => 1, hook_count => 2, path => '/tmp/demo/cli/hello' } ],
            pages   => { entries => ['index'], nav_entries => ['nav/foo.tt'] },
            collectors => [ { name => 'beat', qualified_name => 'demo.beat', has_indicator => 1, interval => 30 } ],
        },
        json_err => {
            error => 'usage failed',
            name  => 'broken',
            enabled => 0,
            path => '/tmp/broken',
            config => { root => '/tmp/config', file => '/tmp/config/config.json' },
            docker => { root => '/tmp/docker', services => [] },
            cli => [],
            pages => { entries => [], nav_entries => [] },
            collectors => [],
        },
    );

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            progress   => $args{progress},
            paths      => $args{paths},
            skip_tests => $args{skip_tests},
        }, $class;
    }

    sub registered_skill_sources {
        return ('demo/source');
    }

    sub install_progress_tasks {
        return [
            { id => 'fetch_source',       label => 'Fetch skill source' },
            { id => 'prepare_layout',     label => 'Prepare skill layout' },
            { id => 'install_aptfile',    label => 'Install aptfile dependencies' },
            { id => 'install_apkfile',    label => 'Install apkfile dependencies' },
            { id => 'install_dnfile',     label => 'Install dnfile dependencies' },
            { id => 'install_wingetfile', label => 'Install wingetfile dependencies' },
            { id => 'install_brewfile',   label => 'Install brewfile dependencies' },
            { id => 'install_cpanfile',   label => 'Install cpanfile dependencies' },
        ];
    }

    sub install_progress_tasks_for_sources {
        my ( $class, @sources ) = @_;
        return [ map { { id => $_, label => $_ } } @sources ];
    }

    sub install {
        my ( $self, $source ) = @_;
        return { repo_name => 'demo', source => $source, status => 'installed' };
    }

    sub install_many {
        my ( $self, @sources ) = @_;
        return {
            success => 1,
            results => [
                map {
                    { repo_name => $_, source => $_, status => 'updated', version_before => '1.00', version_after => '1.01' }
                } @sources
            ],
        };
    }

    sub install_registered_skills {
        return {
            success => 1,
            operations => [
                { repo_name => 'demo', source => 'demo/source', status => 'updated', version_before => '1.00', version_after => '1.01' },
            ],
        };
    }

    sub install_from_ddfiles {
        return {
            success => 1,
            operations => [
                { repo_name => 'dd', source => 'dd/source', status => 'installed', version_before => undef, version_after => '1.00' },
            ],
        };
    }

    sub uninstall { return { success => 1, repo_name => $_[1] } }
    sub enable    { return { success => 1, repo_name => $_[1], enabled => 1 } }
    sub disable   { return { success => 1, repo_name => $_[1], enabled => 0 } }

    sub list {
        return [
            {
                name                  => 'demo',
                enabled               => 1,
                cli_commands_count    => 1,
                pages_count           => 2,
                docker_services_count => 1,
                collectors_count      => 1,
                indicators_count      => 1,
            },
        ];
    }

    sub usage {
        my ( $self, $name ) = @_;
        return $USAGE{$name} if exists $USAGE{$name};
        return $USAGE{json_ok};
    }

    sub get_skill_path {
        my ( $self, $name, %args ) = @_;
        return undef if !$name || $name eq 'missing';
        return '/tmp/demo';
    }

    sub is_enabled {
        my ( $self, $name ) = @_;
        return $name && $name ne 'disabled' ? 1 : 0;
    }
}

{
    package TestSkillsProgress;

    sub new {
        my ( $class, @args ) = @_;
        shift @args if @args % 2 == 1 && !ref( $args[0] );
        my %args
          = @args == 1 && ref( $args[0] ) eq 'HASH' ? %{ $args[0] }
          : @args % 2 == 0                         ? @args
          : ();
        return bless { %args, finished => 0, events => [] }, $class;
    }

    sub callback {
        my ($self) = @_;
        return sub {
            my ($event) = @_;
            push @{ $self->{events} }, $event;
        };
    }

    sub finish {
        my ($self) = @_;
        $self->{finished} = 1;
        return 1;
    }
}

{
    package TestSkillsDispatcher;

    our $RESULT = { success => 1 };

    sub new { return bless {}, shift }

    sub exec_command { return $RESULT }
}

subtest 'CLI::Progress renders and updates task boards' => sub {
    my $buffer = '';
    open my $stream, '>', \$buffer or die $!;

    my $progress = Developer::Dashboard::CLI::Progress->new(
        title   => 'demo progress',
        tasks   => [
            { id => 'first',  label => 'First task' },
            { id => 'second', label => 'Second task' },
        ],
        stream  => $stream,
        dynamic => 1,
        color   => 1,
    );

    like( $buffer, qr/demo progress/, 'initial render prints the title' );
    like( $buffer, qr/\[ \] First task/, 'initial render shows pending tasks' );
    like( $progress->render_text, qr/\e\[32m\[OK]\e\[0m|\[ \]/, 'render_text returns current board text' );
    is( $progress->_status_prefix('done'), '[OK]', 'done maps to the green OK marker' );
    is( $progress->_status_prefix('running'), '->', 'running maps to the arrow marker' );
    is( $progress->_status_prefix('failed'), '[X]', 'failed maps to the red X marker' );
    is( $progress->_status_prefix('pending'), '[ ]', 'other states stay pending' );
    is( $progress->_status_prefix(undef), '[ ]', 'undefined status stays pending' );
    is( $progress->_colorize( '[OK]', 'done' ), "\e[32m[OK]\e[0m", 'done colorizes green when enabled' );
    is( $progress->_colorize( '->', 'running' ), "\e[34m->\e[0m", 'running colorizes blue when enabled' );
    is( $progress->_colorize( '[X]', 'failed' ), "\e[31m[X]\e[0m", 'failed colorizes red when enabled' );
    is( $progress->_colorize( '[ ]', 'pending' ), '[ ]', 'pending text stays plain' );
    is( $progress->_colorize( 'plain', undef ), 'plain', 'undefined marker status stays plain' );
    is( $progress->_colorize_detail( 'detail', 'running' ), "\e[34mdetail\e[0m", 'running detail lines colorize blue when enabled' );
    is( $progress->_colorize_detail( 'detail', 'failed' ), "\e[31mdetail\e[0m", 'failed detail lines colorize red when enabled' );
    is( $progress->_colorize_detail( 'detail', 'pending' ), 'detail', 'pending detail lines stay plain' );
    is( $progress->_colorize_detail( 'detail', undef ), 'detail', 'undefined detail status stays plain' );

    my $callback = $progress->callback;
    ok( $callback, 'callback returns a coderef' );
    $callback->( { task_id => 'first', status => 'running' } );
    $progress->update( { task_id => 'first', status => 'done', label => 'Completed task' } );
    $progress->update( { task_id => 'second', status => 'failed' } );
    $progress->update(undef);
    $progress->update( { task_id => 'missing', status => 'done' } );
    $progress->finish;

    like( $buffer, qr/\e\[1A\e\[2K/s, 'dynamic re-render clears the previous board' );
    like( $buffer, qr/Completed task/, 'update can replace the task label' );
    like( $buffer, qr/\e\[31m\[X]\e\[0m Second task/, 'failed tasks render with the red marker' );
    like( $buffer, qr/\n\z/, 'finish ensures a trailing newline for dynamic boards' );

    my $plain = '';
    open my $plain_stream, '>', \$plain or die $!;
    my $plain_progress = Developer::Dashboard::CLI::Progress->new(
        tasks  => [ { id => 'only' } ],
        stream => $plain_stream,
    );
    $plain_progress->finish;
    like( $plain, qr/dashboard progress/, 'default title is used when none is supplied' );

    ok( $plain_progress->update('not-a-hash'), 'update ignores non-hash payloads' );
    ok( $plain_progress->update( {} ), 'update ignores payloads without a task id' );
    ok( $plain_progress->update( { task_id => 'missing', status => 'done' } ), 'update ignores unknown task ids' );
    ok( $plain_progress->update( { task_id => 'only', detail_lines => 'not-an-array', status => 'running' } ), 'update tolerates non-array detail_lines by clearing the detail window' );
    ok( $plain_progress->update( { task_id => 'only', label => '', status => '' } ), 'update ignores empty label and status replacements' );
    ok( $plain_progress->update( { task_id => 'only', status => undef } ), 'update ignores undefined statuses' );
    is( $plain_progress->{tasks}{only}{label}, 'only', 'empty labels do not replace the existing label' );
    is( $plain_progress->{tasks}{only}{status}, 'running', 'empty statuses do not replace the existing status' );
    is_deeply( $plain_progress->{tasks}{only}{detail_lines}, [], 'non-array detail_lines clear the detail window safely' );
    is( $plain_progress->_colorize( '->', 'running' ), '->', 'colorize leaves markers plain when color output is disabled' );
    is( $plain_progress->_colorize_detail( 'detail', 'running' ), 'detail', 'detail colorization stays plain when color output is disabled' );

    my $default_progress = Developer::Dashboard::CLI::Progress->new();
    like( $default_progress->render_text, qr/\Adashboard progress\n\z/, 'new can rely on the default task list and stream fallbacks' );

    my $implicit_label_progress = Developer::Dashboard::CLI::Progress->new(
        tasks  => [ { id => 'implicit' } ],
        stream => $plain_stream,
    );
    like( $implicit_label_progress->render_text, qr/\[ \] implicit/, 'task labels fall back to the task id when no label is supplied' );

    my $invalid_tasks_error = eval {
        Developer::Dashboard::CLI::Progress->new(
            tasks  => 'not-an-array',
            stream => $plain_stream,
        );
        1;
    } ? '' : $@;
    like( $invalid_tasks_error, qr/Progress tasks must be an array reference/, 'new rejects non-array task lists' );

    my $missing_id_error = eval {
        Developer::Dashboard::CLI::Progress->new(
            tasks  => [ { label => 'broken task' } ],
            stream => $plain_stream,
        );
        1;
    } ? '' : $@;
    like( $missing_id_error, qr/Progress task missing id/, 'new rejects task rows without ids' );

    my $sparse_progress = Developer::Dashboard::CLI::Progress->new(
        title  => 'sparse',
        tasks  => [
            { id => 'first',  label => 'First task' },
            { id => 'second', label => 'Second task' },
        ],
        stream => $plain_stream,
    );
    delete $sparse_progress->{tasks}{second};
    unlike( $sparse_progress->render_text, qr/Second task/, 'render_text skips ordered task ids that no longer exist in the lookup table' );
    $sparse_progress->{tasks}{first}{detail_lines} = 'not-an-array';
    $sparse_progress->{tasks}{first}{status} = 'running';
    unlike( $sparse_progress->render_text, qr/^\s{3}/m, 'render_text suppresses detail rendering when detail_lines is not an array reference' );

    my $fallback_progress = Developer::Dashboard::CLI::Progress->new(
        title            => 'fallback',
        tasks            => [ { id => 'only', label => 'Only task' } ],
        stream           => $plain_stream,
        max_detail_lines => 0,
    );
    for my $idx ( 1 .. 12 ) {
        $fallback_progress->update( { task_id => 'only', status => 'running', detail_line => "line $idx" } );
    }
    like( $fallback_progress->render_text, qr/line 3/, 'falsey max_detail_lines falls back to the ten-line rolling window' );
    unlike( $fallback_progress->render_text, qr/line 2/, 'fallback rolling window still drops lines older than the newest ten entries' );
    ok(
        $fallback_progress->update(
            {
                task_id      => 'only',
                status       => 'running',
                detail_lines => [ map { "fallback replace $_" } 1 .. 12 ],
            }
        ),
        'whole-window replacement also uses the ten-line fallback when max_detail_lines is falsey',
    );
    like( $fallback_progress->render_text, qr/fallback replace 3/, 'falsey max_detail_lines keeps the newest replacement lines' );
    unlike( $fallback_progress->render_text, qr/fallback replace 2/, 'falsey max_detail_lines drops older replacement lines' );
    $fallback_progress->{max_detail_lines} = 0;
    ok(
        $fallback_progress->update(
            {
                task_id      => 'only',
                status       => 'running',
                detail_lines => [ map { "mutated zero $_" } 1 .. 12 ],
            }
        ),
        'detail_lines replacement falls back to ten entries when max_detail_lines is reset to zero after construction',
    );
    like( $fallback_progress->render_text, qr/mutated zero 3/, 'runtime zero max_detail_lines keeps the newest replacement entries' );
    unlike( $fallback_progress->render_text, qr/mutated zero 2/, 'runtime zero max_detail_lines drops the oldest replacement entries' );
    ok(
        $fallback_progress->update(
            {
                task_id     => 'only',
                status      => 'running',
                detail_line => 'mutated zero appended',
            }
        ),
        'detail_line append also falls back to ten entries when max_detail_lines is reset to zero after construction',
    );
    like( $fallback_progress->render_text, qr/mutated zero appended/, 'runtime zero max_detail_lines keeps appended detail lines' );

    my $replace_progress = Developer::Dashboard::CLI::Progress->new(
        title            => 'replace',
        tasks            => [ { id => 'only', label => 'Only task' } ],
        stream           => $plain_stream,
        max_detail_lines => 3,
    );
    ok(
        $replace_progress->update(
            {
                task_id      => 'only',
                status       => 'running',
                detail_lines => [ map { "replace $_" } 1 .. 5 ],
            }
        ),
        'update accepts whole detail window replacements',
    );
    like( $replace_progress->render_text, qr/replace 3/, 'whole-window detail replacement keeps the newest entries when the supplied list is longer than the configured max' );
    unlike( $replace_progress->render_text, qr/replace 2/, 'whole-window detail replacement drops entries older than the configured max' );
    $replace_progress->{tasks}{only}{detail_lines} = undef;
    ok(
        $replace_progress->update(
            {
                task_id     => 'only',
                status      => 'running',
                detail_line => 'replace appended from empty',
            }
        ),
        'single-line detail updates tolerate an undefined existing detail window',
    );
    like( $replace_progress->render_text, qr/replace appended from empty/, 'single-line detail update rebuilds the detail window from empty state' );

    ok( $plain_progress->add_tasks(), 'add_tasks ignores missing task arrays' );
    ok( $plain_progress->add_tasks('not-an-array'), 'add_tasks ignores non-array task lists' );
    ok(
        $plain_progress->add_tasks(
            [
                'not-a-hash',
                {},
                { id => 'only', label => 'Duplicate task id' },
                { id => 'implicit-added' },
                { id => 'labeled-added', label => 'Labeled added task' },
            ]
        ),
        'add_tasks skips invalid rows and appends only valid new tasks'
    );
    like( $plain_progress->render_text, qr/\[ \] implicit-added/, 'add_tasks falls back to the task id when the appended task label is missing' );
    like( $plain_progress->render_text, qr/\[ \] Labeled added task/, 'add_tasks preserves an explicit appended task label' );

    ok(
        $plain_progress->update(
            {
                add_tasks => [
                    { id => 'event-added', label => 'Event-added task' },
                ],
            }
        ),
        'update accepts add_tasks-only events'
    );
    like( $plain_progress->render_text, qr/\[ \] Event-added task/, 'update add_tasks-only events append new visible tasks' );

    my $unlimited_progress = Developer::Dashboard::CLI::Progress->new(
        title            => 'unlimited',
        tasks            => [ { id => 'only', label => 'Only task' } ],
        stream           => $plain_stream,
        max_detail_lines => undef,
    );
    is( $unlimited_progress->_detail_line_limit, undef, 'explicit undef max_detail_lines keeps the detail window unlimited' );
    ok(
        $unlimited_progress->update(
            {
                task_id      => 'only',
                status       => 'running',
                detail_lines => [ map { "unlimited $_" } 1 .. 12 ],
            }
        ),
        'update accepts whole detail window replacements when max_detail_lines is explicitly undef',
    );
    like( $unlimited_progress->render_text, qr/unlimited 1/, 'explicit undef max_detail_lines keeps the oldest detail line instead of trimming it' );
    like( $unlimited_progress->render_text, qr/unlimited 12/, 'explicit undef max_detail_lines also keeps the newest detail line' );

    my $dynamic_unrendered = Developer::Dashboard::CLI::Progress->new(
        title   => 'dynamic',
        tasks   => [ { id => 'only', label => 'Only task' } ],
        stream  => $plain_stream,
        dynamic => 1,
    );
    $dynamic_unrendered->{rendered} = 0;
    ok( $dynamic_unrendered->finish, 'finish also returns early when a dynamic board has not rendered yet' );
    $dynamic_unrendered->{rendered} = 1;
    $dynamic_unrendered->{last_rendered_line_count} = 0;
    ok( $dynamic_unrendered->render, 'render tolerates a dynamic redraw with zero remembered line count' );
};

subtest 'CLI::Complete covers tmux session and collector-name providers' => sub {
    no warnings 'redefine';

    local *Developer::Dashboard::CLI::Ticket::list_sessions = sub { return qw(ticket-123 ticket-456) };
    local *Developer::Dashboard::PathRegistry::new = sub { return bless {}, 'TestCLIPathRegistry' };
    local *Developer::Dashboard::FileRegistry::new = sub { return bless {}, 'TestCLIFileRegistry' };
    local *Developer::Dashboard::Config::new       = sub { return bless {}, 'TestCLICompleteConfig' };
    local *Developer::Dashboard::Collector::new    = sub { return bless {}, 'TestCLICollector' };
    local *Developer::Dashboard::CLI::Suggest::new = sub { return bless {}, 'TestCLISuggest' };

    is_deeply(
        [ Developer::Dashboard::CLI::Complete::_ticket_sessions() ],
        [ qw(ticket-123 ticket-456) ],
        '_ticket_sessions proxies the tmux session list',
    );

    is_deeply(
        [ sort( Developer::Dashboard::CLI::Complete::_collector_names() ) ],
        [ qw(collector-one collector-three collector-two) ],
        '_collector_names merges configured and runtime collector names without duplicates',
    );

    my @top_level = Developer::Dashboard::CLI::Complete::complete(
        words => [ 'dashboard', '' ],
        index => 1,
    );
    ok( scalar grep { $_ eq 'skills' } @top_level, 'complete includes top-level built-in candidates' );

    is_deeply(
        [ Developer::Dashboard::CLI::Complete::complete( words => [ 'dashboard', 'skills', 'i' ], index => 2 ) ],
        ['install'],
        'complete filters static second-level candidates by the active prefix',
    );

    is_deeply(
        [
            sort( Developer::Dashboard::CLI::Complete::complete(
                words            => [ 'dashboard', 'restart', 'collector', 'collector-' ],
                index            => 3,
                collector_names  => sub { return qw(collector-one collector-two); },
            ) )
        ],
        [ qw(collector-one collector-two) ],
        'complete uses the collector-name provider for restart collector completion',
    );

    is_deeply(
        [ Developer::Dashboard::CLI::Complete::_subcommand_candidates('logs') ],
        [ qw(web collector) ],
        '_subcommand_candidates includes runtime-control scopes for logs',
    );
};

subtest 'CLI::Paths covers current-directory delete normalization branches' => sub {
    my $tmp = tempdir( CLEANUP => 1 );
    my $cwd = File::Spec->catdir( $tmp, 'current-dir' );
    make_path($cwd);
    my $previous = File::Spec->catdir( $tmp, 'previous-dir' );
    make_path($previous);
    my $old = Cwd::getcwd();
    chdir $cwd or die "Unable to chdir to $cwd: $!";

    my $config = bless {}, 'TestCLIPathsConfig';
    no warnings 'redefine';
    local *TestCLIPathsConfig::path_aliases = sub {
        return {
            alpha => $previous,
            beta  => $cwd,
        };
    };

    is(
        Developer::Dashboard::CLI::Paths::_normalize_delete_argument(
            paths  => bless( {}, 'TestCLIPathRegistry' ),
            config => $config,
            name   => '.',
        ),
        'beta',
        '_normalize_delete_argument falls back to the first alias that resolves to the current directory',
    );

    local *TestCLIPathsConfig::path_aliases = sub { return { alpha => $previous }; };
    is(
        Developer::Dashboard::CLI::Paths::_normalize_delete_argument(
            paths  => bless( {}, 'TestCLIPathRegistry' ),
            config => $config,
            name   => '.',
        ),
        'current-dir',
        '_normalize_delete_argument falls back to the current directory basename when no alias targets cwd',
    );

    chdir $old or die "Unable to chdir back to $old: $!";
};

subtest 'CLI::Files covers files inventory and locate branches' => sub {
    my $tmp = tempdir( CLEANUP => 1 );
    my $scan_root = File::Spec->catdir( $tmp, 'scan' );
    make_path($scan_root);
    my $old = Cwd::getcwd();
    chdir $tmp or die "Unable to chdir to $tmp: $!";
    my %file_aliases = (
        alias_file => '/tmp/alias-file.txt',
        root_dir   => '/tmp/root-dir',
    );

    no warnings 'redefine';
    no warnings 'once';

    local *Developer::Dashboard::CLI::Files::_build_paths = sub { return bless {}, 'TestCLIPathRegistry' };
    local *Developer::Dashboard::FileRegistry::new = sub {
        return bless {
            named => {},
            all   => { builtin => '/tmp/builtin.txt' },
        }, 'TestCLIFileRegistry';
    };
    local *Developer::Dashboard::Config::new = sub { return bless {}, 'TestCLIConfig' };
    local *TestCLIConfig::file_aliases = sub { return { %file_aliases }; };
    local *TestCLIConfig::save_global_file_alias = sub {
        my ( $self, $name, $path ) = @_;
        $file_aliases{$name} = $path;
        return { name => $name, path => $path };
    };
    local *TestCLIConfig::remove_global_file_alias = sub {
        my ( $self, $name ) = @_;
        my $removed = delete $file_aliases{$name} ? 1 : 0;
        return { name => $name, removed => $removed };
    };
    local *TestCLIFileRegistry::register_named_files = sub {
        my ( $self, $aliases ) = @_;
        %{$self->{named}} = ( %{$self->{named}}, %{ $aliases || {} } );
        return $self;
    };
    local *TestCLIFileRegistry::all_files = sub {
        my ($self) = @_;
        return { %{ $self->{all} }, %{ $self->{named} } };
    };
    local *TestCLIFileRegistry::named_files = sub {
        my ($self) = @_;
        return { %{ $self->{named} } };
    };
    local *TestCLIFileRegistry::resolve_file = sub {
        my ( $self, $name ) = @_;
        die "Unknown file name '$name'" if !exists $self->{named}{$name};
        return $self->{named}{$name};
    };
    local *TestCLIFileRegistry::locate_files_under = sub {
        my ( $self, $root, @terms ) = @_;
        return map { File::Spec->catfile( $root, $_ ) } @terms;
    };
    local *TestCLIFileRegistry::unregister_named_file = sub {
        my ( $self, $name ) = @_;
        delete $self->{named}{$name};
        return $self;
    };

    my ( $stdout_files ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'files', args => [] );
    };
    like( $stdout_files, qr/^File\s+Value/m, 'files command defaults to a summary table' );
    like( $stdout_files, qr/builtin\s+\/tmp\/builtin\.txt/, 'files command summary table includes built-in inventory rows' );
    like( $stdout_files, qr/alias_file\s+\/tmp\/alias-file\.txt/, 'files command summary table includes configured alias rows' );
    my ( $stdout_files_json ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'files', args => [ '-o', 'json' ] );
    };
    is( decode_json($stdout_files_json)->{builtin}, '/tmp/builtin.txt', 'files command can still emit the full JSON payload explicitly' );

    my ( $stdout_resolve ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'resolve', 'alias_file' ] );
    };
    is( $stdout_resolve, "/tmp/alias-file.txt\n", 'file resolve prints the resolved alias path' );

    my ( $stdout_locate_alias ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'locate', 'root_dir', 'needle.txt', '-o', 'json' ] );
    };
    is_deeply(
        decode_json($stdout_locate_alias),
        [ '/tmp/root-dir/needle.txt' ],
        'file locate can scope the search to a resolved file alias path',
    );

    my ( $stdout_locate_dir ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'locate', $scan_root, 'match.txt', '-o', 'json' ] );
    };
    is_deeply(
        decode_json($stdout_locate_dir),
        [ File::Spec->catfile( $scan_root, 'match.txt' ) ],
        'file locate can scope the search to an explicit directory argument',
    );

    my ( $stdout_locate_table ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'locate', 'plain.txt' ] );
    };
    like( $stdout_locate_table, qr/^Path\s*$/m, 'file locate defaults to a one-column summary table' );
    like( $stdout_locate_table, qr/\Q$tmp\/plain.txt\E/, 'file locate default table searches beneath the current working directory' );

    my ( $stdout_add ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'add', 'report', '/tmp/report.txt' ] );
    };
    like( $stdout_add, qr/^Alias\s+Stored\s+Resolved\s+Status/m, 'file add defaults to a mutation summary table' );
    like( $stdout_add, qr/report\s+\/tmp\/report\.txt\s+\/tmp\/report\.txt\s+saved/, 'file add summary table reports the stored and resolved file target' );

    my ( $stdout_list ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'list' ] );
    };
    like( $stdout_list, qr/^Alias\s+Path/m, 'file list defaults to an alias summary table' );
    like( $stdout_list, qr/alias_file\s+\/tmp\/alias-file\.txt/, 'file list summary table includes configured aliases' );
    like( $stdout_list, qr/report\s+\/tmp\/report\.txt/, 'file list summary table includes newly added aliases' );

    my ( $stdout_del ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'del', 'report' ] );
    };
    like( $stdout_del, qr/^Alias\s+Removed\s+Status/m, 'file del defaults to a removal summary table' );
    like( $stdout_del, qr/report\s+yes\s+removed/, 'file del summary table reports removed aliases' );

    like(
        Developer::Dashboard::CLI::Files::_render_table(
            [ 'Alias', 'Status' ],
            [
                [ undef,     'saved' ],
                [ 'example', undef ],
            ],
        ),
        qr/^Alias\s+Status/m,
        '_render_table handles undef file-table cells while preserving the header row',
    );

    like(
        _dies( sub { Developer::Dashboard::CLI::Files::run_files_command( command => 'files', args => [ '-o', 'yaml' ] ) } ),
        qr/Usage: dashboard files \[-o json\|table\]/,
        'files rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'locate', '-o', 'yaml', 'plain.txt' ] ) } ),
        qr/Usage: dashboard file locate \[-o json\|table\]/,
        'file locate rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'add', '-o', 'yaml', 'bad', '/tmp/bad.txt' ] ) } ),
        qr/Usage: dashboard file add <name> <path> \[-o json\|table\]/,
        'file add rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'del', '-o', 'yaml', 'bad' ] ) } ),
        qr/Usage: dashboard file del <name> \[-o json\|table\]/,
        'file del rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [ 'list', '-o', 'yaml' ] ) } ),
        qr/Usage: dashboard file list \[-o json\|table\]/,
        'file list rejects unsupported output formats explicitly',
    );

    chdir $old or die "Unable to chdir back to $old: $!";
};

subtest 'CLI::Paths covers table defaults and output guards' => sub {
    my $tmp = tempdir( CLEANUP => 1 );
    my $cwd = File::Spec->catdir( $tmp, 'cwd' );
    my $named_root = File::Spec->catdir( $tmp, 'named-root' );
    my $project_root = File::Spec->catdir( $tmp, 'project-root' );
    my $workspace_hit = File::Spec->catdir( $tmp, 'workspace-hit' );
    my $nested_hit = File::Spec->catdir( $named_root, 'alpha-hit' );
    make_path( $cwd, $named_root, $project_root, $workspace_hit, $nested_hit );
    my $old = Cwd::getcwd();
    chdir $cwd or die "Unable to chdir to $cwd: $!";
    my %path_aliases = (
        root_alias => $named_root,
        home       => $cwd,
    );

    no warnings 'redefine';
    no warnings 'once';

    local *Developer::Dashboard::CLI::Paths::_build_paths = sub {
        return bless {
            named_paths => {},
        }, 'TestCLIPathRegistry';
    };
    local *Developer::Dashboard::Config::new = sub { return bless {}, 'TestCLIPathsConfig' };
    local *TestCLIPathsConfig::path_aliases = sub { return { %path_aliases }; };
    local *TestCLIPathsConfig::save_global_path_alias = sub {
        my ( $self, $name, $path ) = @_;
        $path_aliases{$name} = $path;
        return { name => $name, path => $path };
    };
    local *TestCLIPathsConfig::remove_global_path_alias = sub {
        my ( $self, $name ) = @_;
        my $removed = delete $path_aliases{$name} ? 1 : 0;
        return { name => $name, removed => $removed };
    };
    local *TestCLIPathRegistry::register_named_paths = sub {
        my ( $self, $aliases ) = @_;
        %{$self->{named_paths}} = ( %{$self->{named_paths}}, %{ $aliases || {} } );
        return $self;
    };
    local *TestCLIPathRegistry::unregister_named_path = sub {
        my ( $self, $name ) = @_;
        delete $self->{named_paths}{$name};
        return $self;
    };
    local *TestCLIPathRegistry::named_paths = sub { return $_[0]{named_paths}; };
    local *TestCLIPathRegistry::all_paths = sub {
        return {
            home_runtime_root => '/tmp/home-runtime',
            cwd               => $cwd,
        };
    };
    local *TestCLIPathRegistry::all_path_aliases = sub {
        my ($self) = @_;
        return {
            home => $cwd,
            %{ $self->{named_paths} || {} },
        };
    };
    local *TestCLIPathRegistry::resolve_dir = sub {
        my ( $self, $name ) = @_;
        die "Unknown path alias '$name'" if !exists $self->{named_paths}{$name};
        return $self->{named_paths}{$name};
    };
    local *TestCLIPathRegistry::locate_projects = sub {
        my ( $self, @terms ) = @_;
        return map { File::Spec->catdir( $workspace_hit, $_ ) } @terms;
    };
    local *TestCLIPathRegistry::locate_dirs_under = sub {
        my ( $self, $root, @terms ) = @_;
        return map { File::Spec->catdir( $root, $_ ) } @terms;
    };
    local *TestCLIPathRegistry::current_working_directory = sub { return $cwd; };
    local *TestCLIPathRegistry::current_project_root = sub { return $project_root; };

    my ( $stdout_paths ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'paths', args => [] );
    };
    like( $stdout_paths, qr/^Path\s+Value/m, 'paths defaults to a summary table' );
    like( $stdout_paths, qr/home_runtime_root\s+\/tmp\/home-runtime/, 'paths summary table includes the runtime inventory rows' );
    my ( $stdout_paths_json ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'paths', args => [ '-o', 'json' ] );
    };
    is( decode_json($stdout_paths_json)->{home_runtime_root}, '/tmp/home-runtime', 'paths can still emit the full JSON payload explicitly' );

    my ( $stdout_locate ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'locate', 'match-dir' ] );
    };
    like( $stdout_locate, qr/^Path\s*$/m, 'path locate defaults to a one-column summary table' );
    like( $stdout_locate, qr/\Q$workspace_hit\/match-dir\E/, 'path locate table includes the matched project path' );

    my ( $stdout_add ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'add', 'demo', $named_root ] );
    };
    like( $stdout_add, qr/^Alias\s+Stored\s+Resolved\s+Status/m, 'path add defaults to a mutation summary table' );
    like( $stdout_add, qr/demo\s+\Q$named_root\E\s+\Q$named_root\E\s+saved/, 'path add summary table reports the stored and resolved target' );

    my ( $stdout_list ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'list' ] );
    };
    like( $stdout_list, qr/^Alias\s+Path/m, 'path list defaults to an alias summary table' );
    like( $stdout_list, qr/root_alias\s+\Q$named_root\E/, 'path list summary table includes configured aliases' );
    like( $stdout_list, qr/demo\s+\Q$named_root\E/, 'path list summary table includes added aliases' );

    my ( $stdout_del ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'del', 'demo' ] );
    };
    like( $stdout_del, qr/^Alias\s+Removed\s+Status/m, 'path del defaults to a removal summary table' );
    like( $stdout_del, qr/demo\s+yes\s+removed/, 'path del summary table reports removed aliases' );

    my ( $stdout_project_root ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'project-root' ] );
    };
    is( $stdout_project_root, "$project_root\n", 'path project-root prints the current project root' );

    like(
        Developer::Dashboard::CLI::Paths::_render_table(
            [ 'Alias', 'Status' ],
            [
                [ undef,     'saved' ],
                [ 'example', undef ],
            ],
        ),
        qr/^Alias\s+Status/m,
        '_render_table handles undef path-table cells while preserving the header row',
    );

    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'paths', args => [ '-o', 'yaml' ] ) } ),
        qr/Usage: dashboard paths \[-o json\|table\]/,
        'paths rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'locate', '-o', 'yaml', 'match-dir' ] ) } ),
        qr/Usage: dashboard path locate \[-o json\|table\]/,
        'path locate rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'add', '-o', 'yaml', 'demo', $named_root ] ) } ),
        qr/Usage: dashboard path add <name> <path> \[-o json\|table\]/,
        'path add rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'del', '-o', 'yaml', 'demo' ] ) } ),
        qr/Usage: dashboard path del <name> \[-o json\|table\]/,
        'path del rejects unsupported output formats explicitly',
    );
    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [ 'list', '-o', 'yaml' ] ) } ),
        qr/Usage: dashboard path list \[-o json\|table\]/,
        'path list rejects unsupported output formats explicitly',
    );

    chdir $old or die "Unable to chdir back to $old: $!";
};

subtest 'Developer::Dashboard::File and FileRegistry cover direct file helpers' => sub {
    my $tmp = tempdir( CLEANUP => 1 );
    my $logs_root = File::Spec->catdir( $tmp, 'logs' );
    my $config_root = File::Spec->catdir( $tmp, 'config' );
    my $dashboards_root = File::Spec->catdir( $tmp, 'dashboards' );
    my $state_root = File::Spec->catdir( $tmp, 'state' );
    make_path( $logs_root, $config_root, $dashboards_root, $state_root );

    my $paths = TestCoveragePaths->new(
        logs_root       => $logs_root,
        config_root     => $config_root,
        dashboards_root => $dashboards_root,
        state_root      => $state_root,
        cwd             => $tmp,
        runtime_roots   => [$tmp],
    );

    my $registry = Developer::Dashboard::FileRegistry->new( paths => $paths );
    $registry->register_named_files(
        {
            notes => File::Spec->catfile( $tmp, 'notes.txt' ),
            temp  => File::Spec->catfile( $tmp, 'temp.txt' ),
        }
    );

    no warnings 'redefine';
    local *Developer::Dashboard::Config::new = sub { return bless {}, 'TestFileConfig' };

    my $all_aliases = $registry->all_file_aliases;
    is( $all_aliases->{prompt_log}, File::Spec->catfile( $logs_root, 'prompt.log' ), 'all_file_aliases exposes built-in prompt_log' );
    is( $all_aliases->{web_state}, File::Spec->catfile( $state_root, 'web.json' ), 'all_file_aliases exposes built-in web_state' );

    my $all_files = $registry->all_files;
    is( $all_files->{notes}, File::Spec->catfile( $tmp, 'notes.txt' ), 'all_files merges named aliases with built-ins' );
    is( $registry->resolve_file('notes'), File::Spec->catfile( $tmp, 'notes.txt' ), 'resolve_file returns a registered alias path' );
    is( $registry->resolve_file( File::Spec->catfile( $tmp, 'direct.txt' ) ), File::Spec->catfile( $tmp, 'direct.txt' ), 'resolve_file accepts a direct absolute path' );
    is( $registry->resolve_file('cfg'), '/tmp/from-config.txt', 'resolve_file falls back to config-backed aliases' );

    my $scan_root = File::Spec->catdir( $tmp, 'scan' );
    make_path($scan_root);
    my $scan_file = File::Spec->catfile( $scan_root, 'needle-file.txt' );
    open my $scan_fh, '>', $scan_file or die $!;
    print {$scan_fh} "needle\n";
    close $scan_fh or die $!;
    is_deeply( [ $registry->locate_files('needle') ], [ $scan_file ], 'locate_files searches below cwd' );
    is_deeply( [ $registry->locate_files_under( $scan_root, 'needle', 'file' ) ], [ $scan_file ], 'locate_files_under matches every term case-insensitively' );

    $registry->write( 'notes', "first\n" );
    is( $registry->read('notes'), "first\n", 'write and read round-trip file contents' );
    $registry->append( 'notes', "second\n" );
    is( $registry->read('notes'), "first\nsecond\n", 'append extends the existing file' );
    ok( -e $registry->touch('temp'), 'touch creates a missing file' );
    ok( !-e $registry->remove('temp'), 'remove deletes a touched file' );
    $registry->unregister_named_file('notes');
    ok( !exists $registry->named_files->{notes}, 'unregister_named_file removes the alias from the registry' );

    local $Developer::Dashboard::File::FILES = undef;
    local %Developer::Dashboard::File::ALIASES = ();
    local %Developer::Dashboard::File::CONFIG_ALIASES = ();
    local $Developer::Dashboard::File::CONFIG_ALIASES_KEY = '';
    local $ENV{DEVELOPER_DASHBOARD_FILE_ENVONLY} = File::Spec->catfile( $tmp, 'env-only.txt' );
    Developer::Dashboard::File->configure(
        files   => $registry,
        aliases => { direct => File::Spec->catfile( $tmp, 'direct.txt' ) },
    );

    Developer::Dashboard::File->write( direct => "alpha\n" );
    is( Developer::Dashboard::File->read('direct'), "alpha\n", 'File->read uses configured aliases' );
    is( Developer::Dashboard::File->cat('direct'), "alpha\n", 'File->cat is an alias for read' );
    ok( Developer::Dashboard::File->exists('direct'), 'File->exists reports files on disk' );
    ok( !Developer::Dashboard::File->exists('missing'), 'File->exists reports false for unknown files' );
    is( Developer::Dashboard::File->all->{cfg}, '/tmp/from-config.txt', 'File->all returns the registry-backed file inventory hash' );
    ok( Developer::Dashboard::File->touch('direct'), 'File->touch succeeds for configured aliases' );
    is( Developer::Dashboard::File->resolve('envonly'), $ENV{DEVELOPER_DASHBOARD_FILE_ENVONLY}, 'File->resolve falls back to the env override naming convention' );
    ok( Developer::Dashboard::File->rm('direct'), 'File->rm removes an existing aliased file' );
    ok( !-e File::Spec->catfile( $tmp, 'direct.txt' ), 'rm deletes the aliased file path' );

    local $Developer::Dashboard::File::FILES = undef;
    local %Developer::Dashboard::File::ALIASES = ();
    local %Developer::Dashboard::File::CONFIG_ALIASES = ();
    local $Developer::Dashboard::File::CONFIG_ALIASES_KEY = '';
    no warnings 'redefine';
    local *Developer::Dashboard::FileRegistry::new = sub {
        my ( $class, %args ) = @_;
        return bless { paths => $args{paths}, named => {} }, 'TestCLIFileRegistry';
    };
    Developer::Dashboard::File->configure(
        paths   => $paths,
        aliases => { generated => File::Spec->catfile( $tmp, 'generated.txt' ) },
    );
    is(
        Developer::Dashboard::File->resolve('generated'),
        File::Spec->catfile( $tmp, 'generated.txt' ),
        'File->configure can lazily build a registry from paths when no files object is supplied',
    );
};

subtest 'CLI::Skills covers helper branches and table rendering' => sub {
    no warnings 'redefine';
    no warnings 'once';

    require Developer::Dashboard::SkillDispatcher;

    local *Developer::Dashboard::CLI::Skills::_build_paths = sub { return bless {}, 'TestCLIPathRegistry' };
    local *Developer::Dashboard::SkillManager::new = sub { return TestSkillsManager->new(@_) };
    local *Developer::Dashboard::SkillManager::install_progress_tasks = sub { return TestSkillsManager->install_progress_tasks(@_) };
    local *Developer::Dashboard::SkillManager::install_progress_tasks_for_sources = sub { return TestSkillsManager->install_progress_tasks_for_sources(@_) };
    local *Developer::Dashboard::CLI::Progress::new = sub { return TestSkillsProgress->new(@_) };
    local *Developer::Dashboard::SkillDispatcher::new = sub { return bless {}, 'TestSkillsDispatcher' };
    local *Developer::Dashboard::SkillDispatcher::exec_command = sub { return $TestSkillsDispatcher::RESULT };

    my ( undef, $stderr_usage ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'install', '-o', 'yaml' ],
        );
        is( $exit, 2, 'invalid install output returns the usage exit code' );
    };
    like( $stderr_usage, qr/Usage: dashboard skills install/, 'invalid install output prints the usage message' );

    my ( $stdout_uninstall ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'uninstall', 'demo' ],
        );
        is( $exit, 0, 'uninstall returns success' );
    };
    like( $stdout_uninstall, qr/^Skill\s+Status/m, 'uninstall defaults to a table summary' );
    like( $stdout_uninstall, qr/demo\s+removed/, 'uninstall table summary reports the removed skill' );
    my ( $stdout_uninstall_json ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'uninstall', 'demo', '-o', 'json' ],
        );
        is( $exit, 0, 'uninstall json returns success' );
    };
    is( decode_json($stdout_uninstall_json)->{repo_name}, 'demo', 'uninstall prints the uninstall payload as JSON when requested' );

    my ( $stdout_enable ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'enable', 'demo' ],
        );
        is( $exit, 0, 'enable returns success' );
    };
    like( $stdout_enable, qr/^Skill\s+Status\s+Enabled/m, 'enable defaults to a table summary' );
    like( $stdout_enable, qr/demo\s+enabled\s+yes/, 'enable table summary reports the enabled result' );
    my ( $stdout_enable_json ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'enable', 'demo', '-o', 'json' ],
        );
        is( $exit, 0, 'enable json returns success' );
    };
    ok( decode_json($stdout_enable_json)->{enabled}, 'enable prints the enabled result as JSON when requested' );

    my ( $stdout_disable ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'disable', 'demo' ],
        );
        is( $exit, 0, 'disable returns success' );
    };
    like( $stdout_disable, qr/^Skill\s+Status\s+Enabled/m, 'disable defaults to a table summary' );
    like( $stdout_disable, qr/demo\s+disabled\s+no/, 'disable table summary reports the disabled result' );
    my ( $stdout_disable_json ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'disable', 'demo', '-o', 'json' ],
        );
        is( $exit, 0, 'disable json returns success' );
    };
    ok( !decode_json($stdout_disable_json)->{enabled}, 'disable prints the disabled result as JSON when requested' );

    my ( $stdout_list_json ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'list', '-o', 'json' ],
        );
        is( $exit, 0, 'list json returns success' );
    };
    is( decode_json($stdout_list_json)->{skills}[0]{name}, 'demo', 'list json prints the skill payload' );

    my ( $stdout_list_table ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'list', '-o', 'table' ],
        );
        is( $exit, 0, 'list table returns success' );
    };
    like( $stdout_list_table, qr/Repo\s+Enabled\s+CLI/, 'list table renders a header row' );

    my $list_usage_ok = eval {
        capture {
            Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => [ 'list', '-o', 'yaml' ],
            );
        };
        1;
    };
    ok( !$list_usage_ok, 'list with invalid output dies with a usage message' );
    like( $@, qr/Usage: dashboard skills list/, 'list with invalid output prints the list usage message' );

    my ( $stdout_usage_json ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'usage', 'json_ok', '-o', 'json' ],
        );
        is( $exit, 0, 'usage json returns success' );
    };
    is( decode_json($stdout_usage_json)->{name}, 'demo', 'usage json prints the usage payload' );

    my ( $stdout_usage_table ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'usage', 'json_ok', '-o', 'table' ],
        );
        is( $exit, 0, 'usage table returns success' );
    };
    like( $stdout_usage_table, qr/Skill: demo/, 'usage table prints the skill header' );
    like( $stdout_usage_table, qr/CLI Commands/, 'usage table includes the CLI section' );

    my $usage_usage_ok = eval {
        capture {
            Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => [ 'usage', 'json_ok', '-o', 'yaml' ],
            );
        };
        1;
    };
    ok( !$usage_usage_ok, 'usage with invalid output dies with a usage message' );
    like( $@, qr/Usage: dashboard skills usage/, 'usage with invalid output prints the usage message' );

    my $install_table = '';
    my $install_exit = eval {
        $install_table = capture {
            my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => [ 'install', 'demo/source' ],
            );
            is( $exit, 0, 'default install table mode returns success' );
        };
        1;
    };
    ok( $install_exit, 'install table mode does not die on a successful install' );
    like( $install_table, qr/Skill\s+Source\s+Before\s+After\s+Status/, 'default install table mode prints the summary table header' );

    my $died = eval {
        no warnings 'redefine';
        local *TestSkillsManager::install = sub { die "kaboom\n" };
        local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
        capture {
            Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => [ 'install', 'demo/source' ],
            );
        };
        1;
    };
    ok( !$died, 'install propagates manager exceptions' );
    like( $@, qr/kaboom/, 'install reports the manager exception text' );

    my $usage_error = eval {
        capture {
            Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => [ 'usage', 'json_err', '-o', 'table' ],
            );
        };
        1;
    };
    ok( !$usage_error, 'usage table dies when the usage payload contains an error' );
    like( $@, qr/usage failed/, 'usage table propagates the usage error text' );

    local $TestSkillsDispatcher::RESULT = { error => 'dispatch failed' };
    my ( undef, $stderr_exec ) = capture {
        my $exit = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ '_exec', 'demo', 'hello' ],
        );
        is( $exit, 1, '_exec returns failure when the dispatcher reports an error' );
    };
    like( $stderr_exec, qr/dispatch failed/, '_exec prints dispatcher errors to STDERR' );

    local $TestSkillsDispatcher::RESULT = { ok => 1 };
    my $exec_exit = Developer::Dashboard::CLI::Skills::run_skills_command(
        command => 'skills',
        args    => [ '_exec', 'demo', 'hello' ],
    );
    is( $exec_exit, 0, '_exec returns success when the dispatcher succeeds' );

    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    my $one_progress = Developer::Dashboard::CLI::Skills::_skills_install_progress();
    isa_ok( $one_progress, 'TestSkillsProgress', '_skills_install_progress builds a progress object when enabled' );
    my $many_progress = Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources(qw(one two));
    isa_ok( $many_progress, 'TestSkillsProgress', '_skills_install_progress_for_sources builds a progress object for multiple sources' );
    ok( !Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources(), 'source progress is skipped when no sources were provided' );

    like(
        Developer::Dashboard::CLI::Skills::_skills_install_summary_table(
            { operations => [ { repo_name => 'demo', source => 'demo', status => 'failed' } ] }
        ),
        qr/No update\./,
        'summary table prints No update when the operations did not change any versions',
    );
    like(
        Developer::Dashboard::CLI::Skills::_skills_install_summary_table(
            { error => 'install failed', operations => [ { repo_name => 'demo', source => 'demo', status => 'failed' } ] }
        ),
        qr/Error: install failed/,
        'summary table prints explicit install errors',
    );
    is_deeply(
        [ Developer::Dashboard::CLI::Skills::_install_result_rows( { results => [ { repo_name => 'demo' } ] } ) ],
        [ { repo_name => 'demo' } ],
        '_install_result_rows normalizes the results payload shape',
    );
    is_deeply(
        [ Developer::Dashboard::CLI::Skills::_install_result_rows( { repo_name => 'single' } ) ],
        [ { repo_name => 'single' } ],
        '_install_result_rows also accepts a single-row payload',
    );
    is_deeply(
        [ Developer::Dashboard::CLI::Skills::_install_result_rows( { message => 'none' } ) ],
        [],
        '_install_result_rows returns an empty list for payloads with no row shape',
    );
    like( Developer::Dashboard::CLI::Skills::_skills_table( TestSkillsManager->list ), qr/enabled/, '_skills_table renders readable enabled text' );
    like( Developer::Dashboard::CLI::Skills::_usage_table( $TestSkillsManager::USAGE{json_ok} ), qr/yes/, '_usage_table renders boolean yes or no values' );

    my $unknown_action_ok = eval {
        capture {
            Developer::Dashboard::CLI::Skills::run_skills_command(
                command => 'skills',
                args    => ['bogus'],
            );
        };
        1;
    };
    ok( !$unknown_action_ok, 'unknown skills actions die with the explicit usage error' );
    like( $@, qr/Unknown skills action: bogus/, 'unknown skills actions print the explicit error text' );
};

subtest 'SkillManager closes the remaining direct error-path coverage branches' => sub {
    my $manager = bless {}, 'Developer::Dashboard::SkillManager';

    my $versionless_root = tempdir( CLEANUP => 1 );
    my $env_file = File::Spec->catfile( $versionless_root, '.env' );
    open my $env_fh, '>', $env_file or die $!;
    print {$env_fh} "# comment only\nNAME=demo\n";
    close $env_fh;
    is(
        $manager->_skill_env_version($versionless_root),
        undef,
        '_skill_env_version returns undef when .env has no VERSION entry',
    );

    is(
        $manager->_dependency_progress_label(
            'install_aptfile',
            tempdir( CLEANUP => 1 ),
            result => { error => "apt exploded\nwith details" },
        ),
        'Install aptfile dependencies (error: apt exploded with details)',
        '_dependency_progress_label still reports errors when the dependency file is absent',
    );

    my $copy_source_root = tempdir( CLEANUP => 1 );
    my $copy_source_dir = File::Spec->catdir( $copy_source_root, 'nested' );
    make_path($copy_source_dir);
    my $copy_source = File::Spec->catfile( $copy_source_dir, 'source.txt' );
    open my $copy_source_fh, '>', $copy_source or die $!;
    print {$copy_source_fh} "copied\n";
    close $copy_source_fh;
    chmod 0600, $copy_source or die $!;
    my $copy_target_root = tempdir( CLEANUP => 1 );
    $manager->_copy_tree_contents( $copy_source_root, $copy_target_root );
    my $copy_target = File::Spec->catfile( $copy_target_root, 'nested', 'source.txt' );
    ok( -f $copy_target, '_copy_tree_contents creates the target parent directory and copies the source file' );
    my $copied_mode = ( stat $copy_target )[2] & 07777;
    is( sprintf( '%04o', $copied_mode ), '0600', '_copy_tree_contents applies the requested file mode to copied targets' );

    my @events;
    my $progress_manager = bless {
        progress => sub {
            my ($event) = @_;
            push @events, { %{$event} };
        },
    }, 'Developer::Dashboard::SkillManager';
    my $manifest_root = tempdir( CLEANUP => 1 );
    my $manifest_path = File::Spec->catfile( $manifest_root, 'ddfile' );
    open my $manifest_fh, '>', $manifest_path or die $!;
    print {$manifest_fh} "broken/source\n";
    close $manifest_fh;
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_install_to_skills_root = sub {
        return { error => 'broken source' };
    };
    my @operations;
    my $manifest_failure = $progress_manager->_install_manifest_file(
        $manifest_path,
        manifest_name => 'ddfile',
        skills_root   => File::Spec->catdir( $manifest_root, 'skills' ),
        operations    => \@operations,
        progress      => 1,
    );
    is( $manifest_failure->{error}, 'broken source', '_install_manifest_file returns the failing source result immediately' );
    is_deeply( [ map { $_->{status} } @events ], [ 'running', 'failed' ], '_install_manifest_file emits failed progress before aborting' );
    is_deeply( \@operations, [], '_install_manifest_file does not append operations for failed sources' );

    my $make_root = tempdir( CLEANUP => 1 );
    my $makefile = File::Spec->catfile( $make_root, 'Makefile' );
    open my $make_fh, '>', $makefile or die $!;
    print {$make_fh} "install:\n\t\@true\n";
    close $make_fh;
    my $make_bin = File::Spec->catfile( $make_root, 'make' );
    open my $bin_fh, '>', $make_bin or die $!;
    print {$bin_fh} "#!/bin/sh\n";
    print {$bin_fh} "exit 1\n";
    close $bin_fh;
    chmod 0755, $make_bin or die $!;
    local *Developer::Dashboard::SkillManager::_makefile_targets = sub { return ('install'); };
    local $ENV{PATH} = join ':', $make_root, ( $ENV{PATH} || '' );
    my $make_failure = $manager->_install_skill_makefile($make_root);
    like(
        $make_failure->{error},
        qr/^Failed to run skill Makefile target 'default' for \Q$make_root\E: /,
        '_install_skill_makefile reports the failing default target explicitly',
    );

    my $named_make_root = tempdir( CLEANUP => 1 );
    my $named_makefile = File::Spec->catfile( $named_make_root, 'Makefile' );
    open my $named_make_fh, '>', $named_makefile or die $!;
    print {$named_make_fh} "install:\n\t\@true\n";
    close $named_make_fh;
    my $named_make_bin = File::Spec->catfile( $named_make_root, 'make' );
    open my $named_bin_fh, '>', $named_make_bin or die $!;
    print {$named_bin_fh} "#!/bin/sh\n";
    print {$named_bin_fh} "if [ \"\${1:-default}\" = \"install\" ]; then\n";
    print {$named_bin_fh} "  echo install failed >&2\n";
    print {$named_bin_fh} "  exit 1\n";
    print {$named_bin_fh} "fi\n";
    print {$named_bin_fh} "exit 0\n";
    close $named_bin_fh;
    chmod 0755, $named_make_bin or die $!;
    local $ENV{PATH} = join ':', $named_make_root, ( $ENV{PATH} || '' );
    my $named_make_failure = $manager->_install_skill_makefile($named_make_root);
    like(
        $named_make_failure->{error},
        qr/^Failed to run skill Makefile target 'install' for \Q$named_make_root\E: install failed/m,
        '_install_skill_makefile reports the failing named target explicitly',
    );

    my $winget_root = tempdir( CLEANUP => 1 );
    my $wingetfile = File::Spec->catfile( $winget_root, 'wingetfile' );
    open my $winget_fh, '>', $wingetfile or die $!;
    print {$winget_fh} "Git.Git\n";
    close $winget_fh;
    my $winget_bin = File::Spec->catfile( $winget_root, 'winget' );
    open my $winget_bin_fh, '>', $winget_bin or die $!;
    print {$winget_bin_fh} "#!/bin/sh\n";
    print {$winget_bin_fh} "echo winget-ok\n";
    print {$winget_bin_fh} "echo winget-warn >&2\n";
    print {$winget_bin_fh} "exit 0\n";
    close $winget_bin_fh;
    chmod 0755, $winget_bin or die $!;
    local $ENV{PATH} = join ':', $winget_root, ( $ENV{PATH} || '' );
    local *Developer::Dashboard::SkillManager::_is_windows = sub { 1 };
    my $winget_ok = $manager->_install_skill_wingetfile($winget_root);
    ok( $winget_ok->{success}, '_install_skill_wingetfile succeeds on Windows when winget exits cleanly' );
    is( $winget_ok->{stdout}, "winget-ok\n", '_install_skill_wingetfile returns streamed winget stdout without folding the progress banner into the result payload' );
    like( $winget_ok->{stderr}, qr/winget-warn/, '_install_skill_wingetfile returns combined stderr from winget' );

    open my $winget_fail_fh, '>', $winget_bin or die $!;
    print {$winget_fail_fh} "#!/bin/sh\n";
    print {$winget_fail_fh} "echo broken-winget >&2\n";
    print {$winget_fail_fh} "exit 1\n";
    close $winget_fail_fh;
    chmod 0755, $winget_bin or die $!;
    my $winget_fail = $manager->_install_skill_wingetfile($winget_root);
    like(
        $winget_fail->{error},
        qr/^Failed to install skill winget dependencies for \Q$winget_root\E: broken-winget/m,
        '_install_skill_wingetfile reports failing winget installs explicitly',
    );

    my $cpan_root = tempdir( CLEANUP => 1 );
    my $cpanfile = File::Spec->catfile( $cpan_root, 'cpanfile' );
    open my $cpan_fh, '>', $cpanfile or die $!;
    print {$cpan_fh} "requires 'Test::More';\n";
    close $cpan_fh;
    my $original_cwd = Cwd::getcwd();
    my $cpan_error = do {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_shared_perl_root = sub { return File::Spec->catdir( $cpan_root, 'perl5-shared' ) };
        local *Developer::Dashboard::SkillManager::_ensure_perl_root = sub { return $_[1] };
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            return {
                stdout => '',
                stderr => "cpan boom\n",
                exit   => 1,
            };
        };
        eval { $manager->_install_skill_cpanfile($cpan_root); 1 } ? '' : $@;
    };
    is( $cpan_error, '', '_install_skill_cpanfile reports streaming failures as structured errors instead of throwing raw exceptions' );
    my $cpan_failure = do {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_shared_perl_root = sub { return File::Spec->catdir( $cpan_root, 'perl5-shared' ) };
        local *Developer::Dashboard::SkillManager::_ensure_perl_root = sub { return $_[1] };
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            return {
                stdout => '',
                stderr => "cpan boom\n",
                exit   => 1,
            };
        };
        $manager->_install_skill_cpanfile($cpan_root);
    };
    like( $cpan_failure->{error}, qr/cpan boom/, '_install_skill_cpanfile surfaces the streamed cpanm failure text in the structured error result' );
    is( Cwd::getcwd(), $original_cwd, '_install_skill_cpanfile restores the original cwd after an in-flight failure' );

    my $cpan_local_root = tempdir( CLEANUP => 1 );
    my $cpanfile_local = File::Spec->catfile( $cpan_local_root, 'cpanfile.local' );
    open my $cpan_local_fh, '>', $cpanfile_local or die $!;
    print {$cpan_local_fh} "requires 'Test::More';\n";
    close $cpan_local_fh;
    my $cpan_local_error = do {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_skill_local_perl_root = sub { return File::Spec->catdir( $cpan_local_root, 'perl5-local' ) };
        local *Developer::Dashboard::SkillManager::_ensure_perl_root = sub { return $_[1] };
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            return {
                stdout => '',
                stderr => "cpan local boom\n",
                exit   => 1,
            };
        };
        eval { $manager->_install_skill_cpanfile_local($cpan_local_root); 1 } ? '' : $@;
    };
    is( $cpan_local_error, '', '_install_skill_cpanfile_local reports streaming failures as structured errors instead of throwing raw exceptions' );
    my $cpan_local_failure = do {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_skill_local_perl_root = sub { return File::Spec->catdir( $cpan_local_root, 'perl5-local' ) };
        local *Developer::Dashboard::SkillManager::_ensure_perl_root = sub { return $_[1] };
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            return {
                stdout => '',
                stderr => "cpan local boom\n",
                exit   => 1,
            };
        };
        $manager->_install_skill_cpanfile_local($cpan_local_root);
    };
    like( $cpan_local_failure->{error}, qr/cpan local boom/, '_install_skill_cpanfile_local surfaces the streamed cpanm failure text in the structured error result' );
    is( Cwd::getcwd(), $original_cwd, '_install_skill_cpanfile_local restores the original cwd after an in-flight failure' );
};

sub _dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}

done_testing();

__END__

=head1 NAME

43-explicit-coverage-qa.t - focused numeric coverage closure for helper modules

=head1 PURPOSE

This test exercises helper modules that are easy to miss in browser and CLI
smoke tests but still count against the explicit 100 percent library coverage
gate.

=head1 WHY IT EXISTS

It exists because the repository now treats the numeric Devel::Cover report as
a standing QA gate after the normal test gate on every change. That means the
helper modules used behind progress boards, file aliases, and lightweight skill
dispatch need direct unit coverage instead of relying on indirect smoke paths.

=head1 WHEN TO USE

Run this file when changing progress rendering, lightweight file and skills
helpers, compatibility file wrappers, or other direct helper branches that do
not naturally get exercised deeply enough by browser or shell smoke tests.

=head1 HOW TO USE

Run it directly with C<prove -lv t/43-explicit-coverage-qa.t> while iterating.
It uses mocked path, config, file-registry, skill-manager, and dispatcher
objects so helper logic can be exercised without booting the whole runtime.

=head1 WHAT USES IT

The explicit numeric Devel::Cover QA gate, the full C<prove -lr t> suite, and
future contributors who need a direct regression target for the helper modules
covered here all depend on this file.

=head1 EXAMPLES

  prove -lv t/43-explicit-coverage-qa.t

Run the focused helper coverage test by itself while iterating on uncovered
branches.

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/43-explicit-coverage-qa.t

Collect Devel::Cover data for the helper modules that this file targets.
