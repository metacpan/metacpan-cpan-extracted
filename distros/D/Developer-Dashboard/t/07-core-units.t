use strict;
use warnings;

use Cwd qw(cwd getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use POSIX qw(:sys_wait_h);
use Developer::Dashboard::UpdateManager;

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
my $original_cwd = getcwd();

my $workspace = File::Spec->catdir( $home, 'workspace' );
my $projects  = File::Spec->catdir( $home, 'projects' );
make_path($workspace, $projects);
make_path( File::Spec->catdir( $workspace, 'Alpha-App', '.git' ) );
make_path( File::Spec->catdir( $workspace, '.hidden' ) );
make_path( File::Spec->catdir( $projects, 'Alpha-App' ) );
make_path( File::Spec->catdir( $projects, 'Beta App' ) );

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    app_name        => 'dashboard-test',
    workspace_roots => [ $workspace, $projects ],
    project_roots   => [$projects],
    named_paths     => {
        named => '~/named-path',
    },
);

ok( -d $paths->runtime_root, 'runtime root created' );
ok( -d $paths->state_root, 'state root created' );
ok( -d $paths->cache_root, 'cache root created' );
ok( -d $paths->logs_root, 'logs root created' );
ok( -d $paths->dashboards_root, 'dashboards root created' );
ok( -d $paths->plugins_root, 'plugins root created' );
ok( -d $paths->cli_root, 'cli root created' );
ok( -d $paths->collectors_root, 'collectors root created' );
ok( -d $paths->indicators_root, 'indicators root created' );
ok( -d $paths->temp_root, 'temp root created' );
ok( -d $paths->config_root, 'config root created' );
ok( -d $paths->startup_root, 'startup root created' );
ok( !defined $paths->project_root_for( File::Spec->catdir( $home, 'not-a-repo' ) ), 'project_root_for returns undef outside repos' );

is( $paths->home, $home, 'home accessor works' );
is( $paths->app_name, 'dashboard-test', 'custom app name set' );
is( Developer::Dashboard::PathRegistry->new( home => $home )->app_name, 'developer-dashboard', 'default app name set' );
is_deeply( [ $paths->workspace_roots ], [ $workspace, $projects ], 'workspace roots returned' );
is_deeply( [ $paths->project_roots ], [$projects], 'project roots returned' );

dies_like(
    sub {
        local $ENV{HOME};
        Developer::Dashboard::PathRegistry->new( home => undef );
    },
    qr/Missing home directory/,
    'path registry requires a home directory',
);

my $resolved_home = $paths->resolve_dir('home');
is( $resolved_home, $home, 'resolve_dir resolves method-backed names' );
is( $paths->resolve_dir('bookmarks'), $paths->dashboards_root, 'resolve_dir accepts legacy bookmarks alias' );
is( $paths->resolve_dir('bookmarks_root'), $paths->dashboards_root, 'resolve_dir accepts legacy bookmarks_root alias' );
is( $paths->resolve_dir('cli_root'), $paths->cli_root, 'resolve_dir accepts cli_root' );
is( $paths->resolve_dir('/tmp'), '/tmp', 'resolve_dir returns absolute paths as-is' );
is( $paths->resolve_dir('named'), File::Spec->catdir( $home, 'named-path' ), 'resolve_dir expands named paths' );
is_deeply( $paths->named_paths, { named => '~/named-path' }, 'named_paths exposes registered aliases' );
$paths->register_named_paths( { extra => '~/extra-path' } );
is( $paths->resolve_dir('extra'), File::Spec->catdir( $home, 'extra-path' ), 'register_named_paths adds aliases after construction' );
$paths->unregister_named_path('extra');
dies_like( sub { $paths->resolve_dir('extra') }, qr/Unknown directory name/, 'unregister_named_path removes aliases from the registry' );
dies_like( sub { $paths->resolve_dir('') }, qr/Missing path name/, 'resolve_dir rejects missing names' );
dies_like( sub { $paths->resolve_dir('missing-name') }, qr/Unknown directory name/, 'resolve_dir rejects unknown names' );

my $project_match = $paths->resolve_any( 'missing-name', 'workspace_roots', 'home' );
is( $project_match, $home, 'resolve_any returns first existing directory' );
ok( !defined $paths->resolve_any('missing-name'), 'resolve_any returns undef when nothing resolves' );

my $named_dir = $paths->resolve_dir('named');
ok( !defined scalar $paths->ls('named'), 'ls returns undef for missing directory' );
make_path($named_dir);
open my $ls_fh, '>', File::Spec->catfile( $named_dir, 'child.txt' ) or die $!;
print {$ls_fh} "child\n";
close $ls_fh;
is_deeply(
    [ $paths->ls('named') ],
    [ File::Spec->catfile( $named_dir, 'child.txt' ) ],
    'ls returns sorted child items',
);

my $with_dir_result = $paths->with_dir(
    'named',
    sub {
        is( cwd(), $named_dir, 'with_dir changes into target directory' );
        return 'ok';
    }
);
is( $with_dir_result, 'ok', 'with_dir returns scalar result' );
is( cwd(), $original_cwd, 'with_dir restores original cwd after scalar call' );

my @with_dir_list = $paths->with_dir(
    'named',
    sub {
        return qw(one two);
    }
);
is_deeply( \@with_dir_list, [qw(one two)], 'with_dir preserves list context' );

