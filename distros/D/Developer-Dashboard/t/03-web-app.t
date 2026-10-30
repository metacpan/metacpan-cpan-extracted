use strict;
use warnings;
use utf8;

use Encode qw(decode);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use IO::Socket::INET;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Errno qw(EACCES EIO ENOTDIR);
use URI::Escape qw(uri_escape);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Codec qw(encode_payload);
use Developer::Dashboard::Config;
use Developer::Dashboard::IndicatorStore::Watch;
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

sub drain_stream_body {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $output = '';
    $body->{stream}->( sub { $output .= $_[0] if defined $_[0] } );
    return $output;
}

# decoded_attr_value($value)
# Decodes one HTML attribute value the way a browser does before use.
# URLs in attributes are HTML-escaped, so a query separator is markup-legal
# only as &amp;; a browser resolves the entities when it reads the attribute,
# and a scrape that feeds the value back into the app must do the same.
# Input: raw attribute text captured from the response body.
# Output: decoded attribute value.
sub decoded_attr_value {
    my ($value) = @_;
    return $value if !defined $value;
    $value =~ s/&lt;/</g;
    $value =~ s/&gt;/>/g;
    $value =~ s/&quot;/"/g;
    $value =~ s/&#39;/'/g;
    $value =~ s/&amp;/&/g;
    return $value;
}

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
my $repo_root = File::Spec->rel2abs('.');
my $repo_lib = File::Spec->catdir( $repo_root, 'lib' );
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";
my $dashboard_bin = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my ( $seed_init_stdout, $seed_init_stderr, $seed_init_exit ) = capture {
    system( $^X, "-I$repo_lib", $dashboard_bin, 'init' );
};
is( $seed_init_exit, 0, 'dashboard init exits cleanly for web app fixture setup' );
is( $seed_init_stderr, '', 'dashboard init does not emit stderr for web app fixture setup' );

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::PageStore->new(paths => $paths);
my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new(paths => $paths);
my $auth = Developer::Dashboard::Auth->new(
    files => $files,
    paths => $paths,
);
my $sessions = Developer::Dashboard::SessionStore->new(paths => $paths);
my $runtime = Developer::Dashboard::PageRuntime->new(paths => $paths);
my $prompt = Developer::Dashboard::Prompt->new(
    paths      => $paths,
    indicators => $indicators,
);
my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);
{
    my $trim_calls = 0;
    my $original_trim = \&Developer::Dashboard::Web::App::_trim;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_trim = sub {
        $trim_calls++;
        return $original_trim->(@_);
    };

    is( $app->_normalized_saved_page_id('welcome'), 'welcome',
        'canonical saved-page ids are preserved' );
    is( $trim_calls, 0,
        'canonical saved-page ids bypass trim and prefix normalization work' );
    is( $app->_normalized_saved_page_id('team-status_2.json'), 'team-status_2.json',
        'canonical ids with the full supported ASCII filename alphabet are preserved' );
    is( $trim_calls, 0,
        'supported canonical ASCII ids all use the direct return path' );
    is( $app->_normalized_saved_page_id(' /app//welcome/ '), 'welcome/',
        'noncanonical saved-page ids retain whitespace and /app/ normalization' );
    is( $trim_calls, 1,
        'noncanonical saved-page ids continue through the established trim helper' );
    is( $app->_normalized_saved_page_id('welcome/nested'), 'welcome/nested',
        'nested ids remain unchanged by the general normalization path' );
    is( $trim_calls, 2,
        'nested ids do not enter the canonical flat-id fast path' );
    is( $app->_normalized_saved_page_id("\x{00e9}quipe"), "\x{00e9}quipe",
        'Unicode ids retain their established normalization behavior' );
    is( $trim_calls, 3,
        'Unicode ids continue through the established trim helper' );
    my $undefined_id;
    is( $app->_normalized_saved_page_id($undefined_id), '',
        'undefined saved-page ids retain the established empty-string normalization' );
    is( $trim_calls, 4,
        'undefined ids take the general normalization path' );
    my $reference_id = {};
    is( $app->_normalized_saved_page_id($reference_id), "$reference_id",
        'reference saved-page ids retain their established string normalization' );
    is( $trim_calls, 5,
        'reference ids take the general normalization path' );
}
{
    my $saved_nav_root = File::Spec->catdir( $paths->dashboards_root, 'nav' );
    make_path($saved_nav_root);
    my $saved_nav_file = File::Spec->catfile( $saved_nav_root, 'snapshot.tt' );
    open my $saved_nav_fh, '>:raw', $saved_nav_file or die "Unable to create saved nav fixture '$saved_nav_file': $!";
    print {$saved_nav_fh} '<span>saved-nav-first</span>'
      or die "Unable to write saved nav fixture '$saved_nav_file': $!";
    close $saved_nav_fh or die "Unable to close saved nav fixture '$saved_nav_file': $!";

    my $saved_nav_watch = Local::Problem48ConfigSnapshotWatch->new;
    my $saved_nav_reads = 0;
    my $saved_nav_loads = 0;
    my $saved_nav_inventory_scans = 0;
    my $original_read = Developer::Dashboard::PageStore->can('_read_saved_instruction');
    my $original_nav_load = Developer::Dashboard::PageStore->can('load_nav_fragment');
    my $original_nav_inventory = Developer::Dashboard::Web::App->can('_nav_ids_for_roots');
    my $saved_nav_app = Developer::Dashboard::Web::App->new(
        auth => $auth, config => $config, pages => $store, prompt => $prompt,
        runtime => $runtime, sessions => $sessions,
    );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $saved_nav_watch };
        local *Developer::Dashboard::Web::App::_skill_dispatcher = sub {
            return bless {}, 'Local::Problem48EmptySkillDispatcher';
        };
        local *Developer::Dashboard::PageStore::_read_saved_instruction = sub {
            $saved_nav_reads++;
            return $original_read->(@_);
        };
        local *Developer::Dashboard::PageStore::load_nav_fragment = sub {
            $saved_nav_loads++;
            return $original_nav_load->(@_);
        };
        local *Developer::Dashboard::Web::App::_nav_ids_for_roots = sub {
            $saved_nav_inventory_scans++;
            return $original_nav_inventory->(@_);
        };

        my $nav_page = Developer::Dashboard::PageDocument->new( id => 'welcome' );
        my $first_html = $saved_nav_app->_nav_items_html( page => $nav_page, runtime_context => {} );
        is(
            $first_html,
            '<section class="dashboard-nav-items"><ul><li data-nav-id="nav/snapshot.tt"><span>saved-nav-first</span></li></ul></section>',
            'saved and skill navigation keeps the exact ordered section markup'
        );
        is(
            $saved_nav_app->{_saved_nav_items_snapshot}{html},
            '<li data-nav-id="nav/snapshot.tt"><span>saved-nav-first</span></li>',
            'saved navigation cache retains the exact fragment list without a wrapper'
        );
        like( $first_html, qr/saved-nav-first/, 'first saved-nav request renders its literal fragment' );
        is( $saved_nav_reads, 1, 'first saved-nav request reads the fragment through the secure page store' );
        is( $saved_nav_loads, 1, 'first saved-nav request resolves the fragment through the page store' );
        is( $saved_nav_inventory_scans, 1, 'first saved-nav request inventories the layered nav roots' );
        my $cached_html = $saved_nav_app->_nav_items_html( page => $nav_page, runtime_context => {} );
        is( $cached_html, $first_html, 'unchanged saved-nav snapshot keeps exact rendered markup' );
        is( $saved_nav_reads, 1, 'unchanged watcher snapshot skips repeated saved-nav file resolution and reads' );
        is( $saved_nav_loads, 1, 'unchanged watcher snapshot skips repeated PageStore nav resolution' );
        is( $saved_nav_inventory_scans, 1, 'unchanged watcher snapshot skips repeated layered nav inventory' );

        open $saved_nav_fh, '>:raw', $saved_nav_file or die "Unable to update saved nav fixture '$saved_nav_file': $!";
        print {$saved_nav_fh} '<span>saved-nav-second</span>'
          or die "Unable to update saved nav fixture '$saved_nav_file': $!";
        close $saved_nav_fh or die "Unable to close updated saved nav fixture '$saved_nav_file': $!";
        $saved_nav_watch->invalidate;
        my $updated_html = $saved_nav_app->_nav_items_html( page => $nav_page, runtime_context => {} );
        like( $updated_html, qr/saved-nav-second/, 'saved-nav watcher event reloads an edited fragment' );
        unlike( $updated_html, qr/saved-nav-first/, 'saved-nav watcher event removes the prior fragment body' );
        is( $saved_nav_reads, 2, 'one saved-nav invalidation causes one secure fragment reread' );
        is( $saved_nav_loads, 2, 'one saved-nav invalidation reloads the affected nav file once' );
        is( $saved_nav_inventory_scans, 2, 'one saved-nav invalidation refreshes the nav inventory once' );

        my $added_nav_file = File::Spec->catfile( $saved_nav_root, 'added.tt' );
        open $saved_nav_fh, '>:raw', $added_nav_file or die "Unable to create added saved nav fixture '$added_nav_file': $!";
        print {$saved_nav_fh} '<span>saved-nav-added</span>'
          or die "Unable to write added saved nav fixture '$added_nav_file': $!";
        close $saved_nav_fh or die "Unable to close added saved nav fixture '$added_nav_file': $!";
        $saved_nav_watch->invalidate;
        my $added_html = $saved_nav_app->_nav_items_html( page => $nav_page, runtime_context => {} );
        like( $added_html, qr/saved-nav-added/, 'saved-nav watcher event discovers a newly added fragment' );

    }
    ok( grep( { $_ eq $saved_nav_root } @{ $saved_nav_watch->{paths} } ),
        'saved-nav watcher includes the direct directory that receives fragment writes' );
    undef $saved_nav_app;
    is( $saved_nav_watch->{closed}, 1, 'web app destruction closes its saved-nav watcher' );
    unlink $saved_nav_file or die "Unable to remove saved nav fixture '$saved_nav_file': $!";
    unlink File::Spec->catfile( $saved_nav_root, 'added.tt' )
      or die "Unable to remove added saved nav fixture: $!";
}
{
    my $active_template_scope;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::Web::App::_handle_request = sub {
            $active_template_scope = $_[0]{runtime}{_template_processor_scope};
            return [ 200, 'text/plain', 'request scope observed' ];
        };
        my $response = $app->_handle_request_with_template_scope;
        is( $response->[0], 200, 'template scope wrapper returns the request response' );
        is( ref($active_template_scope), 'HASH', 'a real PageRuntime receives a request-local template scope' );
        ok( !exists $runtime->{_template_processor_scope}, 'template scope is discarded after the request' );

        my ( $active_path_identity_scope, $active_layer_scope );
        {
            no warnings qw(redefine once);
            local *Developer::Dashboard::Web::App::_handle_request = sub {
                my ($request_app) = @_;
                $active_path_identity_scope = $request_app->{pages}{paths}{_path_identity_scope};
                $active_layer_scope = $request_app->{pages}{paths}{_runtime_layer_candidate_scope};
                return [ 200, 'text/plain', 'request scope observed' ];
            };
            my $scoped_response = $app->handle;
            is( $scoped_response->[0], 200, 'handle returns the scoped request response' );
            is( ref($active_path_identity_scope), 'HASH', 'a real request receives a path identity scope' );
            is( ref($active_layer_scope), 'HASH', 'path identity scope accompanies the runtime-layer scope' );
            ok( !exists $paths->{_path_identity_scope}, 'path identity scope is discarded after the request' );
        }

        local $app->{runtime} = {};
        my $fallback_response = $app->_handle_request_with_template_scope;
        is( $fallback_response->[0], 200, 'non-PageRuntime providers still dispatch the request' );

        my $other_runtime = bless {}, 'Local::Problem48OtherRuntime';
        local $app->{runtime} = $other_runtime;
        my $non_page_runtime_response = $app->_handle_request_with_template_scope;
        is( $non_page_runtime_response->[0], 200, 'blessed non-PageRuntime providers still dispatch the request' );

        my $observed_runtime_layer_scope = 'not observed';
        local *Developer::Dashboard::Web::App::_handle_request = sub {
            my ($request_app) = @_;
            $observed_runtime_layer_scope = exists $request_app->{pages}{paths}{_runtime_layer_candidate_scope} ? 1 : 0;
            return [ 200, 'text/plain', 'handle fallback observed' ];
        };
        local $store->{paths} = {};
        my $non_registry_paths_response = $app->handle(path => '/test');
        is( $non_registry_paths_response->[0], 200, 'PageStore with non-PathRegistry paths still dispatches' );
        is( $observed_runtime_layer_scope, 0, 'non-PathRegistry paths do not receive a registry request scope' );

        local $app->{pages} = {};
        my $non_page_store_response = $app->handle(path => '/test');
        is( $non_page_store_response->[0], 200, 'non-PageStore providers still dispatch through handle' );
    }
}
{
    local $app->{config} = {};
    is_deeply( $app->_web_settings, {}, '_web_settings returns an empty view for a non-object config' );
    local $app->{_request_config_snapshot};
    is( $app->_request_config_snapshot, undef, '_request_config_snapshot skips a non-object config' );
}
{
    local $app->{config} = $paths;
    is_deeply( $app->_web_settings, {}, '_web_settings returns an empty view when the config has no web accessor' );
    local $app->{_request_config_snapshot};
    is( $app->_request_config_snapshot, undef, '_request_config_snapshot skips a config without merged()' );
}
{
    no warnings 'redefine';
    *Developer::Dashboard::Web::App::_machine_ip = sub { '10.20.30.40' };
}

my $page = Developer::Dashboard::PageDocument->new(
    id     => 'welcome',
    title  => 'Welcome',
    layout => { body => 'hello from app [% stash.name %]' },
    meta   => { head => '<meta name="x-bookmark" content="head-injected">' },
);
$store->save_page($page);

