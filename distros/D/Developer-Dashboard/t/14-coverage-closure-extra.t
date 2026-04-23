use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Folder;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );
my $collector_store = Developer::Dashboard::Collector->new( paths => $paths );
my $indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector_store,
    files      => $files,
    indicators => $indicator_store,
    paths      => $paths,
);

{
    my $json_file = File::Spec->catfile( $paths->dashboards_root, 'migrated.json' );
    open my $fh, '>', $json_file or die $!;
    print {$fh} qq|{"id":"migrated","title":"Migrated","layout":{"body":"body"}}|;
    close $fh;

    my $migrated = $store->migrate_legacy_json_pages;
    is( ref($migrated), 'ARRAY', 'legacy json migration returns an array reference' );
    is( $migrated->[0]{id}, 'migrated', 'legacy json migration keeps page id' );
    ok( -f File::Spec->catfile( $paths->dashboards_root, 'migrated' ), 'legacy json migration writes canonical bookmark file' );
    ok( !-e $json_file, 'legacy json migration removes the original json file' );
}

{
    my $bad_stash = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Bad Stash
:--------------------------------------------------------------------------------:
STASH: []
PAGE
    is_deeply( $bad_stash->as_hash->{state}, {}, 'array stash input falls back to an empty hash' );
}

{
    make_path( File::Spec->catdir( $home, 'folder-env' ) );
    local $ENV{DEVELOPER_DASHBOARD_PATH_CUSTOM} = File::Spec->catdir( $home, 'folder-env' );
    Developer::Dashboard::Folder->configure( paths => $paths, aliases => {} );
    is( Developer::Dashboard::Folder->_resolve_path('custom'), File::Spec->catdir( $home, 'folder-env' ), 'Folder resolves DEVELOPER_DASHBOARD_PATH_* overrides' );
    ok( !defined Developer::Dashboard::Folder->_resolve_path('missing-folder-alias'), 'Folder returns undef for unknown folder aliases' );

    my $list_dir = File::Spec->catdir( $home, 'folder-list' );
    make_path( File::Spec->catdir( $list_dir, 'subdir' ) );
    open my $fh, '>', File::Spec->catfile( $list_dir, 'item.txt' ) or die $!;
    print {$fh} "item\n";
    close $fh;
    my @items = Developer::Dashboard::Folder->ls($list_dir);
    is( scalar @items, 2, 'Folder lists both directory and file entries' );
    is( $items[0]{type}, 'folder', 'Folder sorts directories before files' );
    is( $items[1]{type}, 'file', 'Folder records file entries' );
}

{
    my $timeout_dir = File::Spec->catdir( $home, 'timeout-run' );
    make_path($timeout_dir);
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command(
        source     => q{perl -e "sleep 2"},
        cwd        => $timeout_dir,
        timeout_ms => 50,
    );
    is( $exit_code, 124, 'collector command timeout returns 124' );
    ok( $timed_out, 'collector command timeout is marked as timed out' );
    is( $stdout, '', 'collector timeout leaves stdout empty' );
    is( $stderr, '', 'collector timeout leaves stderr empty' );
    ok( Developer::Dashboard::CollectorRunner::_cron_match( '*/5', 10 ), 'collector cron step matches divisible values' );
    ok( !Developer::Dashboard::CollectorRunner::_cron_match( '*/5', 3 ), 'collector cron step does not match unrelated values' );
    ok( !Developer::Dashboard::CollectorRunner::_cron_match( '9', 3 ), 'collector cron exact value can fail to match' );

    my ( $code_stdout, $code_stderr, $code_exit, $code_timed_out ) = $runner->_run_code(
        source     => q{sleep 2; return 0;},
        cwd        => $timeout_dir,
        timeout_ms => 50,
    );
    is( $code_exit, 124, 'collector perl-code timeout returns 124' );
    ok( $code_timed_out, 'collector perl-code timeout is marked as timed out' );
    is( $code_stdout, '', 'collector perl-code timeout leaves stdout empty' );
    is( $code_stderr, '', 'collector perl-code timeout leaves stderr empty' );

    my $mode_error = eval { $runner->_run_job( mode => 'bogus', source => '1', cwd => $timeout_dir ); 1 } ? '' : $@;
    like( $mode_error, qr/Unknown collector mode 'bogus'/, 'collector runner rejects unknown execution modes' );
}

