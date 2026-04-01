use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use Developer::Dashboard::JSON qw(json_decode json_encode);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Runtime::Result;
use Test::More;

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{PERL5LIB} = join ':', grep { defined && $_ ne '' } '/home/mv/perl5/lib/perl5', ( $ENV{PERL5LIB} || () );

my $perl = $^X;
my $repo = getcwd();
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";
my $lib = File::Spec->catdir( $repo, 'lib' );
my $dashboard = File::Spec->catfile( $repo, 'bin', 'dashboard' );
my $of_bin = File::Spec->catfile( $repo, 'bin', 'of' );
my $open_file_bin = File::Spec->catfile( $repo, 'bin', 'open-file' );
my $pjq_bin = File::Spec->catfile( $repo, 'bin', 'pjq' );
my $pyq_bin = File::Spec->catfile( $repo, 'bin', 'pyq' );
my $ptomq_bin = File::Spec->catfile( $repo, 'bin', 'ptomq' );
my $pjp_bin = File::Spec->catfile( $repo, 'bin', 'pjp' );

my $init = _run("$perl -I'$lib' '$dashboard' init");
like($init, qr/runtime_root/, 'dashboard init works');
my $global_config_file = File::Spec->catfile( $ENV{HOME}, '.developer-dashboard', 'config', 'config.json' );
open my $seeded_config_fh, '>', $global_config_file or die "Unable to write $global_config_file: $!";
print {$seeded_config_fh} <<'JSON';
{
   "collectors" : [
      {
         "name" : "example.collector",
         "command" : "printf 'example collector output\\n'",
         "cwd" : "home",
         "interval" : 60
      },
      {
         "name" : "vpn",
         "code" : "return 0;",
         "cwd" : "home",
         "indicator" : {
            "icon" : "🔑"
         }
      },
      {
         "name" : "docker.collector",
         "command" : "docker ps",
         "cwd" : "home",
         "indicator" : {
            "icon" : "🐳"
         }
      }
   ]
}
JSON
close $seeded_config_fh;

my $pages = _run("$perl -I'$lib' '$dashboard' page list");
like($pages, qr/welcome/, 'welcome page listed');
like($pages, qr/api-dashboard/, 'dashboard init seeds the API dashboard bookmark');
like($pages, qr/db-dashboard/, 'dashboard init seeds the DB dashboard bookmark');
my $api_page_source = _run("$perl -I'$lib' '$dashboard' page source api-dashboard");
like($api_page_source, qr/^TITLE:\s+API Dashboard/m, 'api-dashboard source is available as a saved bookmark');
unlike($api_page_source, qr/companies house|username=|password=|dsn=/i, 'api-dashboard bookmark source stays free of legacy sensitive details');
my $db_page_source = _run("$perl -I'$lib' '$dashboard' page source db-dashboard");
like($db_page_source, qr/^TITLE:\s+DB Dashboard/m, 'db-dashboard source is available as a saved bookmark');
unlike($db_page_source, qr/companies house|username=|password=|dsn=/i, 'db-dashboard bookmark source stays free of legacy sensitive details');

my $page_source = _run("$perl -I'$lib' '$dashboard' page source welcome");
like($page_source, qr/^BOOKMARK:\s+welcome/m, 'page source prefers saved page ids over token decoding');

my $collector = _run("$perl -I'$lib' '$dashboard' collector run example.collector");
like($collector, qr/example collector output/, 'collector run works');

my $auth_add = _run("$perl -I'$lib' '$dashboard' auth add-user helper helper-pass-123");
like($auth_add, qr/"username"\s*:\s*"helper"/, 'auth add-user works');

my $auth_list = _run("$perl -I'$lib' '$dashboard' auth list-users");
like($auth_list, qr/"username"\s*:\s*"helper"/, 'auth list-users works');

my $indicator_refresh = _run("$perl -I'$lib' '$dashboard' indicator refresh-core");
like($indicator_refresh, qr/docker|project|git/, 'indicator refresh-core works');