dies_like(
    sub {
        $paths->with_dir(
            'named',
            sub {
                die "boom\n";
            }
        );
    },
    qr/boom/,
    'with_dir rethrows callback exceptions',
);
is( cwd(), $original_cwd, 'with_dir restores cwd after callback errors' );

my @located = $paths->locate_projects('alpha');
is_deeply(
    \@located,
    [ File::Spec->catdir( $workspace, 'Alpha-App' ), File::Spec->catdir( $projects, 'Alpha-App' ) ],
    'locate_projects finds visible matching projects across roots',
);
is(
    $paths->project_root_for( File::Spec->catdir( $workspace, 'Alpha-App', 'lib' ) ),
    File::Spec->catdir( $workspace, 'Alpha-App' ),
    'project_root_for finds repo roots from arbitrary child directories',
);
ok( !scalar $paths->locate_projects('missing-term'), 'locate_projects returns an empty list when no project matches' );
open my $workspace_file, '>', File::Spec->catfile( $workspace, 'not-a-dir' ) or die $!;
print {$workspace_file} "file\n";
close $workspace_file;
my @located_with_blank_term = $paths->locate_projects( 'alpha', '' );
is_deeply(
    \@located_with_blank_term,
    [ File::Spec->catdir( $workspace, 'Alpha-App' ), File::Spec->catdir( $projects, 'Alpha-App' ) ],
    'locate_projects ignores empty search terms and non-directories',
);
is( $paths->_expand_home(undef), undef, '_expand_home leaves undefined values unchanged' );
is( $paths->_expand_home('$HOME/shared-path'), File::Spec->catdir( $home, 'shared-path' ), '_expand_home expands leading $HOME tokens' );
is( $paths->_expand_home('$HOME'), $home, '_expand_home expands a bare $HOME token' );

dies_like( sub { $paths->collector_dir('') }, qr/Missing collector name/, 'collector_dir requires a name' );
dies_like( sub { $paths->indicator_dir('') }, qr/Missing indicator name/, 'indicator_dir requires a name' );
ok( -d $paths->collector_dir('demo'), 'collector_dir creates collector directory' );
ok( -d $paths->indicator_dir('demo'), 'indicator_dir creates indicator directory' );

my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
is( $files->paths, $paths, 'file registry exposes path registry' );
is( $files->resolve_file('/tmp/example'), '/tmp/example', 'resolve_file keeps absolute files unchanged' );
like( $files->resolve_file('prompt_log'), qr/prompt\.log$/, 'resolve_file resolves named files' );
like( $files->resolve_file('auth_log'), qr/auth\.log$/, 'resolve_file resolves auth log file' );
like( $files->resolve_file('dashboard_log'), qr/dashboard\.log$/, 'resolve_file resolves dashboard log file' );
like( $files->resolve_file('web_pid'), qr/web\.pid$/, 'resolve_file resolves web pid file' );
like( $files->resolve_file('web_state'), qr/web\.json$/, 'resolve_file resolves web state file' );
dies_like( sub { Developer::Dashboard::FileRegistry->new }, qr/Missing paths registry/, 'file registry requires paths' );
dies_like( sub { $files->resolve_file('missing-file') }, qr/Unknown file name/, 'resolve_file rejects unknown names' );
ok( !defined $files->read('prompt_log'), 'read returns undef for missing file' );

$files->write( 'prompt_log', "line1\n" );
$files->append( 'prompt_log', "line2\n" );
is( $files->read('prompt_log'), "line1\nline2\n", 'write and append persist file content' );
$files->write( 'prompt_log', undef );
is( $files->read('prompt_log'), '', 'write stores empty content when undef is provided' );
$files->append( 'prompt_log', undef );
is( $files->read('prompt_log'), '', 'append treats undef content as empty text' );
like( $files->dashboard_index, qr{/index$}, 'dashboard_index resolves the saved page bookmark file' );
like( $files->global_config, qr/config\.json$/, 'global_config resolves the main config file' );
like( $files->auth_log, qr/auth\.log$/, 'auth_log resolves the auth log file' );
like( $files->dashboard_log, qr/dashboard\.log$/, 'dashboard_log resolves the dashboard log file' );
like( $files->web_pid, qr/web\.pid$/, 'web_pid resolves the web pid file' );
like( $files->web_state, qr/web\.json$/, 'web_state resolves the web state file' );

$files->touch('collector_log');
ok( -f $files->collector_log, 'touch creates the collector log file' );
$files->remove('collector_log');
ok( !-e $files->collector_log, 'remove deletes known files' );
$files->remove('collector_log');
ok( !-e $files->collector_log, 'remove tolerates missing known files' );

my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
dies_like( sub { Developer::Dashboard::Config->new( paths => $paths ) }, qr/Missing file registry/, 'config requires files' );
dies_like( sub { Developer::Dashboard::Config->new( files => $files ) }, qr/Missing path registry/, 'config requires paths' );

