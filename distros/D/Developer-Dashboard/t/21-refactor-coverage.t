use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use Encode qw(decode_utf8);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::SeededPages ();
use Developer::Dashboard::CLI::Query ();
use Developer::Dashboard::CLI::Ticket ();
use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::Collector;
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::Config;
use Developer::Dashboard::DockerCompose;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::Runtime::Result ();
use Developer::Dashboard::SeedSync ();
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;

my $repo_root = getcwd();

sub _portable_path {
    my ($path) = @_;
    return undef if !defined $path;
    my $resolved = eval { abs_path($path) };
    return defined $resolved && $resolved ne '' ? $resolved : $path;
}

sub is_same_path {
    my ( $got, $expected, $label ) = @_;
    is( _portable_path($got), _portable_path($expected), $label );
}

sub _portable_paths {
    return [ map { _portable_path($_) } @_ ];
}

sub _portable_cdr_payload {
    my ($payload) = @_;
    return {
        target  => _portable_path( $payload->{target} ),
        matches => _portable_paths( @{ $payload->{matches} || [] } ),
    };
}

local $ENV{HOME} = tempdir( CLEANUP => 1 );

my $paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );

is( $paths->app_name, 'developer-dashboard', 'path registry exposes the default app name' );
is( $paths->register_named_paths('nope'), $paths, 'register_named_paths ignores non-hash input' );
is( $paths->unregister_named_path(''), $paths, 'unregister_named_path ignores empty names' );
is_deeply( $paths->named_paths, {}, 'named_paths starts empty' );
is_deeply(
    $paths->all_paths,
    {
        home                 => $paths->home,
        home_runtime_root    => $paths->home_runtime_root,
        project_runtime_root => scalar $paths->project_runtime_root,
        runtime_root         => $paths->runtime_root,
        state_root           => $paths->state_root,
        cache_root           => $paths->cache_root,
        logs_root            => $paths->logs_root,
        dashboards_root      => $paths->dashboards_root,
        bookmarks_root       => $paths->bookmarks_root,
        cli_root             => $paths->cli_root,
        collectors_root      => $paths->collectors_root,
        indicators_root      => $paths->indicators_root,
        config_root          => $paths->config_root,
        current_project_root => scalar $paths->current_project_root,
    },
    'all_paths returns the same full runtime path inventory exposed by dashboard paths',
);
is_deeply(
    $paths->all_path_aliases,
    {
        home            => $paths->home,
        home_runtime    => $paths->home_runtime_root,
        project_runtime => scalar $paths->project_runtime_root,
        runtime         => $paths->runtime_root,
        state           => $paths->state_root,
        cache           => $paths->cache_root,
        logs            => $paths->logs_root,
        dashboards      => $paths->dashboards_root,
        bookmarks       => $paths->bookmarks_root,
        cli             => $paths->cli_root,
        config          => $paths->config_root,
        collectors      => $paths->collectors_root,
        indicators      => $paths->indicators_root,
    },
    'all_path_aliases returns the same alias inventory exposed by dashboard path list',
);
{
    my $from_folder = Developer::Dashboard::PathRegistry->new_from_all_folders;
    isa_ok( $from_folder, 'Developer::Dashboard::PathRegistry', 'new_from_all_folders returns a PathRegistry object' );
    is_deeply(
        $from_folder->all_paths,
        Developer::Dashboard::Folder->all,
        'new_from_all_folders rehydrates a PathRegistry from the public Folder path inventory',
    );
}
{
    my $collector_from_folder = Developer::Dashboard::Collector->new_from_all_folders;
    isa_ok( $collector_from_folder, 'Developer::Dashboard::Collector', 'Collector new_from_all_folders returns a collector store' );
    is_deeply(
        $collector_from_folder->collector_paths('sample')->{dir},
        Developer::Dashboard::Collector->new(
            paths => Developer::Dashboard::PathRegistry->new_from_all_folders,
        )->collector_paths('sample')->{dir},
        'Collector new_from_all_folders uses the same Folder-derived path registry as the explicit constructor',
    );
}
is( $paths->resolve_any('missing-one', 'missing-two'), undef, 'resolve_any returns undef when nothing exists' );
is( $paths->is_home_runtime_path(''), 0, 'is_home_runtime_path rejects empty input' );
is( $paths->is_home_runtime_path('/tmp/outside'), 0, 'is_home_runtime_path rejects non-home runtime paths' );
is( $paths->secure_dir_permissions('/tmp/outside'), '/tmp/outside', 'secure_dir_permissions ignores non-home runtime paths' );
is( $paths->secure_file_permissions('/tmp/outside-file'), '/tmp/outside-file', 'secure_file_permissions ignores non-home runtime files' );
ok( -d $paths->cache_root, 'cache_root creates the cache directory' );
ok( -d $paths->temp_root, 'temp_root creates the temp directory' );
ok( -d $paths->sessions_root, 'sessions_root creates the sessions directory' );
ok( -d $paths->skill_root('alpha-skill'), 'skill_root creates an isolated skill directory' );
is( $paths->_expand_home(undef), undef, '_expand_home leaves undef untouched' );
like(
    _dies( sub { $paths->skill_root('') } ),
    qr/Missing skill name/,
    'skill_root rejects an empty skill name',
);
{
    my $search_root = File::Spec->catdir( $ENV{HOME}, 'locate-dirs-under-root' );
    my $match_one   = File::Spec->catdir( $search_root, 'team-alpha' );
    my $match_two   = File::Spec->catdir( $search_root, 'nested', 'team-alpha-red' );
    my $no_match    = File::Spec->catdir( $search_root, 'nested', 'team-blue' );
    make_path( $match_one, $match_two, $no_match );

    is_deeply(
        _portable_paths( $paths->locate_dirs_under( $search_root, 'team', 'alpha' ) ),
        _portable_paths( sort ( $match_one, $match_two ) ),
        'locate_dirs_under returns every directory beneath the search root whose path matches all keywords',
    );
    is_deeply(
        _portable_paths( $paths->locate_dirs_under( $search_root, 'alpha', 'red' ) ),
        _portable_paths($match_two),
        'locate_dirs_under narrows to one nested directory when only one path matches every keyword',
    );
    is_deeply(
        _portable_paths( $paths->locate_dirs_under( $search_root, 'team', 'alpha$' ) ),
        _portable_paths($match_one),
        'locate_dirs_under treats each keyword as a regex so alpha$ matches team-alpha but not team-alpha-red',
    );
    like(
        _dies( sub { $paths->locate_dirs_under( $search_root, 'broken(' ) } ),
        qr/Invalid regex 'broken\('/,
        'locate_dirs_under reports invalid regex keywords explicitly',
    );

    my $restricted_parent = File::Spec->catdir( $search_root, 'restricted' );
    my $restricted_match   = File::Spec->catdir( $restricted_parent, 'team-alpha-hidden' );
    my $visible_match      = File::Spec->catdir( $search_root, 'visible', 'team-alpha-public' );
    make_path( $restricted_match, $visible_match );
    chmod 0000, $restricted_parent or die "Unable to chmod $restricted_parent: $!";
    my $restricted_effectively_unreadable = !opendir( my $restricted_dh, $restricted_parent );
    closedir($restricted_dh) if !$restricted_effectively_unreadable;
    my ( $restricted_stdout, $restricted_stderr ) = capture {
        my @matches = $paths->locate_dirs_under( $search_root, 'team', 'alpha' );
        print join "\n", @matches;
    };
    chmod 0700, $restricted_parent or die "Unable to restore chmod on $restricted_parent: $!";
    is( $restricted_stderr, '', 'locate_dirs_under skips unreadable subdirectories without printing permission errors' );
    like(
        $restricted_stdout,
        qr/\Q$visible_match\E/,
        'locate_dirs_under still returns readable sibling matches when one subtree is unreadable',
    );
    if ($restricted_effectively_unreadable) {
        unlike(
            $restricted_stdout,
            qr/\Q$restricted_match\E/,
            'locate_dirs_under skips matches hidden behind unreadable subdirectories',
        );
    }
    else {
        pass('locate_dirs_under unreadable-subdirectory exclusion is skipped when the current user can still read chmod 0000 directories, such as root inside the blank install gate');
    }
}
{
    my $docker = Developer::Dashboard::DockerCompose->new(
        config => bless( {}, 'Local::DockerConfigStub' ),
        paths  => $paths,
    );
    is(
        $docker->_home_docker_config_root,
        File::Spec->catdir( $paths->home_runtime_root, 'config', 'docker' ),
        'DockerCompose resolves the home docker config root beneath the home runtime',
    );

    my $compose_only_root = tempdir( CLEANUP => 1 );
    my $compose_only_service_root = File::Spec->catdir( $compose_only_root, 'redis' );
    make_path($compose_only_service_root);
    my $compose_only_file = File::Spec->catfile( $compose_only_service_root, 'compose.yml' );
    _write_file( $compose_only_file, "services: {}\n" );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub {
            return ($compose_only_root);
        };
        is_deeply(
            [ $docker->_discover_service_files( service => 'redis', project_root => $compose_only_root ) ],
            [$compose_only_file],
            'DockerCompose falls back to compose.yml when a service folder has no development.compose.yml',
        );
    }

    my $missing_service_root = tempdir( CLEANUP => 1 );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub {
            return ($missing_service_root);
        };
        is(
            $docker->_service_folder_is_disabled( service => 'redis', project_root => $missing_service_root ),
            0,
            'DockerCompose leaves services enabled when lookup roots exist but the service folder itself is absent',
        );
    }
}
{
    my $config_home = tempdir( CLEANUP => 1 );
    my $config_cwd  = tempdir( CLEANUP => 1 );
    my $cwd         = getcwd();
    chdir $config_cwd or die "Unable to chdir to $config_cwd: $!";

    my $config_paths = Developer::Dashboard::PathRegistry->new( home => $config_home );
    my $config_files = Developer::Dashboard::FileRegistry->new( paths => $config_paths );
    my $config       = Developer::Dashboard::Config->new( files => $config_files, paths => $config_paths );
    my $config_file  = $config_files->global_config;

    ok( !-e $config_file, 'ensure_global_file starts from a missing config.json path in the direct unit coverage case' );
    is_same_path( $config->ensure_global_file, $config_file, 'ensure_global_file returns the writable global config path when creating the file' );
    ok( -f $config_file, 'ensure_global_file creates config.json when it is missing' );
    is_deeply( json_decode( do { local $/; open my $fh, '<', $config_file or die $!; <$fh> } ), {}, 'ensure_global_file writes an empty JSON object when bootstrapping a missing config file' );

    _write_file( $config_file, qq|{"collectors":[{"name":"keep.me"}]}\n| );
    is_same_path( $config->ensure_global_file, $config_file, 'ensure_global_file still returns the config path when the file already exists' );
    is_deeply(
        json_decode( do { local $/; open my $fh, '<', $config_file or die $!; <$fh> } ),
        { collectors => [ { name => 'keep.me' } ] },
        'ensure_global_file leaves an existing config.json untouched',
    );

    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}

is_deeply(
    Developer::Dashboard::InternalCLI::helper_aliases(),
    {
        pjq   => 'jq',
        pyq   => 'yq',
        ptomq => 'tomq',
        pjp   => 'propq',
    },
    'internal CLI exposes the expected helper aliases',
);
is( Developer::Dashboard::InternalCLI::canonical_helper_name('pjq'), 'jq', 'legacy helper alias normalizes to jq' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('xmlq'), 'xmlq', 'current helper name stays unchanged' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('ticket'), 'ticket', 'ticket helper name stays unchanged' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('paths'), 'paths', 'paths helper name stays unchanged' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('bogus'), '', 'unsupported helper names normalize to empty string' );
is(
    Developer::Dashboard::SeedSync::content_md5("abc\n"),
    '0bee89b07a248e27c83fc3d5951213c1',
    'SeedSync content_md5 returns the expected md5 for simple content',
);
ok(
    Developer::Dashboard::SeedSync::same_content_md5("abc\n", "abc\n"),
    'SeedSync same_content_md5 reports matching payloads as identical',
);
ok(
    !Developer::Dashboard::SeedSync::same_content_md5("abc\n", "abcd\n"),
    'SeedSync same_content_md5 reports different payloads as different',
);
is(
    Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $paths ),
    File::Spec->catfile( $paths->config_root, 'seeded-pages.json' ),
    'SeededPages stores the managed seed manifest under the active runtime config root',
);
{
    my $api_dashboard_page = Developer::Dashboard::CLI::SeededPages::page_for_id('api-dashboard');
    isa_ok( $api_dashboard_page, 'Developer::Dashboard::PageDocument', 'page_for_id loads one shipped seeded page document' );
    is( $api_dashboard_page->as_hash->{id}, 'api-dashboard', 'page_for_id returns the seeded page requested by id' );
}
{
    my $sql_dashboard_page = Developer::Dashboard::CLI::SeededPages::sql_dashboard_page();
    isa_ok( $sql_dashboard_page, 'Developer::Dashboard::PageDocument', 'sql_dashboard_page loads the shipped SQL dashboard bookmark definition' );
    is( $sql_dashboard_page->as_hash->{id}, 'sql-dashboard', 'sql_dashboard_page returns the shipped SQL dashboard bookmark id' );
}
ok(
    Developer::Dashboard::CLI::SeededPages::is_known_managed_page_md5(
        id  => 'sql-dashboard',
        md5 => '7d9101e0e2585c159e575f0dbd49b3ef',
    ),
    'SeededPages recognizes the pre-refresh shipped sql-dashboard digest as dashboard-managed for upgrade bridging',
);
ok(
    Developer::Dashboard::CLI::SeededPages::is_known_managed_page_md5(
        id  => 'sql-dashboard',
        md5 => 'f62a03c9ff7d25cdce65ce569cf2e07b',
    ),
    'SeededPages recognizes the older home-runtime sql-dashboard splitter digest as dashboard-managed for upgrade bridging',
);
ok(
    Developer::Dashboard::CLI::SeededPages::is_known_managed_page_md5(
        id  => 'sql-dashboard',
        md5 => '10a14e5749f374a78429654b6c49b5f0',
    ),
    'SeededPages recognizes the older hov1 sql-dashboard splitter digest as dashboard-managed for upgrade bridging',
);
ok(
    !Developer::Dashboard::CLI::SeededPages::is_known_managed_page_md5(
        id  => 'sql-dashboard',
        md5 => 'ffffffffffffffffffffffffffffffff',
    ),
    'SeededPages rejects unknown sql-dashboard digests from automatic refresh',
);
{
    my $shared_root = tempdir( CLEANUP => 1 );
    my $shared_seeded_pages_root = File::Spec->catdir( $shared_root, 'seeded-pages' );
    make_path($shared_seeded_pages_root);
    my $shared_seeded_page = File::Spec->catfile( $shared_seeded_pages_root, 'api-dashboard.page' );
    _write_file(
        $shared_seeded_page,
        Developer::Dashboard::CLI::SeededPages::api_dashboard_page()->canonical_instruction,
    );

    local *Developer::Dashboard::CLI::SeededPages::_repo_seeded_pages_root = sub {
        return File::Spec->catdir( $shared_root, 'missing-repo-seeded-pages' );
    };
    local *Developer::Dashboard::CLI::SeededPages::dist_dir = sub { return $shared_root };

    is(
        Developer::Dashboard::CLI::SeededPages::_shared_seeded_pages_root(),
        $shared_seeded_pages_root,
        'SeededPages resolves the installed shared seeded-pages root through File::ShareDir',
    );
    is(
        Developer::Dashboard::CLI::SeededPages::_seeded_page_asset_path('api-dashboard.page'),
        $shared_seeded_page,
        'SeededPages falls back to the installed shared seeded-page asset path when the repo asset is unavailable',
    );
}
{
    my $create_home = tempdir( CLEANUP => 1 );
    my $cwd         = getcwd();
    chdir $create_home or die "Unable to chdir to $create_home: $!";
    my $create_paths = Developer::Dashboard::PathRegistry->new( home => $create_home );
    my $create_seeded_page = Developer::Dashboard::CLI::SeededPages::sql_dashboard_page();
    my $create_store = bless {
        saved => [],
    }, 'Local::SeededPageStore';

    no warnings qw(redefine once);
    local *Local::SeededPageStore::read_saved_entry = sub {
        my ( $self, $id ) = @_;
        die "Page '$id' not found\n";
    };
    local *Local::SeededPageStore::save_page = sub {
        my ( $self, $page ) = @_;
        push @{ $self->{saved} }, $page;
        return $page;
    };

    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            pages => $create_store,
            paths => $create_paths,
            page  => $create_seeded_page,
        ),
        'created',
        'ensure_seeded_page creates a missing shipped seeded page when no saved copy exists yet',
    );
    is( scalar @{ $create_store->{saved} }, 1, 'ensure_seeded_page saves a newly created seeded page exactly once' );
    ok(
        -f Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $create_paths ),
        'ensure_seeded_page records the seed manifest after creating a missing shipped seeded page',
    );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
{
    my $current_home = tempdir( CLEANUP => 1 );
    my $cwd          = getcwd();
    chdir $current_home or die "Unable to chdir to $current_home: $!";
    my $current_paths = Developer::Dashboard::PathRegistry->new( home => $current_home );
    my $current_page  = Developer::Dashboard::CLI::SeededPages::sql_dashboard_page();
    my $current_store = bless {
        current => $current_page->canonical_instruction,
        saved   => [],
    }, 'Local::SeededPageStore';

    no warnings qw(redefine once);
    local *Local::SeededPageStore::read_saved_entry = sub {
        my ( $self, $id ) = @_;
        return $self->{current};
    };
    local *Local::SeededPageStore::save_page = sub {
        my ( $self, $page ) = @_;
        push @{ $self->{saved} }, $page;
        return $page;
    };

    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            pages => $current_store,
            paths => $current_paths,
            page  => $current_page,
        ),
        'current',
        'ensure_seeded_page records the manifest and returns current when the saved page already matches the shipped seed',
    );
    is_deeply( $current_store->{saved}, [], 'ensure_seeded_page does not rewrite an already-current shipped seeded page' );
    ok(
        -f Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $current_paths ),
        'ensure_seeded_page records the seed manifest when the saved page already matches the shipped seed',
    );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
{
    my $manifest_home = tempdir( CLEANUP => 1 );
    my $manifest_paths = Developer::Dashboard::PathRegistry->new( home => $manifest_home );
    my $manifest_path = Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $manifest_paths );

    open my $manifest_fh, '>:raw', $manifest_path or die "Unable to write $manifest_path: $!";
    print {$manifest_fh} qq|{"sql-dashboard":{"asset":"sql-dashboard.page","md5":"abc123"}}\n|;
    close $manifest_fh or die "Unable to close $manifest_path: $!";

    is_deeply(
        Developer::Dashboard::CLI::SeededPages::_read_manifest( paths => $manifest_paths ),
        {
            'sql-dashboard' => {
                asset => 'sql-dashboard.page',
                md5   => 'abc123',
            },
        },
        '_read_manifest loads an existing seeded-page manifest from disk',
    );

    open my $blank_manifest_fh, '>:raw', $manifest_path or die "Unable to rewrite $manifest_path: $!";
    print {$blank_manifest_fh} "\n";
    close $blank_manifest_fh or die "Unable to close $manifest_path: $!";

    is_deeply(
        Developer::Dashboard::CLI::SeededPages::_read_manifest( paths => $manifest_paths ),
        {},
        '_read_manifest treats a blank seeded-page manifest file as an empty hash',
    );
}
{
    my $legacy_home = tempdir( CLEANUP => 1 );
    my $legacy_paths = Developer::Dashboard::PathRegistry->new( home => $legacy_home );
    my $legacy_seeded_page_hash = Developer::Dashboard::CLI::SeededPages::page_for_id('sql-dashboard')->as_hash;
    my $legacy_current = "legacy-managed-sql-dashboard\n";
    my $legacy_saved = bless {
        current => $legacy_current,
        saved   => [],
    }, 'Local::SeededPageStore';
    my $original_content_md5 = \&Developer::Dashboard::SeedSync::content_md5;

    no warnings qw(redefine once);
    local *Local::SeededPageStore::read_saved_entry = sub {
        my ( $self, $id ) = @_;
        return $self->{current};
    };
    local *Local::SeededPageStore::save_page = sub {
        my ( $self, $page ) = @_;
        push @{ $self->{saved} }, $page;
        return $page;
    };
    local *Developer::Dashboard::SeedSync::content_md5 = sub {
        my ($content) = @_;
        return '10a14e5749f374a78429654b6c49b5f0' if defined $content && $content eq $legacy_current;
        return $original_content_md5->($content);
    };

    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            pages => $legacy_saved,
            paths => $legacy_paths,
            page  => $legacy_seeded_page_hash,
        ),
        'updated',
        'ensure_seeded_page refreshes a stale managed sql-dashboard copy even when the older runtime never wrote a seed manifest',
    );
    is( scalar @{ $legacy_saved->{saved} }, 1, 'ensure_seeded_page rewrites the stale managed sql-dashboard copy once' );
    ok(
        -f Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $legacy_paths ),
        'ensure_seeded_page backfills the seed manifest after refreshing a recognized legacy managed sql-dashboard copy',
    );
}
{
    my $preserve_home = tempdir( CLEANUP => 1 );
    my $cwd           = getcwd();
    chdir $preserve_home or die "Unable to chdir to $preserve_home: $!";
    my $preserve_paths = Developer::Dashboard::PathRegistry->new( home => $preserve_home );
    my $seeded_page_hash = Developer::Dashboard::CLI::SeededPages::page_for_id('api-dashboard')->as_hash;
    my $saved_instruction = <<'BOOKMARK';
TITLE: api-dashboard
:--------------------------------------------------------------------------------:
BOOKMARK: api-dashboard
:--------------------------------------------------------------------------------:
HTML: <div>user-edited seeded page</div>
BOOKMARK
    my $page_store = bless {
        current => $saved_instruction,
        saved   => [],
    }, 'Local::SeededPageStore';

    no warnings qw(redefine once);
    local *Local::SeededPageStore::read_saved_entry = sub {
        my ( $self, $id ) = @_;
        return $self->{current};
    };
    local *Local::SeededPageStore::save_page = sub {
        my ( $self, $page ) = @_;
        push @{ $self->{saved} }, $page;
        return $page;
    };

    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            pages => $page_store,
            paths => $preserve_paths,
            page  => $seeded_page_hash,
        ),
        'preserved',
        'ensure_seeded_page preserves a diverged saved seed when it no longer matches any dashboard-managed digest',
    );
    is_deeply( $page_store->{saved}, [], 'ensure_seeded_page does not rewrite a preserved user-edited seeded page' );
    ok(
        !-f Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $preserve_paths ),
        'ensure_seeded_page does not create or update the seed manifest when it preserves a diverged page',
    );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