my $web_settings_calls = 0;
my $merged_config_calls = 0;
my $runtime_layer_discovery_calls = 0;
my $original_web_settings = Developer::Dashboard::Config->can('web_settings');
my $original_merged_config = Developer::Dashboard::Config->can('merged');
my $original_runtime_layer_discovery = Developer::Dashboard::PathRegistry->can('_ancestor_runtime_layers_for_scope');
my ( $cached_settings_status, $cached_settings_type, $cached_settings_body );
my ( $fresh_settings_status, $fresh_settings_type, $fresh_settings_body );
{
    no warnings 'redefine';
    local *Developer::Dashboard::Config::web_settings = sub {
        $web_settings_calls++;
        return $original_web_settings->(@_);
    };
    local *Developer::Dashboard::Config::merged = sub {
        $merged_config_calls++;
        return $original_merged_config->(@_);
    };
    local *Developer::Dashboard::PathRegistry::_ancestor_runtime_layers_for_scope = sub {
        $runtime_layer_discovery_calls++;
        return $original_runtime_layer_discovery->(@_);
    };
    ( $cached_settings_status, $cached_settings_type, $cached_settings_body ) = @{ $app->handle(
        path        => '/app/welcome',
        query       => '',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $web_settings_calls, 1, 'one request resolves web settings once across authorization and page chrome' );
    is( $merged_config_calls, 1, 'web settings and status collectors share one merged config per request' );
    cmp_ok( $runtime_layer_discovery_calls, '<=', 2, 'one request bounds runtime-layer ancestry scans despite nested permission checks' );
    $web_settings_calls = 0;
    $merged_config_calls = 0;
    $runtime_layer_discovery_calls = 0;
    $config->save_global_web_settings( no_editor => 1 );
    ( $fresh_settings_status, $fresh_settings_type, $fresh_settings_body ) = @{ $app->handle(
        path        => '/app/welcome/edit',
        query       => '',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    $config->save_global_web_settings( no_editor => 0 );
    is( $web_settings_calls, 1, 'a later request resolves its own fresh web settings snapshot' );
    is( $merged_config_calls, 1, 'a later request does not reuse the previous merged config snapshot' );
}
is( $cached_settings_status, 200, 'saved page renders while request settings are observed' );
is( $fresh_settings_status, 403, 'the next request observes a changed no-editor setting' );
like( $fresh_settings_body, qr/read-only no-editor mode/, 'the fresh request uses the changed setting in its denial response' );

{
    my $cache_app = Developer::Dashboard::Web::App->new(
        auth     => $auth,
        config   => $config,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );
    my $fake_watch = Local::Problem48ConfigSnapshotWatch->new;
    my $merged_calls = 0;
    my $indicator_collector_calls = 0;
    my $watch_creations = 0;
    my $original_merged = Developer::Dashboard::Config->can('merged');
    my $original_indicator_collectors = Developer::Dashboard::Config->can('indicator_collectors');
    my $watch_config_file = File::Spec->catfile( $paths->config_root, 'config.json' );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            $watch_creations++;
            return $watch_creations == 1 ? $fake_watch : Local::Problem48ConfigSnapshotWatch->new;
        };
        local *Developer::Dashboard::Config::merged = sub {
            $merged_calls++;
            return $original_merged->(@_);
        };
        local *Developer::Dashboard::Config::indicator_collectors = sub {
            $indicator_collector_calls++;
            return $original_indicator_collectors->(@_);
        };
        my $first = $cache_app->handle(
            path        => '/app/welcome',
            query       => '',
            remote_addr => '127.0.0.1',
            headers     => { host => '127.0.0.1' },
        );
        is( $first->[0], 200, 'the first configured request builds the shared snapshot' );
        is( $merged_calls, 1, 'the first request reads merged config once' );
        ok( ( grep { $_ eq $paths->config_root } @{ $fake_watch->{paths} } ),
            'the snapshot watcher includes the active global config directory' );
        my $watch_paths = $cache_app->_config_snapshot_watch_paths;
        ok( !( grep { $_ eq File::Spec->rootdir || $_ eq File::Spec->tmpdir } @{$watch_paths} ),
            'the snapshot watcher excludes unrelated filesystem ancestors above the home layer' );

        my $second = $cache_app->handle(
            path        => '/app/welcome',
            query       => '',
            remote_addr => '127.0.0.1',
            headers     => { host => '127.0.0.1' },
        );
        is( $second->[0], 200, 'an unchanged watched request still renders successfully' );
        is( $merged_calls, 1, 'an event-free watcher reuses merged config across requests' );
        is( $indicator_collector_calls, 1,
            'an unchanged watched snapshot reuses its indicator collector projection across requests' );

        $config->save_global_web_settings( no_editor => 1 );
        $fake_watch->invalidate;
        my $changed = $cache_app->handle(
            path        => '/app/welcome/edit',
            query       => '',
            remote_addr => '127.0.0.1',
            headers     => { host => '127.0.0.1' },
        );
        is( $changed->[0], 403, 'a config-directory event invalidates the cached web settings' );
        is( $merged_calls, 2, 'an invalidated snapshot is rebuilt exactly once' );

        $config->save_global_web_settings( no_editor => 0 );
        $fake_watch->invalidate;
        my $restored = $cache_app->handle(
            path        => '/app/welcome',
            query       => '',
            remote_addr => '127.0.0.1',
            headers     => { host => '127.0.0.1' },
        );
        is( $restored->[0], 200, 'a later config event is visible after the cache has been refreshed' );
        is( $merged_calls, 3, 'each invalidation performs one fresh merge' );
    }
}

{
    my $signature_app = bless { pages => $store }, 'Developer::Dashboard::Web::App';
    my $before = $signature_app->_config_snapshot_environment_signature;
    like( $before, qr/\ADASHBOARD_CONFIG_SNAPSHOT\0v1\0/, 'snapshot environment signature uses versioned unambiguous framing' );
    {
        local $ENV{DEVELOPER_DASHBOARD_CHECKERS} = 'problem48-filter-change';
        isnt(
            $signature_app->_config_snapshot_environment_signature,
            $before,
            'changing the checker filter changes the reusable config snapshot environment signature',
        );
    }

    my $absent_filter;
    {
        local %ENV = %ENV;
        delete $ENV{DEVELOPER_DASHBOARD_CHECKERS};
        $absent_filter = $signature_app->_config_snapshot_environment_signature;
    }
    my $empty_filter;
    {
        local %ENV = %ENV;
        $ENV{DEVELOPER_DASHBOARD_CHECKERS} = '';
        $empty_filter = $signature_app->_config_snapshot_environment_signature;
    }
    isnt( $absent_filter, $empty_filter, 'missing and explicitly empty environment selectors have distinct signatures' );

    my $delimited_filter;
    {
        local %ENV = %ENV;
        $ENV{DEVELOPER_DASHBOARD_CHECKERS} = "value:with;signature\\0markers";
        $delimited_filter = $signature_app->_config_snapshot_environment_signature;
    }
    isnt( $delimited_filter, $empty_filter, 'length-prefixed values preserve arbitrary delimiter characters' );
}

{
    my $root = tempdir( CLEANUP => 1 );
    my $config_file = File::Spec->catfile( $root, 'config.json' );
    open my $fh, '>:raw', $config_file or die "Unable to create portable snapshot fixture '$config_file': $!\n";
    print {$fh} '{"value":"a"}';
    close $fh or die "Unable to close portable snapshot fixture '$config_file': $!\n";
    my $portable_config = bless {
        paths => bless({ skills => [] }, 'Local::Problem48PortablePaths'),
        file  => $config_file,
    }, 'Local::Problem48PortableConfig';
    my $portable_app = bless {
        config                    => $portable_config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    my $merge_count = 0;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return undef };
        local *Developer::Dashboard::Web::App::_config_snapshot_environment_signature = sub { return 'portable-test' };
        local *Developer::Dashboard::Web::App::_config_snapshot_watch_paths = sub { return [$root] };
        local *Local::Problem48PortableConfig::merged = sub { return { merged => ++$merge_count } };
        my $get_snapshot = sub {
            local $portable_app->{_request_config_snapshot} = undef;
            return $portable_app->_request_config_snapshot;
        };
        my $first = $get_snapshot->();
        is( $first->{merged_config}{merged}, 1, 'portable snapshot builds its initial merged config' );
        my $second = $get_snapshot->();
        is( $second, $first, 'portable metadata-and-content signature reuses an unchanged snapshot without native events' );
        is( $merge_count, 1, 'portable snapshot cache avoids a repeated merge on non-Linux platforms' );

        open my $changed_fh, '>:raw', $config_file or die "Unable to update portable snapshot fixture '$config_file': $!\n";
        print {$changed_fh} '{"value":"b"}';
        close $changed_fh or die "Unable to close updated portable snapshot fixture '$config_file': $!\n";
        my $third = $get_snapshot->();
        is( $third->{merged_config}{merged}, 2, 'portable content hashing detects same-size in-place config edits' );
        is( $merge_count, 2, 'a portable invalidation performs exactly one fresh config merge' );

        my $skill_root = File::Spec->catdir( $root, 'skill-one' );
        my $skill_config_dir = File::Spec->catdir( $skill_root, 'config' );
        make_path($skill_config_dir);
        push @{ $portable_config->{paths}{skills} }, {
            skill_name => 'skill-one',
            layers     => [$skill_root],
        };
        my $before_add = $portable_app->_config_snapshot_portable_signature( [$root, $skill_config_dir] );
        my $skill_config_file = File::Spec->catfile( $skill_config_dir, 'config.json' );
        open my $skill_fh, '>:raw', $skill_config_file or die "Unable to create skill config fixture '$skill_config_file': $!\n";
        print {$skill_fh} '{"skill":true}';
        close $skill_fh or die "Unable to close skill config fixture '$skill_config_file': $!\n";
        my $after_add = $portable_app->_config_snapshot_portable_signature( [$root, $skill_config_dir] );
        isnt( $after_add, $before_add, 'portable signature detects a newly created skill-layer config file' );
        unlink $skill_config_file or die "Unable to remove skill config fixture '$skill_config_file': $!\n";
        my $after_remove = $portable_app->_config_snapshot_portable_signature( [$root, $skill_config_dir] );
        isnt( $after_remove, $after_add, 'portable signature detects a deleted skill-layer config file' );

        my $project_root = File::Spec->catdir( $root, 'project' );
        make_path($project_root);
        my $repo_config = File::Spec->catfile( $project_root, '.developer-dashboard.json' );
        open my $repo_fh, '>:raw', $repo_config or die "Unable to create project config fixture '$repo_config': $!\n";
        print {$repo_fh} '{}';
        close $repo_fh or die "Unable to close project config fixture '$repo_config': $!\n";
        my $before_project = $portable_app->_config_snapshot_portable_signature( [$root, $project_root] );
        $portable_config->{repo_root} = $project_root;
        my $configured_repo = $portable_app->_config_snapshot_portable_signature( [$root, $project_root] );
        isnt( $configured_repo, $before_project, 'portable signature includes the config loader project-root override' );
        delete $portable_config->{repo_root};
        $portable_config->{paths}{project_root} = $project_root;
        my $path_project = $portable_app->_config_snapshot_portable_signature( [$root, $project_root] );
        is( $path_project, $configured_repo, 'portable signature includes the PathRegistry project root when no loader override exists' );
        $portable_config->{paths}{project_root} = '';
        $portable_config->{repo_root} = '';
        ok( defined $portable_app->_config_snapshot_portable_signature( [$root] ),
            'portable signature tolerates an empty project root without adding a candidate' );
        delete $portable_config->{repo_root};
        delete $portable_config->{paths}{project_root};

        my $invalid_entry_signature;
        {
            no warnings qw(redefine once);
            local *Local::Problem48PortablePaths::installed_skill_entries = sub {
                return ( 'not-an-entry', { layers => 'not-an-array' }, { layers => [] } );
            };
            local *Local::Problem48PortableConfig::_global_config_files = sub {
                return ( undef, [], '', $config_file, $config_file );
            };
            $invalid_entry_signature = $portable_app->_config_snapshot_portable_signature( [$root] );
        }
        ok( defined $invalid_entry_signature, 'portable signature filters malformed config candidates and skill entries' );
        {
            no warnings qw(redefine once);
            local *Local::Problem48PortableConfig::_global_config_files = sub { return ($root) };
            ok( defined $portable_app->_config_snapshot_portable_signature( [$root] ),
                'portable signature accepts a directory-shaped config candidate without hashing it as a file' );
        }

        my $missing_directory_error;
        eval { $portable_app->_config_snapshot_portable_signature( [ File::Spec->catdir( $root, 'missing' ) ] ); 1 }
          or $missing_directory_error = $@;
        like( $missing_directory_error, qr/Unable to inspect config snapshot directory/, 'portable signature reports a missing watched directory' );

        my $nonarray_error;
        eval { $portable_app->_config_snapshot_portable_signature( undef ); 1 } or $nonarray_error = $@;
        like( $nonarray_error, qr/watch paths must be an array reference/, 'portable signature rejects malformed directory inventories' );
        ok(
            !defined $portable_app->_config_snapshot_open( File::Spec->catfile( $root, 'missing-config.json' ) ),
            'raw config open reports an unavailable file without hiding the error state',
        );

        for my $failure (qw(directory_stat file_lstat file_stat file_open file_close)) {
            my $error;
            {
                no warnings qw(redefine once);
                my $expected_file = $config_file;
                local *Developer::Dashboard::Web::App::_config_snapshot_stat = sub {
                    my ( $self, $path ) = @_;
                    return if $failure eq 'directory_stat' && $path eq $root;
                    return if $failure eq 'file_stat' && $path eq $expected_file;
                    return CORE::stat($path);
                };
                local *Developer::Dashboard::Web::App::_config_snapshot_lstat = sub {
                    my ( $self, $path ) = @_;
                    if ( $failure eq 'file_lstat' && $path eq $expected_file ) {
                        $! = EACCES;
                        return;
                    }
                    return CORE::lstat($path);
                };
                local *Developer::Dashboard::Web::App::_config_snapshot_open = sub {
                    my ( $self, $path ) = @_;
                    if ( $failure eq 'file_open' && $path eq $expected_file ) {
                        $! = EACCES;
                        return;
                    }
                    open my $open_fh, '<:raw', $path or return;
                    return $open_fh;
                };
                local *Developer::Dashboard::Web::App::_config_snapshot_close = sub {
                    my ( $self, $close_fh ) = @_;
                    if ( $failure eq 'file_close' ) {
                        CORE::close($close_fh);
                        $! = EIO;
                        return 0;
                    }
                    return CORE::close($close_fh);
                };
                eval { $portable_app->_config_snapshot_portable_signature( [$root] ); 1 }
                  or $error = $@;
            }
            like( $error, qr/Unable to .*config snapshot/, "portable signature reports the $failure filesystem failure" );
        }

        {
            no warnings qw(redefine once);
            local *Developer::Dashboard::Web::App::_config_snapshot_lstat = sub {
                my ( $self, $path ) = @_;
                if ( $path eq $config_file ) {
                    $! = ENOTDIR;
                    return;
                }
                return CORE::lstat($path);
            };
            ok(
                defined $portable_app->_config_snapshot_portable_signature( [$root] ),
                'portable signature treats an ENOTDIR config candidate as absent and continues',
            );
        }

        my $missing_config_methods = bless {
            paths => bless( {}, 'Local::Problem48NoPathMethods' ),
        }, 'Local::Problem48NoConfigMethods';
        my $bare_config_app = bless { config => $missing_config_methods }, 'Developer::Dashboard::Web::App';
        ok( defined $bare_config_app->_config_snapshot_portable_signature( [$root] ),
            'portable signature supports config objects without optional path/config accessors' );
        my $unblessed_config_app = bless { config => {} }, 'Developer::Dashboard::Web::App';
        ok( defined $unblessed_config_app->_config_snapshot_portable_signature( [$root] ),
            'portable signature supports an unblessed config provider' );
    }
}

{
    my $root = tempdir( CLEANUP => 1 );
    my $config_file = File::Spec->catfile( $root, 'config.json' );
    open my $fh, '>:raw', $config_file or die "Unable to create shared-inventory config '$config_file': $!\n";
    print {$fh} '{"value":"portable"}';
    close $fh or die "Unable to close shared-inventory config '$config_file': $!\n";
    my $skill_root = File::Spec->catdir( $root, 'skills', 'problem48-skill' );
    my $skill_config_dir = File::Spec->catdir( $skill_root, 'config' );
    make_path($skill_config_dir);
    my $skill_config_file = File::Spec->catfile( $skill_config_dir, 'config.json' );
    open my $skill_fh, '>:raw', $skill_config_file or die "Unable to create shared-inventory skill config '$skill_config_file': $!\n";
    print {$skill_fh} '{"skill":"portable"}';
    close $skill_fh or die "Unable to close shared-inventory skill config '$skill_config_file': $!\n";
    my $layer_paths = bless {
        runtime_roots => [$root],
        config_roots  => [],
        skills_roots  => [],
        installed     => [ { layers => [$skill_root] } ],
        nested        => [],
    }, 'Local::Problem48SkillEntryPaths';
    my $portable_config = bless { paths => $layer_paths, file => $config_file }, 'Local::Problem48PortableConfig';
    my $portable_app = bless {
        config                   => $portable_config,
        pages                    => $layer_paths,
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    my $installed_skill_lookups = 0;
    my $original_skill_entries = Local::Problem48SkillEntryPaths->can('installed_skill_entries');
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return undef };
        local *Developer::Dashboard::Web::App::_config_snapshot_environment_signature = sub { return 'shared-inventory' };
        local *Local::Problem48SkillEntryPaths::installed_skill_entries = sub {
            $installed_skill_lookups++;
            return $original_skill_entries->(@_);
        };
        local *Local::Problem48PortableConfig::merged = sub { return { merged => 1 } };
        {
            local $portable_app->{_request_config_snapshot} = undef;
            $portable_app->_request_config_snapshot;
        }
        is( $installed_skill_lookups, 2,
            'portable config snapshot shares each discovered skill inventory between watch paths and file signature' );
        {
            local $portable_app->{_request_config_snapshot} = undef;
            $portable_app->_request_config_snapshot;
        }
        is( $installed_skill_lookups, 3,
            'each later portable cache hit performs one fresh skill-layer discovery to preserve filesystem freshness' );
        my $bad_skill_entries_error;
        eval { $portable_app->_config_snapshot_portable_signature( [], {} ); 1 }
          or $bad_skill_entries_error = $@;
        like( $bad_skill_entries_error, qr/skill entries must be an array reference/,
            'portable signatures reject malformed shared skill inventories' );
        my $bad_skill_output_error;
        eval { $portable_app->_config_snapshot_watch_paths({}); 1 }
          or $bad_skill_output_error = $@;
        like( $bad_skill_output_error, qr/skill-entry output must be an array reference/,
            'watch-path discovery rejects malformed skill-inventory output targets' );
        ok(
            defined $portable_app->_config_snapshot_portable_signature(
                [$root], [ 'malformed-skill-entry', { layers => 'not-an-array' } ]
            ),
            'portable signature skips malformed shared skill entries without losing file freshness checks',
        );
    }
}

{
    my $native_watcher = Developer::Dashboard::IndicatorStore::Watch->new;
    SKIP: {
        skip 'native filesystem watcher is unavailable on this platform', 3 if !$native_watcher;
        my $config_override = $paths->config_root;
        local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $config_override;
        my $native_cache_app = Developer::Dashboard::Web::App->new(
            auth     => $auth,
            config   => $config,
            pages    => $store,
            prompt   => $prompt,
            runtime  => $runtime,
            sessions => $sessions,
        );
        my $merged_calls = 0;
        my $original_merged = Developer::Dashboard::Config->can('merged');
        {
            no warnings 'redefine';
            local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $native_watcher };
            local *Developer::Dashboard::Config::merged = sub {
                $merged_calls++;
                return $original_merged->(@_);
            };
            for my $request_number ( 1 .. 2 ) {
                my $response = $native_cache_app->handle(
                    path        => '/system/status',
                    query       => '',
                    remote_addr => '127.0.0.1',
                    headers     => { host => '127.0.0.1' },
                );
                is( $response->[0], 200, "native watcher status request $request_number succeeds" );
            }
            is( $merged_calls, 1,
                'native watcher reuses config when repeated configured-root resolution is part of the request' );
        }
    }
}