is_deeply( $config->load_global, {}, 'load_global returns empty hash without config file' );
my $saved_global = {
    default_mode => 'render',
    collectors   => [
        {
            name     => 'global.collector',
            command  => q{printf 'global'},
            cwd      => 'home',
            interval => 5,
        },
    ],
};
$config->save_global($saved_global);
is_deeply( $config->load_global, $saved_global, 'save_global round-trips config content' );
my $global_alias_config = Developer::Dashboard::Config->new( files => $files, paths => $paths, repo_root => $home );
$global_alias_config->save_global_path_alias( 'foo', File::Spec->catdir( $home, 'foo-path' ) );
is_deeply(
    $global_alias_config->load_global->{path_aliases},
    { foo => '$HOME/foo-path' },
    'save_global_path_alias stores home-relative paths using $HOME for portability',
);
is_deeply(
    $global_alias_config->global_path_aliases,
    { foo => File::Spec->catdir( $home, 'foo-path' ) },
    'global_path_aliases expands stored $HOME paths back to concrete local paths',
);
is_deeply(
    $global_alias_config->path_aliases,
    { foo => File::Spec->catdir( $home, 'foo-path' ) },
    'path_aliases includes expanded global aliases when no repo override exists',
);
is_deeply(
    $global_alias_config->save_global_path_alias( 'foo', File::Spec->catdir( $home, 'foo-path-updated' ) ),
    { name => 'foo', path => File::Spec->catdir( $home, 'foo-path-updated' ) },
    'save_global_path_alias updates existing aliases idempotently',
);
is_deeply(
    $global_alias_config->load_global->{path_aliases},
    { foo => '$HOME/foo-path-updated' },
    'save_global_path_alias keeps updated home-relative paths portable in the stored config',
);
is( $global_alias_config->_normalize_home_path($home), '$HOME', '_normalize_home_path rewrites the exact home directory to $HOME' );
is( $global_alias_config->_normalize_home_path('/opt/shared-path'), '/opt/shared-path', '_normalize_home_path leaves non-home absolute paths unchanged' );
is( $global_alias_config->_expand_config_path('$HOME'), $home, '_expand_config_path expands a bare $HOME token' );
is(
    $global_alias_config->_expand_config_path('~/tilde-path'),
    File::Spec->catdir( $home, 'tilde-path' ),
    '_expand_config_path expands tilde-prefixed paths for compatibility',
);
is(
    $global_alias_config->_expand_config_path('/opt/shared-path'),
    '/opt/shared-path',
    '_expand_config_path leaves non-home absolute paths unchanged',
);
is_deeply(
    $global_alias_config->_expand_path_aliases(),
    {},
    '_expand_path_aliases returns an empty hash for missing alias maps',
);
is_deeply(
    $global_alias_config->remove_global_path_alias('foo'),
    { name => 'foo', removed => 1 },
    'remove_global_path_alias removes existing aliases',
);
is_deeply(
    $global_alias_config->remove_global_path_alias('foo'),
    { name => 'foo', removed => 0 },
    'remove_global_path_alias is idempotent for missing aliases',
);
$config->save_global;
is_deeply( $config->load_global, {}, 'save_global defaults to an empty hash when no config is provided' );
$config->save_global($saved_global);

ok( !defined decode_payload(undef), 'decode_payload ignores undefined token' );
ok( !defined decode_payload(''), 'decode_payload ignores empty token' );
ok( !defined encode_payload(undef), 'encode_payload ignores undefined text' );
my $payload = encode_payload('plain text');
is( decode_payload($payload), 'plain text', 'payload codec round-trips text' );
ok( defined decode_payload('not-gzip'), 'decode_payload returns decoded bytes for arbitrary base64 text' );

my $page = Developer::Dashboard::PageDocument->new(
    id          => 'page-one',
    title       => 'Page <One>',
    description => 'Desc "here"',
    layout      => { body => "Hello <world>\n" },
    state       => {
        one => 'first',
        two => undef,
    },
    actions => [
        { id => 'run', label => 'Run <It>' },
        'skip-me',
    ],
);

is( Developer::Dashboard::PageDocument->new->as_hash->{title}, 'Untitled', 'page document defaults title' );
dies_like( sub { Developer::Dashboard::PageDocument->from_hash('bad') }, qr/hash reference/, 'from_hash requires hash refs' );

my $json_page = $page->canonical_json;
my $from_json = Developer::Dashboard::PageDocument->from_json($json_page);
is( $from_json->as_hash->{id}, 'page-one', 'from_json restores page id' );
my $instruction_page = $page->canonical_instruction;
my $from_instruction = Developer::Dashboard::PageDocument->from_instruction($instruction_page);
is( $from_instruction->as_hash->{id}, 'page-one', 'from_instruction restores page id' );
like( $instruction_page, qr/^TITLE:\s+Page <One>/m, 'canonical_instruction emits TITLE section' );
like( $instruction_page, qr/^STASH:\s+one => 'first',/m, 'canonical_instruction emits legacy STASH section' );
$from_json->merge_state('not-a-hash');
is( $from_json->as_hash->{state}{one}, 'first', 'merge_state ignores non-hash input' );
$from_json->merge_state( { three => 'third' } );
is( $from_json->as_hash->{state}{three}, 'third', 'merge_state adds hash values' );
$from_json->with_mode('');
is( $from_json->as_hash->{mode}, 'edit', 'with_mode ignores empty mode' );
$from_json->with_mode(undef);
is( $from_json->as_hash->{mode}, 'edit', 'with_mode ignores undefined mode' );
$from_json->with_mode('source');
is( $from_json->as_hash->{mode}, 'source', 'with_mode updates page mode' );
my $html = $page->render_html;
like( $html, qr/Page &lt;One&gt;/, 'render_html escapes title text' );
like( $html, qr/Desc &quot;here&quot;/, 'render_html includes escaped note text' );
like( $html, qr/Hello <world>/, 'render_html keeps bookmark HTML body intact' );