like(
    _dies( sub { Developer::Dashboard::InternalCLI::helper_path( paths => $paths, name => 'bogus' ) } ),
    qr/Unsupported helper command/,
    'helper_path rejects unsupported helper names',
);
like(
    _dies( sub { Developer::Dashboard::InternalCLI::helper_content('bogus') } ),
    qr/Unsupported helper command/,
    'helper_content rejects unsupported helper names',
);
for my $helper ( Developer::Dashboard::InternalCLI::helper_names() ) {
    my $content = Developer::Dashboard::InternalCLI::helper_content($helper);
    if ( $helper =~ /\A(?:encode|decode|indicator|collector|config|auth|init|cpan|page|action|docker|serve|stop|restart|shell|doctor|skills|skill)\z/ ) {
        like(
            $content,
            qr/\Q_dashboard-core\E/,
            "helper_content renders the staged $helper wrapper that delegates into _dashboard-core",
        );
    }
    elsif ( $helper eq 'of' || $helper eq 'open-file' ) {
        like(
            $content,
            qr/\Qrun_open_file_command( args => \@ARGV );\E/,
            "helper_content renders the embedded $helper open-file helper body",
        );
    }
    elsif ( $helper eq 'ticket' ) {
        like(
            $content,
            qr/\Qrun_ticket_command( args => \@ARGV );\E/,
            'helper_content renders the embedded ticket helper body',
        );
    }
    elsif ( $helper eq 'path' || $helper eq 'paths' ) {
        like(
            $content,
            qr/\Qrun_paths_command( command => '$helper', args => \@ARGV );\E/,
            "helper_content renders the shipped $helper helper body",
        );
    }
    elsif ( $helper eq 'ps1' ) {
        like(
            $content,
            qr/\QThis private helper is staged under F<~\/.developer-dashboard\/cli\/dd\/>\E/,
            'helper_content renders the shipped ps1 helper body',
        );
    }
    elsif ( $helper eq 'housekeeper' ) {
        like(
            $content,
            qr/\Qdashboard housekeeper\E/,
            'helper_content renders the shipped housekeeper helper body',
        );
    }
    elsif ( $helper eq 'which' ) {
        like(
            $content,
            qr/\Qrun_which_command( command => 'which', args => \@ARGV );\E/,
            'helper_content renders the shipped which helper body',
        );
    }
    elsif ( $helper eq 'complete' ) {
        like(
            $content,
            qr/\Qdashboard complete <index> <word0> <word1> ...\E/,
            'helper_content renders the shipped complete helper body',
        );
    }
    else {
        like(
            $content,
            qr/\Qrun_query_command( command => '$helper', args => \@ARGV );\E/,
            "helper_content renders the shipped $helper query helper body",
        );
    }
}
my $seeded_helpers = Developer::Dashboard::InternalCLI::ensure_helpers( paths => $paths );
my @helper_names = Developer::Dashboard::InternalCLI::helper_names();
is( scalar(@$seeded_helpers), scalar(@helper_names), 'ensure_helpers writes every shipped helper once' );
my $seeded_helpers_second = Developer::Dashboard::InternalCLI::ensure_helpers( paths => $paths );
is_deeply( $seeded_helpers_second, [], 'ensure_helpers skips rewriting staged helpers whose md5 already matches the shipped content' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ), 'ensure_helpers also stages the shared _dashboard-core runtime under the dd namespace' );
ok( grep( $_ =~ m{/\Qof\E$}, @$seeded_helpers ), 'ensure_helpers writes the private of helper' );
ok( grep( $_ =~ m{/\Qopen-file\E$}, @$seeded_helpers ), 'ensure_helpers writes the private open-file helper' );
ok( grep( $_ =~ m{/\Qticket\E$}, @$seeded_helpers ), 'ensure_helpers writes the private ticket helper' );
ok( grep( $_ =~ m{/\Qpath\E$}, @$seeded_helpers ), 'ensure_helpers writes the private path helper' );
ok( grep( $_ =~ m{/\Qpaths\E$}, @$seeded_helpers ), 'ensure_helpers writes the private paths helper' );
ok( grep( $_ =~ m{/\Qps1\E$}, @$seeded_helpers ), 'ensure_helpers writes the private ps1 helper' );
ok( !grep( $_ =~ m{/\Qskill\E$}, @$seeded_helpers ), 'ensure_helpers no longer stages the removed singular skill helper' );
ok(
    Developer::Dashboard::SeedSync::file_matches_content_md5(
        File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'dd', 'jq' ),
        Developer::Dashboard::InternalCLI::_managed_helper_content('jq'),
    ),
    'SeedSync file_matches_content_md5 confirms the staged helper content matches the shipped helper body',
);
{
    my $preserve_home = tempdir( CLEANUP => 1 );
    my $preserve_paths = Developer::Dashboard::PathRegistry->new( home => $preserve_home );
    my $preserve_cli_root = File::Spec->catdir( $preserve_home, '.developer-dashboard', 'cli' );
    make_path($preserve_cli_root);
    my $user_jq = File::Spec->catfile( $preserve_cli_root, 'jq' );
    open my $user_jq_fh, '>', $user_jq or die "Unable to write $user_jq: $!";
    print {$user_jq_fh} "#!/usr/bin/env perl\nprint qq(user-jq\\n);\n";
    close $user_jq_fh;
    chmod 0755, $user_jq or die "Unable to chmod $user_jq: $!";
    my $user_note = File::Spec->catfile( $preserve_cli_root, 'user-note.txt' );
    open my $user_note_fh, '>', $user_note or die "Unable to write $user_note: $!";
    print {$user_note_fh} "keep me\n";
    close $user_note_fh;

    my $preserved_helpers = Developer::Dashboard::InternalCLI::ensure_helpers( paths => $preserve_paths );
    open my $preserved_jq_fh, '<', $user_jq or die "Unable to read $user_jq: $!";
    my $preserved_jq = do { local $/; <$preserved_jq_fh> };
    close $preserved_jq_fh;

    is( $preserved_jq, "#!/usr/bin/env perl\nprint qq(user-jq\\n);\n", 'ensure_helpers preserves a pre-existing user CLI file instead of overwriting it' );
    ok( -f $user_note, 'ensure_helpers does not delete unrelated user files from the home runtime CLI root' );
    ok(
        grep( $_ eq File::Spec->catfile( $preserve_home, '.developer-dashboard', 'cli', 'dd', 'jq' ), @{$preserved_helpers} ),
        'ensure_helpers stages the built-in jq helper under the dd namespace even when a user jq exists in the root CLI space',
    );
}
{
    local *Developer::Dashboard::InternalCLI::helper_content = sub {
        return "#!/usr/bin/env perl\n# developer-dashboard-managed-helper: jq\nprint qq(managed\\n);\n";
    };
    is(
        Developer::Dashboard::InternalCLI::_managed_helper_content('jq'),
        "#!/usr/bin/env perl\n# developer-dashboard-managed-helper: jq\nprint qq(managed\\n);\n",
        '_managed_helper_content leaves already-marked helper bodies unchanged',
    );
}
{
    local *Developer::Dashboard::InternalCLI::helper_content = sub {
        return "print qq(no-shebang\\n);\n";
    };
    is(
        Developer::Dashboard::InternalCLI::_managed_helper_content('jq'),
        "# developer-dashboard-managed-helper: jq\nprint qq(no-shebang\\n);\n",
        '_managed_helper_content prepends the ownership marker when helper content has no shebang',
    );
}
{
    my $preserve_home = tempdir( CLEANUP => 1 );
    my $preserve_paths = Developer::Dashboard::PathRegistry->new( home => $preserve_home );
    my $preserve_cli_root = File::Spec->catdir( $preserve_home, '.developer-dashboard', 'cli', 'dd' );
    make_path($preserve_cli_root);
    my $managed_jq = File::Spec->catfile( $preserve_cli_root, 'jq' );
    my $managed_body = Developer::Dashboard::InternalCLI::_managed_helper_content('jq');
    open my $managed_jq_fh, '>', $managed_jq or die "Unable to write $managed_jq: $!";
    print {$managed_jq_fh} $managed_body;
    close $managed_jq_fh;

    ok(
        !Developer::Dashboard::InternalCLI::_stage_managed_helper(
            paths  => $preserve_paths,
            name   => 'jq',
            target => $managed_jq,
        ),
        '_stage_managed_helper skips rewriting an already-managed helper file whose md5 already matches',
    );
    open my $managed_verify_fh, '<', $managed_jq or die "Unable to read $managed_jq: $!";
    my $managed_verify = do { local $/; <$managed_verify_fh> };
    close $managed_verify_fh;
    is( $managed_verify, $managed_body, '_stage_managed_helper leaves an already-managed matching helper unchanged on disk' );
}
{
    my $cleanup_home = tempdir( CLEANUP => 1 );
    my $cleanup_paths = Developer::Dashboard::PathRegistry->new( home => $cleanup_home );
    my $cleanup_cli_root = File::Spec->catdir( $cleanup_home, '.developer-dashboard', 'cli', 'dd' );
    make_path($cleanup_cli_root);
    my $legacy_skill = File::Spec->catfile( $cleanup_cli_root, 'skill' );
    open my $legacy_skill_fh, '>', $legacy_skill or die "Unable to write $legacy_skill: $!";
    print {$legacy_skill_fh} Developer::Dashboard::InternalCLI::_managed_helper_content('jq');
    close $legacy_skill_fh;
    open my $legacy_read_fh, '<', $legacy_skill or die "Unable to read $legacy_skill: $!";
    my $legacy_body = do { local $/; <$legacy_read_fh> };
    close $legacy_read_fh;
    $legacy_body =~ s/developer-dashboard-managed-helper: jq/developer-dashboard-managed-helper: skill/;
    open my $legacy_write_fh, '>', $legacy_skill or die "Unable to rewrite $legacy_skill: $!";
    print {$legacy_write_fh} $legacy_body;
    close $legacy_write_fh;

    ok(
        Developer::Dashboard::InternalCLI::_remove_retired_managed_helper(
            paths => $cleanup_paths,
            name  => 'skill',
        ),
        '_remove_retired_managed_helper removes a dashboard-managed legacy skill helper',
    );
    ok( !-e $legacy_skill, '_remove_retired_managed_helper deletes the retired managed helper from disk' );
}
ok(
    Developer::Dashboard::InternalCLI::_is_dashboard_managed_helper(
        "#!/usr/bin/env perl\n# old helper\nMissing built-in dashboard command\nDeveloper::Dashboard::CLI::SeededPages\n",
        '_dashboard-core',
    ),
    '_is_dashboard_managed_helper accepts the older pre-marker _dashboard-core helper body',
);
ok(
    Developer::Dashboard::InternalCLI::_is_dashboard_managed_helper(
        "#!/usr/bin/env perl\n# LAZY-THIN-CMD\n# Developer Dashboard\n",
        'jq',
    ),
    '_is_dashboard_managed_helper accepts older pre-marker helper bodies via the legacy thin-command marker',
);
ok(
    !Developer::Dashboard::InternalCLI::_is_dashboard_managed_helper( undef, 'jq' ),
    '_is_dashboard_managed_helper rejects undefined helper content',
);
ok(
    !Developer::Dashboard::InternalCLI::_is_dashboard_managed_helper(
        "#!/usr/bin/env perl\nprint qq(user helper\\n);\n",
        'jq',
    ),
    '_is_dashboard_managed_helper rejects unmarked user helper content',
);
{
    my $preserve_home = tempdir( CLEANUP => 1 );
    my $preserve_paths = Developer::Dashboard::PathRegistry->new( home => $preserve_home );
    my $preserve_cli_root = File::Spec->catdir( $preserve_home, '.developer-dashboard', 'cli', 'dd' );
    my $directory_target = File::Spec->catdir( $preserve_cli_root, 'jq' );
    make_path($directory_target);
    ok(
        !Developer::Dashboard::InternalCLI::_stage_managed_helper(
            paths  => $preserve_paths,
            name   => 'jq',
            target => $directory_target,
        ),
        '_stage_managed_helper preserves a colliding directory target instead of replacing it',
    );
}
like(
    Developer::Dashboard::InternalCLI::_repo_private_cli_root(),
    qr/share\/private-cli\z/,
    'internal CLI resolves helper assets from share/private-cli in the repo tree',
);
{
    my $shared_root = tempdir( CLEANUP => 1 );
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root = sub { return File::Spec->catdir( $shared_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::dist_dir = sub { return $shared_root };

    is(
        Developer::Dashboard::InternalCLI::_shared_private_cli_root(),
        File::Spec->catdir( $shared_root, 'private-cli' ),
        'internal CLI resolves the installed shared helper root through File::ShareDir',
    );
    is(
        Developer::Dashboard::InternalCLI::_helper_asset_path('jq'),
        File::Spec->catfile( $shared_root, 'private-cli', 'jq' ),
        'internal CLI falls back to the installed shared helper asset path when the repo asset is unavailable',
    );
}

my $layer_project = File::Spec->catdir( $ENV{HOME}, 'projects', 'cli-helper-layer-project' );
make_path( File::Spec->catdir( $layer_project, '.developer-dashboard', 'cli' ) );
my $layered_paths = Developer::Dashboard::PathRegistry->new(
    home            => $ENV{HOME},
    cwd             => $layer_project,
    workspace_roots => [ File::Spec->catdir( $ENV{HOME}, 'projects' ) ],
    project_roots   => [ File::Spec->catdir( $ENV{HOME}, 'projects' ) ],
);
is(
    Developer::Dashboard::InternalCLI::helper_path( paths => $layered_paths, name => 'jq' ),
    File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'dd', 'jq' ),
    'helper_path always stages built-in helpers under the home runtime dd helper root',
);

my $paths_output = capture {
    Developer::Dashboard::CLI::Paths::run_paths_command( command => 'paths', args => [] );
};
like( $paths_output, qr/"home_runtime_root"/, 'CLI::Paths renders the paths payload' );
{
    my $cwd = getcwd();
    my $projects_root = File::Spec->catdir( $ENV{HOME}, 'projects' );
    my $src_root      = File::Spec->catdir( $ENV{HOME}, 'src' );
    my $work_root     = File::Spec->catdir( $ENV{HOME}, 'work' );
    my $project_dir   = File::Spec->catdir( $projects_root, 'path-cmd-project' );
    my $src_project   = File::Spec->catdir( $src_root,      'locate-sample-app' );
    my $work_project  = File::Spec->catdir( $work_root,     'other-sample-app' );
    my $named_dir     = File::Spec->catdir( $ENV{HOME},     'named-target' );
    my $named_match_one = File::Spec->catdir( $named_dir, 'team-alpha' );
    my $named_match_two = File::Spec->catdir( $named_dir, 'nested', 'team-alpha-red' );
    my $cwd_match_one = File::Spec->catdir( $project_dir, 'docs-alpha' );
    my $cwd_match_two = File::Spec->catdir( $project_dir, 'nested', 'docs-alpha-red' );

    make_path( File::Spec->catdir( $project_dir, '.git' ) );
    make_path($src_project);
    make_path($work_project);
    make_path( $named_dir, $named_match_one, $named_match_two, $cwd_match_one, $cwd_match_two );
    chdir $project_dir or die "Unable to chdir to $project_dir: $!";

    my ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'add', 'named-home-target', $named_dir ],
        );
    };
    is( $stderr, '', 'CLI::Paths add writes no stderr on success' );
    my $added_alias = json_decode($stdout);
    is( $added_alias->{name}, 'named-home-target', 'CLI::Paths add returns the saved alias name' );
    is( $added_alias->{path}, $named_dir, 'CLI::Paths add expands the saved alias path for runtime use' );
    is( $added_alias->{resolved}, $named_dir, 'CLI::Paths add returns the resolved directory path' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => ['resolve', 'named-home-target'],
        );
    };
    is( $stderr, '', 'CLI::Paths resolve writes no stderr on success' );
    is( $stdout, "$named_dir\n", 'CLI::Paths resolve prints the resolved alias path' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'named-home-target' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr for alias-only resolution' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($named_dir),
            matches => [],
        },
        'CLI::Paths cdr returns the resolved alias root when no search keywords follow it',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'named-home-target', 'alpha', 'red' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr for alias-root keyword narrowing' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($named_match_two),
            matches => [],
        },
        'CLI::Paths cdr returns the unique alias-root directory that matches every keyword',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'named-home-target', 'alpha' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr when alias-root keyword search has multiple matches' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($named_dir),
            matches => _portable_paths( sort ( $named_match_one, $named_match_two ) ),
        },
        'CLI::Paths cdr keeps the alias root as the target and returns the match list when alias-root keyword search finds multiple directories',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'complete-cdr', '2', 'cdr', 'named-home-target', 'team-a' ],
        );
    };
    is( $stderr, '', 'CLI::Paths complete-cdr writes no stderr for alias-root completion candidates' );
    is_deeply(
        [ grep { length } split /\n/, $stdout ],
        [qw(team-alpha team-alpha-red)],
        'CLI::Paths complete-cdr suggests alias-root directory basenames that match the current prefix',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'locate', 'sample' ],
        );
    };
    is( $stderr, '', 'CLI::Paths locate writes no stderr on success' );
    my $located = json_decode($stdout);
    is_deeply(
        [ sort @{$located} ],
        [ sort ( $src_project, $work_project ) ],
        'CLI::Paths locate returns matching workspace and project roots',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'alpha', 'red' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr for current-directory keyword search' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($cwd_match_two),
            matches => [],
        },
        'CLI::Paths cdr searches beneath the current directory when the first argument is not a saved alias and one path matches every keyword',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'complete-cdr', '1', 'cdr', 'doc' ],
        );
    };
    is( $stderr, '', 'CLI::Paths complete-cdr writes no stderr for current-directory completion candidates' );
    is_deeply(
        [ grep { length } split /\n/, $stdout ],
        [qw(docs-alpha docs-alpha-red)],
        'CLI::Paths complete-cdr suggests current-directory basenames that match the current prefix',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'named-home-target', 'team-alpha$' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr for regex alias-root narrowing' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($named_match_one),
            matches => [],
        },
        'CLI::Paths cdr treats alias-root narrowing terms as regexes',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'docs-alpha$' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr for regex current-directory narrowing' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($cwd_match_one),
            matches => [],
        },
        'CLI::Paths cdr treats non-alias search terms as regexes beneath the current directory',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'cdr', 'alpha' ],
        );
    };
    is( $stderr, '', 'CLI::Paths cdr writes no stderr when current-directory keyword search has multiple matches' );
    is_deeply(
        _portable_cdr_payload( json_decode($stdout) ),
        {
            target  => _portable_path($project_dir),
            matches => _portable_paths( sort ( $cwd_match_one, $cwd_match_two ) ),
        },
        'CLI::Paths cdr returns only the match list when current-directory keyword search finds multiple directories',
    );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => ['project-root'],
        );
    };
    is( $stderr, '', 'CLI::Paths project-root writes no stderr on success' );
    chomp $stdout;
    is_same_path( $stdout, $project_dir, 'CLI::Paths project-root reports the current git project root' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => ['list'],
        );
    };
    is( $stderr, '', 'CLI::Paths list writes no stderr on success' );
    my $listed_paths = json_decode($stdout);
    is( $listed_paths->{named_home_target}, undef, 'CLI::Paths list preserves alias keys exactly as saved' );
    is( $listed_paths->{'named-home-target'}, $named_dir, 'CLI::Paths list includes saved aliases' );
    is( $listed_paths->{home}, $ENV{HOME}, 'CLI::Paths list includes the home directory path' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'del', 'named-home-target' ],
        );
    };
    is( $stderr, '', 'CLI::Paths del writes no stderr on success' );
    my $deleted_alias = json_decode($stdout);
    is( $deleted_alias->{name}, 'named-home-target', 'CLI::Paths del returns the deleted alias name' );
    is( $deleted_alias->{removed}, 1, 'CLI::Paths del reports successful removal' );

    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => ['bogus'] ) } ),
        qr/Usage: dashboard path <resolve\|locate\|cdr\|complete-cdr\|add\|del\|project-root\|list> \.\.\./,
        'CLI::Paths rejects unsupported path subcommands with a usage error',
    );

    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
{
    my $empty_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $empty_home;
    my $cwd = getcwd();
    chdir $empty_home or die "Unable to chdir to $empty_home: $!";
    my $paths_from_empty_home = Developer::Dashboard::CLI::Paths::_build_paths();
    is_deeply( [ $paths_from_empty_home->workspace_roots ], [], 'CLI::Paths _build_paths skips missing default workspace roots' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
{
    my $prompt_paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
    my $prompt = Developer::Dashboard::Prompt->new(
        indicators => bless( {}, 'Local::PromptIndicators' ),
        paths      => $prompt_paths,
    );
    my $project_dir = tempdir( CLEANUP => 1 );

    no warnings 'once';
    local *Local::PromptIndicators::list_indicators    = sub { return (); };
    local *Local::PromptIndicators::prompt_status_icon = sub { return ''; };
    local *Local::PromptIndicators::is_stale           = sub { return 0; };
    local *Developer::Dashboard::Prompt::capture       = sub (&) { return ( "  main\n  detached\n", '', 0 ) };

    is(
        $prompt->_git_branch($project_dir),
        undef,
        'Prompt _git_branch returns undef when git branch output has no current-branch marker',
    );
}

is(
    Developer::Dashboard::CLI::Ticket::resolve_ticket_request(
        args       => [],
        env_ticket => 'DD-123',
    ),
    'DD-123',
    'resolve_ticket_request falls back to env_ticket when argv is empty',
);
like(
    _dies( sub { Developer::Dashboard::CLI::Ticket::resolve_ticket_request( args => [] ) } ),
    qr/Please specify a ticket name/,
    'resolve_ticket_request rejects empty ticket requests',
);
is_deeply(
    Developer::Dashboard::CLI::Ticket::ticket_environment('DD-123'),
    {
        TICKET_REF => 'DD-123',
        B          => 'DD-123',
        OB         => 'origin/DD-123',
    },
    'ticket_environment builds the expected tmux environment values',
);
like(
    _dies( sub { Developer::Dashboard::CLI::Ticket::ticket_environment('') } ),
    qr/Ticket name is required/,
    'ticket_environment rejects empty ticket names',
);
is(
    Developer::Dashboard::CLI::Ticket::session_exists(
        session => 'exists',
        tmux    => sub { return { exit_code => 0, stdout => '', stderr => '' } },
    ),
    1,
    'session_exists returns true when tmux has-session succeeds',
);
is(
    Developer::Dashboard::CLI::Ticket::session_exists(
        session => 'missing',
        tmux    => sub { return { exit_code => 1, stdout => '', stderr => '' } },
    ),
    0,
    'session_exists returns false when tmux has-session reports a missing session',
);
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::session_exists(
                session => 'broken',
                tmux    => sub { return { exit_code => 2, stdout => "oops\n", stderr => "bad\n" } },
            );
        }
    ),
    qr/Unable to inspect tmux session 'broken': bad\noops\n/,
    'session_exists surfaces unexpected tmux failures',
);