{
    my $loop_name = 'coverage.loop';
    my $pidfile   = $runner->_pidfile($loop_name);
    my $statefile = $runner->_statefile($loop_name);

    my $managed_child = fork();
    die "fork failed: $!" if !defined $managed_child;
    if ( !$managed_child ) {
        $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $loop_name;
        $0 = $runner->_process_title($loop_name);
        $SIG{TERM} = 'IGNORE';
        sleep 30;
        exit 0;
    }
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $managed_child;
    close $fh;
    my @loops;
    for ( 1 .. 20 ) {
        @loops = $runner->running_loops;
        last if @loops == 1;
        select undef, undef, undef, 0.1;
    }
    is( scalar @loops, 1, 'running_loops lists active managed loop pids' );
    is( $loops[0]{name}, $loop_name, 'running_loops returns the managed loop name' );

    my $stopped_pid = $runner->stop_loop($loop_name);
    is( $stopped_pid, $managed_child, 'stop_loop returns managed loop pid' );
    waitpid( $managed_child, 0 );
    ok( !-e $pidfile, 'stop_loop removes loop pid files after forced kill' );
    ok( !-e $statefile, 'stop_loop removes loop state files after forced kill' );
}

{
    my $stale_name = 'coverage.stale';
    my $pidfile = $runner->_pidfile($stale_name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} 999999;
    close $fh;
    my @loops = $runner->running_loops;
    is( scalar @loops, 0, 'running_loops ignores stale unmanaged pids' );
    ok( !-e $pidfile, 'running_loops cleans up stale pid files' );
}

{
    my @names = qw(coverage.sort-b coverage.sort-a);
    my @children;
    for my $name (@names) {
        my $pid = fork();
        die "fork failed: $!" if !defined $pid;
        if ( !$pid ) {
            $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $name;
            $0 = $runner->_process_title($name);
            sleep 30;
            exit 0;
        }
        push @children, $pid;
        open my $fh, '>', $runner->_pidfile($name) or die $!;
        print {$fh} $pid;
        close $fh;
    }
    my @loops;
    for ( 1 .. 10 ) {
        @loops = $runner->running_loops;
        last if @loops == @names;
        select undef, undef, undef, 0.2;
    }
    is_deeply(
        [ map { $_->{name} } @loops ],
        [ sort @names ],
        'running_loops sorts managed loop rows by collector name',
    );
    for my $index ( 0 .. $#children ) {
        kill 'KILL', $children[$index];
        waitpid( $children[$index], 0 );
        $runner->_cleanup_loop_files( $names[$index] );
    }
}

{
    my $shutdown_name = 'coverage.shutdown';
    my $shutdown_pid = fork();
    die "fork failed: $!" if !defined $shutdown_pid;
    if ( !$shutdown_pid ) {
        my $child_runner = Developer::Dashboard::CollectorRunner->new(
            collectors => $collector_store,
            files      => $files,
            indicators => $indicator_store,
            paths      => $paths,
        );
        $child_runner->_shutdown_loop( $shutdown_name, 'stopped' );
    }
    waitpid( $shutdown_pid, 0 );
    is( $? >> 8, 0, '_shutdown_loop exits a managed child cleanly' );

    my $signal_name = 'coverage.signal';
    my $signal_pid = fork();
    die "fork failed: $!" if !defined $signal_pid;
    if ( !$signal_pid ) {
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER    = Developer::Dashboard::CollectorRunner->new(
            collectors => $collector_store,
            files      => $files,
            indicators => $indicator_store,
            paths      => $paths,
        );
        local $Developer::Dashboard::CollectorRunner::SIGNAL_LOOP_NAME = $signal_name;
        Developer::Dashboard::CollectorRunner::_signal_stop();
    }
    waitpid( $signal_pid, 0 );
    is( $? >> 8, 0, '_signal_stop exits a managed child cleanly' );
}

