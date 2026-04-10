#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::XS qw(decode_json);
use Test::More;

use lib 'lib';
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $repo_root = getcwd();
my $repo_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $test_repos = tempdir( CLEANUP => 1 );
my $fake_bin = tempdir( CLEANUP => 1 );
my $cpanm_log = File::Spec->catfile( $fake_bin, 'cpanm.log' );
_write_file(
    File::Spec->catfile( $fake_bin, 'cpanm' ),
    <<"SH",
#!/bin/sh
printf '%s\\n' "\$*" >> "$cpanm_log"
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
ok( -f $cpanm_log, 'install runs cpanm for isolated skill dependencies when a cpanfile is present' );

my $listed = $manager->list();
is( scalar(@$listed), 1, 'list returns the installed skill only once' );
is_deeply(
    $listed->[0]{cli_commands},
    ['run-test'],
    'list reports the isolated skill cli commands',
);
ok(
    index( $listed->[0]{path}, File::Spec->catdir( $ENV{HOME}, '.developer-dashboard', 'skills', 'alpha-skill' ) ) == 0,
    'installed skill lives only under the isolated skills root',
);

my $dispatch = $dispatcher->dispatch( 'alpha-skill', 'run-test', 'one', 'two' );
ok( !$dispatch->{error}, 'dispatcher runs a skill command successfully' ) or diag $dispatch->{error};
like( $dispatch->{stdout}, qr/hook-alpha/, 'dispatch runs skill-local hooks before the main command' );
like( $dispatch->{stdout}, qr/one\|two/, 'dispatch preserves skill command arguments' );
ok( exists $dispatch->{hooks}{'00-pre.pl'}, 'dispatch returns captured hook metadata' );

my $config = $dispatcher->get_skill_config('alpha-skill');
is( $config->{skill_name}, 'alpha-skill', 'dispatcher reads isolated skill config' );

my ( $cli_install_stdout, $cli_install_stderr, $cli_install_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'list' );
};
is( $cli_install_exit >> 8, 0, 'dashboard skills list exits cleanly' );
my $cli_list = decode_json($cli_install_stdout);
is( scalar( @{ $cli_list->{skills} } ), 1, 'dashboard skills list reports installed skills' );

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

my $uninstall = $manager->uninstall('beta-skill');
ok( !$uninstall->{error}, 'uninstall removes the targeted skill cleanly' ) or diag $uninstall->{error};
ok( !$manager->get_skill_path('beta-skill'), 'uninstall removes only the targeted skill path' );
ok( $manager->get_skill_path('alpha-skill'), 'uninstall preserves other installed skills' );

my ( $skill_stdout, $skill_stderr, $skill_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skill', 'alpha-skill', 'run-test', 'cli' );
};
is( $skill_exit >> 8, 0, 'dashboard skill dispatch exits cleanly' );
like( $skill_stdout, qr/updated:cli/, 'dashboard skill dispatch routes through the isolated skill command' );

my ( $uninstall_stdout, $uninstall_stderr, $uninstall_exit ) = capture {
    system( $^X, '-I', 'lib', $repo_bin, 'skills', 'uninstall', 'alpha-skill' );
};
is( $uninstall_exit >> 8, 0, 'dashboard skills uninstall exits cleanly' );
is_deeply( $manager->list, [], 'all skills can be removed cleanly without file hunting elsewhere' );

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
    _write_file( File::Spec->catfile( 'config', 'config.json' ), qq|{"skill_name":"$name"}\n|, 0644 );
    _write_file( File::Spec->catfile( 'config', 'docker', 'postgres', 'compose.yml' ), "services: {}\n", 0644 );
    _write_file( 'cpanfile', "requires 'JSON::XS';\n", 0644 );
    if ( defined $args{bookmark_body} ) {
        _write_file( File::Spec->catfile( 'dashboards', 'welcome' ), $args{bookmark_body}, 0644 );
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