my $ticket_plan = Developer::Dashboard::CLI::Ticket::build_ticket_plan(
    args => ['DD-456'],
    cwd  => '/tmp/work-here',
    tmux => sub { return { exit_code => 1, stdout => '', stderr => '' } },
);
is( $ticket_plan->{session}, 'DD-456', 'build_ticket_plan keeps the requested session name' );
is( $ticket_plan->{cwd}, '/tmp/work-here', 'build_ticket_plan keeps the requested cwd' );
ok( $ticket_plan->{create}, 'build_ticket_plan creates a new session when tmux reports it missing' );
is_deeply(
    $ticket_plan->{attach_argv},
    [ 'attach-session', '-t', 'DD-456' ],
    'build_ticket_plan prepares the attach argv',
);
ok(
    grep( $_ eq 'TICKET_REF=DD-456', @{ $ticket_plan->{create_argv} } ),
    'build_ticket_plan includes TICKET_REF in the create argv',
);
my $existing_ticket_plan = Developer::Dashboard::CLI::Ticket::build_ticket_plan(
    args => ['DD-456'],
    cwd  => '/tmp/work-here',
    tmux => sub { return { exit_code => 0, stdout => '', stderr => '' } },
);
ok( !$existing_ticket_plan->{create}, 'build_ticket_plan skips creation for existing sessions' );

{
    my @tmux_calls;
    my $result = Developer::Dashboard::CLI::Ticket::run_ticket_command(
        args => ['DD-789'],
        cwd  => '/tmp/work-here',
        tmux => sub {
            my (%call) = @_;
            push @tmux_calls, [ @{ $call{args} } ];
            if ( $call{args}[0] eq 'has-session' ) {
                return { exit_code => 1, stdout => '', stderr => '' };
            }
            return { exit_code => 0, stdout => '', stderr => '' };
        },
    );
    is( $result->{session}, 'DD-789', 'run_ticket_command returns the executed plan' );
    is_deeply( $tmux_calls[1][0], 'new-session', 'run_ticket_command creates a missing tmux session before attaching' );
    is_deeply( $tmux_calls[2], [ 'attach-session', '-t', 'DD-789' ], 'run_ticket_command attaches to the requested tmux session' );
}
{
    my @tmux_calls;
    Developer::Dashboard::CLI::Ticket::run_ticket_command(
        args => ['DD-790'],
        cwd  => '/tmp/work-here',
        tmux => sub {
            my (%call) = @_;
            push @tmux_calls, [ @{ $call{args} } ];
            return { exit_code => 0, stdout => '', stderr => '' };
        },
    );
    is( scalar(@tmux_calls), 2, 'run_ticket_command only checks and attaches when the session already exists' );
}
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::run_ticket_command(
                args => ['DD-791'],
                cwd  => '/tmp/work-here',
                tmux => sub {
                    my (%call) = @_;
                    return { exit_code => 1, stdout => '', stderr => '' } if $call{args}[0] eq 'has-session';
                    return { exit_code => 2, stdout => "create\n", stderr => "failed\n" } if $call{args}[0] eq 'new-session';
                    return { exit_code => 0, stdout => '', stderr => '' };
                },
            );
        }
    ),
    qr/Unable to create tmux ticket session 'DD-791': failed\ncreate\n/,
    'run_ticket_command surfaces tmux session creation failures',
);
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::run_ticket_command(
                args => ['DD-792'],
                cwd  => '/tmp/work-here',
                tmux => sub {
                    my (%call) = @_;
                    return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'has-session';
                    return { exit_code => 3, stdout => "attach\n", stderr => "denied\n" };
                },
            );
        }
    ),
    qr/Unable to attach tmux ticket session 'DD-792': denied\nattach\n/,
    'run_ticket_command surfaces tmux attach failures',
);

{
    my $fake_bin = File::Spec->catdir( $ENV{HOME}, 'tmux-bin' );
    make_path($fake_bin);
    my $log_file = File::Spec->catfile( $ENV{HOME}, 'tmux.log' );
    my $fake_tmux = File::Spec->catfile( $fake_bin, 'tmux' );
    _write_file(
        $fake_tmux,
        <<"SH"
#!/bin/sh
printf '%s\\n' "\$*" >> "$log_file"
if [ "\$1" = "has-session" ]; then
  exit 0
fi
exit 0
SH
    );
    chmod 0755, $fake_tmux or die "Unable to chmod $fake_tmux: $!";
    local $ENV{PATH} = join ':', $fake_bin, ( $ENV{PATH} || '' );
    my $tmux_result = Developer::Dashboard::CLI::Ticket::tmux_command(
        args => [ 'attach-session', '-t', 'DD-800' ],
    );
    is( $tmux_result->{exit_code}, 0, 'tmux_command returns the wrapped tmux exit code' );
    is( $tmux_result->{stderr}, '', 'tmux_command captures stderr from tmux' );
    open my $tmux_log_fh, '<', $log_file or die "Unable to read $log_file: $!";
    like( do { local $/; <$tmux_log_fh> }, qr/attach-session -t DD-800/, 'tmux_command runs tmux with the requested argv' );
    close $tmux_log_fh;
}

is_deeply(
    [ Developer::Dashboard::CLI::Query::_split_query_args() ],
    [ '', '' ],
    '_split_query_args returns empty path/file when no args are supplied',
);
is_deeply(
    [ Developer::Dashboard::CLI::Query::_split_query_args( 'alpha.beta', 'missing.file' ) ],
    [ 'alpha.beta missing.file', '' ],
    '_split_query_args rejoins multiple non-file arguments into one query path',
);

my $query_file = File::Spec->catfile( $ENV{HOME}, 'query.json' );
_write_file( $query_file, qq|{"alpha":{"beta":2}}\n| );
is(
    Developer::Dashboard::CLI::Query::_read_query_input($query_file),
    qq|{"alpha":{"beta":2}}\n|,
    '_read_query_input reads explicit files',
);
{
    local *STDIN;
    open STDIN, '<', \$query_file or die "Unable to open scalar STDIN: $!";
    is(
        Developer::Dashboard::CLI::Query::_read_query_input(''),
        $query_file,
        '_read_query_input reads STDIN when no file is supplied',
    );
}

is_deeply(
    Developer::Dashboard::CLI::Query::_parse_query_input( command => 'pjq', text => qq|{"alpha":{"beta":2}}| ),
    { alpha => { beta => 2 } },
    '_parse_query_input supports the legacy JSON alias',
);
is_deeply(
    Developer::Dashboard::CLI::Query::_parse_query_input( command => 'pyq', text => "alpha:\n  beta: 3\n" ),
    { alpha => { beta => 3 } },
    '_parse_query_input supports the legacy YAML alias',
);
is_deeply(
    scalar( Developer::Dashboard::CLI::Query::_parse_query_input( command => 'ptomq', text => "[alpha]\nbeta = 4\n" ) ),
    { alpha => { beta => 4 } },
    '_parse_query_input supports the legacy TOML alias',
);
is_deeply(
    Developer::Dashboard::CLI::Query::_parse_query_input( command => 'pjp', text => "alpha.beta=5\n" ),
    { 'alpha.beta' => '5' },
    '_parse_query_input supports the legacy properties alias',
);
like(
    _dies( sub { Developer::Dashboard::CLI::Query::_parse_query_input( command => 'bogus', text => '' ) } ),
    qr/Unsupported data query command/,
    '_parse_query_input rejects unsupported formats',
);
is_deeply( Developer::Dashboard::CLI::Query::_extract_query_path( { alpha => 1 }, '$d' ), { alpha => 1 }, '_extract_query_path returns the whole document for $d' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( { 'alpha.beta' => 'joined' }, 'alpha.beta' ), 'joined', '_extract_query_path returns a direct dotted hash key when present' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( [ [ 'a', 'b' ] ], '0.1' ), 'b', '_extract_query_path supports array traversal' );
like(
    _dies( sub { Developer::Dashboard::CLI::Query::_extract_query_path( { alpha => {} }, 'alpha.beta' ) } ),
    qr/Missing path segment 'beta'/,
    '_extract_query_path dies for missing hash keys',
);
like(
    _dies( sub { Developer::Dashboard::CLI::Query::_extract_query_path( [1], 'x' ) } ),
    qr/Array index 'x' is invalid/,
    '_extract_query_path rejects non-numeric array indexes',
);
like(
    _dies( sub { Developer::Dashboard::CLI::Query::_extract_query_path( 'plain', 'alpha' ) } ),
    qr/does not resolve through a nested structure/,
    '_extract_query_path rejects traversal through scalars',
);
{
    my ( $stdout ) = capture { Developer::Dashboard::CLI::Query::_print_query_value( { ok => 1 } ) };
    like( $stdout, qr/"ok"\s*:\s*1/s, '_print_query_value renders structures as JSON' );
}
{
    my ( $stdout ) = capture { Developer::Dashboard::CLI::Query::_print_query_value(undef) };
    is( $stdout, "\n", '_print_query_value prints a newline for undef scalars' );
}
is(
    Developer::Dashboard::CLI::Query::_unescape_properties("\\t\\n\\r\\f\\\\"),
    "\t\n\r\f\\",
    '_unescape_properties decodes all supported escape sequences',
);
is_deeply(
    Developer::Dashboard::CLI::Query::_parse_java_properties("! comment\nalpha=one\\\ntwo\nblank\n"),
    { alpha => 'onetwo', blank => '' },
    '_parse_java_properties handles comments, continuations, and blank values',
);
is_deeply(
    Developer::Dashboard::CLI::Query::_parse_ini("name = root\n[alpha]\nbeta = 1\n"),
    {
        _global => { name => 'root' },
        alpha   => { beta => '1' },
    },
    '_parse_ini captures global keys and named sections',
);
is_deeply(
    Developer::Dashboard::CLI::Query::_parse_csv("a,b\n1,2\n\n"),
    [ [ 'a', 'b' ], [ '1', '2' ] ],
    '_parse_csv skips empty trailing rows',
);
is_deeply(
    Developer::Dashboard::CLI::Query::_parse_xml('<root/>'),
    { root => '' },
    '_parse_xml decodes XML into a traversable hash structure',
);