{
    my $merged_config = bless {}, 'Local::Problem48MergedConfig';
    my $snapshot_app = bless {
        config                    => $merged_config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    my $merge_count = 0;
    {
        no warnings 'redefine';
        local *Local::Problem48MergedConfig::merged = sub {
            $merge_count++;
            return { merged => $merge_count };
        };
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return undef };
        my $snapshot = $snapshot_app->_request_config_snapshot;
        is( $snapshot->{merged_config}{merged}, 1, 'missing native watcher keeps fresh configuration loading available' );
        ok( $snapshot_app->{_config_snapshot_watcher_unavailable}, 'missing native watcher is remembered for the application lifetime' );
        local $snapshot_app->{_request_config_snapshot} = undef;
        ok( !defined $snapshot_app->_config_snapshot_watcher, 'an unavailable watcher is not repeatedly reconstructed' );
    }
}

{
    my $merged_config = bless {}, 'Local::Problem48MergedConfig';
    my $rejecting_watch = bless {}, 'Local::Problem48RejectingWatch';
    my $snapshot_app = bless {
        config                    => $merged_config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    my $merge_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $rejecting_watch };
        local *Developer::Dashboard::Web::App::_config_snapshot_environment_signature = sub { return 'portable-after-reject' };
        local *Developer::Dashboard::Web::App::_config_snapshot_watch_paths = sub { return [] };
        local *Developer::Dashboard::Web::App::_config_snapshot_portable_signature = sub { return 'stable-portable-after-reject' };
        local *Local::Problem48MergedConfig::merged = sub {
            $merge_count++;
            return { merged => $merge_count };
        };
        my ( $snapshot, $warning );
        {
            local $SIG{__WARN__} = sub { $warning .= join '', @_ };
            $snapshot = $snapshot_app->_request_config_snapshot;
        }
        is( $snapshot->{merged_config}{merged}, 1, 'a watcher setup rejection falls back to a fresh config merge' );
        like( $warning, qr/watch backend rejected the configuration inventory/, 'a watcher setup rejection reports its fallback reason' );
        is( $snapshot_app->{_config_snapshot_cache}{portable_signature}, 'stable-portable-after-reject',
            'a rejected watcher seeds the portable freshness baseline after its fresh merge' );
        local $snapshot_app->{_request_config_snapshot} = undef;
        my $reused = $snapshot_app->_request_config_snapshot;
        is( $reused->{merged_config}{merged}, 1, 'the portable fallback reuses an unchanged snapshot after watcher setup failure' );
        is( $merge_count, 1, 'watcher setup failure does not disable cross-request config caching' );
    }
}

{
    my $merged_config = bless {}, 'Local::Problem48MergedConfig';
    my $reported_watch = bless {}, 'Local::Problem48ReportedRejectingWatch';
    my $snapshot_app = bless {
        config                    => $merged_config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    {
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $reported_watch };
        local *Local::Problem48MergedConfig::merged = sub { return {} };
        my $warning = '';
        {
            local $SIG{__WARN__} = sub { $warning .= join '', @_ };
            $snapshot_app->_request_config_snapshot;
        }
        like( $warning, qr/injected watcher setup failure/, 'a watcher-supplied setup error is reported without replacement' );
    }
}

{
    my $merged_config = bless {}, 'Local::Problem48MergedConfig';
    my $empty_error_watch = bless {}, 'Local::Problem48EmptyErrorRejectingWatch';
    my $snapshot_app = bless {
        config                    => $merged_config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    {
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $empty_error_watch };
        local *Local::Problem48MergedConfig::merged = sub { return {} };
        my $warning = '';
        {
            local $SIG{__WARN__} = sub { $warning .= join '', @_ };
            $snapshot_app->_request_config_snapshot;
        }
        like( $warning, qr/watch backend rejected the configuration inventory/, 'an empty watcher error uses the explicit generic diagnostic' );
    }
}

for my $cache_case (qw(no_watcher portable_hit portable_stale_signature portable_missing_environment portable_changed_environment portable_missing_signature invalid_cache missing_environment changed_environment missing_watch_signature changed_watcher complete_hit)) {
    my $merged_config = bless {}, 'Local::Problem48MergedConfig';
    my $watch = bless { unchanged => $cache_case eq 'changed_watcher' ? 0 : 1 }, 'Local::Problem48FixedWatch';
    my $cached_snapshot = { merged_config => { cached => $cache_case }, skill_config_entries => [] };
    my $cached = $cache_case eq 'invalid_cache'
      ? []
      : {
        environment_signature => 'current',
        watch_signature       => 'stable-watch',
        snapshot              => $cached_snapshot,
      };
    if ( $cache_case =~ /\Aportable_/ ) {
        $cached->{portable_signature} = $cache_case eq 'portable_stale_signature' ? 'stale-portable' : 'stable-portable'
          if $cache_case ne 'portable_missing_signature';
        delete $cached->{environment_signature} if $cache_case eq 'portable_missing_environment';
        $cached->{environment_signature} = 'stale' if $cache_case eq 'portable_changed_environment';
        delete $cached->{watch_signature};
    }
    delete $cached->{environment_signature} if $cache_case eq 'missing_environment';
    $cached->{environment_signature} = 'stale' if $cache_case eq 'changed_environment';
    delete $cached->{watch_signature} if $cache_case eq 'missing_watch_signature';
    my $snapshot_app = bless {
        config                    => $merged_config,
        pages                     => {},
        _request_config_snapshot => undef,
        _config_snapshot_cache   => $cached,
        _config_snapshot_watcher => $cache_case eq 'no_watcher' || $cache_case =~ /\Aportable_/ ? undef : $watch,
        _config_snapshot_watcher_unavailable => $cache_case eq 'no_watcher' || $cache_case =~ /\Aportable_/ ? 1 : 0,
    }, 'Developer::Dashboard::Web::App';
    my $merge_count = 0;
    {
        no warnings 'redefine';
        local *Local::Problem48MergedConfig::merged = sub {
            $merge_count++;
            return { merged => 'fresh' };
        };
        local *Developer::Dashboard::Web::App::_config_snapshot_environment_signature = sub { return 'current' };
        if ( $cache_case =~ /\Aportable_/ ) {
            local *Developer::Dashboard::Web::App::_config_snapshot_watch_paths = sub { return [] };
            local *Developer::Dashboard::Web::App::_config_snapshot_portable_signature = sub { return 'stable-portable' };
            if ( $cache_case eq 'portable_hit' ) {
                my $snapshot = $snapshot_app->_request_config_snapshot;
                is( $snapshot, $cached_snapshot, 'a matching portable signature returns its cached config snapshot' );
                is( $merge_count, 0, 'a portable cache hit avoids another merged-config load' );
                next;
            }
        }
        my $snapshot = $snapshot_app->_request_config_snapshot;
        if ( $cache_case eq 'complete_hit' ) {
            is( $snapshot, $cached_snapshot, 'a complete matching cache entry is returned without rebuilding' );
            is( $merge_count, 0, 'a complete matching cache entry avoids another config merge' );
        }
        else {
            is( $snapshot->{merged_config}{merged}, 'fresh', "$cache_case cache state safely rebuilds merged config" );
            is( $merge_count, 1, "$cache_case cache state performs exactly one config merge" );
        }
    }
}

{
    my $config = bless {}, 'Local::Problem48MergedConfig';
    my $snapshot_app = bless {
        config                    => $config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    my ( $signature_calls, $merge_calls ) = ( 0, 0 );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return undef };
        local *Developer::Dashboard::Web::App::_config_snapshot_environment_signature = sub { return 'undefined-portable-signature' };
        local *Developer::Dashboard::Web::App::_config_snapshot_watch_paths = sub { return [] };
        local *Developer::Dashboard::Web::App::_config_snapshot_portable_signature = sub {
            return ++$signature_calls == 1 ? undef : 'changed-during-merge';
        };
        local *Local::Problem48MergedConfig::merged = sub { $merge_calls++; return { fresh => 1 } };
        my $snapshot = $snapshot_app->_request_config_snapshot;
        is( $snapshot->{merged_config}{fresh}, 1,
            'an unavailable initial portable signature still returns freshly merged configuration' );
        ok( !exists $snapshot_app->{_config_snapshot_cache},
            'a missing initial portable signature cannot seed a reusable config snapshot' );
        is( $signature_calls, 2,
            'portable freshness is checked again after the fresh merge even when its baseline is unavailable' );
        is( $merge_calls, 1, 'a missing portable baseline does not suppress the current config merge' );
    }
}

for my $unstable_mode (qw(path_changed watcher_changed portable_changed)) {
    my $merged_config = bless {}, 'Local::Problem48MergedConfig';
    my $unstable_watch = Local::Problem48ConfigSnapshotWatch->new;
    my $snapshot_app = bless {
        config                    => $merged_config,
        pages                     => {},
        _request_config_snapshot => undef,
    }, 'Developer::Dashboard::Web::App';
    my $path_call = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return $unstable_mode eq 'portable_changed' ? undef : $unstable_watch;
        };
        local *Local::Problem48MergedConfig::merged = sub { return {} };
        local *Developer::Dashboard::Web::App::_config_snapshot_watch_paths = sub {
            $path_call++;
            return $unstable_mode eq 'path_changed' && $path_call > 1 ? ['/changed'] : ['/initial'];
        };
        if ( $unstable_mode eq 'portable_changed' ) {
            my $signature_call = 0;
            local *Developer::Dashboard::Web::App::_config_snapshot_portable_signature = sub {
                return ++$signature_call == 1 ? 'before-merge' : 'changed-during-merge';
            };
            $snapshot_app->_request_config_snapshot;
        }
        elsif ( $unstable_mode eq 'watcher_changed' ) {
            local *Local::Problem48ConfigSnapshotWatch::unchanged = sub { return 0 };
            $snapshot_app->_request_config_snapshot;
        }
        else {
            $snapshot_app->_request_config_snapshot;
        }
        ok( !exists $snapshot_app->{_config_snapshot_cache}, "$unstable_mode does not cache a snapshot after the inventory changes" );
    }
}

{
    my $project_root = tempdir(CLEANUP => 1);
    my $nested_dir = File::Spec->catdir( $project_root, 'nested' );
    make_path($nested_dir);
    my $boundary_paths = bless {
        runtime_roots => [],
        config_roots => [],
        skills_roots => [],
        cwd => $nested_dir,
        home => File::Spec->catdir( File::Spec->tmpdir, 'outside-home-boundary' ),
        project_root => $project_root,
    }, 'Local::Problem48BoundaryPaths';
    my $boundary_app = bless { pages => $boundary_paths }, 'Developer::Dashboard::Web::App';
    my $watch_paths = $boundary_app->_config_snapshot_watch_paths;
    ok( ( grep { $_ eq $project_root } @{$watch_paths} ), 'watch-path discovery includes the project boundary when cwd is outside home' );
    ok( !( grep { $_ eq '/' } @{$watch_paths} ), 'watch-path discovery stops at the project boundary rather than watching filesystem root' );
}

{
    my $nonexistent_root = '/problem48-missing-root/child';
    my $partial_paths = bless {
        runtime_roots => [ undef, $nonexistent_root ],
        config_roots => [ undef, [], '' ],
        skills_roots => [],
    }, 'Local::Problem48PartialPaths';
    my $partial_app = bless { pages => $partial_paths }, 'Developer::Dashboard::Web::App';
    my $original_dirname = Developer::Dashboard::Web::App->can('dirname');
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::dirname = sub {
            return $_[0] if $_[0] eq $nonexistent_root;
            return $original_dirname->(@_);
        };
        is_deeply( $partial_app->_config_snapshot_watch_paths, [], 'partial path providers skip invalid targets and cannot escape a self-parenting missing path' );
    }
}

{
    my $entries_paths = bless {
        runtime_roots => [],
        config_roots => [ undef, [], '' ],
        skills_roots => [],
        installed => [ undef, 'not a record', {}, { layers => 'not a list' }, { layers => [ undef, [], '' ] }, { layers => ['/tmp'] } ],
        nested => [ undef, 'not a record', {}, { dir => undef }, { dir => [] }, { dir => '/tmp' } ],
    }, 'Local::Problem48SkillEntryPaths';
    my $entries_app = bless { pages => $entries_paths }, 'Developer::Dashboard::Web::App';
    my $watch_paths = $entries_app->_config_snapshot_watch_paths;
    ok( ( grep { $_ eq '/tmp' } @{$watch_paths} ), 'watch-path discovery includes valid installed and nested skill roots' );
    ok( !( grep { ref($_) } @{$watch_paths} ), 'watch-path discovery ignores malformed skill entry and path values' );
}

{
    my $root_paths = bless {
        runtime_roots => [],
        config_roots => [],
        skills_roots => [],
        cwd => File::Spec->rootdir,
        home => '/problem48-not-home',
    }, 'Local::Problem48RootPaths';
    my $root_app = bless { pages => $root_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $root_app->_config_snapshot_watch_paths, [ File::Spec->rootdir ], 'watch-path discovery terminates when the working directory parent is itself' );
}

{
    my $no_home_paths = bless {}, 'Local::Problem48NoHomePaths';
    my $signature_app = bless { pages => $no_home_paths }, 'Developer::Dashboard::Web::App';
    like( $signature_app->_config_snapshot_environment_signature, qr/\ADASHBOARD_CONFIG_SNAPSHOT\0v1\0.*HU/s, 'environment signature records an unavailable home without requiring the accessor' );
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::Web::App::current_working_directory = sub { return undef };
        like(
            $signature_app->_config_snapshot_environment_signature,
            qr/\ADASHBOARD_CONFIG_SNAPSHOT\0v1\0.*HUCU\z/s,
            'environment signature represents an unavailable cwd without collapsing it to an empty path',
        );
    }
    my $no_runtime_app = bless { pages => $no_home_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $no_runtime_app->_config_snapshot_watch_paths, [], 'watch-path discovery skips blessed path providers without runtime_roots' );
}

{
    my $undefined_cwd_paths = bless {
        runtime_roots => [],
        config_roots => [],
        skills_roots => [],
        cwd => undef,
        home => '/problem48/home',
    }, 'Local::Problem48RootPaths';
    my $undefined_cwd_app = bless { pages => $undefined_cwd_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $undefined_cwd_app->_config_snapshot_watch_paths, [], 'watch-path discovery skips ancestry walking when cwd is undefined' );
}

{
    my $project_root = tempdir(CLEANUP => 1);
    my $project_child = File::Spec->catdir( $project_root, 'child' );
    make_path($project_child);
    my $project_paths = bless {
        runtime_roots => [],
        config_roots => [],
        skills_roots => [],
        cwd => $project_child,
        home => '',
        project_root => $project_root,
        inside => 1,
    }, 'Local::Problem48ProjectPaths';
    my $project_app = bless { pages => $project_paths }, 'Developer::Dashboard::Web::App';
    ok( ( grep { $_ eq $project_root } @{ $project_app->_config_snapshot_watch_paths } ), 'an empty home path falls through to a valid project boundary' );
}

{
    my $outside_cwd = tempdir(CLEANUP => 1);
    my $no_same_paths = bless {
        runtime_roots => [], config_roots => [], skills_roots => [],
        cwd => $outside_cwd,
        home => '/problem48/home',
        project_root => '/problem48/project',
    }, 'Local::Problem48NoSamePaths';
    my $no_same_app = bless { pages => $no_same_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $no_same_app->_config_snapshot_watch_paths, [ File::Spec->rootdir ], 'watch-path discovery skips boundary checks when the path provider has no comparison method' );
}

{
    my $empty_project_paths = bless {
        runtime_roots => [], config_roots => [], skills_roots => [],
        cwd => '/problem48/outside', home => '', project_root => '',
    }, 'Local::Problem48ProjectPaths';
    my $empty_project_app = bless { pages => $empty_project_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $empty_project_app->_config_snapshot_watch_paths, [], 'watch-path discovery skips empty home and project boundaries' );
}

{
    my $outside_cwd = tempdir(CLEANUP => 1);
    my $outside_paths = bless {
        runtime_roots => [], config_roots => [], skills_roots => [],
        cwd => $outside_cwd, home => '/problem48/home', project_root => '/problem48/project',
    }, 'Local::Problem48OutsidePaths';
    my $outside_app = bless { pages => $outside_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $outside_app->_config_snapshot_watch_paths, [ File::Spec->rootdir ], 'watch-path discovery does not climb when cwd lies outside home and project roots' );
}

{
    my $empty_cwd_paths = bless {
        runtime_roots => [],
        config_roots => [],
        skills_roots => [],
        cwd => '',
        home => '/problem48/home',
    }, 'Local::Problem48RootPaths';
    my $empty_cwd_app = bless { pages => $empty_cwd_paths }, 'Developer::Dashboard::Web::App';
    is_deeply( $empty_cwd_app->_config_snapshot_watch_paths, [], 'watch-path discovery skips ancestry walking when cwd is empty' );
}

{
    my $no_identity_paths = bless {
        runtime_roots => [],
        config_roots => [],
        skills_roots => [],
        cwd => File::Spec->catdir( File::Spec->tmpdir, 'problem48-no-identity', 'nested' ),
        home => File::Spec->catdir( File::Spec->tmpdir, 'problem48-no-identity' ),
    }, 'Local::Problem48NoIdentityPaths';
    my $no_identity_app = bless { pages => $no_identity_paths }, 'Developer::Dashboard::Web::App';
    ok( ref( $no_identity_app->_config_snapshot_watch_paths ) eq 'ARRAY', 'watch-path discovery remains bounded for path providers without identity comparisons' );
}

my $legacy_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Legacy Welcome
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-welcome
:--------------------------------------------------------------------------------:
HEAD: <meta name="x-bookmark" content="legacy-head-injected">
:--------------------------------------------------------------------------------:
STASH:
  name => 'World'