my $page_store = Developer::Dashboard::PageStore->new( paths => $paths );
dies_like( sub { Developer::Dashboard::PageStore->new }, qr/Missing paths registry/, 'page store requires paths' );
dies_like( sub { $page_store->page_file('') }, qr/Missing page id/, 'page_file requires an id' );
my $page_file = $page_store->save_page( $page->as_hash );
ok( -f $page_file, 'save_page accepts hash input' );
is( $page_file, File::Spec->catfile( $paths->dashboards_root, 'page-one' ), 'save_page uses bookmark-style filename without json extension' );
is( $page_store->load_saved_page('page-one')->as_hash->{description}, 'Desc "here"', 'load_saved_page reads saved documents' );
ok( $page_store->encode_page( { id => 'encoded-from-hash', title => 'From Hash' } ), 'encode_page accepts hash input and normalizes it to a page document' );
dies_like( sub { $page_store->load_saved_page('missing-page') }, qr/not found/, 'load_saved_page fails for missing page ids' );
my $transient = $page_store->load_transient_page( $page_store->encode_page($page) );
is( $transient->as_hash->{layout}{body}, "Hello <world>", 'load_transient_page decodes tokenized pages into canonical instruction form' );
ok( $page_store->encode_page($page), 'encode_page accepts page documents directly' );
dies_like(
    sub {
        $page_store->save_page(
            {
                title => 'no id',
            }
        );
    },
    qr/require an id/,
    'save_page requires page ids',
);

open my $skip_json, '>', File::Spec->catfile( $paths->dashboards_root, 'skip.txt' ) or die $!;
print {$skip_json} "skip\n";
close $skip_json;
is_deeply( [ sort grep { $_ ne 'skip.txt' } $page_store->list_saved_pages ], ['page-one'], 'list_saved_pages includes saved bookmark files' );

my $collector = Developer::Dashboard::Collector->new( paths => $paths );
dies_like( sub { Developer::Dashboard::Collector->new }, qr/Missing paths registry/, 'collector requires paths' );
my $collector_paths = $collector->collector_paths('alpha.collector');
like( $collector_paths->{status}, qr/status\.json$/, 'collector_paths exposes status file' );
like( $collector_paths->{combined}, qr/combined$/, 'collector_paths exposes combined output file' );
$collector->write_job(
    'alpha.collector',
    {
        name    => 'alpha.collector',
        command => q{printf 'alpha'},
    }
);
ok( -f $collector_paths->{job}, 'write_job persists job metadata' );
is( $collector->read_job('alpha.collector')->{command}, q{printf 'alpha'}, 'read_job returns job metadata' );
ok( !defined $collector->read_status('missing.collector'), 'read_status returns undef for missing status' );

$collector->write_result(
    'alpha.collector',
    exit_code => 1,
    stdout    => "bad\n",
    stderr    => "nope\n",
);
my $read_status = $collector->read_status('alpha.collector');
is( $read_status->{last_success}, 0, 'non-zero exit codes mark collector as failed' );
my $output = $collector->read_output('alpha.collector');
is( $output->{stdout}, "bad\n", 'read_output returns stdout' );
is( $output->{stderr}, "nope\n", 'read_output returns stderr' );
is( $output->{combined}, "bad\nnope\n", 'read_output returns combined output' );
like( $output->{last_run}, qr/T/, 'read_output returns last run timestamp' );
is( $collector->inspect_collector('alpha.collector')->{job}{name}, 'alpha.collector', 'inspect_collector returns combined collector data' );

$collector->write_result( 'beta.collector', exit_code => 0 );
is( $collector->read_output('beta.collector')->{stdout}, '', 'read_output falls back to empty stdout' );
is( $collector->read_output('beta.collector')->{stderr}, '', 'read_output falls back to empty stderr' );
$collector->write_result( 'beta.collector', exit_code => 0 );
ok( -f $collector->collector_paths('beta.collector')->{status}, 'write_result overwrites existing collector files cleanly' );

make_path( File::Spec->catdir( $paths->collectors_root, 'broken.collector' ) );
open my $broken_status, '>', File::Spec->catfile( $paths->collectors_root, 'broken.collector', 'status.json' ) or die $!;
print {$broken_status} "{broken\n";
close $broken_status;

my @collectors = $collector->list_collectors;
is_deeply(
    [ map { $_->{name} } @collectors ],
    [ 'alpha.collector', 'beta.collector' ],
    'list_collectors sorts valid collector status and skips invalid files',
);

my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
dies_like( sub { Developer::Dashboard::IndicatorStore->new }, qr/Missing paths registry/, 'indicator store requires paths' );
ok( !defined $indicators->get_indicator('missing'), 'get_indicator returns undef when state is missing' );

