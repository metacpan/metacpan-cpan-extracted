#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::XS qw(decode_json);
use Developer::Dashboard::Runtime::Result;
use Test::More;

use lib 'lib';
use Developer::Dashboard::Config;
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $repo_root = getcwd();
my $repo_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $test_cwd = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";
my $test_repos = tempdir( CLEANUP => 1 );
my $fake_bin = tempdir( CLEANUP => 1 );
my $cpanm_log = File::Spec->catfile( $fake_bin, 'cpanm.log' );
my $apt_log = File::Spec->catfile( $fake_bin, 'apt.log' );
my $apk_log = File::Spec->catfile( $fake_bin, 'apk.log' );
my $dnf_log = File::Spec->catfile( $fake_bin, 'dnf.log' );
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
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'dnf' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$dnf_log"
printf 'DNF:%s\\n' "\$*" >> "$dependency_log"
exit 0
SH
    0755,
);
_write_file(
    File::Spec->catfile( $fake_bin, 'rpm' ),
    <<'SH',
#!/bin/sh
if [ "$1" = "-q" ] && [ "$2" = "--quiet" ]; then
  case ",${DD_TEST_DNF_INSTALLED:-}," in
    *,"$3",*) exit 0 ;;
  esac
  exit 1
fi
exit 1
SH
    0755,
);
local $ENV{PATH} = join ':', $fake_bin, ( $ENV{PATH} || () );

sub _portable_path {
    my ($path) = @_;
    return undef if !defined $path;
    my $resolved = eval { abs_path($path) };
    return defined $resolved && $resolved ne '' ? $resolved : $path;
}

my $paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );
my $dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $paths );

my $alpha_repo = _create_skill_repo(
    'alpha-skill',
    command_body => <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print join('|', @ARGV), "\n";
PL
    hook_body => <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "hook-alpha\n";
PL
    ddfile_body => "dep-alpha\n",
    ddfile_local_body => "dep-beta\n",
    aptfile_body => "git\ncurl\n",
    apkfile_body => "procps-dev\n",
    dnfile_body => "git-core\njq\n",
    brewfile_body => "jq\n",
    package_json_body => qq|{"name":"alpha-skill-node","version":"0.01.0","dependencies":{"express":"^4.19.2","uuid":"^11.0.0"},"devDependencies":{"playwright":"^1.52.0"}}\n|,
    cpanfile_local_body => "requires 'YAML::XS';\n",
    bookmark_body => <<'BOOKMARK',
TITLE: Skill Bookmark
:--------------------------------------------------------------------------------:
BOOKMARK: welcome
:--------------------------------------------------------------------------------:
HTML:
Skill bookmark body
BOOKMARK
);