my $ps1 = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1");
like($ps1, qr/\(1 jobs\)|developer-dashboard:master| D /, 'ps1 command works');
like($ps1, qr/🚨🔑/, 'ps1 seeds configured collector indicators before their first run');
like($ps1, qr/🚨🐳/, 'ps1 shows all configured collector indicators, not just previously-run collectors');
my $ps1_extended = _run("$perl -I'$lib' '$dashboard' ps1 --jobs 1 --mode extended --color");
like($ps1_extended, qr/\e\[|\(1 jobs\)/, 'ps1 supports extended/color modes');

my $collector_inspect = _run("$perl -I'$lib' '$dashboard' collector inspect example.collector");
like($collector_inspect, qr/"job"|"status"/, 'collector inspect works');

my ( $usage_stdout, $usage_stderr, $usage_exit ) = capture {
    system $perl, '-I' . $lib, $dashboard;
    return $? >> 8;
};
is( $usage_exit, 1, 'dashboard with no arguments exits with usage status' );
like( $usage_stdout . $usage_stderr, qr/SYNOPSIS|dashboard init/, 'dashboard with no arguments renders POD-backed usage' );

my $help = _run("$perl -I'$lib' '$dashboard' help");
like($help, qr/Description:/, 'dashboard help renders the fuller POD help');

my $bookmarks_root = _run("$perl -I'$lib' '$dashboard' path resolve bookmarks_root");
is( $bookmarks_root, File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'dashboards' ) . "\n", 'dashboard path resolve supports bookmarks_root alias' );
my $custom_path_root = File::Spec->catdir( $ENV{HOME}, 'custom-path-root' );
make_path($custom_path_root);
my $path_add = _run("$perl -I'$lib' '$dashboard' path add foobar '$custom_path_root'");
like( $path_add, qr/"name"\s*:\s*"foobar"/, 'dashboard path add stores a custom alias' );
like( $path_add, qr/\Q$custom_path_root\E/, 'dashboard path add reports the stored target path' );
open my $global_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
my $global_config = do { local $/; <$global_config_fh> };
close $global_config_fh;
like( $global_config, qr/"foobar"\s*:\s*"\$HOME\/custom-path-root"/, 'dashboard path add stores home-relative aliases using $HOME in global config' );
my $path_add_again = _run("$perl -I'$lib' '$dashboard' path add foobar '$custom_path_root'");
like( $path_add_again, qr/"name"\s*:\s*"foobar"/, 'dashboard path add is idempotent when the alias already exists' );
my $foobar_resolved = _run("$perl -I'$lib' '$dashboard' path resolve foobar");
is( $foobar_resolved, $custom_path_root . "\n", 'dashboard path resolve supports user-defined aliases' );
my $path_list = _run("$perl -I'$lib' '$dashboard' path list");
like( $path_list, qr/"foobar"\s*:\s*"\Q$custom_path_root\E"/, 'dashboard path list includes user-defined aliases' );

my $shell_bootstrap = _run("$perl -I'$lib' '$dashboard' shell bash");
like( $shell_bootstrap, qr/path resolve \"\$1\"/, 'dashboard shell bootstrap resolves named path aliases before project search' );
my $shell_bootstrap_file = File::Spec->catfile( $ENV{HOME}, 'dashboard-shell.sh' );
open my $shell_bootstrap_fh, '>', $shell_bootstrap_file or die "Unable to write $shell_bootstrap_file: $!";
print {$shell_bootstrap_fh} $shell_bootstrap;
close $shell_bootstrap_fh;
my $which_dir_bookmarks = _run("bash -lc '. \"$shell_bootstrap_file\"; which_dir bookmarks_root'");
is( $which_dir_bookmarks, $bookmarks_root, 'which_dir resolves bookmarks_root through the shell helper' );
my $cdr_bookmarks = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr bookmarks_root; pwd'");
is( $cdr_bookmarks, $bookmarks_root, 'cdr navigates to bookmarks_root through the shell helper' );
my $cdr_foobar = _run("bash -lc '. \"$shell_bootstrap_file\"; cdr foobar; pwd'");
is( $cdr_foobar, $custom_path_root . "\n", 'cdr navigates to a user-defined alias through the shell helper' );
my $path_del = _run("$perl -I'$lib' '$dashboard' path del foobar");
like( $path_del, qr/"name"\s*:\s*"foobar"/, 'dashboard path del reports the removed alias' );
like( $path_del, qr/"removed"\s*:\s*1/, 'dashboard path del removes existing aliases' );
my $path_del_again = _run("$perl -I'$lib' '$dashboard' path del foobar");
like( $path_del_again, qr/"removed"\s*:\s*0/, 'dashboard path del is idempotent for missing aliases' );

my $docker_green_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'config', 'docker', 'green' );
make_path($docker_green_root);
open my $docker_green_fh, '>', File::Spec->catfile( $docker_green_root, 'development.compose.yml' )
  or die "Unable to write docker green development compose file: $!";
