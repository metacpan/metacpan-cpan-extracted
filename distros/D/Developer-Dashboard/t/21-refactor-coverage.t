use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use Encode qw(decode_utf8);
use Errno qw(EACCES);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::SeededPages ();
use Developer::Dashboard::CLI::Files ();
use Developer::Dashboard::CLI::Query ();
use Developer::Dashboard::CLI::Ticket ();
use Developer::Dashboard::CollectorRunner;
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
use Developer::Dashboard::RuntimeManager ();
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
        pjq    => 'jq',
        pyq    => 'yq',
        ptomq  => 'tomq',
        pjp    => 'propq',
        ticket => 'workspace',
        skill  => 'skills',
        logs   => 'log',
    },
    'internal CLI exposes the expected helper aliases',
);
is( Developer::Dashboard::InternalCLI::canonical_helper_name('pjq'), 'jq', 'legacy helper alias normalizes to jq' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('skill'), 'skills', 'singular skill helper alias normalizes to skills' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('xmlq'), 'xmlq', 'current helper name stays unchanged' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('ticket'), 'workspace', 'ticket helper name now aliases to workspace' );
is( Developer::Dashboard::InternalCLI::canonical_helper_name('workspace'), 'workspace', 'workspace helper name stays unchanged' );
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
    like(
        _dies( sub { Developer::Dashboard::CLI::SeededPages::page_for_id('missing-dashboard') } ),
        qr/Unknown seeded page id 'missing-dashboard'/,
        'page_for_id rejects unknown seeded page ids after dashboard extraction from core',
    );
}
{
    ok(
        !Developer::Dashboard::CLI::SeededPages::is_known_managed_page_md5(
            id  => 'missing-dashboard',
            md5 => 'ffffffffffffffffffffffffffffffff',
        ),
        'SeededPages rejects unknown digests from automatic refresh after dashboard extraction',
    );
}
{
    is_deeply(
        [ Developer::Dashboard::CLI::SeededPages::known_managed_page_md5s('seeded-demo') ],
        [],
        'SeededPages reports no shipped managed digests once optional browser workspaces are extracted from core',
    );
}
{
    my $manifest_home = tempdir( CLEANUP => 1 );
    my $manifest_paths = Developer::Dashboard::PathRegistry->new( home => $manifest_home );
    my $manifest_path = Developer::Dashboard::CLI::SeededPages::seed_manifest_path( paths => $manifest_paths );

    open my $manifest_fh, '>:raw', $manifest_path or die "Unable to write $manifest_path: $!";
    print {$manifest_fh} qq|{"removed-dashboard":{"asset":"removed-dashboard.page","md5":"abc123"}}\n|;
    close $manifest_fh or die "Unable to close $manifest_path: $!";

    is_deeply(
        Developer::Dashboard::CLI::SeededPages::_read_manifest( paths => $manifest_paths ),
        {
            'removed-dashboard' => {
                asset => 'removed-dashboard.page',
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

    like(
        _dies( sub { Developer::Dashboard::CLI::SeededPages::_write_manifest( paths => $manifest_paths, manifest => undef ) } ),
        qr/Missing seeded page manifest hash/,
        '_write_manifest requires a manifest hash reference',
    );

    my $written = Developer::Dashboard::CLI::SeededPages::_write_manifest(
        paths    => $manifest_paths,
        manifest => { seeded_demo => { md5 => 'abc' } },
    );
    ok( -f $written, '_write_manifest persists a seeded-page manifest file' );

    is(
        Developer::Dashboard::CLI::SeededPages::_record_manifest_md5(
            paths => $manifest_paths,
            id    => 'seeded-demo',
            md5   => '0123456789abcdef0123456789abcdef',
        ),
        '0123456789abcdef0123456789abcdef',
        '_record_manifest_md5 returns the newly recorded digest',
    );
    ok(
        Developer::Dashboard::CLI::SeededPages::_manifest_md5_matches(
            paths => $manifest_paths,
            id    => 'seeded-demo',
            md5   => '0123456789abcdef0123456789abcdef',
        ),
        '_manifest_md5_matches accepts a matching manifest digest',
    );
    ok(
        !Developer::Dashboard::CLI::SeededPages::_manifest_md5_matches(
            paths => $manifest_paths,
            id    => 'seeded-demo',
            md5   => 'ffffffffffffffffffffffffffffffff',
        ),
        '_manifest_md5_matches rejects a different manifest digest',
    );
}
{
    package Local::SeededPageStore;

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            saved        => $args{saved},
            missing      => $args{missing} || 0,
            saved_pages  => [],
        }, $class;
    }

    sub read_saved_entry {
        my ( $self, $id ) = @_;
        die "Page '$id' not found" if $self->{missing};
        return $self->{saved};
    }

    sub save_page {
        my ( $self, $page ) = @_;
        push @{ $self->{saved_pages} }, $page;
        $self->{saved}   = $page->canonical_instruction;
        $self->{missing} = 0;
        return 1;
    }
}
{
    my $manifest_home = tempdir( CLEANUP => 1 );
    my $manifest_paths = Developer::Dashboard::PathRegistry->new( home => $manifest_home );
    my $page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Seeded Demo
:--------------------------------------------------------------------------------:
BOOKMARK: seeded-demo
:--------------------------------------------------------------------------------:
HTML: <div>seeded</div>
PAGE
    my $missing_store = Local::SeededPageStore->new( missing => 1 );
    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            page  => $page,
            pages => $missing_store,
            paths => $manifest_paths,
        ),
        'created',
        'ensure_seeded_page creates a missing seeded page',
    );

    my $current_store = Local::SeededPageStore->new( saved => $page->canonical_instruction );
    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            page  => $page,
            pages => $current_store,
            paths => $manifest_paths,
        ),
        'current',
        'ensure_seeded_page reports current for an unchanged managed page',
    );

    my $stale_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Seeded Demo
:--------------------------------------------------------------------------------:
BOOKMARK: seeded-demo
:--------------------------------------------------------------------------------:
HTML: <div>stale</div>
PAGE
    my $stale_md5 = Developer::Dashboard::SeedSync::content_md5( $stale_page->canonical_instruction );
    Developer::Dashboard::CLI::SeededPages::_write_manifest(
        paths    => $manifest_paths,
        manifest => {
            'seeded-demo' => {
                asset => 'seeded-demo',
                md5   => $stale_md5,
            },
        },
    );
    my $stale_store = Local::SeededPageStore->new( saved => $stale_page->canonical_instruction );
    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            page  => $page->as_hash,
            pages => $stale_store,
            paths => $manifest_paths,
        ),
        'updated',
        'ensure_seeded_page refreshes a manifest-matched managed page',
    );

    my $edited_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Seeded Demo