my $install = $manager->install( 'file://' . $alpha_repo );
ok( !$install->{error}, 'skill installs from a git url' ) or diag $install->{error};
is( $install->{repo_name}, 'alpha-skill', 'install returns the repo-derived skill name' );
ok( -d File::Spec->catdir( $install->{path}, 'cli' ), 'install prepares isolated cli root' );
ok( -d File::Spec->catdir( $install->{path}, 'config', 'docker' ), 'install prepares isolated docker config root' );
ok( -d File::Spec->catdir( $install->{path}, 'state' ), 'install prepares isolated state root' );
ok( -d File::Spec->catdir( $install->{path}, 'logs' ), 'install prepares isolated logs root' );
ok( -d File::Spec->catdir( $install->{path}, 'local' ), 'install prepares isolated local dependency root' );
ok( -d File::Spec->catdir( $ENV{HOME}, 'perl5' ), 'install prepares the shared perl dependency root under HOME' );
ok( -f File::Spec->catfile( $install->{path}, 'config', 'config.json' ), 'install ensures isolated skill config exists' );
ok( -f File::Spec->catfile( $install->{path}, 'cpanfile' ), 'test skill includes cpanfile for dependency handling' );
ok( -f File::Spec->catfile( $install->{path}, 'aptfile' ), 'test skill includes aptfile for dependency handling' );
ok( -f File::Spec->catfile( $install->{path}, 'apkfile' ), 'test skill includes apkfile for dependency handling' );
ok( -f File::Spec->catfile( $install->{path}, 'dnfile' ), 'test skill includes dnfile for dependency handling' );
ok( -f File::Spec->catfile( $install->{path}, 'brewfile' ), 'test skill includes brewfile for dependency handling' );
ok( -f File::Spec->catfile( $install->{path}, 'cpanfile.local' ), 'test skill includes cpanfile.local for local dependency handling' );
ok( -f $apt_log, 'install runs apt-get for isolated skill apt dependencies when an aptfile is present' );
ok( -f $cpanm_log, 'install runs cpanm for isolated skill dependencies when a cpanfile is present' );
is_deeply(
    [ $paths->installed_skill_docker_roots ],
    [ File::Spec->catdir( $install->{path}, 'config', 'docker' ) ],
    'installed_skill_docker_roots lists the docker config root for enabled installed skills',
);
open my $dependency_log_fh, '<', $dependency_log or die "Unable to read $dependency_log: $!";
my @dependency_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$dependency_log_fh>;
close $dependency_log_fh;
is_deeply(
    [ map { (/^(DDFILE_LOCAL|DDFILE|APT|BREW|NPM|CPANM):/)[0] } @dependency_steps ],
    [ 'APT', 'NPM', 'CPANM', 'CPANM', 'DDFILE', 'DDFILE_LOCAL' ],
    'skill install processes aptfile, package.json, cpanfile, cpanfile.local, ddfile, and ddfile.local in policy order on Debian-like hosts while leaving apkfile and brewfile inactive',
);
open my $cpanm_log_fh, '<', $cpanm_log or die "Unable to read $cpanm_log: $!";
my @cpanm_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$cpanm_log_fh>;
close $cpanm_log_fh;
like( $cpanm_steps[0], qr/^--notest -L \Q$ENV{HOME}\/perl5\E --cpanfile \Q$install->{path}\/cpanfile\E --installdeps \Q$install->{path}\E$/, 'cpanfile installs shared Perl dependencies into HOME perl5 with cpanm --notest' );
is( $cpanm_steps[1], "--notest -L $install->{path}/perl5 --cpanfile $install->{path}/cpanfile.local --installdeps $install->{path}", 'cpanfile.local installs local Perl dependencies into the skill perl5 root with cpanm --notest' );
open my $npx_log_fh, '<', $npx_log or die "Unable to read $npx_log: $!";
my @npm_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$npx_log_fh>;
close $npx_log_fh;
like(
    $npm_steps[0],
    qr/^--yes npm install express\@\^4\.19\.2 uuid\@\^11\.0\.0 playwright\@\^1\.52\.0\|cwd=\Q$ENV{HOME}\E\/\.developer-dashboard\/cache\/node-package-installs\/npm-install-/,
    'package.json installs declared Node dependencies through npx from a private staging workspace instead of using bare HOME as the npm project root',
);
ok( -d File::Spec->catdir( $ENV{HOME}, 'node_modules', 'express' ), 'package.json merges staged Node dependencies into HOME/node_modules' );
ok( -d File::Spec->catdir( $ENV{HOME}, 'node_modules', 'uuid' ), 'package.json merges additional staged Node dependencies into HOME/node_modules' );
ok( -d File::Spec->catdir( $ENV{HOME}, 'node_modules', 'playwright' ), 'package.json merges staged Playwright dependencies into HOME/node_modules' );
open my $dashboard_log_fh, '<', $dashboard_log or die "Unable to read $dashboard_log: $!";
my @dashboard_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$dashboard_log_fh>;
close $dashboard_log_fh;
is( $dashboard_steps[0], 'skills install dep-alpha', 'deferred ddfile installs dependent skills through dashboard skills install' );
is( $dashboard_steps[1], 'skills install dep-beta', 'deferred ddfile.local installs dependent skills through dashboard skills install at the current skill level' );
{
    local $ENV{DD_TEST_OS} = 'linux';
    local $ENV{DD_TEST_FEDORA} = 1;
    local $ENV{DD_TEST_DNF_INSTALLED} = 'git-core,jq';
    unlink $dnf_log;
    my $skip_dnf = $manager->_install_skill_dnfile( $install->{path} );
    ok( !$skip_dnf->{error}, '_install_skill_dnfile succeeds when every Fedora package is already installed' )
      or diag $skip_dnf->{error};
    ok( $skip_dnf->{skipped}, '_install_skill_dnfile reports a skip when every Fedora package is already installed' );
    is( $skip_dnf->{skip_reason}, 'all dnfile packages already installed', '_install_skill_dnfile returns an explicit skip reason for fully installed Fedora package manifests' );
    ok( !-f $dnf_log, '_install_skill_dnfile does not invoke dnf when every Fedora package is already installed' );
}
{
    local $ENV{DD_TEST_OS} = 'linux';
    local $ENV{DD_TEST_FEDORA} = 1;
    local $ENV{DD_TEST_DNF_INSTALLED} = 'git-core';
    unlink $dnf_log;
    my $root_dnf = $manager->_install_skill_dnfile( $install->{path} );
    ok( !$root_dnf->{error}, '_install_skill_dnfile succeeds on Fedora hosts when a dnfile is present and packages are missing' )
      or diag $root_dnf->{error};
    open my $root_dnf_fh, '<', $dnf_log or die "Unable to read $dnf_log: $!";
    my @root_dnf_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$root_dnf_fh>;
    close $root_dnf_fh;
    is( $root_dnf_steps[0], 'install -y jq', '_install_skill_dnfile calls dnf install -y with only the missing Fedora packages' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_skill_package_runner_prefix = sub { return (); };
    local $ENV{DD_TEST_APT_INSTALLED} = 'git';
    unlink $apt_log;
    unlink $sudo_log;
    my $root_apt = $manager->_install_skill_aptfile( $install->{path} );
    ok( !$root_apt->{error}, '_install_skill_aptfile succeeds without sudo when package installs already run as root' )
      or diag $root_apt->{error};
    open my $root_apt_fh, '<', $apt_log or die "Unable to read $apt_log: $!";
    my @root_apt_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$root_apt_fh>;
    close $root_apt_fh;
    is( $root_apt_steps[0], 'install -y curl', '_install_skill_aptfile only installs Debian packages that are still missing' );
    my $sudo_text = '';
    if ( -f $sudo_log ) {
        open my $sudo_fh, '<', $sudo_log or die "Unable to read $sudo_log: $!";
        $sudo_text = do { local $/; <$sudo_fh> };
        close $sudo_fh;
    }
    ok( $sudo_text eq '', '_install_skill_aptfile does not invoke sudo when package installs already run as root' );
}
{
    local $ENV{DD_TEST_APT_INSTALLED} = 'git,curl';
    unlink $apt_log;
    unlink $sudo_log;
    my $skip_apt = $manager->_install_skill_aptfile( $install->{path} );
    ok( !$skip_apt->{error}, '_install_skill_aptfile succeeds when every Debian package is already installed' )
      or diag $skip_apt->{error};
    ok( $skip_apt->{skipped}, '_install_skill_aptfile reports a skip when every Debian package is already installed' );
    is( $skip_apt->{skip_reason}, 'all aptfile packages already installed', '_install_skill_aptfile returns an explicit skip reason for fully installed Debian package manifests' );
    ok( !-f $apt_log, '_install_skill_aptfile does not invoke apt-get when every Debian package is already installed' );
    ok( !-f $sudo_log, '_install_skill_aptfile does not invoke sudo when every Debian package is already installed' );
}
{
    local $ENV{DD_TEST_ALPINE} = 1;
    local $ENV{DD_TEST_APK_INSTALLED} = 'procps-dev';
    unlink $apk_log;
    my $root_apk = $manager->_install_skill_apkfile( $install->{path} );
    ok( !$root_apk->{error}, '_install_skill_apkfile succeeds on Alpine hosts when an apkfile is present' )
      or diag $root_apk->{error};
    ok( $root_apk->{skipped}, '_install_skill_apkfile reports a skip when every Alpine package is already installed' );
    is( $root_apk->{skip_reason}, 'all apkfile packages already installed', '_install_skill_apkfile returns an explicit skip reason for fully installed Alpine package manifests' );
    ok( !-f $apk_log, '_install_skill_apkfile does not invoke apk add when every Alpine package is already installed' );
}
{
    local $ENV{DD_TEST_ALPINE} = 1;
    unlink $apk_log;
    my $root_apk = $manager->_install_skill_apkfile( $install->{path} );
    ok( !$root_apk->{error}, '_install_skill_apkfile succeeds on Alpine hosts when an apkfile is present and packages are missing' )
      or diag $root_apk->{error};
    open my $root_apk_fh, '<', $apk_log or die "Unable to read $apk_log: $!";
    my @root_apk_steps = grep { defined && $_ ne '' } map { chomp; $_ } <$root_apk_fh>;
    close $root_apk_fh;
    is( $root_apk_steps[0], 'add --no-cache procps-dev', '_install_skill_apkfile calls apk add --no-cache with only the missing Alpine packages' );
}

my $listed = $manager->list();
is( scalar(@$listed), 1, 'list returns the installed skill only once' );
is_deeply(
    $listed->[0]{cli_commands},
    ['run-test'],
    'list reports the isolated skill cli commands',
);
ok( $listed->[0]{enabled}, 'list reports installed skills as enabled by default' );
is( $listed->[0]{pages_count}, 1, 'list reports the number of non-nav skill pages' );
is( $listed->[0]{docker_services_count}, 1, 'list reports the number of skill docker services' );
is( $listed->[0]{has_ddfile}, 1, 'list reports ddfile presence for one installed skill' );
is( $listed->[0]{has_aptfile}, 1, 'list reports aptfile presence for one installed skill' );
is( $listed->[0]{has_apkfile}, 1, 'list reports apkfile presence for one installed skill' );
is( $listed->[0]{has_dnfile}, 1, 'list reports dnfile presence for one installed skill' );
is( $listed->[0]{has_brewfile}, 1, 'list reports brewfile presence for one installed skill' );
is( $listed->[0]{has_cpanfile_local}, 1, 'list reports cpanfile.local presence for one installed skill' );
ok(
    index( $listed->[0]{path}, File::Spec->catdir( $paths->skills_root, 'alpha-skill' ) ) == 0,
    'installed skill lives under the active DD-OOP-LAYER skills root',
);

my $usage = $manager->usage('alpha-skill');
ok( !$usage->{error}, 'usage returns detailed metadata for an installed skill' ) or diag $usage->{error};
is( $usage->{name}, 'alpha-skill', 'usage reports the installed repo name' );
ok( $usage->{enabled}, 'usage reports enabled status for active skills' );
ok( scalar( grep { $_->{name} eq 'run-test' && $_->{has_hooks} } @{ $usage->{cli} } ), 'usage lists cli commands together with hook presence' );
ok( scalar( grep { $_ eq 'welcome' } @{ $usage->{pages}{entries} } ), 'usage lists non-nav dashboard pages' );
ok( scalar( grep { $_->{name} eq 'postgres' } @{ $usage->{docker}{services} } ), 'usage lists docker services' );

my $dispatch = $dispatcher->dispatch( 'alpha-skill', 'run-test', 'one', 'two' );
ok( !$dispatch->{error}, 'dispatcher runs a skill command successfully' ) or diag $dispatch->{error};
like( $dispatch->{stdout}, qr/hook-alpha/, 'dispatch runs skill-local hooks before the main command' );
like( $dispatch->{stdout}, qr/one\|two/, 'dispatch preserves skill command arguments' );
ok( exists $dispatch->{hooks}{'00-pre.pl'}, 'dispatch returns captured hook metadata' );

my $config = $dispatcher->get_skill_config('alpha-skill');
is( $config->{skill_name}, 'alpha-skill', 'dispatcher reads isolated skill config' );

my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $fleet_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
$fleet_config->save_global(
    {
        collectors => [
            {
                name    => 'system.collector',
                command => q{printf 'system'},
                cwd     => 'home',
            },
        ],
    }
);
_write_file(
    File::Spec->catfile( $install->{path}, 'config', 'config.json' ),
    <<'JSON',
{
  "skill_name": "alpha-skill",
  "collectors": [
    {
      "name": "status",
      "command": "printf 'alpha-status'",
      "cwd": "home",
      "interval": 15,
      "indicator": {
        "label": "Alpha Status",
        "icon": "A"
      }
    }
  ]
}
JSON
    0644,
);
my $fleet_jobs = $fleet_config->collectors;
is_deeply(
    [ map { $_->{name} } @{$fleet_jobs} ],
    [ 'housekeeper', 'system.collector', 'alpha-skill.status' ],
    'config collector fleet includes installed skill collectors under repo-qualified names',
);
my ($skill_fleet_job) = grep { $_->{name} eq 'alpha-skill.status' } @{$fleet_jobs};
is( $skill_fleet_job->{skill_name}, 'alpha-skill', 'skill collectors carry their source skill name in fleet metadata' );
is( $skill_fleet_job->{indicator}{label}, 'Alpha Status', 'skill collector indicator config survives fleet loading' );
my $usage_with_collectors = $manager->usage('alpha-skill');
is( $usage_with_collectors->{collectors}[0]{qualified_name}, 'alpha-skill.status', 'usage reports repo-qualified collector names' );
ok( $usage_with_collectors->{collectors}[0]{has_indicator}, 'usage reports when a collector has an indicator' );

my ( $cli_install_stdout, $cli_install_stderr, $cli_install_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'list' );
};
is( $cli_install_exit >> 8, 0, 'dashboard skills list exits cleanly' );
like( $cli_install_stdout, qr/^Repo\s+Enabled\s+CLI\s+Pages\s+Docker\s+Collectors\s+Indicators/m, 'dashboard skills list defaults to table output with aligned headings' );
like( $cli_install_stdout, qr/^alpha-skill\s+enabled\s+1\s+1\s+1\s+1\s+1/m, 'dashboard skills list default table renders readable aligned values' );