{
    my $loop_name = 'coverage.loop.child';
    my $child_pid = fork();
    die "fork failed: $!" if !defined $child_pid;
    if ( !$child_pid ) {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::run_once     = sub { return { ok => 1 } };
        my $ok = $runner->_run_loop_child(
            daemonize     => 1,
            interval      => 0,
            job           => { command => 'printf child', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        );
        exit( $ok ? 0 : 1 );
    }
    waitpid( $child_pid, 0 );
    is( $? >> 8, 0, '_run_loop_child returns cleanly after one daemonized tick' );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'running', '_run_loop_child writes running state during a successful tick' );
}

{
    my $fork_pid = $runner->_fork_process();
    die "fork helper failed: $!" if !defined $fork_pid;
    if ( !$fork_pid ) {
        exit 0;
    }
    waitpid( $fork_pid, 0 );
    is( $? >> 8, 0, '_fork_process returns a real child pid and allows the child to exit cleanly' );
}

{
    my $loop_name = 'coverage.start.parent';
    my $dispatch_name = 'coverage.start.child';
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 424242 };
    my $pid = $runner->start_loop(
        {
            name     => $loop_name,
            command  => q{printf parent},
            cwd      => 'home',
            interval => 5,
        }
    );
    is( $pid, 424242, 'start_loop uses the fork wrapper and returns the parent pid' );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'starting', 'start_loop parent path writes starting metadata without forking a real child' );
    is( $state->{pid}, 424242, 'start_loop parent path records the wrapped fork pid' );
    is( $files->read( File::Spec->catfile( $paths->collectors_root, "$loop_name.pid" ) ), '424242', 'start_loop parent path writes the pidfile from the wrapped fork result' );

    my $stale_name = 'coverage.start.stale';
    open my $stale_pid, '>', $runner->_pidfile($stale_name) or die $!;
    print {$stale_pid} "999999\n";
    close $stale_pid;
    $runner->_write_loop_state(
        $stale_name,
        {
            pid    => 999999,
            name   => $stale_name,
            status => 'running',
        }
    );
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 565656 };
    my $stale_started = $runner->start_loop(
        {
            name     => $stale_name,
            command  => q{printf stale},
            cwd      => 'home',
            interval => 3,
        }
    );
    is( $stale_started, 565656, 'start_loop replaces stale loop files before writing new parent state' );
    is( $runner->loop_state($stale_name)->{pid}, 565656, 'start_loop stale cleanup path overwrites the old loop state' );

    my @dispatch;
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_run_loop_child = sub {
        my ( $self, %args ) = @_;
        @dispatch = %args;
        return 1;
    };
    ok(
        $runner->start_loop(
            {
                name     => $dispatch_name,
                command  => q{printf child},
                cwd      => 'home',
                interval => 7,
                schedule => 'interval',
            }
        ) == 1,
        'start_loop child dispatch returns the wrapped child runner result when the child path is stubbed',
    );
    my %dispatch = @dispatch;
    is( $dispatch{interval}, 7, 'start_loop child path dispatches the configured interval' );
    is( $dispatch{name}, $dispatch_name, 'start_loop child path dispatches the collector name' );
    is( $dispatch{schedule_mode}, 'interval', 'start_loop child path dispatches the schedule mode' );
    is( $dispatch{title}, $runner->_process_title($dispatch_name), 'start_loop child path dispatches the managed process title' );
    is_deeply(
        $dispatch{job},
        {
            name     => $dispatch_name,
            command  => q{printf child},
            cwd      => 'home',
            interval => 7,
            schedule => 'interval',
        },
        'start_loop child path dispatches the expected collector job hash',
    );
}

