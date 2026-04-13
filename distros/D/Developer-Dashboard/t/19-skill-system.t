#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::XS qw(decode_json);
use Test::More;

use lib 'lib';
use Developer::Dashboard::Config;
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
    File::Spec->catfile( $fake_bin, 'apt-get' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$apt_log"
printf 'APT:%s\\n' "\$*" >> "$dependency_log"
exit 0
SH
    0755,
);
local $ENV{PATH} = join ':', $fake_bin, ( $ENV{PATH} || () );

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
    aptfile_body => "git\ncurl\n",
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
ok( -f File::Spec->catfile( $install->{path}, 'config', 'config.json' ), 'install ensures isolated skill config exists' );
ok( -f File::Spec->catfile( $install->{path}, 'cpanfile' ), 'test skill includes cpanfile for dependency handling' );
ok( -f File::Spec->catfile( $install->{path}, 'aptfile' ), 'test skill includes aptfile for dependency handling' );
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
is( $dependency_steps[0] =~ /^APT:/ ? 1 : 0, 1, 'skill install runs aptfile processing before cpanfile processing' );
is( $dependency_steps[1] =~ /^CPANM:/ ? 1 : 0, 1, 'skill install runs cpanfile processing after aptfile processing' );

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
is( $listed->[0]{has_aptfile}, 1, 'list reports aptfile presence for one installed skill' );
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
    [ 'system.collector', 'alpha-skill.status' ],
    'config collector fleet includes installed skill collectors under repo-qualified names',
);
is( $fleet_jobs->[1]{skill_name}, 'alpha-skill', 'skill collectors carry their source skill name in fleet metadata' );
is( $fleet_jobs->[1]{indicator}{label}, 'Alpha Status', 'skill collector indicator config survives fleet loading' );
my $usage_with_collectors = $manager->usage('alpha-skill');
is( $usage_with_collectors->{collectors}[0]{qualified_name}, 'alpha-skill.status', 'usage reports repo-qualified collector names' );
ok( $usage_with_collectors->{collectors}[0]{has_indicator}, 'usage reports when a collector has an indicator' );

my ( $cli_install_stdout, $cli_install_stderr, $cli_install_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'list' );
};
is( $cli_install_exit >> 8, 0, 'dashboard skills list exits cleanly' );
my $cli_list = decode_json($cli_install_stdout);
is( scalar( @{ $cli_list->{skills} } ), 1, 'dashboard skills list reports installed skills' );
ok( $cli_list->{skills}[0]{enabled}, 'dashboard skills list reports enabled state in JSON output' );

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
is( $dispatcher->dispatch( 'alpha-skill', 'run-test', 'disabled' )->{error}, "Skill 'alpha-skill' is disabled", 'disabled skills no longer dispatch commands' );
is_deeply(
    [ map { $_->{name} } @{ $fleet_config->collectors } ],
    ['system.collector'],
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
    [ 'system.collector', 'alpha-skill.status' ],
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

my ( $removed_skill_stdout, $removed_skill_stderr, $removed_skill_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skill', 'alpha-skill', 'run-test', 'cli' );
};
is( $removed_skill_exit >> 8, 1, 'dashboard skill no longer dispatches installed skill commands' );
like(
    $removed_skill_stdout . $removed_skill_stderr,
    qr/Unsupported built-in dashboard command 'skill'|Usage:/s,
    'dashboard skill now fails as a removed public command',
);

my ( $dotted_skill_stdout, $dotted_skill_stderr, $dotted_skill_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'alpha-skill.run-test', 'cli-dot' );
};
is( $dotted_skill_exit >> 8, 0, 'dashboard <skill>.<command> dispatch exits cleanly' );
like( $dotted_skill_stdout, qr/updated:cli-dot/, 'dashboard <skill>.<command> routes into the installed skill command' );

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
    _write_file( 'cpanfile', "requires 'JSON::XS';\n", 0644 );
    if ( defined $args{aptfile_body} ) {
        _write_file( 'aptfile', $args{aptfile_body}, 0644 );
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