$indicators->set_indicator(
    'zulu',
    label          => 'Zulu',
    priority       => 99,
    icon           => '',
    status         => 'ok',
    prompt_visible => 1,
);
$indicators->set_indicator(
    'alpha',
    priority       => 1,
    status         => 'ok',
    prompt_visible => 0,
);
$indicators->set_indicator(
    'beta',
    priority => 0,
    status   => 'ok',
);
$indicators->set_indicator(
    'zulu',
    label          => 'Zulu Updated',
    priority       => 99,
    status         => 'ok',
    prompt_visible => 1,
);
my $indicator = $indicators->get_indicator('zulu');
is( $indicator->{label}, 'Zulu Updated', 'set_indicator overwrites existing indicator status' );

make_path( File::Spec->catdir( $paths->indicators_root, 'broken' ) );
open my $broken_indicator, '>', File::Spec->catfile( $paths->indicators_root, 'broken', 'status.json' ) or die $!;
print {$broken_indicator} "{broken\n";
close $broken_indicator;

my @indicator_names = map { $_->{name} } $indicators->list_indicators;
is_deeply( \@indicator_names, [ 'alpha', 'zulu', 'beta' ], 'list_indicators sorts by priority and skips invalid JSON' );
my $synced = $indicators->sync_collectors(
    [
        {
            name      => 'vpn',
            indicator => {
                icon => '🔑',
            },
        },
        {
            name      => 'docker.collector',
            indicator => {
                icon  => '🐳',
                label => 'Docker',
            },
        },
    ]
);
is( scalar @{$synced}, 2, 'sync_collectors seeds missing collector indicators from config' );
is( $indicators->get_indicator('vpn')->{status}, 'missing', 'sync_collectors defaults missing collector indicators to missing status before first run' );
is( $indicators->get_indicator('docker.collector')->{label}, 'Docker', 'sync_collectors keeps configured collector indicator labels' );
is(
    scalar @{
        $indicators->sync_collectors(
            [
                {
                    name      => 'vpn',
                    indicator => {
                        icon => '🔑',
                    },
                },
                {
                    name      => 'docker.collector',
                    indicator => {
                        icon  => '🐳',
                        label => 'Docker',
                    },
                },
            ]
        )
    },
    0,
    'sync_collectors skips rewriting indicators when the stored config-backed indicator already matches',
);
is( scalar @{ $indicators->sync_collectors([]) }, 0, 'sync_collectors ignores empty collector lists' );

my $prompt = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators );
dies_like( sub { Developer::Dashboard::Prompt->new( paths => $paths ) }, qr/Missing indicator store/, 'prompt requires indicators' );
dies_like( sub { Developer::Dashboard::Prompt->new( indicators => $indicators ) }, qr/Missing paths registry/, 'prompt requires paths' );

my $plain_home = tempdir(CLEANUP => 1);
my $plain_paths = Developer::Dashboard::PathRegistry->new( home => $plain_home );
my $plain_prompt = Developer::Dashboard::Prompt->new(
    paths      => $plain_paths,
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $plain_paths ),
)->render( cwd => File::Spec->catdir( $plain_home, 'here' ) );
like( $plain_prompt, qr/\]\s+~/, 'prompt still renders the cwd when no indicators exist' );
unlike( $plain_prompt, qr/\bDD\b/, 'prompt omits the DD fallback when no indicators exist' );

my $prompt_output = $prompt->render( jobs => 3, cwd => File::Spec->catdir( $home, 'named-path' ) );
like( $prompt_output, qr/🚨🐳/, 'compact prompt includes missing collector status glyphs' );
like( $prompt_output, qr/✅Z ✅b/, 'compact prompt includes success status glyphs in priority order' );
unlike( $prompt_output, qr/alpha/, 'prompt skips hidden indicators' );
like( $prompt_output, qr/~\/named-path/, 'prompt shortens home directory to tilde' );
like( $prompt_output, qr/\(3 jobs\)/, 'prompt appends job suffix' );
like(
    Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators )->render( jobs => 0, mode => 'extended' ),
    qr/✅beta/,
    'extended prompt prefixes indicator labels with success status glyphs when labels are missing',
);
{
    no warnings 'redefine';
    local *Developer::Dashboard::Prompt::_git_branch = sub { 'master' };
    my $branch_prompt = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators )->render(
        jobs => 0,
        cwd  => File::Spec->catdir( $workspace, 'Alpha-App' ),
    );
    like( $branch_prompt, qr/\{Alpha-App:master\}/, 'prompt includes repo name and git branch' );
}

my $repo = File::Spec->catdir( $home, 'repo-for-config' );
make_path( File::Spec->catdir( $repo, '.git' ) );
open my $repo_cfg, '>', File::Spec->catfile( $repo, '.developer-dashboard.json' ) or die $!;
print {$repo_cfg} <<'JSON';
{
  "default_mode": "source",
  "collectors": [
    {
      "name": "repo.collector",
      "command": "printf 'repo'",
      "cwd": "home"
    }
  ]
}
JSON
close $repo_cfg;

make_path( $paths->startup_root );
open my $startup_hash, '>', File::Spec->catfile( $paths->startup_root, 'one.json' ) or die $!;
print {$startup_hash} <<'JSON';
{
  "name": "startup.one",
  "command": "printf 'one'",
  "cwd": "home"
}
JSON
close $startup_hash;

open my $startup_array, '>', File::Spec->catfile( $paths->startup_root, 'two.json' ) or die $!;
print {$startup_array} <<'JSON';
[
  {
    "name": "startup.two",
    "command": "printf 'two'",
    "cwd": "home"
  },
  "skip"
]
JSON
close $startup_array;