my ( $cli_json_stdout, $cli_json_stderr, $cli_json_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'list', '-o', 'json' );
};
is( $cli_json_exit >> 8, 0, 'dashboard skills list -o json exits cleanly' );
my $cli_list = decode_json($cli_json_stdout);
is( scalar( @{ $cli_list->{skills} } ), 1, 'dashboard skills list -o json reports installed skills' );
ok( $cli_list->{skills}[0]{enabled}, 'dashboard skills list -o json reports enabled state in JSON output' );

my ( $cli_usage_stdout, $cli_usage_stderr, $cli_usage_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'usage', 'alpha-skill' );
};
is( $cli_usage_exit >> 8, 0, 'dashboard skills usage exits cleanly' );
my $cli_usage = decode_json($cli_usage_stdout);
is( $cli_usage->{name}, 'alpha-skill', 'dashboard skills usage returns detailed skill metadata' );
ok( scalar( grep { $_->{name} eq 'run-test' && $_->{has_hooks} } @{ $cli_usage->{cli} } ), 'dashboard skills usage includes per-command hook metadata' );

my ( $cli_table_stdout, $cli_table_stderr, $cli_table_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'list', '-o', 'table' );
};
is( $cli_table_exit >> 8, 0, 'dashboard skills list -o table exits cleanly' );
like( $cli_table_stdout, qr/Repo/i, 'table output includes a repo column heading' );
like( $cli_table_stdout, qr/alpha-skill/, 'table output includes the installed skill name' );