:--------------------------------------------------------------------------------:
HTML: <section>Hello [% name %]</section>
:--------------------------------------------------------------------------------:
CODE1: print "<div>Runtime</div>";
PAGE
$store->save_page($legacy_page);

my $nav_alpha = Developer::Dashboard::PageDocument->new(
    id     => 'nav/alpha.tt',
    title  => 'Alpha Nav',
    layout => { body => '[% IF env.current_page == \'/app/index\' %]Home[% ELSE %]<a href="/app/index">Home</a>[% END %]' },
);
$store->save_page($nav_alpha);

my $nav_beta = Developer::Dashboard::PageDocument->new(
    id     => 'nav/beta.tt',
    title  => 'Beta Nav',
    layout => { body => 'nav-current=[% env.current_page %] nav-rt=[% env.runtime_context.current_page %]' },
);
$store->save_page($nav_beta);

my ($code1, $type1, $body1) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1, 200, 'root editor route ok');
like($body1, qr/<textarea[^>]*name="instruction"/, 'root route renders editable instruction textarea');
unlike($body1, qr/Saved pages live under/, 'root route no longer renders landing list');
unlike($body1, qr/>Update</, 'root route does not render manual update button');
like($body1, qr/class="editor-blocks" id="instruction-blocks"/, 'root route renders a split-block instruction editor container');
like($body1, qr/ddForm\.addEventListener\('focusout', function\(\) \{/s, 'root route auto-submits when focus leaves the whole editor form');
like($body1, qr/function ddApplyDirectiveAssist\(editor\)/, 'root route editor script includes directive assist helper for one editor block');
like($body1, qr/function ddSplitInstruction\(\w+\)/, 'root route editor script can split bookmark source into visible blocks');
like($body1, qr/function ddComposeInstruction\(\)/, 'root route editor script recomposes visible blocks back into the hidden bookmark source');
like($body1, qr/section === 'HEAD' \|\| section === 'HTML'/, 'editor syntax highlighter treats HEAD content as HTML');
like($body1, qr/if \(priorDirective === 'TITLE'\) \{\s*if \(!directives\.BOOKMARK\) return 'BOOKMARK: ';\s*return directives\.HTML \? '' : 'HTML: ';/s, 'directive assist offers BOOKMARK before HTML when TITLE is the current block');
like($body1, qr/if \(priorDirective === 'HTML' \|\| \/\^CODE\\d\+\$\/\.test\(priorDirective\)\) \{\s*return 'CODE' \+ \(ddHighestCodeDirective\(fullText\) \+ 1\) \+ ': ';/s, 'directive assist advances CODE directives from HTML and CODE sections');
like($body1, qr/if \(event\.key !== 'Tab' \|\| event\.shiftKey \|\| event\.ctrlKey \|\| event\.altKey \|\| event\.metaKey\) return;/s, 'split editor reserves plain Tab to start a new section block');
like($body1, qr/ddInsertBlockAfter\(wrapper\);/s, 'split editor creates a new block when the user presses Tab inside a section');

my $root_index = Developer::Dashboard::PageDocument->new(
    id     => 'index',
    title  => 'Index',
    layout => { body => 'index body' },
);
$store->save_page($root_index);
my ($root_index_code, undef, undef, $root_index_headers) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($root_index_code, 302, 'root route redirects to the saved index bookmark when it exists');
is($root_index_headers->{Location}, '/app/index', 'root route uses the canonical saved index bookmark path');
unlink $store->page_file('index') or die "Unable to remove temporary index bookmark: $!";

my ($unknown_code, undef, $unknown_body) = @{ $app->handle(path => '/app/foobar', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($unknown_code, 200, 'unknown saved app routes open the editor instead of returning a not-found page');
like($unknown_body, qr/<textarea[^>]*name="instruction"/, 'unknown saved app routes render the bookmark editor');
like($unknown_body, qr/BOOKMARK:\s+\/app\/foobar/, 'unknown saved app routes prefill the requested bookmark path');
like($unknown_body, qr/HTML:\s*\nBlank page/s, 'unknown saved app routes prefill the blank page body');

my ($unknown_edit_code, undef, $unknown_edit_body) = @{ $app->handle(path => '/app/foobar/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($unknown_edit_code, 200, 'unknown saved edit routes open the editor instead of dying in page resolution');
like($unknown_edit_body, qr/<textarea[^>]*name="instruction"/, 'unknown saved edit routes render the bookmark editor');
like($unknown_edit_body, qr/BOOKMARK:\s+\/app\/foobar/, 'unknown saved edit routes prefill the requested bookmark path');
like($unknown_edit_body, qr/HTML:\s*\nBlank page/s, 'unknown saved edit routes prefill the blank page body');

# Given an authorized local user, when a saved-page route contains a traversal
# component, then the route returns an explicit client error instead of reading
# or writing outside dashboards_root (or leaking an uncaught exception).
for my $unsafe_path (
    '/app/../escaped',
    '/app/nested/../../escaped/edit',
    '/app/nested/../escaped/source',
    '/app/nested/../escaped/action/go',
    '/app/%2e%2e/encoded-escaped',
  ) {
    my ( $unsafe_code, $unsafe_type, $unsafe_body ) = @{ $app->handle(
        path        => $unsafe_path,
        query       => '',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $unsafe_code, 400, "authorized traversal route '$unsafe_path' returns a client error" );
    like( $unsafe_type, qr{text/plain}, "authorized traversal route '$unsafe_path' returns plain text" );
    like( $unsafe_body, qr/Invalid page id/, "authorized traversal route '$unsafe_path' explains the invalid page id" );
}

my $prefixed_saved_page = Developer::Dashboard::PageDocument->new(
    id     => '/app/prefixed-save',
    title  => 'Prefixed Save',
    layout => { body => 'prefixed body' },
);
$store->save_page($prefixed_saved_page);
ok(-f File::Spec->catfile( $paths->dashboards_root, 'prefixed-save' ), 'save_page normalizes a leading /app/ prefix to the relative dashboards path');
my $loaded_prefixed_page = $store->load_saved_page('prefixed-save');
is($loaded_prefixed_page->as_hash->{title}, 'Prefixed Save', 'load_saved_page resolves normalized prefixed bookmark ids');

my $saved_token = uri_escape( $store->encode_page($page) );
my ($code1_forbidden_post, $type1_forbidden_post, $body1_forbidden_post) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Posted%20Page%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20posted%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1_forbidden_post, 403, 'posted transient instruction route is denied by default');
like($type1_forbidden_post, qr/text\/plain/, 'posted transient instruction denial returns plain text');
like($body1_forbidden_post, qr/Transient token URLs are disabled/, 'posted transient instruction denial explains the policy');

my ($code1_forbidden_token, undef, $body1_forbidden_token) = @{ $app->handle(
    path        => '/',
    query       => "mode=render&token=$saved_token",
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1_forbidden_token, 403, 'tokenized transient page route is denied by default');
like($body1_forbidden_token, qr/Transient token URLs are disabled/, 'tokenized transient page denial explains the policy');

my ($code1_allowed_bookmark, undef, $body1_allowed_bookmark) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Saved%20From%20Default%20Policy%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20allowed-under-default%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20saved%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1_allowed_bookmark, 200, 'posted bookmark instruction is still allowed when transient URLs are disabled');
like($body1_allowed_bookmark, qr/saved body/, 'posted bookmark instruction still renders after it is saved');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'allowed-under-default' ), 'posted bookmark instruction still persists bookmark files when transient URLs are disabled' );

# Given an authorized local user submits a bookmark id that escapes the saved
# page root, when the root editor handles the POST, then it returns a deliberate
# client error and does not turn PageStore's rejection into a raw server error.
{
    my $outside_file = File::Spec->catfile( dirname( $paths->dashboards_root ), 'escaped' );
    unlink $outside_file if -e $outside_file;
    my $response;
    my $handled = eval {
        $response = $app->handle(
            path        => '/',
            method      => 'POST',
            body        => 'instruction=' . uri_escape("TITLE: Escaped POST\n:--------------------------------------------------------------------------------:\nBOOKMARK: ../escaped\n:--------------------------------------------------------------------------------:\nHTML: must not save\n"),
            remote_addr => '127.0.0.1',
            headers     => { host => '127.0.0.1' },
        );
        1;
    };
    ok( $handled, 'authorized traversal bookmark POST is handled without an uncaught exception' );
    is( $response ? $response->[0] : undef, 400, 'authorized traversal bookmark POST returns HTTP 400' );
    like( $response ? $response->[1] : '', qr{text/plain}, 'authorized traversal bookmark POST returns plain text' );
    like( $response ? $response->[2] : '', qr/Invalid page id/, 'authorized traversal bookmark POST explains the invalid page id' );
    ok( !-e $outside_file, 'authorized traversal bookmark POST creates no file outside dashboards_root' );
}

# Given an authorized user posts a traversal BOOKMARK id to a saved-page edit
# route, when the editor saves it, then the response is a deliberate client
# error and nothing is written outside dashboards_root.
{
    my ( $edit_code, $edit_type, $edit_body ) = @{ $app->handle(
        path        => '/app/editable-host/edit',
        method      => 'POST',
        body        => 'instruction=' . uri_escape("TITLE: Escaped edit\n:--------------------------------------------------------------------------------:\nBOOKMARK: ../edit-escaped\n:--------------------------------------------------------------------------------:\nHTML: must not save\n"),
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $edit_code, 400, 'a traversal bookmark id in an edit POST body returns HTTP 400' );
    like( $edit_type, qr{text/plain}, 'the edit POST traversal rejection is plain text' );
    like( $edit_body, qr/Invalid page id/, 'the edit POST traversal rejection explains the invalid page id' );
    ok( !-e File::Spec->catfile( dirname( $paths->dashboards_root ), 'edit-escaped' ),
        'the edit POST traversal writes nothing outside dashboards_root' );
}

# Saved-page error translation units: the invalid-id guard only intercepts
# PageStore validation failures and leaves every other error untouched.
{
    package T03::AuthStub;     sub new { bless {}, shift }
    package T03::SessionsStub; sub new { bless {}, shift }
    package T03::NoPageFile;   sub new { bless {}, shift }

    package T03::DyingStore;
    sub new { bless {}, shift }
    sub page_file { die "weird store failure\n" }
}
{
    my $guard_app = Developer::Dashboard::Web::App->new(
        auth => T03::AuthStub->new, pages => T03::NoPageFile->new, sessions => T03::SessionsStub->new,
    );
    is( $guard_app->_invalid_saved_page_id_response('anything'),
        undef, 'the invalid-id guard ignores pages objects without page_file' );

    my $dying_app = Developer::Dashboard::Web::App->new(
        auth => T03::AuthStub->new, pages => T03::DyingStore->new, sessions => T03::SessionsStub->new,
    );
    ok( !eval { $dying_app->_invalid_saved_page_id_response('anything'); 1 },
        'the invalid-id guard rethrows non-validation page_file failures' );
    like( $@, qr/weird store failure/, 'the rethrown page_file failure keeps its original message' );

    is( $app->_saved_page_error_response(undef), undef, 'saved-page error translation ignores undefined errors' );
    is( $app->_saved_page_error_response("boom\n"), undef, 'saved-page error translation ignores unrelated errors' );
    is( $app->_saved_page_error_response("Invalid page path at X line 1.\n")->[0],
        400, 'saved-page error translation converts containment failures to HTTP 400' );
}

# Given the page store fails a save for a reason that is not id validation,
# when the editors handle the POST, then the original failure still dies
# instead of being converted into a client error.
{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::save_page = sub { die "disk exploded\n" };
    my $disk_body = 'instruction=' . uri_escape("TITLE: T\n:--------------------------------------------------------------------------------:\nBOOKMARK: diskfail\n:--------------------------------------------------------------------------------:\nHTML: x\n");
    ok( !eval { $app->root_response(
        path        => '/',
        method      => 'POST',
        body        => $disk_body,
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ); 1 }, 'a non-validation save failure on the root editor still dies' );
    like( $@, qr/disk exploded/, 'the root editor rethrows the original save failure' );
    ok( !eval { $app->page_edit_post_response(
        id          => 'diskfail',
        method      => 'POST',
        body        => $disk_body,
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ); 1 }, 'a non-validation save failure on the page editor still dies' );
    like( $@, qr/disk exploded/, 'the page editor rethrows the original save failure' );
}

local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;

my ($code1b, undef, $body1b) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Posted%20Page%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20posted%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1b, 200, 'posted instruction route ok');
like($body1b, qr/posted body/, 'posted instruction renders through the root route');
unlike($body1b, qr/"instruction"\s*:/, 'posted instruction text is not folded back into stash');
unlike($body1b, qr/"request_host"\s*:/, 'posted instruction does not persist request metadata into stash');
my ($play_url) = $body1b =~ m{<button type="button" class="chrome-button" id="play-button" data-play-url="([^"]+)">Play</button>};
ok($play_url, 'play url extracted from root editor response');
$play_url = decoded_attr_value($play_url);
unlike($body1b, qr/id="view-source-url"/, 'edit mode does not render view source link');
my ($play_query) = $play_url =~ /\?(.*)\z/;
my ($code1c, undef, $body1c) = @{ $app->handle(
    path        => '/',
    query       => $play_query,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1c, 200, 'play url round-trips through token query parsing');
like($body1c, qr/posted body/, 'play url token survives browser-style query transport');
like($body1c, qr/nav-current=\/ nav-rt=\//, 'unnamed transient play route exposes the root path to shared nav tt fragments');
my $raw_plus_query = $play_query;
$raw_plus_query =~ s/%2B/+/g;
my ($code1c_plus, undef, $body1c_plus) = @{ $app->handle(
    path        => '/',
    query       => $raw_plus_query,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1c_plus, 200, 'play url survives raw plus token query transport');
like($body1c_plus, qr/posted body/, 'raw plus token query still decodes correctly');

my ($code1d, undef, $body1d) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A+Plus+Page%0A%3A--------------------------------------------------------------------------------%3A%0ACODE1%3A+print+123%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d, 200, 'form-urlencoded instruction with plus spacing route ok');
like($body1d, qr/123/, 'form-urlencoded root editor can execute opted-in transient CODE blocks');
unlike($body1d, qr/"instruction"\s*:/, 'form-urlencoded update does not pollute stash with instruction text');
unlike($body1d, qr/"request_host"\s*:/, 'form-urlencoded update does not persist request metadata');

my ($code1d_bookmark, undef, $body1d_bookmark) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Developer%20Dashboard%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20index%0A%3A--------------------------------------------------------------------------------%3A%0ASTASH%3A%20%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20HERE%20%5B%25%20env.current_page%20%25%5D%20%5B%25%20env.runtime_context.current_page%20%25%5D%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_bookmark, 200, 'posted bookmark instruction route ok');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'index' ), 'root editor saves posted bookmark instructions to the bookmark store' );
like($body1d_bookmark, qr/BOOKMARK:\s+index/s, 'posted bookmark response preserves the bookmark id');
my ($code1d_saved, undef, $body1d_saved) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved, 200, 'legacy /app/index route loads a bookmark saved from the root editor');
like($body1d_saved, qr/HERE \/app\/index \/app\/index/, 'legacy /app/index route renders the saved bookmark body with current page context');
like($body1d_saved, qr/class="dashboard-nav-items"/, 'saved page render includes shared nav section when nav tt pages exist');
like($body1d_saved, qr{<li data-nav-id="nav/alpha\.tt">Home</li>}s, 'shared nav fragments evaluate Template Toolkit conditionals against the current page');
like($body1d_saved, qr/nav-current=\/app\/index nav-rt=\/app\/index/, 'shared nav fragments receive env.current_page and env.runtime_context.current_page');

my $saved_play_token = uri_escape( $store->encode_page( Developer::Dashboard::PageDocument->from_instruction(<<'PAGE') ) );
TITLE: Saved Bookmark Via Token
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML: token body
PAGE
my ($code1d_saved_play, undef, $body1d_saved_play) = @{ $app->handle(
    path        => '/',
    query       => "mode=render&token=$saved_play_token",
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_saved_play, 200, 'transient render route responds for a named bookmark token');

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_machine_ip = sub { return undef };
    my $remote_page = Developer::Dashboard::PageDocument->new(
        id     => 'context-remote',
        title  => 'Context Remote',
        layout => { body => 'body' },
    );
    $remote_page->{meta}{request_context} = {
        remote_addr => '192.0.2.55',
    };
    my $remote_html = $app->_top_context_html($remote_page);
    like( $remote_html, qr{href="http://192\.0\.2\.55"}, '_top_context_html falls back to remote_addr when machine and host values are absent' );

    my $default_page = Developer::Dashboard::PageDocument->new(
        id     => 'context-default',
        title  => 'Context Default',
        layout => { body => 'body' },
    );
    $default_page->{meta}{request_context} = {};
    my $default_html = $app->_top_context_html($default_page);
    like( $default_html, qr{href="http://127\.0\.0\.1"}, '_top_context_html falls back to loopback when no machine, host, or remote address is available' );
}
like($body1d_saved_play, qr/class="dashboard-nav-items"/, 'transient render for a named bookmark keeps the shared nav section');
like($body1d_saved_play, qr{<li data-nav-id="nav/alpha\.tt">Home</li>}s, 'transient render for a named bookmark evaluates nav tt fragments against the saved page route');
like($body1d_saved_play, qr/nav-current=\/app\/index nav-rt=\/app\/index/, 'transient render for a named bookmark exposes the saved page path to nav tt fragments');

my ($code1d_nav, undef, $body1d_nav) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Nav%20Editor%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20nav%2Ffoo.tt%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20%3Ca%20href%3D%22%2Ffoo%22%3EFoo%20Nav%3C%2Fa%3E%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_nav, 200, 'posted nested nav bookmark route ok');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'nav', 'foo.tt' ), 'root editor saves nested nav bookmark instructions under nav/' );
my ($code1d_nav_page, undef, $body1d_nav_page) = @{ $app->handle(path => '/app/nav/foo.tt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_nav_page, 200, 'legacy /app route loads nested nav bookmark ids');
like($body1d_nav_page, qr/Foo Nav/, 'legacy /app nested nav route renders the saved nav bookmark body');
my ($code1d_nav_source, $type1d_nav_source, $body1d_nav_source) = @{ $app->handle(path => '/app/nav/foo.tt/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_nav_source, 200, 'nested nav bookmark source route ok');
like($type1d_nav_source, qr/text\/plain/, 'nested nav bookmark source route returns plain text');
like($body1d_nav_source, qr/^BOOKMARK:\s+nav\/foo.tt$/m, 'nested nav bookmark source route preserves nested bookmark id');
open my $raw_nav_fh, '>', File::Spec->catfile( $paths->dashboards_root, 'nav', 'here.tt' ) or die $!;
print {$raw_nav_fh} <<'TT';
[% index = '/app/index' %]
[% foo = '/app/foobar' %]
<a href=[% index %]>[% index %]</a>
TT
close $raw_nav_fh;
my ($code1d_raw_nav_page, undef, $body1d_raw_nav_page) = @{ $app->handle(path => '/app/nav/here.tt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_raw_nav_page, 200, 'legacy /app route loads raw nav tt fragment ids');
like($body1d_raw_nav_page, qr{<a href=/app/index>/app/index</a>}s, 'legacy /app nested nav route renders raw nav tt fragment files through Template Toolkit');
my ($code1d_raw_nav_source, $type1d_raw_nav_source, $body1d_raw_nav_source) = @{ $app->handle(path => '/app/nav/here.tt/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_raw_nav_source, 200, 'raw nav tt source route ok');
like($type1d_raw_nav_source, qr/text\/plain/, 'raw nav tt source route returns plain text');
like($body1d_raw_nav_source, qr/\[% index = '\/app\/index' %\]/, 'raw nav tt source route preserves the original raw nav tt source');
my ($code1d_saved_with_raw_nav, undef, $body1d_saved_with_raw_nav) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved_with_raw_nav, 200, 'legacy /app/index route still responds after adding a raw nav tt fragment');
like($body1d_saved_with_raw_nav, qr{<li data-nav-id="nav/here\.tt">\s*<a href=/app/index>/app/index</a>\s*</li>}s, 'saved page render includes raw nav tt fragment files in the shared nav output');
open my $broken_raw_nav_fh, '>', File::Spec->catfile( $paths->dashboards_root, 'nav', 'here.tt' ) or die $!;
print {$broken_raw_nav_fh} <<'TT';
[% index = '/app/index' %]
<a href="[% IF index %]">[% index %]</a>
TT
close $broken_raw_nav_fh;
my ($code1d_broken_raw_nav_page, undef, $body1d_broken_raw_nav_page) = @{ $app->handle(path => '/app/nav/here.tt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_broken_raw_nav_page, 200, 'legacy /app route still responds for a raw nav tt fragment with a syntax error');
like($body1d_broken_raw_nav_page, qr/runtime-error/, 'legacy /app raw nav tt route exposes a runtime error for TT syntax failures');
unlike($body1d_broken_raw_nav_page, qr/\[%\s*IF\s+index\s*%\]|\[%\s*index\s*%\]/, 'legacy /app raw nav tt route does not leak raw TT source when Template Toolkit parsing fails');
my ($code1d_saved_with_broken_raw_nav, undef, $body1d_saved_with_broken_raw_nav) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved_with_broken_raw_nav, 200, 'legacy /app/index route still responds after a raw nav tt fragment gains a syntax error');
like($body1d_saved_with_broken_raw_nav, qr/runtime-error/, 'saved page render surfaces nav TT syntax failures as runtime errors');
unlike($body1d_saved_with_broken_raw_nav, qr/\[%\s*IF\s+index\s*%\]|\[%\s*index\s*%\]/, 'saved page render does not leak raw nav TT source when Template Toolkit parsing fails');

my ($code1d_tt, undef, $body1d_tt) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Sample%20Dashboard%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20index%0A%3A--------------------------------------------------------------------------------%3A%0ASTASH%3A%20foo%20%3D%3E%201%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20%3Ch1%3E%5B%25%20title%20%25%5D%3C%2Fh1%3E%20%5B%25%20stash.foo%20%25%5D%0A%0AHello%20World%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt, 200, 'posted TT bookmark instruction route ok');
like($body1d_tt, qr/\[% title %\]/, 'editor preserves TT placeholders in the posted source view');
like($body1d_tt, qr/HTML:\s*&lt;h1&gt;\[% title %\]&lt;\/h1&gt;/s, 'editor textarea keeps TT placeholders inside HTML sections');
like($body1d_tt, qr/ddSource\.value = "[^"]*\[% title %\][^"]*"\s*;\s*ddLoadBlocks\(ddSource\.value\);/s, 'editor boot script keeps TT placeholders in the browser-loaded hidden instruction source before it splits blocks');
like($app->_editor_overlay_html("HTML: <h1>[% title %]</h1>\n"), qr/<span class="tok-directive">HTML:<\/span>\s*<span class="tok-tag">&lt;h1<\/span><span class="tok-tag">&gt;<\/span><span class="tok-note">\[% title %\]<\/span>/s, 'editor syntax highlight is still built from highlighted bookmark source lines');
my ($code1d_tt_source, $type1d_tt_source, $body1d_tt_source) = @{ $app->handle(
    path        => '/app/index/source',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_source, 200, 'saved TT bookmark source route ok');
like($type1d_tt_source, qr/text\/plain/, 'saved TT bookmark source route returns plain text');
like($body1d_tt_source, qr/^HTML:\s+<h1>\[% title %\]<\/h1> \[% stash\.foo %\]$/m, 'saved TT bookmark source route preserves raw TT placeholders');
my ($play_url_tt) = $body1d_tt =~ m{<button type="button" class="chrome-button" id="play-button" data-play-url="([^"]+)">Play</button>};
ok($play_url_tt, 'TT bookmark play url extracted');
is($play_url_tt, '/app/index', 'saved TT bookmark play url stays on the named saved route');
my ($code1d_tt_render, undef, $body1d_tt_render) = @{ $app->handle(
    path        => '/app/index',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_render, 200, 'TT bookmark play route ok');
like($body1d_tt_render, qr{<h1>\s*Sample Dashboard\s*</h1>\s*1}s, 'TT render receives TITLE and STASH values');
my ($tt_view_source_url) = $body1d_tt_render =~ m{<a href="([^"]+)" id="view-source-url">View Source</a>};
is($tt_view_source_url, '/app/index/edit', 'TT render exposes a saved bookmark view source link');
my $broken_tt_instruction = <<'PAGE';
TITLE: Broken TT Bookmark
:--------------------------------------------------------------------------------:
BOOKMARK: broken-tt
:--------------------------------------------------------------------------------:
HTML: <div>before [% IF stash.foo %] broken</div>
PAGE
$store->save_page( Developer::Dashboard::PageDocument->from_instruction($broken_tt_instruction) );
my ($code1d_broken_tt_render, undef, $body1d_broken_tt_render) = @{ $app->handle(
    path        => '/app/broken-tt',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_broken_tt_render, 200, 'TT bookmark render route still responds when Template Toolkit parsing fails');
like($body1d_broken_tt_render, qr/runtime-error/, 'TT bookmark render route surfaces the Template Toolkit syntax error');
unlike($body1d_broken_tt_render, qr/\[%\s*IF\s+stash\.foo\s*%\]/, 'TT bookmark render route does not leak raw TT syntax when Template Toolkit parsing fails');
my ($code1d_tt_view_source, $type1d_tt_view_source, $body1d_tt_view_source) = @{ $app->handle(
    path        => '/app/index/edit',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_view_source, 200, 'transient TT view source route ok');
like($type1d_tt_view_source, qr/text\/html/, 'transient TT view source route returns the browser editor HTML');
like($body1d_tt_view_source, qr{<textarea[^>]*>[\s\S]*HTML:\s+&lt;h1&gt;\[% title %\]&lt;/h1&gt; \[% stash\.foo %\][\s\S]*</textarea>}m, 'transient TT view source editor keeps raw TT placeholders after render');
unlike($body1d_tt_view_source, qr{<textarea[^>]*>[\s\S]*HTML:\s+&lt;h1&gt;Sample Dashboard&lt;/h1&gt; 1[\s\S]*</textarea>}m, 'transient TT view source editor does not bake rendered values into source');
my $prefixed_page = Developer::Dashboard::PageDocument->new(
    id     => '/app/index',
    title  => 'Prefixed Route',
    layout => { body => '<div>prefixed route body</div>' },
    meta   => {
        source_kind     => 'saved',
        request_context => { path => '/app/index', remote_addr => '127.0.0.1', host => '127.0.0.1' },
    },
);
my $prefixed_render = $app->_render_page_html( $prefixed_page, 'render' );
like( $prefixed_render, qr{href="/app/index/edit" id="view-source-url"}, 'saved route rendering normalizes bookmark ids that already include /app/ when building the view-source link' );
unlike( $prefixed_render, qr{/app//app/index/edit}, 'saved route rendering does not duplicate the /app prefix in edit links' );

my $highlight_source = join "\n",
    'TITLE: Highlight Demo',
    ':--------------------------------------------------------------------------------:',
    q{HTML: <style>body { color: red; }</style><script>const run = 1;</script><div style="color:red" onclick="run()">[% stash.name %]</div>},
    ':--------------------------------------------------------------------------------:',
    q{CODE1: my $name = 'Michael'; print $name;},
    '';
my ($code1e, undef, $body1e) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($highlight_source),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1e, 200, 'highlight demo route ok');
like($body1e, qr/wrap="off"/, 'editor textarea disables soft wrapping so long bookmark lines keep exact geometry');
like($body1e, qr/white-space:\s*pre;/, 'editor stack keeps preformatted line geometry instead of wrapping overlay lines differently from the textarea');
like($body1e, qr/viewport\.className = 'editor-overlay-viewport';/, 'editor route builds a clipped overlay viewport for each visible block');
like($body1e, qr/function ddSyncEditorOverlay\(editor, highlight\)/, 'editor route exposes a dedicated overlay sync helper for one block overlay');
like($body1e, qr/function ddAutoResizeEditor\(editor\)/, 'editor route exposes a dedicated auto-resize helper for each block textarea');
like($body1e, qr/editor\.style\.height = 'auto';\s*editor\.style\.height = Math\.max\(editor\.scrollHeight, 48\) \+ 'px';/s, 'editor route grows each block textarea to match its content height');
like($body1e, qr/highlight\.style\.transform = 'translate\('/, 'editor route syncs each block overlay position through transforms instead of a second scrollbox');
like($body1e, qr/function ddCreateEditorBlock\(/, 'editor route builds visible block editors dynamically from bookmark sections');
like($body1e, qr/function ddRenderEditor\(editor, highlight\) \{\s*highlight\.innerHTML = ddOverlayHtml\(editor\.value\);\s*ddAutoResizeEditor\(editor\);\s*ddSyncEditorOverlay\(editor, highlight\);/s, 'editor route auto-resizes a block before syncing its overlay');
like($body1e, qr/window\.addEventListener\('resize', function\(\) \{\s*Array\.prototype\.slice\.call\(ddBlocks\.querySelectorAll\('\.editor-block'\)\)\.forEach\(function\(block\) \{\s*const editor = block\.querySelector\('\.instruction-block-editor'\);\s*const highlight = block\.querySelector\('\.editor-overlay'\);\s*ddAutoResizeEditor\(editor\);\s*ddSyncEditorOverlay\(editor, highlight\);/s, 'editor route reapplies auto-resize when the window size changes');

# DD-409: the mirrored source textarea must expose a programmatic accessible
# name; the exhaustive accessible-name contract for every generated control
# lives in the dedicated editor field label test.
like($body1e, qr/<textarea class="instruction-source" id="instruction-source" name="instruction" aria-label="[^"]+"/, 'mirrored editor source textarea carries a non-empty accessible name');
my $demo_overlay = $app->_editor_overlay_html($highlight_source);
like($demo_overlay, qr/<span class="tok-directive">HTML:<\/span>/, 'editor overlay highlights bookmark directives');
like($demo_overlay, qr/<span class="tok-tag">&lt;style<\/span>/, 'editor overlay highlights HTML tag names');
like($demo_overlay, qr/<span class="tok-js">const<\/span> run = 1;/, 'editor overlay highlights JavaScript keywords');
like($demo_overlay, qr/<span class="tok-note">\[% stash\.name %\]<\/span>/, 'editor overlay highlights TT placeholders inside HTML sections');
like(
    $app->_editor_overlay_html("HEAD: <script>const ready = true;</script>\n"),
    qr/<span class="tok-js">const<\/span> ready = true;/,
    'server-side editor overlay highlights JavaScript inside HEAD sections',
);

my $broken_editor_source = <<'BOOKMARK';
BOOKMARK: test
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(function () {
    let lastLength = 0;

    $.ajax({
        url: foo.bar,
        type: 'GET',
        dataType: 'text',
        cache: false,

        xhr: function () {
            const xhr = new window.XMLHttpRequest();

            xhr.onprogress = function () {
                const response = xhr.responseText;

                // Replace whole content with everything received so far
                $('.display').text(response);

                // If you want only the new chunk instead, use this:
                // const newChunk = response.substring(lastLength);
                // $('.display').append(newChunk);
                // lastLength = response.length;
            };

            return xhr;
        },

        success: function (response) {
            $('.display').text(response);
        },

        error: function (xhr, status, error) {
            console.error('Stream error:', status, error);
        }
    });
});
</script>
TEST2: <span class=display></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', file => 'foobar', code => q{
while (1) {
  print 123;
  sleep 1;
}
};
~
BOOKMARK
my ( $broken_editor_code, undef, $broken_editor_body ) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($broken_editor_source),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $broken_editor_code, 200, 'exact bookmark editor repro route ok' );
like( $broken_editor_body, qr/Stream error:/, 'exact bookmark editor repro keeps the original bookmark text visible in the editor route' );
my $broken_editor_overlay = $app->_editor_overlay_html($broken_editor_source);
like( $broken_editor_overlay, qr/<span class="tok-js">let<\/span> lastLength = 0;/, 'exact bookmark editor repro keeps the JavaScript source text visible in the editor overlay' );
like( $broken_editor_overlay, qr/<span class="tok-string">'Stream error:'<\/span>/, 'exact bookmark editor repro highlights JavaScript string text in the overlay' );
like( $broken_editor_overlay, qr/<span class="tok-string">'GET'<\/span>/, 'exact bookmark editor repro highlights JavaScript string literals without leaking markup text' );
unlike( $broken_editor_overlay, qr/class=&quot;tok-string&quot;&gt;GET/, 'exact bookmark editor repro no longer leaks span attribute text into the visible editor overlay' );
unlike( $broken_editor_overlay, qr/\x1EHL\d+\x1E/, 'exact bookmark editor repro does not leak placeholder markers into the overlay output' );

my ($code2, $type2, $body2) = @{ $app->handle(path => '/app/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code2, 200, 'saved page route ok');
like($body2, qr/Welcome/, 'saved page rendered');
unlike($body2, qr{<h1>\s*Welcome\s*</h1>}, 'page title is not injected into the page body');
like($body2, qr{<title>Welcome</title>}, 'page title is still rendered in the head title element');
like($body2, qr{<head>.*<meta name="x-bookmark" content="head-injected">.*</head>}s, 'saved bookmark HEAD content is injected inside the rendered document head');
unlike($body2, qr/id="logout-url"/, 'admin route does not render logout link');

my $static_nav_root = File::Spec->catdir( $paths->dashboards_root, 'nav' );
make_path($static_nav_root);
my $static_nav_file = File::Spec->catfile( $static_nav_root, 'static-plain.tt' );
open my $static_nav_fh, '>:raw', $static_nav_file
  or die "Unable to create static nav fixture '$static_nav_file': $!";
print {$static_nav_fh} '<span id="static-nav-fixture">Static navigation</span>'
  or die "Unable to write static nav fixture '$static_nav_file': $!";
close $static_nav_fh or die "Unable to close static nav fixture '$static_nav_file': $!";

my $cache_invalidation_nav = File::Spec->catfile( $static_nav_root, 'cache-invalidation.tt' );
my ( $nav_cache_before_code, undef, $nav_cache_before_body ) = @{ $app->handle(
    path        => '/app/index',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $nav_cache_before_code, 200, 'saved page renders before nav inventory changes' );
open my $cache_nav_fh, '>:raw', $cache_invalidation_nav
  or die "Unable to create nav inventory invalidation fixture '$cache_invalidation_nav': $!";
print {$cache_nav_fh} '<span id="nav-inventory-added">Added navigation</span>'
  or die "Unable to write nav inventory invalidation fixture '$cache_invalidation_nav': $!";
close $cache_nav_fh or die "Unable to close nav inventory invalidation fixture '$cache_invalidation_nav': $!";
my ( $nav_cache_added_code, undef, $nav_cache_added_body ) = @{ $app->handle(
    path        => '/app/index',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $nav_cache_added_code, 200, 'saved page still renders after a nav addition' );
like( $nav_cache_added_body, qr/id="nav-inventory-added"/, 'a new nav fragment appears immediately after the inventory changes' );
open $cache_nav_fh, '>:raw', $cache_invalidation_nav
  or die "Unable to update nav inventory invalidation fixture '$cache_invalidation_nav': $!";
print {$cache_nav_fh} '<span id="nav-inventory-updated">Updated navigation</span>'
  or die "Unable to update nav inventory invalidation fixture '$cache_invalidation_nav': $!";
close $cache_nav_fh or die "Unable to close updated nav inventory invalidation fixture '$cache_invalidation_nav': $!";
my ( $nav_cache_updated_code, undef, $nav_cache_updated_body ) = @{ $app->handle(
    path        => '/app/index',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $nav_cache_updated_code, 200, 'saved page still renders after a nav content update' );
like( $nav_cache_updated_body, qr/id="nav-inventory-updated"/, 'cached filename inventory still loads fresh nav content' );
unlike( $nav_cache_updated_body, qr/id="nav-inventory-added"/, 'cached filename inventory does not cache stale nav content' );
unlink $cache_invalidation_nav
  or die "Unable to remove nav inventory invalidation fixture '$cache_invalidation_nav': $!";
my ( $nav_cache_removed_code, undef, $nav_cache_removed_body ) = @{ $app->handle(
    path        => '/app/index',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $nav_cache_removed_code, 200, 'saved page still renders after a nav removal' );
unlike( $nav_cache_removed_body, qr/nav-inventory-(?:added|updated)/, 'a removed nav fragment disappears immediately' );

{
    my $nav_fixture_root = tempdir( CLEANUP => 1 );
    my $nav_fixture_dir  = File::Spec->catdir( $nav_fixture_root, 'nav' );
    make_path($nav_fixture_dir);
    my $alpha_nav = File::Spec->catfile( $nav_fixture_dir, 'alpha.tt' );
    open my $alpha_fh, '>:raw', $alpha_nav or die "Unable to create nav fixture '$alpha_nav': $!";
    print {$alpha_fh} 'alpha' or die "Unable to write nav fixture '$alpha_nav': $!";
    close $alpha_fh or die "Unable to close nav fixture '$alpha_nav': $!";

    my $scan = Developer::Dashboard::Web::App->can('_scan_nav_directory_ids');
    ok( $scan, 'saved nav inventory has a separately testable directory-scan operation' );
    my $nav_app = bless {}, 'Developer::Dashboard::Web::App';
    ok( !defined $nav_app->_nav_root_for_id('nav/alpha.tt'), 'nav root provenance is absent before an inventory has been built' );
    if ($scan) {
        my $scan_calls = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::_scan_nav_directory_ids = sub {
            $scan_calls++;
            return $scan->(@_);
        };
        my $first_nav_ids = $nav_app->_nav_ids_for_roots( [$nav_fixture_root] );
        is_deeply( $first_nav_ids, ['nav/alpha.tt'], 'saved nav inventory includes the sorted nav id' );
        is( $nav_app->_nav_root_for_id('nav/alpha.tt'), $nav_fixture_root,
            'saved nav inventory retains the supplying layer for direct secure loads' );
        ok( !defined $nav_app->_nav_root_for_id('nav/missing.tt'), 'unknown nav ids have no supplying layer' );
        my $unchanged_nav_ids = $nav_app->_nav_ids_for_roots( [$nav_fixture_root] );
        is_deeply( $unchanged_nav_ids, ['nav/alpha.tt'], 'unchanged nav inventory is returned from the validated cache' );
        is( $scan_calls, 1, 'unchanged nav directory metadata avoids rescanning entries' );

        my $beta_nav = File::Spec->catfile( $nav_fixture_dir, 'beta.tt' );
        open my $beta_fh, '>:raw', $beta_nav or die "Unable to create nav fixture '$beta_nav': $!";
        print {$beta_fh} 'beta' or die "Unable to write nav fixture '$beta_nav': $!";
        close $beta_fh or die "Unable to close nav fixture '$beta_nav': $!";
        is_deeply(
            $nav_app->_nav_ids_for_roots( [$nav_fixture_root] ),
            [ 'nav/alpha.tt', 'nav/beta.tt' ],
            'adding a nav fragment invalidates and refreshes the cached inventory',
        );
        is( $scan_calls, 2, 'a nav addition triggers one directory rescan' );

        my $second_nav_root = tempdir( CLEANUP => 1 );
        make_path( File::Spec->catdir( $second_nav_root, 'nav' ) );
        open my $shadow_beta_fh, '>:raw', File::Spec->catfile( $second_nav_root, 'nav', 'beta.tt' )
          or die "Unable to create shadow nav fixture: $!";
        print {$shadow_beta_fh} 'shadow beta' or die "Unable to write shadow nav fixture: $!";
        close $shadow_beta_fh or die "Unable to close shadow nav fixture: $!";
        $nav_app->_nav_ids_for_roots( [ $nav_fixture_root, $second_nav_root ] );
        is( $nav_app->_nav_root_for_id('nav/beta.tt'), $second_nav_root,
            'the deepest configured layer retains nav lookup precedence' );

        unlink $alpha_nav or die "Unable to remove nav fixture '$alpha_nav': $!";
        is_deeply(
            $nav_app->_nav_ids_for_roots( [$nav_fixture_root] ),
            ['nav/beta.tt'],
            'removing a nav fragment invalidates and refreshes the cached inventory',
        );
        is( $scan_calls, 4, 'a nav removal triggers one directory rescan' );

        $nav_app->{_nav_ids_cache} = {};
        ok( !defined $nav_app->_nav_root_for_id('nav/beta.tt'), 'a cache without root provenance does not invent a layer' );
        is_deeply(
            $nav_app->_nav_ids_for_roots( [$nav_fixture_root] ),
            ['nav/beta.tt'],
            'a cache hash without a signature is treated as a miss',
        );
        is( $scan_calls, 5, 'a missing cached signature triggers a directory rescan' );
        $nav_app->{_nav_ids_cache}{ids} = {};
        is_deeply(
            $nav_app->_nav_ids_for_roots( [$nav_fixture_root] ),
            ['nav/beta.tt'],
            'malformed cached nav ids are discarded and rebuilt',
        );
        is( $scan_calls, 6, 'malformed nav cache data triggers a directory rescan' );
        is_deeply( $nav_app->_nav_ids_for_roots('not-an-array'), [], 'nav inventory rejects a non-array root list' );
        is_deeply( $nav_app->_nav_ids_for_roots( [ undef, '' ] ), [], 'nav inventory skips undefined and empty root paths' );

        my $missing_nav_root = File::Spec->catdir( $nav_fixture_root, 'missing-root' );
        is_deeply( $nav_app->_nav_ids_for_roots( [$missing_nav_root] ), [], 'missing nav directories produce an empty inventory' );
        is_deeply( $nav_app->_nav_ids_for_roots( [$missing_nav_root] ), [], 'an unchanged missing nav directory reuses the empty inventory' );
    }
    {
        no warnings 'redefine';
        local *Time::HiRes::stat = sub { $! = EIO; return; };
        my $stat_error = eval { $nav_app->_nav_ids_for_roots( [$nav_fixture_root] ); 1 } ? '' : $@;
        like( $stat_error, qr/Unable to inspect saved navigation directory/, 'nav inventory reports a high-resolution directory stat failure' );
    }
    {
        no warnings 'redefine';
        my $open_attempts = 0;
        local *Developer::Dashboard::Web::App::_open_nav_directory = sub { $open_attempts++; return; };
        my $open_app = bless {}, 'Developer::Dashboard::Web::App';
        is_deeply( $open_app->_nav_ids_for_roots( [$nav_fixture_root] ), [], 'an unopenable nav directory preserves the established skip behavior' );
        ok( !exists $open_app->{_nav_ids_cache}, 'an incomplete nav inventory is not cached' );
        is_deeply( $open_app->_nav_ids_for_roots( [$nav_fixture_root] ), [], 'an unopenable directory is retried on the next request' );
        is( $open_attempts, 2, 'each uncached incomplete inventory attempts the directory again' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::_read_nav_directory_entries = sub { die "injected nav read failure\n" };
        my $read_error = eval { bless( {}, 'Developer::Dashboard::Web::App' )->_nav_ids_for_roots( [$nav_fixture_root] ); 1 } ? '' : $@;
        like( $read_error, qr/injected nav read failure/, 'nav inventory exposes directory-read failures' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::_close_nav_directory = sub { die "injected nav close failure\n" };
        my $close_error = eval { bless( {}, 'Developer::Dashboard::Web::App' )->_nav_ids_for_roots( [$nav_fixture_root] ); 1 } ? '' : $@;
        like( $close_error, qr/injected nav close failure/, 'nav inventory exposes directory-close failures' );
    }
}

is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
        body          => '<span>literal</span>',
    ), 1, 'literal raw navigation without code blocks qualifies for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'instruction',
        body          => '<span>literal</span>',
    ), 0, 'non-raw navigation does not qualify for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        body => '<span>literal</span>',
    ), 0, 'raw navigation without a source-format marker does not qualify for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
    ), 0, 'raw navigation without a body does not qualify for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
        body          => [ '<span>literal</span>' ],
    ), 0, 'raw navigation with a reference body does not qualify for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
        body          => '[% title %]',
    ), 0, 'raw navigation with a Template Toolkit opener does not qualify for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
        body          => '<span>literal</span>',
        codes         => [ { id => 'CODE1', body => 'print 1' } ],
    ), 0, 'raw navigation with code blocks does not qualify for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
        body          => '<span>literal</span>',
        codes         => [],
    ), 1, 'raw navigation with an empty code-block array qualifies for the preparation bypass' );
is( $app->_is_literal_raw_nav(
        source_format => 'raw-nav-tt',
        body          => '<span>literal</span>',
        codes         => {},
    ), 1, 'raw navigation with no array of code blocks qualifies for the preparation bypass' );

my @raw_nav_prepare_ids;
my @raw_nav_canonical_ids;
my @page_store_abs_path_inputs;
my $original_prepare_page = Developer::Dashboard::PageRuntime->can('prepare_page');
my $original_canonical_instruction = Developer::Dashboard::PageDocument->can('canonical_instruction');
my $original_page_store_abs_path = Developer::Dashboard::PageStore->can('abs_path');
my $original_dashboards_roots = Developer::Dashboard::PathRegistry->can('dashboards_roots');
my $original_page_file_candidates = Developer::Dashboard::PageStore->can('_page_file_candidates');
my $page_candidate_lookup_state = { active => 0 };
my $candidate_roots_resolves = 0;
my ( $code2b, undef, $body2b );
{
    no warnings 'redefine';
    local *Developer::Dashboard::PageStore::abs_path = sub {
        push @page_store_abs_path_inputs, $_[0];
        return $original_page_store_abs_path->(@_);
    };
    local *Developer::Dashboard::PathRegistry::dashboards_roots = sub {
        $candidate_roots_resolves++ if $page_candidate_lookup_state->{active};
        return $original_dashboards_roots->(@_);
    };
    local *Developer::Dashboard::PageStore::_page_file_candidates = sub {
        my ( $store, @args ) = @_;
        local $page_candidate_lookup_state->{active} = 1;
        return $original_page_file_candidates->( $store, @args );
    };
    {
        local *Developer::Dashboard::PageRuntime::prepare_page = sub {
            my ( $runtime_instance, %args ) = @_;
            my $page = $args{page};
            push @raw_nav_prepare_ids, $page->{id} || ''
              if ref($page) eq 'Developer::Dashboard::PageDocument'
              && ( $page->{meta}{source_format} || '' ) eq 'raw-nav-tt';
            return $original_prepare_page->( $runtime_instance, %args );
        };
        local *Developer::Dashboard::PageDocument::canonical_instruction = sub {
            my ($page) = @_;
            push @raw_nav_canonical_ids, $page->{id} || ''
              if ref($page) eq 'Developer::Dashboard::PageDocument'
              && ( $page->{meta}{source_format} || '' ) eq 'raw-nav-tt';
            return $original_canonical_instruction->(@_);
        };
        ( $code2b, undef, $body2b ) = @{ $app->handle(
            path        => '/app/welcome',
            query       => 'name=Michael',
            remote_addr => '127.0.0.1',
            headers     => { host => '127.0.0.1' },
        ) };
    }
    is( $candidate_roots_resolves, 1,
        'saved-page route snapshots ordered page roots once despite loading its page and nav fragments' );
    my @dashboard_roots = $paths->dashboards_roots;
    my $root_resolve_counts = sub {
        my %counts = map { $_ => 0 } @dashboard_roots;
        $counts{$_}++ for grep { exists $counts{$_} } @page_store_abs_path_inputs;
        return [ sort grep { $_ > 0 } values %counts ];
    };
    is_deeply( $root_resolve_counts->(), [1], 'saved-page and nav path checks resolve each dashboards root once per request' );

    $candidate_roots_resolves = 0;
    my $next_response = $app->handle(
        path        => '/app/welcome',
        query       => '',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    );
    is( $next_response->[0], 200, 'the next request still loads the saved page normally' );
    is( $candidate_roots_resolves, 1, 'each saved-page request resolves its ordered page roots once' );
    is_deeply( $root_resolve_counts->(), [2], 'unchanged saved-page snapshots avoid page-root candidate scans while revalidating dashboard roots' );
}
is($code2b, 200, 'saved page with query state route ok');
like($body2b, qr/Michael/, 'query parameters are merged into page state during render');
like( $body2b, qr/<span id="static-nav-fixture">Static navigation<\/span>/,
    'static raw nav fragments preserve their literal HTML output' );
is_deeply( \@raw_nav_prepare_ids, ['nav/here.tt'],
    'literal static nav skips processing while dynamic raw nav remains processed' );
is_deeply( \@raw_nav_canonical_ids, ['nav/here.tt'],
    'literal static nav skips canonical-instruction serialization while dynamic raw nav retains it' );
like($body2b, qr{<li data-nav-id="nav/alpha\.tt"><a href="/app/index">Home</a></li>}s, 'shared nav TT fragments render conditional output against non-index pages');
like($body2b, qr/nav-current=\/app\/welcome nav-rt=\/app\/welcome/s, 'shared nav TT fragments receive the current page path on non-index pages');
like($body2b, qr/\.dashboard-nav-items ul \{\s*list-style: none;\s*margin: 0;\s*padding: 0;\s*display: flex;\s*flex-wrap: wrap;/s, 'shared nav renderer styles nav items as a wrapping horizontal row');
like($body2b, qr/\.dashboard-nav-items \{\s*margin: 0 0 24px;\s*padding: 14px 18px;\s*border: 1px solid var\(--line\);\s*background: var\(--panel/s, 'shared nav container inherits panel styling through CSS variables instead of a hardcoded pale background');
like($body2b, qr/\.dashboard-nav-items a \{\s*color: var\(--text, var\(--ink\)\);\s*text-decoration-color: var\(--accent, currentColor\);\s*\}/s, 'shared nav links inherit theme-aware foreground colors');
my $nav_pos = index($body2b, 'class="dashboard-nav-items"');
my $body_pos = index($body2b, '<section class="body">');
my $alpha_pos = index($body2b, 'data-nav-id="nav/alpha.tt"');
my $beta_pos = index($body2b, 'data-nav-id="nav/beta.tt"');
ok($nav_pos > -1 && $nav_pos < $body_pos, 'shared nav section renders before the main page body');
ok($alpha_pos > -1 && $beta_pos > $alpha_pos, 'shared nav tt bookmarks render in sorted filename order');
unlike($body2b, qr/display:flex;flex-direction:column/, 'shared nav markup no longer hardcodes a vertical inline flex layout');
unlike($body2, qr/id="play-button"/, 'render mode does not render play button');
like($body2, qr{href="/app/welcome/edit"[^>]+id="view-source-url"}, 'render mode view source points to edit route');

my $token = $saved_token;
my ($code3, $type3, $body3) = @{ $app->handle(path => '/', query => "mode=source&token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code3, 200, 'transient source route ok');
like($type3, qr/text\/plain/, 'source mode returns plain text instructions');
like($body3, qr/^TITLE:\s+Welcome/m, 'source mode returns canonical legacy instruction page');

my ($code4, $type4, $body4) = @{ $app->handle(path => '/app/legacy-welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code4, 200, 'legacy saved page route ok');
like($body4, qr/Hello World/, 'legacy placeholders render from stash state');
like($body4, qr{<head>.*<meta name="x-bookmark" content="legacy-head-injected">.*</head>}s, 'legacy bookmark-file HEAD content reaches the rendered document head');
like($body4, qr/Runtime/, 'trusted legacy code output is rendered on saved pages');
like($body4, qr/Right Click Copy &amp; Share or Bookmark This Page/, 'legacy render includes top chrome share link');
unlike($body4, qr/\{legacy-welcome:[^}]+\}/, 'top chrome does not dump shell prompt project context');
unlike($body4, qr/\[\w{3}\s+\w{3}/, 'top chrome does not dump shell prompt timestamps');
like($body4, qr/id="status-on-top"/, 'legacy render includes old top-status container');
like($body4, qr/class="user-name-and-icon"/, 'legacy render includes top-right user marker');
like($body4, qr/id="status-server"/, 'legacy render includes top-right server marker');
like($body4, qr/10\.20\.30\.40/, 'legacy render includes machine ip instead of request host');
like($body4, qr/id="status-datetime"/, 'legacy render includes live-updated date-time marker');

my ($status_code, $status_type, $status_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($status_code, 200, 'legacy status endpoint route ok');
like($status_type, qr/application\/json/, 'legacy status endpoint returns json');
like($status_body, qr/"array"\s*:/, 'legacy status endpoint returns array payload');
$config->save_global(
    {
        collectors => [
            {
                name      => 'vpn',
                code      => 'return 0;',
                cwd       => 'home',
                indicator => {
                    icon => '🔑',
                },
            },
        ],
    }
);
my ($status_icon_code, undef, $status_icon_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($status_icon_code, 200, 'legacy status endpoint still responds after syncing config-backed collector indicators');
like(decode('UTF-8', $status_icon_body), qr/"alias"\s*:\s*"🔑"/, 'legacy status endpoint exposes configured collector indicator icons instead of collector names');
like($app->_prompt_summary, qr/🔑/, 'page top-right prompt summary prefers the configured collector indicator icon');
my $status_indicator_list_calls = 0;
my $list_indicators = \&Developer::Dashboard::IndicatorStore::list_indicators;
my ( $single_list_status_code, undef, $single_list_status_body );
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::list_indicators = sub {
        $status_indicator_list_calls++;
        return $list_indicators->(@_);
    };
    ( $single_list_status_code, undef, $single_list_status_body ) =
      @{ $app->handle( path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
}
is( $single_list_status_code, 200, 'status route remains successful when sharing its collector inventory' );
is( $single_list_status_body, $status_icon_body, 'shared collector inventory preserves exact status response bytes' );
is( $status_indicator_list_calls, 0, 'unchanged configured status response reuses its validated payload without listing indicators again' );
$config->save_global_web_settings( no_editor => 1 );
my ($readonly_render_code, undef, $readonly_render_body) = @{ $app->handle(path => '/app/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_render_code, 200, 'no-editor mode still renders saved pages');
unlike($readonly_render_body, qr/id="share-url"/, 'no-editor mode hides the share link from render views');
unlike($readonly_render_body, qr/id="view-source-url"/, 'no-editor mode hides the view-source link from render views');
unlike($readonly_render_body, qr/id="play-button"/, 'no-editor mode hides the play button from render views');
my ($readonly_source_code, $readonly_source_type, $readonly_source_body) = @{ $app->handle(path => '/app/welcome/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_source_code, 403, 'no-editor mode blocks saved page source routes');
like($readonly_source_type, qr/text\/plain/, 'no-editor blocked source route returns plain text');
like($readonly_source_body, qr/read-only|no-editor/i, 'no-editor blocked source route explains the read-only restriction');
my ($readonly_edit_code, $readonly_edit_type, $readonly_edit_body) = @{ $app->handle(path => '/app/welcome/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_edit_code, 403, 'no-editor mode blocks saved page editor routes');
like($readonly_edit_type, qr/text\/plain/, 'no-editor blocked editor route returns plain text');
like($readonly_edit_body, qr/read-only|no-editor/i, 'no-editor blocked editor route explains the read-only restriction');
my $readonly_post_instruction = uri_escape("TITLE: Changed\n:--------------------------------------------------------------------------------:\nBOOKMARK: welcome\n:--------------------------------------------------------------------------------:\nHTML: changed\n");
my ($readonly_post_code, $readonly_post_type, $readonly_post_body) = @{ $app->handle(
    path        => '/app/welcome/edit',
    method      => 'POST',
    body        => 'instruction=' . $readonly_post_instruction,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($readonly_post_code, 403, 'no-editor mode blocks saved page editor POST saves');
like($readonly_post_type, qr/text\/plain/, 'no-editor blocked editor POST returns plain text');
like($readonly_post_body, qr/read-only|no-editor/i, 'no-editor blocked editor POST explains the read-only restriction');
my $welcome_after_block = $store->load_saved_page('welcome');
is($welcome_after_block->as_hash->{layout}{body}, 'hello from app [% stash.name %]', 'no-editor mode leaves the saved bookmark unchanged after a blocked POST');
my ($readonly_root_code, $readonly_root_type, $readonly_root_body, $readonly_root_headers) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_root_code, 302, 'no-editor mode still lets the root route redirect to a saved index page');
like($readonly_root_type, qr/text\/plain/, 'no-editor root redirect still returns the standard plain-text redirect body');
is($readonly_root_headers->{Location}, '/app/index', 'no-editor root redirect still targets the saved index page');
$config->save_global_web_settings( no_editor => 0 );
$config->save_global_web_settings( no_indicators => 1 );
my ($noind_render_code, undef, $noind_render_body) = @{ $app->handle(path => '/app/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($noind_render_code, 200, 'no-indicators mode still renders saved pages');
unlike($noind_render_body, qr/id="status-on-top"/, 'no-indicators mode hides the top-right indicator strip');
unlike($noind_render_body, qr/id="status-datetime"/, 'no-indicators mode hides the top-right date-time marker');
unlike($noind_render_body, qr/id="status-server"/, 'no-indicators mode hides the top-right server marker');
unlike($noind_render_body, qr/class="user-name-and-icon"/, 'no-indicators mode hides the top-right username marker');
like($app->_prompt_summary, qr/🔑/, 'no-indicators mode does not change prompt-summary data generation');
my ($noind_status_code, undef, $noind_status_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($noind_status_code, 200, 'no-indicators mode keeps the status endpoint available');
like(decode('UTF-8', $noind_status_body), qr/"alias"\s*:\s*"🔑"/, 'no-indicators mode keeps status endpoint indicator payloads intact');
$config->save_global_web_settings( no_indicators => 0 );
$config->save_global(
    {
        collectors => [
            {
                name      => 'vpn-renamed',
                code      => 'return 0;',
                cwd       => 'home',
                indicator => {
                    icon => '🔑',
                },
            },
        ],
    }
);
my ($status_rename_code, undef, $status_rename_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($status_rename_code, 200, 'legacy status endpoint still responds after a collector rename');
unlike($status_rename_body, qr/"prog"\s*:\s*"vpn"/, 'legacy status endpoint removes stale managed collector indicators after a collector rename');
like($status_rename_body, qr/"prog"\s*:\s*"vpn-renamed"/, 'legacy status endpoint keeps the renamed collector indicator');

my $legacy_token = $store->encode_page($legacy_page);
my ($code5, undef, $body5) = @{ $app->handle(path => '/', query => "mode=render&token=$legacy_token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code5, 200, 'legacy transient page route ok');
like($body5, qr/<div>Runtime<\/div>/, 'legacy transient pages execute CODE blocks through the same runtime');

my ($code5b, undef, $body5b) = @{ $app->handle(path => '/app/legacy-welcome', query => 'name=Michael', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code5b, 200, 'legacy /app route with query params ok');
like($body5b, qr/Hello Michael/, 'legacy /app bookmark merges request params into stash');

my $legacy_ajax_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Legacy Ajax
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-ajax
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'json', code => q{
  print j { ok => 1 };
}, file => 'demo.json';
PAGE
$store->save_page($legacy_ajax_page);

my ($code6, undef, $body6) = @{ $app->handle(path => '/app/legacy-ajax', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code6, 200, 'legacy /app route renders bookmark');
like($body6, qr/set_chain_value\(configs,'demo\.endpoint','\/ajax\/demo\.json\?type=json/, 'legacy Ajax helper injects a saved bookmark ajax endpoint when a file is supplied');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'ajax', 'demo.json' ), 'legacy Ajax helper stores the saved bookmark ajax code under the dashboards ajax tree' );

my ($code7, $type7, $body7) = @{ $app->handle(path => '/ajax/demo.json', query => "type=json", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7, 200, 'legacy ajax endpoint executes through the saved bookmark ajax file route');
like($type7, qr/application\/json/, 'legacy ajax endpoint returns json type');
like(drain_stream_body($body7), qr/"ok"\s*:\s*1/, 'legacy ajax endpoint returns encoded payload output as a stream');

my $existing_ajax_dir = File::Spec->catdir( $paths->dashboards_root, 'ajax' );
make_path($existing_ajax_dir);
my $existing_ajax_file = File::Spec->catfile( $existing_ajax_dir, 'existing.sh' );
open my $existing_ajax_fh, '>', $existing_ajax_file or die $!;
print {$existing_ajax_fh} "#!/bin/sh\nprintf 'existing-out\\n'\nprintf 'existing-err\\n' >&2\n";
close $existing_ajax_fh;
chmod 0700, $existing_ajax_file or die $!;

my $legacy_existing_ajax_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Legacy Existing Ajax
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-ajax-existing
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'text', file => 'existing.sh';
PAGE
$store->save_page($legacy_existing_ajax_page);

my ($code7b, undef, $body7b) = @{ $app->handle(path => '/app/legacy-ajax-existing', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7b, 200, 'legacy /app route renders bookmark that points at an existing ajax file');
like($body7b, qr/set_chain_value\(configs,'demo\.endpoint','\/ajax\/existing\.sh\?type=text/, 'legacy Ajax helper injects an existing saved bookmark ajax endpoint when only a file is supplied');
my $bootstrap_pos = index( $body7b, 'function set_chain_value' );
my $binding_pos   = index( $body7b, q{set_chain_value(configs,'demo.endpoint','/ajax/existing.sh?type=text'} );
ok( $bootstrap_pos > -1 && $binding_pos > $bootstrap_pos, 'legacy bootstrap is defined before saved Ajax bindings run in render mode' );

my ($code7d, $type7d, $body7d) = @{ $app->handle(path => '/ajax/existing.sh', query => "type=text", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7d, 200, 'saved bookmark ajax file route executes an existing ajax executable from the dashboards ajax tree');
like($type7d, qr/text\/plain/, 'existing ajax executable returns text type');
my $existing_stream = drain_stream_body($body7d);
like($existing_stream, qr/existing-out/, 'existing ajax executable streams stdout');
like($existing_stream, qr/existing-err/, 'existing ajax executable streams stderr');

my ($jquery_code, $jquery_type, $jquery_body) = @{ $app->handle(path => '/js/jquery.js', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($jquery_code, 200, 'built-in jquery bookmark helper route is available');
like($jquery_type, qr/application\/javascript/, 'built-in jquery bookmark helper route returns javascript');
like($jquery_body, qr/jQuery v4\.0\.0/, 'built-in jquery bookmark helper route ships the bundled jQuery 4 asset');
like($jquery_body, qr/define\("jquery"/, 'built-in jquery bookmark helper keeps the packaged jQuery module wrapper');
like($jquery_body, qr/e\.jQuery=e\.\$=T/, 'built-in jquery bookmark helper exposes jQuery on the window object');

my $legacy_jquery_ajax_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: test-jquery-ajax
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(_ => {
    $.ajax({
        url: foo.bar,
        type: 'GET',
        dataType: 'text',
        success: function (response) {
            $('.display').text(response);
        },
        error: function (xhr, status, error) {
            console.error(error);
        }
    });
});
</script>
TEST2: <span class=disply></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', file => 'foobar', code => q{
print 123
};
PAGE
$store->save_page($legacy_jquery_ajax_page);

my ($jquery_page_code, undef, $jquery_page_body) = @{ $app->handle(path => '/app/test-jquery-ajax', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($jquery_page_code, 200, 'legacy jquery ajax bookmark route renders');
like($jquery_page_body, qr{<script src="/js/jquery\.js"></script>}, 'legacy jquery ajax bookmark keeps the jquery helper script tag');
like($jquery_page_body, qr{set_chain_value\(foo,'bar','/ajax/foobar\?type=text'\)}, 'legacy jquery ajax bookmark binds foo.bar to the saved ajax endpoint with default text type');
my ($jquery_ajax_code, $jquery_ajax_type, $jquery_ajax_body) = @{ $app->handle(path => '/ajax/foobar', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($jquery_ajax_code, 200, 'legacy jquery ajax bookmark saved endpoint is executable');
like($jquery_ajax_type, qr/text\/plain/, 'legacy jquery ajax bookmark saved endpoint defaults to text content type when no type is supplied');
is(drain_stream_body($jquery_ajax_body), '123', 'legacy jquery ajax bookmark saved endpoint returns the code output');

my $fetch_stream_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: fetch-stream-helpers
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<span id="foo"></span><br>
<div id="bar"></div>
<span id="mike"></span><br>
<script>
var endpoints = {};
$(document).ready(function () {
  fetch_value(endpoints.foo, '#foo');
  stream_value(endpoints.bar, '#bar', { type: 'text' });
  fetch_value(endpoints.mike, '#mike', { type: 'json' }, function (value) {
    return value.ok > 0 ? 'OK' : 'Error';
  });
});
</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'endpoints.foo', file => 'foo', code => q{
  print "This is foo echo";
};
:--------------------------------------------------------------------------------:
CODE2: Ajax jvar => 'endpoints.bar', file => 'bar', singleton => 'BAR', code => q{
  print "bar-one\n";
  print "bar-two\n";
};
:--------------------------------------------------------------------------------:
CODE3: Ajax jvar => 'endpoints.mike', file => 'mike', type => 'json', code => q{
  use Developer::Dashboard::DataHelper qw( j );
  print j { ok => 1 };
};
PAGE
$store->save_page($fetch_stream_page);
my ($fetch_stream_code, undef, $fetch_stream_body) = @{ $app->handle(path => '/app/fetch-stream-helpers', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($fetch_stream_code, 200, 'legacy bookmark with fetch_value and stream_value helpers renders');
like($fetch_stream_body, qr/function fetch_value\(url, target, options, formatter\)/, 'legacy bookmark bootstrap exposes fetch_value helper');
like($fetch_stream_body, qr/function stream_value\(url, target, options, formatter\)/, 'legacy bookmark bootstrap exposes stream_value helper');
like($fetch_stream_body, qr/function stream_data\(url, target, options, formatter\)/, 'legacy bookmark bootstrap exposes stream_data helper');
like($fetch_stream_body, qr/new XMLHttpRequest\(\)/, 'legacy bookmark streaming helper uses XMLHttpRequest for progressive browser updates');
like($fetch_stream_body, qr/xhr\.onprogress = function \(\)/, 'legacy bookmark streaming helper updates targets from incremental ajax progress events');
my $foo_bind_pos = index($fetch_stream_body, q{set_chain_value(endpoints,'foo','/ajax/foo?type=text'});
my $bar_bind_pos = index($fetch_stream_body, q{set_chain_value(endpoints,'bar','/ajax/bar?type=text&singleton=BAR'});
my $mike_bind_pos = index($fetch_stream_body, q{set_chain_value(endpoints,'mike','/ajax/mike?type=json'});
my $endpoints_decl_pos = index($fetch_stream_body, q{var endpoints = {};});
my $fetch_call_pos = index($fetch_stream_body, q{fetch_value(endpoints.foo, '#foo');});
ok($foo_bind_pos > -1 && $bar_bind_pos > -1 && $mike_bind_pos > -1, 'legacy bookmark render includes all saved Ajax endpoint bindings for fetch_value and stream_value');
ok($endpoints_decl_pos > -1, 'legacy bookmark render keeps the caller endpoint variable declaration');
ok($foo_bind_pos > $endpoints_decl_pos && $bar_bind_pos > $endpoints_decl_pos && $mike_bind_pos > $endpoints_decl_pos, 'saved Ajax endpoint bindings render after the caller declares the endpoint root object');
ok($fetch_call_pos > -1, 'legacy bookmark render keeps the inline fetch helper call');
like($fetch_stream_body, qr/dashboard_ajax_singleton_cleanup\('BAR'\)/, 'legacy bookmark render keeps singleton cleanup bindings for stream_value pages');

my $stream_data_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: stream-data-helper
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(function () {
  stream_data(foo.bar, '.display');
});
</script>
TEST2: <span class=display></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', singleton => 'FOOBAR', file => 'foobar', code => q{
    while (1) {
      print 123;
      sleep 1;
    }
};
PAGE
$store->save_page($stream_data_page);
my ($stream_data_code, undef, $stream_data_body) = @{ $app->handle(path => '/app/stream-data-helper', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($stream_data_code, 200, 'legacy bookmark with stream_data helper renders');
like($stream_data_body, qr{stream_data\(foo\.bar, '\.display'\);}, 'legacy bookmark render keeps the inline stream_data helper call');
like($stream_data_body, qr{set_chain_value\(foo,'bar','/ajax/foobar\?type=text&singleton=FOOBAR'\)}, 'legacy bookmark render binds stream_data ajax endpoint before browser execution');

{
    open my $fh, '>', $store->page_file('legacy-forward') or die $!;
    print {$fh} '/ajax/demo.json?type=text';
    close $fh;
}
my $raw_named_page = eval { $app->_load_named_page('legacy-forward') };
ok(!defined($raw_named_page) && !$@, 'saved URL entries do not leak PageDocument section errors through named-page loading');
my ($code8, $type8, $body8) = @{ $app->handle(path => '/app/legacy-forward', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code8, 200, 'legacy /app saved-url forwarding works');
like($type8, qr/text\/plain/, 'forwarded saved-url bookmark preserves content type');
like(drain_stream_body($body8), qr/"ok"\s*:\s*1/, 'forwarded saved-url bookmark reaches ajax payload through the stream response');

{
    open my $fh, '>', $store->page_file('legacy-external-forward') or die $!;
    print {$fh} 'https://example.test/bookmark?from=saved';
    close $fh;
}
my ($external_code, $external_type, $external_body, $external_headers) = @{ $app->handle(
    path        => '/app/legacy-external-forward',
    query       => 'from=request',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($external_code, 302, 'legacy external URL bookmark redirects');
like($external_type, qr/text\/plain/, 'external URL redirect uses a plain response');
is($external_headers->{Location}, 'https://example.test/bookmark?from=saved&from=request', 'external URL redirect appends the incoming query');
is($external_body, "Redirecting\n", 'external URL redirect has a concise body');

my $selected_forward = $app->_legacy_app_response(
    id            => 'legacy-forward',
    query_params  => { choice => [qw(first second)], 'choice.selected.pos' => 1 },
    body_params   => {},
    remote_addr   => '127.0.0.1',
    headers       => { host => '127.0.0.1' },
);
ok($selected_forward->[0], 'legacy URL forwarding resolves selected array parameters');
my %selected_params = ( choice => [qw(first second)], 'choice.selected.pos' => 1 );
Developer::Dashboard::Web::App::_resolve_legacy_selected_params(\%selected_params);
is($selected_params{choice}, 'second', 'legacy selected.pos forwards the selected array value');

for my $case (
    [ 'legacy-unsupported-scheme', 'ftp://example.test/file', 400, 'Unsupported bookmark URL scheme' ],
    [ 'legacy-empty-target', '', 400, 'Invalid bookmark target' ],
) {
    open my $fh, '>', $store->page_file($case->[0]) or die $!;
    print {$fh} $case->[1];
    close $fh;
    my ( $status, undef, $body ) = @{ $app->handle(
        path        => '/app/' . $case->[0],
        query       => '',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is($status, $case->[2], "$case->[0] is rejected");
    like($body, qr/\Q$case->[3]\E/, "$case->[0] explains the rejection");
}
my ( $fallback_redirect_status, undef, $fallback_redirect_body, $fallback_redirect_headers ) =
  @{ $app->_legacy_external_redirect_response( target => 'https://example.test/fallback', params => { a => '1' } ) };
is($fallback_redirect_status, 302, 'external redirect can build a query from parsed parameters');
is($fallback_redirect_headers->{Location}, 'https://example.test/fallback?a=1', 'parsed parameters are appended when raw query is absent');
is($fallback_redirect_body, "Redirecting\n", 'parsed-parameter redirect uses the standard body');
my ($control_query_status) =
  @{ $app->_legacy_external_redirect_response( target => 'https://example.test/fallback', raw_query => "bad\nquery" ) };
is($control_query_status, 400, 'external redirect rejects control characters in the incoming query');
my %not_a_hash;
is(Developer::Dashboard::Web::App::_resolve_legacy_selected_params(undef), undef, 'selected parameter helper ignores an undefined input');
Developer::Dashboard::Web::App::_resolve_legacy_selected_params(\%not_a_hash);
is_deeply(\%not_a_hash, {}, 'selected parameter helper leaves an empty hash unchanged');
my %invalid_selection = (
    plain => 'value',
    scalar => 'value',
    'scalar.selected.pos' => 0,
    array => [qw(one)],
    'array.selected.pos' => 'not-a-number',
    out_of_range => [qw(one)],
    'out_of_range.selected.pos' => 2,
);
Developer::Dashboard::Web::App::_resolve_legacy_selected_params(\%invalid_selection);
is($invalid_selection{array}[0], 'one', 'invalid selected.pos leaves array parameters unchanged');
is_deeply($invalid_selection{out_of_range}, ['one'], 'out-of-range selected.pos leaves array parameters unchanged');

{
    open my $fh, '>', $store->page_file('legacy-forward-override') or die $!;
    print {$fh} '/ajax/demo.json?type=text&status=default';
    close $fh;
}
my ($code9, undef, $body9) = @{ $app->handle(path => '/app/legacy-forward-override', query => 'status=override', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code9, 200, 'legacy /app saved-url forwarding with override works');
like(drain_stream_body($body9), qr/"ok"\s*:\s*1/, 'forwarded saved-url override still reaches ajax payload through the stream response');

{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 0;
    my $manual_ajax_token = uri_escape( encode_payload(q{print j { blocked => 1 };}) );
    my ($blocked_ajax_code, $blocked_ajax_type, $blocked_ajax_body) = @{ $app->handle(path => '/ajax', query => "token=$manual_ajax_token&type=json", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
    is($blocked_ajax_code, 403, 'legacy ajax token route is denied when transient token URLs are disabled');
    like($blocked_ajax_type, qr/text\/plain/, 'legacy ajax token denial returns plain text');
    like($blocked_ajax_body, qr/Transient token URLs are disabled/, 'legacy ajax token denial explains the policy');
}
{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    my $manual_ajax_token = uri_escape( encode_payload(q{die "token ajax died\n";}) );
    my ($manual_ajax_error_code, $manual_ajax_error_type, $manual_ajax_error_body) = @{ $app->handle(path => '/ajax', query => "token=$manual_ajax_token&type=text", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
    is($manual_ajax_error_code, 200, 'legacy ajax token runtime errors still return the streaming response shape');
    like($manual_ajax_error_type, qr/text\/plain/, 'legacy ajax token runtime errors keep the requested content type');
    like(drain_stream_body($manual_ajax_error_body), qr/token ajax died/, 'legacy ajax token runtime errors stream the runtime error text');
}

my $script_breakout_source = join "\n",
    'BOOKMARK: script-breakout',
    ':--------------------------------------------------------------------------------:',
    q{HTML: <script src="/js/jquery.js"></script>},
    q{<script>console.log("hello")</script>},
    ':--------------------------------------------------------------------------------:',
    q{CODE1: print 123;},
    '';
my ($script_breakout_code, undef, $script_breakout_body) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($script_breakout_source),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($script_breakout_code, 200, 'editor route handles source containing literal script tags');
like($script_breakout_body, qr{<textarea[^>]*>[\s\S]*&lt;script src="/js/jquery\.js"&gt;&lt;/script&gt;[\s\S]*</textarea>}m, 'editor textarea keeps literal script tags escaped in source view');
like($script_breakout_body, qr/ddSource\.value = ".*\\u003c\/script\\u003e.*"\s*;\s*ddLoadBlocks\(ddSource\.value\);/s, 'editor boot script escapes closing script tags inside the hidden JSON-backed source assignment before block loading');
unlike($script_breakout_body, qr{</html>\s*[\s\S]*ddRenderEditor}m, 'editor boot script text does not leak into the rendered page body');

$auth->add_user( username => 'helper_user', password => 'helper-pass-123' );
my $helper_session = $sessions->create(
    username    => 'helper_user',
    role        => 'helper',
    remote_addr => '10.0.0.2',
);
my $helper_cookie = 'dashboard_session=' . $helper_session->{session_id};

my ($code10, undef, $body10) = @{ $app->handle(
    path        => '/app/welcome',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => '10.0.0.3:7890', cookie => $helper_cookie },
) };
is($code10, 200, 'helper route with session ok');
like($body10, qr/id="logout-url"/, 'helper route renders logout link');
like($body10, qr/class="user-name-and-icon".*helper_user/s, 'helper route shows helper username in the top chrome');

my $index_file = $store->page_file('index');
unlink $index_file if -f $index_file;
my ($code10b, undef, $body10b) = @{ $app->handle(
    path        => '/',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => '10.0.0.3:7890', cookie => $helper_cookie },
) };
is($code10b, 200, 'helper root route with session ok');
like($body10b, qr/id="logout-url"/, 'helper root blank editor renders logout link');
like($body10b, qr/class="user-name-and-icon".*helper_user/s, 'helper root blank editor shows helper username in the top chrome');

my ($code11, undef, $body11, $headers11) = @{ $app->handle(
    path        => '/logout',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => '10.0.0.3:7890', cookie => $helper_cookie },
) };
is($code11, 302, 'helper logout redirects');
like($body11, qr/Redirecting/, 'helper logout returns redirect body');
is($headers11->{Location}, '/login', 'helper logout redirects to login');
like($headers11->{'Set-Cookie'}, qr/dashboard_session=;/, 'helper logout expires session cookie');
ok(!defined $auth->get_user('helper_user'), 'helper logout removes helper account');
ok(!defined $sessions->get($helper_session->{session_id}), 'helper logout removes helper session');

is(
    $app->_custom_skill_route_response( route_path => '/' ),
    undef,
    '_custom_skill_route_response ignores the root path so custom fallback only runs after smart routing misses',
);

{
    package Local::UnknownRouteDispatcher;
    sub resolve_custom_route_path { return { kind => 'bogus' } }
    package main;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::UnknownRouteDispatcher' };
    is(
        $app->_custom_skill_route_response( route_path => '/bogus/custom/path' ),
        undef,
        '_custom_skill_route_response returns undef when custom route metadata resolves to an unsupported route kind',
    );
}

{
    package Local::UnknownSkillOwnedRouteDispatcher;
    sub resolve_custom_route_path { return { kind => 'bogus', skill_name => 'example-skill' } }
    package main;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::UnknownSkillOwnedRouteDispatcher' };
    is(
        $app->_custom_skill_route_response( route_path => '/bogus/skill/path' ),
        undef,
        '_custom_skill_route_response also returns undef when one skill-owned custom route resolves to an unsupported route kind',
    );
}

{
    package Local::RuntimeAjaxAliasDispatcher;
    sub resolve_custom_route_path { return { kind => 'ajax', ajax_file => 'runtime/status' } }
    package main;
    my @captured;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::RuntimeAjaxAliasDispatcher' };
    local *Developer::Dashboard::Web::App::dispatch_request = sub {
        my ( $self, %args ) = @_;
        push @captured, $args{path};
        return [ 200, 'text/plain; charset=utf-8', "runtime ajax alias\n" ];
    };
    is_deeply(
        $app->_custom_skill_route_response( route_path => '/runtime/status' ),
        [ 200, 'text/plain; charset=utf-8', "runtime ajax alias\n" ],
        '_custom_skill_route_response dispatches runtime ajax aliases back through the built-in ajax route family',
    );
    is_deeply( \@captured, ['/ajax/runtime/status'], 'runtime ajax aliases dispatch to the matching built-in ajax path' );
}

{
    package Local::RuntimeStaticAliasDispatcher;
    sub resolve_custom_route_path { return { kind => 'js', file => 'site/main.js' } }
    package main;
    my @captured;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::RuntimeStaticAliasDispatcher' };
    local *Developer::Dashboard::Web::App::dispatch_request = sub {
        my ( $self, %args ) = @_;
        push @captured, $args{path};
        return [ 200, 'application/javascript', "console.log('runtime static alias');\n" ];
    };
    is_deeply(
        $app->_custom_skill_route_response( route_path => '/runtime/main.js' ),
        [ 200, 'application/javascript', "console.log('runtime static alias');\n" ],
        '_custom_skill_route_response dispatches runtime static aliases back through the built-in static route families',
    );
    is_deeply( \@captured, ['/js/site/main.js'], 'runtime static aliases dispatch to the matching built-in static path' );
}

is_deeply(
    $app->_serve_static_file_at_path( 'css', 'missing.css', '' ),
    [ 404, 'text/plain; charset=utf-8', "Not Found\n" ],
    '_serve_static_file_at_path returns an explicit 404 when the caller does not resolve a readable asset path',
);

{
    package Local::Problem48ConfigSnapshotWatch;

    sub new { return bless { stable => 0, paths => [], signature => undef }, $_[0] }

    sub configure {
        my ( $self, $signature, $paths ) = @_;
        $self->{signature} = $signature;
        $self->{paths} = [ @{$paths} ];
        $self->{stable} = 1;
        return 1;
    }

    sub unchanged {
        my ( $self, $signature ) = @_;
        return 0 if !defined $self->{signature} || $self->{signature} ne $signature;
        return $self->{stable} ? 1 : 0;
    }

    sub invalidate { $_[0]->{stable} = 0; return 1 }

    sub last_error { return }
    sub close { $_[0]->{closed}++; return 1 }
}

{
    package Local::Problem48EmptySkillDispatcher;

    sub all_skill_nav_literal_items_html { return undef }
    sub all_skill_nav_pages { return [] }
}

{
    package Local::Problem48MergedConfig;
}

{
    package Local::Problem48PortableConfig;

    sub _global_config_files { return ( $_[0]->{file} ) }
}

{
    package Local::Problem48PortablePaths;

    sub installed_skill_entries { return @{ $_[0]->{skills} || [] } }
    sub current_project_root { return $_[0]->{project_root} }
}

{
    package Local::Problem48NoConfigMethods;
}

{
    package Local::Problem48NoPathMethods;
}

{
    package Local::Problem48RejectingWatch;

    sub configure { return 0 }
}

{
    package Local::Problem48ReportedRejectingWatch;

    sub configure { return 0 }
    sub last_error { return 'injected watcher setup failure' }
}

{
    package Local::Problem48EmptyErrorRejectingWatch;

    sub configure { return 0 }
    sub last_error { return '' }
}

{
    package Local::Problem48FixedWatch;

    sub configure { return 1 }
    sub unchanged { return $_[0]->{unchanged} }
}

{
    package Local::Problem48BoundaryPaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub current_working_directory { return $_[0]->{cwd} }
    sub home { return $_[0]->{home} }
    sub current_project_root { return $_[0]->{project_root} }
    sub _same_or_descendant_path { return $_[1] =~ m{\A\Q$_[2]\E(?:/|\z)} ? 1 : 0 }
    sub _path_identity { return $_[1] }
    sub installed_skill_entries { return }
    sub nested_skill_entries { return }
}

{
    package Local::Problem48PartialPaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
}

{
    package Local::Problem48SkillEntryPaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub installed_skill_entries { return @{ $_[0]->{installed} } }
    sub nested_skill_entries { return @{ $_[0]->{nested} } }
}

{
    package Local::Problem48RootPaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub current_working_directory { return $_[0]->{cwd} }
    sub home { return $_[0]->{home} }
    sub _same_or_descendant_path { return 1 }
    sub _path_identity { return $_[1] }
}

{
    package Local::Problem48NoHomePaths;
}

{
    package Local::Problem48NoIdentityPaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub current_working_directory { return $_[0]->{cwd} }
    sub home { return $_[0]->{home} }
    sub _same_or_descendant_path { return 1 }
}

{
    package Local::Problem48NoSamePaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub current_working_directory { return $_[0]->{cwd} }
    sub home { return $_[0]->{home} }
    sub current_project_root { return $_[0]->{project_root} }
}

{
    package Local::Problem48OutsidePaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub current_working_directory { return $_[0]->{cwd} }
    sub home { return $_[0]->{home} }
    sub current_project_root { return $_[0]->{project_root} }
    sub _same_or_descendant_path { return 0 }
}

{
    package Local::Problem48ProjectPaths;

    sub runtime_roots { return @{ $_[0]->{runtime_roots} } }
    sub config_roots { return @{ $_[0]->{config_roots} } }
    sub skills_roots { return @{ $_[0]->{skills_roots} } }
    sub current_working_directory { return $_[0]->{cwd} }
    sub home { return $_[0]->{home} }
    sub current_project_root { return $_[0]->{project_root} }
    sub _same_or_descendant_path { return $_[0]->{inside} }
    sub _path_identity { return $_[1] }
}

package main;

done_testing;

__END__

=head1 NAME

03-web-app.t - basic web application route tests

=head1 DESCRIPTION

This test verifies the local web app home, saved bookmark rendering (including
raw C<HEAD> content in the document head), editor syntax highlighting,
transient source routes, and request-local runtime-layer, path-identity, and
template-service scopes. It also covers the status configuration snapshot
watcher's cache-hit, invalidation, setup-failure, and runtime/project-boundary
cases, plus the portable validator's unchanged cache hit, same-size config
edit, and skill config file creation/removal when the native backend is
unavailable. It verifies that normalized indicator
collectors are reused only for an unchanged watched configuration and that a
checker-filter change alters the cache signature. It protects the static
raw-nav fast path while confirming dynamic Template Toolkit nav fragments
still receive request context.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the local web application and server-facing routes. It verifies that one request shares one merged settings/config snapshot across authorization, page chrome, and collector assembly; that the optional native watcher safely reuses, invalidates, or declines to cache snapshots; that path discovery stays inside home/project boundaries; that canonical path identities are scoped to a request and discarded afterward; and that a later request observes changed settings. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the local web application and server-facing routes has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the local web application and server-facing routes, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it in the Docker development service with
C<d2 docker compose exec dev prove -lv t/03-web-app.t> while iterating, then
keep it green under the full suite and coverage gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec dev prove -lv t/03-web-app.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  d2 docker compose exec dev perl -e 'exec q{perl}, q{/work/script/coverage-gate}, q{t/03-web-app.t} or die $!'

Run the repository coverage gate for the app test's reached library code.

Example 3:

  d2 docker compose exec dev perl -e 'exec q{perl}, q{/work/script/coverage-gate} or die $!'

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