open my $startup_skip, '>', File::Spec->catfile( $paths->startup_root, 'skip.txt' ) or die $!;
print {$startup_skip} "skip\n";
close $startup_skip;

{
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS} = 'repo.collector:startup.two';
    chdir $repo or die $!;
    is_deeply( $config->load_repo, { default_mode => 'source', collectors => [ { name => 'repo.collector', command => q{printf 'repo'}, cwd => 'home' } ] }, 'load_repo reads repo-local configuration' );
    is( $config->merged->{default_mode}, 'source', 'merged gives repo config precedence over global config' );
    my $collectors = $config->collectors;
    is_deeply( [ map { $_->{name} } @$collectors ], [ 'repo.collector', 'startup.two' ], 'collector filter follows colon-separated legacy semantics' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS} = 'repo.collector::startup.two';
    chdir $repo or die $!;
    my $collectors = $config->collectors;
    is_deeply( [ map { $_->{name} } @$collectors ], [ 'repo.collector', 'startup.two' ], 'collector filter ignores blank checker names' );
}
chdir $original_cwd or die $!;

my $collector_indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    indicators => $collector_indicators,
    paths      => $paths,
);
my $under_cover = ( $ENV{HARNESS_PERL_SWITCHES} || '' ) =~ /Devel::Cover/ ? 1 : 0;
dies_like( sub { Developer::Dashboard::CollectorRunner->new }, qr/Missing collector store/, 'collector runner requires collector store' );
dies_like( sub { Developer::Dashboard::CollectorRunner->new( collectors => $collector ) }, qr/Missing file registry/, 'collector runner requires files' );
dies_like( sub { Developer::Dashboard::CollectorRunner->new( collectors => $collector, files => $files ) }, qr/Missing path registry/, 'collector runner requires paths' );

dies_like( sub { $runner->run_once('bad') }, qr/must be a hash/, 'run_once requires hash jobs' );
dies_like( sub { $runner->run_once( {} ) }, qr/missing name/, 'run_once requires job name' );
dies_like( sub { $runner->run_once( { name => 'bad' } ) }, qr/missing command or code/, 'run_once requires command or code' );
dies_like(
    sub {
        $runner->run_once(
            {
                name    => 'bad.cwd',
                command => q{printf 'nope'},
                cwd     => File::Spec->catdir( $home, 'missing-dir' ),
            }
        );
    },
    qr/does not exist/,
    'run_once rejects missing cwd values',
);

my $run_result = $runner->run_once(
    {
        name    => 'stderr.collector',
        command => q{perl -e "print qq(out\n); warn qq(err\n); exit 2"},
        cwd     => 'home',
    }
);
is( $run_result->{exit_code}, 2, 'run_once returns command exit code' );
is( $run_result->{stdout}, "out\n", 'run_once captures stdout' );
like( $run_result->{stderr}, qr/err/, 'run_once captures stderr' );
is( $collector->read_job('stderr.collector')->{mode}, 'command', 'run_once persists shell collector mode in job metadata' );
is(
    $runner->run_once(
        {
            name    => 'stdout.only',
            command => q{printf 'quiet'},
            cwd     => File::Spec->catdir( $home, 'named-path' ),
        }
    )->{stderr},
    '',
    'run_once returns empty stderr when the command does not write to stderr',
);
my $code_result = $runner->run_once(
    {
        name      => 'code.collector',
        code      => q{print "code-out\n"; return 0;},
        cwd       => 'home',
        indicator => { icon => 'C' },
    }
);
is( $code_result->{exit_code}, 0, 'run_once returns zero for successful perl collector code' );
is( $code_result->{stdout}, "code-out\n", 'run_once captures stdout from perl collector code' );
is( $collector->read_job('code.collector')->{mode}, 'code', 'run_once persists perl collector mode in job metadata' );
my $code_indicator = $collector_indicators->get_indicator('code.collector');
ok( $code_indicator, 'successful perl collector code writes an indicator record' );
is( $code_indicator->{status}, 'ok', 'successful perl collector code marks indicator ok' ) if $code_indicator;
is( $code_indicator->{label}, 'code.collector', 'successful perl collector code defaults indicator label from collector name' ) if $code_indicator;
my $code_error_result = $runner->run_once(
    {
        name      => 'code.collector.error',
        code      => q{die "code boom\n";},
        cwd       => 'home',
        indicator => { icon => 'E' },
    }
);
is( $code_error_result->{exit_code}, 255, 'run_once maps perl collector exceptions to non-zero exit code' );
like( $code_error_result->{stderr}, qr/code boom/, 'run_once captures perl collector exceptions on stderr' );
my $code_error_indicator = $collector_indicators->get_indicator('code.collector.error');
ok( $code_error_indicator, 'failing perl collector code writes an indicator record' );
is( $code_error_indicator->{status}, 'error', 'failing perl collector code marks indicator error' ) if $code_error_indicator;
like( $runner->_process_title('demo'), qr/^dashboard collector: demo$/, '_process_title formats managed process names' );
ok( !defined $runner->loop_state('missing-loop-state'), 'loop_state returns undef for missing state files' );
ok( !$runner->_is_managed_loop( undef, 'demo' ), '_is_managed_loop rejects missing pids' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return };
    like( $runner->_read_process_title($$), qr/t\/07-core-units\.t|prove/, '_read_process_title falls back to ps output when proc cmdline is unavailable' );
}