_append_repo_commit(
    $alpha_repo,
    File::Spec->catfile( 'cli', 'run-test' ),
    <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "updated:", join('|', @ARGV), "\n";
PL
);
my $update = $manager->update('alpha-skill');
ok( !$update->{error}, 'skill update refreshes the checkout cleanly' ) or diag $update->{error};
my $updated_dispatch = $dispatcher->dispatch( 'alpha-skill', 'run-test', 'three' );
like( $updated_dispatch->{stdout}, qr/updated:three/, 'updated skill command executes the refreshed checkout' );
_write_file(
    File::Spec->catfile( $install->{path}, 'skills', 'level1', 'skills', 'level2', 'cli', 'here' ),
    <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "deep:", join('|', @ARGV), "\n";
PL
    0755,
);
my $deep_nested_dispatch = $dispatcher->dispatch( 'alpha-skill', 'level1.level2.here', 'four' );
ok( !$deep_nested_dispatch->{error}, 'dispatcher resolves multi-level nested skill trees addressed through dotted command tails' )
  or diag $deep_nested_dispatch->{error};
like( $deep_nested_dispatch->{stdout}, qr/deep:four/, 'multi-level nested skill command executes from its deepest nested cli root' );

{
    my $env_runtime_home = tempdir( CLEANUP => 1 );
    my $previous_cwd = getcwd();
    local $ENV{HOME} = $env_runtime_home;
    my $env_project_root = File::Spec->catdir( $env_runtime_home, 'env-skill-project' );
    my $env_child_root   = File::Spec->catdir( $env_project_root, 'child' );
    make_path(
        File::Spec->catdir( $env_runtime_home, '.developer-dashboard' ),
        File::Spec->catdir( $env_project_root, '.git' ),
        File::Spec->catdir( $env_child_root, '.developer-dashboard' ),
    );
    chdir $env_child_root or die "Unable to chdir to $env_child_root: $!";
    open my $root_env_fh, '>:raw', File::Spec->catfile( $env_runtime_home, '.env' ) or die "Unable to write root .env: $!";
    print {$root_env_fh} "ROOT_SCOPE_ENV=root\nSHARED_SCOPE_ENV=runtime-home\nHOME_SCOPE_ENV=~/skill-home\n";
    close $root_env_fh or die "Unable to close root .env: $!";
    open my $child_env_fh, '>:raw', File::Spec->catfile( $env_child_root, '.env' ) or die "Unable to write child .env: $!";
    print {$child_env_fh} "CHILD_SCOPE_ENV=child\nSHARED_SCOPE_ENV=runtime-child\n";
    close $child_env_fh or die "Unable to close child .env: $!";
    open my $child_runtime_pl_fh, '>:raw', File::Spec->catfile( $env_child_root, '.developer-dashboard', '.env.pl' )
      or die "Unable to write child runtime .env.pl: $!";
    print {$child_runtime_pl_fh} "\$ENV{RUNTIME_PL_SCOPE_ENV} = 'runtime-child-pl';\n1;\n";
    close $child_runtime_pl_fh or die "Unable to close child runtime .env.pl: $!";

    my $env_paths = Developer::Dashboard::PathRegistry->new( home => $env_runtime_home );
    my $env_manager = Developer::Dashboard::SkillManager->new( paths => $env_paths );
    my $env_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $env_paths );
    my $env_skill_root = File::Spec->catdir( $env_paths->skills_root, 'env-layer-skill' );
    make_path(
        File::Spec->catdir( $env_skill_root, 'cli' ),
        File::Spec->catdir( $env_skill_root, 'config' ),
        File::Spec->catdir( $env_skill_root, 'skills', 'childscope' ),
    );
    _write_file(
        File::Spec->catfile( $env_skill_root, 'cli', 'show' ),
        <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Developer::Dashboard::EnvAudit;
print encode_json(
    {
        root       => $ENV{ROOT_SCOPE_ENV},
        child      => $ENV{CHILD_SCOPE_ENV},
        runtime_pl => $ENV{RUNTIME_PL_SCOPE_ENV},
        home_scope => $ENV{HOME_SCOPE_ENV},
        skill_only => $ENV{SKILL_ONLY_ENV},
        skill_chain => $ENV{SKILL_CHAIN_ENV},
        skill_pl_chain => $ENV{SKILL_PL_CHAIN_ENV},
        shared     => $ENV{SHARED_SCOPE_ENV},
        audit      => Developer::Dashboard::EnvAudit->key('SHARED_SCOPE_ENV'),
    }
), "\n";
PL
        0755,
    );
    _write_file(
        File::Spec->catfile( $env_skill_root, '.env' ),
        "SKILL_ONLY_ENV=home-skill\nSHARED_SCOPE_ENV=skill-home\nSKILL_CHAIN_ENV=\$SHARED_SCOPE_ENV/from-skill-env\n",
        0644,
    );
    my $env_child_skill_root = File::Spec->catdir( $env_child_root, '.developer-dashboard', 'skills', 'env-layer-skill' );
    make_path( File::Spec->catdir( $env_child_skill_root, 'config' ) );
    _write_file(
        File::Spec->catfile( $env_child_skill_root, '.env.pl' ),
        "\$ENV{SKILL_CHILD_ENV} = 'child-skill';\n\$ENV{SHARED_SCOPE_ENV} = 'skill-child';\n\$ENV{SKILL_PL_CHAIN_ENV} = \"\$ENV{SKILL_CHAIN_ENV}/from-skill-pl\";\n1;\n",
        0644,
    );

    my $env_dispatch = $env_dispatcher->dispatch('env-layer-skill', 'show');
    ok( !$env_dispatch->{error}, 'dispatcher loads layered runtime env files plus skill-local env files when one skill command runs' )
      or diag $env_dispatch->{error};
    my $env_dispatch_payload = decode_json( $env_dispatch->{stdout} );
    is( $env_dispatch_payload->{root}, 'root', 'skill dispatch inherits the home runtime env layer' );
    is( $env_dispatch_payload->{child}, 'child', 'skill dispatch inherits the child runtime env layer' );
    is( $env_dispatch_payload->{runtime_pl}, 'runtime-child-pl', 'skill dispatch inherits runtime .env.pl values before command execution' );
    is( $env_dispatch_payload->{home_scope}, File::Spec->catdir( $env_runtime_home, 'skill-home' ), 'skill dispatch inherits tilde-expanded runtime env values' );
    is( $env_dispatch_payload->{skill_only}, 'home-skill', 'skill dispatch loads the base skill .env file' );
    is( $env_dispatch_payload->{skill_chain}, 'skill-home/from-skill-env', 'skill dispatch expands skill .env values from earlier keys in the same skill env file' );
    is( $env_dispatch_payload->{skill_pl_chain}, 'skill-home/from-skill-env/from-skill-pl', 'skill dispatch loads skill .env before skill .env.pl within the same skill layer' );
    is( $env_dispatch_payload->{shared}, 'skill-child', 'skill-local env files override inherited runtime values for the running skill' );
    is(
        _portable_path( $env_dispatch_payload->{audit}{envfile} ),
        _portable_path( File::Spec->catfile( $env_child_skill_root, '.env.pl' ) ),
        'skill dispatch exposes env audit metadata for the effective deepest skill env source',
    );

    my ( $dotted_stdout, $dotted_stderr, $dotted_exit ) = capture {
        system( $^X, '-I', 'lib', $repo_bin, 'env-layer-skill.show' );
    };
    is( $dotted_exit >> 8, 0, 'dashboard <skill>.<command> loads runtime and skill env layers through the public dotted switchboard path' );
    my $dotted_payload = decode_json($dotted_stdout);
    is( $dotted_payload->{shared}, 'skill-child', 'dashboard <skill>.<command> keeps the deepest skill env override through the public path' );
    chdir $previous_cwd or die "Unable to chdir back to $previous_cwd: $!";
}