local $ENV{RESULT} = '';
is_deeply( Developer::Dashboard::Runtime::Result::current(), {}, 'Runtime::Result current returns an empty hash for empty RESULT' );
local $ENV{RESULT_FILE} = '';
local $ENV{LAST_RESULT} = '';
local $ENV{LAST_RESULT_FILE} = '';
is( Developer::Dashboard::Runtime::Result::has(''), 0, 'Runtime::Result has rejects empty names' );
is( Developer::Dashboard::Runtime::Result::entry(''), undef, 'Runtime::Result entry rejects empty names' );
is( Developer::Dashboard::Runtime::Result::stdout('missing'), '', 'Runtime::Result stdout returns empty string for missing names' );
is( Developer::Dashboard::Runtime::Result::stderr('missing'), '', 'Runtime::Result stderr returns empty string for missing names' );
is( Developer::Dashboard::Runtime::Result::exit_code('missing'), undef, 'Runtime::Result exit_code returns undef for missing names' );
is( Developer::Dashboard::Runtime::Result::last_name(), undef, 'Runtime::Result last_name returns undef when RESULT is empty' );
is( Developer::Dashboard::Runtime::Result::last_entry(), undef, 'Runtime::Result last_entry returns undef when RESULT is empty' );
is( Developer::Dashboard::Runtime::Result::last_result(), undef, 'Runtime::Result last_result returns undef when LAST_RESULT is empty' );
is( Developer::Dashboard::Runtime::Result::report(), '', 'Runtime::Result report returns an empty string for empty RESULT' );
is( Developer::Dashboard::Runtime::Result::clear_current(), '', 'Runtime::Result clear_current clears inline or file-backed RESULT state' );
is( Developer::Dashboard::Runtime::Result::clear_last_result(), '', 'Runtime::Result clear_last_result clears inline or file-backed LAST_RESULT state' );
is( Developer::Dashboard::Runtime::Result::_current_json(), '', 'Runtime::Result _current_json returns an empty string when RESULT is empty' );
ok( !Developer::Dashboard::Runtime::Result::stop_requested('plain stderr'), 'Runtime::Result stop_requested ignores plain stderr without the marker' );
ok( Developer::Dashboard::Runtime::Result::stop_requested("[[STOP]] requested\n"), 'Runtime::Result stop_requested detects the explicit stderr stop marker' );
ok(
    Developer::Dashboard::Runtime::Result::stop_requested( { STDERR => 'before [[STOP]] after' } ),
    'Runtime::Result stop_requested accepts structured last-result hashes too',
);
{
    local $ENV{RESULT};
    local $ENV{RESULT_FILE};
    is(
        Developer::Dashboard::Runtime::Result::set_current(
            { '01-inline' => { stdout => "ok\n", stderr => '', exit_code => 0 } },
            max_inline_bytes => 4096,
        ),
        'inline',
        'Runtime::Result keeps small payloads inline in RESULT',
    );
    like( $ENV{RESULT}, qr/01-inline/, 'Runtime::Result writes inline RESULT JSON for small payloads' );
    ok( !defined $ENV{RESULT_FILE}, 'Runtime::Result leaves RESULT_FILE unset for small payloads' );
}
{
    local $ENV{RESULT};
    local $ENV{RESULT_FILE};
    my $mode = Developer::Dashboard::Runtime::Result::set_current(
        { '01-file' => { stdout => ( 'x' x 2048 ), stderr => '', exit_code => 0 } },
        max_inline_bytes => 32,
    );
    is( $mode, 'file', 'Runtime::Result spills oversized payloads into RESULT_FILE before exec would overflow' );
    is( $ENV{RESULT}, undef, 'Runtime::Result clears inline RESULT when file-backed overflow fallback is active' );
    ok( defined $ENV{RESULT_FILE} && $ENV{RESULT_FILE} ne '', 'Runtime::Result exposes the inherited RESULT_FILE path for oversized payloads' );
    is_deeply(
        Developer::Dashboard::Runtime::Result::current(),
        { '01-file' => { stdout => ( 'x' x 2048 ), stderr => '', exit_code => 0 } },
        'Runtime::Result current reads the full file-backed payload through RESULT_FILE',
    );
    is(
        Developer::Dashboard::Runtime::Result::clear_current(),
        '',
        'Runtime::Result clear_current also closes an active file-backed RESULT handle',
    );
    is( $ENV{RESULT} || '', '', 'Runtime::Result clear_current leaves RESULT empty after closing a file-backed payload' );
    is( $ENV{RESULT_FILE} || '', '', 'Runtime::Result clear_current leaves RESULT_FILE empty after closing a file-backed payload' );
}
{
    local $ENV{LAST_RESULT};
    local $ENV{LAST_RESULT_FILE};
    is(
        Developer::Dashboard::Runtime::Result::set_last_result(
            {
                file   => 'cli/test.d/01-inline.pl',
                exit   => 0,
                STDOUT => "inline\n",
                STDERR => '',
            },
            max_inline_bytes => 4096,
        ),
        'inline',
        'Runtime::Result keeps small LAST_RESULT payloads inline',
    );
    like( $ENV{LAST_RESULT}, qr/01-inline\.pl/, 'Runtime::Result writes inline LAST_RESULT JSON for small payloads' );
    ok( !defined $ENV{LAST_RESULT_FILE}, 'Runtime::Result leaves LAST_RESULT_FILE unset for small LAST_RESULT payloads' );
    is_deeply(
        Developer::Dashboard::Runtime::Result::last_result(),
        {
            file   => 'cli/test.d/01-inline.pl',
            exit   => 0,
            STDOUT => "inline\n",
            STDERR => '',
        },
        'Runtime::Result last_result decodes inline LAST_RESULT JSON',
    );
}
{
    local $ENV{LAST_RESULT};
    local $ENV{LAST_RESULT_FILE};
    my $mode = Developer::Dashboard::Runtime::Result::set_last_result(
        {
            file   => 'cli/test.d/01-file.pl',
            exit   => 2,
            STDOUT => '',
            STDERR => ( 'y' x 2048 ),
        },
        max_inline_bytes => 32,
    );
    is( $mode, 'file', 'Runtime::Result spills oversized LAST_RESULT payloads into LAST_RESULT_FILE' );
    is( $ENV{LAST_RESULT}, undef, 'Runtime::Result clears inline LAST_RESULT when file-backed overflow fallback is active' );
    ok(
        defined $ENV{LAST_RESULT_FILE} && $ENV{LAST_RESULT_FILE} ne '',
        'Runtime::Result exposes LAST_RESULT_FILE for oversized last-result payloads',
    );
    is_deeply(
        Developer::Dashboard::Runtime::Result::last_result(),
        {
            file   => 'cli/test.d/01-file.pl',
            exit   => 2,
            STDOUT => '',
            STDERR => ( 'y' x 2048 ),
        },
        'Runtime::Result last_result reads the full file-backed LAST_RESULT payload',
    );
    is(
        Developer::Dashboard::Runtime::Result::clear_last_result(),
        '',
        'Runtime::Result clear_last_result closes an active file-backed LAST_RESULT handle',
    );
    is( $ENV{LAST_RESULT} || '', '', 'Runtime::Result clear_last_result leaves LAST_RESULT empty after cleanup' );
    is( $ENV{LAST_RESULT_FILE} || '', '', 'Runtime::Result clear_last_result leaves LAST_RESULT_FILE empty after cleanup' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX} = '123';
    is(
        Developer::Dashboard::Runtime::Result::_max_inline_bytes(),
        123,
        'Runtime::Result honors the environment override for the inline RESULT byte limit',
    );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX};
    is(
        Developer::Dashboard::Runtime::Result::_max_inline_bytes(),
        65536,
        'Runtime::Result falls back to the default inline RESULT byte limit when no override is present',
    );
}
{
    local $0 = '';
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'env-command';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'env-command', '_command_name falls back to the command env var when $0 is empty' );
}
{
    local $0 = '';
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = '';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', '_command_name falls back to dashboard when neither $0 nor env provide a name' );
}
{
    local $0 = '/tmp/custom-report/run';
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'ignored';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'custom-report', '_command_name uses the parent directory for run-style executables' );
}
{
    local $0 = '/run';
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'env-fallback';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'env-fallback', '_command_name falls back to env when run-style paths have no usable parent name' );
}
{
    local $0 = '/run';
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = '';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', '_command_name falls back to dashboard when run-style paths have no usable parent name and env is empty' );
}
{
    local $ENV{RESULT} = '{"01-foo":{"stdout":"ok\\n","stderr":"","exit_code":0},"02-bar":{"stdout":"","stderr":"bad\\n","exit_code":1}}';
    my $report = decode_utf8( Developer::Dashboard::Runtime::Result::report( command => 'report-result' ) );
    like( $report, qr/report-result Run Report/, 'Runtime::Result report accepts an explicit command override' );
    like( $report, qr/01-foo/, 'Runtime::Result report lists successful hook names' );
    like( $report, qr/02-bar/, 'Runtime::Result report lists failing hook names' );
}

my $test_repos = tempdir( CLEANUP => 1 );
my $test_cwd = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";
my $fake_bin = tempdir( CLEANUP => 1 );
my $cpanm_log = File::Spec->catfile( $fake_bin, 'cpanm.log' );
my $apt_log = File::Spec->catfile( $fake_bin, 'apt.log' );
my $apk_log = File::Spec->catfile( $fake_bin, 'apk.log' );
my $brew_log = File::Spec->catfile( $fake_bin, 'brew.log' );
my $npx_log = File::Spec->catfile( $fake_bin, 'npx.log' );
my $sudo_log = File::Spec->catfile( $fake_bin, 'sudo.log' );
my $dashboard_log = File::Spec->catfile( $fake_bin, 'dashboard.log' );
my $dependency_log = File::Spec->catfile( $fake_bin, 'dependency-install.log' );
_write_file(
    File::Spec->catfile( $fake_bin, 'cpanm' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$cpanm_log"
printf 'CPANM:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_CPANM_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'brew' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$brew_log"
printf 'BREW:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_BREW_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'npx' ),
    <<"SH",
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> "$npx_log"
printf 'NPM:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_NPM_FAIL" = "1" ]; then
  exit 1
fi
if [ "\$DD_TEST_NPM_NO_MODULES" = "1" ]; then
  exit 0
fi
shift
shift
shift
for spec in "\$@"; do
  name=\${spec%%@*}
  mkdir -p "\$PWD/node_modules/\$name"
done
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'sudo' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$sudo_log"
exec "\$@"
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'dashboard' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$dashboard_log"
manifest="\${DEVELOPER_DASHBOARD_DEPENDENCY_MANIFEST:-ddfile}"
if [ "\$manifest" = "ddfile.local" ]; then
  printf 'DDFILE_LOCAL:%s\\n' "\$*" >> "$dependency_log"
else
  printf 'DDFILE:%s\\n' "\$*" >> "$dependency_log"
fi
if [ "\$DD_TEST_DDFILE_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'apt-get' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$apt_log"
printf 'APT:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_APT_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'dpkg-query' ),
    <<'SH',
#!/bin/sh
eval "package=\${$#}"
case ",${DD_TEST_APT_INSTALLED:-}," in
  *,"$package",*)
    printf '%s' 'install ok installed'
    exit 0
    ;;
esac
exit 1
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'apk' ),
    <<"SH",
#!/bin/sh
if [ "\$1" = "info" ] && [ "\$2" = "-e" ]; then
  case ",\${DD_TEST_APK_INSTALLED:-}," in
    *,"\$3",*) exit 0 ;;
  esac
  exit 1
fi
printf '%s\\n' "\$*" >> "$apk_log"
printf 'APK:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_APK_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
    0755,
);
local $ENV{PATH} = join ':', $fake_bin, ( $ENV{PATH} || () );

