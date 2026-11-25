use strict;
use warnings;
use utf8;

use FindBin;
use File::Spec;

# Load the fresh checkout lib first, ahead of the node's blib build, so this
# process runs the tip's Perl modules exactly like the CLI subprocesses
# already do (prove's -I only names the blib). Without this the test process
# runs stale-blib code: the 6.30 PathIdentity hashed the collector state
# root from the raw abs_path spelling (forward slashes on Windows) while the
# housekeeper subprocess used the tip's canonpath spelling, so the
# housekeeper looked in a different state root and silently found no log to
# rotate (line 1111). Verified by the 1111 micro (builds #67/#68).
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Capture::Tiny qw(capture);
use Developer::Dashboard::PerlEnv;
use Cwd qw(abs_path getcwd);
use Config ();
use Digest::SHA qw(sha256_hex);
use Developer::Dashboard::Collector;
use Developer::Dashboard::CLI::SeededPages ();
use Developer::Dashboard::GoRoutine ();
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::InternalCLI;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(effective_mode_octal);
use Encode qw(decode encode);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use LWP::UserAgent;
use Developer::Dashboard::Runtime::Result;
use Test::More;
use Time::HiRes qw(sleep);
use FindBin;

use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use Local::NativeCommand qw(run_shell_command);

my $UNDER_COVER = exists $INC{'Devel/Cover.pm'};
my $repo = getcwd();

sub _portable_path {
    my ($path) = @_;
    return undef if !defined $path;
    $path =~ s{\A/private(?=/var/folders/)}{};
    return $path;
}

sub _portable_output_text {
    my ($text) = @_;
    return '' if !defined $text;
    $text =~ s{/private(?=/var/folders/)}{}g;
    $text =~ s{^Restored session:.*\n}{}mg;
    my $ends_with_newline = $text =~ /\n\z/ ? 1 : 0;
    my @lines = split /\n/, $text;
    @lines = map { _portable_path($_) } @lines;
    my $normalized = join "\n", @lines;
    $normalized .= "\n" if $ends_with_newline;
    return $normalized;
}

sub is_same_path_output {
    my ( $got, $expected, $label ) = @_;
    is( _portable_output_text($got), _portable_output_text($expected), $label );
}

local $ENV{HOME} = tempdir(CLEANUP => 1);
# Every runtime this file starts through the CLI (web, collector supervisor,
# collector loops) is detached, and only the matching `d2 stop` further down
# ends it. A run that is killed part-way never reaches that stop, and the
# runtimes then live on for days. Tie them to this test process: the
# supervisor of each runtime ends its loops, its web service and itself once
# this pid is gone.
local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;
# DD-800: this used to prepend a literal '/home/mv/perl5/lib/perl5'. Do not put
# a machine-specific path back. The line above localises HOME to a tempdir,
# which destroys any $HOME-relative resolution of the module path, and the
# literal was added to compensate - the two lines are adjacent for that reason.
#
# Do not inject a developer-local dependency directory here: the caller's
# PERL5LIB remains authoritative for prerequisites. `prove -l` adds blib to
# its own @INC but does not ensure shell-launched children inherit the current
# native extension path. When a built extension exists, place this checkout's
# blib paths first so an older installed Dashboard.so cannot satisfy HtmlEscape
# while omitting this build's GoRoutine XSUBs.
my @built_perl_libs = grep { -d $_ } map { File::Spec->catdir( $repo, 'blib', $_ ) } qw(arch lib);
local $ENV{PERL5LIB} = join Developer::Dashboard::PerlEnv::path_separator(), grep { defined && $_ ne '' } ( @built_perl_libs, $ENV{PERL5LIB} || () );
my $JAVA_TOOLCHAIN_SKIP_REASON = _java_toolchain_skip_reason();
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $perl = $^X;
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";
my $lib = File::Spec->catdir( $repo, 'lib' );
my $dashboard = File::Spec->catfile( $repo, 'bin', 'd2' );
my $built_dashboard_xs = File::Spec->catfile(
    $repo, 'blib', 'arch', 'auto', 'Developer', 'Dashboard', 'Dashboard.' . $Config::Config{dlext},
);
if ( -f $built_dashboard_xs ) {
    # The probe used to run as a -e one-liner, but on Windows the list-form
    # system() call rebuilds the command line and re-splits an argument that
    # holds both spaces and double quotes, so the child perl only saw
    # "print" as its program and exited 0 having printed nothing. Running
    # the probe from a file keeps the program intact on every platform, the
    # same approach the PSGI smoke program already takes.
    my $goroutine_xs_probe_file = File::Spec->catfile( $ENV{HOME}, 'goroutine-xs-probe.pl' );
    open my $goroutine_xs_probe_fh, '>', $goroutine_xs_probe_file or die "Unable to write $goroutine_xs_probe_file: $!";
    print {$goroutine_xs_probe_fh} <<'PERL';
use strict;
use warnings;
use Developer::Dashboard::GoRoutine;
print defined(&Developer::Dashboard::GoRoutine::spawn) ? "spawn\n" : "missing\n";
PERL
    close $goroutine_xs_probe_fh or die "Unable to close $goroutine_xs_probe_file: $!";
    my $goroutine_xs_probe = _run("$perl -I'$lib' -MDeveloper::Dashboard::GoRoutine '$goroutine_xs_probe_file'");
    is( $goroutine_xs_probe, "spawn\n", 'child Perl processes load GoRoutine XSUBs from the current build before an installed older XS copy' );
}
# Regression: an existing executable d2 entrypoint must not be
# prefixed with Perl. This also exercises the executable-file branch of
# CLI::Which::_dashboard_entry_command under Devel::Cover.
{
    require Developer::Dashboard::CLI::Which;
    my $entrypoint = File::Spec->catfile( $ENV{HOME}, 'which-executable-dashboard' );
    open my $entry_fh, '>', $entrypoint or die "Unable to create $entrypoint: $!";
    print {$entry_fh} "#!/bin/sh\nexit 0\n";
    close $entry_fh or die "Unable to close $entrypoint: $!";
    chmod 0755, $entrypoint or die "Unable to make $entrypoint executable: $!";
    SKIP: {
        skip 'Perl executable file test is not supported by this filesystem', 1
          if !-x $entrypoint;
        local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = $entrypoint;
        is_deeply(
            [ Developer::Dashboard::CLI::Which::_dashboard_entry_command() ],
            [$entrypoint],
            'which --edit invokes an existing executable dashboard directly',
        );
    }
}

my $expected_version = _module_version( File::Spec->catfile( $lib, 'Developer', 'Dashboard.pm' ) );
my $runtime_cli_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
my $runtime_dd_cli_root = File::Spec->catdir( $runtime_cli_root, 'dd' );
my $runtime_jq = File::Spec->catfile( $runtime_dd_cli_root, 'jq' );
my $runtime_yq = File::Spec->catfile( $runtime_dd_cli_root, 'yq' );
my $runtime_tomq = File::Spec->catfile( $runtime_dd_cli_root, 'tomq' );
my $runtime_propq = File::Spec->catfile( $runtime_dd_cli_root, 'propq' );
my $runtime_iniq = File::Spec->catfile( $runtime_dd_cli_root, 'iniq' );
my $runtime_csvq = File::Spec->catfile( $runtime_dd_cli_root, 'csvq' );
my $runtime_xmlq = File::Spec->catfile( $runtime_dd_cli_root, 'xmlq' );
my $runtime_of = File::Spec->catfile( $runtime_dd_cli_root, 'of' );
my $runtime_open_file = File::Spec->catfile( $runtime_dd_cli_root, 'open-file' );
my $runtime_workspace = File::Spec->catfile( $runtime_dd_cli_root, 'workspace' );
my $runtime_path = File::Spec->catfile( $runtime_dd_cli_root, 'path' );
my $runtime_paths = File::Spec->catfile( $runtime_dd_cli_root, 'paths' );
my $runtime_ps1 = File::Spec->catfile( $runtime_dd_cli_root, 'ps1' );
my $runtime_api = File::Spec->catfile( $runtime_dd_cli_root, 'api' );
my $runtime_doctor = File::Spec->catfile( $runtime_dd_cli_root, 'doctor' );
my $runtime_dashboard_core = File::Spec->catfile( $runtime_dd_cli_root, '_dashboard-core' );

my $init = _run("$perl -I'$lib' '$dashboard' init");
like($init, qr/runtime_root/, 'd2 init works');
for my $helper ( $runtime_jq, $runtime_yq, $runtime_tomq, $runtime_propq, $runtime_iniq, $runtime_csvq, $runtime_xmlq, $runtime_of, $runtime_open_file, $runtime_workspace, $runtime_path, $runtime_paths, $runtime_ps1, $runtime_api ) {
    ok( -f $helper, "d2 init seeds private helper $helper" );
    ok( _helper_is_executable($helper), "d2 init marks private helper $helper executable" );
}
ok( -f $runtime_dashboard_core, 'd2 init seeds the private built-in core helper runtime' );
ok( _helper_is_executable($runtime_dashboard_core), 'd2 init marks the private built-in core helper runtime executable' );
ok( !-e File::Spec->catfile( $runtime_cli_root, 'jq' ), 'd2 init does not mix built-in helpers into the user CLI root' );
my $global_config_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'config.json' );
open my $bootstrapped_config_fh, '<:raw', $global_config_file or die "Unable to read $global_config_file: $!";
my $bootstrapped_config_json = do { local $/; <$bootstrapped_config_fh> };
close $bootstrapped_config_fh;
is_deeply( json_decode($bootstrapped_config_json), {}, 'd2 init creates a missing config.json as an empty object' );
my $managed_jq_mtime_before = ( stat $runtime_jq )[9];
my $home_only_init_project = File::Spec->catdir( $ENV{HOME}, 'projects', 'home-only-init-project' );
my $home_only_local_cli = File::Spec->catdir( $home_only_init_project, '.developer-dashboard', 'cli' );
make_path( File::Spec->catdir( $home_only_init_project, '.git' ), $home_only_local_cli );
my $home_only_init = _run("cd '$home_only_init_project' && $perl -I'$lib' '$dashboard' init");
my $home_only_init_data = json_decode($home_only_init);
is( _portable_path( $home_only_init_data->{runtime_root} ),
    _portable_path( File::Spec->catdir( $home_only_init_project, '.developer-dashboard' ) ),
    'd2 init still reports the local runtime root when run inside a project layer' );
ok( !-e File::Spec->catfile( $home_only_local_cli, 'jq' ), 'd2 init does not offload built-in helpers into the local project CLI layer' );
ok( !-d File::Spec->catdir( $home_only_local_cli, 'dd' ), 'd2 init does not create a dd helper namespace in child CLI layers' );
ok( -f $runtime_jq, 'd2 init keeps the built-in helper staged at the home runtime dd helper root' );
make_path( File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config' ) );
open my $seeded_config_fh, '>:raw', $global_config_file or die "Unable to write $global_config_file: $!";
my $seeded_config_json = json_encode(
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
            {
                name      => 'docker.collector',
                command   => 'docker ps',
                cwd       => 'home',
                indicator => {
                    icon => '🐳',
                },
            },
        ],
    }
);
$seeded_config_json = encode( 'UTF-8', $seeded_config_json ) if utf8::is_utf8($seeded_config_json);
print {$seeded_config_fh} $seeded_config_json;
close $seeded_config_fh;

sleep 1.1;
my $reinit = _run("$perl -I'$lib' '$dashboard' init");
like($reinit, qr/config_file/, 'd2 init can be re-run after a config already exists');
is( ( stat $runtime_jq )[9], $managed_jq_mtime_before, 'd2 init skips rewriting a dashboard-managed helper when its md5 already matches the shipped helper content' );
open my $preserved_config_fh, '<:raw', $global_config_file or die "Unable to read $global_config_file: $!";
my $preserved_config_json = do { local $/; <$preserved_config_fh> };
close $preserved_config_fh;
is_deeply(
    json_decode($preserved_config_json),
    json_decode($seeded_config_json),
    'd2 init preserves an existing config.json instead of overwriting it',
);
{
    my $preserve_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $preserve_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $preserve_cli_root = File::Spec->catdir( $preserve_home, '.developer-dashboard', 'cli' );
    make_path($preserve_cli_root);
    my $preserve_dd_cli_root = File::Spec->catdir( $preserve_cli_root, 'dd' );
    my $user_owned_jq = File::Spec->catfile( $preserve_cli_root, 'jq' );
    open my $user_owned_jq_fh, '>', $user_owned_jq or die "Unable to write $user_owned_jq: $!";
    print {$user_owned_jq_fh} "#!/usr/bin/env perl\nprint qq(user-owned-jq\\n);\n";
    close $user_owned_jq_fh;
    chmod 0755, $user_owned_jq or die "Unable to chmod $user_owned_jq: $!";
    my $user_cli_note = File::Spec->catfile( $preserve_cli_root, 'keep-me.txt' );
    open my $user_cli_note_fh, '>', $user_cli_note or die "Unable to write $user_cli_note: $!";
    print {$user_cli_note_fh} "keep me\n";
    close $user_cli_note_fh;

    my $preserve_user_cli = _run_in_home( $preserve_home, "$perl -I'$lib' '$dashboard' init" );
    like( $preserve_user_cli, qr/config_file/, 'd2 init can be re-run when user-owned files already exist in the home runtime CLI root' );
    open my $preserved_user_jq_fh, '<', $user_owned_jq or die "Unable to read $user_owned_jq: $!";
    my $preserved_user_jq = do { local $/; <$preserved_user_jq_fh> };
    close $preserved_user_jq_fh;
    is( $preserved_user_jq, "#!/usr/bin/env perl\nprint qq(user-owned-jq\\n);\n", 'd2 init preserves a pre-existing user CLI command in ~/.developer-dashboard/cli' );
    ok( -f $user_cli_note, 'd2 init does not delete unrelated files from ~/.developer-dashboard/cli' );
    ok( -f File::Spec->catfile( $preserve_dd_cli_root, 'jq' ), 'd2 init stages the built-in jq helper into ~/.developer-dashboard/cli/dd' );
    is( _run(qq{printf '{"foo":"bar"}' | $perl -I'$lib' '$dashboard' jq foo}), "bar\n", 'd2 jq runs the built-in dd helper without mixing with the user CLI root' );
}
{
    my $config_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $config_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $config_init_file = _run_in_home( $config_home, "$perl -I'$lib' '$dashboard' config init" );
    chomp $config_init_file;
    is( $config_init_file, File::Spec->catfile( $config_home, '.developer-dashboard', 'config', 'config.json' ), 'd2 config init reports the writable home config path' );
    open my $config_init_fh, '<:raw', $config_init_file or die "Unable to read $config_init_file: $!";
    my $config_init_json = do { local $/; <$config_init_fh> };
    close $config_init_fh;
    is_deeply( json_decode($config_init_json), {}, 'd2 config init creates an empty object when config.json is missing' );
    my $config_mtime_before = ( stat $config_init_file )[9];

    sleep 1.1;
    my $config_reinit_file = _run_in_home( $config_home, "$perl -I'$lib' '$dashboard' config init" );
    chomp $config_reinit_file;
    is( $config_reinit_file, $config_init_file, 'd2 config init reports the same config path on rerun' );
    is( ( stat $config_init_file )[9], $config_mtime_before, 'd2 config init leaves an existing config.json untouched on rerun' );
}

my $pages = _run("$perl -I'$lib' '$dashboard' page list");
is_deeply(
    json_decode($pages),
    [ 'project-context', 'system-status' ],
    'd2 init seeds only the remaining core starter pages',
);

my $tt_page_instruction = <<'BOOKMARK';
TITLE: TT CLI Demo
:--------------------------------------------------------------------------------:
BOOKMARK: tt-cli-demo
:--------------------------------------------------------------------------------:
STASH: foo => 42
:--------------------------------------------------------------------------------:
HTML: <h1>[% title %]</h1> [% stash.foo %]
BOOKMARK
my $tt_page_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'dashboards', 'tt-cli-demo' );
open my $tt_page_fh, '>', $tt_page_file or die "Unable to write $tt_page_file: $!";
print {$tt_page_fh} $tt_page_instruction;
close $tt_page_fh;
my $tt_page_render = _run("$perl -I'$lib' '$dashboard' page render tt-cli-demo");
like( $tt_page_render, qr{<h1>\s*TT CLI Demo\s*</h1>\s*42}s, 'd2 page render applies Template Toolkit to saved bookmark HTML before rendering' );
unlike( $tt_page_render, qr/\[%\s*title\s*%\]|\[%\s*stash\.foo\s*%\]/, 'd2 page render does not leave raw TT placeholders in the rendered HTML output' );
my $broken_tt_page_instruction = <<'BOOKMARK';
TITLE: Broken TT CLI Demo
:--------------------------------------------------------------------------------:
BOOKMARK: tt-cli-broken
:--------------------------------------------------------------------------------:
HTML: <div>before [% IF stash.foo %] broken</div>
BOOKMARK
my $broken_tt_page_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'dashboards', 'tt-cli-broken' );
open my $broken_tt_page_fh, '>', $broken_tt_page_file or die "Unable to write $broken_tt_page_file: $!";
print {$broken_tt_page_fh} $broken_tt_page_instruction;
close $broken_tt_page_fh;
my $broken_tt_page_render = _run("$perl -I'$lib' '$dashboard' page render tt-cli-broken");
like( $broken_tt_page_render, qr/runtime-error/, 'd2 page render surfaces Template Toolkit syntax failures as runtime errors' );
unlike( $broken_tt_page_render, qr/\[%\s*IF\s+stash\.foo\s*%\]/, 'd2 page render does not leak raw TT syntax after a Template Toolkit parse failure' );

my $auth_add = _run("$perl -I'$lib' '$dashboard' auth add-user helper helper-pass-123");
SKIP: {
    skip 'the local macOS Perl refuses to load libcrypto safely for password hashing', 2
      if $auth_add =~ /loading libcrypto in an unsafe way/;
    like($auth_add, qr/"username"\s*:\s*"helper"/, 'auth add-user works');

    my $auth_list = _run("$perl -I'$lib' '$dashboard' auth list-users");
    like($auth_list, qr/"username"\s*:\s*"helper"/, 'auth list-users works');
}

my $api_list_table = _run("$perl -I'$lib' '$dashboard' api");
like( $api_list_table, qr/^Key\s+Secret\s+Route/m, 'd2 api defaults to a table listing' );

my $api_add_table = _run("$perl -I'$lib' '$dashboard' api add --key helper-bot --secret helper-secret --route /ajax/health --route /ajax/status");
like( $api_add_table, qr/^Key\s+Secret\s+Route/m, 'd2 api add defaults to a table summary' );
like( $api_add_table, qr/helper-bot\s+\S+\s+\/ajax\/health/, 'd2 api add table summary lists the first allowed route' );
my $api_add_secret = json_decode( _run("$perl -I'$lib' '$dashboard' api add --key helper-bot --secret helper-secret --route /ajax/health --route /ajax/status -o json") );
is( $api_add_secret->{file}, File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'api.json' ), 'd2 api add writes to the home runtime when no deeper layer participates' );
is( $api_add_secret->{api}{'helper-bot'}{secret}, sha256_hex('helper-secret'), 'd2 api add hashes raw secrets before saving them' );
is_deeply( $api_add_secret->{api}{'helper-bot'}{ajax}, [ '/ajax/health', '/ajax/status' ], 'd2 api add can create an API key and multiple routes in one command' );

my $api_add_route = json_decode( _run("$perl -I'$lib' '$dashboard' api add --key helper-bot --route /ajax/health -o json") );
is_deeply( $api_add_route->{api}{'helper-bot'}{ajax}, [ '/ajax/health', '/ajax/status' ], 'd2 api add keeps the existing route set unchanged when a repeated route is requested' );

my $api_duplicate_route = json_decode( _run("$perl -I'$lib' '$dashboard' api add --key helper-bot --route /ajax/health -o json") );
ok( !$api_duplicate_route->{changed}, 'd2 api add reports no change when a route already exists' );

my $api_update_secret = json_decode( _run("$perl -I'$lib' '$dashboard' api add --key helper-bot --secret rotated-secret -o json") );
is( $api_update_secret->{api}{'helper-bot'}{secret}, sha256_hex('rotated-secret'), 'd2 api add updates an existing key secret' );

my $api_maybe_secret = json_decode( _run("$perl -I'$lib' '$dashboard' api add --key helper-bot --maybe-secret maybe-secret --route /ajax/extra -o json") );
is( $api_maybe_secret->{api}{'helper-bot'}{secret}, sha256_hex('maybe-secret'), 'd2 api add updates an existing key secret through --maybe-secret' );
is_deeply( $api_maybe_secret->{api}{'helper-bot'}{ajax}, [ '/ajax/health', '/ajax/status', '/ajax/extra' ], 'd2 api add can append routes while using --maybe-secret' );

my $api_filtered = json_decode( _run("$perl -I'$lib' '$dashboard' api ls --key helper-bot -o json") );
is_deeply(
    $api_filtered->{api}{'helper-bot'},
    {
        secret => sha256_hex('maybe-secret'),
        ajax   => [ '/ajax/health', '/ajax/status', '/ajax/extra' ],
    },
    'd2 api ls --key returns the targeted API group as JSON',
);

my $api_remove_route = json_decode( _run("$perl -I'$lib' '$dashboard' api rm --key helper-bot --route /ajax/status -o json") );
is_deeply( $api_remove_route->{api}{'helper-bot'}{ajax}, [ '/ajax/health', '/ajax/extra' ], 'd2 api rm removes one route while keeping the remaining routes and key' );

my $api_project = File::Spec->catdir( $ENV{HOME}, 'projects', 'api-cli-layer' );
make_path( File::Spec->catdir( $api_project, '.git' ), File::Spec->catdir( $api_project, '.developer-dashboard', 'config' ) );
my $api_home_seed = json_decode( _run("$perl -I'$lib' '$dashboard' api add --key inherited-bot --secret inherited-secret --route /ajax/inherited -o json") );
is( $api_home_seed->{file}, File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'api.json' ), 'd2 api seed for inherited smoke coverage stays in the home runtime' );

my $api_project_add = json_decode( _run_in_dir( $api_project, "$perl -I'$lib' '$dashboard' api add --key project-bot --secret project-secret -o json" ) );
is( $api_project_add->{file}, File::Spec->catfile( $api_project, '.developer-dashboard', 'config', 'api.json' ), 'd2 api add writes to the deepest project layer under DD-OOP-LAYERS' );

my $api_project_remove = json_decode( _run_in_dir( $api_project, "$perl -I'$lib' '$dashboard' api rm --key inherited-bot -o json" ) );
ok( $api_project_remove->{changed}, 'd2 api rm can mask an inherited key from a project layer' );
my $api_project_hidden = json_decode( _run_in_dir( $api_project, "$perl -I'$lib' '$dashboard' api ls --key inherited-bot -o json" ) );
ok( !exists $api_project_hidden->{api}{'inherited-bot'}, 'd2 api ls hides inherited keys after a project-layer tombstone is written' );

my $legacy_bookmarks_root = File::Spec->catdir( $ENV{HOME}, 'bookmarks' );
make_path($legacy_bookmarks_root);
chmod 0755, $legacy_bookmarks_root or die "Unable to chmod $legacy_bookmarks_root: $!";
my $legacy_bookmark_file = File::Spec->catfile( $legacy_bookmarks_root, 'legacy.txt' );
open my $legacy_bookmark_fh, '>', $legacy_bookmark_file or die "Unable to write $legacy_bookmark_file: $!";
print {$legacy_bookmark_fh} "legacy\n";
close $legacy_bookmark_fh;
chmod 0644, $legacy_bookmark_file or die "Unable to chmod $legacy_bookmark_file: $!";

my $doctor_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'doctor.d' );
make_path($doctor_hook_root);
my $doctor_hook = File::Spec->catfile( $doctor_hook_root, '00-extra.pl' );
open my $doctor_hook_fh, '>', $doctor_hook or die "Unable to write $doctor_hook: $!";
print {$doctor_hook_fh} <<'PL';
#!/usr/bin/env perl
print "doctor-hook-ok\n";
PL
close $doctor_hook_fh;
chmod 0700, $doctor_hook or die "Unable to chmod $doctor_hook: $!";

my $doctor_report = json_decode( _run("$perl -I'$lib' '$dashboard' doctor") );

# The doctor audits owner-only permission modes on every platform now
# (Windows via icacls since the ACL work): the loose bookmark modes are
# findings everywhere, so the report is not clean before repair.
ok( !$doctor_report->{ok}, 'd2 doctor reports insecure legacy permissions before repair' );
ok(
    grep(
        { $_->{path} eq $legacy_bookmarks_root && $_->{expected_mode} eq '0700' }
          @{ $doctor_report->{issues} || [] }
    ),
    'd2 doctor reports insecure legacy bookmark directories',
);
ok(
    grep(
        { $_->{path} eq $legacy_bookmark_file && $_->{expected_mode} eq '0600' }
          @{ $doctor_report->{issues} || [] }
    ),
    'd2 doctor reports insecure legacy bookmark files',
);
ok(
    grep(
        { ref($_) eq 'HASH' && $_->{stdout} && $_->{stdout} =~ /^doctor-hook-ok\r?\n$/ }
        values %{ $doctor_report->{hooks} || {} }
    ),
    'd2 doctor includes hook stdout in RESULT-backed output',
);

my $doctor_fixed = json_decode( _run("$perl -I'$lib' '$dashboard' doctor --fix") );
ok( !$doctor_fixed->{ok}, 'd2 doctor --fix still reports the findings it repaired in that run' );
# stat() cannot see the ACL repair on Windows (the mode bits stay 0777/0666
# after icacls), so read the DACL-derived mode there instead - the same
# judgement the doctor itself makes.
if ( $^O eq 'MSWin32' ) {
    is( effective_mode_octal($legacy_bookmarks_root), '0700', 'd2 doctor --fix tightens legacy bookmark directory permissions' );
    is( effective_mode_octal($legacy_bookmark_file), '0600', 'd2 doctor --fix tightens legacy bookmark file permissions' );
}
else {
    is( sprintf( '%04o', ( stat($legacy_bookmarks_root) )[2] & 07777 ), '0700', 'd2 doctor --fix tightens legacy bookmark directory permissions' );
    is( sprintf( '%04o', ( stat($legacy_bookmark_file) )[2] & 07777 ), '0600', 'd2 doctor --fix tightens legacy bookmark file permissions' );
}
my $doctor_clean = json_decode( _run("$perl -I'$lib' '$dashboard' doctor") );
ok( $doctor_clean->{ok}, 'd2 doctor reports success after repair' );

# Save the staged core's bytes before clobbering them: the test process
# loads InternalCLI from the node's stale blib tree, so
# _managed_helper_content() returns the OLD core while the doctor
# subprocess (fresh dd-source) expects the NEW one. The staged file is
# provably the expected content (the doctor run above reported ok=1), so
# build the drift from the saved bytes.
open my $managed_core_saved_fh, '<:raw', $runtime_dashboard_core or die "Unable to read $runtime_dashboard_core: $!";
my $managed_core_saved = do { local $/; <$managed_core_saved_fh> };
close $managed_core_saved_fh or die "Unable to close $runtime_dashboard_core: $!";
my $managed_core_stale = $managed_core_saved;
$managed_core_stale .= "\n# stale helper drift\n";
open my $managed_core_stale_fh, '>:raw', $runtime_dashboard_core or die "Unable to write $runtime_dashboard_core: $!";
print {$managed_core_stale_fh} $managed_core_stale;
close $managed_core_stale_fh or die "Unable to close $runtime_dashboard_core: $!";

my $doctor_helper_report = json_decode( _run("$perl -I'$lib' '$runtime_doctor'") );
ok( !$doctor_helper_report->{ok}, 'd2 doctor reports stale managed helper drift' );
ok(
    grep(
        {
            $_->{path} eq $runtime_dashboard_core
              && $_->{kind} eq 'helper'
              && $_->{problem} eq 'stale managed helper content'
        } @{ $doctor_helper_report->{issues} || [] }
    ),
    'd2 doctor reports stale _dashboard-core helper drift through the staged helper runtime',
);

my $doctor_helper_fixed = json_decode( _run("$perl -I'$lib' '$runtime_doctor' --fix") );
ok( !$doctor_helper_fixed->{ok}, 'd2 doctor --fix reports the helper drift it repaired in that run' );
# The _dashboard-core restage is no longer blanket-deferred on Windows:
# the lock probe finds the staged helper unlocked here, so --fix repairs
# the drift on every platform.
ok(
    grep(
        {
            $_->{path} eq $runtime_dashboard_core
              && $_->{kind} eq 'helper'
              && $_->{fixed}
        } @{ $doctor_helper_fixed->{issues} || [] }
    ),
    'd2 doctor --fix marks stale helper drift as repaired through the staged helper runtime',
);
my $doctor_helper_clean = json_decode( _run("$perl -I'$lib' '$runtime_doctor'") );
ok( $doctor_helper_clean->{ok}, 'd2 doctor reports success after helper restaging repair' );

my $bashrc = File::Spec->catfile( $ENV{HOME}, '.bashrc' );
my $local_lib_line = qq{eval "\$("/usr/bin/perl" -I "$ENV{HOME}/perl5/lib/perl5" -Mlocal::lib)"};
my $dashboard_line = qq{eval "\$("$ENV{HOME}/perl5/bin/d2" shell bash)"};
open my $bashrc_fh, '>', $bashrc or die "Unable to write $bashrc: $!";
print {$bashrc_fh} <<"BASHRC";
[ -z "\$PS1" ] && return
$local_lib_line
$dashboard_line
BASHRC
close $bashrc_fh or die "Unable to close $bashrc: $!";

my $doctor_shell_report = json_decode( _run("$perl -I'$lib' '$runtime_doctor'") );
ok( !$doctor_shell_report->{ok}, 'd2 doctor reports misplaced bash bootstrap lines through the staged helper runtime' );
ok(
    grep(
        {
            $_->{path} eq $bashrc
              && $_->{kind} eq 'shell-bootstrap'
              && $_->{problem} eq 'dashboard-managed bash bootstrap is hidden behind the non-interactive return guard'
        } @{ $doctor_shell_report->{issues} || [] }
    ),
    'd2 doctor reports the misplaced bash bootstrap issue through the staged helper runtime',
);

my $doctor_shell_fixed = json_decode( _run("$perl -I'$lib' '$runtime_doctor' --fix") );
ok( !$doctor_shell_fixed->{ok}, 'd2 doctor --fix reports the bash bootstrap issue it repaired through the staged helper runtime' );
ok(
    grep(
        {
            $_->{path} eq $bashrc
              && $_->{kind} eq 'shell-bootstrap'
              && $_->{fixed}
        } @{ $doctor_shell_fixed->{issues} || [] }
    ),
    'd2 doctor --fix marks the misplaced bash bootstrap issue as fixed through the staged helper runtime',
);
my $doctor_shell_clean = json_decode( _run("$perl -I'$lib' '$runtime_doctor'") );
ok( $doctor_shell_clean->{ok}, 'd2 doctor reports success after repairing misplaced bash bootstrap lines' );
unlink $bashrc or die "Unable to remove $bashrc after doctor shell-bootstrap smoke coverage: $!";

my $indicator_refresh = _run("$perl -I'$lib' '$dashboard' indicator refresh-core");
like($indicator_refresh, qr/docker|project|git/, 'indicator refresh-core works');

my $fake_tmux_dir = File::Spec->catdir( $ENV{HOME}, 'fake-bin' );
make_path($fake_tmux_dir);
my $fake_tmux_log = File::Spec->catfile( $ENV{HOME}, 'fake-tmux.log' );

# The fake tmux must be runnable by the platform that runs the product:
# a #!/bin/sh script cannot run where there is no sh. On Windows it is a
# .cmd file instead, which the product's direct system() call finds through
# PATHEXT. The PATH joins below use the platform separator for the same
# reason: joining with ':' mangles the drive-letter entries of a Windows
# PATH, so the fake bin directory would never be reached.
my $path_sep = Developer::Dashboard::PerlEnv::path_separator();
my $fake_tmux;
if ( $^O eq 'MSWin32' ) {
    $fake_tmux = File::Spec->catfile( $fake_tmux_dir, 'tmux.cmd' );
    open my $fake_tmux_fh, '>', $fake_tmux or die "Unable to write $fake_tmux: $!";
    print {$fake_tmux_fh} <<"CMD";
\@echo off
echo %* >> "$fake_tmux_log"
if "%1"=="show-environment" if "%2"=="TICKET_REF" echo TICKET_REF=DD-123
if "%1"=="show-environment" if "%2"=="TICKET_REF" exit /b 0
exit /b 1
CMD
    close $fake_tmux_fh or die "Unable to close $fake_tmux: $!";
}
else {
    $fake_tmux = File::Spec->catfile( $fake_tmux_dir, 'tmux' );
    open my $fake_tmux_fh, '>', $fake_tmux or die "Unable to write $fake_tmux: $!";
    print {$fake_tmux_fh} <<"SH";
#!/bin/sh
printf '%s\n' "\$*" >> '$fake_tmux_log'
if [ "\$1" = "show-environment" ] && [ "\$2" = "TICKET_REF" ]; then
  printf 'TICKET_REF=DD-123\n'
  exit 0
fi
exit 1
SH
    close $fake_tmux_fh or die "Unable to close $fake_tmux: $!";
    chmod 0755, $fake_tmux or die "Unable to chmod $fake_tmux: $!";
}
local $ENV{PATH} = join $path_sep, $fake_tmux_dir, ( $ENV{PATH} || () );
local $ENV{TICKET_REF};
local $ENV{WORKSPACE_REF};
local $ENV{TMUX} = '';