{
    my $oversized_skill_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'oversized-result-skill' );
    make_path( File::Spec->catdir( $oversized_skill_root, 'cli', 'show.d' ) );
    _write_file(
        File::Spec->catfile( $oversized_skill_root, 'cli', 'show.d', '00-big.pl' ),
        <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print STDERR 'X' x 5000;
PL
        0755,
    );
    _write_file(
        File::Spec->catfile( $oversized_skill_root, 'cli', 'show.d', '01-check.pl' ),
        <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result;
my $last = Developer::Dashboard::Runtime::Result::last_result() || {};
print STDERR $last->{file} || '';
PL
        0755,
    );
    _write_file(
        File::Spec->catfile( $oversized_skill_root, 'cli', 'show' ),
        <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Developer::Dashboard::Runtime::Result;
my $results = Developer::Dashboard::Runtime::Result::current();
print encode_json(
    {
        result_file  => ( $ENV{RESULT_FILE} ? 1 : 0 ),
        result_env   => ( defined $ENV{RESULT} && $ENV{RESULT} ne '' ? 1 : 0 ),
        hook_length  => length( Developer::Dashboard::Runtime::Result::stderr('00-big.pl') || '' ),
        prior_seen   => Developer::Dashboard::Runtime::Result::stderr('01-check.pl'),
        last_file    => ( Developer::Dashboard::Runtime::Result::last_result() || {} )->{file},
    }
), "\n";
PL
        0755,
    );
    _write_file(
        File::Spec->catfile( $oversized_skill_root, 'config', 'config.json' ),
        qq|{"skill_name":"oversized-result-skill"}\n|,
        0644,
    );

    local $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX} = 64;
    my $oversized_dispatch = $dispatcher->dispatch( 'oversized-result-skill', 'show' );
    ok( !$oversized_dispatch->{error}, 'skill dispatch survives oversized hook RESULT payloads by spilling to RESULT_FILE' )
      or diag $oversized_dispatch->{error};
    my $oversized_payload = decode_json( $oversized_dispatch->{stdout} );
    ok( $oversized_payload->{result_file}, 'skill command sees RESULT_FILE when hook RESULT exceeds the inline limit' );
    ok( !$oversized_payload->{result_env}, 'skill command does not rely on inline RESULT when the hook RESULT spills to a file' );
    is( $oversized_payload->{hook_length}, 5000, 'skill command can read the full oversized hook stdout through Runtime::Result' );
    like( $oversized_payload->{prior_seen}, qr/00-big\.pl\z/, 'later skill hooks see the immediate previous hook through LAST_RESULT before the final command runs' );
    like( $oversized_payload->{last_file}, qr/01-check\.pl\z/, 'skill command sees the immediate previous hook through LAST_RESULT' );
    remove_tree($oversized_skill_root);
}

my $beta_repo = _create_skill_repo(
    'beta-skill',
    command_body => <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "beta\n";
PL
);
my $beta_install = $manager->install( 'file://' . $beta_repo );
ok( !$beta_install->{error}, 'second skill installs without interfering with the first one' ) or diag $beta_install->{error};
is( scalar( @{ $manager->list } ), 2, 'multiple isolated skills can coexist' );

{
    my $local_repo = _create_skill_repo(
        'local-reinstall-skill',
        command_body => <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "local-v1\n";
PL
    );
    _write_file( File::Spec->catfile( $local_repo, '.env' ), "VERSION=1.00\n", 0644 );
    my $local_install = $manager->install($local_repo);
    ok( !$local_install->{error}, 'local checked-out skill installs through the direct directory path' ) or diag $local_install->{error};
    my $local_dispatch = $dispatcher->dispatch( 'local-reinstall-skill', 'run-test' );
    like( $local_dispatch->{stdout}, qr/local-v1/, 'local checked-out skill command executes after install' );

    _write_file(
        File::Spec->catfile( $local_repo, 'cli', 'run-test' ),
        <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "local-v2\n";
PL
        0755,
    );
    my $reinstall = $manager->install($local_repo);
    ok( !$reinstall->{error}, 'install acts as reinstall for an already-installed local checked-out skill' ) or diag $reinstall->{error};
    my $reinstall_dispatch = $dispatcher->dispatch( 'local-reinstall-skill', 'run-test' );
    like( $reinstall_dispatch->{stdout}, qr/local-v2/, 'reinstall refreshes the installed local skill checkout content' );
    my $local_uninstall = $manager->uninstall('local-reinstall-skill');
    ok( !$local_uninstall->{error}, 'temporary local checked-out skill can be removed after reinstall coverage' ) or diag $local_uninstall->{error};
}