my $skill_paths = Developer::Dashboard::PathRegistry->new( home => File::Spec->catdir( $ENV{HOME}, 'skills-home' ) );
my $manager = Developer::Dashboard::SkillManager->new( paths => $skill_paths );
is_deeply( $manager->list, [], 'skill manager list is empty before installation' );
is_deeply(
    Developer::Dashboard::SkillManager->install_progress_tasks,
    [
        { id => 'fetch_source',         label => 'Fetch skill source' },
        { id => 'prepare_layout',       label => 'Prepare skill layout' },
        { id => 'install_aptfile',      label => 'Install aptfile dependencies' },
        { id => 'install_apkfile',      label => 'Install apkfile dependencies' },
        { id => 'install_dnfile',       label => 'Install dnfile dependencies' },
        { id => 'install_brewfile',     label => 'Install brewfile dependencies' },
        { id => 'install_package_json', label => 'Install package.json dependencies' },
        { id => 'install_cpanfile',     label => 'Install cpanfile dependencies' },
        { id => 'install_cpanfile_local', label => 'Install cpanfile.local dependencies' },
        { id => 'install_ddfile',       label => 'Install ddfile dependencies' },
        { id => 'install_ddfile_local', label => 'Install ddfile.local dependencies' },
    ],
    'install_progress_tasks returns the documented dashboard skills install task sequence',
);
{
    my @events;
    my $progress_manager = Developer::Dashboard::SkillManager->new(
        paths    => $skill_paths,
        progress => sub { push @events, shift },
    );
    is( $progress_manager->_progress_emit( { task_id => 'fetch_source', status => 'running' } ), 1, '_progress_emit returns true when a progress callback is configured' );
    is_deeply(
        \@events,
        [ { task_id => 'fetch_source', status => 'running' } ],
        '_progress_emit forwards events into the configured callback',
    );
}
{
    my $label_skill = File::Spec->catdir( $ENV{HOME}, 'label-skill' );
    my $label_package_json = File::Spec->catfile( $label_skill, 'package.json' );
    make_path($label_skill);
    _write_file( $label_package_json, qq|{"name":"label-skill","version":"1.0.0"}\n| );
    is(
        $manager->_dependency_progress_label( 'install_package_json', $label_skill ),
        "Install package.json dependencies from $label_package_json",
        '_dependency_progress_label surfaces the detected package.json path while npm work is in progress',
    );
    is(
        $manager->_dependency_progress_label(
            'install_package_json',
            $label_skill,
            result => { success => 1, skipped => 1 },
        ),
        'Install package.json dependencies (skipped: package.json not present)',
        '_dependency_progress_label makes skipped package.json work explicit in the progress board',
    );
}
is( $manager->get_skill_path('missing'), undef, 'get_skill_path returns undef for missing skills' );
is( $manager->_normalize_install_source('browser'), 'https://github.com/manif3station/browser', '_normalize_install_source expands bare skill names against the official GitHub base' );
is( $manager->_normalize_install_source('foo/bar'), 'https://github.com/foo/bar', '_normalize_install_source expands owner/repo shorthand against GitHub' );
is( $manager->_normalize_install_source('https://github.com/foo/bar.git'), 'https://github.com/foo/bar.git', '_normalize_install_source leaves explicit HTTPS remotes unchanged' );
is( $manager->_normalize_install_source('git@github.com:foo/bar.git'), 'git@github.com:foo/bar.git', '_normalize_install_source leaves explicit SSH remotes unchanged' );
is( $manager->_normalize_install_source('foo bar?baz'), 'foo bar?baz', '_normalize_install_source leaves non-shorthand install sources unchanged' );
is( Developer::Dashboard::SkillManager::_extract_repo_name('bogus'), undef, '_extract_repo_name returns undef for strings without a repo path segment' );
is( Developer::Dashboard::SkillManager::_extract_repo_name('https://example.invalid/owner/repo.git'), 'repo', '_extract_repo_name strips .git from repository URLs' );
is( Developer::Dashboard::SkillManager::_extract_repo_name(''), undef, '_extract_repo_name returns undef for empty URLs' );
is_deeply( $manager->install(''), { error => 'Missing skill source' }, 'install rejects an empty skill source' );
{
    my $shorthand_home = tempdir( CLEANUP => 1 );
    my $shorthand_paths = Developer::Dashboard::PathRegistry->new( home => $shorthand_home );
    my $shorthand_manager = Developer::Dashboard::SkillManager->new( paths => $shorthand_paths );
    my $remote_repo = _create_skill_repo(
        $test_repos,
        'remote-demo',
        with_cpanfile => 0,
        with_bookmark => 0,
        with_nav      => 0,
        with_hook     => 0,
    );
    my @clone_calls;
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_clone_skill_source = sub {
        my ( $self, $clone_source, $target_path ) = @_;
        @clone_calls = ( $clone_source, $target_path );
        my $copy = $self->_copy_tree( $remote_repo, $target_path );
        return $copy if $copy->{error};
        return { success => 1 };
    };
    my $remote_install = $shorthand_manager->install('remote-demo');
    ok( !$remote_install->{error}, 'install accepts one bare skill name and resolves it through the official GitHub base' ) or diag $remote_install->{error};
    is_deeply(
        \@clone_calls,
        [ 'https://github.com/manif3station/remote-demo', $remote_install->{path} ],
        'install clones bare skill names from the official GitHub base URL',
    );
}
{
    my $shorthand_home = tempdir( CLEANUP => 1 );
    my $shorthand_paths = Developer::Dashboard::PathRegistry->new( home => $shorthand_home );
    my $shorthand_manager = Developer::Dashboard::SkillManager->new( paths => $shorthand_paths );
    my $remote_repo = _create_skill_repo(
        $test_repos,
        'bar',
        with_cpanfile => 0,
        with_bookmark => 0,
        with_nav      => 0,
        with_hook     => 0,
    );
    my @clone_calls;
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_clone_skill_source = sub {
        my ( $self, $clone_source, $target_path ) = @_;
        @clone_calls = ( $clone_source, $target_path );
        my $copy = $self->_copy_tree( $remote_repo, $target_path );
        return $copy if $copy->{error};
        return { success => 1 };
    };
    my $remote_install = $shorthand_manager->install('foo/bar');
    ok( !$remote_install->{error}, 'install accepts owner/repo shorthand skill names' ) or diag $remote_install->{error};
    is_deeply(
        \@clone_calls,
        [ 'https://github.com/foo/bar', $remote_install->{path} ],
        'install clones owner/repo shorthand from the matching GitHub repository URL',
    );
}
like( $manager->install('https://example.invalid/not-a-repo.git')->{error}, qr/Failed to clone/, 'install reports git clone failures' );
{
    my $invalid_local_repo = File::Spec->catdir( $test_repos, 'invalid-local-skill' );
    make_path($invalid_local_repo);
    is_deeply(
        $manager->install($invalid_local_repo),
        { error => "Local skill source '$invalid_local_repo' is missing a .git directory" },
        'install rejects local directories that are not checked-out git repositories',
    );

    make_path( File::Spec->catdir( $invalid_local_repo, '.git' ) );
    is_deeply(
        $manager->install($invalid_local_repo),
        { error => "Local skill source '$invalid_local_repo' is missing a .env file with VERSION" },
        'install rejects local checked-out repositories that are missing the qualification .env file',
    );

    open my $invalid_env_fh, '>', File::Spec->catfile( $invalid_local_repo, '.env' ) or die "Unable to write invalid local .env: $!";
    print {$invalid_env_fh} "NAME=invalid\n";
    close $invalid_env_fh;
    is_deeply(
        $manager->install($invalid_local_repo),
        { error => "Local skill source '$invalid_local_repo' is missing a .env file with VERSION" },
        'install rejects local checked-out repositories whose .env file has no VERSION key',
    );
}
{
    my $local_repo = _create_skill_repo( $test_repos, 'no-rsync-local-skill' );
    open my $local_env_fh, '>', File::Spec->catfile( $local_repo, '.env' ) or die "Unable to write local fallback .env: $!";
    print {$local_env_fh} "VERSION=1.00\n";
    close $local_env_fh;

    local *Developer::Dashboard::SkillManager::_rsync_available = sub { 0 };
    my $local_install = $manager->install($local_repo);
    ok( !$local_install->{error}, 'install falls back to the Perl local-copy path when rsync is unavailable' ) or diag $local_install->{error};
    my $local_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $skill_paths );
    my $local_dispatch = $local_dispatcher->dispatch( 'no-rsync-local-skill', 'run-test' );
    like( $local_dispatch->{stdout}, qr/hooked/, 'rsync-free local install still leaves one runnable installed skill copy' );
    my $local_uninstall = $manager->uninstall('no-rsync-local-skill');
    ok( !$local_uninstall->{error}, 'rsync-free local install fixture can be removed after the fallback coverage' )
      or diag $local_uninstall->{error};
}
{
    my $sync_error_repo = _create_skill_repo( $test_repos, 'local-sync-error-skill', with_cpanfile => 0 );
    open my $sync_error_env_fh, '>', File::Spec->catfile( $sync_error_repo, '.env' ) or die "Unable to write local sync error .env: $!";
    print {$sync_error_env_fh} "VERSION=1.00\n";
    close $sync_error_env_fh;

    my $preexisting_target = File::Spec->catdir( $skill_paths->skills_root, 'local-sync-error-skill' );
    make_path($preexisting_target);
    _write_file( File::Spec->catfile( $preexisting_target, 'stale.txt' ), "stale\n" );

    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_remove_existing_skill_path = sub { return { success => 1 } };
    local *Developer::Dashboard::SkillManager::_sync_local_skill_source     = sub { return { error => 'synthetic sync failure' } };

    is_deeply(
        $manager->install($sync_error_repo),
        { error => 'synthetic sync failure' },
        'install returns local sync failures for direct checked-out repositories',
    );
    ok( !-d $preexisting_target, 'install removes a pre-existing target tree when local sync fails mid-install' );
}
{
    my $rsync_fail_bin = File::Spec->catdir( $ENV{HOME}, 'fake-rsync-bin' );
    make_path($rsync_fail_bin);
    _write_file(
        File::Spec->catfile( $rsync_fail_bin, 'rsync' ),
        "#!/bin/sh\nprintf 'rsync failed\\n' >&2\nexit 1\n",
        0755,
    );

    local $ENV{PATH} = $rsync_fail_bin . ':' . ( $ENV{PATH} || '' );
    local *Developer::Dashboard::SkillManager::_rsync_available = sub { 1 };

    like(
        $manager->_sync_local_skill_source( '/tmp/source-skill', '/tmp/target-skill' )->{error},
        qr/^Failed to sync local skill source \/tmp\/source-skill: rsync failed/m,
        '_sync_local_skill_source reports rsync stderr when rsync fails',
    );
}
{
    my $copy_source = File::Spec->catdir( $test_repos, 'copy-tree-error-source' );
    my $copy_target = File::Spec->catdir( $test_repos, 'copy-tree-error-target' );
    make_path($copy_source);
    _write_file( File::Spec->catfile( $copy_source, 'file.txt' ), "copy me\n" );

    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::copy = sub { 0 };

    like(
        $manager->_copy_tree( $copy_source, $copy_target )->{error},
        qr/^Failed to sync local skill source \Q$copy_source\E without rsync: Unable to copy /,
        '_copy_tree reports a local copy failure when one file cannot be copied',
    );
}
is_deeply( $manager->update(''), { error => 'Missing repo name' }, 'update rejects an empty repo name' );
is_deeply( $manager->uninstall(''), { error => 'Missing repo name' }, 'uninstall rejects an empty repo name' );
is_deeply( $manager->update('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'update rejects unknown skills' );
is_deeply( $manager->uninstall('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'uninstall rejects unknown skills' );

my $dep_repo = _create_skill_repo(
    $test_repos,
    'dep-skill',
    with_cpanfile => 1,
    with_aptfile => 1,
    with_apkfile => 1,
    with_ddfile  => 1,
    with_ddfile_local => 1,
    with_package_json => 1,
    with_cpanfile_local => 1,
);
my $install = $manager->install( 'file://' . $dep_repo );
ok( !$install->{error}, 'skill manager installs a skill with a cpanfile' ) or diag $install->{error};
my $dep_skill_root = $manager->get_skill_path('dep-skill');
_write_file(
    File::Spec->catfile( $dep_repo, 'cli', 'run-test' ),
    <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "reinstalled-dep-skill\n";
PL
    0755,
);
{
    my $cwd = getcwd();
    chdir $dep_repo or die "Unable to chdir to $dep_repo: $!";
    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', 'Reinstall dep skill update' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
my $duplicate = $manager->install( 'file://' . $dep_repo );
ok( !$duplicate->{error}, 'install acts as reinstall instead of rejecting duplicate skill installs' ) or diag $duplicate->{error};
my $reinstall_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $skill_paths );
my $reinstalled_dispatch = $reinstall_dispatcher->dispatch( 'dep-skill', 'run-test' );
like( $reinstalled_dispatch->{stdout}, qr/reinstalled-dep-skill/, 'reinstall refreshes the already-installed git-backed skill content' );
my $dep_install = $manager->_install_skill_dependencies( $manager->get_skill_path('dep-skill') );
ok( !$dep_install->{error}, '_install_skill_dependencies succeeds for a skill with a cpanfile' ) or diag $dep_install->{error};
ok( -f $apt_log, '_install_skill_dependencies records an apt-get invocation when the skill ships an aptfile' );
ok( -f $cpanm_log, '_install_skill_dependencies records cpanm invocations when the skill ships Perl dependency files' );
ok( -f $dashboard_log, '_install_skill_dependencies records dashboard install invocations when the skill ships a ddfile' );
open my $dependency_log_fh, '<', $dependency_log or die "Unable to read $dependency_log: $!";
my @dependency_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$dependency_log_fh>;
close $dependency_log_fh;
is_deeply(
    [ map { (/^(DDFILE_LOCAL|DDFILE|APT|BREW|NPM|CPANM):/)[0] } @dependency_steps[-6 .. -1] ],
    [ 'APT', 'NPM', 'CPANM', 'CPANM', 'DDFILE', 'DDFILE_LOCAL' ],
    '_install_skill_dependencies follows the documented aptfile -> apkfile -> dnfile -> brewfile -> package.json -> cpanfile -> cpanfile.local -> ddfile -> ddfile.local order on Debian-like hosts while leaving apkfile, dnfile, and brewfile inactive',
);
open my $cpanm_log_fh, '<', $cpanm_log or die "Unable to read $cpanm_log: $!";
my @cpanm_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$cpanm_log_fh>;
close $cpanm_log_fh;
like( $cpanm_steps[-2], qr/^--notest -L \Q$ENV{HOME}\/skills-home\/perl5\E --cpanfile .*\/cpanfile --installdeps /, '_install_skill_dependencies installs cpanfile dependencies into HOME perl5 with cpanm --notest' );
like( $cpanm_steps[-1], qr/^--notest -L .*\/perl5 --cpanfile .*\/cpanfile\.local --installdeps /, '_install_skill_dependencies installs cpanfile.local dependencies into the skill-local perl5 root with cpanm --notest' );
open my $npm_log_fh, '<', $npx_log or die "Unable to read $npx_log: $!";
my @npm_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$npm_log_fh>;
close $npm_log_fh;
like(
    $npm_steps[-1],
    qr/^--yes npm install dep-skill-runtime\@\^1\.2\.3 dep-skill-dev\@\^4\.5\.6\|cwd=\Q$ENV{HOME}\E\/skills-home\/\.developer-dashboard\/cache\/node-package-installs\/npm-install-/,
    '_install_skill_dependencies stages package.json work under the dashboard runtime cache through npx instead of using bare HOME as the npm project root',
);
ok( -d File::Spec->catdir( $ENV{HOME}, 'skills-home', 'node_modules', 'dep-skill-runtime' ), '_install_skill_dependencies merges staged Node dependencies into the manager HOME node_modules tree' );
ok( -d File::Spec->catdir( $ENV{HOME}, 'skills-home', 'node_modules', 'dep-skill-dev' ), '_install_skill_dependencies merges staged dev Node dependencies into the manager HOME node_modules tree' );
{
    local $ENV{DD_TEST_APT_INSTALLED} = 'git';
    unlink $apt_log;
    my $partial_apt = $manager->_install_skill_aptfile( $dep_skill_root );
    ok( !$partial_apt->{error}, '_install_skill_aptfile succeeds when only some Debian packages are already installed' )
      or diag $partial_apt->{error};
    open my $partial_apt_fh, '<', $apt_log or die "Unable to read $apt_log: $!";
    my @partial_apt_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$partial_apt_fh>;
    close $partial_apt_fh;
    is( $partial_apt_steps[-1], 'install -y curl', '_install_skill_aptfile only installs the Debian packages that are still missing' );
}
{
    local $ENV{DD_TEST_APT_INSTALLED} = 'git,curl';
    unlink $apt_log;
    unlink $sudo_log;
    my $skip_apt = $manager->_install_skill_aptfile( $dep_skill_root );
    ok( !$skip_apt->{error}, '_install_skill_aptfile succeeds when every Debian package from aptfile is already installed' )
      or diag $skip_apt->{error};
    ok( $skip_apt->{skipped}, '_install_skill_aptfile reports a skip when every Debian package from aptfile is already installed' );
    is( $skip_apt->{skip_reason}, 'all aptfile packages already installed', '_install_skill_aptfile returns the explicit Debian package skip reason' );
    ok( !-f $apt_log, '_install_skill_aptfile does not run apt-get when every Debian package from aptfile is already installed' );
    ok( !-f $sudo_log, '_install_skill_aptfile does not run sudo when every Debian package from aptfile is already installed' );
    is(
        $manager->_dependency_progress_label( 'install_aptfile', $dep_skill_root, result => $skip_apt ),
        'Install aptfile dependencies (skipped: all aptfile packages already installed)',
        '_dependency_progress_label reports the explicit Debian package skip reason',
    );
}
my $browser_like_package_json = File::Spec->catfile( $ENV{HOME}, 'browser-like-package.json' );
_write_file(
    $browser_like_package_json,
    qq|{"name":"browser-like","version":"0.01.0","dependencies":{"express":"^4.19.2","uuid":"^11.0.0"},"devDependencies":{"playwright":"^1.52.0"}}\n|,
);
is_deeply(
    [ $manager->_package_json_dependency_specs($browser_like_package_json) ],
    [ 'express@^4.19.2', 'uuid@^11.0.0', 'playwright@^1.52.0' ],
    '_package_json_dependency_specs extracts installable dependency specs even when the skill version itself is npm-invalid',
);
my $empty_package_json = File::Spec->catfile( $ENV{HOME}, 'empty-package.json' );
_write_file( $empty_package_json, qq|{"name":"empty-node","version":"1.0.0"}\n| );
is_deeply(
    [ $manager->_package_json_dependency_specs($empty_package_json) ],
    [],
    '_package_json_dependency_specs returns an empty install list when package.json declares no installable dependency sections',
);
_write_file( File::Spec->catfile( $ENV{HOME}, 'package.json' ), qq|{"name":"home-project","version":"0.01.0"}\n| );
my $home_manifest_skill = File::Spec->catdir( $ENV{HOME}, 'home-manifest-skill' );
make_path($home_manifest_skill);
_write_file(
    File::Spec->catfile( $home_manifest_skill, 'package.json' ),
    qq|{"name":"staged-node-skill","version":"0.01.0","dependencies":{"left-pad":"1.3.0"}}\n|,
);
my $home_manifest_result = $manager->_install_skill_package_json($home_manifest_skill);
ok( !$home_manifest_result->{error}, '_install_skill_package_json ignores an npm-invalid HOME/package.json by using a private staging workspace' )
  or diag $home_manifest_result->{error};
ok( -d File::Spec->catdir( $ENV{HOME}, 'skills-home', 'node_modules', 'left-pad' ), '_install_skill_package_json still lands packages in the manager HOME node_modules tree when HOME/package.json is npm-invalid' );
{
    local $ENV{DD_TEST_NPM_NO_MODULES} = '1';
    my $no_modules_result = $manager->_install_skill_package_json($home_manifest_skill);
    ok( !$no_modules_result->{error}, '_install_skill_package_json treats a successful npm run without a node_modules tree as a successful no-op merge' )
      or diag $no_modules_result->{error};
}
my $metadata = $manager->list->[0];
ok( $metadata->{enabled}, 'skill metadata records enabled state for active skills' );
is( $metadata->{has_config}, 1, 'skill metadata records config presence' );
is( $metadata->{has_ddfile}, 1, 'skill metadata records ddfile presence' );
is( $metadata->{has_cpanfile}, 1, 'skill metadata records cpanfile presence' );
is( $metadata->{has_aptfile}, 1, 'skill metadata records aptfile presence' );
is( $metadata->{has_apkfile}, 1, 'skill metadata records apkfile presence' );
is( $metadata->{has_cpanfile_local}, 1, 'skill metadata records cpanfile.local presence' );
is_deeply( $metadata->{docker_services}, ['postgres'], 'skill metadata records docker service folders' );
is_deeply( $metadata->{cli_commands}, ['run-test'], 'skill metadata records cli commands only, not hook directories' );
is( $metadata->{pages_count}, 2, 'skill metadata records non-nav page counts' );
is( $metadata->{docker_services_count}, 1, 'skill metadata records docker service counts' );
is_deeply( $manager->enable(''), { error => 'Missing repo name' }, 'enable rejects an empty repo name' );
is_deeply( $manager->disable(''), { error => 'Missing repo name' }, 'disable rejects an empty repo name' );
is_deeply( $manager->usage(''), { error => 'Missing repo name' }, 'usage rejects an empty repo name' );
is_deeply( $manager->enable('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'enable rejects unknown skills' );
is_deeply( $manager->disable('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'disable rejects unknown skills' );
is_deeply( $manager->usage('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'usage rejects unknown skills' );
my $usage = $manager->usage('dep-skill');
ok( !$usage->{error}, 'usage succeeds for an installed skill' ) or diag $usage->{error};
ok( $usage->{enabled}, 'usage reports enabled state for active skills' );
ok( scalar( grep { $_->{name} eq 'run-test' && $_->{has_hooks} } @{ $usage->{cli} } ), 'usage reports command hook metadata' );
ok( scalar( grep { $_ eq 'index' } @{ $usage->{pages}{entries} } ), 'usage reports dashboard pages' );
ok( scalar( grep { $_ eq 'nav/skill.tt' } @{ $usage->{pages}{nav_entries} } ), 'usage reports nav pages separately' );
ok( scalar( grep { $_->{name} eq 'postgres' } @{ $usage->{docker}{services} } ), 'usage reports docker services' );
my $manual_skill_root = $skill_paths->skill_root('layout-skill');
make_path($manual_skill_root);
ok( $manager->_prepare_skill_layout($manual_skill_root), '_prepare_skill_layout succeeds for a partially populated skill root' );
ok( -f File::Spec->catfile( $manual_skill_root, 'config', 'config.json' ), '_prepare_skill_layout creates a missing config.json file' );

my $layered_project_root = File::Spec->catdir( $test_repos, 'layered-project' );
my $layered_work_root = File::Spec->catdir( $layered_project_root, 'workspace' );
make_path( File::Spec->catdir( $layered_project_root, '.developer-dashboard' ) );
make_path( File::Spec->catdir( $layered_project_root, '.git' ) );
make_path($layered_work_root);
my $layered_home_only_repo = _create_skill_repo( $test_repos, 'home-layer-skill', with_cpanfile => 0 );
ok( !$manager->install( 'file://' . $layered_home_only_repo )->{error}, 'home-only layered fixture skill installs cleanly' );
my $shared_layer_repo = _create_skill_repo( $test_repos, 'shared-layer-skill', with_cpanfile => 0 );
ok( !$manager->install( 'file://' . $shared_layer_repo )->{error}, 'shared layered fixture skill installs into the home layer first' );
{
    my $cwd = getcwd();
    chdir $shared_layer_repo or die "Unable to chdir to $shared_layer_repo: $!";
    _write_file(
        File::Spec->catfile( 'cli', 'run-test' ),
        "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{project-layer\\n};\n",
        0755,
    );
    _write_file(
        File::Spec->catfile( 'cli', 'run-test.d', '00-pre.pl' ),
        "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{project-hook\\n};\n",
        0755,
    );
    _write_file(
        File::Spec->catfile( 'config', 'config.json' ),
        json_encode(
            {
                skill_name => 'shared-layer-skill',
                collectors => [
                    { name => 'alpha', interval => 20 },
                    { name => 'beta',  interval => 30 },
                ],
                providers => [
                    { id => 'main',  title => 'Project' },
                    { id => 'extra', title => 'Extra' },
                ],
            }
        ) . "\n",
    );
    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', 'Project layer variant' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
{
    my $cwd = getcwd();
    chdir $layered_work_root or die "Unable to chdir to $layered_work_root: $!";
    my $layered_paths = Developer::Dashboard::PathRegistry->new( home => File::Spec->catdir( $ENV{HOME}, 'skills-home' ) );
    my $layered_manager = Developer::Dashboard::SkillManager->new( paths => $layered_paths );
    is(
        $layered_paths->skills_root,
        File::Spec->catdir( $layered_project_root, '.developer-dashboard', 'skills' ),
        'skills_root writes to the deepest participating DD-OOP-LAYER',
    );
    is_deeply(
        [ $layered_paths->skills_roots ],
        [
            File::Spec->catdir( $layered_project_root, '.developer-dashboard', 'skills' ),
            File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills' ),
        ],
        'skills_roots resolves layered skill roots in deepest-first lookup order',
    );
    ok( !$layered_manager->install( 'file://' . $shared_layer_repo )->{error}, 'layered manager installs the shared skill into the project layer without clashing with the home copy' );
    is_deeply(
        [ $layered_paths->skill_roots_for('shared-layer-skill') ],
        [
            File::Spec->catdir( $layered_project_root, '.developer-dashboard', 'skills', 'shared-layer-skill' ),
            File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'shared-layer-skill' ),
        ],
        'skill_roots_for resolves one layered skill in deepest-first lookup order',
    );
    is(
        $layered_manager->get_skill_path('shared-layer-skill'),
        File::Spec->catdir( $layered_project_root, '.developer-dashboard', 'skills', 'shared-layer-skill' ),
        'get_skill_path prefers the deepest matching layered skill',
    );
    is(
        $layered_manager->get_skill_path('home-layer-skill'),
        File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'home-layer-skill' ),
        'get_skill_path still inherits home-layer skills when no deeper override exists',
    );
    my $layered_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $layered_paths );
    my $layered_hooks = $layered_dispatcher->execute_hooks( 'shared-layer-skill', 'run-test' );
    ok(
        exists $layered_hooks->{hooks}{'00-pre.pl'},
        'execute_hooks keeps the first hook basename for the first matching layered hook',
    );
    ok(
        exists $layered_hooks->{hooks}{'run-test.d/00-pre.pl'},
        'execute_hooks namespaces duplicate layered hook basenames by hook directory leaf',
    );
    my $layered_stream_hooks = $layered_dispatcher->_execute_hooks_streaming(
        'shared-layer-skill',
        'run-test',
        [ $layered_manager->get_skill_path('shared-layer-skill'), File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'shared-layer-skill' ) ],
    );
    ok(
        exists $layered_stream_hooks->{hooks}{'run-test.d/00-pre.pl'},
        '_execute_hooks_streaming namespaces duplicate layered hook basenames by hook directory leaf',
    );
    is_deeply(
        $layered_dispatcher->get_skill_config('shared-layer-skill'),
        {
            skill_name => 'shared-layer-skill',
            collectors => [
                { name => 'alpha', interval => 20 },
                { name => 'beta',  interval => 30 },
            ],
            providers => [
                { id => 'main',  title => 'Project' },
                { id => 'extra', title => 'Extra' },
            ],
        },
        'get_skill_config merges layered collector and provider arrays by logical identity',
    );
    is_deeply(
        [ map { File::Basename::basename($_) } $layered_paths->installed_skill_roots ],
        [ 'shared-layer-skill', 'dep-skill', 'home-layer-skill', 'layout-skill' ],
        'installed_skill_roots exposes the effective layered skill set once per repo name',
    );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}

my $no_dep_repo = _create_skill_repo( $test_repos, 'no-dep-skill', with_cpanfile => 0 );
ok( !$manager->install( 'file://' . $no_dep_repo )->{error}, 'skill manager installs skills without a cpanfile' );
{
    local $ENV{DD_TEST_CPANM_FAIL} = 1;
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-dep-skill' );
    make_path($fail_repo);
    _write_file( File::Spec->catfile( $fail_repo, 'cpanfile' ), "requires 'JSON::XS';\n" );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install skill dependencies/,
        'install reports isolated dependency installation failures',
    );
}
{
    local $ENV{DD_TEST_ALPINE} = 1;
    my $apk_repo = File::Spec->catdir( $test_repos, 'apk-skill' );
    make_path($apk_repo);
    _write_file( File::Spec->catfile( $apk_repo, 'apkfile' ), "procps-dev\n" );
    unlink $apk_log;
    my $apk_install = $manager->_install_skill_dependencies($apk_repo);
    ok( !$apk_install->{error}, '_install_skill_dependencies succeeds for apkfile-driven installs on Alpine' ) or diag $apk_install->{error};
    ok( -f $apk_log, '_install_skill_dependencies records an apk invocation when the skill ships an apkfile on Alpine' );
}
{
    local $ENV{DD_TEST_ALPINE} = 1;
    local $ENV{DD_TEST_APK_INSTALLED} = 'procps-dev';
    my $apk_repo = File::Spec->catdir( $test_repos, 'apk-skip-skill' );
    make_path($apk_repo);
    _write_file( File::Spec->catfile( $apk_repo, 'apkfile' ), "procps-dev\n" );
    unlink $apk_log;
    unlink $sudo_log;
    my $skip_apk = $manager->_install_skill_dependencies($apk_repo);
    ok( !$skip_apk->{error}, '_install_skill_dependencies succeeds for apkfile-driven installs on Alpine when every package is already installed' )
      or diag $skip_apk->{error};
    ok( !-f $apk_log, '_install_skill_dependencies skips apk add when every Alpine package is already installed' );
    ok( !-f $sudo_log, '_install_skill_dependencies skips sudo when every Alpine package is already installed' );
    is(
        $manager->_dependency_progress_label(
            'install_apkfile',
            $apk_repo,
            result => {
                success     => 1,
                skipped     => 1,
                skip_reason => 'all apkfile packages already installed',
            }
        ),
        'Install apkfile dependencies (skipped: all apkfile packages already installed)',
        '_dependency_progress_label reports the explicit Alpine package skip reason',
    );
}
{
    local $ENV{DD_TEST_APK_FAIL} = 1;
    local $ENV{DD_TEST_ALPINE} = 1;
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-apk-skill' );
    make_path($fail_repo);
    _write_file( File::Spec->catfile( $fail_repo, 'apkfile' ), "procps-dev\n" );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install skill apk dependencies/,
        'install reports apk dependency installation failures',
    );
}
{
    local $ENV{DD_TEST_APT_FAIL} = 1;
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-apt-skill' );
    make_path($fail_repo);
    _write_file( File::Spec->catfile( $fail_repo, 'aptfile' ), "git\n" );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install skill apt dependencies/,
        'install reports isolated apt dependency installation failures',
    );
}
{
    local $ENV{DD_TEST_OS} = 'darwin';
    my $brew_repo = File::Spec->catdir( $test_repos, 'brew-skill' );
    make_path($brew_repo);
    _write_file( File::Spec->catfile( $brew_repo, 'brewfile' ), "jq\n" );
    unlink $brew_log;
    my $brew_install = $manager->_install_skill_dependencies($brew_repo);
    ok( !$brew_install->{error}, '_install_skill_dependencies succeeds for brewfile-driven installs on macOS' ) or diag $brew_install->{error};
    ok( -f $brew_log, '_install_skill_dependencies records a brew invocation when the skill ships a brewfile on macOS' );
}
{
    local $ENV{DD_TEST_BREW_FAIL} = 1;
    local $ENV{DD_TEST_OS} = 'darwin';
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-brew-skill' );
    make_path($fail_repo);
    _write_file( File::Spec->catfile( $fail_repo, 'brewfile' ), "jq\n" );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install skill brew dependencies/,
        'install reports brew dependency installation failures',
    );
}
{
    local $ENV{DD_TEST_DDFILE_FAIL} = 1;
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-dd-skill' );
    make_path($fail_repo);
    _write_file( File::Spec->catfile( $fail_repo, 'ddfile' ), "shared-skill\n" );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install dependent skills for/,
        'install reports ddfile dependency installation failures',
    );
}
{
    local $ENV{DD_TEST_NPM_FAIL} = 1;
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-npm-skill' );
    make_path($fail_repo);
    _write_file(
        File::Spec->catfile( $fail_repo, 'package.json' ),
        qq|{"name":"fail-npm","version":"0.01.0","dependencies":{"fail-npm-runtime":"^9.9.9"}}\n|
    );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install skill Node dependencies/,
        'install reports package.json dependency installation failures',
    );
}
{
    my $missing_home = File::Spec->catdir( $test_repos, 'missing-npm-home' );
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-npm-chdir-skill' );
    make_path($fail_repo);
    _write_file(
        File::Spec->catfile( $fail_repo, 'package.json' ),
        qq|{"name":"fail-npm-chdir","version":"0.01.0","dependencies":{"fail-npm-runtime":"^9.9.9"}}\n|
    );
    my $cwd = getcwd();
    my $broken_paths = Developer::Dashboard::PathRegistry->new( home => $missing_home );
    my $broken_manager = Developer::Dashboard::SkillManager->new( paths => $broken_paths );
    my $error = eval { $broken_manager->_install_skill_package_json($fail_repo); 1 } ? '' : $@;
    like(
        $error,
        qr/Unable to chdir to \Q$missing_home\E for package\.json dependency install/,
        '_install_skill_package_json surfaces a HOME chdir failure before npm runs',
    );
    is(
        getcwd(),
        $cwd,
        '_install_skill_package_json restores the original cwd after a HOME chdir failure',
    );
}
{
    my $capture_fail_repo = File::Spec->catdir( $test_repos, 'capture-fail-npm-skill' );
    make_path($capture_fail_repo);
    _write_file(
        File::Spec->catfile( $capture_fail_repo, 'package.json' ),
        qq|{"name":"capture-fail-npm","version":"1.0.0","dependencies":{"capture-fail-runtime":"^1.0.0"}}\n|
    );
    my $cwd = getcwd();
    my $error;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::capture = sub (&) {
            die "synthetic npm capture failure\n";
        };
        $error = eval { $manager->_install_skill_package_json($capture_fail_repo); 1 } ? '' : $@;
    }
    like(
        $error,
        qr/synthetic npm capture failure/,
        '_install_skill_package_json surfaces capture failures from the staged npm install workspace',
    );
    is(
        getcwd(),
        $cwd,
        '_install_skill_package_json restores the original cwd after a staged npm capture failure',
    );
}
{
    my $installed_dep = File::Spec->catdir( $skill_paths->skills_root, 'shared-skill' );
    make_path($installed_dep);
    my $skip_repo = File::Spec->catdir( $test_repos, 'skip-dd-skill' );
    make_path($skip_repo);
    _write_file( File::Spec->catfile( $skip_repo, 'ddfile' ), "shared-skill\nfresh-skill\n" );
    unlink $dashboard_log;
    my $skip_install = $manager->_install_skill_dependencies($skip_repo);
    ok( !$skip_install->{error}, '_install_skill_dependencies skips already-installed ddfile dependencies without looping' ) or diag $skip_install->{error};
    open my $dashboard_log_fh, '<', $dashboard_log or die "Unable to read $dashboard_log: $!";
    my @dashboard_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$dashboard_log_fh>;
    close $dashboard_log_fh;
    is_deeply( \@dashboard_steps, ['skills install fresh-skill'], '_install_skill_dependencies skips installed skills and only installs missing ddfile dependencies' );
}
{
    my $stacked_repo = File::Spec->catdir( $test_repos, 'stacked-dd-skill' );
    make_path($stacked_repo);
    _write_file( File::Spec->catfile( $stacked_repo, 'ddfile' ), "stacked-skill\nfresh-skill\n" );

    open my $dashboard_script_fh, '<', File::Spec->catfile( $fake_bin, 'dashboard' ) or die "Unable to read fake dashboard script: $!";
    my $original_dashboard_script = do { local $/; <$dashboard_script_fh> };
    close $dashboard_script_fh;

    _write_file(
        File::Spec->catfile( $fake_bin, 'dashboard' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$dashboard_log"
printf 'DDFILE:%s\\n' "\$*" >> "$dependency_log"
printf 'installed:%s\\n' "\$3"
printf 'warning:%s\\n' "\$3" >&2
if [ "\$DD_TEST_DDFILE_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
        0755,
    );

    unlink $dashboard_log;
    local $ENV{DEVELOPER_DASHBOARD_INSTALL_STACK} = 'stacked-skill';
    my $stacked_install = $manager->_install_skill_ddfile($stacked_repo);
    ok( !$stacked_install->{error}, '_install_skill_ddfile skips dependencies already present in the install stack' ) or diag $stacked_install->{error};
    is( $stacked_install->{stdout}, "installed:fresh-skill\n", '_install_skill_ddfile returns captured stdout when a dependent install emits output' );
    is( $stacked_install->{stderr}, "warning:fresh-skill\n", '_install_skill_ddfile returns captured stderr when a dependent install emits warnings' );

    open my $stacked_dashboard_log_fh, '<', $dashboard_log or die "Unable to read $dashboard_log after stacked ddfile install: $!";
    my @stacked_dashboard_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$stacked_dashboard_log_fh>;
    close $stacked_dashboard_log_fh;
    is_deeply( \@stacked_dashboard_steps, ['skills install fresh-skill'], '_install_skill_ddfile only invokes dashboard install for dependencies missing from the current install stack' );

    _write_file( File::Spec->catfile( $fake_bin, 'dashboard' ), $original_dashboard_script, 0755 );
}
{
    my $bad_root_repo = File::Spec->catdir( $test_repos, 'bad-root-dd-skill' );
    make_path($bad_root_repo);
    _write_file( File::Spec->catfile( $bad_root_repo, 'ddfile' ), "fresh-skill\n" );

    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_skill_install_root = sub { '/definitely/missing-skill-root' };

    my $error = eval { $manager->_install_skill_ddfile($bad_root_repo); 1 } ? '' : $@;
    like(
        $error,
        qr/Unable to chdir to \/definitely\/missing-skill-root for ddfile dependency install/,
        '_install_skill_ddfile surfaces skill-root chdir failures explicitly',
    );
}
{
    my $local_repo = File::Spec->catdir( $test_repos, 'stacked-dd-local-skill' );
    my $skills_root = File::Spec->catdir( $test_repos, 'stacked-dd-local-root', 'skills' );
    make_path($skills_root);
    make_path($local_repo);
    _write_file( File::Spec->catfile( $local_repo, 'ddfile.local' ), "fresh-local-skill\n" );

    unlink $dashboard_log;
    my $cwd = getcwd();
    chdir $skills_root or die "Unable to chdir to $skills_root: $!";
    my $local_install = $manager->_install_skill_ddfile_local($local_repo);
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    ok( !$local_install->{error}, '_install_skill_ddfile_local installs dependencies at the current skills root level' ) or diag $local_install->{error};

    open my $local_dashboard_log_fh, '<', $dashboard_log or die "Unable to read $dashboard_log after ddfile.local install: $!";
    my @local_dashboard_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$local_dashboard_log_fh>;
    close $local_dashboard_log_fh;
    is_deeply( \@local_dashboard_steps, ['skills install fresh-local-skill'], '_install_skill_ddfile_local invokes dashboard install for local-only dependencies' );
}
{
    my $manifest_root = File::Spec->catdir( $test_repos, 'manifest-ddfile-root' );
    my $global_repo = _create_skill_repo( $test_repos, 'manifest-global-skill', with_cpanfile => 0 );
    my $local_repo  = _create_skill_repo( $test_repos, 'manifest-local-skill',  with_cpanfile => 0 );
    make_path($manifest_root);
    _write_file( File::Spec->catfile( $manifest_root, 'ddfile' ), "file://$global_repo\n" );
    _write_file( File::Spec->catfile( $manifest_root, 'ddfile.local' ), "file://$local_repo\n" );

    my $manifest_install = $manager->install_from_ddfiles($manifest_root);
    ok( !$manifest_install->{error}, 'install_from_ddfiles installs both ddfile and ddfile.local manifests successfully' )
      or diag $manifest_install->{error};
    ok(
        -d File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'manifest-global-skill' ),
        'install_from_ddfiles writes ddfile dependencies into the home DD-OOP-LAYER skills root',
    );
    ok(
        !-d File::Spec->catdir( $manifest_root, '.developer-dashboard', 'skills', 'manifest-global-skill' ),
        'install_from_ddfiles does not write ddfile dependencies into a child DD-OOP-LAYER skills root under the current directory',
    );
    ok(
        -d File::Spec->catdir( $manifest_root, 'skills', 'manifest-local-skill' ),
        'install_from_ddfiles writes ddfile.local dependencies into the current skill-local skills root',
    );
    is_deeply(
        $manifest_install->{operations},
        [
            {
                manifest  => 'ddfile',
                source    => "file://$global_repo",
                repo_name => 'manifest-global-skill',
                path      => File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'manifest-global-skill' ),
            },
            {
                manifest  => 'ddfile.local',
                source    => "file://$local_repo",
                repo_name => 'manifest-local-skill',
                path      => File::Spec->catdir( $manifest_root, 'skills', 'manifest-local-skill' ),
            },
        ],
        'install_from_ddfiles processes ddfile before ddfile.local',
    );
}
{
    my $manifest_root = File::Spec->catdir( $test_repos, 'manifest-reinstall-root' );
    my $global_repo = _create_skill_repo( $test_repos, 'manifest-reinstall-skill', with_cpanfile => 0 );
    make_path($manifest_root);
    _write_file( File::Spec->catfile( $manifest_root, 'ddfile' ), "file://$global_repo\n" );

    my $first_manifest_install = $manager->install_from_ddfiles($manifest_root);
    ok( !$first_manifest_install->{error}, 'install_from_ddfiles installs a manifest-listed skill the first time' )
      or diag $first_manifest_install->{error};
    my $global_skill_root = File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'manifest-reinstall-skill' );
    _write_file( File::Spec->catfile( $global_repo, 'cli', 'run-test' ), "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{manifest-refresh\\n};\n", 0755 );
    {
        my $cwd = getcwd();
        chdir $global_repo or die "Unable to chdir to $global_repo: $!";
        _run_or_die(qw(git add .));
        _run_or_die( 'git', 'commit', '-m', 'Refresh manifest reinstall skill' );
        chdir $cwd or die "Unable to chdir back to $cwd: $!";
    }

    my $second_manifest_install = $manager->install_from_ddfiles($manifest_root);
    ok( !$second_manifest_install->{error}, 'install_from_ddfiles reinstalls already-installed manifest skills as updates' )
      or diag $second_manifest_install->{error};
    my $manifest_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $skill_paths );
    like(
        $manifest_dispatcher->dispatch( 'manifest-reinstall-skill', 'run-test' )->{stdout},
        qr/manifest-refresh/,
        'manifest-driven install refreshes the installed skill content on repeat runs',
    );
    ok( -d $global_skill_root, 'manifest reinstall keeps the target skill installed after refresh' );
}
{
    my $missing_manifest_root = File::Spec->catdir( $test_repos, 'missing-manifest-root' );
    make_path($missing_manifest_root);
    is_deeply(
        $manager->install_from_ddfiles($missing_manifest_root),
        { error => "No ddfile or ddfile.local found under $missing_manifest_root" },
        'install_from_ddfiles rejects roots with no ddfile manifests',
    );
}
{
    my $broken_repo = _create_skill_repo( $test_repos, 'broken-update-skill', with_cpanfile => 0 );
    ok( !$manager->install( 'file://' . $broken_repo )->{error}, 'broken-update-skill installs cleanly' );
    my $installed_root = $manager->get_skill_path('broken-update-skill');
    _run_or_die( 'git', '-C', $installed_root, 'remote', 'set-url', 'origin', 'file:///definitely-missing-repo-path' );
    like(
        $manager->update('broken-update-skill')->{error},
        qr/Failed to update skill:/,
        'update reports git pull failures',
    );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::remove_tree = sub {
        my ( $path, $options ) = @_;
        push @{ ${ $options->{error} } }, { $path => 'boom' };
        return;
    };
    like(
        $manager->uninstall('no-dep-skill')->{error},
        qr/Failed to uninstall skill:/,
        'uninstall reports remove_tree failures',
    );
}
{
    my $replace_target = File::Spec->catdir( $test_repos, 'failing-replace-skill' );
    make_path($replace_target);
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::remove_tree = sub {
        my ( $path, $options ) = @_;
        push @{ ${ $options->{error} } }, 'replace failed';
        return;
    };
    is_deeply(
        $manager->_remove_existing_skill_path($replace_target),
        { error => "Failed to replace existing skill at $replace_target: replace failed" },
        '_remove_existing_skill_path reports remove_tree failures while replacing an installed skill',
    );
}

