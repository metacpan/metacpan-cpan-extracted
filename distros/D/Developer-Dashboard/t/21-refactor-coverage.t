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
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::Runtime::Result ();
use Developer::Dashboard::SeedSync ();
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;

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
        qr/Usage: dashboard path <resolve\|locate\|cdr\|add\|del\|project-root\|list> \.\.\./,
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
    [ 'alpha.beta', '' ],
    '_split_query_args leaves a non-file argument as the query path',
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
    { _raw => '<root/>' },
    '_parse_xml preserves the raw XML payload',
);

local $ENV{RESULT} = '';
is_deeply( Developer::Dashboard::Runtime::Result::current(), {}, 'Runtime::Result current returns an empty hash for empty RESULT' );
local $ENV{RESULT_FILE} = '';
is( Developer::Dashboard::Runtime::Result::has(''), 0, 'Runtime::Result has rejects empty names' );
is( Developer::Dashboard::Runtime::Result::entry(''), undef, 'Runtime::Result entry rejects empty names' );
is( Developer::Dashboard::Runtime::Result::stdout('missing'), '', 'Runtime::Result stdout returns empty string for missing names' );
is( Developer::Dashboard::Runtime::Result::stderr('missing'), '', 'Runtime::Result stderr returns empty string for missing names' );
is( Developer::Dashboard::Runtime::Result::exit_code('missing'), undef, 'Runtime::Result exit_code returns undef for missing names' );
is( Developer::Dashboard::Runtime::Result::last_name(), undef, 'Runtime::Result last_name returns undef when RESULT is empty' );
is( Developer::Dashboard::Runtime::Result::last_entry(), undef, 'Runtime::Result last_entry returns undef when RESULT is empty' );
is( Developer::Dashboard::Runtime::Result::report(), '', 'Runtime::Result report returns an empty string for empty RESULT' );
is( Developer::Dashboard::Runtime::Result::clear_current(), '', 'Runtime::Result clear_current clears inline or file-backed RESULT state' );
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
my $fake_bin = tempdir( CLEANUP => 1 );
my $cpanm_log = File::Spec->catfile( $fake_bin, 'cpanm.log' );
_write_file(
    File::Spec->catfile( $fake_bin, 'cpanm' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$cpanm_log"
if [ "\$DD_TEST_CPANM_FAIL" = "1" ]; then
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
is( $manager->get_skill_path('missing'), undef, 'get_skill_path returns undef for missing skills' );
is( Developer::Dashboard::SkillManager::_extract_repo_name('bogus'), undef, '_extract_repo_name returns undef for strings without a repo path segment' );
is( Developer::Dashboard::SkillManager::_extract_repo_name('https://example.invalid/owner/repo.git'), 'repo', '_extract_repo_name strips .git from repository URLs' );
is( Developer::Dashboard::SkillManager::_extract_repo_name(''), undef, '_extract_repo_name returns undef for empty URLs' );
is_deeply( $manager->install(''), { error => 'Missing Git URL' }, 'install rejects an empty Git URL' );
like( $manager->install('https://example.invalid/not-a-repo.git')->{error}, qr/Failed to clone/, 'install reports git clone failures' );
is_deeply( $manager->update(''), { error => 'Missing repo name' }, 'update rejects an empty repo name' );
is_deeply( $manager->uninstall(''), { error => 'Missing repo name' }, 'uninstall rejects an empty repo name' );
is_deeply( $manager->update('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'update rejects unknown skills' );
is_deeply( $manager->uninstall('missing-skill'), { error => "Skill 'missing-skill' not found" }, 'uninstall rejects unknown skills' );

my $dep_repo = _create_skill_repo( $test_repos, 'dep-skill', with_cpanfile => 1 );
my $install = $manager->install( 'file://' . $dep_repo );
ok( !$install->{error}, 'skill manager installs a skill with a cpanfile' ) or diag $install->{error};
my $duplicate = $manager->install( 'file://' . $dep_repo );
like( $duplicate->{error}, qr/already installed/, 'install rejects duplicate skill installs' );
my $dep_install = $manager->_install_skill_dependencies( $manager->get_skill_path('dep-skill') );
ok( !$dep_install->{error}, '_install_skill_dependencies succeeds for a skill with a cpanfile' ) or diag $dep_install->{error};
ok( -f $cpanm_log, '_install_skill_dependencies records an isolated cpanm invocation when the skill ships a cpanfile' );
my $metadata = $manager->list->[0];
is( $metadata->{has_config}, 1, 'skill metadata records config presence' );
is( $metadata->{has_cpanfile}, 1, 'skill metadata records cpanfile presence' );
is_deeply( $metadata->{docker_services}, ['postgres'], 'skill metadata records docker service folders' );
is_deeply( $metadata->{cli_commands}, ['run-test'], 'skill metadata records cli commands only, not hook directories' );
my $manual_skill_root = $skill_paths->skill_root('layout-skill');
make_path($manual_skill_root);
ok( $manager->_prepare_skill_layout($manual_skill_root), '_prepare_skill_layout succeeds for a partially populated skill root' );
ok( -f File::Spec->catfile( $manual_skill_root, 'config', 'config.json' ), '_prepare_skill_layout creates a missing config.json file' );

my $no_dep_repo = _create_skill_repo( $test_repos, 'no-dep-skill', with_cpanfile => 0 );
ok( !$manager->install( 'file://' . $no_dep_repo )->{error}, 'skill manager installs skills without a cpanfile' );
{
    local $ENV{DD_TEST_CPANM_FAIL} = 1;
    my $fail_repo = File::Spec->catdir( $test_repos, 'fail-dep-skill' );
    make_path($fail_repo);
    make_path( File::Spec->catdir( $fail_repo, 'local' ) );
    _write_file( File::Spec->catfile( $fail_repo, 'cpanfile' ), "requires 'JSON::XS';\n" );
    like(
        $manager->_install_skill_dependencies($fail_repo)->{error},
        qr/Failed to install skill dependencies/,
        'install reports isolated dependency installation failures',
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

my $dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $skill_paths );
is_deeply( $dispatcher->dispatch( '', 'run-test' ), { error => 'Missing skill name' }, 'dispatcher rejects missing skill names' );
is_deeply( $dispatcher->dispatch( 'dep-skill', '' ), { error => 'Missing command name' }, 'dispatcher rejects missing command names' );
is_deeply(
    $dispatcher->dispatch( 'missing-skill', 'run-test' ),
    { error => "Skill 'missing-skill' not found" },
    'dispatcher rejects missing skills',
);
is_deeply( $dispatcher->execute_hooks( '', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for missing skill names' );
is_deeply( $dispatcher->execute_hooks( 'dep-skill', '' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for missing command names' );
is_deeply( $dispatcher->execute_hooks( 'missing-skill', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result for missing skills' );
my $hookless_repo = _create_skill_repo( $test_repos, 'hookless-skill', with_hook => 0, with_cpanfile => 0 );
ok( !$manager->install( 'file://' . $hookless_repo )->{error}, 'hookless skill installs cleanly' );
is_deeply( $dispatcher->execute_hooks( 'hookless-skill', 'run-test' ), { hooks => {}, result_state => {} }, 'execute_hooks returns an empty result when no hook directory exists' );
is_deeply( $dispatcher->get_skill_config(''), {}, 'get_skill_config returns an empty hash for empty skill names' );
is_deeply( $dispatcher->get_skill_config('missing-skill'), {}, 'get_skill_config returns an empty hash for missing skills' );
my $invalid_config_root = $manager->get_skill_path('hookless-skill');
_write_file( File::Spec->catfile( $invalid_config_root, 'config', 'config.json' ), "{not json}\n" );
is_deeply( $dispatcher->get_skill_config('hookless-skill'), {}, 'get_skill_config falls back to an empty hash for invalid JSON config' );
is( $dispatcher->get_skill_path(''), undef, 'get_skill_path returns undef for empty skill names' );
is( $dispatcher->get_skill_path('dep-skill'), $manager->get_skill_path('dep-skill'), 'get_skill_path returns the installed skill path for valid skills' );
is( $dispatcher->command_path( '', 'run-test' ), undef, 'command_path returns undef for missing skill names' );
is( $dispatcher->command_path( 'dep-skill', '' ), undef, 'command_path returns undef for missing command names' );
is( $dispatcher->command_path( 'dep-skill', 'missing' ), undef, 'command_path returns undef for missing skill commands' );
my $no_bookmark_repo = _create_skill_repo( $test_repos, 'no-bookmarks-skill', with_cpanfile => 0, with_bookmark => 0 );
ok( !$manager->install( 'file://' . $no_bookmark_repo )->{error}, 'skill without bookmarks installs cleanly' );
is( $dispatcher->route_response( skill_name => 'missing-skill', route => 'bookmarks' )->[0], 404, 'route_response returns 404 for missing skills' );
is( $dispatcher->route_response( skill_name => 'dep-skill', route => '' )->[0], 404, 'route_response returns 404 for empty routes' );
is( $dispatcher->route_response( skill_name => 'no-bookmarks-skill', route => 'bookmarks' )->[0], 404, 'route_response returns 404 when a skill has no bookmarks' );
is( $dispatcher->route_response( skill_name => 'dep-skill', route => 'unknown' )->[0], 404, 'route_response rejects unsupported skill routes' );
{
    my $local_lib = File::Spec->catdir( $manager->get_skill_path('dep-skill'), 'local', 'lib', 'perl5' );
    make_path($local_lib);
    local $ENV{PERL5LIB} = 'base-lib';
    my %env = $dispatcher->_skill_env(
        skill_name   => 'dep-skill',
        skill_path   => $manager->get_skill_path('dep-skill'),
        command      => 'run-test',
        result_state => { alpha => { stdout => "ok\n" } },
    );
    like( $env{PERL5LIB}, qr/\Q$local_lib\E/, '_skill_env prepends the skill-local perl library when present' );
    like( $env{RESULT}, qr/alpha/, '_skill_env serializes RESULT state for skill hooks and commands' );
}

done_testing();

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
    if ( !exists $args{with_bookmark} || $args{with_bookmark} ) {
        _write_file(
            File::Spec->catfile( 'dashboards', 'welcome' ),
            "TITLE: Welcome\n:--------------------------------------------------------------------------------:\nBOOKMARK: welcome\n:--------------------------------------------------------------------------------:\nHTML:\nHello\n",
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