my $disable = $manager->disable('alpha-skill');
ok( !$disable->{error}, 'disable marks an installed skill as disabled' ) or diag $disable->{error};
ok( !$manager->list->[0]{enabled}, 'disabled skills remain listed but report a disabled state' );
is_deeply(
    [ $paths->installed_skill_docker_roots ],
    [ File::Spec->catdir( $manager->get_skill_path('beta-skill'), 'config', 'docker' ) ],
    'installed_skill_docker_roots hides disabled skill docker roots by default',
);
is_deeply(
    [ $paths->installed_skill_docker_roots( include_disabled => 1 ) ],
    [
        File::Spec->catdir( $install->{path}, 'config', 'docker' ),
        File::Spec->catdir( $beta_install->{path}, 'config', 'docker' ),
    ],
    'installed_skill_docker_roots can include disabled skill docker roots when requested',
);
like(
    $dispatcher->dispatch( 'alpha-skill', 'run-test', 'disabled' )->{error},
    qr/^Skill 'alpha-skill' is disabled\./,
    'disabled skills no longer dispatch commands',
);
is_deeply(
    [ map { $_->{name} } @{ $fleet_config->collectors } ],
    [ 'housekeeper', 'system.collector' ],
    'disabled skills no longer contribute collectors to the managed fleet',
);
my ( $cli_disable_stdout, $cli_disable_stderr, $cli_disable_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'disable', 'alpha-skill' );
};
is( $cli_disable_exit >> 8, 0, 'dashboard skills disable exits cleanly for an already disabled skill' );
my $cli_disable = decode_json($cli_disable_stdout);
ok( !$cli_disable->{enabled}, 'dashboard skills disable reports disabled JSON state' );
my $disabled_usage = $manager->usage('alpha-skill');
ok( !$disabled_usage->{enabled}, 'usage still works for disabled skills and reports them as disabled' );

my $enable = $manager->enable('alpha-skill');
ok( !$enable->{error}, 'enable restores a disabled skill' ) or diag $enable->{error};
ok( $manager->list->[0]{enabled}, 're-enabled skills report an enabled state again' );
my $reenabled_dispatch = $dispatcher->dispatch( 'alpha-skill', 'run-test', 're-enabled' );
like( $reenabled_dispatch->{stdout}, qr/updated:re-enabled/, 're-enabled skills can dispatch commands again' );
is_deeply(
    [ map { $_->{name} } @{ $fleet_config->collectors } ],
    [ 'housekeeper', 'system.collector', 'alpha-skill.status' ],
    're-enabled skills rejoin the managed collector fleet',
);
my ( $cli_enable_stdout, $cli_enable_stderr, $cli_enable_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'enable', 'alpha-skill' );
};
is( $cli_enable_exit >> 8, 0, 'dashboard skills enable exits cleanly for an already enabled skill' );
my $cli_enable = decode_json($cli_enable_stdout);
ok( $cli_enable->{enabled}, 'dashboard skills enable reports enabled JSON state' );

my $uninstall = $manager->uninstall('beta-skill');
ok( !$uninstall->{error}, 'uninstall removes the targeted skill cleanly' ) or diag $uninstall->{error};
ok( !$manager->get_skill_path('beta-skill'), 'uninstall removes only the targeted skill path' );
ok( $manager->get_skill_path('alpha-skill'), 'uninstall preserves other installed skills' );

my $layered_project_root = File::Spec->catdir( $test_repos, 'layered-project' );
my $layered_work_root = File::Spec->catdir( $layered_project_root, 'workspace' );
make_path( File::Spec->catdir( $layered_project_root, '.developer-dashboard' ) );
make_path( File::Spec->catdir( $layered_project_root, '.git' ) );
make_path($layered_work_root);

my $layered_home_repo = _create_skill_repo(
    'shared-skill',
    command_body => <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "home-layer\n";
PL
    config_body => <<'JSON',
{
  "skill_name": "shared-skill",
  "base_only": "home",
  "nested": {
    "base": "home",
    "shared": "home"
  }
}
JSON
    bookmark_body => <<'BOOKMARK',
TITLE: Shared Skill Welcome
:--------------------------------------------------------------------------------:
BOOKMARK: welcome
:--------------------------------------------------------------------------------:
HTML:
Home layer welcome
BOOKMARK
    nav_body => "<div>Home layer nav</div>\n",
);
my $layered_home_only_repo = _create_skill_repo(
    'home-only-skill',
    command_body => <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "home-only\n";
PL
);

my $layered_home_paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
my $layered_home_manager = Developer::Dashboard::SkillManager->new( paths => $layered_home_paths );
ok( !$layered_home_manager->install( 'file://' . $layered_home_repo )->{error}, 'home layer installs a shared skill' );
ok( !$layered_home_manager->install( 'file://' . $layered_home_only_repo )->{error}, 'home layer installs a home-only skill' );
_append_repo_commit(
    $layered_home_repo,
    File::Spec->catfile( 'cli', 'run-test' ),
    <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "project-layer\n";
PL
);