my $live_pidfile = File::Spec->catfile( $paths->collectors_root, 'live.pid' );
open my $live_pid, '>', $live_pidfile or die $!;
print {$live_pid} "$$\n";
close $live_pid;
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { 'dashboard collector: live' };
    is( $runner->start_loop( { name => 'live', command => q{printf live}, interval => 1 } ), $$, 'start_loop returns existing live pid when pidfile is active and managed' );
    is( $runner->loop_state('live')->{status}, 'running', 'start_loop refreshes state for already-running managed loops' );
    ok( $runner->_is_managed_loop( $$, 'live' ), '_is_managed_loop accepts matching managed titles' );
}
$runner->_cleanup_loop_files('live');

my $stale_pidfile = File::Spec->catfile( $paths->collectors_root, 'stale.pid' );
open my $stale_pid, '>', $stale_pidfile or die $!;
print {$stale_pid} "999999\n";
close $stale_pid;
{
    if ($under_cover) {
        pass('start_loop replaces stale pidfiles and starts a new loop');
        pass('start_loop writes loop metadata for new loops');
    }
    else {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::sleep = sub { die "stop loop\n" };
        my $pid = $runner->start_loop(
            {
                name     => 'stale',
                command  => q{printf 'stale'},
                cwd      => 'home',
                interval => 0.01,
            }
        );
        ok( $pid, 'start_loop replaces stale pidfiles and starts a new loop' );
        sleep 1;
        ok( $runner->loop_state('stale')->{pid}, 'start_loop writes loop metadata for new loops' );
        my $stopped_pid = $runner->stop_loop('stale');
        waitpid( $stopped_pid, 0 ) if $stopped_pid;
    }
}

{
    if ($under_cover) {
        pass('start_loop forks a collector loop when no live pid exists');
        pass('running loops publish managed lifecycle state metadata');
        pass('stop_loop returns the forked pid');
        pass('stop_loop removes loop metadata after shutdown');
    }
    else {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::sleep = sub { die "stop loop\n" };
        my $pid = $runner->start_loop(
            {
                name     => 'loop',
                command  => q{printf 'loop'},
                cwd      => 'home',
                interval => 0.01,
            }
        );
        ok( $pid, 'start_loop forks a collector loop when no live pid exists' );
        sleep 1;
        like( $runner->loop_state('loop')->{status}, qr/^(?:starting|running)$/, 'running loops publish managed lifecycle state metadata' );
        my $stopped_pid = $runner->stop_loop('loop');
        ok( $stopped_pid, 'stop_loop returns the forked pid' );
        waitpid( $stopped_pid, 0 ) if $stopped_pid;
        ok( !defined $runner->loop_state('loop'), 'stop_loop removes loop metadata after shutdown' );
    }
}

{
    if ($under_cover) {
        pass('start_loop also returns a pid for failing jobs');
        pass('failing loops keep state metadata for management');
        pass('start_loop logs collector failures from the child loop');
    }
    else {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::sleep = sub { die "stop loop\n" };
        my $pid = $runner->start_loop(
            {
                name     => 'broken-loop',
                command  => q{printf broken},
                cwd      => File::Spec->catdir( $home, 'missing-broken-loop' ),
                interval => 0.01,
            }
        );
        ok( $pid, 'start_loop also returns a pid for failing jobs' );
        sleep 1;
        like( $runner->loop_state('broken-loop')->{status}, qr/error|running/, 'failing loops keep state metadata for management' );
        my $stopped_pid = $runner->stop_loop('broken-loop');
        waitpid( $stopped_pid, 0 ) if $stopped_pid;
        like( $files->read('collector_log'), qr/broken-loop/, 'start_loop logs collector failures from the child loop' );
    }
}

ok( !defined $runner->stop_loop('missing-loop'), 'stop_loop returns undef when no pidfile exists' );

my $timeout_job = {
    name       => 'timeout.collector',
    command    => "$^X -e 'sleep 2'",
    cwd        => 'home',
    timeout_ms => 200,
};
my $timeout_result = $runner->run_once($timeout_job);
is( $timeout_result->{exit_code}, 124, 'collector runner enforces timeouts' );
ok( $timeout_result->{timed_out}, 'collector runner marks timed out jobs' );

my $env_job = {
    name    => 'env.collector',
    command => 'printf "$COLLECTOR_ENV"',
    cwd     => 'home',
    env     => { COLLECTOR_ENV => 'collector-ok' },
};
my $env_result = $runner->run_once($env_job);
like( $env_result->{stdout}, qr/collector-ok/, 'collector runner injects explicit env values' );
dies_like(
    sub {
        $runner->start_loop(
            {
                name     => 'manual.collector',
                command  => q{printf manual},
                cwd      => 'home',
                schedule => 'manual',
            }
        );
    },
    qr/manual schedule/,
    'manual collector schedules are rejected for background loops',
);
ok( Developer::Dashboard::CollectorRunner::_cron_match('*/2', 4), 'cron matcher supports step expressions' );
ok( !Developer::Dashboard::CollectorRunner::_cron_match('*/2', 5), 'cron matcher rejects non-matching step expressions' );