my $dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $skill_paths );
is_deeply( $dispatcher->dispatch( '', 'run-test' ), { error => 'Missing skill name' }, 'dispatcher rejects missing skill names' );
is_deeply( $dispatcher->dispatch( 'dep-skill', '' ), { error => 'Missing command name' }, 'dispatcher rejects missing command names' );
is_deeply( $dispatcher->exec_command( '', 'run-test' ), { error => 'Missing skill name' }, 'exec_command rejects missing skill names' );
is_deeply( $dispatcher->exec_command( 'dep-skill', '' ), { error => 'Missing command name' }, 'exec_command rejects missing command names' );
{
    my $missing_skill = $dispatcher->dispatch( 'missing-skill', 'run-test' );
    like( $missing_skill->{error}, qr/\ASkill 'missing-skill' not found\./, 'dispatcher rejects missing skills' );
    like( $missing_skill->{error}, qr/\n\nDid you mean:\n/, 'missing-skill dispatch guidance includes suggestion heading' );
}
{
    my $missing_exec = $dispatcher->exec_command( 'missing-skill', 'run-test' );
    like( $missing_exec->{error}, qr/\ASkill 'missing-skill' not found\./, 'exec_command rejects missing skills' );
    like( $missing_exec->{error}, qr/\n\nDid you mean:\n/, 'missing-skill exec guidance includes suggestion heading' );
}
is_deeply( $dispatcher->execute_hooks( '', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for missing skill names' );
is_deeply( $dispatcher->execute_hooks( 'dep-skill', '' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for missing command names' );
is_deeply( $dispatcher->execute_hooks( 'missing-skill', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for missing skills' );
is_deeply( $dispatcher->_execute_hooks_streaming( '', 'run-test', [] ), { hooks => {}, result_state => {} }, '_execute_hooks_streaming returns an empty payload for missing skill names' );
is_deeply( $dispatcher->_execute_hooks_streaming( 'dep-skill', '', [] ), { hooks => {}, result_state => {} }, '_execute_hooks_streaming returns an empty payload for missing command names' );
is_deeply( $dispatcher->_execute_hooks_streaming( 'dep-skill', 'run-test', [] ), { hooks => {}, result_state => {} }, '_execute_hooks_streaming returns an empty payload when no skill layers participate' );
ok( !$manager->disable('dep-skill')->{error}, 'disable succeeds for an installed skill' );
ok( !$manager->is_enabled('dep-skill'), 'is_enabled reports false once a skill is disabled' );
my @enabled_skill_roots = $skill_paths->installed_skill_roots;
my @all_skill_roots = $skill_paths->installed_skill_roots( include_disabled => 1 );
ok( !grep( { $_ eq $dep_skill_root } @enabled_skill_roots ), 'installed_skill_roots excludes disabled skills by default' );
ok( grep( { $_ eq $dep_skill_root } @all_skill_roots ), 'installed_skill_roots can still enumerate disabled skills when requested' );
is( $manager->get_skill_path('dep-skill'), undef, 'get_skill_path hides disabled skills from normal runtime lookup' );
ok( $manager->get_skill_path( 'dep-skill', include_disabled => 1 ), 'get_skill_path can still resolve disabled skills when explicitly requested' );
is_deeply(
    $dispatcher->dispatch( 'dep-skill', 'run-test' ),
    {
        error => "Skill 'dep-skill' is disabled.\n\nEnable it with:\n  dashboard skills enable dep-skill\n",
    },
    'dispatcher rejects disabled skills explicitly',
);
is_deeply( $dispatcher->execute_hooks( 'dep-skill', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for disabled skills' );
is_deeply( $dispatcher->get_skill_config('dep-skill'), {}, 'get_skill_config hides disabled skill config from runtime callers' );
ok( !$manager->usage('dep-skill')->{enabled}, 'usage still works for disabled skills and reports them as disabled' );
ok( !$manager->enable('dep-skill')->{error}, 'enable restores a disabled skill' );
ok( $manager->is_enabled('dep-skill'), 'is_enabled reports true after re-enabling a skill' );
my $hookless_repo = _create_skill_repo( $test_repos, 'hookless-skill', with_hook => 0, with_cpanfile => 0 );
ok( !$manager->install( 'file://' . $hookless_repo )->{error}, 'hookless skill installs cleanly' );
is_deeply( $dispatcher->execute_hooks( 'hookless-skill', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result when no hook directory exists' );
is_deeply( $dispatcher->get_skill_config(''), {}, 'get_skill_config returns an empty hash for empty skill names' );
is_deeply( $dispatcher->get_skill_config('missing-skill'), {}, 'get_skill_config returns an empty hash for missing skills' );
is_deeply(
    $dispatcher->get_skill_config('dep-skill'),
    { skill_name => 'dep-skill' },
    'get_skill_config returns the decoded skill-local config payload',
);
my $invalid_config_root = $manager->get_skill_path('hookless-skill');
_write_file( File::Spec->catfile( $invalid_config_root, 'config', 'config.json' ), "{not json}\n" );
is_deeply( $dispatcher->get_skill_config('hookless-skill'), {}, 'get_skill_config falls back to an empty hash for invalid JSON config' );
is( $dispatcher->get_skill_path(''), undef, 'get_skill_path returns undef for empty skill names' );
is( $dispatcher->get_skill_path('dep-skill'), $manager->get_skill_path('dep-skill'), 'get_skill_path returns the installed skill path for valid skills' );
{
    my $fallback_dispatcher = bless {
        manager => bless(
            {
                paths => bless( {}, 'Local::NoSkillLayerPaths' ),
            },
            'Local::FallbackSkillManager'
        ),
    }, 'Developer::Dashboard::SkillDispatcher';
    no warnings qw(redefine once);
    local *Local::FallbackSkillManager::get_skill_path = sub {
        my ( $self, $skill_name ) = @_;
        return '' if !$skill_name;
        return '/tmp/fallback-skill-root';
    };
    is_deeply(
        [ $fallback_dispatcher->_skill_layers('fallback-skill') ],
        ['/tmp/fallback-skill-root'],
        '_skill_layers falls back to manager get_skill_path when the path registry does not expose layered helpers',
    );
}
is( $dispatcher->command_path( '', 'run-test' ), undef, 'command_path returns undef for missing skill names' );
is( $dispatcher->command_path( 'dep-skill', '' ), undef, 'command_path returns undef for missing command names' );
is( $dispatcher->command_path( 'missing-skill', 'run-test' ), undef, 'command_path returns undef for unknown skills' );
is( $dispatcher->command_path( 'dep-skill', 'missing' ), undef, 'command_path returns undef for missing skill commands' );
is( $dispatcher->command_spec( '', 'run-test' ), undef, 'command_spec returns undef for missing skill names' );
is(
    $dispatcher->command_spec( 'dep-skill', 'run-test' )->{cmd_path},
    File::Spec->catfile( $dep_skill_root, 'cli', 'run-test' ),
    'command_spec returns the resolved command metadata for a valid installed skill command',
);
make_path( File::Spec->catdir( $dep_skill_root, 'skills', 'foo', 'cli' ) );
_write_file(
    File::Spec->catfile( $dep_skill_root, 'skills', 'foo', 'cli', 'foo' ),
    "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{nested-coverage\\n};\n",
    0755,
);
make_path( File::Spec->catdir( $dep_skill_root, 'skills', 'level1', 'skills', 'level2', 'cli' ) );
_write_file(
    File::Spec->catfile( $dep_skill_root, 'skills', 'level1', 'skills', 'level2', 'cli', 'here' ),
    "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{deep-nested-coverage\\n};\n",
    0755,
);
is(
    $dispatcher->command_path( 'dep-skill', 'foo.foo' ),
    File::Spec->catfile( $dep_skill_root, 'skills', 'foo', 'cli', 'foo' ),
    'command_path resolves nested skills/<repo>/cli commands inside one installed skill',
);
is(
    $dispatcher->dispatch( 'dep-skill', 'foo.foo' )->{stdout},
    "nested-coverage\n",
    'dispatcher executes nested skills/<repo>/cli commands inside one installed skill',
);
is(
    $dispatcher->command_path( 'dep-skill', 'level1.level2.here' ),
    File::Spec->catfile( $dep_skill_root, 'skills', 'level1', 'skills', 'level2', 'cli', 'here' ),
    'command_path resolves multi-level nested skills/<repo>/.../skills/<repo>/cli commands inside one installed skill',
);
is(
    $dispatcher->dispatch( 'dep-skill', 'level1.level2.here' )->{stdout},
    "deep-nested-coverage\n",
    'dispatcher executes multi-level nested skills/<repo>/.../skills/<repo>/cli commands inside one installed skill',
);
is_deeply(
    [ $dispatcher->command_hook_paths( 'dep-skill', 'run-test' ) ],
    [ File::Spec->catfile( $dep_skill_root, 'cli', 'run-test.d', '00-pre.pl' ) ],
    'command_hook_paths lists participating skill hook files in execution order',
);
is_deeply(
    [ $dispatcher->command_hook_paths( 'dep-skill', 'level1.level2.here' ) ],
    [],
    'command_hook_paths returns an empty list when a nested skill command has no hook directory',
);
{
    my $missing_command = $dispatcher->dispatch( 'dep-skill', 'missing' );
    like( $missing_command->{error}, qr/\ACommand 'missing' not found in skill 'dep-skill'\./, 'dispatcher rejects missing commands inside installed skills' );
    like( $missing_command->{error}, qr/\n\nDid you mean:\n/, 'missing skill command guidance includes suggestion heading' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::execute_hooks = sub {
        return { error => 'hook failure' };
    };
    is_deeply(
        $dispatcher->dispatch( 'dep-skill', 'run-test' ),
        { error => 'hook failure' },
        'dispatcher returns hook execution errors before launching the main skill command',
    );
}
{
    my $streaming_dir = tempdir( CLEANUP => 1 );
    my $streaming_script = File::Spec->catfile( $streaming_dir, 'stream-child.pl' );
    _write_file(
        $streaming_script,
        <<'PERL',
#!/usr/bin/env perl
use strict;
use warnings;
$| = 1;
print "stream-out:$ENV{SKILL_COMMAND}\n";
print STDERR "stream-err\n";
exit 7;
PERL
        0755,
    );
    my ( $stdout, $stderr, $result ) = capture {
        $dispatcher->_run_child_command_streaming(
            command      => [ $^X, $streaming_script ],
            args         => [],
            env          => { SKILL_COMMAND => 'run-test' },
            skill_layers => [$dep_skill_root],
            result_state => {},
            last_result  => {},
            stdin_mode   => 'null',
        );
    };
    is( $stdout, "stream-out:run-test\n", '_run_child_command_streaming mirrors child stdout while using null stdin for hooks' );
    is( $stderr, "stream-err\n", '_run_child_command_streaming mirrors child stderr while using null stdin for hooks' );
    is( $result->{stdout}, "stream-out:run-test\n", '_run_child_command_streaming captures child stdout for RESULT handoff' );
    is( $result->{stderr}, "stream-err\n", '_run_child_command_streaming captures child stderr for RESULT handoff' );
    is( $result->{exit_code}, 7, '_run_child_command_streaming captures the child exit code' );
}
{
    my $streaming_dir = tempdir( CLEANUP => 1 );
    my $streaming_script = File::Spec->catfile( $streaming_dir, 'stream-last-result.pl' );
    _write_file(
        $streaming_script,
        <<'PERL',
#!/usr/bin/env perl
use strict;
use warnings;
print "stream-last-result\n";
exit 0;
PERL
        0755,
    );
    local *Developer::Dashboard::Runtime::Result::set_last_result = sub {
        my ( $payload ) = @_;
        $main::dd_last_result_payload = $payload;
        return;
    };
    local $main::dd_last_result_payload;
    my ( $stdout, $stderr, $result ) = capture {
        $dispatcher->_run_child_command_streaming(
            command      => [ $^X, $streaming_script ],
            args         => [],
            env          => {},
            skill_layers => [$dep_skill_root],
            result_state => {},
            last_result  => { file => '/tmp/previous-hook', exit => 0, STDOUT => "old\n", STDERR => '' },
            stdin_mode   => 'null',
        );
    };
    is( $stdout, "stream-last-result\n", '_run_child_command_streaming still mirrors stdout when a prior RESULT payload exists' );
    is( $stderr, '', '_run_child_command_streaming keeps stderr empty when a prior RESULT payload exists and the child emits no stderr' );
    is_deeply(
        $main::dd_last_result_payload,
        { file => '/tmp/previous-hook', exit => 0, STDOUT => "old\n", STDERR => '' },
        '_run_child_command_streaming reloads the previous RESULT payload before launching the child',
    );
    is( $result->{exit_code}, 0, '_run_child_command_streaming preserves successful exit codes while restoring the previous RESULT payload' );
}
{
    my $stdin_dir = tempdir( CLEANUP => 1 );
    my $stdin_script = File::Spec->catfile( $stdin_dir, 'stdin-child.pl' );
    _write_file(
        $stdin_script,
        <<'PERL',
#!/usr/bin/env perl
use strict;
use warnings;
$| = 1;
my $line = <STDIN>;
$line = '' if !defined $line;
print "stdin:$line";
exit 0;
PERL
        0755,
    );
    my $stdin_text = File::Spec->catfile( $stdin_dir, 'stdin.txt' );
    _write_file( $stdin_text, "hello-from-stdin\n" );
    open my $saved_stdin, '<&', \*STDIN or die "Unable to duplicate original STDIN: $!";
    open my $saved_stdout, '>&', \*STDOUT or die "Unable to duplicate original STDOUT: $!";
    open my $saved_stderr, '>&', \*STDERR or die "Unable to duplicate original STDERR: $!";
    my $stdout_path = File::Spec->catfile( $stdin_dir, 'stdout.txt' );
    my $stderr_path = File::Spec->catfile( $stdin_dir, 'stderr.txt' );
    open STDIN, '<', $stdin_text or die "Unable to open stdin fixture file: $!";
    open STDOUT, '>', $stdout_path or die "Unable to redirect stdout fixture file: $!";
    open STDERR, '>', $stderr_path or die "Unable to redirect stderr fixture file: $!";
    my $result = $dispatcher->_run_child_command_streaming(
        command      => [ $^X, $stdin_script ],
        args         => [],
        env          => {},
        skill_layers => [$dep_skill_root],
        result_state => {},
        last_result  => {},
        stdin_mode   => 'inherit',
    );
    open STDIN, '<&', $saved_stdin or die "Unable to restore original STDIN: $!";
    open STDOUT, '>&', $saved_stdout or die "Unable to restore original STDOUT: $!";
    open STDERR, '>&', $saved_stderr or die "Unable to restore original STDERR: $!";
    my $stdout = do {
        open my $fh, '<', $stdout_path or die "Unable to read captured stdout fixture file: $!";
        local $/;
        <$fh>;
    };
    my $stderr = do {
        open my $fh, '<', $stderr_path or die "Unable to read captured stderr fixture file: $!";
        local $/;
        <$fh>;
    };
    is( $stdout, "stdin:hello-from-stdin\n", '_run_child_command_streaming preserves interactive stdin when requested' );
    is( $stderr, '', '_run_child_command_streaming keeps stderr empty when the child emits no stderr' );
    is( $result->{stdout}, "stdin:hello-from-stdin\n", '_run_child_command_streaming captures inherited-stdin child stdout' );
    is( $result->{stderr}, '', '_run_child_command_streaming captures an empty stderr stream when nothing is emitted' );
    is( $result->{exit_code}, 0, '_run_child_command_streaming captures a successful inherited-stdin exit code' );
}
{
    my $hook_dir = File::Spec->catdir( $dep_skill_root, 'cli', 'streaming-hook.d' );
    make_path($hook_dir);
    my $hook_script = File::Spec->catfile( $hook_dir, '00-stream.pl' );
    _write_file(
        $hook_script,
        <<'PERL',
#!/usr/bin/env perl
use strict;
use warnings;
$| = 1;
print "hook-stream-out\n";
print STDERR "hook-stream-err\n";
exit 4;
PERL
        0755,
    );
    my ( $stdout, $stderr, $result ) = capture {
        $dispatcher->_execute_hooks_streaming( 'dep-skill', 'streaming-hook', [$dep_skill_root] );
    };
    is( $stdout, "hook-stream-out\n", '_execute_hooks_streaming mirrors hook stdout live' );
    is( $stderr, "hook-stream-err\n", '_execute_hooks_streaming mirrors hook stderr live' );
    is_deeply(
        $result->{hooks}{'00-stream.pl'},
        {
            stdout    => "hook-stream-out\n",
            stderr    => "hook-stream-err\n",
            exit_code => 4,
        },
        '_execute_hooks_streaming captures hook stdout, stderr, and exit code',
    );
    is_deeply(
        $result->{last_result},
        {
            file   => $hook_script,
            exit   => 4,
            STDOUT => "hook-stream-out\n",
            STDERR => "hook-stream-err\n",
        },
        '_execute_hooks_streaming records the last streaming hook result for downstream RESULT consumers',
    );
}
{
    no warnings 'redefine';
    local %ENV = %ENV;
    my %seen;
    local *Developer::Dashboard::SkillDispatcher::_execute_hooks_streaming = sub {
        return {
            hooks        => { pre => { stdout => "hook\n", stderr => '', exit_code => 0 } },
            result_state => { pre => { stdout => "hook\n", stderr => '', exit_code => 0 } },
            last_result  => { file => '/tmp/hook', exit => 0, STDOUT => "hook\n", STDERR => '' },
        };
    };
    local *Developer::Dashboard::SkillDispatcher::_exec_resolved_command = sub {
        my ( $self, $cmd_path, $command, $args ) = @_;
        $seen{cmd_path} = $cmd_path;
        $seen{command} = [ @{$command} ];
        $seen{args} = [ @{$args} ];
        $seen{env} = {
            map { $_ => $ENV{$_} }
              grep { exists $ENV{$_} }
              qw(
              DEVELOPER_DASHBOARD_SKILL_NAME
              DEVELOPER_DASHBOARD_SKILL_ROOT
              DEVELOPER_DASHBOARD_SKILL_COMMAND
              DEVELOPER_DASHBOARD_SKILL_CLI_ROOT
              DEVELOPER_DASHBOARD_SKILL_CONFIG_ROOT
              DEVELOPER_DASHBOARD_SKILL_DOCKER_ROOT
              DEVELOPER_DASHBOARD_SKILL_STATE_ROOT
              DEVELOPER_DASHBOARD_SKILL_LOGS_ROOT
              DEVELOPER_DASHBOARD_SKILL_LOCAL_ROOT
              PERL5LIB
              )
        };
        $seen{current} = Developer::Dashboard::Runtime::Result::current();
        $seen{last} = Developer::Dashboard::Runtime::Result::last_result();
        return {
            success => 1,
            %seen,
        };
    };
    local *Developer::Dashboard::EnvLoader::load_runtime_layers = sub {
        shift;
        $seen{runtime_layers_loaded}++;
        return;
    };
    local *Developer::Dashboard::EnvLoader::load_skill_layers = sub {
        shift;
        my (%args) = @_;
        $seen{skill_layers} = [ @{ $args{skill_layers} || [] } ];
        return;
    };
    my $exec_result = $dispatcher->exec_command( 'dep-skill', 'run-test', 'alpha', 'beta' );
    ok( $exec_result->{success}, 'exec_command delegates to the resolved command runner after preparing the environment' );
    is_same_path( $exec_result->{cmd_path}, File::Spec->catfile( $dep_skill_root, 'cli', 'run-test' ), 'exec_command resolves the final runnable command path' );
    is_deeply( $exec_result->{args}, [ 'alpha', 'beta' ], 'exec_command forwards the original user arguments to the final command runner' );
    is( $exec_result->{env}{DEVELOPER_DASHBOARD_SKILL_NAME}, 'dep-skill', 'exec_command exposes the skill name in the child environment' );
    is( $exec_result->{env}{DEVELOPER_DASHBOARD_SKILL_COMMAND}, 'run-test', 'exec_command exposes the resolved command name in the child environment' );
    is_same_path( $exec_result->{env}{DEVELOPER_DASHBOARD_SKILL_ROOT}, $dep_skill_root, 'exec_command exposes the resolved skill path in the child environment' );
    is_deeply( $exec_result->{skill_layers}, [$dep_skill_root], 'exec_command loads the participating skill layers before exec' );
    is( $exec_result->{runtime_layers_loaded}, 1, 'exec_command reloads runtime env layers before replacing the helper process' );
    is_deeply(
        $exec_result->{last},
        { file => '/tmp/hook', exit => 0, STDOUT => "hook\n", STDERR => '' },
        'exec_command forwards the last hook RESULT payload into Runtime::Result',
    );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::_execute_hooks_streaming = sub { return { error => 'stream hook failure' } };
    is_deeply(
        $dispatcher->exec_command( 'dep-skill', 'run-test' ),
        { error => 'stream hook failure' },
        'exec_command stops before exec when streaming hooks report an error',
    );
}
{
    my ( undef, undef, $exec_error ) = capture {
        local *Developer::Dashboard::SkillDispatcher::_exec_replacement = sub { return 'mock exec failure'; };
        $dispatcher->_exec_resolved_command( '/no/such/path', [ '/definitely/missing-skill-command' ], [] );
    };
    like( $exec_error->{error}, qr/\AUnable to exec \/no\/such\/path: mock exec failure/, '_exec_resolved_command reports direct exec failures clearly' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::_execute_hooks_streaming = sub {
        return {
            hooks        => {},
            result_state => {},
        };
    };
    local *Developer::Dashboard::SkillDispatcher::_exec_resolved_command = sub {
        my $last_result = Developer::Dashboard::Runtime::Result::last_result();
        return {
            success     => 1,
            last_result => $last_result,
        };
    };
    my $exec_result = $dispatcher->exec_command( 'dep-skill', 'run-test' );
    ok( $exec_result->{success}, 'exec_command still reaches the final command runner when hooks return no last_result payload' );
    ok( !defined $exec_result->{last_result}, 'exec_command clears the previous RESULT payload when hooks return no last_result data' );
}
{
    my ( undef, $stderr, $exec_error ) = capture {
        return $dispatcher->_exec_replacement( ['/definitely/missing-skill-command'], [] );
    };
    like(
        $stderr,
        qr/Can't exec "\/definitely\/missing-skill-command": No such file or directory/,
        '_exec_replacement leaves the underlying exec failure visible on stderr',
    );
    like(
        $exec_error,
        qr/No such file or directory/,
        '_exec_replacement returns the system exec failure string when the replacement command cannot be executed',
    );
}
{
    my $arrayref = [qw(alpha beta)];
    is_deeply(
        $dispatcher->_arrayref_or_empty($arrayref),
        $arrayref,
        '_arrayref_or_empty preserves array references',
    );
    is_deeply(
        $dispatcher->_arrayref_or_empty(undef),
        [],
        '_arrayref_or_empty falls back to an empty array reference',
    );

    my $hashref = { alpha => 1 };
    is_deeply(
        $dispatcher->_hashref_or_empty($hashref),
        $hashref,
        '_hashref_or_empty preserves hash references',
    );
    is_deeply(
        $dispatcher->_hashref_or_empty(undef),
        {},
        '_hashref_or_empty falls back to an empty hash reference',
    );

    is(
        $dispatcher->_defined_or_default( 'stdin', 'inherit' ),
        'stdin',
        '_defined_or_default preserves defined values',
    );
    is(
        $dispatcher->_defined_or_default( undef, 'inherit' ),
        'inherit',
        '_defined_or_default falls back when the value is undef',
    );
}
my $no_bookmark_repo = _create_skill_repo( $test_repos, 'no-bookmarks-skill', with_cpanfile => 0, with_bookmark => 0, with_nav => 0 );
ok( !$manager->install( 'file://' . $no_bookmark_repo )->{error}, 'skill without bookmarks installs cleanly' );
my $no_nav_repo = _create_skill_repo( $test_repos, 'no-nav-skill', with_cpanfile => 0, with_nav => 0 );
ok( !$manager->install( 'file://' . $no_nav_repo )->{error}, 'skill without nav installs cleanly' );
is( $dispatcher->route_response( skill_name => 'missing-skill', route => 'bookmarks' )->[0], 404, 'route_response returns 404 for missing skills' );
is( $dispatcher->route_response( skill_name => 'dep-skill', route => '' )->[0], 200, 'route_response returns the skill index when the app route omits an explicit page id' );
is( $dispatcher->route_response( skill_name => 'no-bookmarks-skill', route => 'bookmarks' )->[0], 404, 'route_response returns 404 when a skill has no bookmarks' );
{
    my $bookmark_index = $dispatcher->route_response( skill_name => 'dep-skill', route => 'bookmarks' );
    is( $bookmark_index->[0], 200, 'route_response returns bookmark listings for the compatibility /bookmarks route' );
    is_deeply(
        json_decode( $bookmark_index->[2] ),
        { skill => 'dep-skill', bookmarks => [ 'index', 'welcome' ] },
        'route_response lists the skill bookmark files and excludes nav entries',
    );
}
is( $dispatcher->route_response( skill_name => 'dep-skill', route => 'unknown' )->[0], 404, 'route_response rejects unsupported skill routes' );
is_deeply( $dispatcher->skill_nav_pages(''), [], 'skill_nav_pages returns an empty list for empty skill names' );
is_deeply( $dispatcher->skill_nav_pages('missing-skill'), [], 'skill_nav_pages returns an empty list for unknown skills' );
is_deeply( $dispatcher->skill_nav_pages('no-nav-skill'), [], 'skill_nav_pages returns an empty list when a skill has no nav root' );
{
    my %route_ids = $dispatcher->_skill_nav_route_ids('dep-skill');
    is_deeply(
        \%route_ids,
        { 'skill.tt' => 'nav/skill.tt' },
        '_skill_nav_route_ids enumerates layered nav templates as route ids',
    );
}
{
    my $pages = $dispatcher->all_skill_nav_pages;
    ok( ref($pages) eq 'ARRAY', 'all_skill_nav_pages returns an array reference of prepared skill nav pages' );
    my $has_dep_skill_nav = scalar grep { $_->{meta}{skill_name} && $_->{meta}{skill_name} eq 'dep-skill' } @{$pages};
    ok(
        $has_dep_skill_nav,
        'all_skill_nav_pages includes nav pages from installed skills that provide them',
    );
}
{
    my $local_lib = File::Spec->catdir( $manager->get_skill_path('dep-skill'), 'perl5', 'lib', 'perl5' );
    make_path($local_lib);
    local $ENV{PERL5LIB} = 'base-lib';
    my %env = $dispatcher->_skill_env(
        skill_name   => 'dep-skill',
        skill_path   => $manager->get_skill_path('dep-skill'),
        skill_layers => [ $manager->get_skill_path('dep-skill') ],
        command      => 'run-test',
        result_state => { alpha => { stdout => "ok\n" } },
    );
    like( $env{PERL5LIB}, qr/\Q$local_lib\E/, '_skill_env prepends the skill-local perl library when present' );
    ok( !exists $env{RESULT}, '_skill_env leaves RESULT handoff to Runtime::Result instead of inlining it into the child env' );
}
is_deeply(
    $dispatcher->_merge_array_items_by_identity(
        [ { name => 'alpha', interval => 10 }, 'keep-left' ],
        [ { name => 'alpha', interval => 20 }, { name => 'beta', interval => 30 }, 'keep-right' ],
        'name',
    ),
    [
        { name => 'alpha', interval => 20 },
        'keep-left',
        { name => 'beta', interval => 30 },
        'keep-right',
    ],
    '_merge_array_items_by_identity replaces collector-like entries by logical identity while preserving unmatched items',
);
is_deeply(
    $dispatcher->_merge_array_items_by_identity(
        [ { id => 'provider', title => 'Base' }, 'keep-left' ],
        [ { id => 'provider', title => 'Leaf' }, { id => 'two', title => 'Two' }, 'keep-right' ],
        'id',
    ),
    [
        { id => 'provider', title => 'Leaf' },
        'keep-left',
        { id => 'two', title => 'Two' },
        'keep-right',
    ],
    '_merge_array_items_by_identity also handles provider-like identities directly',
);
is_deeply(
    $dispatcher->_merge_array_items_by_identity( undef, undef, 'name' ),
    [],
    '_merge_array_items_by_identity returns an empty array ref when both sides are missing',
);
is_deeply(
    $dispatcher->_merge_skill_hashes(
        {
            collectors => [ { name => 'alpha', interval => 10 } ],
            providers  => [ { id => 'main', title => 'Home' } ],
        },
        {
            collectors => [ { name => 'alpha', interval => 20 }, { name => 'beta', interval => 30 } ],
            providers  => [ { id => 'main', title => 'Leaf' }, { id => 'extra', title => 'Extra' } ],
        },
    ),
    {
        collectors => [
            { name => 'alpha', interval => 20 },
            { name => 'beta',  interval => 30 },
        ],
        providers => [
            { id => 'main',  title => 'Leaf' },
            { id => 'extra', title => 'Extra' },
        ],
    },
    '_merge_skill_hashes merges collector and provider arrays by logical identity for layered skill config',
);
is_deeply(
    $dispatcher->_merge_skill_hashes(
        { collectors => [ { name => 'alpha', interval => 10 } ] },
        { collectors => [ { name => 'alpha', interval => 20 } ] },
    ),
    { collectors => [ { name => 'alpha', interval => 20 } ] },
    '_merge_skill_hashes routes collector arrays through logical name-based replacement',
);
is_deeply(
    $dispatcher->_merge_skill_hashes(
        { providers => [ { id => 'alpha', title => 'Old' } ] },
        { providers => [ { id => 'alpha', title => 'New' } ] },
    ),
    { providers => [ { id => 'alpha', title => 'New' } ] },
    '_merge_skill_hashes routes provider arrays through logical id-based replacement',
);
is_deeply(
    $dispatcher->_merge_skill_hashes(
        { indicator => { icon => 'base', status => 'ok' }, passthrough => 1 },
        { indicator => { status => 'warn', label => 'Leaf' } },
    ),
    {
        indicator   => { icon => 'base', status => 'warn', label => 'Leaf' },
        passthrough => 1,
    },
    '_merge_skill_hashes recursively merges nested hashes while preserving inherited keys',
);
is_deeply(
    $dispatcher->_merge_skill_hashes(
        {
            collectors => [ { name => 'alpha', interval => 10 }, 'keep-left' ],
        },
        {
            collectors => [ { name => 'alpha', interval => 20 }, { name => 'beta', interval => 30 }, 'keep-right' ],
        },
    ),
    {
        collectors => [
            { name => 'alpha', interval => 20 },
            'keep-left',
            { name => 'beta', interval => 30 },
            'keep-right',
        ],
    },
    '_merge_skill_hashes preserves unmatched collector entries while replacing logical collector duplicates',
);
is_deeply(
    $dispatcher->_merge_skill_hashes(
        {
            providers => [ { id => 'provider', title => 'Base' }, 'keep-left' ],
        },
        {
            providers => [ { id => 'provider', title => 'Leaf' }, { id => 'two', title => 'Two' }, 'keep-right' ],
        },
    ),
    {
        providers => [
            { id => 'provider', title => 'Leaf' },
            'keep-left',
            { id => 'two', title => 'Two' },
            'keep-right',
        ],
    },
    '_merge_skill_hashes preserves unmatched provider entries while replacing logical provider duplicates',
);
{
    my $files = Developer::Dashboard::FileRegistry->new( paths => $skill_paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $skill_paths );
    is_deeply(
        $config->merged->{'_dep-skill'},
        { skill_name => 'dep-skill' },
        'Config merges installed skill config into the effective runtime config under the underscored skill key',
    );
}
{
    for my $module_path (
        map { File::Spec->catfile( $repo_root, $_ ) } qw(
          lib/Developer/Dashboard/CLI/OpenFile.pm
          lib/Developer/Dashboard/CLI/Query.pm
          lib/Developer/Dashboard/UpdateManager.pm
          )
      )
    {
        open my $fh, '<', $module_path or die "Unable to read $module_path: $!";
        local $/;
        my $source = <$fh>;
        close $fh;
        unlike(
            $source,
            qr/\buse\s+FindBin\b/,
            "$module_path avoids FindBin at module load time so built-dist loads do not depend on the caller script path",
        );
    }
}

sub _create_skill_repo {
    my ( $root, $name, %args ) = @_;
    my $repo = File::Spec->catdir( $root, $name );
    make_path($repo);
    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    _run_or_die(qw(git init --quiet));
    _run_or_die(qw(git config user.email test@example.com));
    _run_or_die(qw(git config user.name Test));

    make_path('cli');
    make_path('config');
    make_path( File::Spec->catdir( 'config', 'docker', 'postgres' ) );
    make_path('state');
    make_path('logs');
    make_path('dashboards') if !exists $args{with_bookmark} || $args{with_bookmark};
    make_path( File::Spec->catdir( 'dashboards', 'nav' ) ) if !exists $args{with_nav} || $args{with_nav};
    if ( !exists $args{with_hook} || $args{with_hook} ) {
        make_path( File::Spec->catdir( 'cli', 'run-test.d' ) );
    }

    _write_file(
        File::Spec->catfile( 'cli', 'run-test' ),
        "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint join('|', \@ARGV), qq{\\n};\n",
        0755,
    );
    if ( !exists $args{with_hook} || $args{with_hook} ) {
        _write_file(
            File::Spec->catfile( 'cli', 'run-test.d', '00-pre.pl' ),
            "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{hooked\\n};\n",
            0755,
        );
    }
    _write_file( File::Spec->catfile( 'config', 'config.json' ), qq|{"skill_name":"$name"}\n| );
    _write_file( File::Spec->catfile( 'config', 'docker', 'postgres', 'compose.yml' ), "services: {}\n" );
    if ( !exists $args{with_cpanfile} || $args{with_cpanfile} ) {
        _write_file( 'cpanfile', "requires 'JSON::XS';\n" );
    }
    if ( $args{with_aptfile} ) {
        _write_file( 'aptfile', "git\ncurl\n" );
    }
    if ( $args{with_apkfile} ) {
        _write_file( 'apkfile', "procps-dev\n" );
    }
    if ( $args{with_ddfile} ) {
        _write_file( 'ddfile', "shared-skill\n" );
    }
    if ( $args{with_ddfile_local} ) {
        _write_file( 'ddfile.local', "shared-local-skill\n" );
    }
    if ( $args{with_brewfile} ) {
        _write_file( 'brewfile', "jq\n" );
    }
    if ( $args{with_package_json} ) {
        _write_file(
            'package.json',
            qq|{"name":"$name-node","version":"0.01.0","dependencies":{"$name-runtime":"^1.2.3"},"devDependencies":{"$name-dev":"^4.5.6"}}\n|
        );
    }
    if ( $args{with_cpanfile_local} ) {
        _write_file( 'cpanfile.local', "requires 'YAML::XS';\n" );
    }
    if ( !exists $args{with_bookmark} || $args{with_bookmark} ) {
        _write_file(
            File::Spec->catfile( 'dashboards', 'index' ),
            "TITLE: Index\n:--------------------------------------------------------------------------------:\nBOOKMARK: index\n:--------------------------------------------------------------------------------:\nHTML:\nIndex\n",
        );
        _write_file(
            File::Spec->catfile( 'dashboards', 'welcome' ),
            "TITLE: Welcome\n:--------------------------------------------------------------------------------:\nBOOKMARK: welcome\n:--------------------------------------------------------------------------------:\nHTML:\nHello\n",
        );
    }
    if ( !exists $args{with_nav} || $args{with_nav} ) {
        _write_file(
            File::Spec->catfile( 'dashboards', 'nav', 'skill.tt' ),
            "<div>Skill Nav</div>\n",
        );
    }

    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', "Initial $name" );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return $repo;
}

sub _run_or_die {
    my (@command) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system(@command);
    };
    die "Command failed: @command\n$stderr" if $exit != 0;
    return $stdout;
}

sub _write_file {
    my ( $path, $content, $mode ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    chmod( $mode || 0644, $path ) or die "Unable to chmod $path: $!";
    return 1;
}

sub _dies {
    my ($code) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    return $error;
}

{
    require Developer::Dashboard::CLI::Progress;
    my $output = '';
    open my $fh, '>', \$output or die "Unable to open scalar handle for progress output: $!";
    my $progress = Developer::Dashboard::CLI::Progress->new(
        title   => 'dashboard restart progress',
        tasks   => [
            { id => 'stop_web',  label => 'Stop dashboard web service' },
            { id => 'start_web', label => 'Start dashboard web service' },
        ],
        stream  => $fh,
        dynamic => 1,
    );
    like( $output, qr/dashboard restart progress/, 'CLI::Progress renders the board title immediately' );
    like( $output, qr/\[ \] Stop dashboard web service/, 'CLI::Progress renders pending tasks with an empty checkbox marker' );
    like( $output, qr/\[ \] Start dashboard web service/, 'CLI::Progress renders later pending tasks before work begins' );
    $progress->callback->( { task_id => 'stop_web', status => 'running' } );
    like( $output, qr/\e\[1A\e\[2K/, 'CLI::Progress redraws previous lines in dynamic mode' );
    like( $output, qr/-> Stop dashboard web service/, 'CLI::Progress marks the running task with the right-arrow marker' );
    $progress->update( { task_id => 'stop_web', status => 'done' } );
    like( $output, qr/\[OK\] Stop dashboard web service/, 'CLI::Progress marks completed tasks with the OK marker' );
    $progress->update( { task_id => 'start_web', status => 'failed' } );
    like( $output, qr/\[X\] Start dashboard web service/, 'CLI::Progress marks failed tasks with the failure marker' );
    ok( $progress->update( { task_id => 'missing-task', status => 'done' } ), 'CLI::Progress ignores unknown task ids without failing' );
    ok( $progress->update(), 'CLI::Progress ignores missing events without failing' );
    ok( $progress->finish, 'CLI::Progress finish succeeds after dynamic redraws' );
}

{
    require Developer::Dashboard::CLI::Progress;
    my $output = '';
    open my $fh, '>', \$output or die "Unable to open scalar handle for progress output: $!";
    my $progress = Developer::Dashboard::CLI::Progress->new(
        title   => 'dashboard restart progress',
        tasks   => [ { id => 'stop_web', label => 'Stop dashboard web service' } ],
        stream  => $fh,
        dynamic => 0,
        color   => 1,
    );
    $progress->update( { task_id => 'stop_web', status => 'running' } );
    like( $output, qr/\x1b\[33m->\x1b\[0m Stop dashboard web service/, 'CLI::Progress colors the running marker yellow when color output is enabled' );
    $progress->update( { task_id => 'stop_web', status => 'done' } );
    like( $output, qr/\x1b\[32m\[OK\]\x1b\[0m Stop dashboard web service/, 'CLI::Progress colors the done marker green when color output is enabled' );
    $progress->update( { task_id => 'stop_web', status => 'failed' } );
    like( $output, qr/\x1b\[31m\[X\]\x1b\[0m Stop dashboard web service/, 'CLI::Progress colors the failed marker red when color output is enabled' );
}

done_testing();

__END__

=head1 NAME

21-refactor-coverage.t - direct coverage closure for helper packaging and skills

=head1 DESCRIPTION

This test closes direct branch coverage for the private helper packaging,
query parsing, runtime result, path registry, and isolated skill modules.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the hard-to-hit branches that keep library coverage honest. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the hard-to-hit branches that keep library coverage honest has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the hard-to-hit branches that keep library coverage honest, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/21-refactor-coverage.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/21-refactor-coverage.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/21-refactor-coverage.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