my $ps1 = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1");
like($ps1, qr/\(1 jobs\)|developer-dashboard:master| D /, 'ps1 command works');
like($ps1, qr/🚨🔑/, 'ps1 seeds configured collector indicators before their first run');
like($ps1, qr/🚨🐳/, 'ps1 shows all configured collector indicators, not just previously-run collectors');
unlike($ps1, qr/🎫:DD-123/, 'ps1 does not probe tmux for ticket context when TMUX is unset');
ok( !-e $fake_tmux_log || _run("cat '$fake_tmux_log'") eq '', 'ps1 skips tmux show-environment entirely when TMUX is unset' );
local $ENV{TMUX} = 'tmux-session';
my $tmux_ps1 = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1");
like($tmux_ps1, qr/🎫:DD-123/, 'ps1 loads the ticket from the tmux session environment when TMUX is active and TICKET_REF is not already exported');
my $ps1_extended = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1 --mode extended --color");
like($ps1_extended, qr/\e\[|\(1 jobs\)/, 'ps1 supports extended/color modes');
{
    my $fake_git_repo = File::Spec->catdir( $ENV{HOME}, 'prompt-head-repo' );
    my $fake_git_meta = File::Spec->catdir( $fake_git_repo, '.git', 'refs', 'heads' );
    my $fake_git_bin_dir = File::Spec->catdir( $ENV{HOME}, 'fake-git-bin' );
    my $fake_git_log = File::Spec->catfile( $ENV{HOME}, 'fake-git.log' );
    make_path( $fake_git_meta, $fake_git_bin_dir );
    open my $fake_head_fh, '>', File::Spec->catfile( $fake_git_repo, '.git', 'HEAD' ) or die $!;
    print {$fake_head_fh} "ref: refs/heads/main\n";
    close $fake_head_fh;
    open my $fake_branch_fh, '>', File::Spec->catfile( $fake_git_meta, 'main' ) or die $!;
    print {$fake_branch_fh} "0123456789abcdef0123456789abcdef01234567\n";
    close $fake_branch_fh;
    my $fake_git = File::Spec->catfile( $fake_git_bin_dir, 'git' );
    open my $fake_git_fh, '>', $fake_git or die "Unable to write $fake_git: $!";
    print {$fake_git_fh} <<"SH";
#!/bin/sh
printf '%s\n' "\$*" >> '$fake_git_log'
exit 98
SH
    close $fake_git_fh;
    chmod 0755, $fake_git or die "Unable to chmod $fake_git: $!";

    local $ENV{PATH} = join $path_sep, $fake_git_bin_dir, $fake_tmux_dir, grep { defined && $_ ne '' } split /\Q$path_sep\E/, ( $ENV{PATH} || '' );
    local $ENV{TMUX} = '';
    unlink $fake_git_log if -e $fake_git_log;
    my $head_only_ps1 = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 0 --cwd '$fake_git_repo'");
    like( $head_only_ps1, qr/\Q🌿main\E/, 'ps1 reads the git branch from .git metadata without needing the git command' );
    ok( !-e $fake_git_log || _run("cat '$fake_git_log'") eq '', 'ps1 does not invoke git subprocesses when branch metadata is available on disk' );
}

my $collector_inspect = _run("$perl -I'$lib' '$dashboard' collector inspect docker.collector");
like($collector_inspect, qr/"job"|"status"/, 'collector inspect works');

my ( $usage_stdout, $usage_stderr, $usage_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard;
    return $? >> 8;
};
is( $usage_exit, 1, 'dashboard with no arguments exits with usage status' );
like( $usage_stdout . $usage_stderr, qr/SYNOPSIS|d2 init/, 'dashboard with no arguments renders POD-backed usage' );

my $help = _run("$perl -I'$lib' '$dashboard' help");
like($help, qr/^Available built-in commands:/m, 'd2 help renders the concise command index');
like($help, qr/^  d2 api \[ls\|add\|rm\] \[options\]/m, 'd2 help shows actionable usage for each built-in command');
like($help, qr/^  d2 version\b/m, 'd2 help includes the public version command');
unlike($help, qr/d2 skill <repo-name> <command>/, 'd2 help does not advertise the removed singular skill dispatcher');
my ( $invalid_cmd_stdout, $invalid_cmd_stderr, $invalid_cmd_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard, 'dcoekr';
    return $? >> 8;
};
is( $invalid_cmd_exit, 1, 'dashboard exits non-zero for an unknown top-level command' );
like( $invalid_cmd_stdout . $invalid_cmd_stderr, qr/Unknown d2 command 'dcoekr'/, 'dashboard reports the mistyped top-level command explicitly' );
like( $invalid_cmd_stdout . $invalid_cmd_stderr, qr/Did you mean:\s+d2 docker/s, 'dashboard suggests the closest built-in command for a mistyped top-level command' );
my ( $invalid_alias_stdout, $invalid_alias_stderr, $invalid_alias_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard, 'skils', 'list';
    return $? >> 8;
};
is( $invalid_alias_exit, 1, 'dashboard exits non-zero for another unknown top-level command typo' );
like( $invalid_alias_stdout . $invalid_alias_stderr, qr/Did you mean:\s+d2 skills/s, 'dashboard suggests the closest plural built-in command for another typo' );
like( $invalid_alias_stdout . $invalid_alias_stderr, qr/Usage:/, 'dashboard still prints the command list after typo guidance' );
my $complete_top = _run("$perl -I'$lib' '$dashboard' complete 1 dashboard do");
like( $complete_top, qr/^docker$/m, 'd2 complete suggests docker for top-level completion' );
like( $complete_top, qr/^doctor$/m, 'd2 complete suggests doctor for top-level completion' );
my $complete_top_alias = _run("$perl -I'$lib' '$dashboard' complete 1 d2 do");
like( $complete_top_alias, qr/^docker$/m, 'd2 complete suggests docker for the d2 alias as well' );
like( $complete_top_alias, qr/^doctor$/m, 'd2 complete suggests doctor for the d2 alias as well' );
my $complete_sub = _run("$perl -I'$lib' '$dashboard' complete 2 d2 docker co");
is( $complete_sub, "compose\n", 'd2 complete suggests docker subcommands' );
my $complete_docker = _run("$perl -I'$lib' '$dashboard' complete 2 d2 docker ''");
like( $complete_docker, qr/^development$/m, 'd2 complete exposes the docker development subcommand after d2 docker' );
my $complete_docker_development = _run("$perl -I'$lib' '$dashboard' complete 3 d2 docker development ''");
is( $complete_docker_development, "enable\ndisable\n", 'd2 complete exposes development enable and disable actions' );
my $docker_help = _run("$perl -I'$lib' '$dashboard' docker --help");
like( $docker_help, qr/^Usage: d2 docker/m, 'docker --help prints Docker command usage' );
like( $docker_help, qr/d2 docker development enable <service>/, 'docker --help documents development overlays' );
like( $docker_help, qr/compose-arguments\.\.\./, 'docker --help documents Compose passthrough' );
my $completion_skill_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'completion-skill', 'cli' );
make_path($completion_skill_root);
my $completion_skill_command = File::Spec->catfile( $completion_skill_root, 'run-test' );
open my $completion_skill_fh, '>', $completion_skill_command or die "Unable to write $completion_skill_command: $!";
print {$completion_skill_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{completion\\n};\n";
close $completion_skill_fh;
chmod 0755, $completion_skill_command or die "Unable to chmod $completion_skill_command: $!";
my $complete_skill = _run("$perl -I'$lib' '$dashboard' complete 1 dashboard completion-s");
like( $complete_skill, qr/^completion-skill\.run-test$/m, 'd2 complete suggests installed dotted skill commands' );

my $serve_workers_port = _find_free_port();
my $serve_workers = _run("$perl -I'$lib' '$dashboard' serve workers 3 --port $serve_workers_port");
like($serve_workers, qr/"workers"\s*:\s*3/, 'd2 serve workers persists the default worker count');
my ($serve_workers_pid) = $serve_workers =~ /"pid"\s*:\s*"?(\d+)"?/;
ok( !defined $serve_workers_pid || $serve_workers_pid =~ /^\d+$/, 'd2 serve workers returns a numeric pid when it starts a stopped web service' );
open my $workers_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
my $workers_config = do { local $/; <$workers_config_fh> };
close $workers_config_fh;
like( $workers_config, qr/"web"\s*:\s*\{\s*"workers"\s*:\s*3/s, 'd2 serve workers stores the default worker count in config' );
if ( defined $serve_workers_pid ) {
    my $serve_workers_stop = _run("$perl -I'$lib' '$dashboard' stop -o json");
    like(
        $serve_workers_stop,
        qr/"web"\s*:\s*\{\s*"details"\s*:\s*"dashboard web service"\s*,\s*"pid"\s*:\s*(?:null|\d+)\s*,\s*"status"\s*:\s*"stopped"/s,
        'd2 stop reports the service started by serve workers as stopped even when the managed pid has already disappeared from the final summary',
    );
}
else {
    pass('d2 serve workers reused an already-running managed web service instead of starting a new pid');
}
if ( !$UNDER_COVER ) {
    my $live_status_port = _find_free_port();
    my $live_status_pid;
    {
        local @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
        delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)} if _coverage_requested();
        $live_status_pid = Developer::Dashboard::GoRoutine::spawn(
            [ $perl, '-I' . $lib, $dashboard, 'serve', '--foreground', '--host', '127.0.0.1', '--port', $live_status_port ],
            {},
        );
    }
    my $status_ua = LWP::UserAgent->new( timeout => 5 );
    my $status_response;
    for ( 1 .. _startup_probe_attempts() ) {
        $status_response = $status_ua->get("http://127.0.0.1:$live_status_port/system/status");
        last if $status_response->is_success;
        sleep 0.25;
    }
    ok( $status_response && $status_response->is_success, 'live foreground runtime exposes the system status endpoint' );
    like( decode( 'UTF-8', $status_response->content ), qr/"alias"\s*:\s*"🔑"/, 'live foreground runtime syncs configured collector indicator icons into system status' );
    ok( Developer::Dashboard::GoRoutine::terminate_process( $live_status_pid, 'TERM' ),
        'live foreground status process stops through the GoRoutine process API' );

    # On Windows there is no signal delivery to another process, so
    # terminate_process ends it with TerminateProcess and the exit code is
    # the XS's 128+signal convention (143 for TERM, as on Unix when a
    # process dies by SIGTERM). A clean 0 is only possible where the
    # process can catch SIGTERM and exit itself.
    my $expected_reap = $^O eq 'MSWin32' ? 143 : 0;
    is( Developer::Dashboard::GoRoutine::wait_process($live_status_pid), $expected_reap,
        'live foreground status process shuts down cleanly and is reaped through the GoRoutine process API' );
}
my $dashboard_log_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'logs', 'dashboard.log' );
make_path( File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'logs' ) );
open my $dashboard_log_fh, '>', $dashboard_log_file or die "Unable to write $dashboard_log_file: $!";
print {$dashboard_log_fh} "starman boot line\nDancer2 boot line\n";
close $dashboard_log_fh;
my $serve_logs = _run("$perl -I'$lib' '$dashboard' serve logs");
like($serve_logs, qr/starman boot line/, 'd2 serve logs prints the web-service log content');
like($serve_logs, qr/Dancer2 boot line/, 'd2 serve logs includes Dancer2-side log lines');
my $serve_logs_tail = _run("$perl -I'$lib' '$dashboard' serve logs -n 1");
is($serve_logs_tail, "Dancer2 boot line\n", 'd2 serve logs -n prints only the requested trailing lines');
my $serve_logs_docker_tail = _run("$perl -I'$lib' '$dashboard' serve logs --tail=1");
is($serve_logs_docker_tail, "Dancer2 boot line\n", 'd2 serve logs --tail=N uses the shared Docker-style tail parser');
my $serve_logs_timestamps = _run("$perl -I'$lib' '$dashboard' serve logs -t --tail=1");
like( $serve_logs_timestamps, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ Dancer2 boot line\n\z/, 'd2 serve logs -t timestamps the tailed web log line' );
{
    require IPC::Open3;
    require Symbol;
    my $stderr_fh = Symbol::gensym();
    my $pid = IPC::Open3::open3( undef, my $stdout_fh, $stderr_fh, $perl, '-I' . $lib, $dashboard, 'serve', 'logs', '-f', '-n', '1' );
    my $first = <$stdout_fh>;
    is( $first, "Dancer2 boot line\n", 'd2 serve logs -f -n prints the requested trailing lines before following new output' );
    open my $append_fh, '>>', $dashboard_log_file or die "Unable to append $dashboard_log_file: $!";
    print {$append_fh} "followed line\n";
    close $append_fh;
    my $followed = <$stdout_fh>;
    is( $followed, "followed line\n", 'd2 serve logs -f streams appended log lines' );
    kill 'TERM', $pid;
    waitpid( $pid, 0 );
}
if ( !$UNDER_COVER ) {
    my $serve_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $serve_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $serve_init = _run_in_home( $serve_home, "$perl -I'$lib' '$dashboard' init" );
    like( $serve_init, qr/runtime_root/, 'isolated lifecycle smoke home initializes a runtime for serve/restart collector checks' );
    my $serve_config_file = File::Spec->catfile( $serve_home, '.developer-dashboard', 'config', 'config.json' );
    open my $serve_config_fh, '>:raw', $serve_config_file or die "Unable to write $serve_config_file: $!";
    my $serve_config_json = json_encode(
        {
            collectors => [
                {
                    name     => 'tick.collector',
                    command  => q{perl -MTime::HiRes=time -e 'printf qq{%.6f\n}, time'},
                    cwd      => 'home',
                    interval => 1,
                },
            ],
        }
    );
    $serve_config_json = encode( 'UTF-8', $serve_config_json ) if utf8::is_utf8($serve_config_json);
    print {$serve_config_fh} $serve_config_json;
    close $serve_config_fh;
    my $serve_port = _find_free_port();
    my $serve_json = json_decode( _run_in_home( $serve_home, "$perl -I'$lib' '$dashboard' serve --host 127.0.0.1 --port $serve_port" ) );
    ok( $serve_json->{pid}, 'd2 serve returns a managed web pid for the collector lifecycle smoke test' );
    # DD-801: this loop used to carry a second `last if` that re-tested
    # $first_stdout against the exact regex the first condition had already
    # rejected - it could never be the reason the loop exited, and its only
    # observable effect was a `collector status` subprocess (a full perl
    # startup) paid on every one of up to 160 iterations to evaluate a
    # condition that could not fire. One real check, one subprocess per
    # iteration, is what the loop actually needs.
    my $first_stdout = '';
    for ( 1 .. 160 ) {
        my $output = json_decode( _run_in_home( $serve_home, "$perl -I'$lib' '$dashboard' collector output tick.collector" ) );
        $first_stdout = $output->{stdout} || '';
        last if $first_stdout =~ /^\d+\.\d+\n$/;
        sleep 0.25;
    }
    like( $first_stdout, qr/^\d+\.\d+\n$/, 'd2 serve starts configured interval collectors so collector output begins changing without a separate restart' );
    my $restart_json = json_decode( _run_in_home( $serve_home, "$perl -I'$lib' '$dashboard' restart -o json --host 127.0.0.1 --port $serve_port" ) );
    ok( $restart_json->{web_pid}, 'd2 restart still returns a managed web pid in the collector lifecycle smoke test' );
    ok( kill( 0, $restart_json->{web_pid} ), 'd2 restart reports a live managed web pid in the collector lifecycle smoke test' );
    my $serve_ua = LWP::UserAgent->new( timeout => 5 );
    my $serve_health_response;
    for ( 1 .. _startup_probe_attempts() ) {
        $serve_health_response = $serve_ua->get("http://127.0.0.1:$serve_port/");
        last if $serve_health_response->code;
        sleep 0.25;
    }
    ok( $serve_health_response && $serve_health_response->code, 'd2 restart leaves the collector lifecycle web listener reachable on the restarted port' );
    my $second_stdout = '';
    for ( 1 .. 160 ) {
        my $output = json_decode( _run_in_home( $serve_home, "$perl -I'$lib' '$dashboard' collector output tick.collector" ) );
        $second_stdout = $output->{stdout} || '';
        last if $second_stdout =~ /^\d+\.\d+\n$/ && $second_stdout ne $first_stdout;
        sleep 0.25;
    }
    unlike( $second_stdout, qr/^\Q$first_stdout\E$/, 'd2 restart restarts collector loops and refreshes collector output after the serve-started run' );
    my $serve_stop = json_decode( _run_in_home( $serve_home, "$perl -I'$lib' '$dashboard' stop -o json" ) );
    ok( ref( $serve_stop->{collectors} ) eq 'ARRAY', 'd2 stop still returns the collector stop list after serve/restart lifecycle control' );
    my $serve_stop_response = $serve_ua->get("http://127.0.0.1:$serve_port/");
    ok( !$serve_stop_response->is_success, 'd2 stop actually tears down the restarted collector lifecycle web listener' );
}
if ( !$UNDER_COVER ) {
    my $readonly_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $readonly_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $readonly_init = _run_in_home( $readonly_home, "$perl -I'$lib' '$dashboard' init" );
    like( $readonly_init, qr/runtime_root/, 'isolated no-editor smoke home initializes a runtime' );
    my $readonly_source = _run_in_home( $readonly_home, "$perl -I'$lib' '$dashboard' page new readonly 'Read Only'" );
    my $readonly_source_file = File::Spec->catfile( $readonly_home, 'readonly.page' );
    open my $readonly_source_fh, '>:raw', $readonly_source_file or die "Unable to write $readonly_source_file: $!";
    print {$readonly_source_fh} $readonly_source;
    close $readonly_source_fh;
    _run_in_home( $readonly_home, "$perl -I'$lib' '$dashboard' page save readonly < '$readonly_source_file'" );
    my $readonly_port = _find_free_port();
    my $readonly_serve = json_decode( _run_in_home( $readonly_home, "$perl -I'$lib' '$dashboard' serve --host 127.0.0.1 --port $readonly_port --no-endit" ) );
    ok( $readonly_serve->{pid}, 'd2 serve --no-endit starts the managed web service' );
    my $readonly_ua = LWP::UserAgent->new( timeout => 5 );
    my $readonly_ready_response;
    for ( 1 .. 240 ) {
        $readonly_ready_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/system/status");
        last if $readonly_ready_response->is_success;
        sleep 0.25;
    }
    ok( $readonly_ready_response && $readonly_ready_response->is_success, 'no-editor live server exposes the system status route before route assertions begin' );
    my $render_response;
    for ( 1 .. 240 ) {
        $render_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly");
        last if $render_response->is_success;
        sleep 0.25;
    }
    ok( $render_response && $render_response->is_success, 'no-editor live server serves saved page render routes' );
    my $render_body = decode( 'UTF-8', $render_response->decoded_content );
    unlike( $render_body, qr/id="share-url"/, 'no-editor live server hides the share link from render views' );
    unlike( $render_body, qr/id="view-source-url"/, 'no-editor live server hides the view-source link from render views' );
    unlike( $render_body, qr/id="play-url"/, 'no-editor live server hides the play link from render views' );
    my $edit_response;
    for ( 1 .. 240 ) {
        $edit_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly/edit");
        last if $edit_response->code == 403;
        sleep 0.25;
    }
    is( $edit_response->code, 403, 'no-editor live server blocks direct bookmark editor routes' );
    my $edit_post_response;
    for ( 1 .. 240 ) {
        $edit_post_response = $readonly_ua->post(
            "http://127.0.0.1:$readonly_port/app/readonly/edit",
            { instruction => "TITLE: Changed\n:--------------------------------------------------------------------------------:\nBOOKMARK: readonly\n:--------------------------------------------------------------------------------:\nHTML: changed\n" },
        );
        last if $edit_post_response->code == 403;
        sleep 0.25;
    }
    is( $edit_post_response->code, 403, 'no-editor live server blocks bookmark editor post saves' );
    my $readonly_config_file = File::Spec->catfile( $readonly_home, '.developer-dashboard', 'config', 'config.json' );
    open my $readonly_config_fh, '<', $readonly_config_file or die "Unable to read $readonly_config_file: $!";
    my $readonly_config = do { local $/; <$readonly_config_fh> };
    close $readonly_config_fh;
    like( $readonly_config, qr/"web"\s*:\s*\{[\s\S]*"no_editor"\s*:\s*1/s, 'd2 serve --no-endit persists no_editor in config' );
    my $readonly_restart = json_decode( _run_in_home( $readonly_home, "$perl -I'$lib' '$dashboard' restart -o json --host 127.0.0.1 --port $readonly_port" ) );
    ok( $readonly_restart->{web_pid}, 'd2 restart keeps managing the no-editor web service' );
    for ( 1 .. _startup_probe_attempts() ) {
        my $ready_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly");
        last if $ready_response->is_success;
        sleep 0.25;
    }
    my $source_response = $readonly_ua->get("http://127.0.0.1:$readonly_port/app/readonly/source");
    is( $source_response->code, 403, 'd2 restart preserves the saved no-editor source block' );
    my $readonly_stop = json_decode( _run_in_home( $readonly_home, "$perl -I'$lib' '$dashboard' stop -o json" ) );
    ok( ref( $readonly_stop->{collectors} ) eq 'ARRAY', 'd2 stop still works after a no-editor lifecycle run' );
}
if ( !$UNDER_COVER ) {
    my $noind_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $noind_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $noind_init = _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' init" );
    like( $noind_init, qr/runtime_root/, 'isolated no-indicators smoke home initializes a runtime' );
    my $noind_source = _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' page new noind 'No Indicators'" );
    my $noind_source_file = File::Spec->catfile( $noind_home, 'noind.page' );
    open my $noind_source_fh, '>:raw', $noind_source_file or die "Unable to write $noind_source_file: $!";
    print {$noind_source_fh} $noind_source;
    close $noind_source_fh;
    _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' page save noind < '$noind_source_file'" );
    my $noind_port = _find_free_port();
    my $noind_serve = json_decode( _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' serve --host 127.0.0.1 --port $noind_port --no-indicator" ) );
    ok( $noind_serve->{pid}, 'd2 serve --no-indicator starts the managed web service' );
    my $noind_ua = LWP::UserAgent->new( timeout => 5 );
    my $noind_ready_response;
    for ( 1 .. 240 ) {
        $noind_ready_response = $noind_ua->get("http://127.0.0.1:$noind_port/system/status");
        last if $noind_ready_response->is_success;
        sleep 0.25;
    }
    ok( $noind_ready_response && $noind_ready_response->is_success, 'no-indicators live server exposes the system status route before route assertions begin' );
    my $noind_render_response;
    for ( 1 .. 240 ) {
        $noind_render_response = $noind_ua->get("http://127.0.0.1:$noind_port/app/noind");
        last if $noind_render_response->is_success;
        sleep 0.25;
    }
    ok( $noind_render_response && $noind_render_response->is_success, 'no-indicators live server serves saved page render routes' );
    my $noind_render_body = decode( 'UTF-8', $noind_render_response->decoded_content );
    unlike( $noind_render_body, qr/id="status-on-top"/, 'no-indicators live server hides the top-right indicator strip' );
    unlike( $noind_render_body, qr/id="status-datetime"/, 'no-indicators live server hides the top-right date-time marker' );
    unlike( $noind_render_body, qr/id="status-server"/, 'no-indicators live server hides the top-right server marker' );
    unlike( $noind_render_body, qr/class="user-name-and-icon"/, 'no-indicators live server hides the top-right user marker' );
    my $noind_status_response;
    for ( 1 .. 240 ) {
        $noind_status_response = $noind_ua->get("http://127.0.0.1:$noind_port/system/status");
        last if $noind_status_response->code == 200;
        sleep 0.25;
    }
    is( $noind_status_response->code, 200, 'no-indicators live server keeps the status endpoint available' );
    like( decode( 'UTF-8', $noind_status_response->decoded_content ), qr/"array"\s*:/, 'no-indicators live server still exposes status payload data' );
    my $noind_ps1 = _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' ps1 --jobs 0" );
    like( $noind_ps1, qr/\S/, 'no-indicators mode does not blank the terminal prompt output' );
    my $noind_config_file = File::Spec->catfile( $noind_home, '.developer-dashboard', 'config', 'config.json' );
    open my $noind_config_fh, '<', $noind_config_file or die "Unable to read $noind_config_file: $!";
    my $noind_config = do { local $/; <$noind_config_fh> };
    close $noind_config_fh;
    like( $noind_config, qr/"web"\s*:\s*\{[\s\S]*"no_indicators"\s*:\s*1/s, 'd2 serve --no-indicator persists no_indicators in config' );
    my $noind_restart = json_decode( _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' restart -o json --host 127.0.0.1 --port $noind_port" ) );
    ok( $noind_restart->{web_pid}, 'd2 restart keeps managing the no-indicators web service' );
    my $post_restart_render;
    for ( 1 .. 240 ) {
        $post_restart_render = $noind_ua->get("http://127.0.0.1:$noind_port/app/noind");
        last if $post_restart_render->is_success;
        sleep 0.25;
    }
    ok( $post_restart_render && $post_restart_render->is_success, 'no-indicators live server remains reachable after restart' );
    my $post_restart_body = decode( 'UTF-8', $post_restart_render->decoded_content );
    unlike( $post_restart_body, qr/id="status-on-top"/, 'd2 restart preserves the no-indicators top-right strip removal' );
    my $noind_stop = json_decode( _run_in_home( $noind_home, "$perl -I'$lib' '$dashboard' stop -o json" ) );
    ok( ref( $noind_stop->{collectors} ) eq 'ARRAY', 'd2 stop still works after a no-indicators lifecycle run' );
}
{
    my $collector_log_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $collector_log_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $collector_init = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' init" );
    like( $collector_init, qr/runtime_root/, 'isolated collector-log smoke home initializes a runtime' );
    my $collector_config_file = File::Spec->catfile( $collector_log_home, '.developer-dashboard', 'config', 'config.json' );
    open my $collector_config_fh, '>:raw', $collector_config_file or die "Unable to write $collector_config_file: $!";
    my $collector_config_json = json_encode(
        {
            collectors => [
                {
                    name    => 'cli.collector',
                    # printf does not exist on the Windows job PATH and
                    # collector commands run through PowerShell there, so
                    # use a portable perl -e with byte-identical output
                    # (stdout and stderr) instead. The old printf shape
                    # passed on Windows only vacuously: the PowerShell
                    # error text echoed the command line, so the log
                    # assertions below matched without any real output.
                    command => q{perl -e "print qq(cli stdout\n); print STDERR qq(cli stderr\n)"},
                    cwd     => 'home',
                },
                {
                    name    => 'pending.collector',
                    command => q{printf 'pending\n'},
                    cwd     => 'home',
                },
                {
                    name    => 'templated.collector',
                    # printf does not exist on the Windows job PATH and
                    # collector commands run through PowerShell there, so
                    # use a portable perl -e with byte-identical output
                    # instead (same shape as the t/07 TT JSON fixture).
                    command => q{perl -e "print qq({\"a\":123})"},
                    cwd     => 'home',
                    indicator => {
                        name  => 'templated.indicator',
                        label => 'Templated',
                        icon  => '[% a %]',
                    },
                },
                {
                    name      => 'housekeeper',
                    interval  => 30,
                    indicator => {
                        icon => 'HK',
                    },
                },
                {
                    name     => 'rotating.collector',
                    command  => q{printf 'rotate\n'},
                    cwd      => 'home',
                    rotation => {
                        lines => 4,
                    },
                },
            ],
        }
    );
    $collector_config_json = encode( 'UTF-8', $collector_config_json ) if utf8::is_utf8($collector_config_json);
    print {$collector_config_fh} $collector_config_json;
    close $collector_config_fh;

    my $collector_run = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector run cli.collector" ) );
    is( $collector_run->{name}, 'cli.collector', 'd2 collector run returns the requested collector payload before log inspection' );

    my $named_log = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector log cli.collector" );
    like( $named_log, qr/cli\.collector/, 'd2 collector log <name> resolves the named collector log stream' );
    like( $named_log, qr/cli stdout/, 'd2 collector log <name> includes collector stdout' );
    like( $named_log, qr/cli stderr/, 'd2 collector log <name> includes collector stderr' );

    my $all_logs = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector log" );
    like( $all_logs, qr/cli\.collector/, 'd2 collector log without a name aggregates collector log output' );
    like( $all_logs, qr/cli stdout/, 'd2 collector log aggregate includes collector stdout' );

    my $pending_log = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector log pending.collector" );
    like( $pending_log, qr/No log entries are available yet for collector 'pending\.collector'/, 'd2 collector log <name> is explicit when a configured collector has not run yet' );

    my $collector_log_files = Developer::Dashboard::FileRegistry->new(
        paths => Developer::Dashboard::PathRegistry->new( home => $collector_log_home )
    );
    $collector_log_files->write( 'dashboard_log', "web one\nweb two\n" );
    my $top_level_web_log = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' log web" );
    is( $top_level_web_log, "web one\nweb two\n", 'd2 log web prints only the dashboard web log' );
    my $top_level_web_timestamp = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' log -t web" );
    like( $top_level_web_timestamp, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ web one\n/, 'd2 log -t web prefixes raw web lines with UTC read timestamps' );

    my $top_level_collector_logs = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' log collector" );
    like( $top_level_collector_logs, qr/cli\.collector/, 'd2 log collector prints collector logs without needing the nested collector command' );
    like( $top_level_collector_logs, qr/cli stdout/, 'd2 log collector includes collector stdout content' );

    my $named_top_level_collector_log = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' log collector cli.collector" );
    like( $named_top_level_collector_log, qr/cli\.collector/, 'd2 log collector <name> resolves one named collector log stream' );
    unlike( $named_top_level_collector_log, qr/pending\.collector/, 'd2 log collector <name> limits output to the requested collector' );

    my $everything_log = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' logs" );
    like( $everything_log, qr/web one/, 'd2 logs includes the dashboard web log in the all-logs view' );
    like( $everything_log, qr/cli\.collector/, 'd2 logs includes collector logs in the all-logs view' );
    my $everything_timestamp = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' logs -t" );
    like( $everything_timestamp, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ web one/, 'd2 logs -t timestamps web lines in mixed output' );
    like( $everything_timestamp, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:Z|[+-]\d{4}) === collector cli\.collector/, 'd2 logs -t timestamps collector records from their event time' );

    my $everything_tail_equal = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' logs --tail=2" );
    my @everything_tail_equal_lines = split /\n/, $everything_tail_equal;
    is( scalar @everything_tail_equal_lines, 2, 'd2 logs --tail=N prints exactly the requested final number of lines' );
    my $everything_tail_spaced = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' logs --tail 2" );
    is( $everything_tail_spaced, $everything_tail_equal, 'd2 logs --tail N is equivalent to --tail=N' );
    my $web_tail = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' log web --tail=1" );
    is( $web_tail, "web two\n", 'd2 log web --tail=N tails the web log' );
    my $logs_no_lines = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' logs --tail=0" );
    is( $logs_no_lines, '', 'd2 logs --tail=0 emits no lines' );

    my $templated_run = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector run templated.collector" ) );
    is( $templated_run->{exit_code}, 0, 'd2 collector run keeps TT-icon collectors successful when stdout contains valid JSON' );
    my $templated_indicators = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' indicator list" ) );
    my ($templated_indicator) = grep { $_->{name} eq 'templated.indicator' } @{$templated_indicators};
    ok( $templated_indicator, 'd2 indicator list exposes the TT-backed collector indicator after a collector run' );
    is( $templated_indicator->{icon}, '123', 'd2 indicator list preserves the rendered TT-backed collector icon instead of reverting to raw template syntax' ) if $templated_indicator;

    my $collector_log_paths = Developer::Dashboard::PathRegistry->new( home => $collector_log_home );
    my $collector_store = Developer::Dashboard::Collector->new( paths => $collector_log_paths );
    my $rotating_log = $collector_store->collector_paths('rotating.collector')->{log};
    open my $rotating_log_fh, '>', $rotating_log or die "Unable to write $rotating_log: $!";
    print {$rotating_log_fh} "line-1\nline-2\nline-3\nline-4\nline-5\nline-6\n";
    close $rotating_log_fh or die "Unable to close $rotating_log: $!";

    # DD-613: --dry-run must report the same would-be rotation without
    # touching the log file, before the real invocation below actually
    # rotates it.
    my $dry_run_housekeeper = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' housekeeper --dry-run" ) );
    is( $dry_run_housekeeper->{ok}, 1, 'd2 housekeeper --dry-run reports a successful preview scan' );
    ok( $dry_run_housekeeper->{dry_run}, 'd2 housekeeper --dry-run flags the summary as a dry run' );
    open my $unrotated_log_fh, '<', $rotating_log or die "Unable to read $rotating_log: $!";
    my $unrotated_log = do { local $/; <$unrotated_log_fh> };
    close $unrotated_log_fh or die "Unable to close $rotating_log: $!";
    is( $unrotated_log, "line-1\nline-2\nline-3\nline-4\nline-5\nline-6\n",
        'd2 housekeeper --dry-run leaves the collector log completely unrotated' );

    my $housekeeper_run = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' housekeeper" ) );
    is( $housekeeper_run->{ok}, 1, 'd2 housekeeper reports a successful cleanup scan' );
    ok( exists $housekeeper_run->{scanned}, 'd2 housekeeper reports scan counts' );
    ok( $housekeeper_run->{scanned}{collector_logs} >= 1, 'd2 housekeeper reports configured collector log scans when rotation is enabled' );
    open my $rotated_log_fh, '<', $rotating_log or die "Unable to read $rotating_log: $!";
    my $rotated_log = do { local $/; <$rotated_log_fh> };
    close $rotated_log_fh or die "Unable to close $rotating_log: $!";
    is( $rotated_log, "line-3\nline-4\nline-5\nline-6\n", 'd2 housekeeper rotates configured collector logs from the CLI command path' );

    my $collector_housekeeper_run = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector run housekeeper" ) );
    is( $collector_housekeeper_run->{name}, 'housekeeper', 'd2 collector run housekeeper executes the built-in housekeeper collector' );
    is( $collector_housekeeper_run->{exit_code}, 0, 'd2 collector run housekeeper succeeds' );

    my ( $missing_stdout, $missing_stderr, $missing_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' collector log missing.collector");
    ok( $missing_exit != 0, 'd2 collector log exits non-zero for an unknown collector name' );
    like(
        decode( 'UTF-8', $missing_stdout . $missing_stderr ),
        qr/Unknown collector 'missing\.collector'/,
        'd2 collector log reports unknown collector names explicitly',
    );

    my ( $missing_restart_stdout, $missing_restart_stderr, $missing_restart_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' restart collector missing.collector");
    ok( $missing_restart_exit != 0, 'd2 restart collector exits non-zero for an unknown collector name' );
    like(
        decode( 'UTF-8', $missing_restart_stdout . $missing_restart_stderr ),
        qr/Unknown collector 'missing\.collector'/,
        'd2 restart collector reports unknown collector names explicitly',
    );

    my ( $missing_stop_stdout, $missing_stop_stderr, $missing_stop_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' stop collector missing.collector");
    ok( $missing_stop_exit != 0, 'd2 stop collector exits non-zero for an unknown collector name' );
    like(
        decode( 'UTF-8', $missing_stop_stdout . $missing_stop_stderr ),
        qr/Unknown collector 'missing\.collector'/,
        'd2 stop collector reports unknown collector names explicitly',
    );

    my $collector_start_pid = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector start cli.collector" );
    like( $collector_start_pid, qr/\A\d+\n\z/, 'd2 collector start still starts one named collector loop directly' );

    # d2 collector stop <name> (path 2) must go through the supervisor-aware
    # stop so the watchdog cannot respawn the collector (regression: it used to
    # call the low-level stop_loop directly and leave the supervisor running).
    my $collector_subcmd_stop = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector stop cli.collector" );
    like( $collector_subcmd_stop, qr/\A(?:\d+\n)?\z/, 'd2 collector stop <name> prints the stopped loop pid (or nothing when already stopped)' );
    my $collector_subcmd_stopped_status = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector status cli.collector" ) );
    ok( !$collector_subcmd_stopped_status->{running}, 'd2 collector stop <name> leaves the collector not running so the supervisor cannot respawn it' );
    # re-start so the following top-level stop/restart assertions still control a live collector
    _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' collector start cli.collector" );

    my $top_level_stop_named_collector = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' stop collector cli.collector" );
    like( $top_level_stop_named_collector, qr/Component\s+Target\s+Status/, 'd2 stop collector <name> prints a table summary by default' );
    like( $top_level_stop_named_collector, qr/collector\s+cli\.collector\s+stopped/, 'd2 stop collector <name> reports the named collector row' );

    my $top_level_restart_named_collector = json_decode( _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' restart collector cli.collector -o json" ) );
    is( $top_level_restart_named_collector->{scope}, 'collector', 'd2 restart collector <name> reports the collector scope in JSON mode' );
    is( $top_level_restart_named_collector->{target}, 'cli.collector', 'd2 restart collector <name> reports the requested collector target in JSON mode' );

    my $top_level_stop_all_collectors = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' stop collector" );
    like( $top_level_stop_all_collectors, qr/Component\s+Target\s+Status/, 'd2 stop collector without a name prints a table summary by default' );
    like( $top_level_stop_all_collectors, qr/collector/, 'd2 stop collector without a name reports collector rows' );

    my $restart_web_port = _find_free_port();
    my $top_level_restart_web = json_decode(
        _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' restart web -o json --host 127.0.0.1 --port $restart_web_port" )
    );
    is( $top_level_restart_web->{scope}, 'web', 'd2 restart web reports the web scope in JSON mode' );
    ok( $top_level_restart_web->{web_pid}, 'd2 restart web returns the managed web pid in JSON mode' );
    my $top_level_stop_web = _run_in_home( $collector_log_home, "$perl -I'$lib' '$dashboard' stop web" );
    like( $top_level_stop_web, qr/Component\s+Target\s+Status/, 'd2 stop web prints a table summary by default' );
    like( $top_level_stop_web, qr/web\s+d2\s+stopped/, 'd2 stop web reports the web row in the summary table' );
}

my $bookmarks_root = _run("$perl -I'$lib' '$dashboard' path resolve bookmarks_root");
is( $bookmarks_root, File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'dashboards' ) . "\n", 'd2 path resolve supports bookmarks_root alias' );
my $custom_path_root = File::Spec->catdir( $ENV{HOME}, 'custom-path-root' );
make_path($custom_path_root);
my $path_add = _run("$perl -I'$lib' '$dashboard' path add foobar '$custom_path_root'");
like( $path_add, qr/^Alias\s+Stored\s+Resolved\s+Status/m, 'd2 path add defaults to a table summary' );
like( $path_add, qr/foobar\s+\Q$custom_path_root\E\s+\Q$custom_path_root\E\s+saved/, 'd2 path add table summary reports the stored alias and resolved path' );
open my $global_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
my $global_config = do { local $/; <$global_config_fh> };
close $global_config_fh;
like( $global_config, qr/"foobar"\s*:\s*"\$HOME\/custom-path-root"/, 'd2 path add stores home-relative aliases using $HOME in global config' );
my $path_add_again = _run("$perl -I'$lib' '$dashboard' path add foobar '$custom_path_root'");
like( $path_add_again, qr/foobar\s+\Q$custom_path_root\E\s+\Q$custom_path_root\E\s+saved/, 'd2 path add is idempotent when the alias already exists' );
my $foobar_resolved = _run("$perl -I'$lib' '$dashboard' path resolve foobar");
is( $foobar_resolved, $custom_path_root . "\n", 'd2 path resolve supports user-defined aliases' );
my $path_list = _run("$perl -I'$lib' '$dashboard' path list");
like( $path_list, qr/^Alias\s+Path/m, 'd2 path list defaults to a table summary' );
like( $path_list, qr/foobar\s+\Q$custom_path_root\E/, 'd2 path list includes user-defined aliases in the table summary' );
my $dot_current_path_root = File::Spec->catdir( $ENV{HOME}, 'dot-current-path-root' );
make_path($dot_current_path_root);
my $path_add_dot = _run("cd '$dot_current_path_root' && $perl -I'$lib' '$dashboard' path add .");
like( $path_add_dot, qr/dot-current-path-root\s+\Q$dot_current_path_root\E\s+\Q$dot_current_path_root\E\s+saved/, 'd2 path add . derives the alias name from the current directory basename and stores the current directory target' );
my $dot_current_resolved = _run("$perl -I'$lib' '$dashboard' path resolve dot-current-path-root");
is_same_path_output( $dot_current_resolved, "$dot_current_path_root\n", 'd2 path add . resolves back to the current directory' );
my $path_add_named_dot = _run("cd '$dot_current_path_root' && $perl -I'$lib' '$dashboard' path add right-here .");
like( $path_add_named_dot, qr/right-here\s+\Q$dot_current_path_root\E\s+\Q$dot_current_path_root\E\s+saved/, 'd2 path add NAME . keeps the explicit alias name and uses the current directory as the target path' );
my $custom_file_target = File::Spec->catfile( $ENV{HOME}, 'custom-notes.txt' );
open my $custom_file_target_fh, '>', $custom_file_target or die "Unable to write $custom_file_target: $!";
print {$custom_file_target_fh} "notes\n";
close $custom_file_target_fh;
my $file_add = _run("$perl -I'$lib' '$dashboard' file add notes '$custom_file_target'");
like( $file_add, qr/^Alias\s+Stored\s+Resolved\s+Status/m, 'd2 file add defaults to a table summary' );
like( $file_add, qr/notes\s+\Q$custom_file_target\E\s+\Q$custom_file_target\E\s+saved/, 'd2 file add reports the stored target file in the table summary' );
open my $global_file_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
my $global_file_config = do { local $/; <$global_file_config_fh> };
close $global_file_config_fh;
like( $global_file_config, qr/"notes"\s*:\s*"\$HOME\/custom-notes\.txt"/, 'd2 file add stores home-relative file aliases using $HOME in global config' );
my $notes_resolved = _run("$perl -I'$lib' '$dashboard' file resolve notes");
is( $notes_resolved, $custom_file_target . "\n", 'd2 file resolve supports user-defined file aliases' );
my $file_list = _run("$perl -I'$lib' '$dashboard' file list");
like( $file_list, qr/^Alias\s+Path/m, 'd2 file list defaults to a table summary' );
like( $file_list, qr/notes\s+\Q$custom_file_target\E/, 'd2 file list includes user-defined file aliases in the table summary' );
my $of_file_alias = _run("$perl -I'$lib' '$dashboard' of --print notes");
is( $of_file_alias, $custom_file_target . "\n", 'd2 of resolves configured file aliases directly' );
{
    my $layered_path_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $layered_path_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $layered_init = _run("$perl -I'$lib' '$dashboard' init");
    like( $layered_init, qr/runtime_root/, 'isolated layered path smoke home initializes a runtime' );
    my $layered_root_config_file = File::Spec->catfile( $layered_path_home, '.developer-dashboard', 'config', 'config.json' );
    open my $layered_root_config_fh, '>:raw', $layered_root_config_file or die "Unable to write $layered_root_config_file: $!";
    print {$layered_root_config_fh} json_encode(
        {
            collectors => [
                {
                    name     => 'root.collector',
                    command  => q{true},
                    cwd      => 'home',
                    interval => 10,
                },
            ],
            web => {
                no_editor => 1,
            },
        }
    );
    close $layered_root_config_fh;
    my $layered_project = File::Spec->catdir( $layered_path_home, 'layered-path-project' );
    make_path(
        File::Spec->catdir( $layered_project, '.git' ),
        File::Spec->catdir( $layered_project, '.developer-dashboard', 'cli' ),
    );
    my $layered_cli = File::Spec->catfile( $layered_project, '.developer-dashboard', 'cli', 'foobar' );
    open my $layered_cli_fh, '>:raw', $layered_cli or die "Unable to write $layered_cli: $!";
    print {$layered_cli_fh} "#!/usr/bin/env perl\nprint qq{layered path smoke\\n};\n";
    close $layered_cli_fh;
    chmod 0700, $layered_cli or die "Unable to chmod $layered_cli: $!";
    my $layered_path_add = _run("cd '$layered_project' && HOME='$layered_path_home' $perl -I'$lib' '$dashboard' path add layered '$layered_project'");
    like( $layered_path_add, qr/layered\s+\Q$layered_project\E\s+\Q$layered_project\E\s+saved/, 'd2 path add saves an alias inside a deepest child DD-OOP layer' );
    my $layered_child_config_file = File::Spec->catfile( $layered_project, '.developer-dashboard', 'config', 'config.json' );
    open my $layered_child_config_fh, '<', $layered_child_config_file or die "Unable to read $layered_child_config_file: $!";
    my $layered_child_config = decode( 'UTF-8', do { local $/; <$layered_child_config_fh> } );
    close $layered_child_config_fh;
    is_deeply(
        json_decode($layered_child_config),
        {
            path_aliases => {
                layered => '$HOME/layered-path-project',
            },
        },
        'd2 path add writes only the new portable alias into the deepest child config file',
    );
    unlike( $layered_child_config, qr/"root\.collector"/, 'd2 path add does not copy inherited collector settings into the deepest child config file' );
    unlike( $layered_child_config, qr/"no_editor"\s*:\s*1/, 'd2 path add does not copy inherited web settings into the deepest child config file' );
}
{
    my $env_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $env_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

    my $env_repo    = File::Spec->catdir( $env_home, 'env-project' );
    my $env_project = File::Spec->catdir( $env_repo, 'child' );
    make_path(
        File::Spec->catdir( $env_home, '.developer-dashboard' ),
        File::Spec->catdir( $env_repo, '.git' ),
        File::Spec->catdir( $env_project, '.developer-dashboard', 'cli' ),
        File::Spec->catdir( $env_project, '.developer-dashboard', 'skills', 'envskill', 'cli' ),
    );
    open my $home_env_fh, '>:raw', File::Spec->catfile( $env_home, '.env' ) or die "Unable to write $env_home/.env: $!";
    print {$home_env_fh} <<'EOF';
ROOT_ENV=root
SHARED_ENV=home
HOME_REF=~/cli-home
DEFAULT_REF=${MISSING_VALUE:-cli-fallback}
CHAIN_REF=$ROOT_ENV/$SHARED_ENV
# comment
// comment
/* block
comment */
EOF
    close $home_env_fh or die "Unable to close $env_home/.env: $!";
    open my $home_runtime_env_fh, '>:raw', File::Spec->catfile( $env_home, '.developer-dashboard', '.env' )
      or die "Unable to write $env_home/.developer-dashboard/.env: $!";
    print {$home_runtime_env_fh} "HOME_RUNTIME_ENV=home-runtime\n";
    close $home_runtime_env_fh or die "Unable to close $env_home/.developer-dashboard/.env: $!";
    open my $repo_env_pl_fh, '>:raw', File::Spec->catfile( $env_repo, '.env.pl' )
      or die "Unable to write $env_repo/.env.pl: $!";
    print {$repo_env_pl_fh} "\$ENV{PROJECT_ENV_PL} = \"\$ENV{HOME_RUNTIME_ENV}/project\";\n1;\n";
    close $repo_env_pl_fh or die "Unable to close $env_repo/.env.pl: $!";
    open my $child_env_fh, '>:raw', File::Spec->catfile( $env_project, '.env' ) or die "Unable to write child .env: $!";
    print {$child_env_fh} "CHILD_ENV=child\nSHARED_ENV=child\n";
    close $child_env_fh or die "Unable to close child .env: $!";
    open my $child_env_pl_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', '.env.pl' )
      or die "Unable to write child runtime .env.pl: $!";
    print {$child_env_pl_fh} "\$ENV{CHILD_PL_ENV} = \"\$ENV{SHARED_ENV}-pl\";\n1;\n";
    close $child_env_pl_fh or die "Unable to close child runtime .env.pl: $!";
    open my $skill_env_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', '.env' )
      or die "Unable to write skill .env: $!";
    print {$skill_env_fh} "SKILL_ONLY_ENV=skill\nSHARED_ENV=skill\n";
    close $skill_env_fh or die "Unable to close skill .env: $!";
    open my $show_env_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to write show-env command: $!";
    print {$show_env_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Developer::Dashboard::EnvAudit;
print encode_json(
    {
        root       => $ENV{ROOT_ENV},
        child      => $ENV{CHILD_ENV},
        child_pl   => $ENV{CHILD_PL_ENV},
        home_runtime => $ENV{HOME_RUNTIME_ENV},
        project_env_pl => $ENV{PROJECT_ENV_PL},
        shared     => $ENV{SHARED_ENV},
        home_ref   => $ENV{HOME_REF},
        default_ref => $ENV{DEFAULT_REF},
        chain_ref  => $ENV{CHAIN_REF},
        skill_only => defined $ENV{SKILL_ONLY_ENV} ? $ENV{SKILL_ONLY_ENV} : undef,
        audit      => Developer::Dashboard::EnvAudit->key('SHARED_ENV'),
    }
), "\n";
PL
    close $show_env_fh or die "Unable to close show-env command: $!";
    chmod 0700, File::Spec->catfile( $env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to chmod show-env command: $!";
    open my $skill_show_fh, '>:raw', File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', 'cli', 'show' )
      or die "Unable to write skill show command: $!";
    print {$skill_show_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Developer::Dashboard::EnvAudit;
print encode_json(
    {
        root       => $ENV{ROOT_ENV},
        child      => $ENV{CHILD_ENV},
        skill_only => $ENV{SKILL_ONLY_ENV},
        shared     => $ENV{SHARED_ENV},
        audit      => Developer::Dashboard::EnvAudit->key('SHARED_ENV'),
    }
), "\n";
PL
    close $skill_show_fh or die "Unable to close skill show command: $!";
    chmod 0700, File::Spec->catfile( $env_project, '.developer-dashboard', 'skills', 'envskill', 'cli', 'show' )
      or die "Unable to chmod skill show command: $!";

    my $regular_env = json_decode( _run("cd '$env_project' && HOME='$env_home' $perl -I'$lib' '$dashboard' show-env") );
    is( $regular_env->{root}, 'root', 'dashboard custom commands inherit env values from the home .env layer' );
    is( $regular_env->{child}, 'child', 'dashboard custom commands inherit env values from the child .env layer' );
    is( $regular_env->{child_pl}, 'child-pl', 'dashboard custom commands load child .env before child .env.pl at the same layer' );
    is( $regular_env->{home_runtime}, 'home-runtime', 'dashboard custom commands load home runtime environment values' );
    is( $regular_env->{project_env_pl}, 'home-runtime/project', 'project-root .env.pl can use a value from the home runtime .env' );
    is( $regular_env->{shared}, 'child', 'dashboard custom commands keep the deepest non-skill env value when no skill command is being run' );
    is( $regular_env->{home_ref}, File::Spec->catdir( $env_home, 'cli-home' ), 'dashboard custom commands receive tilde-expanded env values from .env files' );
    is( $regular_env->{default_ref}, 'cli-fallback', 'dashboard custom commands receive default-expanded ${NAME:-default} env values from .env files' );
    is( $regular_env->{chain_ref}, 'root/home', 'dashboard custom commands receive values expanded from earlier keys in the same .env file' );
    ok( !defined $regular_env->{skill_only}, 'dashboard non-skill commands do not load skill-local env files' );
    is(
        _portable_path( $regular_env->{audit}{envfile} ),
        _portable_path( File::Spec->catfile( $env_project, '.env' ) ),
        'dashboard custom commands expose env audit metadata for the deepest effective non-skill key source',
    );

    my $skill_env = json_decode( _run("cd '$env_project' && HOME='$env_home' $perl -I'$lib' '$dashboard' envskill.show") );
    is( $skill_env->{root}, 'root', 'dashboard dotted skill commands still inherit the home .env layer' );
    is( $skill_env->{child}, 'child', 'dashboard dotted skill commands still inherit the child .env layer' );
    is( $skill_env->{skill_only}, 'skill', 'dashboard dotted skill commands additionally load skill-local env files' );
    is( $skill_env->{shared}, 'child', 'the invocation cwd env overrides skill-local values when a skill is running' );
    is(
        _portable_path( $skill_env->{audit}{envfile} ),
        _portable_path( File::Spec->catfile( $env_project, '.env' ) ),
        'dashboard dotted skill commands expose env audit metadata for the effective cwd env override',
    );
}
{
    my $bad_env_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $bad_env_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $bad_env_project = File::Spec->catdir( $bad_env_home, 'bad-env-project' );
    make_path(
        File::Spec->catdir( $bad_env_home, '.developer-dashboard' ),
        File::Spec->catdir( $bad_env_project, '.git' ),
        File::Spec->catdir( $bad_env_project, '.developer-dashboard', 'cli' ),
    );
    open my $bad_env_fh, '>:raw', File::Spec->catfile( $bad_env_project, '.env' ) or die "Unable to write malformed child .env: $!";
    print {$bad_env_fh} "THIS IS NOT VALID\n";
    close $bad_env_fh or die "Unable to close malformed child .env: $!";
    open my $bad_cli_fh, '>:raw', File::Spec->catfile( $bad_env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to write bad-env show-env command: $!";
    print {$bad_cli_fh} "#!/usr/bin/env perl\nprint qq{never-runs\\n};\n";
    close $bad_cli_fh or die "Unable to close bad-env show-env command: $!";
    chmod 0700, File::Spec->catfile( $bad_env_project, '.developer-dashboard', 'cli', 'show-env' )
      or die "Unable to chmod bad-env show-env command: $!";

    my ( $bad_stdout, $bad_stderr, $bad_exit ) = _sh_capture("cd '$bad_env_project' && HOME='$bad_env_home' $perl -I'$lib' '$dashboard' show-env");
    ok( $bad_exit != 0, 'dashboard exits non-zero when a participating .env file is malformed' );
    # The path separator in the reported .env path is a backslash on
    # Windows and a forward slash everywhere else; match either so the
    # assertion checks the message, not the platform's separator.
    like(
        decode( 'UTF-8', $bad_stdout . $bad_stderr ),
        qr/Invalid env line .*bad-env-project[\/\\]\.env line 1/,
        'dashboard reports malformed .env files explicitly instead of hiding the load failure',
    );
}

my $alias_multi_one = File::Spec->catdir( $custom_path_root, 'alpha-foo' );
my $alias_multi_two = File::Spec->catdir( $custom_path_root, 'alpha-foo-two' );
my $alias_unique = File::Spec->catdir( $custom_path_root, 'nested', 'alpha-foo-bar' );
make_path( $alias_multi_one, $alias_multi_two, $alias_unique );

my $cwd_search_root = File::Spec->catdir( $ENV{HOME}, 'cdr-search-root' );
my $cwd_search_multi_one = File::Spec->catdir( $cwd_search_root, 'team-alpha' );
my $cwd_search_multi_two = File::Spec->catdir( $cwd_search_root, 'nested', 'team-alpha-ops' );
my $cwd_search_unique = File::Spec->catdir( $cwd_search_root, 'nested', 'team-alpha-red' );
make_path( $cwd_search_multi_one, $cwd_search_multi_two, $cwd_search_unique );

my $shell_bootstrap = _run("$perl -I'$lib' '$dashboard' shell bash");
# The bootstrap spells the entrypoint with forward slashes on Windows
# (abs_path) while this file's $dashboard uses backslashes (File::Spec),
# and the perl path is backslashed in both. Compare separator-normalized
# copies in the assertions below so they check the paths, not the spelling
# of the separator.
my $shell_bootstrap_forward = $shell_bootstrap;
$shell_bootstrap_forward =~ s/\\/\//g;
my $perl_forward = $perl;
$perl_forward =~ s/\\/\//g;
my $dashboard_forward = $dashboard;
$dashboard_forward =~ s/\\/\//g;
like( $shell_bootstrap, qr/path cdr/, 'd2 shell bootstrap delegates cdr target selection through the Perl path helper' );
unlike( $shell_bootstrap, qr/\bperl\s+-MJSON::XS\b/, 'd2 shell bootstrap does not decode helper JSON through a bare perl command that can drift to an incompatible interpreter' );
like( $shell_bootstrap, qr/\Q$perl\E.*-MJSON::XS/s, 'd2 shell bootstrap decodes helper JSON through the same perl interpreter that generated the bootstrap' );
unlike( $shell_bootstrap, qr/\bd2\(\)\s*\{/, 'd2 shell bash bootstrap no longer defines a d2 shell function because d2 is now a real installed command' );
like( $shell_bootstrap, qr/complete -F _dashboard_complete d2/, 'd2 shell bash bootstrap wires tab completion for d2' );
like( $shell_bootstrap, qr/complete -F _dashboard_complete_cdr cdr dd_cdr which_dir/, 'd2 shell bash bootstrap wires cdr-family tab completion' );
unlike( $shell_bootstrap, qr/done\s+<\s+</, 'd2 shell bash bootstrap avoids process substitution in completion helpers for macOS compatibility' );
like( $shell_bootstrap_forward, qr/completion_output="\$\('\Q$perl_forward\E'(?:\s+'-I[^']+')?\s+'\Q$dashboard_forward\E' complete /, 'd2 shell bash bootstrap captures dashboard completions through command substitution' );
like( $shell_bootstrap_forward, qr/\Q$perl_forward\E.*\Q$dashboard_forward\E/s, 'd2 shell bootstrap uses the current Perl runtime for the checkout entrypoint' );
like( $shell_bootstrap_forward, qr/completion_output="\$\('\Q$perl_forward\E'(?:\s+'-I[^']+')?\s+'\Q$dashboard_forward\E' path complete-cdr /, 'd2 shell bash bootstrap captures cdr completions through command substitution' );
{
    local $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '/tmp/stale-dashboard-entrypoint';
    my $stale_entrypoint_bootstrap = _run("$perl -I'$lib' '$dashboard' shell bash");
    my $stale_entrypoint_forward = $stale_entrypoint_bootstrap;
    $stale_entrypoint_forward =~ s/\\/\//g;
    like(
        $stale_entrypoint_forward,
        qr/completion_output="\$\('\Q$perl_forward\E'(?:\s+'-I[^']+')?\s+'\Q$dashboard_forward\E' complete /,
        'd2 shell bash bootstrap ignores a stale inherited d2 entrypoint path',
    );
    unlike(
        $stale_entrypoint_bootstrap,
        qr/\Q$ENV{DEVELOPER_DASHBOARD_ENTRYPOINT}\E/,
        'd2 shell bash bootstrap does not leak an inherited stale d2 entrypoint path',
    );
}
my $shell_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell.sh' );
open my $shell_bootstrap_fh, '>', $shell_bootstrap_file or die "Unable to write $shell_bootstrap_file: $!";
print {$shell_bootstrap_fh} $shell_bootstrap;
close $shell_bootstrap_fh;
my $d2_bindir = $dashboard;
$d2_bindir =~ s{/[^/]+\z}{};

# Bash completion, cdr and which_dir are shell features: every command in
# this section runs bash, which does not exist on the Windows Sandbox.
# The generated bootstrap itself is still checked after this block (the
# content assertions below), so only the bash execution is skipped here.
# 57 = 36 assertions in this section + 21 exit-code assertions the _run
# calls inside it make.
SKIP: {
    skip 'bash is not available on Windows', 57 if $^O eq 'MSWin32';

    # d2 is now a real installed command; make its bin dir discoverable on PATH and
    # confirm it dispatches d2 subcommands identically.
    my $bash_d2_version = _run("bash -lc 'PATH=\"$d2_bindir:" . dirname($perl) . ":\$PATH\"; . \"$shell_bootstrap_file\"; d2 version'");
    is( $bash_d2_version, "$expected_version\n", 'the real d2 command dispatches d2 subcommands identically to dashboard' );
    my $bash_completion = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(dashboard do); COMP_CWORD=1; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_completion, qr/^docker$/m, 'd2 shell bash completion suggests docker through the generated completion helper' );
    like( $bash_completion, qr/^doctor$/m, 'd2 shell bash completion suggests doctor through the generated completion helper' );
    my $bash_global_help_entry = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(dashboard ''); COMP_CWORD=1; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_global_help_entry, qr/^help$/m, 'd2 shell bash completion exposes the global help entrypoint' );
    like( $bash_global_help_entry, qr/^version$/m, 'd2 shell bash completion exposes the built-in version command' );
    my $bash_completion_alias = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 do); COMP_CWORD=1; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_completion_alias, qr/^docker$/m, 'd2 shell bash completion also works through the d2 alias' );
    like( $bash_completion_alias, qr/^doctor$/m, 'd2 shell bash completion keeps the same candidates for d2' );
    my $bash_api_actions = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 api ''); COMP_CWORD=2; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_api_actions, qr/^ls$/m, 'dashboard bash TAB completion lists the API default action' );
    like( $bash_api_actions, qr/^add$/m, 'dashboard bash TAB completion lists API add' );
    like( $bash_api_actions, qr/^rm$/m, 'dashboard bash TAB completion lists API removal' );
    my $bash_docker_development_actions = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 docker development ''); COMP_CWORD=3; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    is( _portable_output_text($bash_docker_development_actions), "enable\ndisable\n", 'dashboard bash TAB completion offers both Docker development marker actions' );
    my $bash_file_actions = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 file ''); COMP_CWORD=2; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_file_actions, qr/^resolve$/m, 'dashboard bash TAB completion lists file resolution' );
    like( $bash_file_actions, qr/^list$/m, 'dashboard bash TAB completion lists file aliases' );
    my $bash_path_actions = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 path ''); COMP_CWORD=2; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_path_actions, qr/^cdr$/m, 'dashboard bash TAB completion lists the implemented cdr action' );
    like( $bash_path_actions, qr/^complete-cdr$/m, 'dashboard bash TAB completion lists the cdr completion protocol' );
    like( $bash_path_actions, qr/^rm$/m, 'dashboard bash TAB completion lists the path rm alias' );
    my $bash_api_options = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 api add -); COMP_CWORD=3; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_api_options, qr/^--secret$/m, 'dashboard bash TAB completion suggests API command options' );
    like( $bash_api_options, qr/^--help$/m, 'dashboard bash TAB completion suggests explicit help options' );
    my $bash_api_default_options = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 api -); COMP_CWORD=2; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_api_default_options, qr/^--key$/m, 'dashboard bash TAB completion suggests the API default-list key filter' );
    like( $bash_api_default_options, qr/^--output$/m, 'dashboard bash TAB completion suggests the API default-list output option' );
    my $bash_global_help = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(d2 help docker ''); COMP_CWORD=3; _dashboard_complete; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_global_help, qr/^compose$/m, 'dashboard bash TAB completion suggests actions after global help target' );
    my $bash_cdr_completion = _run("bash -lc '. \"$shell_bootstrap_file\"; COMP_WORDS=(cdr foobar alpha); COMP_CWORD=2; _dashboard_complete_cdr; printf \"%s\\n\" \"\${COMPREPLY[@]}\"'");
    like( $bash_cdr_completion, qr/^alpha-foo$/m, 'd2 shell bash cdr completion suggests alias-root narrowing candidates' );
    unlike( $bash_cdr_completion, qr/^alpha-foo-bar$/m, 'd2 shell bash cdr completion does not recursively suggest deeper descendants' );
    my $which_dir_bookmarks = _run("bash -lc '. \"$shell_bootstrap_file\"; which_dir bookmarks_root'");
    is_same_path_output( $which_dir_bookmarks, $bookmarks_root, 'which_dir resolves bookmarks_root through the shell helper' );
    my $cdr_bookmarks = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr bookmarks_root; pwd'");
    is_same_path_output( $cdr_bookmarks, $bookmarks_root, 'cdr navigates to bookmarks_root through the shell helper' );
    my $cdr_foobar = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar; pwd'");
    is_same_path_output( $cdr_foobar, $custom_path_root . "\n", 'cdr navigates to a user-defined alias through the shell helper' );
    my $cdr_foobar_unique = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar alpha foo bar; pwd'");
    is_same_path_output( $cdr_foobar_unique, $alias_unique . "\n", 'cdr narrows a resolved alias with AND-matched keywords and enters the only matching subdirectory' );
    my $cdr_foobar_multi = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar alpha foo; pwd'");
    my $portable_cdr_foobar_multi = _portable_output_text($cdr_foobar_multi);
    like( $portable_cdr_foobar_multi, qr/^\Q@{[ _portable_path($alias_multi_one) ]}\E$/m, 'cdr prints the first alias-root search match when multiple subdirectories satisfy the keywords' );
    like( $portable_cdr_foobar_multi, qr/^\Q@{[ _portable_path($alias_multi_two) ]}\E$/m, 'cdr prints the second alias-root search match when multiple subdirectories satisfy the keywords' );
    like( $portable_cdr_foobar_multi, qr/\Q@{[ _portable_path($custom_path_root) ]}\E\n\z/, 'cdr stays at the resolved alias root when alias-root keyword search finds multiple directories' );
    my $cdr_foobar_regex = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar alpha-foo\$; pwd'");
    is_same_path_output( $cdr_foobar_regex, $alias_multi_one . "\n", 'cdr treats alias-root narrowing terms as regexes' );
    my $cdr_keywords_unique = _run("bash -lc '. \"$shell_bootstrap_file\"; cd \"$cwd_search_root\"; cdr alpha red; pwd'");
    is_same_path_output( $cdr_keywords_unique, $cwd_search_unique . "\n", 'cdr treats non-alias arguments as current-directory search keywords and enters a unique match' );
    my $cdr_keywords_multi = _run("bash -lc '. \"$shell_bootstrap_file\"; cd \"$cwd_search_root\"; cdr team alpha; pwd'");
    my $portable_cdr_keywords_multi = _portable_output_text($cdr_keywords_multi);
    like( $portable_cdr_keywords_multi, qr/^\Q@{[ _portable_path($cwd_search_multi_one) ]}\E$/m, 'cdr prints one current-directory search match when multiple directories satisfy non-alias keywords' );
    like( $portable_cdr_keywords_multi, qr/^\Q@{[ _portable_path($cwd_search_multi_two) ]}\E$/m, 'cdr prints the other current-directory search match when multiple directories satisfy non-alias keywords' );
    like( $portable_cdr_keywords_multi, qr/\Q@{[ _portable_path($cwd_search_root) ]}\E\n\z/, 'cdr leaves the shell in place when non-alias keyword search has multiple matches' );
    my $cdr_keywords_regex = _run("bash -lc '. \"$shell_bootstrap_file\"; cd \"$cwd_search_root\"; cdr team-alpha\$; pwd'");
    is_same_path_output( $cdr_keywords_regex, $cwd_search_multi_one . "\n", 'cdr treats non-alias search terms as regexes beneath the current directory' );
}
like( $shell_bootstrap, qr/ps1 --jobs \\j --mode compact/, 'd2 shell bash bootstrap keeps bash job-count prompt rendering' );
like( $shell_bootstrap, qr/_dd_tmux_status_active/, 'd2 shell bash bootstrap centralizes the dashboard ticket tmux-session detection helper' );
like( $shell_bootstrap, qr/TICKET_REF/, 'd2 shell bash bootstrap also recognizes ticket-managed tmux sessions through the ticket reference environment' );
like( $shell_bootstrap, qr/tmux set-option -q status-position bottom/, 'd2 shell bash bootstrap keeps the normal tmux status bar at the bottom in ticket sessions' );
like( $shell_bootstrap, qr/tmux set-option -q status 2/, 'd2 shell bash bootstrap enables a two-line tmux status block for ticket sessions' );
like( $shell_bootstrap, qr/tmux set-option -q status-interval 15/, 'd2 shell bash bootstrap refreshes the tmux status block automatically for ticket sessions without hot-looping' );
like( $shell_bootstrap, qr/tmux set-option -q 'status-format\[0\]'.*tmux-status-top --width #\{client_width\}/s, 'd2 shell bash bootstrap renders the indicator strip into the first tmux status row' );
like( $shell_bootstrap_forward, qr/status-format\[0\]' "#\((?:'[^']+'\s+)*'\Q$dashboard_forward\E' ps1 --mode tmux-status-top --width #\{client_width\}\)"/, 'd2 shell bash bootstrap renders the tmux ticket indicator row through the explicit d2 entrypoint path' );
unlike( $shell_bootstrap, qr/status-format\[0\]'? "#\(d2 ps1 --mode tmux-status-top --width #\{client_width\}\)"/, 'd2 shell bash bootstrap does not depend on a bare dashboard PATH lookup for tmux ticket status rendering' );
like( $shell_bootstrap, qr/tmux set-option -q 'status-format\[1\]' "\$_dd_default_status"/, 'd2 shell bash bootstrap restores the normal tmux status row beneath the indicators' );
like( $shell_bootstrap, qr/_dd_update_prompt\(\)/, 'd2 shell bash bootstrap centralizes prompt refresh through one helper so later distro PS1 assignments cannot permanently override it' );
like( $shell_bootstrap, qr/PROMPT_COMMAND=.*_dd_update_prompt/s, 'd2 shell bash bootstrap installs a PROMPT_COMMAND refresh hook so the dashboard prompt survives later bashrc prompt assignments' );
like( $shell_bootstrap, qr/ps1 --jobs \\j --mode compact --no-indicators/, 'd2 shell bash bootstrap suppresses prompt indicators when tmux owns the status line' );

my $zsh_bootstrap = _run("$perl -I'$lib' '$dashboard' shell zsh");
like( $zsh_bootstrap, qr/add-zsh-hook precmd _dd_update_prompt/, 'd2 shell zsh bootstrap refreshes the prompt through a precmd hook' );
like( $zsh_bootstrap, qr/ps1 --jobs \$\{#jobstates\} --mode compact/, 'd2 shell zsh bootstrap uses zsh job counts for prompt rendering' );
like( $zsh_bootstrap, qr/_dd_tmux_status_active/, 'd2 shell zsh bootstrap centralizes the dashboard ticket tmux-session detection helper' );
like( $zsh_bootstrap, qr/TICKET_REF/, 'd2 shell zsh bootstrap also recognizes ticket-managed tmux sessions through the ticket reference environment' );
like( $zsh_bootstrap, qr/tmux set-option -q status-position bottom/, 'd2 shell zsh bootstrap keeps the normal tmux status bar at the bottom in ticket sessions' );
like( $zsh_bootstrap, qr/tmux set-option -q status 2/, 'd2 shell zsh bootstrap enables a two-line tmux status block for ticket sessions' );
like( $zsh_bootstrap, qr/tmux set-option -q status-interval 15/, 'd2 shell zsh bootstrap refreshes the tmux status block automatically for ticket sessions without hot-looping' );
like( $zsh_bootstrap, qr/tmux set-option -q 'status-format\[0\]'.*tmux-status-top --width #\{client_width\}/s, 'd2 shell zsh bootstrap renders the indicator strip into the first tmux status row' );
like( $zsh_bootstrap, qr/tmux set-option -q 'status-format\[1\]' "\$default_status"/, 'd2 shell zsh bootstrap restores the normal tmux status row beneath the indicators' );
like( $zsh_bootstrap, qr/ps1 --jobs \$\{#jobstates\} --mode compact --no-indicators/, 'd2 shell zsh bootstrap suppresses prompt indicators when tmux owns the status line' );
like( $zsh_bootstrap, qr/path cdr/, 'd2 shell zsh bootstrap keeps the cdr path helper functions' );
unlike( $zsh_bootstrap, qr/\bd2\(\)\s*\{/, 'd2 shell zsh bootstrap no longer defines a d2 shell function because d2 is now a real installed command' );
like( $zsh_bootstrap, qr/autoload -Uz compinit/, 'd2 shell zsh bootstrap loads compinit for fresh shells before completion setup' );
like( $zsh_bootstrap, qr{whence compdef >/dev/null 2>&1}, 'd2 shell zsh bootstrap checks whether compdef is already available' );
like( $zsh_bootstrap, qr/\bcompinit\b/, 'd2 shell zsh bootstrap initializes zsh completion when compdef is missing' );
like( $zsh_bootstrap, qr/compdef _dashboard_complete_zsh d2/, 'd2 shell zsh bootstrap wires tab completion for d2' );
like( $zsh_bootstrap, qr/compdef _dashboard_complete_cdr_zsh cdr dd_cdr which_dir/, 'd2 shell zsh bootstrap wires cdr-family tab completion' );
unlike( $zsh_bootstrap, qr/\bd2\(\)/, 'd2 shell zsh bootstrap defines no d2 function body at all' );

my $sh_bootstrap = _run("$perl -I'$lib' '$dashboard' shell sh");
like( $sh_bootstrap, qr/path cdr/, 'd2 shell sh bootstrap keeps the cdr path helper functions' );
like( $sh_bootstrap, qr/ps1 --mode compact/, 'd2 shell sh bootstrap renders the prompt through d2 ps1' );
like( $sh_bootstrap, qr/_dd_tmux_status_active/, 'd2 shell sh bootstrap centralizes the dashboard ticket tmux-session detection helper' );
like( $sh_bootstrap, qr/TICKET_REF/, 'd2 shell sh bootstrap also recognizes ticket-managed tmux sessions through the ticket reference environment' );
like( $sh_bootstrap, qr/tmux set-option -q status-position bottom/, 'd2 shell sh bootstrap keeps the normal tmux status bar at the bottom in ticket sessions' );
like( $sh_bootstrap, qr/tmux set-option -q status 2/, 'd2 shell sh bootstrap enables a two-line tmux status block for ticket sessions' );
like( $sh_bootstrap, qr/tmux set-option -q status-interval 15/, 'd2 shell sh bootstrap refreshes the tmux status block automatically for ticket sessions without hot-looping' );
like( $sh_bootstrap, qr/tmux set-option -q 'status-format\[0\]'.*tmux-status-top --width #\{client_width\}/s, 'd2 shell sh bootstrap renders the indicator strip into the first tmux status row' );
like( $sh_bootstrap, qr/tmux set-option -q 'status-format\[1\]' "\$_dd_default_status"/, 'd2 shell sh bootstrap restores the normal tmux status row beneath the indicators' );
like( $sh_bootstrap, qr/ps1 --mode compact --no-indicators/, 'd2 shell sh bootstrap suppresses prompt indicators when tmux owns the status line' );
unlike( $sh_bootstrap, qr/ps1 --jobs \\j/, 'd2 shell sh bootstrap does not rely on bash-specific job expansion' );
unlike( $sh_bootstrap, qr/\bperl\s+-MJSON::XS\b/, 'd2 shell sh bootstrap does not decode helper JSON through a bare perl command either' );
like( $sh_bootstrap, qr/\Q$perl\E.*-MJSON::XS/s, 'd2 shell sh bootstrap decodes helper JSON through the same perl interpreter that generated the bootstrap' );
unlike( $sh_bootstrap, qr/\bd2\(\)\s*\{/, 'd2 shell sh bootstrap no longer defines a d2 shell function because d2 is now a real installed command' );
my $sh_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell-posix.sh' );
open my $sh_bootstrap_fh, '>', $sh_bootstrap_file or die "Unable to write $sh_bootstrap_file: $!";
print {$sh_bootstrap_fh} $sh_bootstrap;
close $sh_bootstrap_fh;
# The POSIX shell bootstrap is exercised through sh, which does not
# exist on the Windows Sandbox. The bootstrap content itself is still
# checked above, so only the sh execution is skipped here.
# 8 = 4 assertions in this section + 4 exit-code assertions the _run
# calls inside it make.
SKIP: {
    skip 'sh is not available on Windows', 8 if $^O eq 'MSWin32';

    my $sh_d2_version = _run("sh -lc 'PATH=\"$d2_bindir:" . dirname($perl) . ":\$PATH\"; . \"$sh_bootstrap_file\"; d2 version'");
    is( $sh_d2_version, "$expected_version\n", 'd2 helper dispatches d2 subcommands through the POSIX shell bootstrap' );
    my $sh_which_dir_bookmarks = _run("sh -lc '. \"$sh_bootstrap_file\"; which_dir bookmarks_root'");
    is_same_path_output( $sh_which_dir_bookmarks, $bookmarks_root, 'which_dir resolves bookmarks_root through the POSIX shell helper' );
    my $sh_cdr_bookmarks = _run("sh -lc '. \"$sh_bootstrap_file\"; cdr bookmarks_root; pwd'");
    is_same_path_output( $sh_cdr_bookmarks, $bookmarks_root, 'cdr navigates to bookmarks_root through the POSIX shell helper' );
    my $sh_cdr_foobar_unique = _run("sh -lc '. \"$sh_bootstrap_file\"; cdr foobar alpha foo bar; pwd'");
    is_same_path_output( $sh_cdr_foobar_unique, $alias_unique . "\n", 'cdr narrows aliases through the POSIX shell helper as well' );
}

my $ps_bootstrap = _run("$perl -I'$lib' '$dashboard' shell ps");
like( $ps_bootstrap, qr/function prompt \{/, 'd2 shell ps bootstrap uses the PowerShell prompt function instead of a PS1 variable' );
like( $ps_bootstrap, qr/function cdr \{/, 'd2 shell ps bootstrap exposes the cdr helper' );
like( $ps_bootstrap, qr/\bps1 --mode compact/, 'd2 shell ps bootstrap still renders prompt text through d2 ps1' );
like( $ps_bootstrap, qr/DEVELOPER_DASHBOARD_TMUX_STATUS -eq '1'/, 'd2 shell ps bootstrap gates tmux status-right behind the dashboard ticket session flag' );
like( $ps_bootstrap, qr/TICKET_REF/, 'd2 shell ps bootstrap also recognizes ticket-managed tmux sessions through the ticket reference environment' );
like( $ps_bootstrap, qr/tmux set-option -q status-position bottom/, 'd2 shell ps bootstrap keeps the normal tmux status bar at the bottom in ticket sessions' );
like( $ps_bootstrap, qr/tmux set-option -q status 2/, 'd2 shell ps bootstrap enables a two-line tmux status block for ticket sessions' );
like( $ps_bootstrap, qr/tmux set-option -q status-interval 15/, 'd2 shell ps bootstrap refreshes the tmux status block automatically for ticket sessions without hot-looping' );
like( $ps_bootstrap, qr/tmux set-option -q status-format\[0\].*tmux-status-top --width #\{client_width\}/s, 'd2 shell ps bootstrap renders the indicator strip into the first tmux status row' );
like( $ps_bootstrap, qr/tmux set-option -q status-format\[1\] \$ddDefaultStatus/, 'd2 shell ps bootstrap restores the normal tmux status row beneath the indicators' );
like( $ps_bootstrap, qr/\bps1 --mode compact --no-indicators/, 'd2 shell ps bootstrap suppresses prompt indicators when tmux owns the status line' );
like( $ps_bootstrap, qr/\[Console\]::InputEncoding\s*=\s*\[System\.Text\.UTF8Encoding\]::new\(\$false\)/, 'd2 shell ps bootstrap forces UTF-8 console input encoding so prompt glyphs survive on Windows' );
like( $ps_bootstrap, qr/\[Console\]::OutputEncoding\s*=\s*\[System\.Text\.UTF8Encoding\]::new\(\$false\)/, 'd2 shell ps bootstrap forces UTF-8 console output encoding so prompt glyphs survive on Windows' );
like( $ps_bootstrap, qr/\$ddPrompt\s*=\s*& .*?\bps1 --mode compact/s, 'd2 shell ps bootstrap captures the dashboard prompt text before splitting header and cursor lines' );
like( $ps_bootstrap, qr/Write-Host \$header/s, 'd2 shell ps bootstrap writes the status header line separately before returning the cursor prompt' );
like( $ps_bootstrap, qr/return '> '/s, 'd2 shell ps bootstrap falls back to a bare next-line cursor prompt when the helper returns no content' );
unlike( $ps_bootstrap, qr/\bPS1\b/, 'd2 shell ps bootstrap does not mention the POSIX PS1 environment variable' );
unlike( $ps_bootstrap, qr/function Invoke-DashboardShortcut \{/, 'd2 shell ps bootstrap no longer defines a d2 shortcut runner because d2 is now a real installed command' );
unlike( $ps_bootstrap, qr/Set-Alias d2 Invoke-DashboardShortcut/, 'd2 shell ps bootstrap no longer aliases d2 because d2 is now a real installed command' );
like( $ps_bootstrap, qr/Register-ArgumentCompleter/, 'd2 shell ps bootstrap wires argument completion for d2' );
like( $ps_bootstrap, qr/CommandName 'd2'/, 'd2 shell ps bootstrap registers completion for d2' );
like( $ps_bootstrap, qr/CommandName 'cdr', 'dd_cdr', 'which_dir'/, 'd2 shell ps bootstrap also registers cdr-family completion' );
my $tmux_status_render_top = _run("$perl -I'$lib' '$dashboard' ps1 --mode tmux-status-top --width 200 --cwd '$ENV{HOME}'");
like( $tmux_status_render_top, qr/[✅🚨]🐳.*🕒\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, 'd2 ps1 tmux-status-top keeps the full indicator strip plus trailing date-time on one line when the tmux width is wide enough' );
my $tmux_status_render_bottom = _run("$perl -I'$lib' '$dashboard' ps1 --mode tmux-status-bottom --width 200 --cwd '$ENV{HOME}'");
is( $tmux_status_render_bottom, '', 'd2 ps1 tmux-status-bottom stays empty when the tmux width is wide enough for one indicator line' );
{
    my $tmux_indicator_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $tmux_indicator_home;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
    my $tmux_indicator_paths = Developer::Dashboard::PathRegistry->new(
        home            => $tmux_indicator_home,
        cwd             => $tmux_indicator_home,
        workspace_roots => [],
        project_roots   => [],
    );
    my $tmux_indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $tmux_indicator_paths );
    make_path(
        File::Spec->catdir( $tmux_indicator_home, '.developer-dashboard', 'config' ),
    );
    open my $tmux_config_fh, '>:raw', File::Spec->catfile( $tmux_indicator_home, '.developer-dashboard', 'config', 'config.json' )
      or die "Unable to write tmux indicator config: $!";
    print {$tmux_config_fh} encode(
        'UTF-8',
        json_encode(
            {
                collectors => [
                    {
                        name      => 'heartbeat',
                        indicator => {
                            name  => 'heartbeat',
                            label => 'Heartbeat',
                            icon  => 'H',
                        },
                    },
                    {
                        name      => 'templated.rate',
                        indicator => {
                            name  => 'templated.rate',
                            label => 'Rate',
                            icon  => '[% data.rate %]%',
                        },
                    },
                ],
            }
        )
    );
    close $tmux_config_fh;
    $tmux_indicator_store->set_indicator(
        'heartbeat',
        name                 => 'heartbeat',
        label                => 'Heartbeat',
        icon                 => '96%',
        configured_label     => 'Heartbeat',
        configured_alias     => '',
        configured_icon      => 'H',
        configured_page_status_icon => '',
        status               => 'ok',
        collector_name       => 'heartbeat',
        managed_by_collector => 1,
        updated_at           => time,
    );
    $tmux_indicator_store->set_indicator(
        'templated.rate',
        name                 => 'templated.rate',
        label                => '59.46%',
        icon                 => '59.46%',
        icon_template        => '[% data.rate %]%',
        configured_label     => 'Rate',
        configured_alias     => '',
        configured_icon      => '[% data.rate %]%',
        configured_page_status_icon => '',
        status               => 'ok',
        collector_name       => 'templated.rate',
        managed_by_collector => 1,
        updated_at           => time,
    );

    my $live_tmux_status_top = _run("$perl -I'$lib' '$dashboard' ps1 --mode tmux-status-top --width 18 --cwd '$tmux_indicator_home'");
    my $live_tmux_status_bottom = _run("$perl -I'$lib' '$dashboard' ps1 --mode tmux-status-bottom --width 18 --cwd '$tmux_indicator_home'");
    my $live_tmux_status = $live_tmux_status_top . $live_tmux_status_bottom;
    like( $live_tmux_status, qr/✅96%/, 'dashboard tmux-status lines preserve live literal collector icons instead of resetting them to the config placeholder' );
    like( $live_tmux_status, qr/✅59\.46%/, 'dashboard tmux-status lines preserve TT-backed live collector icons containing percent signs instead of resetting them to the raw TT config' );
    unlike( $live_tmux_status, qr/\[%\s*data\.rate\s*%\]/, 'dashboard tmux-status lines do not leak raw TT-backed collector icon templates' );
}
my $path_del = _run("$perl -I'$lib' '$dashboard' path del foobar");
like( $path_del, qr/^Alias\s+Removed\s+Status/m, 'd2 path del defaults to a table summary' );
like( $path_del, qr/foobar\s+yes\s+removed/, 'd2 path del removes existing aliases' );
my $path_del_again = _run("$perl -I'$lib' '$dashboard' path del foobar");
like( $path_del_again, qr/foobar\s+no\s+no-change/, 'd2 path del is idempotent for missing aliases' );
my $path_del_dot = _run("cd '$dot_current_path_root' && $perl -I'$lib' '$dashboard' path del .");
like( $path_del_dot, qr/dot-current-path-root\s+yes\s+removed/, 'd2 path del . removes the alias that points at the current directory' );
my $path_rm = _run("$perl -I'$lib' '$dashboard' path rm right-here");
like( $path_rm, qr/right-here\s+yes\s+removed/, 'd2 path rm removes named aliases' );
my $file_del = _run("$perl -I'$lib' '$dashboard' file del notes");
like( $file_del, qr/^Alias\s+Removed\s+Status/m, 'd2 file del defaults to a table summary' );
like( $file_del, qr/notes\s+yes\s+removed/, 'd2 file del removes existing aliases' );
my $file_del_again = _run("$perl -I'$lib' '$dashboard' file del notes");
like( $file_del_again, qr/notes\s+no\s+no-change/, 'd2 file del is idempotent for missing aliases' );

my $docker_green_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green' );
make_path($docker_green_root);
open my $docker_green_base_fh, '>', File::Spec->catfile( $docker_green_root, 'compose.yml' )
  or die "Unable to write docker green base compose file: $!";
print {$docker_green_base_fh} "services:\n  green:\n    image: alpine\n";
close $docker_green_base_fh;
open my $docker_green_fh, '>', File::Spec->catfile( $docker_green_root, 'development.compose.yml' )
  or die "Unable to write docker green development compose file: $!";
print {$docker_green_fh} "services:\n  green:\n    environment:\n      MODE: development\n";
close $docker_green_fh;
my $docker_dry_run = _run("$perl -I'$lib' '$dashboard' docker compose --dry-run up -d --build green");
my $docker_dry_run_data = json_decode($docker_dry_run);
ok( grep( { $_ eq '-d' } @{ $docker_dry_run_data->{command} } ), 'd2 docker compose leaves short docker passthrough flags such as -d untouched' );
ok( grep( { $_ eq '--build' } @{ $docker_dry_run_data->{command} } ), 'd2 docker compose leaves docker passthrough flags such as --build untouched' );
ok( grep( { $_ eq 'green' } @{ $docker_dry_run_data->{services} } ), 'd2 docker compose still infers service names from passthrough args when docker flags are present' );
# The dry-run JSON carries native paths, so on Windows the compose files
# arrive with backslashes: match either separator in the path regexes below.
ok( grep( { /[\/\\]green[\/\\]compose\.yml\z/ } @{ $docker_dry_run_data->{files} } ), 'd2 docker compose always includes the green base compose file' );
ok( !grep( { /[\/\\]green[\/\\]development\.compose\.yml\z/ } @{ $docker_dry_run_data->{files} } ), 'd2 docker compose omits green development compose until enabled' );
my $docker_development_enable = _run("$perl -I'$lib' '$dashboard' docker development enable green");
like( $docker_development_enable, qr/"development"\s*:\s*1/, 'd2 docker development enable reports development mode enabled' );
ok( -f File::Spec->catfile( $docker_green_root, 'develop.yml' ), 'd2 docker development enable creates the develop.yml marker' );
my $docker_dev_dry_run = json_decode( _run("$perl -I'$lib' '$dashboard' docker compose --dry-run up green") );
my ($green_base_pos) = grep { $docker_dev_dry_run->{files}[$_] =~ /[\/\\]green[\/\\]compose\.yml\z/ } 0 .. $#{ $docker_dev_dry_run->{files} };
my ($green_dev_pos)  = grep { $docker_dev_dry_run->{files}[$_] =~ /[\/\\]green[\/\\]development\.compose\.yml\z/ } 0 .. $#{ $docker_dev_dry_run->{files} };
ok( defined $green_base_pos && defined $green_dev_pos, 'd2 docker compose includes both files after development enable' );
ok( defined $green_base_pos && defined $green_dev_pos && $green_base_pos < $green_dev_pos, 'd2 docker compose orders the development file after its base file' );
my $docker_development_disable = _run("$perl -I'$lib' '$dashboard' docker development disable green");
like( $docker_development_disable, qr/"development"\s*:\s*0/, 'd2 docker development disable reports development mode disabled' );
ok( !-e File::Spec->catfile( $docker_green_root, 'develop.yml' ), 'd2 docker development disable removes the develop.yml marker' );
unlink File::Spec->catfile( $docker_green_root, 'development.compose.yml' ) or die $!;
_run("$perl -I'$lib' '$dashboard' docker development enable green");
my $docker_missing_dev_dry_run = _run("$perl -I'$lib' '$dashboard' docker compose --dry-run config green");
like( $docker_missing_dev_dry_run, qr/"files"/, 'd2 docker compose succeeds when develop.yml exists but development.compose.yml is missing' );
ok( grep( { /[\/\\]green[\/\\]compose\.yml\z/ } @{ json_decode($docker_missing_dev_dry_run)->{files} } ), 'd2 docker compose retains the base file when the opted-in development file is missing' );
_run("$perl -I'$lib' '$dashboard' docker development disable green");
my $fake_bin = File::Spec->catdir( $ENV{HOME}, 'fake-bin' );
make_path($fake_bin);
my $fake_docker = File::Spec->catfile( $fake_bin, 'docker' );
open my $fake_docker_fh, '>', $fake_docker or die "Unable to write $fake_docker: $!";
print {$fake_docker_fh} <<'SH';
#!/bin/sh
last=''
for arg in "$@"; do last="$arg"; done
if [ "$last" = 'config' ]; then
    printf 'services:\n  green: {}\n'
else
    printf 'DOCKER:%s\n' "$*"
fi
SH
close $fake_docker_fh;
chmod 0755, $fake_docker or die "Unable to chmod $fake_docker: $!";
if ( $^O eq 'MSWin32' ) {
    # Same Windows twin as the cpanm/npx/make fakes: the sh fake above is
    # invisible to Windows program search (PATHEXT needs .exe/.bat/.cmd),
    # so the product's list-form system('docker', ...) died with
    # "'docker' is not recognized" (build #76, test 585). The micro in
    # build #77 proved the extensionless fake is never found even with a
    # correct ';' PATH, and that a docker.bat twin is found and runs.
    # Mirrors the sh fake: print a fake compose config when the last arg
    # is 'config', else echo the invocation.
    my $fake_docker_bat = File::Spec->catfile( $fake_bin, 'docker.bat' );
    open my $fake_docker_bat_fh, '>', $fake_docker_bat or die "Unable to write $fake_docker_bat: $!";
    print {$fake_docker_bat_fh} <<"BAT";
\@echo off
set "last="
for %%A in (%*) do set "last=%%A"
if "%last%"=="config" (
    echo services:
    echo   green: {}
) else (
    echo DOCKER:%*
)
BAT
    close $fake_docker_bat_fh;
}
my $docker_exec_output = _run("PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' docker compose up -d --build green");
like( $docker_exec_output, qr/^DOCKER:compose /m, 'd2 docker compose execs the real docker command for non-dry-run invocations' );
unlike( $docker_exec_output, qr/\"command\"\s*:/, 'd2 docker compose no longer prints JSON envelopes for non-dry-run invocations' );
my $docker_disable = _run("$perl -I'$lib' '$dashboard' docker disable green");
like( $docker_disable, qr/"service"\s*:\s*"green"/, 'd2 docker disable reports the toggled service name' );
like( $docker_disable, qr/"disabled"\s*:\s*1/, 'd2 docker disable reports the service as disabled' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'd2 docker disable creates the disabled marker in the home docker root when no project layer is active' );
my $docker_enable = _run("$perl -I'$lib' '$dashboard' docker enable green");
like( $docker_enable, qr/"service"\s*:\s*"green"/, 'd2 docker enable reports the toggled service name' );
like( $docker_enable, qr/"disabled"\s*:\s*0/, 'd2 docker enable reports the service as enabled' );
ok( !-f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'd2 docker enable removes the disabled marker from the home docker root' );

# DD-919: multiple service names in one invocation.
my $docker_disable_multi = _run("$perl -I'$lib' '$dashboard' docker disable green blue");
like( $docker_disable_multi, qr/"service"\s*:\s*"green"/, 'd2 docker disable with multiple names reports the first toggled service' );
like( $docker_disable_multi, qr/"service"\s*:\s*"blue"/,  'd2 docker disable with multiple names reports the second toggled service' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'd2 docker disable with multiple names disables the first service' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'blue',  'disabled.yml' ), 'd2 docker disable with multiple names disables the second service' );
my $docker_enable_multi = _run("$perl -I'$lib' '$dashboard' docker enable green blue");
like( $docker_enable_multi, qr/"service"\s*:\s*"green"/, 'd2 docker enable with multiple names reports the first toggled service' );
like( $docker_enable_multi, qr/"service"\s*:\s*"blue"/,  'd2 docker enable with multiple names reports the second toggled service' );
ok( !-f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'd2 docker enable with multiple names enables the first service' );
ok( !-f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'blue',  'disabled.yml' ), 'd2 docker enable with multiple names enables the second service' );
my ( $docker_partial_stdout, $docker_partial_stderr, $docker_partial_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' docker disable green ../escape");
my $docker_disable_partial = decode( 'UTF-8', $docker_partial_stdout . $docker_partial_stderr );
ok( $docker_partial_exit != 0, 'd2 docker disable with a bad name among good ones exits non-zero' );
like( $docker_disable_partial, qr/"service"\s*:\s*"green"/, 'd2 docker disable with a bad name among good ones still reports the good one' );
like( $docker_disable_partial, qr/escape/, 'd2 docker disable with a bad name among good ones reports an error for the bad one' );
ok( -f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'd2 docker disable with a bad name among good ones still disables the good one' );
_run("$perl -I'$lib' '$dashboard' docker enable green");
ok( !-f File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green', 'disabled.yml' ), 'green is re-enabled after the partial-failure test so later assertions see its expected default state' );
my $docker_blue_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'blue' );
make_path($docker_blue_root);
open my $docker_blue_fh, '>', File::Spec->catfile( $docker_blue_root, 'compose.yml' )
  or die "Unable to write docker blue compose file: $!";
print {$docker_blue_fh} "services:\n  blue:\n    image: alpine\n";
close $docker_blue_fh;
open my $docker_blue_disabled_fh, '>', File::Spec->catfile( $docker_blue_root, 'disabled.yml' )
  or die "Unable to write docker blue disabled marker: $!";
print {$docker_blue_disabled_fh} "---\ndisabled: 1\n";
close $docker_blue_disabled_fh;
my $docker_list = json_decode( _run("$perl -I'$lib' '$dashboard' docker list") );
is_deeply(
    [ map { $_->{service} } @{$docker_list} ],
    [ qw(blue green) ],
    'd2 docker list reports all isolated services in sorted order',
);
is_deeply(
    {
        map { $_->{service} => $_->{disabled} } @{$docker_list}
    },
    {
        blue  => 1,
        green => 0,
    },
    'd2 docker list reports enabled and disabled state',
);
my $docker_enabled_list = json_decode( _run("$perl -I'$lib' '$dashboard' docker list --enabled") );
is_deeply(
    [ map { $_->{service} } @{$docker_enabled_list} ],
    [qw(green)],
    'd2 docker list --enabled keeps only enabled services',
);
my $docker_disabled_list = json_decode( _run("$perl -I'$lib' '$dashboard' docker list --disabled") );
is_deeply(
    [ map { $_->{service} } @{$docker_disabled_list} ],
    [qw(blue)],
    'd2 docker list --disabled keeps only disabled services',
);
my $fake_cpanm_log = File::Spec->catfile( $fake_bin, 'cpanm.log' );
my $fake_cpanm = File::Spec->catfile( $fake_bin, 'cpanm' );
open my $fake_cpanm_fh, '>', $fake_cpanm or die "Unable to write $fake_cpanm: $!";
print {$fake_cpanm_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" >> '$fake_cpanm_log'
exit 0
SH
close $fake_cpanm_fh;
chmod 0755, $fake_cpanm or die "Unable to chmod $fake_cpanm: $!";
if ( $^O eq 'MSWin32' ) {
    # Windows cannot execute the extensionless sh fake above: CreateProcess
    # skips it, and Strawberry's cpanm.bat then runs `perl -x -S`, which
    # finds the fake by plain name and dies "No Perl script found in input"
    # on its #!/bin/sh line (build #50). A .bat twin with the same logging
    # behaviour is what Windows actually runs; the micro in build #51
    # proved the twin runs while the sh fake never does.
    my $fake_cpanm_bat = File::Spec->catfile( $fake_bin, 'cpanm.bat' );
    open my $fake_cpanm_bat_fh, '>', $fake_cpanm_bat or die "Unable to write $fake_cpanm_bat: $!";
    print {$fake_cpanm_bat_fh} <<"BAT";
\@echo off
echo %*>>"$fake_cpanm_log"
exit /b 0
BAT
    close $fake_cpanm_bat_fh;
}
my $fake_npx_log = File::Spec->catfile( $fake_bin, 'npx.log' );
my $fake_npx = File::Spec->catfile( $fake_bin, 'npx' );
open my $fake_npx_fh, '>', $fake_npx or die "Unable to write $fake_npx: $!";
print {$fake_npx_fh} <<"SH";
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> '$fake_npx_log'
shift
shift
shift
for spec in "\$@"; do
  name=\${spec%%@*}
  mkdir -p "\$PWD/node_modules/\$name"
done
exit 0
SH
close $fake_npx_fh;
chmod 0755, $fake_npx or die "Unable to chmod $fake_npx: $!";
if ( $^O eq 'MSWin32' ) {
    # Same Windows twin as the cpanm fake above: the sh fake is invisible
    # to CreateProcess, so the real Node npx ran instead and npx.log was
    # never created (build #50 died reading it at line 1974).
    my $fake_npx_bat = File::Spec->catfile( $fake_bin, 'npx.bat' );
    open my $fake_npx_bat_fh, '>', $fake_npx_bat or die "Unable to write $fake_npx_bat: $!";
    print {$fake_npx_bat_fh} <<"BAT";
\@echo off
echo %*^|cwd=%CD%>>"$fake_npx_log"
shift
shift
shift
:loop
if "%~1"=="" goto done
for /f "delims=@ tokens=1" %%a in ("%~1") do mkdir "%CD%\\node_modules\\%%a" 2>nul
shift
goto loop
:done
exit /b 0
BAT
    close $fake_npx_bat_fh;
}
my $fake_make_log = File::Spec->catfile( $fake_bin, 'make.log' );
my $fake_make = File::Spec->catfile( $fake_bin, 'make' );
open my $fake_make_fh, '>', $fake_make or die "Unable to write $fake_make: $!";
print {$fake_make_fh} <<"SH";
#!/bin/sh
printf '%s|cwd=%s\\n' "\$*" "\$PWD" >> '$fake_make_log'
exit 0
SH
close $fake_make_fh;
chmod 0755, $fake_make or die "Unable to chmod $fake_make: $!";
if ( $^O eq 'MSWin32' ) {
    # Same Windows twin as the cpanm fake above: no `make` exists on the
    # Windows node, so without this the Makefile step cannot run at all.
    my $fake_make_bat = File::Spec->catfile( $fake_bin, 'make.bat' );
    open my $fake_make_bat_fh, '>', $fake_make_bat or die "Unable to write $fake_make_bat: $!";
    print {$fake_make_bat_fh} <<"BAT";
\@echo off
echo %*^|cwd=%CD%>>"$fake_make_log"
exit /b 0
BAT
    close $fake_make_bat_fh;
}
my $fake_sudo = File::Spec->catfile( $fake_bin, 'sudo' );
open my $fake_sudo_fh, '>', $fake_sudo or die "Unable to write $fake_sudo: $!";
print {$fake_sudo_fh} <<"SH";
#!/bin/sh
exec "\$@"
SH
close $fake_sudo_fh;
chmod 0755, $fake_sudo or die "Unable to chmod $fake_sudo: $!";
my $skill_repo_root = File::Spec->catdir( $ENV{HOME}, 'skill-fixtures' );
my $skill_repo = File::Spec->catdir( $skill_repo_root, 'demo-skill' );
make_path( File::Spec->catdir( $skill_repo, 'cli', 'foo.d' ) );
make_path( File::Spec->catdir( $skill_repo, 'config' ) );
make_path( File::Spec->catdir( $skill_repo, 'dashboards', 'nav' ) );
open my $skill_command_fh, '>', File::Spec->catfile( $skill_repo, 'cli', 'foo' ) or die "Unable to write skill command: $!";
print {$skill_command_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nif (\@ARGV) {\n    print join('|', \@ARGV), qq{\\n};\n    exit 0;\n}\nprint qq{foo:};\nmy \$answer = <STDIN>;\ndefined \$answer or die qq{missing stdin\\n};\nprint qq{answer=\$answer};\n";
close $skill_command_fh;
chmod 0755, File::Spec->catfile( $skill_repo, 'cli', 'foo' ) or die "Unable to chmod skill command: $!";
open my $skill_hook_fh, '>', File::Spec->catfile( $skill_repo, 'cli', 'foo.d', '00-pre.pl' ) or die "Unable to write skill hook: $!";
print {$skill_hook_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{skill-hook\\n};\n";
close $skill_hook_fh;
chmod 0755, File::Spec->catfile( $skill_repo, 'cli', 'foo.d', '00-pre.pl' ) or die "Unable to chmod skill hook: $!";
open my $skill_config_fh, '>', File::Spec->catfile( $skill_repo, 'config', 'config.json' ) or die "Unable to write skill config: $!";
print {$skill_config_fh} qq|{"skill_name":"demo-skill"}\n|;
close $skill_config_fh;
open my $skill_cpanfile_fh, '>', File::Spec->catfile( $skill_repo, 'cpanfile' ) or die "Unable to write skill cpanfile: $!";
print {$skill_cpanfile_fh} "requires 'JSON::XS';\n";
close $skill_cpanfile_fh;
open my $skill_package_json_fh, '>', File::Spec->catfile( $skill_repo, 'package.json' ) or die "Unable to write skill package.json: $!";
print {$skill_package_json_fh} qq|{"name":"demo-skill-node","version":"1.0.0","dependencies":{"left-pad":"1.3.0"}}\n|;
close $skill_package_json_fh;
open my $skill_makefile_fh, '>', File::Spec->catfile( $skill_repo, 'Makefile' ) or die "Unable to write skill Makefile: $!";
print {$skill_makefile_fh} ".PHONY: all test install clean\nall:\n\t\@:\ntest:\n\t\@:\ninstall:\n\t\@:\nclean:\n\t\@:\n";
close $skill_makefile_fh;
open my $skill_ddfile_fh, '>', File::Spec->catfile( $skill_repo, 'ddfile' ) or die "Unable to write skill ddfile: $!";
close $skill_ddfile_fh;
open my $skill_ddfile_local_fh, '>', File::Spec->catfile( $skill_repo, 'ddfile.local' ) or die "Unable to write skill ddfile.local: $!";
close $skill_ddfile_local_fh;
open my $skill_index_fh, '>', File::Spec->catfile( $skill_repo, 'dashboards', 'index' ) or die "Unable to write skill index: $!";
print {$skill_index_fh} "TITLE: Demo Skill Index\n:--------------------------------------------------------------------------------:\nBOOKMARK: index\n:--------------------------------------------------------------------------------:\nHTML:\nDemo Skill Index\n";
close $skill_index_fh;
open my $skill_page_fh, '>', File::Spec->catfile( $skill_repo, 'dashboards', 'foo' ) or die "Unable to write skill page: $!";
print {$skill_page_fh} "TITLE: Demo Skill Foo\n:--------------------------------------------------------------------------------:\nBOOKMARK: foo\n:--------------------------------------------------------------------------------:\nHTML:\nDemo Skill Foo\n";
close $skill_page_fh;
open my $skill_nav_fh, '>', File::Spec->catfile( $skill_repo, 'dashboards', 'nav', 'demo.tt' ) or die "Unable to write skill nav: $!";
print {$skill_nav_fh} "<div>Demo Skill Nav</div>\n";
close $skill_nav_fh;
{
    my $cwd_before_skill_repo = getcwd();
    chdir $skill_repo or die "Unable to chdir to $skill_repo: $!";
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial demo skill';
        return $? >> 8;
    };
    is( $exit, 0, 'skill fixture repository initializes cleanly for CLI smoke coverage' ) or diag $stderr;
    chdir $cwd_before_skill_repo or die "Unable to chdir back to $cwd_before_skill_repo: $!";
}
my $skill_install = _run("PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' skills install -o json 'file://$skill_repo'");
like( $skill_install, qr/"repo_name"\s*:\s*"demo-skill"/, 'd2 skills install clones the skill into the isolated skills root' );
my ( $skill_progress_stdout, $skill_progress_stderr, $skill_progress_exit ) = _sh_capture(
    "PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' skills install -o json 'file://$skill_repo'",
    { env => { DEVELOPER_DASHBOARD_PROGRESS => 1 } },
);
is( $skill_progress_exit, 0, 'd2 skills install still succeeds when forced terminal progress output is enabled' );
like( $skill_progress_stdout, qr/"repo_name"\s*:\s*"demo-skill"/, 'd2 skills install keeps the machine-readable install payload on stdout while progress is enabled' );
like( $skill_progress_stderr, qr/d2 skills install progress/, 'd2 skills install progress output prints the task-board title when enabled' );
like( $skill_progress_stderr, qr/\[ \] Fetch skill source/, 'd2 skills install progress output prints the full task list before work begins' );
like( $skill_progress_stderr, qr/\[OK\] Install package\.json dependencies from .*demo-skill.*package\.json/, 'd2 skills install progress output shows that package.json was detected and handed to npx-wrapped npm' );
like( $skill_progress_stderr, qr/\[OK\] Install Makefile dependencies from .*demo-skill.*Makefile/, 'd2 skills install progress output shows that Makefile dependencies were processed before ddfile work' );
like( $skill_progress_stderr, qr/\[OK\] Install cpanfile dependencies/, 'd2 skills install progress output marks dependency steps complete after work finishes' );
like( $skill_progress_stderr, qr/\[OK\] Install ddfile dependencies \(skipped: no dependency installs needed\)/, 'd2 skills install reports an existing empty ddfile without claiming it is missing' );
like( $skill_progress_stderr, qr/\[OK\] Install ddfile\.local dependencies \(skipped: no dependency installs needed\)/, 'd2 skills install reports an existing empty ddfile.local without claiming it is missing' );
unlike( $skill_progress_stderr, qr/Install ddfile(?:\.local)? dependencies \(skipped: ddfile(?:\.local)? not present\)/, 'd2 skills install does not call a present dependency manifest missing' );
open my $fake_npx_log_fh, '<', $fake_npx_log or die "Unable to read $fake_npx_log: $!";
my @fake_npx_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$fake_npx_log_fh>;
close $fake_npx_log_fh;
ok( scalar @fake_npx_steps, 'd2 skills install runs npx when the skill ships a package.json' );
my $portable_npm_stage_root = _portable_path(
    File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cache', 'node-package-installs' )
);
like(
    _portable_output_text($fake_npx_steps[0]),
    qr/^--yes npm install left-pad\@1\.3\.0\|cwd=\Q$portable_npm_stage_root\E[\/\\]npm-install-/,
    'd2 skills install stages npx-wrapped npm work under the dashboard runtime cache instead of using bare HOME as the npm project root',
);
ok(
    -d File::Spec->catdir( $ENV{HOME}, 'node_modules', 'left-pad' ),
    'd2 skills install merges staged Node dependencies into HOME/node_modules',
);
open my $fake_make_log_fh, '<', $fake_make_log or die "Unable to read $fake_make_log: $!";
my @fake_make_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$fake_make_log_fh>;
close $fake_make_log_fh;
my $demo_skill_dir = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'demo-skill' );
is_deeply(
    [ map { _portable_output_text($_) } @fake_make_steps[ -4 .. -1 ] ],
    [ map { _portable_output_text($_) } (
        "|cwd=$demo_skill_dir",
        "test|cwd=$demo_skill_dir",
        "install|cwd=$demo_skill_dir",
        "clean|cwd=$demo_skill_dir",
    ) ],
    'd2 skills install runs the default Makefile command chain for skills that ship a Makefile',
);
unlink $fake_make_log;
my $skill_install_notest = _run("PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' skills install --notest -o json 'file://$skill_repo'");
like( $skill_install_notest, qr/"repo_name"\s*:\s*"demo-skill"/, 'd2 skills install --notest still installs the requested skill successfully' );
open my $fake_make_notest_fh, '<', $fake_make_log or die "Unable to read $fake_make_log after --notest install: $!";
my @fake_make_notest_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$fake_make_notest_fh>;
close $fake_make_notest_fh;
is_deeply(
    [ map { _portable_output_text($_) } @fake_make_notest_steps[ -3 .. -1 ] ],
    [ map { _portable_output_text($_) } (
        "|cwd=$demo_skill_dir",
        "install|cwd=$demo_skill_dir",
        "clean|cwd=$demo_skill_dir",
    ) ],
    'd2 skills install --notest skips the Makefile test target while still running make, make install, and make clean',
);
my $home_root_ddfile = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'ddfile' );
open my $home_root_ddfile_fh, '<', $home_root_ddfile or die "Unable to read $home_root_ddfile: $!";
my @registered_skill_sources = grep { defined && $_ ne '' && $_ !~ /\A#/ } map { chomp; $_ } <$home_root_ddfile_fh>;
close $home_root_ddfile_fh;
is_deeply(
    \@registered_skill_sources,
    ["file://$skill_repo"],
    'd2 skills install records one non-duplicated source in the home root ddfile after repeated explicit installs',
);
my $second_skill_repo = File::Spec->catdir( $ENV{HOME}, 'demo-skill-two-repo' );
make_path($second_skill_repo);
{
    my $cwd_before_second_skill_repo = getcwd();
    chdir $second_skill_repo or die "Unable to chdir to $second_skill_repo: $!";
    make_path('cli');
    make_path('config');
    open my $second_skill_env_fh, '>', '.env' or die "Unable to write .env for $second_skill_repo: $!";
    print {$second_skill_env_fh} "VERSION=1.00\n";
    close $second_skill_env_fh;
    open my $second_skill_cli_fh, '>', File::Spec->catfile( 'cli', 'hello' ) or die "Unable to write cli/hello for $second_skill_repo: $!";
    print {$second_skill_cli_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{demo-skill-two\\n};\n";
    close $second_skill_cli_fh;
    chmod 0755, File::Spec->catfile( 'cli', 'hello' ) or die "Unable to chmod cli/hello for $second_skill_repo: $!";
    open my $second_skill_config_fh, '>', File::Spec->catfile( 'config', 'config.json' ) or die "Unable to write config/config.json for $second_skill_repo: $!";
    print {$second_skill_config_fh} "{}\n";
    close $second_skill_config_fh;
    my ( $second_repo_stdout, $second_repo_stderr, $second_repo_exit ) = capture {
        system 'git', 'init';
        system 'git', 'config', 'user.email', 'test@example.com' if $? == 0;
        system 'git', 'config', 'user.name', 'Test' if $? == 0;
        system 'git', 'add', '.' if $? == 0;
        system 'git', 'commit', '-m', 'Initial second demo skill' if $? == 0;
    };
    is( $second_repo_exit >> 8, 0, 'second skill fixture repository initializes cleanly for multi-install smoke coverage' )
      or diag $second_repo_stdout . $second_repo_stderr;
    chdir $cwd_before_second_skill_repo or die "Unable to chdir back to $cwd_before_second_skill_repo: $!";
}
my $multi_skill_install = _run("$perl -I'$lib' '$dashboard' skills install -o json 'file://$skill_repo' 'file://$second_skill_repo'");
like( $multi_skill_install, qr/"sources"\s*:\s*\[/, 'd2 skills install accepts more than one explicit source in one command' );
like( $multi_skill_install, qr/"repo_name"\s*:\s*"demo-skill-two-repo"/, 'd2 skills install reports the later source result in a multi-source install' );
open my $multi_root_ddfile_fh, '<', $home_root_ddfile or die "Unable to read $home_root_ddfile after multi-source install: $!";
my @multi_registered_skill_sources = grep { defined && $_ ne '' && $_ !~ /\A#/ } map { chomp; $_ } <$multi_root_ddfile_fh>;
close $multi_root_ddfile_fh;
is_deeply(
    \@multi_registered_skill_sources,
    [ "file://$skill_repo", "file://$second_skill_repo" ],
    'd2 skills install records every multi-source argument once in the home root ddfile',
);
my $singular_skill_list = _run("$perl -I'$lib' '$dashboard' skill list -o json");
like( $singular_skill_list, qr/"name"\s*:\s*"demo-skill-two-repo"/, 'd2 skill singular alias reaches the skills management command family' );
{
    my $cwd_before_version_bump = getcwd();
    chdir $second_skill_repo or die "Unable to chdir to $second_skill_repo: $!";
    open my $bumped_env_fh, '>', '.env' or die "Unable to rewrite .env for $second_skill_repo: $!";
    print {$bumped_env_fh} "VERSION=1.01\n";
    close $bumped_env_fh;
    my ( $bump_stdout, $bump_stderr, $bump_exit ) = capture {
        system 'git', 'add', '.env';
        system 'git', 'commit', '-m', 'Bump demo skill version' if $? == 0;
    };
    is( $bump_exit >> 8, 0, 'second demo skill fixture commits a newer .env VERSION for update-all summary coverage' )
      or diag $bump_stdout . $bump_stderr;
    chdir $cwd_before_version_bump or die "Unable to chdir back to $cwd_before_version_bump: $!";
}
my ( $skill_install_registered_stdout, $skill_install_registered_stderr, $skill_install_registered_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    system( $perl, '-I', $lib, $dashboard, 'skills', 'install' );
};
is( $skill_install_registered_exit >> 8, 0, 'bare d2 skills install exits successfully when the home root ddfile has registered sources' );
like( $skill_install_registered_stderr, qr/d2 skills install progress/, 'bare d2 skills install prints a source-level progress rundown before replaying the home root ddfile' );
like( $skill_install_registered_stderr, qr/Install\/update file:\/\/\Q$skill_repo\E/, 'bare d2 skills install progress names each registered source before work starts' );
like(
    $skill_install_registered_stdout,
    qr/Skill\s+Source\s+Before\s+After\s+Status/,
    'bare d2 skills install prints a table summary by default',
);
like(
    $skill_install_registered_stdout,
    qr/demo-skill-two-repo\s+file:\/\/\Q$second_skill_repo\E\s+1\.00\s+1\.01\s+updated/,
    'bare d2 skills install table reports updated skills with before and after .env versions',
);
my ( $skill_install_no_update_stdout, $skill_install_no_update_stderr, $skill_install_no_update_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    system( $perl, '-I', $lib, $dashboard, 'skills', 'install' );
};
is( $skill_install_no_update_exit >> 8, 0, 'bare d2 skills install exits successfully when no registered skill version changes' );
like( $skill_install_no_update_stderr, qr/d2 skills install progress/, 'bare d2 skills install still prints progress for no-change update-all runs' );
like( $skill_install_no_update_stdout, qr/No update\./, 'bare d2 skills install states no update when every .env VERSION is unchanged' );
like(
    $skill_install_no_update_stdout,
    qr/demo-skill-two-repo\s+file:\/\/\Q$second_skill_repo\E\s+1\.01\s+1\.01\s+no update/,
    'bare d2 skills install table reports unchanged before and after .env versions',
);
my $fake_apt = File::Spec->catfile( $fake_bin, 'apt-get' );
open my $fake_apt_fh, '>', $fake_apt or die "Unable to write $fake_apt: $!";
print {$fake_apt_fh} <<"SH";
#!/bin/sh
printf 'apt exploded for %s\\n' "\$*" >&2
exit 1
SH
close $fake_apt_fh;
chmod 0755, $fake_apt or die "Unable to chmod $fake_apt: $!";
my $fake_dpkg_query = File::Spec->catfile( $fake_bin, 'dpkg-query' );
open my $fake_dpkg_query_fh, '>', $fake_dpkg_query or die "Unable to write $fake_dpkg_query: $!";
print {$fake_dpkg_query_fh} <<"SH";
#!/bin/sh
exit 1
SH
close $fake_dpkg_query_fh;
chmod 0755, $fake_dpkg_query or die "Unable to chmod $fake_dpkg_query: $!";
my $failing_skill_repo = File::Spec->catdir( $skill_repo_root, 'failing-apt-skill' );
make_path( File::Spec->catdir( $failing_skill_repo, 'config' ) );
open my $failing_skill_env_fh, '>', File::Spec->catfile( $failing_skill_repo, '.env' ) or die "Unable to write failing skill .env: $!";
print {$failing_skill_env_fh} "VERSION=1.00\n";
close $failing_skill_env_fh;
open my $failing_skill_config_fh, '>', File::Spec->catfile( $failing_skill_repo, 'config', 'config.json' )
  or die "Unable to write failing skill config: $!";
print {$failing_skill_config_fh} "{}\n";
close $failing_skill_config_fh;
open my $failing_skill_apt_fh, '>', File::Spec->catfile( $failing_skill_repo, 'aptfile' )
  or die "Unable to write failing skill aptfile: $!";
print {$failing_skill_apt_fh} "dd-smoke-fail-package\n";
close $failing_skill_apt_fh;
{
    my $cwd_before_failing_skill_repo = getcwd();
    chdir $failing_skill_repo or die "Unable to chdir to $failing_skill_repo: $!";
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial failing apt skill';
        return $? >> 8;
    };
    is( $exit, 0, 'failing apt skill fixture repository initializes cleanly for install error reporting coverage' )
      or diag $stdout . $stderr;
    chdir $cwd_before_failing_skill_repo or die "Unable to chdir back to $cwd_before_failing_skill_repo: $!";
}
my ( $failed_skill_stdout, $failed_skill_stderr, $failed_skill_exit ) = _sh_capture(
    "PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' skills install 'file://$failing_skill_repo'",
    { env => { DEVELOPER_DASHBOARD_PROGRESS => 1, DD_TEST_OS => 'linux', DD_TEST_DEBIAN_LIKE => 1 } },
);
is( $failed_skill_exit, 1, 'd2 skills install exits non-zero when aptfile installation fails' );
like( $failed_skill_stderr, qr/\[X\] Install aptfile dependencies from .*failing-apt-skill.*aptfile \(error: Failed to install skill apt dependencies .*?\)/, 'd2 skills install progress prints the failure reason directly on the failed aptfile row' );
like( $failed_skill_stdout, qr/^Error: Failed to install skill apt dependencies /m, 'd2 skills install table mode prints the install error instead of a no-update summary when installation fails' );
unlike( $failed_skill_stdout, qr/No update\./, 'd2 skills install does not claim no update when installation failed' );

my $manifest_global_skill_repo = File::Spec->catdir( $ENV{HOME}, 'manifest-global-skill-fixture' );
make_path($manifest_global_skill_repo);
{
    my $cwd_before_manifest_global_skill_repo = getcwd();
    chdir $manifest_global_skill_repo or die "Unable to chdir to $manifest_global_skill_repo: $!";
    make_path('cli');
    make_path('config');
    open my $manifest_global_env_fh, '>', '.env' or die "Unable to write .env for $manifest_global_skill_repo: $!";
    print {$manifest_global_env_fh} "VERSION=1.00\n";
    close $manifest_global_env_fh;
    open my $manifest_global_cli_fh, '>', File::Spec->catfile( 'cli', 'hi' ) or die "Unable to write cli/hi for $manifest_global_skill_repo: $!";
    print {$manifest_global_cli_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{manifest-global\\n};\n";
    close $manifest_global_cli_fh;
    chmod 0755, File::Spec->catfile( 'cli', 'hi' ) or die "Unable to chmod cli/hi for $manifest_global_skill_repo: $!";
    open my $manifest_global_config_fh, '>', File::Spec->catfile( 'config', 'config.json' ) or die "Unable to write config/config.json for $manifest_global_skill_repo: $!";
    print {$manifest_global_config_fh} "{}\n";
    close $manifest_global_config_fh;
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial manifest global skill';
        return $? >> 8;
    };
    is( $exit, 0, 'manifest global skill fixture repository initializes cleanly for CLI smoke coverage' ) or diag $stderr;
    chdir $cwd_before_manifest_global_skill_repo or die "Unable to chdir back to $cwd_before_manifest_global_skill_repo: $!";
}

my $manifest_local_skill_repo = File::Spec->catdir( $ENV{HOME}, 'manifest-local-skill-fixture' );
make_path($manifest_local_skill_repo);
{
    my $cwd_before_manifest_local_skill_repo = getcwd();
    chdir $manifest_local_skill_repo or die "Unable to chdir to $manifest_local_skill_repo: $!";
    make_path('cli');
    make_path('config');
    open my $manifest_local_env_fh, '>', '.env' or die "Unable to write .env for $manifest_local_skill_repo: $!";
    print {$manifest_local_env_fh} "VERSION=1.00\n";
    close $manifest_local_env_fh;
    open my $manifest_local_cli_fh, '>', File::Spec->catfile( 'cli', 'hi' ) or die "Unable to write cli/hi for $manifest_local_skill_repo: $!";
    print {$manifest_local_cli_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{manifest-local\\n};\n";
    close $manifest_local_cli_fh;
    chmod 0755, File::Spec->catfile( 'cli', 'hi' ) or die "Unable to chmod cli/hi for $manifest_local_skill_repo: $!";
    open my $manifest_local_config_fh, '>', File::Spec->catfile( 'config', 'config.json' ) or die "Unable to write config/config.json for $manifest_local_skill_repo: $!";
    print {$manifest_local_config_fh} "{}\n";
    close $manifest_local_config_fh;
    my ( $stdout, $stderr, $exit ) = capture {
        system 'git', 'init', '--quiet';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.email', 'test@example.com';
        return $? >> 8 if $? != 0;
        system 'git', 'config', 'user.name', 'Test';
        return $? >> 8 if $? != 0;
        system 'git', 'add', '.';
        return $? >> 8 if $? != 0;
        system 'git', 'commit', '-m', 'Initial manifest local skill';
        return $? >> 8;
    };
    is( $exit, 0, 'manifest local skill fixture repository initializes cleanly for CLI smoke coverage' ) or diag $stderr;
    chdir $cwd_before_manifest_local_skill_repo or die "Unable to chdir back to $cwd_before_manifest_local_skill_repo: $!";
}

my $manifest_install_root = File::Spec->catdir( $ENV{HOME}, 'manifest-install-root' );
make_path($manifest_install_root);
open my $manifest_global_ddfile_fh, '>', File::Spec->catfile( $manifest_install_root, 'ddfile' )
  or die "Unable to write ddfile under $manifest_install_root: $!";
print {$manifest_global_ddfile_fh} "file://$manifest_global_skill_repo\n";
close $manifest_global_ddfile_fh;
open my $manifest_local_ddfile_fh, '>', File::Spec->catfile( $manifest_install_root, 'ddfile.local' )
  or die "Unable to write ddfile.local under $manifest_install_root: $!";
print {$manifest_local_ddfile_fh} "file://$manifest_local_skill_repo\n";
close $manifest_local_ddfile_fh;

{
    my $cwd_before_manifest_install_root = getcwd();
    chdir $manifest_install_root or die "Unable to chdir to $manifest_install_root: $!";
    my $manifest_install = _run("$perl -I'$lib' '$dashboard' skills install --ddfile -o json");
    like( $manifest_install, qr/"success"\s*:\s*1/, 'd2 skills install --ddfile succeeds when manifest files are present' );
    ok( -d File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'manifest-global-skill-fixture' ), 'd2 skills install --ddfile installs ddfile entries into the home DD-OOP-LAYER skills root' );
    ok( -d File::Spec->catdir( $manifest_install_root, 'skills', 'manifest-local-skill-fixture' ), 'd2 skills install --ddfile installs ddfile.local entries into the current skill-local skills root' );
    chdir $cwd_before_manifest_install_root or die "Unable to chdir back to $cwd_before_manifest_install_root: $!";
}

my $skill_dotted_dispatch = _run("$perl -I'$lib' '$dashboard' demo-skill.foo alpha beta");
like( $skill_dotted_dispatch, qr/skill-hook/, 'd2 <skill>.<command> runs skill-local hooks before the skill command body' );
like( $skill_dotted_dispatch, qr/alpha\|beta/, 'd2 <skill>.<command> forwards remaining args to the skill command body' );

# DD-954: a skill with ONLY a cli/__init__ self-script (no other subcommand,
# and no top-level .d2/cli/<name>) responds to a bare "d2 <name>"
# invocation by running that __init__ script directly.
my $init_skill_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'init-skill', 'cli' );
make_path($init_skill_root);
my $init_skill_command = File::Spec->catfile( $init_skill_root, '__init__' );
open my $init_skill_fh, '>', $init_skill_command or die "Unable to write $init_skill_command: $!";
print {$init_skill_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{init-self|\@ARGV\\n};\n";
close $init_skill_fh;
chmod 0755, $init_skill_command or die "Unable to chmod $init_skill_command: $!";
my $bare_init_dispatch = _run("$perl -I'$lib' '$dashboard' init-skill one two");
like( $bare_init_dispatch, qr/init-self\|one two/, 'd2 <skill-with-only-init> runs the skill\'s own cli/__init__ with no subcommand needed' );

# An explicit top-level command for the same name still wins over __init__.
my $init_override_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
make_path($init_override_root);
my $init_override_command = File::Spec->catfile( $init_override_root, 'init-skill' );
open my $init_override_fh, '>', $init_override_command or die "Unable to write $init_override_command: $!";
print {$init_override_fh} "#!/usr/bin/env perl\nuse strict;\nuse warnings;\nprint qq{top-level-wins\\n};\n";
close $init_override_fh;
chmod 0755, $init_override_command or die "Unable to chmod $init_override_command: $!";
my $bare_init_overridden = _run("$perl -I'$lib' '$dashboard' init-skill");
like( $bare_init_overridden, qr/top-level-wins/, 'an explicit top-level .d2/cli/<name> still wins over a skill\'s own cli/__init__' );
unlike( $bare_init_overridden, qr/init-self/, 'the __init__ fallback is never reached once a top-level command resolves' );
unlink $init_override_command or die "Unable to remove $init_override_command: $!";
{
    # 'ask' is now a reserved built-in command, so this stdin-passthrough check
    # uses a non-reserved custom command name to keep exercising the user
    # top-level command path (built-ins resolve before custom commands).
    my $interactive_cli = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'interactive-demo' );
    open my $interactive_cli_fh, '>', $interactive_cli or die "Unable to write $interactive_cli: $!";
    print {$interactive_cli_fh} <<'PERL';
#!/usr/bin/env perl
use strict;
use warnings;
print "foo:";
my $answer = <STDIN>;
defined $answer or die "missing stdin\n";
print "answer=$answer";
PERL
    close $interactive_cli_fh;
    chmod 0755, $interactive_cli or die "Unable to chmod $interactive_cli: $!";

    my $top_level_prompt = _run_interactive_command(
        command => [ $perl, '-I', $lib, $dashboard, 'interactive-demo' ],
        input   => "bar\n",
    );
    is( $top_level_prompt->{exit_code}, 0, 'dashboard top-level CLI command keeps stdin prompting interactive' );
    like( $top_level_prompt->{stdout}, qr/\Afoo:answer=bar\r?\n\z/, 'dashboard top-level CLI command prints its prompt and receives stdin through dashboard dispatch' );

    my $skill_prompt = _run_interactive_command(
        command => [ $perl, '-I', $lib, $dashboard, 'demo-skill.foo' ],
        input   => "bar\n",
    );
    is( $skill_prompt->{exit_code}, 0, 'dashboard dotted skill command keeps stdin prompting interactive' );
    like( $skill_prompt->{stdout}, qr/skill-hook/, 'dashboard dotted skill command still runs hooks before interactive skill execution' );
    like( $skill_prompt->{stdout}, qr/foo:answer=bar\r?\n/, 'dashboard dotted skill command prints its prompt and receives stdin through dashboard dispatch' );
}

my $open_root = File::Spec->catdir( $ENV{HOME}, 'open-file-fixtures' );
make_path($open_root);
my $open_target = File::Spec->catfile( $open_root, 'alpha-notes.txt' );
open my $open_fh, '>', $open_target or die "Unable to write $open_target: $!";
print {$open_fh} "alpha\n";
close $open_fh;

my $open_print = _run("$perl -I'$lib' '$dashboard' open-file --print '$open_root' alpha");
like($open_print, qr/\Q$open_target\E/, 'd2 open-file prints matching files');

my $second_open_target = File::Spec->catfile( $open_root, 'alpha-second.txt' );
open my $second_open_fh, '>', $second_open_target or die "Unable to write $second_open_target: $!";
print {$second_open_fh} "alpha second\n";
close $second_open_fh;

my $fake_editor_bin = File::Spec->catdir( $ENV{HOME}, 'fake-editor-bin' );
make_path($fake_editor_bin);
my $fake_editor_log = File::Spec->catfile( $ENV{HOME}, 'fake-editor.log' );
my $fake_editor = File::Spec->catfile( $fake_editor_bin, 'fake-editor' );
open my $fake_editor_fh, '>', $fake_editor or die "Unable to write $fake_editor: $!";
print {$fake_editor_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" > '$fake_editor_log'
SH
close $fake_editor_fh;
chmod 0755, $fake_editor or die "Unable to chmod $fake_editor: $!";

my $grep_content_target = File::Spec->catfile( $open_root, 'content-match.txt' );
open my $grep_content_fh, '>', $grep_content_target or die "Unable to write $grep_content_target: $!";
print {$grep_content_fh} "needle is in the file body\n";
close $grep_content_fh;
my $of_grep_print = _run("$perl -I'$lib' '$dashboard' of --print grep -nr needle '$open_root'");
is( $of_grep_print, "$grep_content_target\n", 'd2 of grep -nr searches file contents and prints the matching file' );
my $of_grep_open = _run("EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of grep -nr needle '$open_root'");
open my $grep_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after grep open: $!";
my $grep_editor_args = do { local $/; <$grep_editor_log_fh> };
close $grep_editor_log_fh;
is( $grep_editor_args, "$grep_content_target\n", 'd2 of grep opens the unique content match in the configured editor' );

my $open_select = _run(qq{printf '2\\n' | EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of '$open_root' alpha});
like($open_select, qr/^\d+: \Q$open_target\E$/m, 'd2 of lists the first matching open-file path');
like($open_select, qr/^\d+: \Q$second_open_target\E$/m, 'd2 of lists the second matching open-file path');
like($open_select, qr/> /, 'd2 of prompts with the legacy numbered chooser marker');
open my $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log: $!";
my $fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
my ($selected_open_path) = $open_select =~ /^2:\s+(.*)$/m;
is($fake_editor_args, "$selected_open_path\n", 'd2 of opens the selected match through the configured editor');

my $open_select_all = _run(qq{printf '1,2\\n' | EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of '$open_root' alpha});
like($open_select_all, qr/> /, 'd2 of keeps the chooser prompt for comma-separated multi selection');
open $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after multi select: $!";
$fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
my @multi_selected_open = split / /, $fake_editor_args;
chomp $multi_selected_open[-1];
is_deeply([ sort @multi_selected_open ], [ sort ( $open_target, $second_open_target ) ], 'd2 of opens both selected files for comma-separated multi selection');

my $fake_vim = File::Spec->catfile( $fake_editor_bin, 'vim' );
open my $fake_vim_fh, '>', $fake_vim or die "Unable to write $fake_vim: $!";
print {$fake_vim_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" > '$fake_editor_log'
SH
close $fake_vim_fh;
chmod 0755, $fake_vim or die "Unable to chmod $fake_vim: $!";
if ( $^O eq 'MSWin32' ) {
    # Same Windows twin as the docker fake: the sh fake above is
    # invisible to Windows program search, and the product's block-form
    # system() performs no PATH search or extension probing, so 'vim'
    # was never found even with a correct ';' PATH (build #81, tests
    # 694/696, exit 2, log left at the previous test's content). The
    # micros in builds #82/#83 proved the extensionless fake never runs
    # and the twin alone does not fix the run either - the product also
    # needed to resolve the bare editor name to a runnable file first
    # (OpenFile::_exec_raw). The twin supplies the runnable file the
    # resolver looks for: it skips the extensionless script and returns
    # this .bat. Mirrors the sh fake: echo the invocation to the log.
    my $fake_vim_bat = File::Spec->catfile( $fake_editor_bin, 'vim.bat' );
    open my $fake_vim_bat_fh, '>', $fake_vim_bat or die "Unable to write $fake_vim_bat: $!";
    print {$fake_vim_bat_fh} <<"BAT";
\@echo off
echo %*>"$fake_editor_log"
BAT
    close $fake_vim_bat_fh;
}
my $blank_open_all = _run(qq{printf '\\n' | PATH='$fake_editor_bin':"\$PATH" $perl -I'$lib' '$dashboard' of '$open_root' alpha});
like($blank_open_all, qr/> /, 'd2 of blank-enter chooser still renders the prompt before opening all matches');
open $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after blank open-all: $!";
$fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
like($fake_editor_args, qr/^-p /, 'd2 of blank-enter chooser opens all matches through vim tab mode');

my $jq_scope_root = File::Spec->catdir( $ENV{HOME}, 'jq-scope-fixtures' );
my $jq_scope_cli_root = File::Spec->catdir( $jq_scope_root, 'cli' );
my $jq_scope_js_root  = File::Spec->catdir( $jq_scope_root, 'public', 'js' );
make_path( $jq_scope_cli_root, $jq_scope_js_root );
my $jq_scope_helper = File::Spec->catfile( $jq_scope_cli_root, 'jq' );
open my $jq_scope_helper_fh, '>', $jq_scope_helper or die "Unable to write $jq_scope_helper: $!";
print {$jq_scope_helper_fh} "#!/bin/sh\n";
close $jq_scope_helper_fh;
chmod 0755, $jq_scope_helper or die "Unable to chmod $jq_scope_helper: $!";
my $jq_scope_script = File::Spec->catfile( $jq_scope_js_root, 'jq.js' );
open my $jq_scope_script_fh, '>', $jq_scope_script or die "Unable to write $jq_scope_script: $!";
print {$jq_scope_script_fh} "window.jq = true;\n";
close $jq_scope_script_fh;
my $jq_scope_ok_js = File::Spec->catfile( $jq_scope_js_root, 'ok.js' );
open my $jq_scope_ok_js_fh, '>', $jq_scope_ok_js or die "Unable to write $jq_scope_ok_js: $!";
print {$jq_scope_ok_js_fh} "window.ok = true;\n";
close $jq_scope_ok_js_fh;
my $jq_scope_ok_json = File::Spec->catfile( $jq_scope_js_root, 'ok.json' );
open my $jq_scope_ok_json_fh, '>', $jq_scope_ok_json or die "Unable to write $jq_scope_ok_json: $!";
print {$jq_scope_ok_json_fh} "{\"ok\":true}\n";
close $jq_scope_ok_json_fh;
my $jq_scope_exact = File::Spec->catfile( $jq_scope_root, '456.txt' );
open my $jq_scope_exact_fh, '>', $jq_scope_exact or die "Unable to write $jq_scope_exact: $!";
print {$jq_scope_exact_fh} "exact\n";
close $jq_scope_exact_fh;
my $jq_scope_jquery = File::Spec->catfile( $jq_scope_js_root, 'jquery.js' );
open my $jq_scope_jquery_fh, '>', $jq_scope_jquery or die "Unable to write $jq_scope_jquery: $!";
print {$jq_scope_jquery_fh} "window.jquery = true;\n";
close $jq_scope_jquery_fh;
my $jq_scope_select = _run(qq{cd '$jq_scope_root' && printf '1,2\\n' | EDITOR='$fake_editor' $perl -I'$lib' '$dashboard' of . jq});
like($jq_scope_select, qr/^1: \Q.\/cli\/jq\E$/m, 'd2 of . jq lists the exact jq helper first');
like($jq_scope_select, qr/^2: \Q.\/public\/js\/jq.js\E$/m, 'd2 of . jq lists jq.js before jquery.js');
like($jq_scope_select, qr/^3: \Q.\/public\/js\/jquery.js\E$/m, 'd2 of . jq still includes jquery.js in the chooser');
open $fake_editor_log_fh, '<', $fake_editor_log or die "Unable to read $fake_editor_log after jq scope selection: $!";
$fake_editor_args = do { local $/; <$fake_editor_log_fh> };
close $fake_editor_log_fh;
is($fake_editor_args, "./cli/jq ./public/js/jq.js\n", 'd2 of . jq opens the selected jq helper and jq.js before jquery.js');
my $ok_regex_scope = _run("cd '$jq_scope_root' && $perl -I'$repo/lib' '$repo/bin/d2' of --print . 'Ok\\.js\$'");
is( $ok_regex_scope, "./public/js/ok.js\n", 'd2 of . treats scope keywords as regexes, so Ok\\.js$ matches ok.js but not ok.json' );
my $scoped_exact_file = _run("cd '$jq_scope_root' && $perl -I'$lib' '$dashboard' path add jq-scope . >/dev/null && $perl -I'$repo/lib' '$repo/bin/d2' of --print jq-scope 456.txt");
is(
    $scoped_exact_file,
    $jq_scope_exact . "\n",
    'd2 of path aliases resolves exact relative file targets inside the aliased folder',
);

my $of_print = _run("$perl -I'$lib' '$dashboard' of --print '$open_root' alpha");
like($of_print, qr/\Q$open_target\E/, 'd2 of is shorthand for open-file');

my $runtime_open_print = _run("$perl -I'$lib' '$runtime_open_file' --print '$open_root' alpha");
like($runtime_open_print, qr/\Q$open_target\E/, 'private runtime open-file helper prints matching files');

my $runtime_of_print = _run("$perl -I'$lib' '$runtime_of' --print '$open_root' alpha");
like($runtime_of_print, qr/\Q$open_target\E/, 'private runtime of helper prints matching files');

ok( !-f File::Spec->catfile( $repo, 'bin', 'of' ), 'standalone of executable is no longer shipped from the repo tree' );
ok( !-f File::Spec->catfile( $repo, 'bin', 'open-file' ), 'standalone open-file executable is no longer shipped from the repo tree' );

my $perl_root = File::Spec->catdir( $open_root, 'lib', 'My' );
make_path($perl_root);
my $perl_target = File::Spec->catfile( $perl_root, 'App.pm' );
open my $perl_fh, '>', $perl_target or die "Unable to write $perl_target: $!";
print {$perl_fh} "package My::App;\n1;\n";
close $perl_fh;
local $ENV{PERL5LIB} = join Developer::Dashboard::PerlEnv::path_separator(), grep { defined && $_ ne '' } File::Spec->catdir( $open_root, 'lib' ), $ENV{PERL5LIB};
my $perl_module = _run("$perl -I'$lib' '$dashboard' open-file --print My::App");
like($perl_module, qr/\Q$perl_target\E/, 'd2 open-file resolves Perl module names');

my $runtime_perl_module = _run("$perl -I'$lib' '$runtime_open_file' --print My::App");
like($runtime_perl_module, qr/\Q$perl_target\E/, 'private runtime open-file helper resolves Perl module names');

my $java_root = File::Spec->catdir( $open_root, 'src', 'com', 'example' );
make_path($java_root);
my $java_target = File::Spec->catfile( $java_root, 'App.java' );
open my $java_fh, '>', $java_target or die "Unable to write $java_target: $!";
print {$java_fh} "package com.example;\nclass App {}\n";
close $java_fh;
my $java_class = _run("cd '$open_root' && $perl -I'$repo/lib' '$repo/bin/d2' open-file --print com.example.App");
like($java_class, qr/\Q$java_target\E/, 'd2 open-file resolves Java class names');

my $runtime_java_class = _run("cd '$open_root' && $perl -I'$repo/lib' '$runtime_open_file' --print com.example.App");
like($runtime_java_class, qr/\Q$java_target\E/, 'private runtime open-file helper resolves Java class names');
my $m2_sources_dir = File::Spec->catdir( $ENV{HOME}, '.m2', 'repository', 'com', 'example', 'archive-demo', '1.0.0' );
make_path($m2_sources_dir);
my $m2_sources_jar = File::Spec->catfile( $m2_sources_dir, 'archive-demo-1.0.0-sources.jar' );
_write_zip_entries(
    $m2_sources_jar,
    {
        'com/example/Archived.java' => "package com.example;\npublic class Archived {}\n",
    },
);
my $java_archive_source = _run("cd '$open_root' && $perl -I'$repo/lib' '$repo/bin/d2' open-file --print com.example.Archived");
my ($java_archive_path) = $java_archive_source =~ /([^\n]+)\n?\z/;
ok( defined $java_archive_path && -f $java_archive_path, 'd2 open-file resolves Java classes from local source jars when the project tree has no matching .java file' );
open my $java_archive_fh, '<', $java_archive_path or die "Unable to read $java_archive_path: $!";
my $java_archive_text = do { local $/; <$java_archive_fh> };
close $java_archive_fh;
like( $java_archive_text, qr/public class Archived/, 'd2 open-file preserves the extracted Java source content from source jars' );

my $fake_ticket_bin = File::Spec->catdir( $ENV{HOME}, 'fake-ticket-bin' );
make_path($fake_ticket_bin);
my $fake_ticket_log = File::Spec->catfile( $ENV{HOME}, 'fake-ticket-tmux.log' );
my $fake_ticket_tmux = File::Spec->catfile( $fake_ticket_bin, 'tmux' );
open my $fake_ticket_tmux_fh, '>', $fake_ticket_tmux or die "Unable to write $fake_ticket_tmux: $!";
print {$fake_ticket_tmux_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$*" >> '$fake_ticket_log'
if [ "\$1" = "has-session" ]; then
  if [ "\$3" = "DD-NEW" ]; then
    exit 1
  fi
  exit 0
fi
if [ "\$1" = "show-options" ] && [ "\$3" = "status-format[0]" ]; then
  printf '%s\n' '#[default]DEFAULT-ROW'
  exit 0
fi
exit 0
SH
close $fake_ticket_tmux_fh;
chmod 0755, $fake_ticket_tmux or die "Unable to chmod $fake_ticket_tmux: $!";
if ( $^O eq 'MSWin32' ) {
    # Same Windows twin as the docker/vim fakes: the sh fake above is
    # invisible to Windows program search, so 'tmux' was never found
    # and d2 workspace died with 'Unable to create tmux ticket session'
    # (build #86, tests 725/726). The micro in build #87 proved the
    # twin alone fixes the session-creation calls (tmux_command is
    # list-form system, which finds .bat files), but two details
    # matter. First, the log line must use the redirect-first form:
    # 'echo %*>>log' drops a trailing digit, because cmd parses '2>>'
    # as a stderr redirect - the 'set-option -gq status 2' line was
    # lost that way on win-ts, while '>>log echo %*' keeps it. Second,
    # the attach step is a bare exec, which on Windows returns before
    # the batch completes, so the attach-session line raced the log
    # read; Ticket::_exec_tmux now runs it synchronously with system.
    # Mirrors the sh fake: log the invocation, exit 1 when the session
    # is missing, answer the status-format snapshot, else exit 0.
    my $fake_ticket_tmux_bat = File::Spec->catfile( $fake_ticket_bin, 'tmux.bat' );
    open my $fake_ticket_tmux_bat_fh, '>', $fake_ticket_tmux_bat or die "Unable to write $fake_ticket_tmux_bat: $!";
    print {$fake_ticket_tmux_bat_fh} <<"BAT";
\@echo off
>>"$fake_ticket_log" echo %*
if "%~1"=="has-session" if "%~3"=="DD-NEW" exit /b 1
if "%~1"=="show-options" if "%~3"=="status-format[0]" echo #[default]DEFAULT-ROW
exit /b 0
BAT
    close $fake_ticket_tmux_bat_fh;
}
my $ticket_output = _run("PATH='$fake_ticket_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' workspace DD-NEW");
is( $ticket_output, '', 'd2 workspace stays quiet on success while tmux handles the terminal attach' );
open my $fake_ticket_log_fh, '<', $fake_ticket_log or die "Unable to read $fake_ticket_log: $!";
my $fake_ticket_log_text = do { local $/; <$fake_ticket_log_fh> };
close $fake_ticket_log_fh;
like( $fake_ticket_log_text, qr/^has-session -t DD-NEW$/m, 'd2 workspace checks whether the requested tmux session already exists' );
like( $fake_ticket_log_text, qr/^new-session -d .* -s DD-NEW -n Code1$/m, 'd2 workspace creates a new tmux session when the workspace session is missing' );
like( $fake_ticket_log_text, qr/^show-options -gqv \@dd_ticket_status_default$/m, 'd2 workspace checks whether tmux already recorded the default bottom-row status' );
like( $fake_ticket_log_text, qr/^show-options -gqv status-format\[0\]$/m, 'd2 workspace snapshots the current global tmux bottom-row status before replacing it with the indicator row' );
like( $fake_ticket_log_text, qr/^set-option -gq status-position bottom$/m, 'd2 workspace keeps the tmux status block anchored at the bottom' );
like( $fake_ticket_log_text, qr/^set-option -gq status 2$/m, 'd2 workspace enables a two-line tmux status block for dashboard-managed workspace sessions' );
like( $fake_ticket_log_text, qr/^set-option -gq status-interval 15$/m, 'd2 workspace refreshes the tmux status block automatically for dashboard-managed workspace sessions without hot-looping' );
like( $fake_ticket_log_text, qr/^set-option -gq status-format\[0\] "?#\('.*d2' ps1 --mode tmux-status-top --width #\{client_width\}\)"?$/m, 'd2 workspace configures the first tmux status row to render dashboard indicators through the explicit d2 entrypoint path' );
like( $fake_ticket_log_text, qr/^set-option -gq status-format\[1\] /m, 'd2 workspace restores the normal tmux bottom-row status beneath the indicator strip' );
like( $fake_ticket_log_text, qr/^set-option -guq status-format\[2\]$/m, 'd2 workspace clears any stale third tmux status row after configuring the workspace status block' );
like( $fake_ticket_log_text, qr/^attach-session -t DD-NEW$/m, 'd2 workspace attaches to the requested tmux session' );
like( $fake_ticket_log_text, qr/WORKSPACE_REF=DD-NEW/, 'd2 workspace seeds WORKSPACE_REF into new tmux sessions' );
like( $fake_ticket_log_text, qr/TICKET_REF=DD-NEW/, 'd2 workspace keeps TICKET_REF seeded for compatibility with older tmux sessions' );
like( $fake_ticket_log_text, qr/DEVELOPER_DASHBOARD_TMUX_STATUS=1/, 'd2 workspace seeds the tmux-status session flag into new tmux sessions so only dashboard-managed workspace sessions move indicators into the tmux status line' );

unlink $fake_ticket_log or die "Unable to unlink $fake_ticket_log: $!";
my $runtime_ticket_output = _run("PATH='$fake_ticket_bin':\"\$PATH\" $perl -I'$lib' '$runtime_workspace' DD-EXISTING");
is( $runtime_ticket_output, '', 'private runtime workspace helper stays quiet on success' );
open my $runtime_ticket_log_fh, '<', $fake_ticket_log or die "Unable to read $fake_ticket_log: $!";
my $runtime_ticket_log_text = do { local $/; <$runtime_ticket_log_fh> };
close $runtime_ticket_log_fh;
like( $runtime_ticket_log_text, qr/^has-session -t DD-EXISTING$/m, 'private runtime workspace helper checks the requested session' );
unlike( $runtime_ticket_log_text, qr/^new-session /m, 'private runtime workspace helper skips session creation when tmux reports it already exists' );
like( $runtime_ticket_log_text, qr/^set-option -gq status-format\[0\] "?#\('.*d2' ps1 --mode tmux-status-top --width #\{client_width\}\)"?$/m, 'private runtime workspace helper also reapplies the indicator tmux status row for existing workspace sessions' );
like( $runtime_ticket_log_text, qr/^attach-session -t DD-EXISTING$/m, 'private runtime workspace helper attaches to existing sessions' );

my $json_value = _run(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta});
is( $json_value, "2\n", 'jq extracts scalar JSON values' );
my $json_file = File::Spec->catfile( $open_root, 'sample.json' );
open my $json_fh, '>', $json_file or die "Unable to write $json_file: $!";
print {$json_fh} qq|{"alpha":{"beta":2}}|;
close $json_fh;
my $json_root = _run("$perl -I'$lib' '$dashboard' jq '\$d' '$json_file'");
is_deeply( json_decode($json_root), { alpha => { beta => 2 } }, 'jq accepts file then root query with order-independent args' );
my $json_root_stdin = _run("cat '$json_file' | $perl -I'$lib' '$dashboard' jq '\$d'");
is( $json_root_stdin, $json_root, 'jq returns the same whole-document result from stdin and file input' );
my $json_keys = _run(qq{printf '{"foo":[1,2,3,4],"bar":[4,5,6]}' | $perl -I'$lib' '$dashboard' jq 'sort keys %\$d'});
is_deeply( json_decode($json_keys), [ 'bar', 'foo' ], 'jq evaluates Perl expressions against decoded stdin data through $d' );
my $json_keys_file = _run("$perl -I'$lib' '$dashboard' jq '$json_file' 'sort' 'keys' '%\$d'");
is_deeply( json_decode($json_keys_file), ['alpha'], 'jq rejoins split expression argv pieces when the file path comes first' );
my $json_direct = _run(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$runtime_jq' alpha.beta});
is( $json_direct, $json_value, 'private runtime jq matches d2 jq output' );

my $yaml_value = _run(qq{printf 'alpha:\\n  beta: 3\\n' | $perl -I'$lib' '$dashboard' yq alpha.beta});
is( $yaml_value, "3\n", 'yq extracts scalar YAML values' );
my $yaml_file = File::Spec->catfile( $open_root, 'sample.yaml' );
open my $yaml_fh, '>', $yaml_file or die "Unable to write $yaml_file: $!";
print {$yaml_fh} "alpha:\n  beta: 3\n";
close $yaml_fh;
my $yaml_root = _run("$perl -I'$lib' '$dashboard' yq '$yaml_file' '\$d'");
is_deeply( json_decode($yaml_root), { alpha => { beta => '3' } }, 'yq accepts file then root query with order-independent args' );
my $yaml_root_stdin = _run("cat '$yaml_file' | $perl -I'$lib' '$dashboard' yq '\$d'");
is( $yaml_root_stdin, $yaml_root, 'yq returns the same whole-document result from stdin and file input' );
my $yaml_keys = _run(qq{printf 'foo:\\n  - 1\\nbar:\\n  - 2\\n' | $perl -I'$lib' '$dashboard' yq 'sort keys %\$d'});
is_deeply( json_decode($yaml_keys), [ 'bar', 'foo' ], 'yq evaluates Perl expressions against decoded YAML data through $d' );
my $yaml_direct = _run(qq{printf 'alpha:\\n  beta: 3\\n' | $perl -I'$lib' '$runtime_yq' alpha.beta});
is( $yaml_direct, $yaml_value, 'private runtime yq matches d2 yq output' );

my $jq_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'jq.d' );
make_path($jq_hook_root);
my $jq_hook_one = File::Spec->catfile( $jq_hook_root, '00-first.pl' );
open my $jq_hook_one_fh, '>', $jq_hook_one or die "Unable to write $jq_hook_one: $!";
print {$jq_hook_one_fh} <<'PL';
#!/usr/bin/env perl
print "hook-one\n";
warn "hook-one-err\n";
PL
close $jq_hook_one_fh;
chmod 0755, $jq_hook_one or die "Unable to chmod $jq_hook_one: $!";
my $jq_hook_two = File::Spec->catfile( $jq_hook_root, '01-second.pl' );
my $jq_hook_result = File::Spec->catfile( $ENV{HOME}, 'jq-hook-result.txt' );
open my $jq_hook_two_fh, '>', $jq_hook_two or die "Unable to write $jq_hook_two: $!";
print {$jq_hook_two_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
use lib '$repo/lib';
use Developer::Dashboard::Runtime::Result;
open my \$fh, '>', '$jq_hook_result' or die \$!;
print {\$fh} Developer::Dashboard::Runtime::Result::stdout('00-first.pl');
close \$fh;
print "hook-two\n";
warn "hook-two-err\n";
PL
close $jq_hook_two_fh;
chmod 0755, $jq_hook_two or die "Unable to chmod $jq_hook_two: $!";
my $jq_hook_skipped = File::Spec->catfile( $jq_hook_root, 'data.file' );
open my $jq_hook_skipped_fh, '>', $jq_hook_skipped or die "Unable to write $jq_hook_skipped: $!";
print {$jq_hook_skipped_fh} "skip\n";
close $jq_hook_skipped_fh;
chmod 0600, $jq_hook_skipped or die "Unable to chmod $jq_hook_skipped: $!";
my ( $jq_hooked_stdout, $jq_hooked_stderr, $jq_hooked_exit ) = _sh_capture(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta});
is( $jq_hooked_exit, 0, 'd2 jq succeeds when command hook files exist' );
like( $jq_hooked_stdout, qr/^hook-one\r?\n/s, 'd2 jq streams hook stdout before the main command output' );
like( $jq_hooked_stdout, qr/hook-two\r?\n2\r?\n\z/s, 'd2 jq keeps the main command output after streamed hook stdout' );
like( $jq_hooked_stderr, qr/hook-one-err\r?\n/, 'd2 jq streams hook stderr live' );
like( $jq_hooked_stderr, qr/hook-two-err\r?\n/, 'd2 jq keeps later hook stderr visible' );
my $jq_which = _run("$perl -I'$lib' '$dashboard' which jq");
like( $jq_which, qr/^COMMAND \Q$runtime_jq\E$/m, 'd2 which jq reports the staged built-in helper path' );
like( $jq_which, qr/^HOOK \Q$jq_hook_one\E$/m, 'd2 which jq lists the first participating hook file' );
like( $jq_which, qr/^HOOK \Q$jq_hook_two\E$/m, 'd2 which jq lists the later participating hook file' );
my $which_editor_log = File::Spec->catfile( $ENV{HOME}, 'which-editor.log' );
my $which_editor = File::Spec->catfile( $ENV{HOME}, 'fake-editor' );
open my $which_editor_fh, '>', $which_editor or die "Unable to write $which_editor: $!";
print {$which_editor_fh} <<"SH";
#!/bin/sh
printf '%s\\n' "\$@" > '$which_editor_log'
SH
close $which_editor_fh;
chmod 0755, $which_editor or die "Unable to chmod $which_editor: $!";
if ( $^O eq 'MSWin32' ) {
    # Same Windows twin as the vim fake above (build #81): the sh fake
    # is invisible to Windows program search, and the shebang route
    # through Git sh silently never writes the log (build #99, test
    # 781, exit 2 at the log read). Point EDITOR at the .bat twin
    # instead; the product runs .bat files by full path
    # (OpenFile::_exec_raw) and the twin echoes the invocation to the
    # same log. Mirrors the sh fake: echo the invocation to the log.
    my $which_editor_bat = File::Spec->catfile( $ENV{HOME}, 'fake-editor.bat' );
    open my $which_editor_bat_fh, '>', $which_editor_bat or die "Unable to write $which_editor_bat: $!";
    print {$which_editor_bat_fh} <<"BAT";
\@echo off
echo %*>"$which_editor_log"
BAT
    close $which_editor_bat_fh;
    $which_editor = $which_editor_bat;
}
my ( $jq_which_edit_stdout, $jq_which_edit_stderr, $jq_which_edit_exit ) = capture {
    local $ENV{EDITOR} = $which_editor;
    system $perl, '-I' . $lib, $dashboard, 'which', '--edit', 'jq';
    return $? >> 8;
};
is( $jq_which_edit_exit, 0, 'd2 which --edit jq exits cleanly' );
is( $jq_which_edit_stdout, '', 'd2 which --edit jq does not print inspection output before opening the file' );
is( $jq_which_edit_stderr, '', 'd2 which --edit jq keeps stderr clean' );
open my $which_editor_log_fh, '<', $which_editor_log or die "Unable to read $which_editor_log: $!";
my $which_editor_args = do { local $/; <$which_editor_log_fh> };
close $which_editor_log_fh;
is_same_path_output( $which_editor_args, "$runtime_jq\n", 'd2 which --edit jq opens the resolved helper path through d2 open-file' );
open my $jq_hook_result_fh, '<', $jq_hook_result or die "Unable to read $jq_hook_result: $!";
is( do { local $/; <$jq_hook_result_fh> }, "hook-one\n", 'later built-in command hooks can read the accumulated RESULT JSON from earlier hook output' );
close $jq_hook_result_fh;

SKIP: {
    skip 'Go hook smoke requires a Go version with `go run -C` support', 4
      if !_go_supports_run_from_directory();
    my $jq_go_hook = File::Spec->catfile( $jq_hook_root, '02-go.go' );
    open my $jq_go_hook_fh, '>', $jq_go_hook or die "Unable to write $jq_go_hook: $!";
    print {$jq_go_hook_fh} <<'GO';
package main

import (
    "fmt"
    "os"
)

func main() {
    fmt.Println("hook-go")
    fmt.Fprintln(os.Stderr, "hook-go-err")
}
GO
    close $jq_go_hook_fh;
    chmod 0755, $jq_go_hook or die "Unable to chmod $jq_go_hook: $!";

    my ( $jq_go_stdout, $jq_go_stderr, $jq_go_exit ) = _sh_capture(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta});
    is( $jq_go_exit, 0, 'd2 jq succeeds when an executable Go hook file exists' );
    like( $jq_go_stdout, qr/hook-go\n2\n\z/s, 'd2 jq runs the Go hook before the main command output' );
    like( $jq_go_stderr, qr/hook-go-err\n/, 'd2 jq keeps Go hook stderr visible' );
    like( $jq_go_stdout, qr/^hook-one\r?\nhook-two\r?\nhook-go\r?\n/s, 'd2 jq keeps Go hook ordering with earlier hook files' );
}

SKIP: {
    skip "Java hook smoke skipped: $JAVA_TOOLCHAIN_SKIP_REASON", 4
      if defined $JAVA_TOOLCHAIN_SKIP_REASON;
    my $jq_java_hook = File::Spec->catfile( $jq_hook_root, '03-java.java' );
    open my $jq_java_hook_fh, '>', $jq_java_hook or die "Unable to write $jq_java_hook: $!";
    print {$jq_java_hook_fh} <<'JAVA';
class HookJava {
    public static void main(String[] args) {
        System.out.println("hook-java");
        System.err.println("hook-java-err");
    }
}
JAVA
    close $jq_java_hook_fh;
    chmod 0755, $jq_java_hook or die "Unable to chmod $jq_java_hook: $!";

    my ( $jq_java_stdout, $jq_java_stderr, $jq_java_exit ) = _sh_capture(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' jq alpha.beta});
    is( $jq_java_exit, 0, 'd2 jq succeeds when an executable Java hook file exists' );
    like( $jq_java_stdout, qr/hook-java\n2\n\z/s, 'd2 jq runs the Java hook before the main command output' );
    like( $jq_java_stderr, qr/hook-java-err\n/, 'd2 jq keeps Java hook stderr visible' );
    like( $jq_java_stdout, qr/^hook-one\r?\nhook-two\r?\n(?:hook-go\r?\n)?hook-java\r?\n/s, 'd2 jq keeps Java hook ordering with the earlier hook files' );
}

local $ENV{RESULT} = json_encode(
    {
        '00-first.pl' => {
            stdout    => "hook-one\n",
            stderr    => "hook-one-err\n",
            exit_code => 0,
        },
        '01-second.pl' => {
            stdout    => "hook-two\n",
            stderr    => "hook-two-err\n",
            exit_code => 0,
        },
    }
);
is_deeply( Developer::Dashboard::Runtime::Result::current(), json_decode( $ENV{RESULT} ), 'Runtime::Result decodes RESULT into a hash' );
is_deeply( [ Developer::Dashboard::Runtime::Result::names() ], [ '00-first.pl', '01-second.pl' ], 'Runtime::Result lists stored hook names in sorted order' );
ok( Developer::Dashboard::Runtime::Result::has('00-first.pl'), 'Runtime::Result detects known hook names' );
ok( !Developer::Dashboard::Runtime::Result::has('99-missing.pl'), 'Runtime::Result rejects missing hook names' );
is( Developer::Dashboard::Runtime::Result::stdout('00-first.pl'), "hook-one\n", 'Runtime::Result returns stored hook stdout' );
is( Developer::Dashboard::Runtime::Result::stderr('01-second.pl'), "hook-two-err\n", 'Runtime::Result returns stored hook stderr' );
is( Developer::Dashboard::Runtime::Result::exit_code('01-second.pl'), 0, 'Runtime::Result returns stored hook exit codes' );
is( Developer::Dashboard::Runtime::Result::last_name(), '01-second.pl', 'Runtime::Result returns the last sorted hook name' );
is_deeply( Developer::Dashboard::Runtime::Result::last_entry(), json_decode( $ENV{RESULT} )->{'01-second.pl'}, 'Runtime::Result returns the last sorted hook entry' );
{
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'update';
    local $0 = '/tmp/report-result/';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'report-result', 'Runtime::Result preserves a trailing-slash script name when basename still resolves it' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'update';
    local $0 = '/';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'd2', 'Runtime::Result falls back to d2 when only a root-like script path is available' );
}
like(
    decode( 'UTF-8', Developer::Dashboard::Runtime::Result->report() ),
    qr/^[-]+\n.*Run Report\n[-]+\n✅ 00-first\.pl\n✅ 01-second\.pl\n[-]+\n\z/s,
    'Runtime::Result renders a human-readable hook run report',
);
local $ENV{RESULT} = '{';
my $invalid_json_error = do {
    local $@;
    eval { Developer::Dashboard::Runtime::Result::current() };
    $@;
};
like( $invalid_json_error, qr/at character offset|malformed JSON string/i, 'Runtime::Result surfaces invalid RESULT json decoding errors' );
local $ENV{RESULT} = json_encode( [ 1, 2, 3 ] );
my $non_hash_error = do {
    local $@;
    eval { Developer::Dashboard::Runtime::Result::current() };
    $@;
};
like( $non_hash_error, qr/RESULT must decode to a hash/, 'Runtime::Result rejects non-hash RESULT payloads' );
delete $ENV{RESULT};

my $custom_dir_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'inspect-result' );
make_path($custom_dir_root);
my $custom_hook = File::Spec->catfile( $custom_dir_root, '00-pre.pl' );
open my $custom_hook_fh, '>', $custom_hook or die "Unable to write $custom_hook: $!";
print {$custom_hook_fh} <<'PL';
#!/usr/bin/env perl
print "custom-hook\n";
warn "custom-hook-err\n";
PL
close $custom_hook_fh;
chmod 0755, $custom_hook or die "Unable to chmod $custom_hook: $!";
my $custom_run = File::Spec->catfile( $custom_dir_root, 'run' );
open my $custom_run_fh, '>', $custom_run or die "Unable to write $custom_run: $!";
print {$custom_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $custom_run_fh;
chmod 0755, $custom_run or die "Unable to chmod $custom_run: $!";
my ( $custom_stdout, $custom_stderr, $custom_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' inspect-result");
is( $custom_exit, 0, 'directory-backed custom command succeeds after hook streaming' );
like( $custom_stdout, qr/^custom-hook\r?\n/s, 'directory-backed custom command streams hook stdout before the final RESULT json' );
like( $custom_stderr, qr/custom-hook-err\r?\n/, 'directory-backed custom command streams hook stderr live' );
my ($custom_json) = $custom_stdout =~ /(\{[\s\S]*\})\s*\z/;
ok( defined $custom_json, 'directory-backed custom command leaves trailing RESULT json after streamed hook output' );
my $custom_result_data = json_decode($custom_json);
is( $custom_result_data->{'00-pre.pl'}{stdout}, "custom-hook\n", 'directory-backed custom commands receive RESULT JSON from their hook files' );
like( $custom_result_data->{'00-pre.pl'}{stderr}, qr/custom-hook-err/, 'directory-backed custom command RESULT keeps captured hook stderr' );

my $report_dir_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'report-result' );
make_path($report_dir_root);
my $report_hook_ok = File::Spec->catfile( $report_dir_root, '00-first.pl' );
open my $report_hook_ok_fh, '>', $report_hook_ok or die "Unable to write $report_hook_ok: $!";
print {$report_hook_ok_fh} <<'PL';
#!/usr/bin/env perl
print "report-hook\n";
PL
close $report_hook_ok_fh;
chmod 0755, $report_hook_ok or die "Unable to chmod $report_hook_ok: $!";
my $report_hook_fail = File::Spec->catfile( $report_dir_root, '01-second.pl' );
open my $report_hook_fail_fh, '>', $report_hook_fail or die "Unable to write $report_hook_fail: $!";
print {$report_hook_fail_fh} <<'PL';
#!/usr/bin/env perl
warn "report-fail\n";
exit 2;
PL
close $report_hook_fail_fh;
chmod 0755, $report_hook_fail or die "Unable to chmod $report_hook_fail: $!";
my $report_run = File::Spec->catfile( $report_dir_root, 'run' );
open my $report_run_fh, '>', $report_run or die "Unable to write $report_run: $!";
print {$report_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result;
print Developer::Dashboard::Runtime::Result->report();
PL
close $report_run_fh;
chmod 0755, $report_run or die "Unable to chmod $report_run: $!";
my ( $report_stdout, $report_stderr, $report_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' report-result");
$report_stdout = decode( 'UTF-8', $report_stdout );
$report_stderr = decode( 'UTF-8', $report_stderr );
is( $report_exit, 0, 'directory-backed custom commands can print Runtime::Result reports after hook execution' );
like( $report_stdout, qr/^report-hook\r?\n/s, 'Runtime::Result report command still streams hook stdout before the final report' );
like( $report_stdout, qr/report-result Run Report/, 'Runtime::Result report titles the report with the current command name' );
like( $report_stdout, qr/✅ 00-first\.pl/, 'Runtime::Result report marks successful hooks with a success glyph' );
like( $report_stdout, qr/🚨 01-second\.pl/, 'Runtime::Result report marks failing hooks with an error glyph' );
like( $report_stderr, qr/report-fail/, 'Runtime::Result report does not suppress hook stderr' );

my $update_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'update.d' );
make_path($update_hook_root);
my $update_command = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'update' );
open my $update_command_fh, '>', $update_command or die "Unable to write $update_command: $!";
print {$update_command_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $update_command_fh;
chmod 0755, $update_command or die "Unable to chmod $update_command: $!";
my $update_hook = File::Spec->catfile( $update_hook_root, '01-cpan' );
open my $update_hook_fh, '>', $update_hook or die "Unable to write $update_hook: $!";
print {$update_hook_fh} <<'PL';
#!/usr/bin/env perl
print "Test";
warn "warned\n";
PL
close $update_hook_fh;
chmod 0755, $update_hook or die "Unable to chmod $update_hook: $!";
my $update_skip = File::Spec->catfile( $update_hook_root, 'data.file' );
open my $update_skip_fh, '>', $update_skip or die "Unable to write $update_skip: $!";
print {$update_skip_fh} "skip\n";
close $update_skip_fh;
chmod 0600, $update_skip or die "Unable to chmod $update_skip: $!";
my ( $update_stdout, $update_stderr, $update_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' update");
is( $update_exit, 0, 'd2 update custom command succeeds' );
like( $update_stdout, qr/^Test/s, 'd2 update custom command streams hook stdout before returning RESULT json' );
like( $update_stderr, qr/warned/, 'd2 update streams hook stderr live' );
my ($update_json) = $update_stdout =~ /(\{[\s\S]*\})\s*\z/;
ok( defined $update_json, 'd2 update custom command leaves trailing RESULT json after streamed hook output' );
my $update_result_data = json_decode($update_json);
is( $update_result_data->{'01-cpan'}{stdout}, 'Test', 'd2 update custom command receives stdout from executable update hook files' );
like( $update_result_data->{'01-cpan'}{stderr}, qr/warned/, 'd2 update custom command receives stderr from executable update hook files' );
ok( !exists $update_result_data->{'data.file'}, 'd2 update custom command skips non-executable files in the update hook folder' );

my $huge_command = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'huge-result' );
open my $huge_command_fh, '>', $huge_command or die "Unable to write $huge_command: $!";
print {$huge_command_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result ();
my $result = Developer::Dashboard::Runtime::Result::current();
my $entry = $result->{'01-big'} || {};
print "stdout=", length( $entry->{stdout} // '' ), "\n";
print "stderr=", length( $entry->{stderr} // '' ), "\n";
print "result_file=", ( ( $ENV{RESULT_FILE} || '' ) ne '' ? 1 : 0 ), "\n";
PL
close $huge_command_fh;
chmod 0755, $huge_command or die "Unable to chmod $huge_command: $!";

my $huge_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'huge-result.d' );
make_path($huge_hook_root);
my $huge_hook = File::Spec->catfile( $huge_hook_root, '01-big' );
open my $huge_hook_fh, '>', $huge_hook or die "Unable to write $huge_hook: $!";
print {$huge_hook_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print 'S' x 32;
print STDERR 'E' x 1800000;
PL
close $huge_hook_fh;
chmod 0755, $huge_hook or die "Unable to chmod $huge_hook: $!";
my $huge_probe = File::Spec->catfile( $huge_hook_root, '02-probe' );
open my $huge_probe_fh, '>', $huge_probe or die "Unable to write $huge_probe: $!";
print {$huge_probe_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result ();
my $entry = Developer::Dashboard::Runtime::Result::entry('01-big') || {};
print 'probe-stderr=', length( $entry->{stderr} // '' ), "\n";
PL
close $huge_probe_fh;
chmod 0755, $huge_probe or die "Unable to chmod $huge_probe: $!";

my ( $huge_stdout, $huge_stderr, $huge_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' huge-result");
is( $huge_exit, 0, 'dashboard custom commands still succeed when RESULT grows beyond the inline exec-safe environment size' );
like( $huge_stdout, qr/probe-stderr=1800000\r?\n/s, 'later hook files can still read oversized RESULT state through the fallback channel' );
like( $huge_stdout, qr/stdout=32\n/s, 'final command still receives the oversized hook stdout length through Runtime::Result' );
like( $huge_stdout, qr/stderr=1800000\n/s, 'final command still receives the oversized hook stderr length through Runtime::Result' );
like( $huge_stdout, qr/result_file=1\n/s, 'final command sees the explicit RESULT_FILE fallback when hook output would otherwise overflow exec' );
unlike( $huge_stderr, qr/Argument list too long/, 'oversized RESULT fallback avoids kernel exec failures from large hook payloads' );

my $stop_command = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'cli', 'hook-stop-check' );
open my $stop_command_fh, '>', $stop_command or die "Unable to write $stop_command: $!";
print {$stop_command_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print "__DD_RESULT_BEGIN__\n", ( $ENV{RESULT} // '' ), "\n__DD_RESULT_END__\n";
print "__DD_LAST_RESULT_BEGIN__\n", ( $ENV{LAST_RESULT} // '' ), "\n__DD_LAST_RESULT_END__\n";
PL
close $stop_command_fh;
chmod 0755, $stop_command or die "Unable to chmod $stop_command: $!";

my $stop_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'hook-stop-check.d' );
make_path($stop_hook_root);
my $stop_probe = File::Spec->catfile( $ENV{HOME}, 'hook-stop-last-result.json' );
my $stop_sentinel = File::Spec->catfile( $ENV{HOME}, 'hook-stop-third-ran.txt' );
my $stop_first = File::Spec->catfile( $stop_hook_root, '00-first.pl' );
open my $stop_first_fh, '>', $stop_first or die "Unable to write $stop_first: $!";
print {$stop_first_fh} <<'PL';
#!/usr/bin/env perl
print "ABC\n";
PL
close $stop_first_fh;
chmod 0755, $stop_first or die "Unable to chmod $stop_first: $!";
my $stop_second = File::Spec->catfile( $stop_hook_root, '01-stop.pl' );
open my $stop_second_fh, '>', $stop_second or die "Unable to write $stop_second: $!";
print {$stop_second_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
use lib '$repo/lib';
use JSON::XS qw(encode_json);
use Developer::Dashboard::Runtime::Result ();
my \$last = Developer::Dashboard::Runtime::Result->last_result() || {};
open my \$fh, '>', '$stop_probe' or die \$!;
print {\$fh} encode_json(\$last);
close \$fh;
print "stop-hook\n";
warn "[[STOP]] stop requested by 01-stop.pl\\n";
PL
close $stop_second_fh;
chmod 0755, $stop_second or die "Unable to chmod $stop_second: $!";
my $stop_third = File::Spec->catfile( $stop_hook_root, '02-never.pl' );
open my $stop_third_fh, '>', $stop_third or die "Unable to write $stop_third: $!";
print {$stop_third_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
open my \$fh, '>', '$stop_sentinel' or die \$!;
print {\$fh} "ran\\n";
close \$fh;
print "third-hook\\n";
PL
close $stop_third_fh;
chmod 0755, $stop_third or die "Unable to chmod $stop_third: $!";

my ( $stop_stdout, $stop_stderr, $stop_exit ) = _sh_capture("$perl -I'$lib' '$dashboard' hook-stop-check");
is( $stop_exit, 0, 'dashboard returns to the main command after a hook emits the explicit stop marker' );
like( $stop_stdout, qr/^ABC\r?\n/s, 'dashboard still streams stdout from hooks that ran before the stop marker' );
like( $stop_stdout, qr/stop-hook\r?\n/s, 'dashboard still streams stdout from the hook that requested stop' );
unlike( $stop_stdout, qr/third-hook\n/s, 'dashboard skips later hook scripts after a stop marker appears on stderr' );
like( $stop_stderr, qr/\[\[STOP\]\] stop requested by 01-stop\.pl/, 'dashboard keeps the explicit stop marker visible on stderr' );
ok( !-e $stop_sentinel, 'dashboard does not execute later hook files once the stop marker is seen' );
open my $stop_probe_fh, '<', $stop_probe or die "Unable to read $stop_probe: $!";
my $stop_previous = json_decode( do { local $/; <$stop_probe_fh> } );
close $stop_probe_fh;
like( $stop_previous->{file}, qr/\Qhook-stop-check.d\E.*\Q00-first.pl\E\z/, 'Runtime::Result last_result exposes the previous hook file path inside the next hook' );
is( $stop_previous->{exit}, 0, 'Runtime::Result last_result exposes the previous hook exit code inside the next hook' );
is( $stop_previous->{STDOUT}, "ABC\n", 'Runtime::Result last_result exposes the previous hook stdout inside the next hook' );
is( $stop_previous->{STDERR}, '', 'Runtime::Result last_result exposes the previous hook stderr inside the next hook' );
my ($stop_result_json) = $stop_stdout =~ /__DD_RESULT_BEGIN__\n([\s\S]*?)\n__DD_RESULT_END__/;
ok( defined $stop_result_json && $stop_result_json ne '', 'main command receives RESULT after hook-stop execution' );
my $stop_result_data = json_decode($stop_result_json);
ok( exists $stop_result_data->{'00-first.pl'}, 'main command RESULT keeps the first hook entry' );
ok( exists $stop_result_data->{'01-stop.pl'}, 'main command RESULT keeps the stopping hook entry' );
ok( !exists $stop_result_data->{'02-never.pl'}, 'main command RESULT skips hooks after the explicit stop marker' );
my ($stop_last_json) = $stop_stdout =~ /__DD_LAST_RESULT_BEGIN__\n([\s\S]*?)\n__DD_LAST_RESULT_END__/;
ok( defined $stop_last_json && $stop_last_json ne '', 'main command receives LAST_RESULT after hook-stop execution' );
my $stop_last_data = json_decode($stop_last_json);
like( $stop_last_data->{file}, qr/\Qhook-stop-check.d\E.*\Q01-stop.pl\E\z/, 'main command LAST_RESULT points at the stopping hook file' );
is( $stop_last_data->{exit}, 0, 'main command LAST_RESULT keeps the stopping hook exit code' );
is( $stop_last_data->{STDOUT}, "stop-hook\n", 'main command LAST_RESULT keeps the stopping hook stdout' );
like( $stop_last_data->{STDERR}, qr/\[\[STOP\]\] stop requested by 01-stop\.pl/, 'main command LAST_RESULT keeps the stopping hook stderr' );

is( _run("$perl -I'$lib' '$dashboard' version"), "$expected_version\n", 'd2 version prints the installed d2 version' );
open my $dashboard_entrypoint_fh, '<', $dashboard or die "Unable to read $dashboard: $!";
my $dashboard_entrypoint_source = do { local $/; <$dashboard_entrypoint_fh> };
close $dashboard_entrypoint_fh;
unlike( $dashboard_entrypoint_source, qr/^use Pod::Usage\b/m, 'lightweight d2 commands do not eagerly load POD usage rendering' );
like( $dashboard_entrypoint_source, qr/^\s*require Pod::Usage;/m, 'usage-error branches lazily require POD usage rendering when needed' );

my $toml_value = _run(qq{printf '[alpha]\\nbeta = 4\\n' | $perl -I'$lib' '$dashboard' tomq alpha.beta});
is( $toml_value, "4\n", 'tomq extracts scalar TOML values' );
my $toml_file = File::Spec->catfile( $open_root, 'sample.toml' );
open my $toml_fh, '>', $toml_file or die "Unable to write $toml_file: $!";
print {$toml_fh} "[alpha]\nbeta = 4\n";
close $toml_fh;
my $toml_root = _run("$perl -I'$lib' '$dashboard' tomq '\$d' '$toml_file'");
is_deeply( json_decode($toml_root), { alpha => { beta => 4 } }, 'tomq accepts file then root query with order-independent args' );
my $toml_root_stdin = _run("cat '$toml_file' | $perl -I'$lib' '$dashboard' tomq '\$d'");
is( $toml_root_stdin, $toml_root, 'tomq returns the same whole-document result from stdin and file input' );
my $toml_keys = _run(qq{printf '[foo]\\na = 1\\n[bar]\\nb = 2\\n' | $perl -I'$lib' '$dashboard' tomq 'sort keys %\$d'});
is_deeply( json_decode($toml_keys), [ 'bar', 'foo' ], 'tomq evaluates Perl expressions against decoded TOML data through $d' );
my $toml_bool = _run(qq{printf 'enabled = true\\ndisabled = false\\n' | $perl -I'$lib' '$dashboard' tomq '\$d'});
is_deeply( json_decode($toml_bool), { disabled => 0, enabled => 1 }, 'tomq returns plain Perl scalar booleans instead of TOML backend objects' );
my $toml_direct = _run(qq{printf '[alpha]\\nbeta = 4\\n' | $perl -I'$lib' '$runtime_tomq' alpha.beta});
is( $toml_direct, $toml_value, 'private runtime tomq matches d2 tomq output' );

my $props_value = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$dashboard' propq alpha.beta});
is( $props_value, "5\n", 'propq extracts scalar Java properties values' );
my $props_file = File::Spec->catfile( $open_root, 'sample.properties' );
open my $props_fh, '>', $props_file or die "Unable to write $props_file: $!";
print {$props_fh} "alpha.beta=5\nname = demo\n";
close $props_fh;
my $props_root = _run("$perl -I'$lib' '$dashboard' propq '$props_file' '\$d'");
is_deeply( json_decode($props_root), { 'alpha.beta' => '5', name => 'demo' }, 'propq accepts file then root query with order-independent args' );
my $props_root_stdin = _run("cat '$props_file' | $perl -I'$lib' '$dashboard' propq '\$d'");
is( $props_root_stdin, $props_root, 'propq returns the same whole-document result from stdin and file input' );
my $props_keys = _run(qq{printf 'foo=1\\nbar=2\\n' | $perl -I'$lib' '$dashboard' propq 'sort keys %\$d'});
is_deeply( json_decode($props_keys), [ 'bar', 'foo' ], 'propq evaluates Perl expressions against decoded properties data through $d' );
my $props_direct = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$runtime_propq' alpha.beta});
is( $props_direct, $props_value, 'private runtime propq matches d2 propq output' );

my $ini_value = _run(qq{printf '[alpha]\\nbeta=6\\n' | $perl -I'$lib' '$dashboard' iniq alpha.beta});
is( $ini_value, "6\n", 'iniq extracts scalar INI values' );
my $ini_keys = _run(qq{printf '[foo]\\na=1\\n[bar]\\nb=2\\n' | $perl -I'$lib' '$dashboard' iniq 'sort keys %\$d'});
is_deeply( json_decode($ini_keys), [ '_global', 'bar', 'foo' ], 'iniq evaluates Perl expressions against decoded INI data through $d' );
my $ini_direct = _run(qq{printf '[alpha]\\nbeta=6\\n' | $perl -I'$lib' '$runtime_iniq' alpha.beta});
is( $ini_direct, $ini_value, 'private runtime iniq matches d2 iniq output' );

my $csv_value = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$dashboard' csvq 1.1});
is( $csv_value, "8\n", 'csvq extracts scalar CSV values by row and column index' );
my $csv_expression = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$dashboard' csvq 'join q(-), map { \$d->[1][\$_] } 0 .. \$#{ \$d->[1] }'});
is( $csv_expression, "7-8\n", 'csvq evaluates Perl expressions against decoded CSV row arrays through $d' );
my $csv_direct = _run(qq{printf 'alpha,beta\\n7,8\\n' | $perl -I'$lib' '$runtime_csvq' 1.1});
is( $csv_direct, $csv_value, 'private runtime csvq matches d2 csvq output' );

my $xml_file = File::Spec->catfile( $open_root, 'sample.xml' );
open my $xml_fh, '>', $xml_file or die "Unable to write $xml_file: $!";
print {$xml_fh} '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>';
close $xml_fh;
my $xml_value = _run(qq{printf '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>' | $perl -I'$lib' '$dashboard' xmlq root.value});
is( $xml_value, "demo\n", 'xmlq extracts scalar XML values from the decoded XML tree' );
my $xml_root = _run("$perl -I'$lib' '$dashboard' xmlq '\$d' '$xml_file'");
is_deeply(
    json_decode($xml_root),
    {
        root => {
            value => 'demo',
            item  => [
                { _attributes => { id => '1' }, _text => 'x' },
                { _attributes => { id => '2' }, _text => 'y' },
            ],
        },
    },
    'xmlq returns the decoded XML tree for the whole-document selector',
);
my $xml_root_stdin = _run("cat '$xml_file' | $perl -I'$lib' '$dashboard' xmlq '\$d'");
is( $xml_root_stdin, $xml_root, 'xmlq returns the same decoded whole-document result from stdin and file input' );
my $xml_expression = _run(qq{printf '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>' | $perl -I'$lib' '$dashboard' xmlq 'join q(,), map { \$_->{_attributes}{id} } \@{ \$d->{root}{item} }'});
is( $xml_expression, "1,2\n", 'xmlq evaluates Perl expressions against decoded XML data through $d' );
my $xml_direct = _run(qq{printf '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>' | $perl -I'$lib' '$runtime_xmlq' root.value});
is( $xml_direct, $xml_value, 'private runtime xmlq matches d2 xmlq output' );

my $cli_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
make_path($cli_root);
my $ext = File::Spec->catfile( $cli_root, 'foobar' );
open my $ext_fh, '>', $ext or die "Unable to write $ext: $!";
print {$ext_fh} <<'SH';
#!/bin/sh
# cat is an external binary in Git usr/bin, which is not on the Windows
# job PATH, so slurp stdin with perl instead (byte-identical output:
# command substitution strips trailing newlines either way).
input="$(perl -e 'local $/; print <STDIN>')"
printf 'argv:%s|stdin:%s\n' "$*" "$input"
SH
close $ext_fh;
chmod 0755, $ext or die "Unable to chmod $ext: $!";

my ( $ext_stdout, $ext_stderr, $ext_exit ) = capture {
    open my $pipe, '|-', $perl, '-I' . $lib, $dashboard, 'foobar', 'one', 'two'
      or die "Unable to exec dashboard extension: $!";
    print {$pipe} "hello-extension";
    close $pipe or die "dashboard extension failed: $!";
    return $? >> 8;
};
is( $ext_exit, 0, 'user CLI extension exits successfully' );
is( $ext_stderr, '', 'user CLI extension keeps stderr clean' );
like( $ext_stdout, qr/^argv:one two\|stdin:hello-extension$/m, 'user CLI extension receives argv and stdin passthrough' );
SKIP: {
    skip 'direct Go source-command smoke test requires a Go version with `go run -C` support', 3
      if !_go_supports_run_from_directory();
    my $go_extension = File::Spec->catfile( $cli_root, 'hi.go' );
    open my $go_extension_fh, '>', $go_extension or die "Unable to write $go_extension: $!";
    print {$go_extension_fh} <<'GO';
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
GO
    close $go_extension_fh;
    chmod 0755, $go_extension or die "Unable to chmod $go_extension: $!";
    my ( $go_stdout, $go_stderr, $go_exit ) = capture {
        system $perl, '-I' . $lib, $dashboard, 'hi';
        return $? >> 8;
    };
    is( $go_exit, 0, 'dashboard resolves cli/<command>.go as a direct custom command' );
    is( $go_stderr, '', 'dashboard direct Go custom command keeps stderr clean' );
    is( $go_stdout, "Hello, World!\n", 'dashboard direct Go custom command runs through go run' );
}
SKIP: {
    skip "Direct Java source-command smoke skipped: $JAVA_TOOLCHAIN_SKIP_REASON", 3
      if defined $JAVA_TOOLCHAIN_SKIP_REASON;
    my $java_extension = File::Spec->catfile( $cli_root, 'foo.java' );
    open my $java_extension_fh, '>', $java_extension or die "Unable to write $java_extension: $!";
    print {$java_extension_fh} <<'JAVA';
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
JAVA
    close $java_extension_fh;
    chmod 0755, $java_extension or die "Unable to chmod $java_extension: $!";
    my ( $java_stdout, $java_stderr, $java_exit ) = capture {
        system $perl, '-I' . $lib, $dashboard, 'foo';
        return $? >> 8;
    };
    is( $java_exit, 0, 'dashboard resolves cli/<command>.java as a direct custom command' );
    is( $java_stderr, '', 'dashboard direct Java custom command keeps stderr clean' );
    is( $java_stdout, "Hello, World!\n", 'dashboard direct Java custom command compiles and runs through javac/java' );
}

my $nonrepo_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'nonrepo-local-cli-project' );
my $nonrepo_cli_root = File::Spec->catdir( $nonrepo_root, '.developer-dashboard', 'cli' );
make_path($nonrepo_cli_root);
open my $nonrepo_ext_fh, '>', File::Spec->catfile( $nonrepo_cli_root, 'foobar' )
  or die "Unable to write non-repo custom command: $!";
print {$nonrepo_ext_fh} <<'SH';
#!/bin/sh
printf 'nonrepo-command:%s\n' "$*"
SH
close $nonrepo_ext_fh;
chmod 0755, File::Spec->catfile( $nonrepo_cli_root, 'foobar' )
  or die "Unable to chmod non-repo custom command: $!";

my ( $nonrepo_command_stdout, undef, $nonrepo_command_exit ) = _sh_capture("cd '$nonrepo_root' && $perl -I'$repo/lib' '$repo/bin/d2' foobar one two");
is( $nonrepo_command_exit, 0, 'non-repo local custom command exits successfully' );
like( $nonrepo_command_stdout, qr/^nonrepo-command:one two$/m, 'non-repo local .developer-dashboard CLI command overrides the home CLI command' );

my $empty_nonrepo_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'nonrepo-home-fallback-project' );
make_path( File::Spec->catdir( $empty_nonrepo_root, '.developer-dashboard' ) );
my ( $empty_nonrepo_stdout, undef, $empty_nonrepo_exit ) = _sh_capture("cd '$empty_nonrepo_root' && printf '' | $perl -I'$repo/lib' '$repo/bin/d2' foobar one two");
is( $empty_nonrepo_exit, 0, 'home custom command still exits successfully from a non-repo directory' );
like( $empty_nonrepo_stdout, qr/^argv:one two\|stdin:$/m, 'home CLI command still resolves when a non-repo directory lacks a local CLI override' );

my $plain_repo = File::Spec->catdir( $ENV{HOME}, 'projects', 'plain-restart-project' );
make_path( File::Spec->catdir( $plain_repo, '.git' ) );
my $plain_restart_port = _find_free_port();

# A restart spawns the runtime server, which must not inherit the
# coverage switches: the server would run under Devel::Cover and write
# its cover database into the served directory. The switches are
# cleared only when coverage was requested, matching the original
# capture blocks.
my %restart_env;
if ( _coverage_requested() ) {
    %restart_env = ( PERL5OPT => undef, HARNESS_PERL_SWITCHES => undef );
}
my ( $plain_restart_stdout, $plain_restart_stderr, $plain_restart_exit ) = _sh_capture(
    "cd '$plain_repo' && $perl -I'$repo/lib' '$repo/bin/d2' restart --host 127.0.0.1 --port $plain_restart_port",
    { env => \%restart_env },
);
is( $plain_restart_exit, 0, 'd2 restart succeeds from a repo without a project-local dashboard root' );
unlike( $plain_restart_stderr, qr/\S/, 'd2 restart keeps stderr clean in a repo without a project-local dashboard root' );
like( $plain_restart_stdout, qr/Component\s+Target\s+Status/, 'd2 restart prints a table summary by default' );
like( $plain_restart_stdout, qr/\bweb\b/, 'd2 restart table summary includes the web row' );
ok( !-d File::Spec->catdir( $plain_repo, '.developer-dashboard' ), 'd2 restart does not create a project-local .developer-dashboard tree in repos that have not opted in' );
my ( $plain_stop_stdout, $plain_stop_stderr, $plain_stop_exit ) = capture {
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system $perl, '-I' . $lib, $dashboard, 'stop';
    return $? >> 8;
};
is( $plain_stop_exit, 0, 'd2 stop succeeds after the plain-repo restart check' );
unlike( $plain_stop_stderr, qr/\S/, 'd2 stop keeps stderr clean after the plain-repo restart check' );
like( $plain_stop_stdout, qr/Component\s+Target\s+Status/, 'd2 stop prints a table summary by default' );
like( $plain_stop_stdout, qr/\bweb\b/, 'd2 stop table summary includes the web row' );

my $json_restart_port = _find_free_port();
my ( $json_restart_stdout, $json_restart_stderr, $json_restart_exit ) = _sh_capture(
    "cd '$plain_repo' && $perl -I'$repo/lib' '$repo/bin/d2' restart -o json --host 127.0.0.1 --port $json_restart_port",
    { env => \%restart_env },
);
is( $json_restart_exit, 0, 'd2 restart -o json succeeds from a repo without a project-local dashboard root' );
unlike( $json_restart_stderr, qr/\S/, 'd2 restart -o json keeps stderr clean in a repo without a project-local dashboard root' );
like( $json_restart_stdout, qr/"web_pid"\s*:/, 'd2 restart -o json prints the legacy machine-readable payload' );
my ( $json_stop_stdout, $json_stop_stderr, $json_stop_exit ) = capture {
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system $perl, '-I' . $lib, $dashboard, 'stop', '-o', 'json';
    return $? >> 8;
};
is( $json_stop_exit, 0, 'd2 stop -o json succeeds after the json restart check' );
unlike( $json_stop_stderr, qr/\S/, 'd2 stop -o json keeps stderr clean after the json restart check' );
like( $json_stop_stdout, qr/"collectors"\s*:/, 'd2 stop -o json prints the legacy machine-readable payload' );

my $progress_restart_port = _find_free_port();
my ( $progress_restart_stdout, $progress_restart_stderr, $progress_restart_exit ) = _sh_capture(
    "cd '$plain_repo' && $perl -I'$repo/lib' '$repo/bin/d2' restart --host 127.0.0.1 --port $progress_restart_port",
    { env => { DEVELOPER_DASHBOARD_PROGRESS => 1, %restart_env } },
);
is( $progress_restart_exit, 0, 'd2 restart still succeeds when forced terminal progress output is enabled' );
like( $progress_restart_stderr, qr/d2 restart progress/, 'd2 restart progress output prints the task-board title when enabled' );
like( $progress_restart_stderr, qr/\[ \] Stop dashboard web service/, 'd2 restart progress output prints the full task list before work begins' );
like( $progress_restart_stderr, qr/-> Start dashboard web service|\[OK\] Start dashboard web service/, 'd2 restart progress output updates the web start task while work runs' );
my ( $progress_stop_stdout, $progress_stop_stderr, $progress_stop_exit ) = capture {
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    local $ENV{PERL5OPT} if _coverage_requested();
    local $ENV{HARNESS_PERL_SWITCHES} if _coverage_requested();
    system $perl, '-I' . $lib, $dashboard, 'stop';
    return $? >> 8;
};
is( $progress_stop_exit, 0, 'd2 stop still succeeds when forced terminal progress output is enabled' );
like( $progress_stop_stderr, qr/d2 stop progress/, 'd2 stop progress output prints the task-board title when enabled' );
like( $progress_stop_stderr, qr/\[OK\] Stop dashboard web service/, 'd2 stop progress output marks the web shutdown task complete' );

my $project_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'local-cli-project' );
make_path( File::Spec->catdir( $project_root, '.git' ) );
my $project_cli_root = File::Spec->catdir( $project_root, '.developer-dashboard', 'cli' );
make_path( File::Spec->catdir( $project_cli_root, 'foobar' ) );
open my $project_ext_fh, '>', File::Spec->catfile( $project_cli_root, 'foobar', 'run' )
  or die "Unable to write project run command: $!";
print {$project_ext_fh} <<'SH';
#!/bin/sh
printf 'project-command:%s\n' "$*"
SH
close $project_ext_fh;
chmod 0755, File::Spec->catfile( $project_cli_root, 'foobar', 'run' )
  or die "Unable to chmod project run command: $!";
make_path( File::Spec->catdir( $cli_root, 'jq.d' ) );
open my $home_hook_fh, '>', File::Spec->catfile( $cli_root, 'jq.d', '02-home-only.pl' )
  or die "Unable to write home fallback hook: $!";
print {$home_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-hook\n";
PL
close $home_hook_fh;
chmod 0755, File::Spec->catfile( $cli_root, 'jq.d', '02-home-only.pl' )
  or die "Unable to chmod home fallback hook: $!";
my $project_tool_hook_root = File::Spec->catdir( $project_cli_root, 'tool.d' );
make_path($project_tool_hook_root);
make_path( File::Spec->catdir( $cli_root, 'tool.d' ) );
open my $home_tool_hook_fh, '>', File::Spec->catfile( $cli_root, 'tool.d', '01-home-tool.pl' )
  or die "Unable to write home tool hook: $!";
print {$home_tool_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-hook\n";
PL
close $home_tool_hook_fh;
chmod 0755, File::Spec->catfile( $cli_root, 'tool.d', '01-home-tool.pl' )
  or die "Unable to chmod home tool hook: $!";
open my $project_pjq_first_fh, '>', File::Spec->catfile( $project_tool_hook_root, '00-project-first.pl' )
  or die "Unable to write project-first hook: $!";
print {$project_pjq_first_fh} <<'PL';
#!/usr/bin/env perl
print "project-hook\n";
PL
close $project_pjq_first_fh;
chmod 0755, File::Spec->catfile( $project_tool_hook_root, '00-project-first.pl' )
  or die "Unable to chmod project-first hook: $!";
open my $project_pjq_run_fh, '>', File::Spec->catfile( $project_cli_root, 'tool' )
  or die "Unable to write project tool command: $!";
print {$project_pjq_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $project_pjq_run_fh;
chmod 0755, File::Spec->catfile( $project_cli_root, 'tool' )
  or die "Unable to chmod project tool command: $!";

my ( $project_command_stdout, undef, $project_command_exit ) = _sh_capture("cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/d2' foobar one two");
is( $project_command_exit, 0, 'project-local custom command exits successfully' );
like( $project_command_stdout, qr/^project-command:one two$/m, 'project-local custom command overrides the home CLI command when a local dashboard root exists' );

my ( $project_hook_stdout, $project_hook_stderr, $project_hook_exit ) = _sh_capture("cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/d2' tool");
is( $project_hook_exit, 0, 'project-local hook-backed command exits successfully' );
like( $project_hook_stdout, qr/project-hook/, 'project-local hook directories run before the final command' );
like( $project_hook_stdout, qr/home-hook/, 'project-local hook-backed commands still inherit matching home hook directories' );
like( $project_hook_stdout, qr/00-project-first\.pl/, 'project-local hook results are propagated into RESULT for the final command' );
is( $project_hook_stderr, '', 'project-local hook-backed command keeps stderr clean' );

my $layer_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'oop-layer-root' );
my $layer_parent = File::Spec->catdir( $layer_root, 'parent' );
my $layer_leaf = File::Spec->catdir( $layer_parent, 'leaf' );
my $layer_home_cli = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
my $layer_parent_cli = File::Spec->catdir( $layer_parent, '.developer-dashboard', 'cli' );
my $layer_leaf_cli = File::Spec->catdir( $layer_leaf, '.developer-dashboard', 'cli' );
make_path( File::Spec->catdir( $layer_home_cli, 'global-only' ) );
open my $home_global_run_fh, '>', File::Spec->catfile( $layer_home_cli, 'global-only', 'run' )
  or die "Unable to write home global-only command: $!";
print {$home_global_run_fh} <<'SH';
#!/bin/sh
printf 'home-global:%s\n' "$*"
SH
close $home_global_run_fh;
chmod 0755, File::Spec->catfile( $layer_home_cli, 'global-only', 'run' )
  or die "Unable to chmod home global-only command: $!";
make_path( File::Spec->catdir( $layer_leaf_cli, 'foobar' ) );
open my $layer_foobar_fh, '>', File::Spec->catfile( $layer_leaf_cli, 'foobar', 'run' )
  or die "Unable to write layered foobar command: $!";
print {$layer_foobar_fh} <<'SH';
#!/bin/sh
printf 'leaf-foobar:%s\n' "$*"
SH
close $layer_foobar_fh;
chmod 0755, File::Spec->catfile( $layer_leaf_cli, 'foobar', 'run' )
  or die "Unable to chmod layered foobar command: $!";
make_path( File::Spec->catdir( $layer_home_cli, 'layered-tool.d' ) );
open my $layer_home_hook_fh, '>', File::Spec->catfile( $layer_home_cli, 'layered-tool.d', '00-home.pl' )
  or die "Unable to write home layered hook: $!";
print {$layer_home_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-layer\n";
PL
close $layer_home_hook_fh;
chmod 0755, File::Spec->catfile( $layer_home_cli, 'layered-tool.d', '00-home.pl' )
  or die "Unable to chmod home layered hook: $!";
make_path( File::Spec->catdir( $layer_parent_cli, 'layered-tool.d' ) );
open my $layer_parent_hook_fh, '>', File::Spec->catfile( $layer_parent_cli, 'layered-tool.d', '10-parent.pl' )
  or die "Unable to write parent layered hook: $!";
print {$layer_parent_hook_fh} <<'PL';
#!/usr/bin/env perl
print "parent-layer\n";
PL
close $layer_parent_hook_fh;
chmod 0755, File::Spec->catfile( $layer_parent_cli, 'layered-tool.d', '10-parent.pl' )
  or die "Unable to chmod parent layered hook: $!";
make_path( File::Spec->catdir( $layer_leaf_cli, 'layered-tool.d' ) );
open my $layer_leaf_hook_fh, '>', File::Spec->catfile( $layer_leaf_cli, 'layered-tool.d', '20-leaf.pl' )
  or die "Unable to write leaf layered hook: $!";
print {$layer_leaf_hook_fh} <<'PL';
#!/usr/bin/env perl
print "leaf-layer\n";
PL
close $layer_leaf_hook_fh;
chmod 0755, File::Spec->catfile( $layer_leaf_cli, 'layered-tool.d', '20-leaf.pl' )
  or die "Unable to chmod leaf layered hook: $!";
open my $layer_tool_run_fh, '>', File::Spec->catfile( $layer_leaf_cli, 'layered-tool' )
  or die "Unable to write layered tool command: $!";
print {$layer_tool_run_fh} <<'PL';
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
close $layer_tool_run_fh;
chmod 0755, File::Spec->catfile( $layer_leaf_cli, 'layered-tool' )
  or die "Unable to chmod layered tool command: $!";
my $layered_command = File::Spec->catfile( $layer_leaf_cli, 'layered-tool' );
my $home_hook       = File::Spec->catfile( $layer_home_cli, 'layered-tool.d', '00-home.pl' );
my $parent_hook     = File::Spec->catfile( $layer_parent_cli, 'layered-tool.d', '10-parent.pl' );
my $leaf_hook       = File::Spec->catfile( $layer_leaf_cli, 'layered-tool.d', '20-leaf.pl' );

my ( $layered_command_stdout, undef, $layered_command_exit ) = _sh_capture("cd '$layer_leaf' && $perl -I'$repo/lib' '$repo/bin/d2' foobar one two");
is( $layered_command_exit, 0, 'deepest non-repo layer custom command exits successfully' );
like( $layered_command_stdout, qr/^leaf-foobar:one two$/m, 'deepest current-directory layer overrides home CLI commands even without a git repo' );

my $tmp_no_layer = tempdir( CLEANUP => 1 );
my ( $home_fallback_stdout, undef, $home_fallback_exit ) = _sh_capture("cd '$tmp_no_layer' && $perl -I'$repo/lib' '$repo/bin/d2' global-only here");
is( $home_fallback_exit, 0, 'home CLI fallback command exits successfully outside any project layer' );
like( $home_fallback_stdout, qr/^home-global:here$/m, 'home CLI fallback command resolves when no local layer exists' );

my ( $layered_hook_stdout, $layered_hook_stderr, $layered_hook_exit ) = _sh_capture("cd '$layer_leaf' && $perl -I'$repo/lib' '$repo/bin/d2' layered-tool");
is( $layered_hook_exit, 0, 'layered hook-backed command exits successfully' );
like( $layered_hook_stdout, qr/home-layer.*parent-layer.*leaf-layer/s, 'layered hooks run from home to leaf order across every discovered .developer-dashboard layer' );
like( $layered_hook_stdout, qr/00-home\.pl/, 'home hook output is preserved in RESULT for the final command' );
like( $layered_hook_stdout, qr/10-parent\.pl/, 'parent hook output is preserved in RESULT for the final command' );
like( $layered_hook_stdout, qr/20-leaf\.pl/, 'leaf hook output is preserved in RESULT for the final command' );
is( $layered_hook_stderr, '', 'layered hook-backed command keeps stderr clean' );
my $layered_which = _run("cd '$layer_leaf' && $perl -I'$repo/lib' '$repo/bin/d2' which layered-tool");
like( $layered_which, qr/^COMMAND \Q$layered_command\E$/m, 'd2 which reports the deepest resolved custom command path' );
like( $layered_which, qr/^HOOK \Q$home_hook\E$/m, 'd2 which includes the home-layer hook for a layered custom command' );
like( $layered_which, qr/^HOOK \Q$parent_hook\E$/m, 'd2 which includes the parent-layer hook for a layered custom command' );
like( $layered_which, qr/^HOOK \Q$leaf_hook\E$/m, 'd2 which includes the leaf-layer hook for a layered custom command' );

my $project_local_bookmarks = File::Spec->catdir( $project_root, '.developer-dashboard', 'dashboards' );
make_path($project_local_bookmarks);
my $project_local_paths = _run("cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/d2' paths");
# The paths output spells separators natively (backslashes on Windows,
# forward slashes everywhere else), and $project_root is built with
# File::Spec. Compare separator-normalized copies so the assertions
# check the paths, not the spelling of the separator.
my $project_root_forward = $project_root;
$project_root_forward =~ s/\\/\//g;
my $project_local_bookmarks_forward = $project_local_bookmarks;
$project_local_bookmarks_forward =~ s/\\/\//g;
my $project_local_paths_forward = $project_local_paths;
$project_local_paths_forward =~ s/\\/\//g;
like( $project_local_paths_forward, qr/runtime_root\s+\Q$project_root_forward\/.developer-dashboard\E/, 'd2 paths reports the project-local runtime root when present' );
like( $project_local_paths_forward, qr/dashboards_root\s+\Q$project_local_bookmarks_forward\E/, 'd2 paths reports the project-local dashboards root when present' );
my $project_cpan_output = _run("cd '$project_root' && PATH='$fake_bin':\"\$PATH\" $perl -I'$repo/lib' '$repo/bin/d2' cpan DBD::Mock");
# The cpan output is JSON, so each Windows backslash arrives escaped as
# a pair: normalize each PAIR to one slash, not each backslash (that
# doubled every separator in build 117). Plain-text outputs below still
# use the single-backslash form.
my $project_cpan_output_forward = $project_cpan_output;
$project_cpan_output_forward =~ s/\\\\/\//g;
like( $project_cpan_output_forward, qr/"ok"\s*:\s*1/, 'd2 cpan reports success' );
like( $project_cpan_output_forward, qr/"runtime_root"\s*:\s*"\Q$project_root_forward\/.developer-dashboard\E"/, 'd2 cpan reports the project-local runtime root' );
like( $project_cpan_output_forward, qr/"cpanfile"\s*:\s*"\Q$project_root_forward\/.developer-dashboard\/cpanfile\E"/, 'd2 cpan reports the runtime cpanfile path' );
like( $project_cpan_output_forward, qr/"local_root"\s*:\s*"\Q$project_root_forward\/.developer-dashboard\/local\E"/, 'd2 cpan reports the runtime local library root' );
open my $project_cpanfile_fh, '<', File::Spec->catfile( $project_root, '.developer-dashboard', 'cpanfile' )
  or die "Unable to read project runtime cpanfile: $!";
my $project_cpanfile = do { local $/; <$project_cpanfile_fh> };
close $project_cpanfile_fh;
like( $project_cpanfile, qr/requires 'DBI';/, 'd2 cpan records DBI in the runtime cpanfile when installing a DBD driver' );
like( $project_cpanfile, qr/requires 'DBD::Mock';/, 'd2 cpan records the requested DBD driver in the runtime cpanfile' );
open my $fake_cpanm_log_fh, '<', $fake_cpanm_log or die "Unable to read $fake_cpanm_log: $!";
my $fake_cpanm_args = do { local $/; <$fake_cpanm_log_fh> };
close $fake_cpanm_log_fh;
# The fake-cpanm log is plain text with single backslashes on Windows,
# so it takes the single-backslash normalization, like the paths output.
my $fake_cpanm_args_forward = $fake_cpanm_args;
$fake_cpanm_args_forward =~ s/\\/\//g;
like( $fake_cpanm_args_forward, qr/-L \Q$project_root_forward\/.developer-dashboard\/local\E/, 'd2 cpan installs into the project-local runtime local library' );
like( $fake_cpanm_args, qr/\bDBI\b/, 'd2 cpan installs DBI automatically for DBD drivers' );
like( $fake_cpanm_args, qr/\bDBD::Mock\b/, 'd2 cpan installs the requested DBD driver' );


# ---------------------------------------------------------------------------
# DD-810: THE MAIN GATE. A hooks/ directory in any runtime layer holds
# executables that run ONCE per bin/d2 invocation, before command
# resolution, for every form of the command line. Every scenario below builds
# its OWN fresh HOME: a main-gate hook under the shared $ENV{HOME} above would
# fire on every later invocation in this file and turn unrelated assertions
# into tests of this section.
# ---------------------------------------------------------------------------
my $d2_entrypoint = File::Spec->catfile( $repo, 'bin', 'd2' );

# _gate_fixture()
# Builds one isolated HOME with an empty project layer beneath it.
# Input: none.
# Output: list of ($home, $project_dir, $home_hooks_dir, $project_hooks_dir);
#         both hooks/ directories exist and are empty.
sub _gate_fixture {
    my $home       = abs_path( tempdir( CLEANUP => 1 ) );
    my $proj       = File::Spec->catdir( $home, 'proj' );
    my $home_hooks = File::Spec->catdir( $home, '.developer-dashboard', 'hooks' );
    my $proj_hooks = File::Spec->catdir( $proj, '.developer-dashboard', 'hooks' );
    make_path( $home_hooks, $proj_hooks );
    return ( $home, $proj, $home_hooks, $proj_hooks );
}

# _gate_file($path, $content, $mode)
# Writes one hook (or decoy) file with an explicit permission mode, creating
# its parent directory when needed.
# Input: absolute path, file content, octal mode.
# Output: the path written.
sub _gate_file {
    my ( $path, $content, $mode ) = @_;
    my ( $volume, $dir ) = File::Spec->splitpath($path);
    my $parent = File::Spec->catpath( $volume, $dir, '' );
    make_path($parent) if $parent ne '' && !-d $parent;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    chmod $mode, $path or die "Unable to chmod $path: $!";
    return $path;
}

# _gate_run($home, $dir, $entrypoint, @args)
# Runs an entrypoint under an explicit HOME from an explicit directory and
# returns everything it produced. Nothing is asserted here because several
# scenarios expect a non-zero exit.
# Input: HOME directory, working directory, entrypoint path, argv list.
# Output: list of (stdout, stderr, exit_code), both streams UTF-8 decoded.
sub _gate_run {
    my ( $home, $dir, $entrypoint, @args ) = @_;
    my $argv = join ' ', map { "'$_'" } @args;
    my $child_perl5opt = join ' ',
      grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    my %env;
    if ( _coverage_requested() ) {
        $env{PERL5OPT} = $child_perl5opt;
        # Clear HARNESS_PERL_SWITCHES too: its switches are already merged
        # into PERL5OPT above, and leaving the ambient value in the child
        # would be stale — the restart blocks clear both the same way.
        $env{HARNESS_PERL_SWITCHES} = undef;
    }
    my ( $stdout, $stderr, $exit_code ) = run_shell_command(
        "cd '$dir' && HOME='$home' '$perl' -I'$lib' '$entrypoint' $argv",
        { env => \%env },
    );
    return ( decode( 'UTF-8', $stdout ), decode( 'UTF-8', $stderr ), $exit_code );
}

# _gate_lines($path)
# Reads a marker file written by hooks as a list of chomped lines.
# Input: marker path.
# Output: list of lines; the empty list when the file does not exist.
sub _gate_lines {
    my ($path) = @_;
    return () if !-e $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my @lines = <$fh>;
    close $fh or die "Unable to close $path: $!";
    chomp @lines;
    return @lines;
}

# AC-4: a layer with no hooks/ contributes nothing, and zero hooks is
# bit-for-bit today's behaviour - stderr EMPTY, not merely "no failure".
{
    my $home = abs_path( tempdir( CLEANUP => 1 ) );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $home, $dashboard, 'version' );
    is( $stdout, "$expected_version\n", 'AC-4: no hooks/ directory anywhere - version output unchanged' );
    is( $stderr, '',                    'AC-4: no hooks/ directory anywhere - stderr empty' );
    is( $exit,   0,                     'AC-4: no hooks/ directory anywhere - exit 0' );

    my ( $empty_home, $empty_proj ) = _gate_fixture();
    ( $stdout, $stderr, $exit ) = _gate_run( $empty_home, $empty_proj, $dashboard, 'version' );
    is( $stdout, "$expected_version\n", 'AC-4: empty hooks/ in two layers - version output unchanged' );
    is( $stderr, '',                    'AC-4: empty hooks/ in two layers - stderr empty, no warning' );
    is( $exit,   0,                     'AC-4: empty hooks/ in two layers - exit 0' );
}

# AC-1: the gate runs exactly once per invocation, BEFORE command resolution,
# so every form of the command line - including the forms that never resolve
# a command at all - passes through it. Each form is compared against a
# hookless control HOME to prove the gate alters neither output nor exit.
{
    my ( $home, $proj, $home_hooks ) = _gate_fixture();
    my $control = abs_path( tempdir( CLEANUP => 1 ) );
    my $marker  = File::Spec->catfile( $home, 'hook-marker' );
    _gate_file(
        File::Spec->catfile( $home_hooks, '10-mark.sh' ),
        "#!/bin/sh\nprintf 'HOOK-RAN %s\\n' \"\$*\" >> '$marker'\n",
        0755
    );

    my @forms = (
        [ 'no command',      [] ],
        [ 'help',            ['help'] ],
        [ 'version',         ['version'] ],
        [ 'which version',   [ 'which', 'version' ] ],
        [ 'unknown command', ['no-such-command-dd810'] ],
    );
    my $expected_lines = 0;
    for my $form (@forms) {
        my ( $label, $argv ) = @{$form};
        my @gated   = _gate_run( $home,    $home,    $dashboard, @{$argv} );
        my @control = _gate_run( $control, $control, $dashboard, @{$argv} );
        is( $gated[0], $control[0], "AC-1 [$label]: stdout identical to the hookless control" );
        is( $gated[1], $control[1], "AC-1 [$label]: stderr identical to the hookless control" );
        is( $gated[2], $control[2], "AC-1 [$label]: exit status identical to the hookless control" );
        $expected_lines++;
        my @lines = _gate_lines($marker);
        is( scalar @lines, $expected_lines,
            "AC-1 [$label]: the main gate ran exactly once (marker now $expected_lines line(s))" );

        # DD-835 (reverses DD-832): the hook's argv is the full command line
        # as typed, including the top-level command name as its first
        # element - it is NOT stripped to match the eventual target's argv.
        is( $lines[-1] // '', 'HOOK-RAN ' . join( ' ', @{$argv} ),
            "AC-1 [$label]: the hook's argv is the full command line, with the command name prepended" );
    }
}

# AC-11 (Q-142 A): deepest layer first, HOME last - the REVERSE of the
# per-command chain, deliberately. Exercised through bin/d2 so the re-exec
# path carries the order too.
{
    my ( $home, $proj, $home_hooks, $proj_hooks ) = _gate_fixture();
    _gate_file( File::Spec->catfile( $home_hooks, 'foo.pl' ), "#!$perl\nprint \"foo.pl\\n\";\n", 0755 );
    _gate_file( File::Spec->catfile( $proj_hooks, 'bar.pl' ), "#!$perl\nprint \"bar.pl\\n\";\n", 0755 );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $proj, $d2_entrypoint, 'version' );
    # Hook stdout is streamed through live, so on Windows each hook line
    # arrives with CRLF (the hook child's :crlf layer) while the version
    # line is bare LF: normalize the line endings in a copy so the
    # comparison checks the order and the content, not the platform's
    # line endings. The streamed display itself stays untouched (bare LF
    # would stair-step in cmd.exe).
    my $stdout_lf = $stdout;
    $stdout_lf =~ s/\r\n/\n/g;
    is( $stdout_lf, "bar.pl\nfoo.pl\n$expected_version\n",
        'AC-11: project hook (deepest) runs first, HOME hook last, then the command' );
    is( $stderr, '', 'AC-11: ordering scenario writes nothing to stderr' );
    is( $exit,   0,  'AC-11: ordering scenario exits 0' );
}

# AC-12 (Q-143 A): every layer between the cwd and HOME contributes its hooks.
{
    my $home   = abs_path( tempdir( CLEANUP => 1 ) );
    my $a      = File::Spec->catdir( $home, 'a' );
    my $b      = File::Spec->catdir( $a,    'b' );
    my $marker = File::Spec->catfile( $home, 'layer-marker' );
    for my $layer ( [ $home, 'home' ], [ $a, 'a' ], [ $b, 'b' ] ) {
        my ( $dir, $name ) = @{$layer};
        _gate_file(
            File::Spec->catfile( $dir, '.developer-dashboard', 'hooks', '10-mark.sh' ),
            "#!/bin/sh\necho '$name' >> '$marker'\n",
            0755
        );
    }
    my ( undef, undef, $exit ) = _gate_run( $home, $b, $dashboard, 'version' );
    is( $exit, 0, 'AC-12: three-layer stack exits 0 from the deepest layer' );
    is_deeply( [ _gate_lines($marker) ], [ 'b', 'a', 'home' ],
        'AC-12: from HOME/a/b every layer contributes, deepest first' );
    unlink $marker;
    ( undef, undef, $exit ) = _gate_run( $home, $a, $dashboard, 'version' );
    is( $exit, 0, 'AC-12: two-layer stack exits 0 from the middle layer' );
    is_deeply( [ _gate_lines($marker) ], [ 'a', 'home' ],
        'AC-12: from HOME/a only the layers at or above the cwd contribute' );
}

# AC-13 (Q-144 A): each hook is handed the full command argv, and the previous
# hook's stdout/stderr/exit are recorded in LAST_RESULT for the next one -
# the same contract the per-command chain honours.
{
    my ( $home, $proj, $home_hooks ) = _gate_fixture();
    my $argv_file   = File::Spec->catfile( $home, 'hook-argv' );
    my $result_file = File::Spec->catfile( $home, 'hook-last-result' );
    _gate_file(
        File::Spec->catfile( $home_hooks, '10-argv.sh' ),
        "#!/bin/sh\nprintf '%s\\n' \"\$*\" > '$argv_file'\necho first-hook-stdout\n",
        0755
    );
    _gate_file(
        File::Spec->catfile( $home_hooks, '20-last-result.sh' ),
        "#!/bin/sh\nprintf '%s' \"\${LAST_RESULT:-}\" > '$result_file'\n",
        0755
    );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $home, $d2_entrypoint, 'version', '--json' );
    is( $exit, 0, 'AC-13: version with an extra argument still exits 0 through the gate' );

    # DD-835 (reverses DD-832): the hook's argv is the full command line as
    # typed - "version" is prepended, not stripped. The hook script joins
    # $* into a single line, so this is one element.
    is_deeply( [ _gate_lines($argv_file) ], ['version --json'],
        "AC-13: the main-gate hook's argv is the full command line, with the command name prepended" );
    my $last_json = join '', _gate_lines($result_file);
    ok( $last_json ne '', 'AC-13: the second main-gate hook receives LAST_RESULT from the first' );
    my $last = $last_json ne '' ? json_decode($last_json) : {};
    like( $last->{file} // '', qr/\Q10-argv.sh\E\z/, 'AC-13: LAST_RESULT names the previous main-gate hook file' );
    is( $last->{exit},   0,                     'AC-13: LAST_RESULT carries the previous hook exit code' );
    is( $last->{STDOUT}, "first-hook-stdout\n", 'AC-13: LAST_RESULT carries the previous hook stdout' );
    is( $last->{STDERR}, '',                    'AC-13: LAST_RESULT carries the previous hook stderr' );
}

# DD-832 AC-2: a main-gate hook can still learn which top-level command is
# about to run, via $ENV{DEVELOPER_DASHBOARD_COMMAND} - set before the main
# gate runs now that the command name is no longer prepended to the hook's
# own argv.
{
    my ( $home, $proj, $home_hooks ) = _gate_fixture();
    my $command_file = File::Spec->catfile( $home, 'hook-command-env' );
    _gate_file(
        File::Spec->catfile( $home_hooks, '10-command-env.sh' ),
        "#!/bin/sh\nprintf '%s' \"\${DEVELOPER_DASHBOARD_COMMAND:-}\" > '$command_file'\n",
        0755
    );
    my ( undef, undef, $exit ) = _gate_run( $home, $home, $dashboard, 'version' );
    is( $exit, 0, 'DD-832 AC-2: version through the gate still exits 0' );
    is( join( '', _gate_lines($command_file) ), 'version',
        'DD-832 AC-2: a main-gate hook reads the top-level command name from $ENV{DEVELOPER_DASHBOARD_COMMAND}' );
}

# AC-5: hook output is streamed through the same runner as per-command hooks,
# so it appears BEFORE the command's own output.
{
    my ( $home, $proj, $home_hooks ) = _gate_fixture();
    _gate_file( File::Spec->catfile( $home_hooks, '10-hello.sh' ), "#!/bin/sh\necho 'hello from main gate'\n", 0755 );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $home, $dashboard, 'version' );
    is( $stdout, "hello from main gate\n$expected_version\n", 'AC-5: hook stdout is streamed before the command output' );
    is( $stderr, '', 'AC-5: streaming scenario writes nothing to stderr' );
    is( $exit,   0,  'AC-5: streaming scenario exits 0' );
}

# AC-3: discovery mirrors _command_hook_roots - only executable regular files
# directly under <layer>/hooks/, lexically sorted; a non-executable file, a
# subdirectory and a file named run are all skipped.
{
    my ( $home, $proj, $home_hooks, $proj_hooks ) = _gate_fixture();
    my $marker = File::Spec->catfile( $home, 'discovery-marker' );
    my %entries = (
        '10-a.sh'          => 0755,
        '20-b.sh'          => 0755,
        '30-c.sh'          => 0644,
        'sub/40-d.sh'      => 0755,
        'run'              => 0755,
    );
    for my $entry ( sort keys %entries ) {
        _gate_file( File::Spec->catfile( $proj_hooks, split m{/}, $entry ),
            "#!/bin/sh\necho '$entry' >> '$marker'\n", $entries{$entry} );
    }
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $proj, $dashboard, 'version' );
    is( $exit, 0, 'AC-3: discovery scenario exits 0' );
    # On Windows there are no Unix mode bits: chmod 0644 and 0755 leave
    # identical filesystem state (both stat 0666, verified live on win-ts),
    # so a 0644 .sh file is runnable there by the platform's own rule
    # (extension + interpreter + shebang) and runs. This is not a skip:
    # the expectation still asserts the full discovery behavior on every
    # platform, and the sub/ and run skips below hold everywhere - only
    # the mode-bit part of the expectation is platform-conditional.
    my @ac3_expected = $^O eq 'MSWin32' ? ( '10-a.sh', '20-b.sh', '30-c.sh' ) : ( '10-a.sh', '20-b.sh' );
    is_deeply( [ _gate_lines($marker) ], \@ac3_expected,
        'AC-3: only executable regular files directly under hooks/ run, in lexical order; 0644, sub/ and run are skipped' );
    is( $stderr, '', 'AC-3: skipped entries produce no warning' );
}

# AC-6: d2 which <cmd> reports the main-gate hooks it would run, one
# HOOK <absolute path> line each in run order, BEFORE the per-command lines.
# (which version cannot resolve - version is a switchboard built-in, not a
# helper - so the resolvable helper jq is the subject here.)
{
    my ( $home, $proj, $home_hooks, $proj_hooks ) = _gate_fixture();
    my $hook_marker = File::Spec->catfile( $home, 'which-marker' );
    for my $entry ( [ '10-a.sh', 0755 ], [ '20-b.sh', 0755 ], [ '30-c.sh', 0644 ], [ 'run', 0755 ] ) {
        _gate_file( File::Spec->catfile( $proj_hooks, $entry->[0] ), "#!/bin/sh\necho '$entry->[0]' >> '$hook_marker'\n", $entry->[1] );
    }
    _gate_file( File::Spec->catfile( $proj_hooks, 'sub', '40-d.sh' ), "#!/bin/sh\necho '40-d.sh' >> '$hook_marker'\n", 0755 );
    my $cmd_hook = _gate_file(
        File::Spec->catfile( $proj, '.developer-dashboard', 'cli', 'jq.d', '50-cmd.sh' ),
        "#!/bin/sh\necho '50-cmd.sh' >> '$hook_marker'\n",
        0755
    );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $proj, $dashboard, 'which', 'jq' );
    is( $exit, 0, 'AC-6: which jq exits 0 with main-gate hooks present' );
    my @lines = grep { $_ ne '' } split /\n/, $stdout;
    like( $lines[0] // '', qr/^COMMAND /, 'AC-6: which jq still prints the COMMAND line first' );
    is_deeply(
        [ map { _portable_output_text($_) } grep { /^HOOK / } @lines ],
        [ map { _portable_output_text($_) } (
            'HOOK ' . File::Spec->catfile( $proj_hooks, '10-a.sh' ),
            'HOOK ' . File::Spec->catfile( $proj_hooks, '20-b.sh' ),
            # Same Windows mode-bit rule as AC-3 above: 30-c.sh is
            # runnable there, so which lists it too.
            ( $^O eq 'MSWin32' ? ( 'HOOK ' . File::Spec->catfile( $proj_hooks, '30-c.sh' ) ) : () ),
            "HOOK $cmd_hook",
        ) ],
        'AC-6: which jq lists the main-gate hooks in run order before the per-command hook, skipping 0644, sub/ and run'
    );
    is_deeply( [ _gate_lines($hook_marker) ],
        $^O eq 'MSWin32' ? [ '10-a.sh', '20-b.sh', '30-c.sh' ] : [ '10-a.sh', '20-b.sh' ],
        'AC-6: which jq itself passed through the main gate exactly once' );
}

# AC-7: a hook that invokes dashboard itself must not recurse. The fixture
# caps its own depth at three markers so a missing guard fails the assertion
# instead of forking without bound on a shared host. The depth is counted
# with perl, not wc -l | tr: both live in Git usr/bin, which is not on the
# Windows job PATH, so with them missing the depth came back empty, the -lt
# test errored, and the nested invocation never ran - the guard passed
# vacuously there.
{
    my ( $home, $proj, $home_hooks ) = _gate_fixture();
    my $marker = File::Spec->catfile( $home, 'nested-marker' );
    _gate_file(
        File::Spec->catfile( $home_hooks, '10-nested.sh' ),
        "#!/bin/sh\necho nested >> '$marker'\n"
          . "depth=\$('$perl' -ne 'END { print \$.\+0 }' '$marker')\n"
          . "if [ \"\$depth\" -lt 3 ]; then HOME='$home' '$perl' -I'$lib' '$dashboard' version >/dev/null 2>&1; fi\n",
        0755
    );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $home, $dashboard, 'version' );
    is( $exit,   0,                     'AC-7: a hook that re-enters dashboard still lets the outer command exit 0' );
    is( $stdout, "$expected_version\n", 'AC-7: the outer command output is unaffected by the nested invocation' );
    is( scalar( () = _gate_lines($marker) ), 1, 'AC-7: the recursion guard lets the main gate run exactly once' );
}

# AC-14 (Q-149 B): [[STOP]] on a main-gate hook's stderr skips the remaining
# hooks AND the command; dashboard exits 1 with the hook's stderr visible.
# This deliberately differs from the per-command chain, where a stop lets the
# command run and exit 0 (see the hook-stop-check scenario above).
{
    my ( $home, $proj, $home_hooks ) = _gate_fixture();
    my $marker = File::Spec->catfile( $home, 'stop-marker' );
    _gate_file( File::Spec->catfile( $home_hooks, '10-gate.sh' ),
        "#!/bin/sh\necho 'blocked: no ticket' >&2\necho '[[STOP]]' >&2\nexit 0\n", 0755 );
    _gate_file( File::Spec->catfile( $home_hooks, '20-mark.sh' ), "#!/bin/sh\necho ran >> '$marker'\n", 0755 );
    my ( $stdout, $stderr, $exit ) = _gate_run( $home, $home, $dashboard, 'version' );
    is( $stdout, '', 'AC-14: a main-gate [[STOP]] prevents the command from running (empty stdout)' );
    like( $stderr, qr/^blocked: no ticket$/m, 'AC-14: the stopping hook stderr reaches the caller' );
    like( $stderr, qr/^\[\[STOP\]\]$/m,        'AC-14: the [[STOP]] marker itself is visible on stderr' );
    is( $exit, 1, 'AC-14: dashboard exits 1 after a main-gate stop' );
    ok( !-e $marker, 'AC-14: the hooks after the stopping one never run' );
}

# AC-8 and AC-9: the gate resolves its roots from the runtime layer stack (no
# new hard-coded layer literal in the switchboard), and the switchboard POD
# describes the main gate.
{
    open my $fh, '<', $dashboard or die "Unable to read $dashboard: $!";
    my $source = do { local $/; <$fh> };
    close $fh;
    my $literal_count = () = $source =~ /'\.developer-dashboard'/g;
    is( $literal_count, 0, 'AC-8: bin/d2 gains no hard-coded .developer-dashboard literal for the main gate' );
    like( $source, qr/^=head\d.*\bmain gate\b/mi,     'AC-9: bin/d2 POD has a heading for the main gate' );
    like( $source, qr/hooks\/.*deepest.*first/is,     'AC-9: bin/d2 POD states the deepest-first run order' );
    like( $source, qr/\[\[STOP\]\].*exit(?:s)? (?:non-zero|1)/is, 'AC-9: bin/d2 POD states the main-gate stop contract' );
}
done_testing;

sub _write_zip_entries {
    my ( $archive, $entries ) = @_;
    my $zip = Archive::Zip->new();
    for my $name ( sort keys %{$entries || {}} ) {
        $zip->addString( $entries->{$name}, $name );
    }
    my $status = $zip->writeToFileNamed($archive);
    die "Unable to write $archive\n" if $status != AZ_OK;
    return 1;
}

# _sh_capture($cmd, \%options)
# Runs one shell fragment and returns (stdout, stderr, exit_code), the
# exit code already shifted, matching the capture blocks it replaces.
# On Unix it is `sh -c`; on Windows it is the native runner, so a call
# site needs no platform branch of its own. The env option carries
# environment overrides (undef deletes the key).
sub _sh_capture {
    my ( $cmd, $options ) = @_;
    return run_shell_command( $cmd, $options || {} );
}

# _helper_is_executable($path)
# Unix filesystems carry an exec bit; Windows has none, and the dashboard
# always invokes helpers as `$perl <helper>`, so readability is the
# Windows equivalent of "the helper can be run".
sub _helper_is_executable {
    my ($path) = @_;
    return -r $path if $^O eq 'MSWin32';
    return -x $path;
}

sub _run {
    my ($cmd) = @_;
    my $child_perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    my $runtime_command = (
        defined $dashboard
          && $cmd =~ /\Q'$dashboard'\E\s+(?:serve|restart|stop)\b/
    ) || (
        defined $runtime_dd_cli_root
          && $cmd =~ /\Q'$runtime_dd_cli_root\E\/(?:_dashboard-core|doctor|serve|restart|stop)\b/
    );

    # There is no sh on Windows, so the command is run natively there
    # (Local::NativeCommand parses the fragment and launches the argv list
    # directly); on Unix it is still `sh -c`, unchanged. The Git Bash path
    # rewriting and MSYS conversion variables this used to work around are
    # gone with the shell.
    my %env;
    if ($runtime_command) {
        $env{PERL5OPT}              = undef;
        $env{HARNESS_PERL_SWITCHES} = undef;
    }
    elsif ( _coverage_requested() ) {
        $env{PERL5OPT} = $child_perl5opt;
    }
    my ( $stdout, $stderr, $exit_code ) = run_shell_command( $cmd, { env => \%env } );
    is( $exit_code, 0, "command succeeded: $cmd" );
    return decode( 'UTF-8', $stdout . $stderr );
}

sub _run_in_dir {
    my ( $dir, $cmd ) = @_;
    die "run directory is required\n" if !defined $dir || $dir eq '';
    die "command is required\n" if !defined $cmd || $cmd eq '';
    return _run("cd '$dir' && $cmd");
}

sub _run_in_home {
    my ( $home, $cmd ) = @_;
    die "home directory is required\n" if !defined $home || $home eq '';
    return _run_in_dir( $home, $cmd );
}

sub _run_interactive_command {
    my (%args) = @_;
    my $command = $args{command} || die "interactive command array required";
    my $input = defined $args{input} ? $args{input} : '';
    require IPC::Open3;
    require Symbol;
    my $stderr_fh = Symbol::gensym();
    my $pid = IPC::Open3::open3( my $stdin_fh, my $stdout_fh, $stderr_fh, @{$command} );
    print {$stdin_fh} $input;
    close $stdin_fh;
    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr = do { local $/; <$stderr_fh> };
    waitpid( $pid, 0 );
    return {
        stdout    => decode( 'UTF-8', $stdout // '' ),
        stderr    => decode( 'UTF-8', $stderr // '' ),
        exit_code => $? >> 8,
    };
}

sub _literal_pattern {
    my (@tokens) = @_;
    return qr/@{[ join '|', map { quotemeta $_ } @tokens ]}/i;
}

sub _find_free_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to reserve a free local TCP port: $!";
    my $port = $socket->sockport();
    close $socket or die "Unable to release reserved local TCP port $port: $!";
    return $port;
}

sub _startup_probe_attempts {
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return 480 if $perl5opt =~ /Devel::Cover/;
    return 160;
}

sub _coverage_requested {
    return 1 if $UNDER_COVER;
    my $perl5opt = join ' ', grep { defined $_ && $_ ne '' } ( $ENV{PERL5OPT}, $ENV{HARNESS_PERL_SWITCHES} );
    return $perl5opt =~ /Devel::Cover/ ? 1 : 0;
}

# _module_version($path)
# Reads the declared Developer Dashboard release version from a Perl module.
# Input: path string to the main module or the lightweight Version module.
# Output: version string, resolving the shared Version module when the main
# module aliases its scalar, or a fatal error when no version is declared.
sub _module_version {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $1 if $content =~ /our \$VERSION = '([^']+)'/;
    if ( $content =~ /our \$VERSION = \$Developer::Dashboard::Version::VERSION;/ ) {
        my ( $volume, $directory ) = File::Spec->splitpath($path);
        return _module_version(
            File::Spec->catpath( $volume, $directory, File::Spec->catfile( 'Dashboard', 'Version.pm' ) )
        );
    }
    die "Unable to find module version in $path";
}

sub _command_available {
    my ($name) = @_;
    if ( $^O eq 'MSWin32' ) {

        # There is no sh on Windows, so `command -v` cannot run. where.exe
        # answers the same question natively.
        my ( undef, undef, $exit_code ) = capture {
            system 'where', $name;
            return $? >> 8;
        };
        return $exit_code == 0 ? 1 : 0;
    }
    my ( undef, undef, $exit_code ) = _sh_capture("command -v '$name' >/dev/null 2>&1");
    return $exit_code == 0 ? 1 : 0;
}

sub _command_usable {
    my ( $name, @args ) = @_;
    return 0 if !_command_available($name);
    my ( undef, undef, $exit_code ) = capture {
        system $name, @args;
        return $? >> 8;
    };
    return $exit_code == 0 ? 1 : 0;
}

# _java_toolchain_skip_reason()
# Checks that the available Java compiler can produce a class that the selected
# runtime can execute, so Java-specific smoke assertions skip on mismatched JDKs.
# Input: none; resolves javac and java through the current PATH.
# Output: undef when compatible, or a visible skip reason string.
sub _java_toolchain_skip_reason {
    return 'javac is unavailable' if !_command_usable( 'javac', '-version' );
    return 'java is unavailable' if !_command_usable( 'java', '-version' );

    my $probe_dir = tempdir( 'dd-java-toolchain-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $probe_source = File::Spec->catfile( $probe_dir, 'DashboardJavaToolchainProbe.java' );
    open my $probe_handle, '>', $probe_source
      or die "Unable to write Java toolchain probe '$probe_source': $!";
    print {$probe_handle} <<'JAVA_PROBE';
public class DashboardJavaToolchainProbe {
    public static void main(String[] args) {
        System.out.println("dashboard-java-toolchain-ok");
    }
}
JAVA_PROBE
    close $probe_handle
      or die "Unable to close Java toolchain probe '$probe_source': $!";

    my ( undef, undef, $compile_exit ) = capture {
        system 'javac', $probe_source;
        return $? >> 8;
    };
    return "javac could not compile a compatibility probe (exit $compile_exit)"
      if $compile_exit != 0;

    my ( $stdout, $run_stderr, $run_exit ) = capture {
        system 'java', '-cp', $probe_dir, 'DashboardJavaToolchainProbe';
        return $? >> 8;
    };
    return "javac output is incompatible with the available java runtime (exit $run_exit)"
      if $run_exit != 0 || $stdout ne "dashboard-java-toolchain-ok\n";

    return;
}

sub _go_supports_run_from_directory {
    return 0 if !_command_available('go');
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'go', 'run', '-C', '.', '-h';
        return $? >> 8;
    };
    return 0 if $exit_code != 0;
    return 0 if ( $stdout . $stderr ) =~ /flag provided but not defined:\s*-C/;
    return 1;
}

__END__

=head1 NAME

05-cli-smoke.t - CLI smoke tests for dashboard

=head1 DESCRIPTION

This test verifies the main command-line entrypoints for Developer Dashboard.
It also verifies Docker service base/development compose selection and the
development marker commands through the staged helper without starting real
containers. Built-in and nested help, catalog-backed actions/options, the
version command, and generated Bash completion are exercised through the same
public CLI dispatch; the zsh bootstrap's completion registration is checked.
The cdr completion case verifies that alias-root suggestions stay at the
immediate child level instead of recursively walking deeper descendants on
every TAB.
The open-file smoke cases also prove that content grep returns matching paths
instead of treating `grep` and its switches as filename patterns.
Top-level log tests exercise `-t`, `-f`, `--tail N`, and `--tail=N` through
public helper dispatch, including web, collector, mixed output, timestamped
follow, and zero-line requests.
The layered-environment fixture also proves that a project-root `.env.pl` can
read values from the home `.developer-dashboard/.env` file.
When this checkout has a built XS extension, child Perl commands also verify
that the current `blib/arch` is preferred over an installed older copy.
The live foreground status probe is launched, terminated, and reaped through
the Dashboard GoRoutine process API to keep process control portable.
Java-specific hook and direct-source assertions first compile and run a small
compatibility probe; those assertions skip with a visible reason when the
available Java compiler and runtime are missing or incompatible.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the thin CLI, helper staging, low-level runtime contracts, layered environment inheritance, Docker help and completion, Docker service development overlays, and the user-facing `d2 of grep` invocation. Its shell completion checks cover command-only root candidates, nested actions, parser-backed flags such as API's implicit list options, and bounded cdr directory traversal. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the thin CLI, helper staging, and low-level runtime contracts has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the thin CLI, helper staging, layered environment inheritance, completion candidate scope, cdr directory traversal, low-level runtime contracts, or public log timestamp/follow/tail behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/05-cli-smoke.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. The Docker assertions use Compose resolution/dry-run output; they do not start the declared services.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/05-cli-smoke.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/05-cli-smoke.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

Example 4:

  d2 docker development enable green
  d2 docker compose --dry-run config green
  d2 docker development disable green

Verify that the base compose file remains selected, the opt-in development
overlay is layered above it, and disabling the marker returns to the base-only
configuration without starting containers.

=for comment FULL-POD-DOC END

=cut