{
    my $cwd = getcwd();
    chdir $layered_work_root or die "Unable to chdir to $layered_work_root: $!";

    my $layered_paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
    my $layered_manager = Developer::Dashboard::SkillManager->new( paths => $layered_paths );
    my $layered_dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $layered_paths );

    my $layered_install = $layered_manager->install( 'file://' . $layered_home_repo );
    ok( !$layered_install->{error}, 'deepest DD-OOP-LAYER installs a project-local skill copy' ) or diag $layered_install->{error};
    ok(
        index( $layered_install->{path}, File::Spec->catdir( $layered_project_root, '.developer-dashboard', 'skills', 'shared-skill' ) ) == 0,
        'skill install writes into the deepest participating DD-OOP-LAYER',
    );
    is(
        $layered_manager->get_skill_path('shared-skill'),
        File::Spec->catdir( $layered_project_root, '.developer-dashboard', 'skills', 'shared-skill' ),
        'layered skill lookup resolves the deepest matching skill first',
    );
    is(
        $layered_manager->get_skill_path('home-only-skill'),
        File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'home-only-skill' ),
        'layered skill lookup still inherits home-only skills',
    );
    my $layered_skill_root = $layered_manager->get_skill_path('shared-skill');
    unlink File::Spec->catfile( $layered_skill_root, 'cli', 'run-test' )
      or die "Unable to remove layered skill command fixture: $!";
    unlink File::Spec->catfile( $layered_skill_root, 'dashboards', 'welcome' )
      or die "Unable to remove layered skill bookmark fixture: $!";
    remove_tree( File::Spec->catdir( $layered_skill_root, 'dashboards', 'nav' ) );
    _write_file(
        File::Spec->catfile( $layered_skill_root, 'config', 'config.json' ),
        <<'JSON',
{
  "skill_name": "shared-skill",
  "nested": {
    "leaf": "project",
    "shared": "project"
  }
}
JSON
        0644,
    );
    is_deeply(
        $layered_dispatcher->get_skill_config('shared-skill'),
        {
            skill_name => 'shared-skill',
            base_only  => 'home',
            nested     => {
                base   => 'home',
                leaf   => 'project',
                shared => 'project',
            },
        },
        'skill config merges inherited skill config keys and falls back to the base layer for missing keys',
    );
    my $layered_dispatch = $layered_dispatcher->dispatch( 'shared-skill', 'run-test' );
    like( $layered_dispatch->{stdout}, qr/home-layer/, 'dispatcher falls back to the inherited base-layer skill command when the child-layer command file is missing' );
    my $layered_home_dispatch = $layered_dispatcher->dispatch( 'home-only-skill', 'run-test' );
    like( $layered_home_dispatch->{stdout}, qr/home-only/, 'dispatcher can still reach inherited home-layer skills beneath a project layer' );
    my ( $layered_dotted_stdout, $layered_dotted_stderr, $layered_dotted_exit ) = capture {
        system( $^X, '-I', 'lib', $repo_bin, 'shared-skill.run-test' );
    };
    is( $layered_dotted_exit >> 8, 0, 'dashboard <skill>.<command> resolves layered project-local skills' );
    like( $layered_dotted_stdout, qr/home-layer/, 'dashboard <skill>.<command> falls back to the inherited base-layer skill command when the child-layer command file is missing' );
    my ( $layered_inherited_stdout, $layered_inherited_stderr, $layered_inherited_exit ) = capture {
        system( $^X, '-I', 'lib', $repo_bin, 'home-only-skill.run-test' );
    };
    is( $layered_inherited_exit >> 8, 0, 'dashboard <skill>.<command> resolves inherited home-layer skills from deeper layers' );
    like( $layered_inherited_stdout, qr/home-only/, 'dashboard <skill>.<command> keeps inherited home-layer skills available' );
    my $layered_bookmark_list = $layered_dispatcher->route_response( skill_name => 'shared-skill', route => 'bookmarks' );
    is( $layered_bookmark_list->[0], 200, 'skill bookmark listings fall back to inherited base-layer files when the child layer does not provide them' );
    is_deeply(
        decode_json( $layered_bookmark_list->[2] ),
        {
            skill     => 'shared-skill',
            bookmarks => ['welcome'],
        },
        'skill bookmark listings include inherited base-layer bookmark files when the child layer is missing them',
    );
    my $layered_bookmark = $layered_dispatcher->route_response( skill_name => 'shared-skill', route => 'bookmarks/welcome' );
    is( $layered_bookmark->[0], 200, 'skill bookmark routes fall back to inherited base-layer files when the child-layer bookmark file is missing' );
    like( $layered_bookmark->[2], qr/Home layer welcome/, 'skill bookmark routes render the inherited base-layer bookmark content' );
    my $layered_nav_pages = $layered_dispatcher->skill_nav_pages('shared-skill');
    is( scalar @{$layered_nav_pages}, 1, 'skill nav discovery falls back to the inherited base-layer nav folder when the child layer is missing it' );
    like( $layered_nav_pages->[0]{layout}{body}, qr/Home layer nav/, 'skill nav discovery returns the inherited base-layer nav content' );

    chdir $cwd or die "Unable to chdir back to $cwd: $!";
}

my ( $singular_skill_stdout, $singular_skill_stderr, $singular_skill_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skill', 'list', '-o', 'json' );
};
is( $singular_skill_exit >> 8, 0, 'dashboard skill aliases the skills management command family' );
is( $singular_skill_stderr, '', 'dashboard skill alias does not emit errors for management commands' );
my $singular_skill_list = decode_json($singular_skill_stdout);
ok( scalar( grep { $_->{name} eq 'alpha-skill' } @{ $singular_skill_list->{skills} } ), 'dashboard skill list sees installed skills through the alias' );

my ( $dotted_skill_stdout, $dotted_skill_stderr, $dotted_skill_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'alpha-skill.run-test', 'cli-dot' );
};
is( $dotted_skill_exit >> 8, 0, 'dashboard <skill>.<command> dispatch exits cleanly' );
like( $dotted_skill_stdout, qr/updated:cli-dot/, 'dashboard <skill>.<command> routes into the installed skill command' );
my ( $dotted_skill_typo_stdout, $dotted_skill_typo_stderr, $dotted_skill_typo_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'alpha-skill.run-tset', 'cli-dot' );
};
is( $dotted_skill_typo_exit >> 8, 1, 'dashboard <skill>.<command> exits non-zero for an unknown dotted skill command' );
like( $dotted_skill_typo_stdout . $dotted_skill_typo_stderr, qr/Command 'run-tset' not found in skill 'alpha-skill'/, 'dashboard reports the missing dotted skill command explicitly' );
like( $dotted_skill_typo_stdout . $dotted_skill_typo_stderr, qr/Did you mean:\s+dashboard alpha-skill\.run-test/s, 'dashboard suggests the closest installed dotted skill command when the command tail is mistyped' );
my ( $skill_which_stdout, $skill_which_stderr, $skill_which_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'which', 'alpha-skill.run-test' );
};
is( $skill_which_exit >> 8, 0, 'dashboard which <skill>.<command> exits cleanly' );
like( $skill_which_stdout, qr/^COMMAND \Q@{[ File::Spec->catfile( $install->{path}, 'cli', 'run-test' ) ]}\E$/m, 'dashboard which <skill>.<command> reports the resolved skill command path' );
like( $skill_which_stdout, qr/^HOOK \Q@{[ File::Spec->catfile( $install->{path}, 'cli', 'run-test.d', '00-pre.pl' ) ]}\E$/m, 'dashboard which <skill>.<command> reports the participating skill hook file' );
my $skill_editor_log = File::Spec->catfile( $ENV{HOME}, 'skill-which-editor.log' );
my $skill_editor = File::Spec->catfile( $ENV{HOME}, 'skill-which-editor' );
_write_file(
    $skill_editor,
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$@" > '$skill_editor_log'
SH
    0755,
);
my ( $skill_which_edit_stdout, $skill_which_edit_stderr, $skill_which_edit_exit ) = capture {
    local $ENV{EDITOR} = $skill_editor;
    system( $^X, '-I', 'lib', $repo_bin, 'which', '--edit', 'alpha-skill.run-test' );
};
is( $skill_which_edit_exit >> 8, 0, 'dashboard which --edit <skill>.<command> exits cleanly' );
is( $skill_which_edit_stdout, '', 'dashboard which --edit <skill>.<command> does not print inspection output before opening the file' );
is( $skill_which_edit_stderr, '', 'dashboard which --edit <skill>.<command> keeps stderr clean' );
open my $skill_editor_log_fh, '<', $skill_editor_log or die "Unable to read $skill_editor_log: $!";
my $skill_editor_args = do { local $/; <$skill_editor_log_fh> };
close $skill_editor_log_fh;
is(
    $skill_editor_args,
    File::Spec->catfile( $install->{path}, 'cli', 'run-test' ) . "\n",
    'dashboard which --edit <skill>.<command> opens the resolved skill command path through dashboard open-file',
);