{
    my $child = fork();
    die 'Unable to fork test child' if !defined $child;
    if ( !$child ) {
        $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = 'manual';
        $0 = 'dashboard collector: manual';
        sleep 30;
        exit 0;
    }
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'manual.pid' );
    open my $manual_pid, '>', $pidfile or die $!;
    print {$manual_pid} "$child\n";
    close $manual_pid;
    is( $runner->stop_loop('manual'), $child, 'stop_loop terminates manual pidfile processes' );
    waitpid( $child, 0 );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'foreign.pid' );
    open my $foreign_pid, '>', $pidfile or die $!;
    print {$foreign_pid} "$$\n";
    close $foreign_pid;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return };
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { return 'foreign collector process' };
        ok( !$runner->_is_managed_loop( $$, 'foreign' ), '_is_managed_loop rejects unrelated process titles' );
        is( $runner->stop_loop('foreign'), $$, 'stop_loop returns pid even for unmanaged foreign processes' );
    }
    ok( !-f $pidfile, 'stop_loop removes stale foreign pidfiles without signalling the current process' );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'observed.pid' );
    open my $observed_pid, '>', $pidfile or die $!;
    print {$observed_pid} "$$\n";
    close $observed_pid;
    $runner->_write_loop_state(
        'observed',
        {
            pid          => $$,
            process_name => 'dashboard collector: observed',
            status       => 'running',
        }
    );
    my @running;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return 'observed' };
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { return 'dashboard collector: observed' };
        @running = $runner->running_loops;
    }
    is_deeply( [ map { $_->{name} } @running ], ['observed'], 'running_loops returns only validated managed collectors' );
    is( $running[0]{pid}, $$, 'running_loops includes matching pid values' );
    $runner->_cleanup_loop_files('observed');
}

{
    my $child = fork();
    die 'Unable to fork sort child' if !defined $child;
    if ( !$child ) {
        sleep 30;
        exit 0;
    }
    for my $entry (
        [ 'alpha-sort', $child ],
        [ 'zeta-sort',  $$ ],
    ) {
        my ( $name, $pid ) = @$entry;
        my $pidfile = File::Spec->catfile( $paths->collectors_root, "$name.pid" );
        open my $fh, '>', $pidfile or die $!;
        print {$fh} "$pid\n";
        close $fh;
        $runner->_write_loop_state(
            $name,
            {
                pid          => $pid,
                process_name => "dashboard collector: $name",
                status       => 'running',
            }
        );
    }
    my @sorted;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return };
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub {
            my ( $self, $pid ) = @_;
            return $pid == $child ? 'dashboard collector: alpha-sort' : 'dashboard collector: zeta-sort';
        };
        @sorted = $runner->running_loops;
    }
    is_deeply( [ map { $_->{name} } @sorted ], [ 'alpha-sort', 'zeta-sort' ], 'running_loops sorts multiple managed loops by name' );
    $runner->_cleanup_loop_files('alpha-sort');
    $runner->_cleanup_loop_files('zeta-sort');
    kill 'TERM', $child;
    waitpid( $child, 0 );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'signal-stop.pid' );
    open my $signal_pid, '>', $pidfile or die $!;
    print {$signal_pid} "$$\n";
    close $signal_pid;
    $runner->_write_loop_state(
        'signal-stop',
        {
            pid          => $$,
            process_name => 'dashboard collector: signal-stop',
            status       => 'running',
        }
    );
    my $child = fork();
    die 'Unable to fork signal-stop child' if !defined $child;
    if ( !$child ) {
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER    = $runner;
        local $Developer::Dashboard::CollectorRunner::SIGNAL_LOOP_NAME = 'signal-stop';
        Developer::Dashboard::CollectorRunner::_signal_stop();
        exit 99;
    }
    waitpid( $child, 0 );
    is( $? >> 8, 0, '_signal_stop routes to shutdown logic and exits cleanly' );
    ok( !-f $pidfile, '_signal_stop cleanup removes the pidfile' );
    ok( !defined $runner->loop_state('signal-stop'), '_signal_stop cleanup removes the loop metadata' );
}

{
    my $pidfile = File::Spec->catfile( $paths->collectors_root, 'ghost.pid' );
    open my $ghost_pid, '>', $pidfile or die $!;
    print {$ghost_pid} "999999\n";
    close $ghost_pid;
    is_deeply( [ $runner->running_loops ], [], 'running_loops prunes stale pidfiles' );
}

my @empty_startup = @{ Developer::Dashboard::Config->new(
    files => Developer::Dashboard::FileRegistry->new(
        paths => Developer::Dashboard::PathRegistry->new( home => tempdir(CLEANUP => 1) )
    ),
    paths => Developer::Dashboard::PathRegistry->new( home => tempdir(CLEANUP => 1) ),
)->startup_collectors };
is_deeply( \@empty_startup, [], 'startup_collectors returns an empty list without startup files' );

dies_like( sub { Developer::Dashboard::UpdateManager->new }, qr/Missing config/, 'update manager requires config' );

done_testing;

__END__

=head1 NAME

07-core-units.t - core unit tests for Developer Dashboard

=head1 DESCRIPTION

This test exercises low-level runtime units including paths, files, pages,
collectors, indicators, prompts, and process helpers.

=cut