print {$docker_green_fh} "services:\n  green:\n    image: alpine\n";
close $docker_green_fh;
my $docker_dry_run = _run("$perl -I'$lib' '$dashboard' docker compose --dry-run up -d --build green");
my $docker_dry_run_data = json_decode($docker_dry_run);
ok( grep( { $_ eq '-d' } @{ $docker_dry_run_data->{command} } ), 'dashboard docker compose leaves short docker passthrough flags such as -d untouched' );
ok( grep( { $_ eq '--build' } @{ $docker_dry_run_data->{command} } ), 'dashboard docker compose leaves docker passthrough flags such as --build untouched' );
ok( grep( { $_ eq 'green' } @{ $docker_dry_run_data->{services} } ), 'dashboard docker compose still infers service names from passthrough args when docker flags are present' );
my $fake_bin = File::Spec->catdir( $ENV{HOME}, 'fake-bin' );
make_path($fake_bin);
my $fake_docker = File::Spec->catfile( $fake_bin, 'docker' );
open my $fake_docker_fh, '>', $fake_docker or die "Unable to write $fake_docker: $!";
print {$fake_docker_fh} <<'SH';
#!/bin/sh
printf 'DOCKER:%s\n' "$*"
SH
close $fake_docker_fh;
chmod 0755, $fake_docker or die "Unable to chmod $fake_docker: $!";
my $docker_exec_output = _run("PATH='$fake_bin':\"\$PATH\" $perl -I'$lib' '$dashboard' docker compose up -d --build green");
like( $docker_exec_output, qr/^DOCKER:compose /m, 'dashboard docker compose execs the real docker command for non-dry-run invocations' );
unlike( $docker_exec_output, qr/\"command\"\s*:/, 'dashboard docker compose no longer prints JSON envelopes for non-dry-run invocations' );

my $open_root = File::Spec->catdir( $ENV{HOME}, 'open-file-fixtures' );
make_path($open_root);
my $open_target = File::Spec->catfile( $open_root, 'alpha-notes.txt' );
open my $open_fh, '>', $open_target or die "Unable to write $open_target: $!";
print {$open_fh} "alpha\n";
close $open_fh;

my $open_print = _run("$perl -I'$lib' '$dashboard' open-file --print '$open_root' alpha");
like($open_print, qr/\Q$open_target\E/, 'dashboard open-file prints matching files');

my $of_print = _run("$perl -I'$lib' '$dashboard' of --print '$open_root' alpha");
like($of_print, qr/\Q$open_target\E/, 'dashboard of is shorthand for open-file');

my $standalone_of_print = _run("$perl -I'$lib' '$of_bin' --print '$open_root' alpha");
is( $standalone_of_print, $of_print, 'standalone of matches dashboard of output' );

my $standalone_open_file = _run("$perl -I'$lib' '$open_file_bin' --print '$open_root' alpha");
is( $standalone_open_file, $open_print, 'standalone open-file matches dashboard open-file output' );

my $perl_root = File::Spec->catdir( $open_root, 'lib', 'My' );
make_path($perl_root);
my $perl_target = File::Spec->catfile( $perl_root, 'App.pm' );
open my $perl_fh, '>', $perl_target or die "Unable to write $perl_target: $!";
print {$perl_fh} "package My::App;\n1;\n";
close $perl_fh;
local $ENV{PERL5LIB} = join ':', grep { defined && $_ ne '' } File::Spec->catdir( $open_root, 'lib' ), $ENV{PERL5LIB};
my $perl_module = _run("$perl -I'$lib' '$dashboard' open-file --print My::App");
like($perl_module, qr/\Q$perl_target\E/, 'dashboard open-file resolves Perl module names');

my $java_root = File::Spec->catdir( $open_root, 'src', 'com', 'example' );
make_path($java_root);
my $java_target = File::Spec->catfile( $java_root, 'App.java' );
open my $java_fh, '>', $java_target or die "Unable to write $java_target: $!";
print {$java_fh} "package com.example;\nclass App {}\n";
close $java_fh;
my $java_class = _run("cd '$open_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' open-file --print com.example.App");
like($java_class, qr/\Q$java_target\E/, 'dashboard open-file resolves Java class names');

my $json_value = _run(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' pjq alpha.beta});
is( $json_value, "2\n", 'pjq extracts scalar JSON values' );
my $json_file = File::Spec->catfile( $open_root, 'sample.json' );
open my $json_fh, '>', $json_file or die "Unable to write $json_file: $!";
print {$json_fh} qq|{"alpha":{"beta":2}}|;
close $json_fh;
my $json_root = _run("$perl -I'$lib' '$dashboard' pjq '\$d' '$json_file'");
is_deeply( json_decode($json_root), { alpha => { beta => 2 } }, 'pjq accepts file then root query with order-independent args' );
my $json_root_stdin = _run("cat '$json_file' | $perl -I'$lib' '$dashboard' pjq '\$d'");
is( $json_root_stdin, $json_root, 'pjq returns the same whole-document result from stdin and file input' );
my $json_direct = _run(qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$pjq_bin' alpha.beta});
is( $json_direct, $json_value, 'standalone pjq matches dashboard pjq output' );

my $yaml_value = _run(qq{printf 'alpha:\\n  beta: 3\\n' | $perl -I'$lib' '$dashboard' pyq alpha.beta});
is( $yaml_value, "3\n", 'pyq extracts scalar YAML values' );
my $yaml_file = File::Spec->catfile( $open_root, 'sample.yaml' );
open my $yaml_fh, '>', $yaml_file or die "Unable to write $yaml_file: $!";
print {$yaml_fh} "alpha:\n  beta: 3\n";
close $yaml_fh;
my $yaml_root = _run("$perl -I'$lib' '$dashboard' pyq '$yaml_file' '\$d'");
is_deeply( json_decode($yaml_root), { alpha => { beta => '3' } }, 'pyq accepts file then root query with order-independent args' );
my $yaml_root_stdin = _run("cat '$yaml_file' | $perl -I'$lib' '$dashboard' pyq '\$d'");
is( $yaml_root_stdin, $yaml_root, 'pyq returns the same whole-document result from stdin and file input' );
my $yaml_direct = _run(qq{printf 'alpha:\\n  beta: 3\\n' | $perl -I'$lib' '$pyq_bin' alpha.beta});
is( $yaml_direct, $yaml_value, 'standalone pyq matches dashboard pyq output' );

my $pjq_hook_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli', 'pjq.d' );
make_path($pjq_hook_root);
my $pjq_hook_one = File::Spec->catfile( $pjq_hook_root, '00-first.pl' );
open my $pjq_hook_one_fh, '>', $pjq_hook_one or die "Unable to write $pjq_hook_one: $!";
print {$pjq_hook_one_fh} <<'PL';
#!/usr/bin/env perl
print "hook-one\n";
warn "hook-one-err\n";
PL
close $pjq_hook_one_fh;
chmod 0755, $pjq_hook_one or die "Unable to chmod $pjq_hook_one: $!";
my $pjq_hook_two = File::Spec->catfile( $pjq_hook_root, '01-second.pl' );
my $pjq_hook_result = File::Spec->catfile( $ENV{HOME}, 'pjq-hook-result.txt' );
open my $pjq_hook_two_fh, '>', $pjq_hook_two or die "Unable to write $pjq_hook_two: $!";
print {$pjq_hook_two_fh} <<"PL";
#!/usr/bin/env perl
use strict;
use warnings;
use lib '$repo/lib';
use Runtime::Result;
open my \$fh, '>', '$pjq_hook_result' or die \$!;
print {\$fh} Runtime::Result::stdout('00-first.pl');
close \$fh;
print "hook-two\n";
warn "hook-two-err\n";
PL
close $pjq_hook_two_fh;
chmod 0755, $pjq_hook_two or die "Unable to chmod $pjq_hook_two: $!";
my $pjq_hook_skipped = File::Spec->catfile( $pjq_hook_root, 'data.file' );
open my $pjq_hook_skipped_fh, '>', $pjq_hook_skipped or die "Unable to write $pjq_hook_skipped: $!";
print {$pjq_hook_skipped_fh} "skip\n";
close $pjq_hook_skipped_fh;
chmod 0600, $pjq_hook_skipped or die "Unable to chmod $pjq_hook_skipped: $!";
my ( $pjq_hooked_stdout, $pjq_hooked_stderr, $pjq_hooked_exit ) = capture {
    system 'sh', '-c', qq{printf '{"alpha":{"beta":2}}' | $perl -I'$lib' '$dashboard' pjq alpha.beta};
    return $? >> 8;
};
is( $pjq_hooked_exit, 0, 'dashboard pjq succeeds when command hook files exist' );
like( $pjq_hooked_stdout, qr/^hook-one\n/s, 'dashboard pjq streams hook stdout before the main command output' );
like( $pjq_hooked_stdout, qr/hook-two\n2\n\z/s, 'dashboard pjq keeps the main command output after streamed hook stdout' );
like( $pjq_hooked_stderr, qr/hook-one-err\n/, 'dashboard pjq streams hook stderr live' );
like( $pjq_hooked_stderr, qr/hook-two-err\n/, 'dashboard pjq keeps later hook stderr visible' );
open my $pjq_hook_result_fh, '<', $pjq_hook_result or die "Unable to read $pjq_hook_result: $!";
is( do { local $/; <$pjq_hook_result_fh> }, "hook-one\n", 'later built-in command hooks can read the accumulated RESULT JSON from earlier hook output' );
close $pjq_hook_result_fh;

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
is_deeply( Runtime::Result::current(), json_decode( $ENV{RESULT} ), 'Runtime::Result decodes RESULT into a hash' );
is_deeply( [ Runtime::Result::names() ], [ '00-first.pl', '01-second.pl' ], 'Runtime::Result lists stored hook names in sorted order' );
ok( Runtime::Result::has('00-first.pl'), 'Runtime::Result detects known hook names' );
ok( !Runtime::Result::has('99-missing.pl'), 'Runtime::Result rejects missing hook names' );
is( Runtime::Result::stdout('00-first.pl'), "hook-one\n", 'Runtime::Result returns stored hook stdout' );
is( Runtime::Result::stderr('01-second.pl'), "hook-two-err\n", 'Runtime::Result returns stored hook stderr' );
is( Runtime::Result::exit_code('01-second.pl'), 0, 'Runtime::Result returns stored hook exit codes' );
is( Runtime::Result::last_name(), '01-second.pl', 'Runtime::Result returns the last sorted hook name' );
is_deeply( Runtime::Result::last_entry(), json_decode( $ENV{RESULT} )->{'01-second.pl'}, 'Runtime::Result returns the last sorted hook entry' );
local $ENV{RESULT} = '{';
my $invalid_json_error = do {
    local $@;
    eval { Runtime::Result::current() };
    $@;
};
like( $invalid_json_error, qr/at character offset|malformed JSON string/i, 'Runtime::Result surfaces invalid RESULT json decoding errors' );
local $ENV{RESULT} = json_encode( [ 1, 2, 3 ] );
my $non_hash_error = do {
    local $@;
    eval { Runtime::Result::current() };
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
my ( $custom_stdout, $custom_stderr, $custom_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' inspect-result";
    return $? >> 8;
};
is( $custom_exit, 0, 'directory-backed custom command succeeds after hook streaming' );
like( $custom_stdout, qr/^custom-hook\n/s, 'directory-backed custom command streams hook stdout before the final RESULT json' );
like( $custom_stderr, qr/custom-hook-err\n/, 'directory-backed custom command streams hook stderr live' );
my ($custom_json) = $custom_stdout =~ /(\{[\s\S]*\})\s*\z/;
ok( defined $custom_json, 'directory-backed custom command leaves trailing RESULT json after streamed hook output' );
my $custom_result_data = json_decode($custom_json);
is( $custom_result_data->{'00-pre.pl'}{stdout}, "custom-hook\n", 'directory-backed custom commands receive RESULT JSON from their hook files' );
like( $custom_result_data->{'00-pre.pl'}{stderr}, qr/custom-hook-err/, 'directory-backed custom command RESULT keeps captured hook stderr' );

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
my ( $update_stdout, $update_stderr, $update_exit ) = capture {
    system 'sh', '-c', "$perl -I'$lib' '$dashboard' update";
    return $? >> 8;
};
is( $update_exit, 0, 'dashboard update custom command succeeds' );
like( $update_stdout, qr/^Test/s, 'dashboard update custom command streams hook stdout before returning RESULT json' );
like( $update_stderr, qr/warned/, 'dashboard update streams hook stderr live' );
my ($update_json) = $update_stdout =~ /(\{[\s\S]*\})\s*\z/;
ok( defined $update_json, 'dashboard update custom command leaves trailing RESULT json after streamed hook output' );
my $update_result_data = json_decode($update_json);
is( $update_result_data->{'01-cpan'}{stdout}, 'Test', 'dashboard update custom command receives stdout from executable update hook files' );
like( $update_result_data->{'01-cpan'}{stderr}, qr/warned/, 'dashboard update custom command receives stderr from executable update hook files' );
ok( !exists $update_result_data->{'data.file'}, 'dashboard update custom command skips non-executable files in the update hook folder' );
is( _run("$perl -I'$lib' '$dashboard' version"), "0.94\n", 'dashboard version prints the installed dashboard version' );

my $toml_value = _run(qq{printf '[alpha]\\nbeta = 4\\n' | $perl -I'$lib' '$dashboard' ptomq alpha.beta});
is( $toml_value, "4\n", 'ptomq extracts scalar TOML values' );
my $toml_file = File::Spec->catfile( $open_root, 'sample.toml' );
open my $toml_fh, '>', $toml_file or die "Unable to write $toml_file: $!";
print {$toml_fh} "[alpha]\nbeta = 4\n";
close $toml_fh;
my $toml_root = _run("$perl -I'$lib' '$dashboard' ptomq '\$d' '$toml_file'");
is_deeply( json_decode($toml_root), { alpha => { beta => 4 } }, 'ptomq accepts file then root query with order-independent args' );
my $toml_root_stdin = _run("cat '$toml_file' | $perl -I'$lib' '$dashboard' ptomq '\$d'");
is( $toml_root_stdin, $toml_root, 'ptomq returns the same whole-document result from stdin and file input' );
my $toml_direct = _run(qq{printf '[alpha]\\nbeta = 4\\n' | $perl -I'$lib' '$ptomq_bin' alpha.beta});
is( $toml_direct, $toml_value, 'standalone ptomq matches dashboard ptomq output' );

my $props_value = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$dashboard' pjp alpha.beta});
is( $props_value, "5\n", 'pjp extracts scalar Java properties values' );
my $props_file = File::Spec->catfile( $open_root, 'sample.properties' );
open my $props_fh, '>', $props_file or die "Unable to write $props_file: $!";
print {$props_fh} "alpha.beta=5\nname = demo\n";
close $props_fh;
my $props_root = _run("$perl -I'$lib' '$dashboard' pjp '$props_file' '\$d'");
is_deeply( json_decode($props_root), { 'alpha.beta' => '5', name => 'demo' }, 'pjp accepts file then root query with order-independent args' );
my $props_root_stdin = _run("cat '$props_file' | $perl -I'$lib' '$dashboard' pjp '\$d'");
is( $props_root_stdin, $props_root, 'pjp returns the same whole-document result from stdin and file input' );
my $props_direct = _run(qq{printf 'alpha.beta=5\\nname = demo\\n' | $perl -I'$lib' '$pjp_bin' alpha.beta});
is( $props_direct, $props_value, 'standalone pjp matches dashboard pjp output' );

my $cli_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'cli' );
make_path($cli_root);
my $ext = File::Spec->catfile( $cli_root, 'foobar' );
open my $ext_fh, '>', $ext or die "Unable to write $ext: $!";
print {$ext_fh} <<'SH';
#!/bin/sh
input="$(cat)"
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
open my $home_hook_fh, '>', File::Spec->catfile( $cli_root, 'pjq.d', '02-home-only.pl' )
  or die "Unable to write home fallback hook: $!";
print {$home_hook_fh} <<'PL';
#!/usr/bin/env perl
print "home-hook\n";
PL
close $home_hook_fh;
chmod 0755, File::Spec->catfile( $cli_root, 'pjq.d', '02-home-only.pl' )
  or die "Unable to chmod home fallback hook: $!";
my $project_tool_hook_root = File::Spec->catdir( $project_cli_root, 'tool.d' );
make_path($project_tool_hook_root);
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

my ( $project_command_stdout, undef, $project_command_exit ) = capture {
    system 'sh', '-c', "cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' foobar one two";
    return $? >> 8;
};
is( $project_command_exit, 0, 'project-local custom command exits successfully' );
like( $project_command_stdout, qr/^project-command:one two$/m, 'project-local custom command overrides the home CLI command when a local dashboard root exists' );

my ( $project_hook_stdout, $project_hook_stderr, $project_hook_exit ) = capture {
    system 'sh', '-c', "cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' tool";
    return $? >> 8;
};
is( $project_hook_exit, 0, 'project-local hook-backed command exits successfully' );
like( $project_hook_stdout, qr/project-hook/, 'project-local hook directories run before the final command' );
unlike( $project_hook_stdout, qr/home-hook/, 'project-local hook directories override home hook directories instead of merging them' );
like( $project_hook_stdout, qr/00-project-first\.pl/, 'project-local hook results are propagated into RESULT for the final command' );
is( $project_hook_stderr, '', 'project-local hook-backed command keeps stderr clean' );

my $project_local_bookmarks = File::Spec->catdir( $project_root, '.developer-dashboard', 'dashboards' );
make_path($project_local_bookmarks);
my $project_local_paths = _run("cd '$project_root' && $perl -I'$repo/lib' '$repo/bin/dashboard' paths");
like( $project_local_paths, qr/"runtime_root"\s*:\s*"\Q$project_root\/.developer-dashboard\E"/, 'dashboard paths reports the project-local runtime root when present' );
like( $project_local_paths, qr/"dashboards_root"\s*:\s*"\Q$project_local_bookmarks\E"/, 'dashboard paths reports the project-local dashboards root when present' );

done_testing;

sub _run {
    my ($cmd) = @_;
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'sh', '-c', $cmd;
        return $? >> 8;
    };
    is( $exit_code, 0, "command succeeded: $cmd" );
    return $stdout . $stderr;
}

__END__

=head1 NAME

05-cli-smoke.t - CLI smoke tests for dashboard

=head1 DESCRIPTION

This test verifies the main command-line entrypoints for Developer Dashboard.

=cut