:--------------------------------------------------------------------------------:
BOOKMARK: seeded-demo
:--------------------------------------------------------------------------------:
HTML: <div>edited</div>
PAGE
    my $edited_store = Local::SeededPageStore->new( saved => $edited_page->canonical_instruction );
    is(
        Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
            page  => $page,
            pages => $edited_store,
            paths => $manifest_paths,
        ),
        'preserved',
        'ensure_seeded_page preserves a diverged user-edited page',
    );
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
    if ( $helper =~ /\A(?:encode|decode|indicator|collector|config|auth|init|cpan|page|action|docker|serve|stop|restart|log|shell|doctor|skills|skill)\z/ ) {
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
    elsif ( $helper eq 'workspace' ) {
        like(
            $content,
            qr/\Qrun_workspace_command( args => \@ARGV );\E/,
            'helper_content renders the shipped workspace helper body',
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
    elsif ( $helper eq 'file' || $helper eq 'files' ) {
        like(
            $content,
            qr/\Qrun_files_command( command => '$helper', args => \@ARGV );\E/,
            "helper_content renders the shipped $helper file helper body",
        );
    }
    elsif ( $helper eq 'api' ) {
        like(
            $content,
            qr/\Qdashboard api ...\E/,
            'helper_content renders the shipped api wrapper body',
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
for my $wrapper_helper (qw(encode decode indicator collector config auth api init cpan page action docker serve stop restart log shell doctor housekeeper skills)) {
    my $managed_content = Developer::Dashboard::InternalCLI::_managed_helper_content($wrapper_helper);
    like(
        $managed_content,
        qr/^# developer-dashboard-managed-helper-version: \Q$Developer::Dashboard::InternalCLI::VERSION\E$/m,
        "_managed_helper_content stamps the $wrapper_helper wrapper with the current helper-version marker",
    );
    like(
        $managed_content,
        qr/my \$command = '\Q$wrapper_helper\E';/,
        "_managed_helper_content stages the $wrapper_helper wrapper with an explicit built-in command name",
    );
    unlike(
        $managed_content,
        qr/basename\(\$0\)/,
        "_managed_helper_content no longer relies on \$0 basename discovery for the staged $wrapper_helper wrapper",
    );
    like(
        $managed_content,
        qr/use Developer::Dashboard::Platform qw\(is_windows\);/,
        "_managed_helper_content stages the $wrapper_helper wrapper with the Windows-aware helper runtime import",
    );
    like(
        $managed_content,
        qr/if \(is_windows\(\)\) \{\n    system \@command;\n    my \$status = \$\?;\n    my \$exit_code = \$status > 255 \? \$status >> 8 : \$status;\n    exit \$exit_code;\n\}/,
        "_managed_helper_content stages the $wrapper_helper wrapper with Windows-native child-exit propagation instead of raw exec",
    );
}
my $seeded_helpers = Developer::Dashboard::InternalCLI::ensure_helpers( paths => $paths );
my @helper_names = Developer::Dashboard::InternalCLI::helper_names();
is( scalar(@$seeded_helpers), scalar(@helper_names), 'ensure_helpers writes every shipped helper once' );
my $seeded_helpers_second = Developer::Dashboard::InternalCLI::ensure_helpers( paths => $paths );
is_deeply( $seeded_helpers_second, [], 'ensure_helpers skips rewriting staged helpers whose md5 already matches the shipped content' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ), 'ensure_helpers also stages the shared _dashboard-core runtime under the dd namespace' );
ok( grep( $_ =~ m{/\Qof\E$}, @$seeded_helpers ), 'ensure_helpers writes the private of helper' );
ok( grep( $_ =~ m{/\Qopen-file\E$}, @$seeded_helpers ), 'ensure_helpers writes the private open-file helper' );
ok( grep( $_ =~ m{/\Qworkspace\E$}, @$seeded_helpers ), 'ensure_helpers writes the private workspace helper' );
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
    my $core_only_home  = tempdir( CLEANUP => 1 );
    my $core_only_paths = Developer::Dashboard::PathRegistry->new( home => $core_only_home );
    is(
        Developer::Dashboard::InternalCLI::dashboard_core_path( paths => $core_only_paths ),
        File::Spec->catfile( $core_only_home, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ),
        'dashboard_core_path resolves the staged shared core helper location',
    );
    is_deeply(
        Developer::Dashboard::InternalCLI::ensure_dashboard_core( paths => $core_only_paths ),
        [ File::Spec->catfile( $core_only_home, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ) ],
        'ensure_dashboard_core stages only the shared _dashboard-core helper',
    );
}
{
    my $single_home = tempdir( CLEANUP => 1 );
    my $single_paths = Developer::Dashboard::PathRegistry->new( home => $single_home );
    my $single_written = Developer::Dashboard::InternalCLI::ensure_helper(
        paths => $single_paths,
        name  => 'ps1',
    );
    is_deeply(
        $single_written,
        [ File::Spec->catfile( $single_home, '.developer-dashboard', 'cli', 'dd', 'ps1' ) ],
        'ensure_helper stages only the requested standalone helper when the helper has no shared core runtime dependency',
    );
    ok(
        !-e File::Spec->catfile( $single_home, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ),
        'ensure_helper does not eagerly stage _dashboard-core for standalone helpers',
    );
    is_deeply(
        Developer::Dashboard::InternalCLI::ensure_helper(
            paths => $single_paths,
            name  => 'ps1',
        ),
        [],
        'ensure_helper skips rewriting a staged helper when the version marker already matches the current dashboard build',
    );
}
{
    my $wrapper_home = tempdir( CLEANUP => 1 );
    my $wrapper_paths = Developer::Dashboard::PathRegistry->new( home => $wrapper_home );
    my $wrapper_written = Developer::Dashboard::InternalCLI::ensure_helper(
        paths => $wrapper_paths,
        name  => 'shell',
    );
    is_deeply(
        $wrapper_written,
        [
            File::Spec->catfile( $wrapper_home, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ),
            File::Spec->catfile( $wrapper_home, '.developer-dashboard', 'cli', 'dd', 'shell' ),
        ],
        'ensure_helper stages the shared core runtime and the requested wrapper helper when the helper delegates through _dashboard-core',
    );
}
{
    my $wrapper_home = tempdir( CLEANUP => 1 );
    my $wrapper_paths = Developer::Dashboard::PathRegistry->new( home => $wrapper_home );
    my $wrapper_target = File::Spec->catfile( $wrapper_home, '.developer-dashboard', 'cli', 'dd', 'init' );
    my $wrapper_root = File::Spec->catdir( $wrapper_home, '.developer-dashboard', 'cli', 'dd' );
    make_path($wrapper_root);
    my $stale_wrapper = Developer::Dashboard::InternalCLI::_managed_helper_content('init') . "# stale\n";
    open my $wrapper_fh, '>:raw', $wrapper_target or die "Unable to write $wrapper_target: $!";
    print {$wrapper_fh} $stale_wrapper;
    close $wrapper_fh or die "Unable to close $wrapper_target: $!";

    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { return 1 };

    my $written = Developer::Dashboard::InternalCLI::ensure_helper(
        paths => $wrapper_paths,
        name  => 'init',
    );
    is_deeply(
        $written,
        [ File::Spec->catfile( $wrapper_home, '.developer-dashboard', 'cli', 'dd', '_dashboard-core' ) ],
        'ensure_helper refreshes only the shared core runtime on Windows when an existing managed wrapper helper is already present on the hot path',
    );
    open my $wrapper_read_fh, '<:raw', $wrapper_target or die "Unable to read $wrapper_target: $!";
    local $/;
    is( <$wrapper_read_fh>, $stale_wrapper, 'ensure_helper leaves the existing managed Windows wrapper helper untouched on the hot path' );
    close $wrapper_read_fh or die "Unable to close $wrapper_target after verification: $!";
}
{
    my $legacy_flat_core = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', '_dashboard-core' );
    my $legacy_flat_shell = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'shell' );
    open my $legacy_core_fh, '>:raw', $legacy_flat_core or die "Unable to write $legacy_flat_core: $!";
    print {$legacy_core_fh} Developer::Dashboard::InternalCLI::_managed_helper_content('_dashboard-core');
    close $legacy_core_fh or die "Unable to close $legacy_flat_core: $!";
    open my $legacy_shell_fh, '>:raw', $legacy_flat_shell or die "Unable to write $legacy_flat_shell: $!";
    print {$legacy_shell_fh} Developer::Dashboard::InternalCLI::_managed_helper_content('shell');
    close $legacy_shell_fh or die "Unable to close $legacy_flat_shell: $!";

    my $cleanup_result = Developer::Dashboard::InternalCLI::ensure_helpers( paths => $paths );
    is_deeply( $cleanup_result, [], 'ensure_helpers can rerun purely as a legacy flat-helper cleanup pass' );
    ok( !-e $legacy_flat_core, 'ensure_helpers removes dashboard-managed legacy flat _dashboard-core files from the cli root' );
    ok( !-e $legacy_flat_shell, 'ensure_helpers removes dashboard-managed legacy flat helper wrappers from the cli root' );
}
{
    my $shell_helper = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'dd', 'shell' );
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $shell_helper, 'bash';
        return $? >> 8;
    };
    is( $exit, 0, 'the staged shell helper executes successfully from the managed dd helper root' );
    is( $stderr, '', 'the staged shell helper writes no stderr for shell bash output' );
    like( $stdout, qr/_dd_tmux_status_active/, 'the staged shell helper bootstrap includes the ticket tmux-status detection helper' );
    like( $stdout, qr/status-format\[0\].*tmux-status-top --width #\{client_width\}/s, 'the staged shell helper bootstrap includes the tmux ticket status format wiring' );
    like( $stdout, qr/status-interval 15/, 'the staged shell helper bootstrap slows the tmux status refresh cadence to avoid hot-looping' );
    like( $stdout, qr/ps1 --jobs \\j --mode compact --no-indicators/, 'the staged shell helper bootstrap suppresses prompt indicators when tmux owns the status line' );
}
{
    my $legacy_flat_core = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', '_dashboard-core' );
    my $legacy_flat_shell = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'shell' );
    open my $legacy_core_fh, '>:raw', $legacy_flat_core or die "Unable to write $legacy_flat_core: $!";
    print {$legacy_core_fh} Developer::Dashboard::InternalCLI::_managed_helper_content('_dashboard-core');
    close $legacy_core_fh or die "Unable to close $legacy_flat_core: $!";
    open my $legacy_shell_fh, '>:raw', $legacy_flat_shell or die "Unable to write $legacy_flat_shell: $!";
    print {$legacy_shell_fh} Developer::Dashboard::InternalCLI::_managed_helper_content('shell');
    close $legacy_shell_fh or die "Unable to close $legacy_flat_shell: $!";

    my $focused_cleanup = Developer::Dashboard::InternalCLI::ensure_helper(
        paths => $paths,
        name  => 'shell',
    );
    ok( ref($focused_cleanup) eq 'ARRAY', 'ensure_helper returns an array reference while cleaning legacy flat helpers on the focused path' );
    ok( !-e $legacy_flat_core, 'ensure_helper also removes dashboard-managed legacy flat _dashboard-core files from the cli root' );
    ok( !-e $legacy_flat_shell, 'ensure_helper also removes dashboard-managed legacy flat helper wrappers from the cli root' );
}
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
        "#!/usr/bin/env perl\n# developer-dashboard-managed-helper: jq\n# developer-dashboard-managed-helper-version: $Developer::Dashboard::InternalCLI::VERSION\nprint qq(managed\\n);\n",
        '_managed_helper_content injects the current helper-version marker into already-managed helper bodies when it is missing',
    );
}
{
    local *Developer::Dashboard::InternalCLI::helper_content = sub {
        return "print qq(no-shebang\\n);\n";
    };
    is(
        Developer::Dashboard::InternalCLI::_managed_helper_content('jq'),
        "# developer-dashboard-managed-helper: jq\n# developer-dashboard-managed-helper-version: $Developer::Dashboard::InternalCLI::VERSION\nprint qq(no-shebang\\n);\n",
        '_managed_helper_content prepends the ownership and helper-version markers when helper content has no shebang',
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
    my $repair_home = tempdir( CLEANUP => 1 );
    my $repair_paths = Developer::Dashboard::PathRegistry->new( home => $repair_home );
    my $repair_cli_root = File::Spec->catdir( $repair_home, '.developer-dashboard', 'cli', 'dd' );
    make_path($repair_cli_root);
    my $repair_target = File::Spec->catfile( $repair_cli_root, '_dashboard-core' );
    open my $repair_target_fh, '>', $repair_target or die "Unable to write $repair_target: $!";
    close $repair_target_fh;

    ok(
        Developer::Dashboard::InternalCLI::_stage_managed_helper(
            paths  => $repair_paths,
            name   => '_dashboard-core',
            target => $repair_target,
        ),
        '_stage_managed_helper repairs a zero-byte managed helper target under the dd namespace',
    );
    open my $repair_verify_fh, '<', $repair_target or die "Unable to read $repair_target: $!";
    my $repair_verify = do { local $/; <$repair_verify_fh> };
    close $repair_verify_fh;
    is(
        $repair_verify,
        Developer::Dashboard::InternalCLI::_managed_helper_content('_dashboard-core'),
        '_stage_managed_helper rewrites the full managed helper body when the target was truncated to zero bytes',
    );
}
{
    my $atomic_home = tempdir( CLEANUP => 1 );
    my $atomic_target = File::Spec->catfile( $atomic_home, 'helper' );
    my $read_atomic_target = sub {
        open my $fh, '<', $atomic_target or die "Unable to read $atomic_target: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        return $content;
    };
    ok(
        Developer::Dashboard::InternalCLI::_write_helper_atomically( $atomic_target, "one\n" ),
        '_write_helper_atomically writes the first helper payload through a temp file and rename',
    );
    is( $read_atomic_target->(), "one\n", '_write_helper_atomically leaves the requested helper body on disk' );
    ok(
        Developer::Dashboard::InternalCLI::_write_helper_atomically( $atomic_target, "two\n" ),
        '_write_helper_atomically also replaces an existing helper payload atomically',
    );
    is( $read_atomic_target->(), "two\n", '_write_helper_atomically leaves the replacement helper body on disk' );
    is_deeply(
        [ sort glob( $atomic_target . '.tmp.*' ) ],
        [],
        '_write_helper_atomically does not leave temporary helper fragments behind',
    );
}
{
    my $rename_fail_home = tempdir( CLEANUP => 1 );
    my $rename_fail_target = File::Spec->catdir( $rename_fail_home, 'helper-target-dir' );
    make_path($rename_fail_target);

    my $error = eval {
        Developer::Dashboard::InternalCLI::_write_helper_atomically( $rename_fail_target, "broken\n" );
        return;
    };
    like(
        $@,
        qr/\AUnable to rename \Q$rename_fail_target\E\.tmp\.\d+\.\d+ to \Q$rename_fail_target\E:/,
        '_write_helper_atomically reports rename failures explicitly when the final helper target cannot be replaced',
    );
    is_deeply(
        [ sort glob( $rename_fail_target . '.tmp.*' ) ],
        [],
        '_write_helper_atomically cleans up the temporary helper file after a rename failure',
    );
}
{
    my $replace_home = tempdir( CLEANUP => 1 );
    my $replace_target = File::Spec->catfile( $replace_home, '_dashboard-core' );
    open my $replace_existing_fh, '>:raw', $replace_target or die "Unable to write $replace_target: $!";
    print {$replace_existing_fh} "old\n";
    close $replace_existing_fh or die "Unable to close $replace_target: $!";

    my @rename_calls;
    my @unlink_calls;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::InternalCLI::is_windows = sub { return 1 };
        local *Developer::Dashboard::InternalCLI::_rename_path = sub {
            my ( $source, $target ) = @_;
            push @rename_calls, [ $source, $target ];
            if ( @rename_calls == 1 ) {
                $! = EACCES;
                return 0;
            }
            return rename $source, $target;
        };
        local *Developer::Dashboard::InternalCLI::_unlink_path = sub {
            my ($path) = @_;
            push @unlink_calls, $path;
            return unlink $path;
        };
        ok(
            Developer::Dashboard::InternalCLI::_write_helper_atomically( $replace_target, "new\n" ),
            '_write_helper_atomically retries the final Windows helper replace after removing the existing target',
        );
    }
    is( scalar @rename_calls, 2, '_write_helper_atomically retries one Windows helper rename after the initial collision' );
    is_deeply( \@unlink_calls, [$replace_target], '_write_helper_atomically removes the existing Windows helper target before retrying the replace' );
    open my $replace_read_fh, '<:raw', $replace_target or die "Unable to read $replace_target: $!";
    local $/;
    is( <$replace_read_fh>, "new\n", '_write_helper_atomically leaves the retried Windows helper payload on disk' );
    close $replace_read_fh or die "Unable to close $replace_target after retry verification: $!";
}
{
    my $defer_home = tempdir( CLEANUP => 1 );
    my $defer_target = File::Spec->catfile( $defer_home, '_dashboard-core' );
    my $stale_core = Developer::Dashboard::InternalCLI::_managed_helper_content('_dashboard-core') . "# stale\n";
    open my $defer_fh, '>:raw', $defer_target or die "Unable to write $defer_target: $!";
    print {$defer_fh} $stale_core;
    close $defer_fh or die "Unable to close $defer_target: $!";

    local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER} = $defer_target;
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { return 1 };

    ok(
        !Developer::Dashboard::InternalCLI::_stage_managed_helper(
            paths  => $paths,
            name   => '_dashboard-core',
            target => $defer_target,
        ),
        '_stage_managed_helper defers replacing the running _dashboard-core helper on Windows instead of dying',
    );
    open my $defer_read_fh, '<:raw', $defer_target or die "Unable to read $defer_target: $!";
    local $/;
    is( <$defer_read_fh>, $stale_core, '_stage_managed_helper leaves the running Windows _dashboard-core helper unchanged when refresh is deferred' );
    close $defer_read_fh or die "Unable to close $defer_target after verification: $!";
}
{
    my $defer_home = tempdir( CLEANUP => 1 );
    my $defer_target = File::Spec->catfile( $defer_home, 'init' );
    my $stale_helper = Developer::Dashboard::InternalCLI::_managed_helper_content('init') . "# stale\n";
    open my $defer_fh, '>:raw', $defer_target or die "Unable to write $defer_target: $!";
    print {$defer_fh} $stale_helper;
    close $defer_fh or die "Unable to close $defer_target: $!";

    local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER} = $defer_target;
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { return 1 };

    ok(
        !Developer::Dashboard::InternalCLI::_stage_managed_helper(
            paths  => $paths,
            name   => 'init',
            target => $defer_target,
        ),
        '_stage_managed_helper also defers replacing the running Windows wrapper helper instead of dying',
    );
    open my $defer_read_fh, '<:raw', $defer_target or die "Unable to read $defer_target: $!";
    local $/;
    is( <$defer_read_fh>, $stale_helper, '_stage_managed_helper leaves the running Windows wrapper helper unchanged when refresh is deferred' );
    close $defer_read_fh or die "Unable to close $defer_target after verification: $!";
}
{
    my $wrapper_body = Developer::Dashboard::InternalCLI::_managed_helper_content('init');
    like(
        $wrapper_body,
        qr/DEVELOPER_DASHBOARD_RUNNING_HELPER/,
        '_managed_helper_content stamps wrapper helpers with the running-helper environment marker for Windows-safe refresh deferral',
    );
}
{
    my $core_body = Developer::Dashboard::InternalCLI::helper_content('_dashboard-core');
    like(
        $core_body,
        qr/DEVELOPER_DASHBOARD_RUNNING_HELPER/,
        'helper_content exposes the _dashboard-core init fallback that seeds the running-helper marker when older wrappers did not set it',
    );
    like(
        $core_body,
        qr/helper_path\(\s*paths => \$paths,\s*name\s*=> 'init'/s,
        'helper_content seeds the running-helper marker from the staged init helper path inside dashboard init on Windows',
    );
    like(
        $core_body,
        qr/skip_names\} = \['init'\]/,
        'helper_content skips rewriting the active init helper during Windows dashboard init refresh',
    );
}
{
    my $skip_home  = tempdir( CLEANUP => 1 );
    my $skip_paths = Developer::Dashboard::PathRegistry->new( home => $skip_home );
    my $written = Developer::Dashboard::InternalCLI::ensure_helpers(
        paths      => $skip_paths,
        skip_names => ['init'],
    );
    ok(
        !grep( $_ =~ m{/\Qinit\E$}, @$written ),
        'ensure_helpers can skip staging one named helper while still refreshing the rest of the managed helper set',
    );
    ok(
        !-e Developer::Dashboard::InternalCLI::helper_path( paths => $skip_paths, name => 'init' ),
        'ensure_helpers leaves the skipped helper target untouched on disk',
    );
    ok(
        grep( $_ =~ m{/\Qshell\E$}, @$written ),
        'ensure_helpers still stages non-skipped helpers when one helper name is excluded',
    );
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
    local $ENV{HOME} = tempdir( CLEANUP => 1 );
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root = sub { return File::Spec->catdir( $shared_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return File::Spec->catdir( $shared_root, 'missing-private-cli' ) };
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
{
    my $install_root = tempdir( CLEANUP => 1 );
    my $shared_private_cli_root = File::Spec->catdir( $install_root, 'private-cli' );
    make_path($shared_private_cli_root);
    my $shared_helper = File::Spec->catfile( $shared_private_cli_root, '_dashboard-core' );
    open my $shared_fh, '>:raw', $shared_helper or die "Unable to write $shared_helper: $!";
    print {$shared_fh} "#!/usr/bin/env perl\nprint qq(core\\n);\n";
    close $shared_fh or die "Unable to close $shared_helper: $!";

    local $ENV{HOME} = tempdir( CLEANUP => 1 );
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root = sub { return File::Spec->catdir( $install_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return File::Spec->catdir( $install_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::dist_dir = sub { return $shared_private_cli_root };
    local *Developer::Dashboard::InternalCLI::_module_install_lib_root = sub { return File::Spec->catdir( $install_root, 'missing-lib-root' ) };

    is(
        Developer::Dashboard::InternalCLI::_shared_private_cli_root(),
        $shared_private_cli_root,
        'internal CLI accepts a dist_dir result that already points at the private-cli root',
    );
    is(
        Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core'),
        $shared_helper,
        'internal CLI resolves helper assets when File::ShareDir already returns the private-cli root itself',
    );
}
{
    my $install_root = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = tempdir( CLEANUP => 1 );
    my $module_lib_root = File::Spec->catdir( $install_root, 'lib', 'perl5' );
    my $broken_dist_root = File::Spec->catdir(
        $install_root,
        'lib',
        'perl5',
        'MSWin32-x64-multi-thread',
        'auto',
        'Developer',
        'Dashboard',
    );
    my $broken_private_cli_root = File::Spec->catdir( $broken_dist_root, 'private-cli' );
    my $shared_private_cli_root = File::Spec->catdir(
        $module_lib_root,
        'auto',
        'share',
        'dist',
        'Developer-Dashboard',
        'private-cli',
    );
    make_path( $broken_private_cli_root, $shared_private_cli_root );
    my $shared_helper = File::Spec->catfile( $shared_private_cli_root, '_dashboard-core' );
    open my $shared_fh, '>:raw', $shared_helper or die "Unable to write $shared_helper: $!";
    print {$shared_fh} "#!/usr/bin/env perl\nprint qq(core\\n);\n";
    close $shared_fh or die "Unable to close $shared_helper: $!";

    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root = sub { return File::Spec->catdir( $install_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return File::Spec->catdir( $install_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::dist_dir = sub { return $broken_dist_root };
    local *Developer::Dashboard::InternalCLI::_module_install_lib_root = sub { return $module_lib_root };

    is(
        Developer::Dashboard::InternalCLI::_shared_private_cli_root(),
        $shared_private_cli_root,
        'internal CLI falls back to the module-relative auto/share dist helper root when File::ShareDir points at an existing but empty arch auto private-cli directory',
    );
    is(
        Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core'),
        $shared_helper,
        'internal CLI finds _dashboard-core through the module-relative shared helper fallback when the default dist_dir root is wrong',
    );
}
{
    my $home = tempdir( CLEANUP => 1 );
    my $home_private_cli_root = File::Spec->catdir( $home, '.developer-dashboard', 'cli' );
    my $managed_dd_root = File::Spec->catdir( $home_private_cli_root, 'dd' );
    make_path($managed_dd_root);
    make_path($home_private_cli_root);
    my $home_helper = File::Spec->catfile( $home_private_cli_root, '_dashboard-core' );
    open my $home_fh, '>:raw', $home_helper or die "Unable to write $home_helper: $!";
    print {$home_fh} "#!/usr/bin/env perl\nprint qq(home\\n);\n";
    close $home_fh or die "Unable to close $home_helper: $!";
    my $managed_core = File::Spec->catfile( $managed_dd_root, '_dashboard-core' );
    open my $managed_fh, '>:raw', $managed_core or die "Unable to write $managed_core: $!";
    print {$managed_fh} "#!/usr/bin/env perl\nprint qq(managed\\n);\n";
    close $managed_fh or die "Unable to close $managed_core: $!";
    my $home_jq = File::Spec->catfile( $home_private_cli_root, 'jq' );
    open my $home_jq_fh, '>:raw', $home_jq or die "Unable to write $home_jq: $!";
    print {$home_jq_fh} "#!/usr/bin/env perl\nprint qq(jq\\n);\n";
    close $home_jq_fh or die "Unable to close $home_jq: $!";

    local $ENV{HOME} = $home;
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root = sub { return File::Spec->catdir( $home, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return File::Spec->catdir( $home, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::dist_dir = sub { return File::Spec->catdir( $home, 'missing-dist-root' ) };
    local *Developer::Dashboard::InternalCLI::_module_install_lib_root = sub { return File::Spec->catdir( $home, 'missing-lib-root' ) };

    is(
        Developer::Dashboard::InternalCLI::_shared_private_cli_root(),
        $managed_dd_root,
        'internal CLI prefers the managed dd helper root once checkout installs have already staged _dashboard-core there',
    );
    is(
        Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core'),
        $managed_core,
        'internal CLI finds _dashboard-core through the managed dd helper root once checkout installs have staged it there',
    );
    is(
        Developer::Dashboard::InternalCLI::_helper_asset_path('jq'),
        $home_jq,
        'internal CLI still falls back to the home bootstrap helper file for non-core helpers while the managed dd helper root is only partially staged',
    );
}
{
    my $install_root = tempdir( CLEANUP => 1 );
    my $blib_root = File::Spec->catdir( $install_root, 'blib', 'lib' );
    my $shared_private_cli_root = File::Spec->catdir( $install_root, 'auto', 'share', 'dist', 'Developer-Dashboard', 'private-cli' );
    make_path($shared_private_cli_root);
    my $shared_helper = File::Spec->catfile( $shared_private_cli_root, '_dashboard-core' );
    open my $shared_fh, '>:raw', $shared_helper or die "Unable to write $shared_helper: $!";
    print {$shared_fh} "#!/usr/bin/env perl\nprint qq(core\\n);\n";
    close $shared_fh or die "Unable to close $shared_helper: $!";

    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root = sub { return File::Spec->catdir( $install_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return File::Spec->catdir( $install_root, 'missing-private-cli' ) };
    local *Developer::Dashboard::InternalCLI::_module_source_path = sub { return File::Spec->catfile( $blib_root, 'Developer', 'Dashboard', 'InternalCLI.pm' ) };
    local *Developer::Dashboard::InternalCLI::dist_dir = sub { return File::Spec->catdir( $install_root, 'missing-dist-root' ) };
    local *Developer::Dashboard::InternalCLI::_shared_private_cli_root_candidates = sub { return ($shared_private_cli_root) };

    is(
        Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core'),
        $shared_helper,
        'internal CLI uses shared helper candidates directly when the module source path comes from a blib build tree',
    );
}
{
    my $candidate_root = tempdir( CLEANUP => 1 );
    my $first = File::Spec->catdir( $candidate_root, 'first-private-cli' );
    my $second = File::Spec->catdir( $candidate_root, 'second-private-cli' );
    make_path( $first, $second );

    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return ( $first, $second ) };
    local *Developer::Dashboard::InternalCLI::_private_cli_root_has_dashboard_core = sub { return 0 };

    is(
        Developer::Dashboard::InternalCLI::_repo_private_cli_root(),
        $first,
        'internal CLI falls back to the first repo helper candidate when none of them expose _dashboard-core',
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

{
    no warnings 'redefine';
    require File::ShareDir;
    local *File::ShareDir::dist_dir = sub { return '/tmp/internal-cli-dist-root' };
    is(
        Developer::Dashboard::InternalCLI::dist_dir('Developer-Dashboard'),
        '/tmp/internal-cli-dist-root',
        'InternalCLI dist_dir lazily proxies File::ShareDir::dist_dir',
    );
}

my $paths_output = capture {
    Developer::Dashboard::CLI::Paths::run_paths_command( command => 'paths', args => [] );
};
like( $paths_output, qr/^Path\s+Value/m, 'CLI::Paths renders the default paths summary table' );
like( $paths_output, qr/home_runtime_root/, 'CLI::Paths default table includes the home runtime row' );
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
            args    => [ 'add', 'named-home-target', $named_dir, '-o', 'json' ],
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
            args    => [ 'locate', 'sample', '-o', 'json' ],
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
            args    => [ 'list', '-o', 'json' ],
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
            args    => [ 'add', '.', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Paths add . writes no stderr on success' );
    my $added_dot_alias = json_decode($stdout);
    is( $added_dot_alias->{name}, 'path-cmd-project', 'CLI::Paths add . derives the alias name from the current directory basename' );
    is_same_path( $added_dot_alias->{path}, $project_dir, 'CLI::Paths add . stores the current directory as the target path' );
    is_same_path( $added_dot_alias->{resolved}, $project_dir, 'CLI::Paths add . resolves back to the current directory' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'add', 'here', '.', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Paths add NAME . writes no stderr on success' );
    my $added_here_alias = json_decode($stdout);
    is( $added_here_alias->{name}, 'here', 'CLI::Paths add NAME . preserves the explicit alias name' );
    is_same_path( $added_here_alias->{path}, $project_dir, 'CLI::Paths add NAME . stores the current directory as the target path' );
    is_same_path( $added_here_alias->{resolved}, $project_dir, 'CLI::Paths add NAME . resolves to the current directory target' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'del', 'named-home-target', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Paths del writes no stderr on success' );
    my $deleted_alias = json_decode($stdout);
    is( $deleted_alias->{name}, 'named-home-target', 'CLI::Paths del returns the deleted alias name' );
    is( $deleted_alias->{removed}, 1, 'CLI::Paths del reports successful removal' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'del', '.', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Paths del . writes no stderr on success' );
    my $deleted_dot_alias = json_decode($stdout);
    is( $deleted_dot_alias->{name}, 'path-cmd-project', 'CLI::Paths del . removes the basename-derived alias that points at the current directory' );
    is( $deleted_dot_alias->{removed}, 1, 'CLI::Paths del . reports successful removal' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'rm', 'here', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Paths rm writes no stderr on success' );
    my $removed_here_alias = json_decode($stdout);
    is( $removed_here_alias->{name}, 'here', 'CLI::Paths rm returns the removed alias name' );
    is( $removed_here_alias->{removed}, 1, 'CLI::Paths rm aliases the delete behavior' );

    like(
        _dies( sub { Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => ['bogus'] ) } ),
        qr/Usage: dashboard path <resolve\|locate\|cdr\|complete-cdr\|add\|del\|rm\|project-root\|list> \.\.\./,
        'CLI::Paths rejects unsupported path subcommands with a usage error',
    );

    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}
{
    my $cwd = getcwd();
    my $home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $home;
    my $project_dir = File::Spec->catdir( $home, 'project' );
    make_path(
        File::Spec->catdir( $home, '.developer-dashboard', 'config' ),
        File::Spec->catdir( $project_dir, '.git' ),
    );
    chdir $project_dir or die "Unable to chdir to $project_dir: $!";

    my ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command(
            command => 'file',
            args    => [ 'add', 'notes', File::Spec->catfile( $home, 'notes.txt' ), '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Files add writes no stderr on success' );
    my $added_file = json_decode($stdout);
    is( $added_file->{name}, 'notes', 'CLI::Files add returns the saved alias name' );
    is( $added_file->{path}, File::Spec->catfile( $home, 'notes.txt' ), 'CLI::Files add returns the resolved alias target file' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command(
            command => 'file',
            args    => [ 'resolve', 'notes' ],
        );
    };
    is( $stderr, '', 'CLI::Files resolve writes no stderr on success' );
    chomp $stdout;
    is_same_path( $stdout, File::Spec->catfile( $home, 'notes.txt' ), 'CLI::Files resolve prints the saved file alias target' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command(
            command => 'file',
            args    => [ 'list', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Files list writes no stderr on success' );
    my $listed_files = json_decode($stdout);
    is( $listed_files->{notes}, File::Spec->catfile( $home, 'notes.txt' ), 'CLI::Files list includes saved file aliases' );

    ( $stdout, $stderr ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command(
            command => 'file',
            args    => [ 'del', 'notes', '-o', 'json' ],
        );
    };
    is( $stderr, '', 'CLI::Files del writes no stderr on success' );
    my $deleted_file = json_decode($stdout);
    is( $deleted_file->{name}, 'notes', 'CLI::Files del returns the deleted alias name' );
    is( $deleted_file->{removed}, 1, 'CLI::Files del reports successful removal' );

    like(
        _dies( sub { Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => ['bogus'] ) } ),
        qr/Usage: dashboard file <resolve\|locate\|add\|del\|list> \.\.\./,
        'CLI::Files rejects unsupported file subcommands with a usage error',
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
like(
    _dies( sub { Developer::Dashboard::CLI::Ticket::resolve_ticket_request( args => 'DD-123' ) } ),
    qr/Ticket args must be an array reference/,
    'resolve_ticket_request rejects non-array argv containers',
);
my $isolated_ticket_env_cwd = tempdir( CLEANUP => 1 );
is_deeply(
    Developer::Dashboard::CLI::Ticket::ticket_environment( 'DD-123', cwd => $isolated_ticket_env_cwd ),
    {
        TICKET_REF                      => 'DD-123',
        B                               => 'DD-123',
        OB                              => 'origin/DD-123',
        DEVELOPER_DASHBOARD_TMUX_STATUS => 1,
    },
    'ticket_environment builds the expected tmux environment values',
);
like(
    _dies( sub { Developer::Dashboard::CLI::Ticket::ticket_environment('') } ),
    qr/Ticket name is required/,
    'ticket_environment rejects empty ticket names',
);
{
    my $workspace_root = tempdir( CLEANUP => 1 );
    my $workspace_parent = File::Spec->catdir( $workspace_root, 'parent' );
    my $workspace_child  = File::Spec->catdir( $workspace_parent, 'child' );
    make_path($workspace_child);
    _write_file( File::Spec->catfile( $workspace_root, '.env' ), "ROOT_ONLY=root\nSHARED=root\n" );
    _write_file( File::Spec->catfile( $workspace_parent, '.env' ), "PARENT_ONLY=parent\nSHARED=parent\n" );
    _write_file( File::Spec->catfile( $workspace_child, '.env' ), "CHILD_ONLY=child\nSHARED=child\n" );

    my $workspace_env = Developer::Dashboard::CLI::Ticket::workspace_environment( 'DD-123', cwd => $workspace_child );
    is( $workspace_env->{ROOT_ONLY}, 'root', 'workspace_environment loads the highest ancestor .env as the base layer' );
    is( $workspace_env->{PARENT_ONLY}, 'parent', 'workspace_environment loads parent .env files after the root base layer' );
    is( $workspace_env->{CHILD_ONLY}, 'child', 'workspace_environment loads the current directory .env last' );
    is( $workspace_env->{SHARED}, 'child', 'workspace_environment lets the current directory .env override shallower values' );
    is( $workspace_env->{WORKSPACE_REF}, 'DD-123', 'workspace_environment seeds WORKSPACE_REF for workspace sessions' );
    is( $workspace_env->{TICKET_REF}, 'DD-123', 'workspace_environment keeps TICKET_REF for compatibility with older prompt flows' );
    is(
        $workspace_env->{DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS},
        'CHILD_ONLY:PARENT_ONLY:ROOT_ONLY:SHARED',
        'workspace_environment records the layered .env keys for later tmux session refresh',
    );
}
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
is_deeply(
    [
        Developer::Dashboard::CLI::Ticket::list_sessions(
            tmux => sub {
                return {
                    exit_code => 0,
                    stdout    => "DD-100\n\nDD-200\n",
                    stderr    => '',
                };
            },
        )
    ],
    [ qw(DD-100 DD-200) ],
    'list_sessions returns one ordered tmux session name per line',
);
is_deeply(
    [
        Developer::Dashboard::CLI::Ticket::list_sessions(
            tmux => sub { return { exit_code => 1, stdout => '', stderr => '' } },
        )
    ],
    [],
    'list_sessions returns an empty list when tmux reports no sessions are available',
);
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::list_sessions(
                tmux => sub { return { exit_code => 2, stdout => "oops\n", stderr => "bad\n" } },
            );
        }
    ),
    qr/Unable to list tmux ticket sessions: bad\noops\n/,
    'list_sessions surfaces unexpected tmux list failures',
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
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Ticket::cwd = sub { return '/tmp/default-ticket-cwd' };
    my $default_cwd_plan = Developer::Dashboard::CLI::Ticket::build_ticket_plan(
        args => ['DD-456'],
        tmux => sub { return { exit_code => 1, stdout => '', stderr => '' } },
    );
    is( $default_cwd_plan->{cwd}, '/tmp/default-ticket-cwd', 'build_ticket_plan falls back to cwd when no explicit cwd is provided' );
}

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
    is_deeply( $tmux_calls[-1], [ 'attach-session', '-t', 'DD-789' ], 'run_ticket_command attaches to the requested tmux session after configuring tmux status' );
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
    is( $tmux_calls[0][0], 'has-session', 'run_ticket_command still checks whether the session exists first' );
    is_deeply( $tmux_calls[-1], [ 'attach-session', '-t', 'DD-790' ], 'run_ticket_command still finishes by attaching to an existing session' );
    ok( scalar(@tmux_calls) > 2, 'run_ticket_command also refreshes tmux status before attaching to an existing session' );
}
{
    my $workspace_root = tempdir( CLEANUP => 1 );
    my $workspace_parent = File::Spec->catdir( $workspace_root, 'parent' );
    my $workspace_child  = File::Spec->catdir( $workspace_parent, 'child' );
    make_path($workspace_child);
    _write_file( File::Spec->catfile( $workspace_root, '.env' ), "ROOT_ONLY=root\nSHARED=root\n" );
    _write_file( File::Spec->catfile( $workspace_parent, '.env' ), "PARENT_ONLY=parent\nSHARED=parent\n" );
    _write_file( File::Spec->catfile( $workspace_child, '.env' ), "CHILD_ONLY=child\nSHARED=child\n" );

    my @tmux_calls;
    Developer::Dashboard::CLI::Ticket::run_workspace_command(
        args => ['DD-790A'],
        cwd  => $workspace_child,
        tmux => sub {
            my (%call) = @_;
            push @tmux_calls, [ @{ $call{args} } ];
            return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'has-session';
            return {
                exit_code => 0,
                stdout    => "DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS=OLD_ONLY:SHARED\n",
                stderr    => '',
            } if $call{args}[0] eq 'show-environment';
            return { exit_code => 0, stdout => '', stderr => '' };
        },
    );
    ok(
        scalar( grep { $_->[0] eq 'set-environment' && $_->[3] eq '-u' && $_->[4] eq 'OLD_ONLY' } @tmux_calls ),
        'run_workspace_command unsets stale layered tmux env keys when a workspace session is resumed',
    );
    ok(
        scalar( grep { $_->[0] eq 'set-environment' && $_->[3] eq 'ROOT_ONLY' && $_->[4] eq 'root' } @tmux_calls ),
        'run_workspace_command refreshes root-layer .env values into resumed workspace sessions',
    );
    ok(
        scalar( grep { $_->[0] eq 'set-environment' && $_->[3] eq 'PARENT_ONLY' && $_->[4] eq 'parent' } @tmux_calls ),
        'run_workspace_command refreshes parent-layer .env values into resumed workspace sessions',
    );
    ok(
        scalar( grep { $_->[0] eq 'set-environment' && $_->[3] eq 'CHILD_ONLY' && $_->[4] eq 'child' } @tmux_calls ),
        'run_workspace_command refreshes current-directory .env values into resumed workspace sessions',
    );
    ok(
        scalar( grep { $_->[0] eq 'set-environment' && $_->[3] eq 'SHARED' && $_->[4] eq 'child' } @tmux_calls ),
        'run_workspace_command applies current-directory .env values as the final override when a workspace session is resumed',
    );
}
{
    my ( $clean, $flag ) = Developer::Dashboard::CLI::Ticket::split_workspace_change_dir_args( [ '-c', 'foobar' ] );
    is_deeply( $clean, ['foobar'], 'split_workspace_change_dir_args strips a leading -c flag from workspace argv' );
    is( $flag, 1, 'split_workspace_change_dir_args reports the change-directory flag when -c leads the argv' );
    ( $clean, $flag ) = Developer::Dashboard::CLI::Ticket::split_workspace_change_dir_args( [ 'foobar', '-c' ] );
    is_deeply( $clean, ['foobar'], 'split_workspace_change_dir_args strips a trailing -c flag from workspace argv' );
    is( $flag, 1, 'split_workspace_change_dir_args reports the change-directory flag when -c trails the workspace name' );
    ( $clean, $flag ) = Developer::Dashboard::CLI::Ticket::split_workspace_change_dir_args( ['foobar'] );
    is_deeply( $clean, ['foobar'], 'split_workspace_change_dir_args keeps plain workspace argv unchanged' );
    is( $flag, 0, 'split_workspace_change_dir_args reports no change-directory flag for plain workspace argv' );
    like(
        _dies( sub { Developer::Dashboard::CLI::Ticket::split_workspace_change_dir_args('foobar') } ),
        qr/Workspace args must be an array reference/,
        'split_workspace_change_dir_args rejects argv that is not an array reference',
    );
}
for my $flag_order ( [ '-c', 'foobar' ], [ 'foobar', '-c' ] ) {
    my $registered_root = tempdir( CLEANUP => 1 );
    my $registered_target = abs_path($registered_root);
    my @tmux_calls;
    my @resolve_calls;
    my $old_cwd = getcwd();
    my $plan = Developer::Dashboard::CLI::Ticket::run_workspace_command(
        args        => [ @{$flag_order} ],
        resolve_dir => sub { push @resolve_calls, $_[0]; return $registered_target },
        tmux        => sub {
            my (%call) = @_;
            push @tmux_calls, [ @{ $call{args} } ];
            return { exit_code => 1, stdout => '', stderr => '' } if $call{args}[0] eq 'has-session';
            return { exit_code => 0, stdout => '', stderr => '' };
        },
    );
    my $order_label = join ' ', @{$flag_order};
    is_deeply( \@resolve_calls, ['foobar'], "workspace -c resolves the workspace name through the registered paths inventory for '$order_label'" );
    is( abs_path( getcwd() ), $registered_target, "workspace -c changes the helper process into the registered directory first for '$order_label'" );
    is( $plan->{session}, 'foobar', "workspace -c keeps the workspace session name free of the flag for '$order_label'" );
    is( $plan->{cwd}, $registered_target, "workspace -c plans the tmux session from the registered directory for '$order_label'" );
    my ($create_call) = grep { $_->[0] eq 'new-session' } @tmux_calls;
    ok( $create_call, "workspace -c still creates the tmux session when it does not exist for '$order_label'" );
    my %create_pairs;
    for my $index ( 1 .. $#{$create_call} - 1 ) {
        $create_pairs{ $create_call->[$index] } = $create_call->[ $index + 1 ];
    }
    is( $create_pairs{'-c'}, $registered_target, "workspace -c starts the tmux session inside the registered directory for '$order_label'" );
    chdir $old_cwd or die "Unable to restore cwd to $old_cwd: $!";
}
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::run_workspace_command(
                args        => [ '-c', 'unregistered-workspace' ],
                resolve_dir => sub { return '' },
                tmux        => sub { return { exit_code => 0, stdout => '', stderr => '' } },
            );
        }
    ),
    qr/Workspace 'unregistered-workspace' is not a registered dashboard path/,
    'workspace -c refuses to run when the workspace name is not a registered dashboard path',
);
{
    my $not_dir_root = tempdir( CLEANUP => 1 );
    my $not_dir = File::Spec->catfile( $not_dir_root, 'plain-file' );
    _write_file( $not_dir, "not a directory\n" );
    like(
        _dies(
            sub {
                Developer::Dashboard::CLI::Ticket::run_workspace_command(
                    args        => [ '-c', 'file-backed' ],
                    resolve_dir => sub { return $not_dir },
                    tmux        => sub { return { exit_code => 0, stdout => '', stderr => '' } },
                );
            }
        ),
        qr/resolves to '\Q$not_dir\E', which is not a directory/,
        'workspace -c refuses to change into a registered path that is not a directory',
    );
}
{
    my $blocked_root = tempdir( CLEANUP => 1 );
    my $blocked_dir = File::Spec->catdir( $blocked_root, 'blocked' );
    make_path($blocked_dir);
    chmod 0000, $blocked_dir or die "Unable to chmod $blocked_dir: $!";
    like(
        _dies(
            sub {
                Developer::Dashboard::CLI::Ticket::run_workspace_command(
                    args        => [ '-c', 'blocked-workspace' ],
                    resolve_dir => sub { return $blocked_dir },
                    tmux        => sub { return { exit_code => 0, stdout => '', stderr => '' } },
                );
            }
        ),
        qr/Unable to change directory to '\Q$blocked_dir\E' for workspace 'blocked-workspace'/,
        'workspace -c surfaces the chdir failure instead of starting the workspace from the wrong directory',
    );
    chmod 0700, $blocked_dir or die "Unable to restore permissions on $blocked_dir: $!";
}
{
    my $alias_home = tempdir( CLEANUP => 1 );
    my $alias_target = File::Spec->catdir( $alias_home, 'projects', 'foobar-repo' );
    make_path($alias_target);
    my $alias_config_dir = File::Spec->catdir( $alias_home, '.developer-dashboard', 'config' );
    make_path($alias_config_dir);
    _write_file(
        File::Spec->catfile( $alias_config_dir, 'config.json' ),
        json_encode( { path_aliases => { foobar => $alias_target } } ),
    );
    local $ENV{HOME} = $alias_home;
    my $old_cwd = getcwd();
    chdir $alias_home or die "Unable to chdir to $alias_home: $!";
    my $resolved = Developer::Dashboard::CLI::Ticket::registered_workspace_dir('foobar');
    my $missing  = Developer::Dashboard::CLI::Ticket::registered_workspace_dir('not-a-registered-alias');
    chdir $old_cwd or die "Unable to restore cwd to $old_cwd: $!";
    is( abs_path($resolved), abs_path($alias_target), 'registered_workspace_dir resolves configured path aliases like cdr does' );
    is( $missing, '', 'registered_workspace_dir returns an empty target for names that are not registered' );
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
                    return {
                        exit_code => 0,
                        stdout    => "DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS=\n",
                        stderr    => '',
                    } if $call{args}[0] eq 'show-environment';
                    return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'set-environment';
                    return { exit_code => 3, stdout => "attach\n", stderr => "denied\n" } if $call{args}[0] eq 'set-option';
                    return { exit_code => 0, stdout => '', stderr => '' };
                },
            );
        }
    ),
    qr/Unable to configure tmux ticket status for 'DD-792': denied\nattach\n/,
    'run_ticket_command surfaces tmux status configuration failures before attach',
);
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::run_ticket_command(
                args => ['DD-793'],
                cwd  => '/tmp/work-here',
                tmux => sub {
                    my (%call) = @_;
                    return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'has-session';
                    return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'show-options';
                    return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'set-option' || $call{args}[0] eq 'set-option';
                    return { exit_code => 4, stdout => "attach-out\n", stderr => "attach-err\n" } if $call{args}[0] eq 'attach-session';
                    return { exit_code => 0, stdout => '', stderr => '' };
                },
            );
        }
    ),
    qr/Unable to attach tmux ticket session 'DD-793': attach-err\nattach-out\n/,
    'run_ticket_command surfaces tmux attach failures after status setup succeeds',
);
{
    my @tmux_calls;
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '/tmp/fake-dashboard';
    is(
        Developer::Dashboard::CLI::Ticket::apply_ticket_status(
            session => 'DD-794',
            tmux    => sub {
                my (%call) = @_;
                push @tmux_calls, [ @{ $call{args} } ];
                return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'show-options';
                return { exit_code => 0, stdout => '', stderr => '' };
            },
        ),
        1,
        'apply_ticket_status succeeds when it resolves the dashboard entrypoint from the environment',
    );
    like(
        join( "\n", map { join ' ', @{$_} } @tmux_calls ),
        qr{/tmp/fake-dashboard' ps1 --mode tmux-status-top --width \#\{client_width\}},
        'apply_ticket_status uses the environment-provided dashboard entrypoint in the tmux status command',
    );
}
{
    my @tmux_calls;
    is(
        Developer::Dashboard::CLI::Ticket::apply_workspace_status(
            session => 'DD-794W',
            tmux    => sub {
                my (%call) = @_;
                push @tmux_calls, [ @{ $call{args} } ];
                return { exit_code => 0, stdout => '', stderr => '' };
            },
        ),
        1,
        'apply_workspace_status delegates through the shared tmux status configurator',
    );
    is_deeply(
        $tmux_calls[0],
        [ 'show-options', '-gqv', '@dd_ticket_status_default' ],
        'apply_workspace_status starts from the same tmux default-status lookup as apply_ticket_status',
    );
}
{
    my @tmux_calls;
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '';
    local *Developer::Dashboard::CLI::Ticket::command_in_path = sub { return '/tmp/bin/dashboard'; };
    is(
        Developer::Dashboard::CLI::Ticket::apply_ticket_status(
            session => 'DD-795',
            tmux    => sub {
                my (%call) = @_;
                push @tmux_calls, [ @{ $call{args} } ];
                return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'show-options';
                return { exit_code => 0, stdout => '', stderr => '' };
            },
        ),
        1,
        'apply_ticket_status succeeds when it resolves the dashboard entrypoint from PATH',
    );
    like(
        join( "\n", map { join ' ', @{$_} } @tmux_calls ),
        qr{/tmp/bin/dashboard' ps1 --mode tmux-status-top --width \#\{client_width\}},
        'apply_ticket_status uses the PATH-resolved dashboard entrypoint in the tmux status command',
    );
}
{
    my @tmux_calls;
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '';
    local *Developer::Dashboard::CLI::Ticket::command_in_path = sub { return undef; };
    is(
        Developer::Dashboard::CLI::Ticket::apply_ticket_status(
            session => 'DD-795A',
            tmux    => sub {
                my (%call) = @_;
                push @tmux_calls, [ @{ $call{args} } ];
                return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'show-options';
                return { exit_code => 0, stdout => '', stderr => '' };
            },
        ),
        1,
        'apply_ticket_status falls back to the literal dashboard command name when no explicit entrypoint can be resolved',
    );
    like(
        join( "\n", map { join ' ', @{$_} } @tmux_calls ),
        qr/\#\('dashboard' ps1 --mode tmux-status-top --width \#\{client_width\}\)/,
        'apply_ticket_status uses the literal dashboard command fallback in the tmux status command',
    );
}
{
    my @tmux_calls;
    is(
        Developer::Dashboard::CLI::Ticket::apply_ticket_status(
            session => 'DD-796',
            dashboard => '/tmp/custom-dashboard',
            tmux    => sub {
                my (%call) = @_;
                push @tmux_calls, [ @{ $call{args} } ];
                return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'show-options' && $call{args}[2] eq '@dd_ticket_status_default';
                return { exit_code => 0, stdout => "#[default-status]\n", stderr => '' } if $call{args}[0] eq 'show-options' && $call{args}[2] eq 'status-format[0]';
                return { exit_code => 0, stdout => '', stderr => '' };
            },
        ),
        1,
        'apply_ticket_status records the tmux default status row when it is missing',
    );
    ok(
        ( scalar grep { $_->[0] eq 'set-option' && $_->[2] eq '@dd_ticket_status_default' && $_->[3] eq '#[default-status]' } @tmux_calls ),
        'apply_ticket_status saves the discovered default tmux status row before overriding it',
    );
}
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::Ticket::apply_ticket_status(
                session   => 'DD-797',
                dashboard => '/tmp/custom-dashboard',
                tmux      => sub {
                    my (%call) = @_;
                    return { exit_code => 0, stdout => '', stderr => '' } if $call{args}[0] eq 'show-options' && $call{args}[2] eq '@dd_ticket_status_default';
                    return { exit_code => 0, stdout => "#[default-status]\n", stderr => '' } if $call{args}[0] eq 'show-options' && $call{args}[2] eq 'status-format[0]';
                    return { exit_code => 7, stdout => "save-out\n", stderr => "save-err\n" } if $call{args}[0] eq 'set-option' && $call{args}[2] eq '@dd_ticket_status_default';
                    return { exit_code => 0, stdout => '', stderr => '' };
                },
            );
        }
    ),
    qr/Unable to record tmux ticket default status for 'DD-797': save-err\nsave-out\n/,
    'apply_ticket_status surfaces failures while recording the default tmux status row',
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
like(
    _dies( sub { Developer::Dashboard::CLI::Ticket::tmux_command( args => 'attach-session -t DD-800' ) } ),
    qr/tmux args must be an array reference/,
    'tmux_command rejects non-array tmux argv payloads',
);

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
my $make_log = File::Spec->catfile( $fake_bin, 'make.log' );
my $npx_log = File::Spec->catfile( $fake_bin, 'npx.log' );
my $python_log = File::Spec->catfile( $fake_bin, 'python.log' );
my $sudo_log = File::Spec->catfile( $fake_bin, 'sudo.log' );
my $dashboard_log = File::Spec->catfile( $fake_bin, 'dashboard.log' );
my $docker_log = File::Spec->catfile( $fake_bin, 'docker.log' );
my $dependency_log = File::Spec->catfile( $fake_bin, 'dependency-install.log' );
_write_file(
    File::Spec->catfile( $fake_bin, 'cpanm' ),
    <<"SH",
#!/bin/sh
printf 'PERL_MM_USE_DEFAULT=%s NONINTERACTIVE_TESTING=%s PERL_CANARY_STABILITY_NOPROMPT=%s\\n' "\${PERL_MM_USE_DEFAULT:-}" "\${NONINTERACTIVE_TESTING:-}" "\${PERL_CANARY_STABILITY_NOPROMPT:-}" >> "$cpanm_log"
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
    File::Spec->catfile( $fake_bin, 'python' ),
    <<"SH",
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> "$python_log"
printf 'PYTHON:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_PYTHON_FAIL" = "1" ]; then
  exit 1
fi
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'make' ),
    <<"SH",
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> "$make_log"
printf 'MAKE:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_MAKE_FAIL" = "\${1:-default}" ]; then
  exit 1
fi
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
    File::Spec->catfile( $fake_bin, 'docker' ),
    <<"SH",
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> "$docker_log"
printf 'DOCKER:%s\\n' "\$*" >> "$dependency_log"
if [ "\$DD_TEST_DOCKER_FAIL" = "1" ]; then
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
        { id => 'install_wingetfile',   label => 'Install wingetfile dependencies' },
        { id => 'install_brewfile',     label => 'Install brewfile dependencies' },
        { id => 'install_package_json', label => 'Install package.json dependencies' },
        { id => 'install_requirements_txt', label => 'Install requirements.txt dependencies' },
        { id => 'install_cpanfile',     label => 'Install cpanfile dependencies' },
        { id => 'install_cpanfile_local', label => 'Install cpanfile.local dependencies' },
        { id => 'install_makefile',     label => 'Install Makefile dependencies' },
        { id => 'install_dockerfile', label => 'Install dockerfile dependencies' },
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
    my $label_requirements = File::Spec->catfile( $label_skill, 'requirements.txt' );
    my $label_makefile = File::Spec->catfile( $label_skill, 'Makefile' );
    make_path($label_skill);
    _write_file( $label_package_json, qq|{"name":"label-skill","version":"1.0.0"}\n| );
    _write_file( $label_requirements, "requests==2.32.3\n" );
    _write_file( $label_makefile, "all:\n\t\@:\n" );
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
    is(
        $manager->_dependency_progress_label(
            'install_package_json',
            $label_skill,
            result => {
                error => "Failed to install skill Node dependencies for $label_skill: npm blew up\nwith details",
            },
        ),
        "Install package.json dependencies from $label_package_json (error: Failed to install skill Node dependencies for $label_skill: npm blew up with details)",
        '_dependency_progress_label carries one compact failure reason into the visible progress board',
    );
    is(
        $manager->_dependency_progress_label( 'install_requirements_txt', $label_skill ),
        "Install requirements.txt dependencies from $label_requirements",
        '_dependency_progress_label surfaces the detected requirements.txt path while pip work is in progress',
    );
    is(
        $manager->_dependency_progress_label(
            'install_requirements_txt',
            $label_skill,
            result => { success => 1, skipped => 1 },
        ),
        'Install requirements.txt dependencies (skipped: requirements.txt not present)',
        '_dependency_progress_label makes skipped requirements.txt work explicit in the progress board',
    );
    is(
        $manager->_dependency_progress_label(
            'install_requirements_txt',
            $label_skill,
            result => {
                error => "Failed to install skill Python dependencies for $label_skill: pip blew up\nwith details",
            },
        ),
        "Install requirements.txt dependencies from $label_requirements (error: Failed to install skill Python dependencies for $label_skill: pip blew up with details)",
        '_dependency_progress_label carries requirements.txt failures into the visible progress board',
    );
    is(
        $manager->_dependency_progress_label( 'install_makefile', $label_skill ),
        "Install Makefile dependencies from $label_makefile",
        '_dependency_progress_label surfaces the detected Makefile path while make work is in progress',
    );
    {
        local $ENV{DD_TEST_OS} = 'linux';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        local $ENV{DD_TEST_ALPINE} = 0;
        local $ENV{DD_TEST_FEDORA} = 0;
        _write_file( File::Spec->catfile( $label_skill, 'aptfile' ), "jq\n" );
        _write_file( File::Spec->catfile( $label_skill, 'brewfile' ), "jq\n" );
        is_deeply(
            $manager->dependency_progress_tasks_for_skill_path($label_skill),
            [
                { id => 'install_aptfile', label => 'Install aptfile dependencies' },
                { id => 'install_package_json', label => 'Install package.json dependencies' },
                { id => 'install_requirements_txt', label => 'Install requirements.txt dependencies' },
                { id => 'install_makefile', label => 'Install Makefile dependencies' },
            ],
            'dependency_progress_tasks_for_skill_path keeps only present cross-platform manifests plus the host-relevant package manager task',
        );
    }
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
    my $windows_rsync_bin = File::Spec->catdir( $ENV{HOME}, 'fake-windows-rsync-bin' );
    make_path($windows_rsync_bin);
    _write_file(
        File::Spec->catfile( $windows_rsync_bin, 'rsync.exe' ),
        "fake windows rsync\n",
    );

    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    local $ENV{PATH} = $windows_rsync_bin;
    ok( $manager->_rsync_available, '_rsync_available resolves rsync directly on Windows without requiring sh on PATH' );

    local $ENV{PATH} = File::Spec->catdir( $ENV{HOME}, 'no-windows-rsync-bin' );
    ok( !$manager->_rsync_available, '_rsync_available returns false on Windows when rsync itself is absent' );
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
    with_makefile => 1,
    with_dockerfile => 1,
    with_package_json => 1,
    with_requirements_txt => 1,
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
    [ map { (/^(DDFILE_LOCAL|DDFILE|DOCKER|APT|BREW|NPM|PYTHON|CPANM|MAKE):/)[0] } @dependency_steps[-12 .. -1] ],
    [ 'APT', 'NPM', 'PYTHON', 'CPANM', 'CPANM', 'MAKE', 'MAKE', 'MAKE', 'MAKE', 'DOCKER', 'DDFILE', 'DDFILE_LOCAL' ],
    '_install_skill_dependencies follows the documented aptfile -> apkfile -> dnfile -> brewfile -> package.json -> requirements.txt -> cpanfile -> cpanfile.local -> Makefile -> dockerfile -> ddfile -> ddfile.local order on Debian-like hosts while leaving apkfile, dnfile, and brewfile inactive',
);
open my $cpanm_log_fh, '<', $cpanm_log or die "Unable to read $cpanm_log: $!";
my @cpanm_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$cpanm_log_fh>;
close $cpanm_log_fh;
is( $cpanm_steps[-4], 'PERL_MM_USE_DEFAULT=1 NONINTERACTIVE_TESTING=1 PERL_CANARY_STABILITY_NOPROMPT=1', '_install_skill_dependencies forces non-interactive CPAN environment defaults for cpanfile installs' );
like( $cpanm_steps[-3], qr/^--notest -L \Q$ENV{HOME}\/skills-home\/perl5\E --cpanfile .*\/cpanfile --installdeps \.$/, '_install_skill_dependencies installs cpanfile dependencies into HOME perl5 with cpanm --notest from the skill root itself' );
is( $cpanm_steps[-2], 'PERL_MM_USE_DEFAULT=1 NONINTERACTIVE_TESTING=1 PERL_CANARY_STABILITY_NOPROMPT=1', '_install_skill_dependencies forces non-interactive CPAN environment defaults for cpanfile.local installs' );
like( $cpanm_steps[-1], qr/^--notest -L .*\/perl5 --cpanfile .*\/cpanfile\.local --installdeps \.$/, '_install_skill_dependencies installs cpanfile.local dependencies into the skill-local perl5 root with cpanm --notest from the skill root itself' );
open my $npm_log_fh, '<', $npx_log or die "Unable to read $npx_log: $!";
my @npm_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$npm_log_fh>;
close $npm_log_fh;
like(
    $npm_steps[-1],
    qr/^--yes npm install dep-skill-runtime\@\^1\.2\.3 dep-skill-dev\@\^4\.5\.6\|cwd=\Q$ENV{HOME}\E\/skills-home\/\.developer-dashboard\/cache\/node-package-installs\/npm-install-/,
    '_install_skill_dependencies stages package.json work under the dashboard runtime cache through npx instead of using bare HOME as the npm project root',
);
open my $python_log_fh, '<', $python_log or die "Unable to read $python_log: $!";
my @python_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$python_log_fh>;
close $python_log_fh;
is(
    $python_steps[-1],
    "-m pip install --user --requirement $dep_skill_root/requirements.txt|cwd=$dep_skill_root",
    '_install_skill_dependencies installs requirements.txt through python -m pip install --user from the installed skill root',
);
open my $make_log_fh, '<', $make_log or die "Unable to read $make_log: $!";
my @make_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$make_log_fh>;
close $make_log_fh;
is_deeply(
    [ @make_steps[ -4 .. -1 ] ],
    [
        "|cwd=$dep_skill_root",
        "test|cwd=$dep_skill_root",
        "install|cwd=$dep_skill_root",
        "clean|cwd=$dep_skill_root",
    ],
    '_install_skill_dependencies runs the default Makefile command chain before ddfile processing',
);
open my $docker_log_fh, '<', $docker_log or die "Unable to read $docker_log: $!";
my @docker_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$docker_log_fh>;
close $docker_log_fh;
like(
    $docker_steps[-1],
    qr/^build -t dep-skill -f \Q$dep_skill_root\E\/dockerfile \Q$dep_skill_root\E\|cwd=\Q$dep_skill_root\E$/,
    '_install_skill_dependencies builds dockerfile-based skill images from the installed skill root',
);
{
    unlink $make_log;
    my $skip_test_manager = Developer::Dashboard::SkillManager->new(
        paths      => $skill_paths,
        skip_tests => 1,
    );
    my $skip_make = $skip_test_manager->_install_skill_makefile($dep_skill_root);
    ok( !$skip_make->{error}, '_install_skill_makefile succeeds when --notest-style skips are requested' )
      or diag $skip_make->{error};
    open my $skip_make_fh, '<', $make_log or die "Unable to read $make_log after skip-test install: $!";
    my @skip_make_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$skip_make_fh>;
    close $skip_make_fh;
    is_deeply(
        \@skip_make_steps,
        [
            "|cwd=$dep_skill_root",
            "install|cwd=$dep_skill_root",
            "clean|cwd=$dep_skill_root",
        ],
        '_install_skill_makefile skips the test target when the manager is configured for --notest installs',
    );
}
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
    local $ENV{PATH} = $fake_bin;
    my $portable_copy_result = $manager->_install_skill_package_json($home_manifest_skill);
    ok( !$portable_copy_result->{error}, '_install_skill_package_json merges staged Node dependencies without requiring a Unix cp command on PATH' )
      or diag $portable_copy_result->{error};
    ok( -d File::Spec->catdir( $ENV{HOME}, 'skills-home', 'node_modules', 'left-pad' ), '_install_skill_package_json still merges the staged node_modules tree when PATH omits cp' );
}
{
    my $runner_home = tempdir( CLEANUP => 1 );
    my $runner_paths = Developer::Dashboard::PathRegistry->new( home => $runner_home );
    my $runner = Developer::Dashboard::CollectorRunner->new(
        collectors => Developer::Dashboard::Collector->new( paths => $runner_paths ),
        files      => Developer::Dashboard::FileRegistry->new( paths => $runner_paths ),
        paths      => $runner_paths,
    );
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    local *POSIX::setsid = sub { die "setsid should not run on Windows\n" };
    ok( $runner->_detach_process_session, '_detach_process_session skips POSIX::setsid on Windows collector loops' );
}
is(
    $manager->_remove_tree_error_text(
        [
            { 'C:\\Users\\Docker\\.developer-dashboard\\skills\\browser' => 'Permission denied' },
            'fallback cleanup message',
        ]
    ),
    'C:\\Users\\Docker\\.developer-dashboard\\skills\\browser: Permission denied, fallback cleanup message',
    '_remove_tree_error_text renders structured remove_tree errors without Perl hash stringification',
);
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
is( $metadata->{has_makefile}, 1, 'skill metadata records Makefile presence' );
is( $metadata->{has_dockerfile}, 1, 'skill metadata records dockerfile presence' );
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
ok( $usage->{config}{has_makefile}, 'usage reports Makefile presence in the skill config metadata' );
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
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            die "synthetic npm streaming failure\n";
        };
        $error = eval { $manager->_install_skill_package_json($capture_fail_repo); 1 } ? '' : $@;
    }
    like(
        $error,
        qr/synthetic npm streaming failure/,
        '_install_skill_package_json surfaces streaming failures from the staged npm install workspace',
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
                manifest       => 'ddfile',
                source         => "file://$global_repo",
                repo_name      => 'manifest-global-skill',
                path           => File::Spec->catdir( $ENV{HOME}, 'skills-home', '.developer-dashboard', 'skills', 'manifest-global-skill' ),
                version_before => undef,
                version_after  => undef,
                status         => 'installed',
                changed        => 1,
            },
            {
                manifest       => 'ddfile.local',
                source         => "file://$local_repo",
                repo_name      => 'manifest-local-skill',
                path           => File::Spec->catdir( $manifest_root, 'skills', 'manifest-local-skill' ),
                version_before => undef,
                version_after  => undef,
                status         => 'installed',
                changed        => 1,
            },
        ],
        'install_from_ddfiles treats first-time manifest installs without VERSION metadata as installed and still processes ddfile before ddfile.local',
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
    my $registry_home = tempdir( CLEANUP => 1 );
    my $registry_paths = Developer::Dashboard::PathRegistry->new( home => $registry_home );
    my $registry_manager = Developer::Dashboard::SkillManager->new( paths => $registry_paths );
    my $registry_repo = _create_skill_repo( $test_repos, 'registered-root-skill', with_cpanfile => 0 );
    my $registry_source = "file://$registry_repo";
    my $root_ddfile = File::Spec->catfile( $registry_paths->home_runtime_root, 'ddfile' );
    my $home_gitignore = File::Spec->catfile( $registry_paths->home_runtime_root, '.gitignore' );
    $registry_paths->ensure_dir( $registry_paths->home_runtime_root );
    _write_file( $home_gitignore, "# dashboard runtime ignores\n" );

    my $first_registry_install = $registry_manager->install($registry_source);
    ok( !$first_registry_install->{error}, 'explicit skill install succeeds before registering the root ddfile source' )
      or diag $first_registry_install->{error};
    is( _read_file($root_ddfile), "$registry_source\n", 'explicit skill install appends the source to the home root ddfile' );
    is( _read_file($home_gitignore), "# dashboard runtime ignores\nskills/registered-root-skill/\n", 'explicit skill install appends the installed skill path to an existing home .gitignore' );
    is( $first_registry_install->{registered_ddfile}, $root_ddfile, 'install result reports the root ddfile registry path' );
    ok( $first_registry_install->{registered_ddfile_entry}, 'install result reports a newly registered root ddfile entry' );
    is( $first_registry_install->{registered_gitignore}, $home_gitignore, 'install result reports the home .gitignore registry path when present' );
    ok( $first_registry_install->{registered_gitignore_entry}, 'install result reports a newly registered home .gitignore entry' );

    my $second_registry_install = $registry_manager->install($registry_source);
    ok( !$second_registry_install->{error}, 'repeat explicit skill install succeeds as an update' )
      or diag $second_registry_install->{error};
    is( _read_file($root_ddfile), "$registry_source\n", 'repeat explicit skill install does not duplicate the root ddfile source' );
    is( _read_file($home_gitignore), "# dashboard runtime ignores\nskills/registered-root-skill/\n", 'repeat explicit skill install does not duplicate the home .gitignore skill entry' );
    ok( !$second_registry_install->{registered_ddfile_entry}, 'repeat install reports that the root ddfile entry already existed' );
    ok( !$second_registry_install->{registered_gitignore_entry}, 'repeat install reports that the home .gitignore entry already existed' );

    my $internal_repo = _create_skill_repo( $test_repos, 'internal-dependency-skill', with_cpanfile => 0 );
    {
        local $ENV{DEVELOPER_DASHBOARD_SKIP_SKILL_REGISTRY} = 1;
        my $internal_install = $registry_manager->install("file://$internal_repo");
        ok( !$internal_install->{error}, 'internal dependency install can skip root ddfile registration' )
          or diag $internal_install->{error};
    }
    is( _read_file($root_ddfile), "$registry_source\n", 'internal dependency install does not pollute the home root ddfile registry' );
    like( _read_file($home_gitignore), qr/skills\/internal-dependency-skill\//, 'internal dependency install still keeps installed skill directories ignored when home .gitignore exists' );

    _write_file( File::Spec->catfile( $registry_repo, 'cli', 'run-test' ), "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{registered-refresh\\n};\n", 0755 );
    {
        my $cwd = getcwd();
        chdir $registry_repo or die "Unable to chdir to $registry_repo: $!";
        _run_or_die(qw(git add .));
        _run_or_die( 'git', 'commit', '-m', 'Refresh registered root skill' );
        chdir $cwd or die "Unable to chdir back to $cwd: $!";
    }
    my $registered_update = $registry_manager->install_registered_skills;
    ok( !$registered_update->{error}, 'install_registered_skills refreshes every source listed in the home root ddfile' )
      or diag $registered_update->{error};
    is_deeply(
        $registered_update->{operations},
        [
            {
                manifest       => 'ddfile',
                source         => $registry_source,
                repo_name      => 'registered-root-skill',
                path           => File::Spec->catdir( $registry_paths->home_runtime_root, 'skills', 'registered-root-skill' ),
                version_before => undef,
                version_after  => undef,
                status         => 'unknown',
                changed        => 0,
            },
        ],
        'install_registered_skills keeps existing root-ddfile refreshes without VERSION metadata classified as unknown',
    );
    my $registry_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $registry_paths );
    like(
        $registry_dispatcher->dispatch( 'registered-root-skill', 'run-test' )->{stdout},
        qr/registered-refresh/,
        'install_registered_skills updates the installed skill content from the registered root ddfile source',
    );
    is_deeply(
        [ $registry_manager->registered_skill_sources ],
        [$registry_source],
        'registered_skill_sources reads the home root ddfile in install order',
    );
    is_deeply(
        Developer::Dashboard::SkillManager->install_progress_tasks_for_sources($registry_source),
        [ { id => 'install_source_0', label => "Install/update $registry_source" } ],
        'install_progress_tasks_for_sources builds one visible source-level progress task',
    );
}
{
    my $empty_registry_home = tempdir( CLEANUP => 1 );
    my $empty_registry_paths = Developer::Dashboard::PathRegistry->new( home => $empty_registry_home );
    my $empty_registry_manager = Developer::Dashboard::SkillManager->new( paths => $empty_registry_paths );
    my $empty_ddfile = File::Spec->catfile( $empty_registry_paths->home_runtime_root, 'ddfile' );
    is_deeply(
        $empty_registry_manager->install_registered_skills,
        { error => "No root ddfile found under " . $empty_registry_paths->home_runtime_root . '; install a skill first or pass a skill source' },
        'install_registered_skills reports a clear error before any root ddfile exists',
    );
    _write_file( $empty_ddfile, "# empty registry\n\n" );
    is_deeply(
        $empty_registry_manager->install_registered_skills,
        { error => "Root ddfile $empty_ddfile does not list any skills to install" },
        'install_registered_skills reports a clear error when the root ddfile has no installable entries',
    );
}
{
    my $newline_registry_home = tempdir( CLEANUP => 1 );
    my $newline_registry_paths = Developer::Dashboard::PathRegistry->new( home => $newline_registry_home );
    my $newline_registry_manager = Developer::Dashboard::SkillManager->new( paths => $newline_registry_paths );
    my $newline_repo = _create_skill_repo( $test_repos, 'newline-registry-skill', with_cpanfile => 0 );
    my $newline_ddfile = File::Spec->catfile( $newline_registry_paths->home_runtime_root, 'ddfile' );
    _write_file( $newline_ddfile, 'existing-skill-without-newline' );

    my $newline_install = $newline_registry_manager->install("file://$newline_repo");
    ok( !$newline_install->{error}, 'explicit install appends to an existing root ddfile without a trailing newline' )
      or diag $newline_install->{error};
    is(
        _read_file($newline_ddfile),
        "existing-skill-without-newline\nfile://$newline_repo\n",
        'root ddfile registration repairs a missing trailing newline before appending a new source',
    );
}
{
    my $newline_gitignore_home = tempdir( CLEANUP => 1 );
    my $newline_gitignore_paths = Developer::Dashboard::PathRegistry->new( home => $newline_gitignore_home );
    my $newline_gitignore_manager = Developer::Dashboard::SkillManager->new( paths => $newline_gitignore_paths );
    my $newline_gitignore_repo = _create_skill_repo( $test_repos, 'newline-gitignore-skill', with_cpanfile => 0 );
    my $newline_gitignore = File::Spec->catfile( $newline_gitignore_paths->home_runtime_root, '.gitignore' );
    _write_file( $newline_gitignore, '# dashboard runtime ignores' );

    my $newline_gitignore_install = $newline_gitignore_manager->install("file://$newline_gitignore_repo");
    ok( !$newline_gitignore_install->{error}, 'explicit install appends to an existing home .gitignore without a trailing newline' )
      or diag $newline_gitignore_install->{error};
    is(
        _read_file($newline_gitignore),
        "# dashboard runtime ignores\nskills/newline-gitignore-skill/\n",
        'home .gitignore registration repairs a missing trailing newline before appending a new skill entry',
    );
}
{
    my $multi_registry_home = tempdir( CLEANUP => 1 );
    my $multi_registry_paths = Developer::Dashboard::PathRegistry->new( home => $multi_registry_home );
    my $multi_registry_manager = Developer::Dashboard::SkillManager->new( paths => $multi_registry_paths );
    my $first_multi_repo = _create_skill_repo( $test_repos, 'multi-root-one', with_cpanfile => 0 );
    my $second_multi_repo = _create_skill_repo( $test_repos, 'multi-root-two', with_cpanfile => 0 );
    my @multi_sources = ( "file://$first_multi_repo", "file://$second_multi_repo" );
    my $multi_root_ddfile = File::Spec->catfile( $multi_registry_paths->home_runtime_root, 'ddfile' );
    my $multi_home_gitignore = File::Spec->catfile( $multi_registry_paths->home_runtime_root, '.gitiignore' );
    $multi_registry_paths->ensure_dir( $multi_registry_paths->home_runtime_root );
    _write_file( $multi_home_gitignore, "# typo-compatible ignore file\n" );

    my $multi_install = $multi_registry_manager->install_many(@multi_sources);
    ok( !$multi_install->{error}, 'install_many installs multiple explicit skill sources in one call' )
      or diag $multi_install->{error};
    is_deeply( $multi_install->{sources}, \@multi_sources, 'install_many reports sources in command-line order' );
    is_deeply(
        [ map { $_->{repo_name} } @{ $multi_install->{results} } ],
        [ 'multi-root-one', 'multi-root-two' ],
        'install_many returns each individual install result',
    );
    is( _read_file($multi_root_ddfile), join( "\n", @multi_sources ) . "\n", 'install_many registers each source once in the home root ddfile' );
    is(
        _read_file($multi_home_gitignore),
        "# typo-compatible ignore file\nskills/multi-root-one/\nskills/multi-root-two/\n",
        'install_many registers each installed skill path once in an existing typo-compatible home .gitiignore',
    );

    my $repeat_multi_install = $multi_registry_manager->install_many(@multi_sources);
    ok( !$repeat_multi_install->{error}, 'install_many can refresh multiple existing sources without errors' )
      or diag $repeat_multi_install->{error};
    is( _read_file($multi_root_ddfile), join( "\n", @multi_sources ) . "\n", 'install_many does not duplicate root ddfile entries on refresh' );
}
{
    my $multi_fail_home = tempdir( CLEANUP => 1 );
    my $multi_fail_paths = Developer::Dashboard::PathRegistry->new( home => $multi_fail_home );
    my @multi_fail_events;
    my $multi_fail_manager = Developer::Dashboard::SkillManager->new(
        paths    => $multi_fail_paths,
        progress => sub {
            my ($event) = @_;
            push @multi_fail_events, { %{$event} };
        },
    );
    my $good_repo = _create_skill_repo( $test_repos, 'multi-fail-good', with_cpanfile => 0 );
    my $bad_local_source = File::Spec->catdir( $test_repos, 'multi-fail-bad' );
    make_path($bad_local_source);

    my $multi_fail = $multi_fail_manager->install_many( "file://$good_repo", $bad_local_source );
    ok( $multi_fail->{error}, 'install_many returns an explicit error when one later source fails' );
    like(
        $multi_fail->{error},
        qr/^Failed to install skill source \Q$bad_local_source\E: Local skill source '\Q$bad_local_source\E' is missing a \.git directory/,
        'install_many error text names the failing source and underlying cause',
    );
    is( scalar @{ $multi_fail->{results} || [] }, 2, 'install_many returns the completed per-source results before aborting' );
    ok( @multi_fail_events >= 2, 'install_many emits visible progress events while processing multiple sources' );
    is( $multi_fail_events[0]{status}, 'running', 'install_many marks the first source as running before work begins' );
    is( $multi_fail_events[-1]{status}, 'failed', 'install_many marks the broken later source as failed before aborting' );
}
{
    my $cli_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $cli_home;
    my $cli_paths = Developer::Dashboard::PathRegistry->new( home => $cli_home );
    my $cli_repo = _create_skill_repo( $test_repos, 'cli-root-ddfile-skill', with_cpanfile => 0 );
    _write_file( File::Spec->catfile( $cli_paths->home_runtime_root, 'ddfile' ), "file://$cli_repo\n" );

    require Developer::Dashboard::CLI::Skills;
    my $cli_code;
    my ( $cli_stdout, $cli_stderr, $cli_exit ) = capture {
        $cli_code = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'install', '-o', 'json' ],
        );
    };
    is( $cli_exit, 0, 'bare dashboard skills install does not die when a root ddfile exists' );
    is( $cli_code, 0, 'bare dashboard skills install returns success after consuming the root ddfile' );
    is( $cli_stderr, '', 'bare dashboard skills install does not print usage errors when a root ddfile exists' );
    is_deeply(
        json_decode($cli_stdout)->{operations},
        [
            {
                manifest       => 'ddfile',
                source         => "file://$cli_repo",
                repo_name      => 'cli-root-ddfile-skill',
                path           => File::Spec->catdir( $cli_paths->home_runtime_root, 'skills', 'cli-root-ddfile-skill' ),
                version_before => undef,
                version_after  => undef,
                status         => 'installed',
                changed        => 1,
            },
        ],
        'bare dashboard skills install reports a first root-ddfile install without VERSION metadata as installed',
    );
}
{
    my $multi_cli_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $multi_cli_home;
    my $multi_cli_paths = Developer::Dashboard::PathRegistry->new( home => $multi_cli_home );
    my $first_cli_repo = _create_skill_repo( $test_repos, 'cli-multi-root-one', with_cpanfile => 0 );
    my $second_cli_repo = _create_skill_repo( $test_repos, 'cli-multi-root-two', with_cpanfile => 0 );
    my @cli_sources = ( "file://$first_cli_repo", "file://$second_cli_repo" );

    require Developer::Dashboard::CLI::Skills;
    my $multi_cli_code;
    my ( $multi_cli_stdout, $multi_cli_stderr, $multi_cli_exit ) = capture {
        $multi_cli_code = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skills',
            args    => [ 'install', '-o', 'json', @cli_sources ],
        );
    };
    is( $multi_cli_exit, 0, 'dashboard skills install with multiple sources does not die' );
    is( $multi_cli_code, 0, 'dashboard skills install with multiple sources returns success' );
    is( $multi_cli_stderr, '', 'dashboard skills install with multiple sources does not print usage errors' );
    is_deeply( json_decode($multi_cli_stdout)->{sources}, \@cli_sources, 'dashboard skills install accepts multiple explicit sources in order' );
    is(
        _read_file( File::Spec->catfile( $multi_cli_paths->home_runtime_root, 'ddfile' ) ),
        join( "\n", @cli_sources ) . "\n",
        'dashboard skills install registers every explicit source from one multi-source command',
    );

    my $alias_cli_code;
    my ( $alias_cli_stdout, $alias_cli_stderr, $alias_cli_exit ) = capture {
        $alias_cli_code = Developer::Dashboard::CLI::Skills::run_skills_command(
            command => 'skill',
            args    => [ 'list', '-o', 'json' ],
        );
    };
    is( $alias_cli_exit, 0, 'dashboard skill alias command runtime does not die' );
    is( $alias_cli_code, 0, 'dashboard skill alias command runtime returns success' );
    is( $alias_cli_stderr, '', 'dashboard skill alias command runtime does not emit errors' );
    is( scalar @{ json_decode($alias_cli_stdout)->{skills} }, 2, 'dashboard skill alias reaches the skills management command family' );
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
    my $uninstall_repo = _create_skill_repo( $test_repos, 'registered-uninstall-skill', with_cpanfile => 0 );
    my $keep_repo      = _create_skill_repo( $test_repos, 'registered-keep-skill',      with_cpanfile => 0 );
    my $root_ddfile    = File::Spec->catfile( $skill_paths->home_runtime_root, 'ddfile' );
    $skill_paths->ensure_dir( $skill_paths->home_runtime_root );

    my $install_source = 'file://' . $uninstall_repo;
    my $keep_source    = 'file://' . $keep_repo;
    _write_file(
        $root_ddfile,
        join(
            "\n",
            '# dashboard skills',
            $install_source,
            $keep_source,
            'owner/registered-uninstall-skill',
            q{},
        ),
    );

    ok( !$manager->install($install_source)->{error}, 'registered-uninstall-skill installs cleanly before uninstalling it' );
    ok( !$manager->uninstall('registered-uninstall-skill')->{error}, 'uninstall succeeds for a skill registered in the root ddfile' );
    is(
        _read_file($root_ddfile),
        join( "\n", '# dashboard skills', $keep_source, q{} ),
        'uninstall removes matching root ddfile entries while preserving unrelated sources and comments',
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
    if ( $args{with_makefile} ) {
    if ( $args{with_dockerfile} ) {
        _write_file(
            'dockerfile',
            "FROM alpine:latest\nRUN echo 'test dockerfile'\n",
        );
    }
        _write_file(
            'Makefile',
            ".PHONY: all test install clean\nall:\n\t\@:\ntest:\n\t\@:\ninstall:\n\t\@:\nclean:\n\t\@:\n",
        );
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
    if ( $args{with_requirements_txt} ) {
        _write_file( 'requirements.txt', "requests==2.32.3\nrich==13.9.4\n" );
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

# _read_file($path)
# Reads a complete text file for focused fixture assertions.
# Input: file path string.
# Output: file content string.
sub _read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
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
        title   => 'dashboard skills install progress',
        tasks   => [
            { id => 'fetch_source',   label => 'Fetch skill source' },
            { id => 'prepare_layout', label => 'Prepare skill layout' },
        ],
        stream  => $fh,
        dynamic => 0,
    );
    $progress->update(
        {
            add_tasks => [
                { id => 'install_package_json', label => 'Install package.json dependencies' },
                { id => 'install_cpanfile',     label => 'Install cpanfile dependencies' },
            ],
        }
    );
    like( $output, qr/\[ \] Install package\.json dependencies/, 'CLI::Progress can append newly discovered tasks after the board is created' );
    like( $output, qr/\[ \] Install cpanfile dependencies/, 'CLI::Progress keeps appended tasks pending until work begins' );
}

{
    require Developer::Dashboard::CLI::Progress;
    my $output = '';
    open my $fh, '>', \$output or die "Unable to open scalar handle for progress output: $!";
    my $progress = Developer::Dashboard::CLI::Progress->new(
        title   => 'dashboard skills install progress',
        max_detail_lines => 10,
        tasks   => [
            { id => 'install_brewfile',     label => 'Install brewfile dependencies' },
            { id => 'install_package_json', label => 'Install package.json dependencies' },
            { id => 'install_requirements_txt', label => 'Install requirements.txt dependencies' },
        ],
        stream  => $fh,
        dynamic => 1,
    );
    $progress->update(
        {
            task_id      => 'install_brewfile',
            status       => 'running',
            label        => 'Install brewfile dependencies from /tmp/skill/brewfile',
            detail_lines => [ map { sprintf 'brew line %02d', $_ } 1 .. 12 ],
        }
    );
    like(
        $output,
        qr/-> Install brewfile dependencies from \/tmp\/skill\/brewfile\n(?:   .*?\n){10}\[ \] Install package\.json dependencies\n\[ \] Install requirements\.txt dependencies/s,
        'CLI::Progress renders a ten-line rolling detail window beneath the active task without displacing later epic tasks',
    );
    unlike( $output, qr/brew line 01/, 'CLI::Progress drops detail lines older than the rolling ten-line window' );
    like( $output, qr/brew line 12/, 'CLI::Progress keeps the newest detail lines in the rolling window' );
    $progress->update(
        {
            task_id => 'install_brewfile',
            status  => 'done',
            label   => 'Install brewfile dependencies from /tmp/skill/brewfile',
        }
    );
    my @boards = $output =~ /(dashboard skills install progress.*?)(?=dashboard skills install progress|\z)/sg;
    my $last_board = $boards[-1] || '';
    unlike( $last_board, qr/brew line 12/, 'CLI::Progress collapses active detail lines once the task completes successfully' );
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
    $progress->update(
        {
            task_id      => 'stop_web',
            status       => 'running',
            detail_lines => ['waiting for listener'],
        }
    );
    like( $output, qr/\x1b\[34m->\x1b\[0m Stop dashboard web service/, 'CLI::Progress colors the running marker blue when color output is enabled' );
    like( $output, qr/   \x1b\[34mwaiting for listener\x1b\[0m/, 'CLI::Progress colors running detail lines blue when color output is enabled' );
    $progress->update( { task_id => 'stop_web', status => 'done' } );
    like( $output, qr/\x1b\[32m\[OK\]\x1b\[0m Stop dashboard web service/, 'CLI::Progress colors the done marker green when color output is enabled' );
    $progress->update(
        {
            task_id      => 'stop_web',
            status       => 'failed',
            detail_lines => ['listener never stopped'],
        }
    );
    like( $output, qr/\x1b\[31m\[X\]\x1b\[0m Stop dashboard web service/, 'CLI::Progress colors the failed marker red when color output is enabled' );
    like( $output, qr/   \x1b\[31mlistener never stopped\x1b\[0m/, 'CLI::Progress colors failed detail lines red when color output is enabled' );
}

{
    require Developer::Dashboard::CLI::Progress;

    my $invalid_array_error;
    eval { Developer::Dashboard::CLI::Progress->new( tasks => {} ); 1 } or $invalid_array_error = $@;
    like( $invalid_array_error, qr/Progress tasks must be an array reference/, 'CLI::Progress rejects non-array task lists' );

    my $missing_id_error;
    eval { Developer::Dashboard::CLI::Progress->new( tasks => [ {} ] ); 1 } or $missing_id_error = $@;
    like( $missing_id_error, qr/Progress task missing id/, 'CLI::Progress rejects task entries without ids' );

    my $output = '';
    open my $fh, '>', \$output or die "Unable to open scalar handle for progress output: $!";
    my $progress = Developer::Dashboard::CLI::Progress->new(
        title   => 'dashboard progress edge coverage',
        tasks   => [ { id => 'only_task', label => 'Only task label' } ],
        stream  => $fh,
        dynamic => 0,
        color   => 0,
    );

    is( $progress->_detail_line_limit, undef, 'CLI::Progress leaves the detail-line limit undefined when no cap is configured' );
    is( $progress->_status_prefix('pending'), '[ ]', 'CLI::Progress uses the pending prefix for unknown statuses' );
    is( $progress->_colorize( '[ ]', 'pending' ), '[ ]', 'CLI::Progress leaves pending markers uncolored' );
    is( $progress->_colorize_detail( 'detail line', 'pending' ), 'detail line', 'CLI::Progress leaves pending detail text uncolored' );
    like( $progress->render_text, qr/\[ \] Only task label/, 'CLI::Progress render_text includes the pending task board text' );

    my $callback = $progress->callback;
    ok( ref($callback) eq 'CODE', 'CLI::Progress callback returns a coderef' );
    ok( $callback->( { task_id => 'only_task', status => 'running', label => 'Only task running' } ), 'CLI::Progress callback forwards runtime events to update' );
    like( $output, qr/-> Only task running/, 'CLI::Progress callback updates the rendered board' );

    ok( $progress->add_tasks(), 'CLI::Progress ignores missing appended task lists' );
    ok( $progress->add_tasks('not-an-array'), 'CLI::Progress ignores non-array appended task lists' );
    ok(
        $progress->add_tasks(
            [
                'not-a-hash',
                {},
                { id => 'only_task', label => 'Duplicate id stays ignored' },
                { id => 'second_task', label => 'Second task label' },
            ]
        ),
        'CLI::Progress ignores invalid or duplicate appended tasks while accepting valid new tasks'
    );
    like( $output, qr/\[ \] Second task label/, 'CLI::Progress appends only valid new tasks' );

    ok( $progress->update( { add_tasks => [ { id => 'third_task', label => 'Third task label' } ] } ), 'CLI::Progress accepts add_tasks-only events' );
    like( $output, qr/\[ \] Third task label/, 'CLI::Progress add_tasks-only events still render appended tasks' );

    ok(
        $progress->update(
            {
                task_id     => 'second_task',
                status      => 'running',
                label       => 'Second task running',
                detail_line => 'one appended line',
            }
        ),
        'CLI::Progress accepts one-by-one detail lines'
    );
    like( $output, qr/one appended line/, 'CLI::Progress renders appended single detail lines' );

    ok(
        $progress->update(
            {
                task_id      => 'second_task',
                status       => 'failed',
                detail_lines => 'not-an-array',
            }
        ),
        'CLI::Progress clears detail lines when detail_lines is not an array reference'
    );
    my @boards = $output =~ /(dashboard progress edge coverage.*?)(?=dashboard progress edge coverage|\z)/sg;
    my $last_board = $boards[-1] || '';
    unlike( $last_board, qr/one appended line/, 'CLI::Progress drops stale detail lines when a malformed detail_lines payload arrives' );

    my $zero_output = '';
    open my $zero_fh, '>', \$zero_output or die "Unable to open scalar handle for zero-limit progress output: $!";
    my $zero_limit_progress = Developer::Dashboard::CLI::Progress->new(
        title            => 'dashboard zero detail limit',
        tasks            => [ { id => 'zero_task', label => 'Zero task label' } ],
        stream           => $zero_fh,
        dynamic          => 0,
        max_detail_lines => 0,
    );
    is( $zero_limit_progress->_detail_line_limit, 10, 'CLI::Progress normalizes a falsey configured detail limit back to ten lines' );
    $zero_limit_progress->update(
        {
            task_id      => 'zero_task',
            status       => 'running',
            detail_lines => [ map { sprintf 'line %02d', $_ } 1 .. 12 ],
        }
    );
    unlike( $zero_output, qr/line 01/, 'CLI::Progress trims older lines when a falsey configured detail limit falls back to ten lines' );
    like( $zero_output, qr/line 12/, 'CLI::Progress keeps the newest detail lines after the falsey limit fallback' );

    my $undef_output = '';
    open my $undef_fh, '>', \$undef_output or die "Unable to open scalar handle for undef-limit progress output: $!";
    my $undef_limit_progress = Developer::Dashboard::CLI::Progress->new(
        title            => 'dashboard undef detail limit',
        tasks            => [ { id => 'undef_task', label => 'Undef task label' } ],
        stream           => $undef_fh,
        dynamic          => 0,
        max_detail_lines => undef,
    );
    is( $undef_limit_progress->_detail_line_limit, undef, 'CLI::Progress preserves an explicit undef detail-line limit as unlimited' );
    $undef_limit_progress->update(
        {
            task_id      => 'undef_task',
            status       => 'running',
            detail_lines => [ map { sprintf 'line %02d', $_ } 1 .. 12 ],
        }
    );
    like( $undef_output, qr/line 01/, 'CLI::Progress keeps older detail lines when the configured limit is explicitly undef' );
    like( $undef_output, qr/line 12/, 'CLI::Progress also keeps the newest detail lines when the configured limit is explicitly undef' );

    ok( $undef_limit_progress->finish, 'CLI::Progress finish succeeds without emitting a newline when the board is static' );
}
{
    my $versionless_skill_root = tempdir( CLEANUP => 1 );
    _write_file( File::Spec->catfile( $versionless_skill_root, '.env' ), "# no version here\nNAME=demo\n" );
    is(
        $manager->_skill_env_version($versionless_skill_root),
        undef,
        '_skill_env_version returns undef when the .env file has no VERSION assignment',
    );
}
{
    my $label_root = tempdir( CLEANUP => 1 );
    is(
        $manager->_dependency_progress_label(
            'install_aptfile',
            $label_root,
            result => { error => "apt exploded\nwith details" },
        ),
        'Install aptfile dependencies (error: apt exploded with details)',
        '_dependency_progress_label still surfaces dependency errors when the manifest file is absent',
    );
}
{
    my $manifest_progress_home = tempdir( CLEANUP => 1 );
    my $manifest_progress_paths = Developer::Dashboard::PathRegistry->new( home => $manifest_progress_home );
    my @manifest_progress_events;
    my $manifest_progress_manager = Developer::Dashboard::SkillManager->new(
        paths    => $manifest_progress_paths,
        progress => sub {
            my ($event) = @_;
            push @manifest_progress_events, { %{$event} };
        },
    );
    my $manifest_dir = tempdir( CLEANUP => 1 );
    my $broken_dependency = File::Spec->catdir( $manifest_dir, 'broken-dependency' );
    make_path($broken_dependency);
    my $manifest_path = File::Spec->catfile( $manifest_dir, 'ddfile' );
    _write_file( $manifest_path, "$broken_dependency\n" );
    my @operations;

    my $manifest_failure = $manifest_progress_manager->_install_manifest_file(
        $manifest_path,
        manifest_name => 'ddfile',
        skills_root   => File::Spec->catdir( $manifest_progress_paths->home_runtime_root, 'skills' ),
        operations    => \@operations,
        progress      => 1,
    );
    ok( $manifest_failure->{error}, '_install_manifest_file returns an explicit error when one manifest source fails' );
    like(
        $manifest_failure->{error},
        qr/Local skill source '\Q$broken_dependency\E' is missing a \.git directory/,
        '_install_manifest_file forwards the underlying manifest install failure',
    );
    is_deeply( \@operations, [], '_install_manifest_file records no completed operations when the first source fails' );
    is_deeply(
        [ map { $_->{status} } @manifest_progress_events ],
        [ 'running', 'failed' ],
        '_install_manifest_file emits running and failed progress events for a broken source',
    );
}
{
    my $default_fail_skill = _create_skill_repo( $test_repos, 'make-default-fail', with_cpanfile => 0 );
    _write_file( File::Spec->catfile( $default_fail_skill, 'Makefile' ), "install:\n\t\@true\n" );
    my $default_make_failure;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            my ( undef, %args ) = @_;
            my $target = @{ $args{command} } > 1 ? join( ' ', @{ $args{command} }[ 1 .. $#{ $args{command} } ] ) : 'default';
            return {
                stdout => '',
                stderr => "synthetic make failure for $target\n",
                exit   => 1,
            };
        };
        $default_make_failure = $manager->_install_skill_makefile($default_fail_skill);
    }
    ok( $default_make_failure->{error}, '_install_skill_makefile returns an explicit error when the default make target fails' );
    like(
        $default_make_failure->{error},
        qr/^Failed to run skill Makefile target 'default' for \Q$default_fail_skill\E: /,
        '_install_skill_makefile names the failing default target in its error message',
    );
}
{
    my $install_target_make_failure;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_run_streaming_command = sub {
            my ( undef, %args ) = @_;
            my $target = @{ $args{command} } > 1 ? join( ' ', @{ $args{command} }[ 1 .. $#{ $args{command} } ] ) : 'default';
            return {
                stdout => '',
                stderr => $target eq 'install' ? "synthetic make failure for $target\n" : '',
                exit   => $target eq 'install' ? 1 : 0,
            };
        };
        $install_target_make_failure = $manager->_install_skill_makefile($dep_skill_root);
    }
    ok( $install_target_make_failure->{error}, '_install_skill_makefile returns an explicit error when a named target fails' );
    like(
        $install_target_make_failure->{error},
        qr/^Failed to run skill Makefile target 'install' for \Q$dep_skill_root\E: /,
        '_install_skill_makefile names the failing non-default target in its error message',
    );
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