{
    my $loop_name = 'coverage.loop.inline';
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::run_once     = sub { return { ok => 1 } };
    ok(
        $runner->_run_loop_child(
            daemonize     => 0,
            interval      => 0,
            job           => { command => 'printf inline', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        ),
        '_run_loop_child can execute a single non-daemonized coverage tick',
    );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'running', '_run_loop_child non-daemonized tick still writes running state' );
}

{
    my $loop_name = 'coverage.loop.scrub';
    my $seen_file = File::Spec->catfile( $paths->state_root, 'coverage-loop-scrub.json' );
    my $child_pid = fork();
    die "fork failed: $!" if !defined $child_pid;
    if ( !$child_pid ) {
        no warnings 'redefine';
        local $ENV{PERL5OPT} = '-MDevel::Cover';
        local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::run_once = sub {
            my ($self, $job) = @_;
            open my $fh, '>', $seen_file or die "Unable to write $seen_file: $!";
            print {$fh} json_encode(
                {
                    perl5opt               => ( defined $ENV{PERL5OPT} ? $ENV{PERL5OPT} : '' ),
                    harness_perl_switches  => ( defined $ENV{HARNESS_PERL_SWITCHES} ? $ENV{HARNESS_PERL_SWITCHES} : '' ),
                }
            );
            close $fh;
            return { ok => 1 };
        };
        my $ok = $runner->_run_loop_child(
            daemonize     => 0,
            interval      => 0,
            job           => { command => 'printf scrub', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        );
        exit( $ok ? 0 : 1 );
    }
    waitpid( $child_pid, 0 );
    is( $? >> 8, 0, '_run_loop_child keeps a coverage-instrumented child alive long enough to execute one scrubbed tick' );
    open my $seen_fh, '<', $seen_file or die "Unable to read $seen_file: $!";
    my $seen = json_decode( do { local $/; <$seen_fh> } );
    close $seen_fh;
    is( $seen->{perl5opt}, '', '_run_loop_child clears PERL5OPT inside managed collector children when coverage instrumentation is active' );
    is( $seen->{harness_perl_switches}, '', '_run_loop_child clears HARNESS_PERL_SWITCHES inside managed collector children when coverage instrumentation is active' );
}

{
    my $loop_name = 'coverage.loop.error';
    my $child_pid = fork();
    die "fork failed: $!" if !defined $child_pid;
    if ( !$child_pid ) {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::run_once     = sub { die "forced child failure\n" };
        my $ok = $runner->_run_loop_child(
            daemonize     => 1,
            interval      => 0,
            job           => { command => 'printf child', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        );
        exit( $ok ? 0 : 1 );
    }
    waitpid( $child_pid, 0 );
    is( $? >> 8, 0, '_run_loop_child returns cleanly after one daemonized error tick' );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'error', '_run_loop_child writes error state when a collector tick dies' );
    like( $state->{error}, qr/forced child failure/, '_run_loop_child persists the collector error message' );
}

{
    my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
    my $web_page = Developer::Dashboard::PageDocument->new(
        title  => 'Web Coverage',
        layout => {
            body => qq{<script>const value = "x";</script><div onclick="go()">[% stash.name %]</div>},
        },
    );
    my $rendered = $web_page->render_html;
    my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
    my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
    my $actions = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );
    my $prompt = Developer::Dashboard::Prompt->new( indicators => $indicator_store, paths => $paths );
    my $app = Developer::Dashboard::Web::App->new(
        actions  => $actions,
        auth     => $auth,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );

    like( Developer::Dashboard::Web::App::_highlight_js_text( undef, q{const value = "x"; // note} ), qr/tok-js/, 'web app JS highlighter marks JavaScript keywords' );
    like( Developer::Dashboard::Web::App::_highlight_js_text( undef, q{const value = 'x';} ), qr/tok-string/, 'web app JS highlighter marks single-quoted JavaScript strings' );
    like( Developer::Dashboard::Web::App::_highlight_css_text( undef, q{body { color: red; }} ), qr/tok-css|tok-attr|tok-value/, 'web app CSS highlighter supports direct package-style calls' );
    like( Developer::Dashboard::Web::App::_highlight_css_text( undef, q{/* note */ body { color: red; }} ), qr/tok-comment/, 'web app CSS highlighter marks CSS comments' );
    like( Developer::Dashboard::Web::App::_highlight_perl_text( undef, q{my $value = 1;} ), qr/tok-perl-keyword/, 'web app Perl highlighter supports direct package-style calls' );
    like( Developer::Dashboard::Web::App::_highlight_perl_text( undef, q{my $value = 'x';} ), qr/tok-string/, 'web app Perl highlighter marks single-quoted Perl strings' );
    like( Developer::Dashboard::Web::App::_highlight_perl_text( undef, q{[% stash.name %] my @items = (); my %lookup = ();} ), qr/tok-note.*tok-perl-var/s, 'web app Perl highlighter marks TT notes and array/hash variables' );
    is( Developer::Dashboard::Web::App::_highlight_restore_tokens( undef, 'plain text', undef ), 'plain text', 'web app restore helper leaves plain text untouched when no tokens were stored' );
    like(
        $app->_highlight_perl_text(q{my $value = 1; # trailing comment}),
        qr/tok-comment/,
        'web app Perl highlighter marks trailing comments inside CODE sections',
    );
    like(
        $app->_highlight_html_text( q{const value = "x";</script><div>next</div>}, { html_mode => 'script' } ),
        qr/tok-js.*tok-tag/s,
        'web app HTML highlighter closes script mode and resumes markup highlighting',
    );
    like(
        $app->_highlight_html_text( q{body { color: red; }}, { html_mode => 'style' } ),
        qr/tok-css|tok-attr|tok-value/,
        'web app HTML highlighter keeps CSS highlighting active when style mode continues onto the next line',
    );
    like(
        $app->_highlight_html_text( q{const value = "x";}, { html_mode => 'script' } ),
        qr/tok-js/,
        'web app HTML highlighter handles script mode lines without closing tags',
    );
    like(
        $app->_highlight_tag_markup( '&lt;', 'div', q{ style=&quot;color:red&quot; onclick=&quot;go()&quot; data-id=&quot;1&quot;}, '&gt;' ),
        qr/tok-value tok-css.*tok-value tok-js.*tok-value/s,
        'web app tag highlighter classifies style, JS, and generic attribute values',
    );
    like(
        $app->_highlight_instruction_html(<<'SOURCE'),
HTML: <style>
body { color: red; }
</style>
NOTE: [% stash.name %]
CODE1: my $value = 1;
SOURCE
        qr/tok-directive.*tok-css.*tok-note.*tok-perl-keyword/s,
        'web app instruction highlighter covers HTML, note, and code sections from one source block',
    );
    {
        my %state = ( section => 'NOTE', html_mode => '' );
        like(
            $app->_highlight_editor_line('still [% stash.name %]', \%state),
            qr/tok-note/,
            'web app editor-line highlighter preserves TT note highlighting on section continuation lines',
        );
    }
    {
        my %state = ( section => '', html_mode => '' );
        like(
            $app->_highlight_editor_line(':--------------------------------------------------------------------------------:', \%state),
            qr/tok-separator/,
            'web app editor-line highlighter marks separator rows explicitly',
        );
    }
    {
        my %state = ( section => '', html_mode => '' );
        like(
            $app->_highlight_editor_line('HTML: plain text', \%state),
            qr/tok-directive/,
            'web app editor-line highlighter marks directive prefixes explicitly',
        );
        is( $state{section}, 'HTML', 'web app editor-line highlighter updates section tracking from directives' );
    }
    is(
        $app->_highlight_section_text( '<plain>', { section => 'FORM', html_mode => 'style' } ),
        '&lt;plain&gt;',
        'web app section highlighter treats removed FORM sections as plain escaped text',
    );
    like(
        $app->_highlight_section_text( '[% stash.name %]', { section => 'NOTE', html_mode => '' } ),
        qr/tok-note/,
        'web app section highlighter routes note sections through the note highlighter',
    );
    is(
        $app->_highlight_section_text( '<plain>', { section => 'TITLE', html_mode => '' } ),
        '&lt;plain&gt;',
        'web app section highlighter falls back to escaped plain text for non-code non-HTML sections',
    );
    like(
        $app->_highlight_html_text( q{body { color: red; }</style><div>next</div>}, { html_mode => 'style' } ),
        qr/tok-attr|tok-value.*tok-tag/s,
        'web app HTML highlighter closes style mode and resumes markup highlighting',
    );
    like(
        $app->_highlight_html_text( q{before<style>body { color: red; }</style>after}, { html_mode => '' } ),
        qr/tok-tag.*tok-css/s,
        'web app HTML highlighter enters style mode when a style tag opens on the current line',
    );

    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub {
        my ($name) = @_;
        return $name eq 'ifconfig' ? '/tmp/fake-ifconfig' : undef;
    };
    local *Developer::Dashboard::Web::App::capture = sub (&) {
        my ($code) = @_;
        my $stdout = "wg0: flags\n    inet 10.8.0.2\neth0: flags\n    inet 192.168.1.9\n";
        my $exit = 0;
        return ( $stdout, '', $exit );
    };
    my @ifconfig_pairs = $app->_ip_pairs_from_ifconfig;
    is_deeply(
        \@ifconfig_pairs,
        [
            { iface => 'wg0',  ip => '10.8.0.2' },
            { iface => 'eth0', ip => '192.168.1.9' },
        ],
        'web app parses ifconfig fallback output',
    );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::_ip_interface_pairs = sub {
            return (
                { iface => 'wg0',  ip => '10.8.0.2' },
                { iface => 'eth0', ip => '192.168.1.9' },
                { iface => 'lo',   ip => '127.0.0.1' },
                { iface => 'eth0', ip => '192.168.1.9' },
            );
        };
        is_deeply(
            [ $app->_ip_candidates ],
            [ '10.8.0.2', '192.168.1.9', '127.0.0.1' ],
            'web app orders VPN, preferred, and other IPv4 candidates while removing duplicates',
        );
    }

    my $transient_action_page = Developer::Dashboard::PageDocument->new(
        title       => 'Transient Action',
        state       => { value => 'hello' },
        actions     => [ { id => 'page-state', kind => 'builtin', builtin => 'page.state' } ],
        permissions => { allow_untrusted_actions => 1 },
    );
    my $token = $store->encode_page($transient_action_page);
    my ( $blocked_status, $blocked_type, $blocked_body ) = @{ $app->handle(
        path        => '/action',
        method      => 'POST',
        query       => '',
        body        => 'token=' . uri_escape($token) . '&id=page-state',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $blocked_status, 403, 'transient action fallback route is denied by default' );
    like( $blocked_type, qr/text\/plain/, 'transient action fallback denial returns plain-text content type' );
    like( $blocked_body, qr/Transient token URLs are disabled/, 'transient action fallback denial explains the policy' );

    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    my ( $status, $type, $body ) = @{ $app->handle(
        path        => '/action',
        method      => 'POST',
        query       => '',
        body        => 'token=' . uri_escape($token) . '&id=page-state',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $status, 404, 'transient action fallback route executes and rejects missing serialized actions cleanly' );
    like( $type, qr/text\/plain/, 'transient action fallback returns plain-text error content type when the action is absent' );
    like( $body, qr/Action not found/, 'transient action fallback reports missing transient action ids cleanly' );

    my $body_app = Developer::Dashboard::Web::App->new(
        actions  => bless( {}, 'Local::BodyActionRunner' ),
        auth     => $auth,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );
    my $saved_action_page = Developer::Dashboard::PageDocument->new(
        id      => 'body-action',
        title   => 'Body Action',
        actions => [ { id => 'download', kind => 'builtin', builtin => 'page.state' } ],
    );
    my $response = $body_app->_action_response(
        id     => 'download',
        page   => $saved_action_page,
        source => 'saved',
        params => {},
    );
    is( $response->[0], 200, 'web app action response returns success for explicit body payloads' );
    is( $response->[1], 'text/plain; charset=utf-8', 'web app action response uses explicit body content type defaults' );
    is( $response->[2], 'body-payload', 'web app action response returns raw body payloads' );

    {
        my $render_page = Developer::Dashboard::PageDocument->new(
            id      => 'render-cover',
            title   => 'Render Cover',
            layout  => { body => '<div>render body</div>' },
            actions => [ undef, { builtin => 'missing-id' }, { id => 'download', builtin => 'page.state' } ],
        );
        $render_page->{meta}{source_kind} = 'saved';
        my $html = $body_app->_render_page_html( $render_page, 'render' );
        like( $html, qr/render body/, 'web app render helper still renders page bodies when invalid actions are skipped' );
        like( $html, qr/view-source-url/, 'web app render helper still renders the shared chrome after skipping invalid action rows' );
    }

    $indicator_store->set_indicator(
        'docker',
        label          => 'Docker',
        alias          => '&#x1F433;',
        status         => 'ok',
        prompt_visible => 1,
    );
    is( $app->_prompt_summary, '&#x2705;&#x1F433;', 'web app top status summary renders indicator status and alias pairs' );
    like(
        $app->_top_chrome_html(
            Developer::Dashboard::PageDocument->new( id => 'coverage-top', layout => { body => 'Body' } ),
            { edit => '/app/coverage-top/edit', render => '/app/coverage-top', source => '/app/coverage-top/source' },
        ),
        qr/Segoe UI Emoji.*Noto Color Emoji/s,
        'web app top chrome uses an emoji-capable font stack for the browser status strip',
    );
}

{
    my $error_icon = $indicator_store->_page_status_icon( { status => 'error' } );
    is( $error_icon, '&#x1F6A8;', 'indicator store resolves explicit error icon mappings' );
    is( $indicator_store->prompt_status_icon( { status => 'ok' } ), '✅', 'indicator store resolves prompt success glyphs' );
    my $fallback_icon = $indicator_store->_page_status_icon( { status => 'unknown', icon => 'X' } );
    is( $fallback_icon, 'X', 'indicator store falls back to explicit icon when no mapping exists' );
}

done_testing;

{
    package Local::BodyActionRunner;
    # run_page_action(%args)
    # Returns a direct body payload for Web::App action response coverage.
    # Input: ignored.
    # Output: hash reference with body and content_type.
    sub run_page_action { return { body => 'body-payload' } }

    # encode_action_payload(%args)
    # Returns a stable fake encoded action token for render-link coverage.
    # Input: ignored.
    # Output: string token.
    sub encode_action_payload { return 'encoded-action-token' }
}

__END__

=head1 NAME

14-coverage-closure-extra.t - targeted coverage closure tests for remaining runtime branches

=head1 DESCRIPTION

This test exercises migration, fallback, private helper, and managed-child
paths that are difficult to reach from the higher-level CLI and browser flows.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the hard-to-hit branches that keep library coverage honest. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the hard-to-hit branches that keep library coverage honest has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the hard-to-hit branches that keep library coverage honest, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/14-coverage-closure-extra.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/14-coverage-closure-extra.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/14-coverage-closure-extra.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