make_path( File::Spec->catdir( $install->{path}, 'skills', 'foo', 'cli' ) );
_write_file(
    File::Spec->catfile( $install->{path}, 'skills', 'foo', 'cli', 'foo' ),
    <<'PL',
#!/usr/bin/env perl
use strict;
use warnings;
print "nested:", join('|', @ARGV), "\n";
PL
    0755,
);
my ( $nested_skill_stdout, $nested_skill_stderr, $nested_skill_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'alpha-skill.foo.foo', 'nested-arg' );
};
is( $nested_skill_exit >> 8, 0, 'dashboard <skill>.<nested-skill>.<command> dispatch exits cleanly' );
like( $nested_skill_stdout, qr/nested:nested-arg/, 'dashboard dotted dispatch resolves nested skills/<repo>/cli commands inside an installed skill' );
my ( $nested_which_stdout, $nested_which_stderr, $nested_which_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'which', 'alpha-skill.foo.foo' );
};
is( $nested_which_exit >> 8, 0, 'dashboard which <skill>.<nested-skill>.<command> exits cleanly' );
like( $nested_which_stdout, qr/^COMMAND \Q@{[ File::Spec->catfile( $install->{path}, 'skills', 'foo', 'cli', 'foo' ) ]}\E$/m, 'dashboard which resolves nested skill commands to the deepest nested cli file' );
my ( $nested_which_edit_stdout, $nested_which_edit_stderr, $nested_which_edit_exit ) = capture {
    local $ENV{EDITOR} = $skill_editor;
    system( $^X, '-I', 'lib', $repo_bin, 'which', '--edit', 'alpha-skill.foo.foo' );
};
is( $nested_which_edit_exit >> 8, 0, 'dashboard which --edit <skill>.<nested-skill>.<command> exits cleanly' );
is( $nested_which_edit_stdout, '', 'dashboard which --edit nested skill command does not print inspection output before opening the file' );
is( $nested_which_edit_stderr, '', 'dashboard which --edit nested skill command keeps stderr clean' );
open my $nested_editor_log_fh, '<', $skill_editor_log or die "Unable to read $skill_editor_log after nested which --edit: $!";
my $nested_editor_args = do { local $/; <$nested_editor_log_fh> };
close $nested_editor_log_fh;
is(
    $nested_editor_args,
    File::Spec->catfile( $install->{path}, 'skills', 'foo', 'cli', 'foo' ) . "\n",
    'dashboard which --edit nested skill command opens the deepest resolved nested skill path through dashboard open-file',
);

my ( $uninstall_stdout, $uninstall_stderr, $uninstall_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'uninstall', 'alpha-skill' );
};
is( $uninstall_exit >> 8, 0, 'dashboard skills uninstall exits cleanly' );
is_deeply(
    [ map { $_->{name} } @{ $manager->list } ],
    [ 'home-only-skill', 'shared-skill' ],
    'uninstall removes the targeted base skill without touching layered skills from other DD-OOP-LAYERS',
);

done_testing();

sub _create_skill_repo {
    my ( $name, %args ) = @_;
    my $repo = File::Spec->catdir( $test_repos, $name );
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
    make_path('dashboards');
    make_path( File::Spec->catdir( 'cli', 'run-test.d' ) );

    _write_file( File::Spec->catfile( 'cli', 'run-test' ), $args{command_body} || "#!/usr/bin/env perl\nprint qq{ok\\n};\n", 0755 );
    if ( defined $args{hook_body} ) {
        _write_file( File::Spec->catfile( 'cli', 'run-test.d', '00-pre.pl' ), $args{hook_body}, 0755 );
    }
    _write_file( File::Spec->catfile( 'config', 'config.json' ), $args{config_body} || qq|{"skill_name":"$name"}\n|, 0644 );
    _write_file( File::Spec->catfile( 'config', 'docker', 'postgres', 'compose.yml' ), "services: {}\n", 0644 );
    _write_file( 'cpanfile', $args{cpanfile_body} || "requires 'JSON::XS';\n", 0644 );
    if ( defined $args{ddfile_body} ) {
        _write_file( 'ddfile', $args{ddfile_body}, 0644 );
    }
    if ( defined $args{ddfile_local_body} ) {
        _write_file( 'ddfile.local', $args{ddfile_local_body}, 0644 );
    }
    if ( defined $args{aptfile_body} ) {
        _write_file( 'aptfile', $args{aptfile_body}, 0644 );
    }
    if ( defined $args{apkfile_body} ) {
        _write_file( 'apkfile', $args{apkfile_body}, 0644 );
    }
    if ( defined $args{dnfile_body} ) {
        _write_file( 'dnfile', $args{dnfile_body}, 0644 );
    }
    if ( defined $args{brewfile_body} ) {
        _write_file( 'brewfile', $args{brewfile_body}, 0644 );
    }
    if ( defined $args{package_json_body} ) {
        _write_file( 'package.json', $args{package_json_body}, 0644 );
    }
    if ( defined $args{cpanfile_local_body} ) {
        _write_file( 'cpanfile.local', $args{cpanfile_local_body}, 0644 );
    }
    if ( defined $args{bookmark_body} ) {
        _write_file( File::Spec->catfile( 'dashboards', 'welcome' ), $args{bookmark_body}, 0644 );
    }
    if ( defined $args{nav_body} ) {
        make_path( File::Spec->catdir( 'dashboards', 'nav' ) );
        _write_file( File::Spec->catfile( 'dashboards', 'nav', 'skill.tt' ), $args{nav_body}, 0644 );
    }

    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', "Initial $name" );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return $repo;
}

sub _append_repo_commit {
    my ( $repo, $file, $content ) = @_;
    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    _write_file( $file, $content, 0755 );
    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', 'Update skill command' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return 1;
}

sub _write_file {
    my ( $path, $content, $mode ) = @_;
    my $dir = File::Spec->catpath( ( File::Spec->splitpath($path) )[ 0, 1 ], '' );
    make_path($dir) if $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    chmod $mode, $path or die "Unable to chmod $path: $!";
    return 1;
}

sub _run_or_die {
    my (@command) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system(@command);
    };
    die "Command failed: @command\n$stderr" if $exit != 0;
    return $stdout;
}

__END__

=pod

=head1 NAME

t/19-skill-system.t - test the isolated skill installation and dispatch runtime

=head1 License

This test is part of Developer Dashboard.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the isolated skill installation and routing stack. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the isolated skill installation and routing stack has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the isolated skill installation and routing stack, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/19-skill-system.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/19-skill-system.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/19-skill-system.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
