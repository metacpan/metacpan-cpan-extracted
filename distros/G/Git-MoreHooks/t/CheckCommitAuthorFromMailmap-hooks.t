#!perl
## no critic (Variables::ProhibitPunctuationVars)
use strict;
use warnings;
use Test2::V0;
use Git::Hooks::Test ':all';
use Path::Tiny;

my ( $repo, $clone, $T );

# Eliminate the effects of system wide and global configuration.
# https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
my %git_test_env = (
    LC_ALL              => 'C',
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,
);

my $mailmap = <<'MAILMAP_END';
<cto@company.xx>                                <cto@coompany.xx>
Some Dude <some@dude.xx>                  nick1 <bugs@company.xx>
Other Author <other@author.xx>            nick2 <bugs@company.xx>
Other Author <other@author.xx>                  <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx>          <me@company.xx>
Me Myself              <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                Me I Myself     <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                MeIMyself     <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                me                         <me@comp.xx>
Me Myself              <me.myself@comp.xx>                me                         <me.myself@comp.xx>
Me Too Myself          <me.myself@comp.xx>
MAILMAP_END

sub setup_repos {
    ( $repo, undef, $clone, $T ) = new_repos();

    install_hooks( $repo,  undef, qw/pre-commit/ );
    install_hooks( $clone, undef, qw/update pre-receive/ );
    return;
}

sub modify_file {
    my ( $testname, $file, $action, $data ) = @_;
    my @path     = split qr{/}msx, $file;
    my $wcpath   = path( $repo->work_tree() );
    my $filename = $wcpath->child(@path);

    unless ( -e $filename ) {    ## no critic (ControlStructures::ProhibitUnlessBlocks)
        pop @path;
        my $dirname = $wcpath->child(@path);
        $dirname->mkpath;
    }

    if ( !defined $action ) {
        if ( $filename->append( $data || 'data' ) ) {
            $repo->run( add => $filename );
        }
        else {
            fail($testname);
            diag("[TEST FRAMEWORK INTERNAL ERROR] Cannot append to file: $filename; $!\n");
        }
    }
    elsif ( $action eq 'truncate' ) {
        if ( $filename->append( { truncate => 1 }, $data || 'data' ) ) {
            $repo->run( add => $filename );
        }
        else {
            fail($testname);
            diag("[TEST FRAMEWORK INTERNAL ERROR] Cannot write to file: $filename; $!\n");
        }
    }
    elsif ( $action eq 'rm' ) {
        $repo->run( rm => $filename );
    }
    else {
        fail($testname);
        diag("[TEST FRAMEWORK INTERNAL ERROR] Invalid action: $action; $!\n");
    }

    return $filename;
}

sub check_can_commit {
    my ( $testname, $file, $action, $data, $env ) = @_;
    my $all_env = { %git_test_env, %{$env} };
    modify_file( $testname, $file, $action, $data );
    test_ok( $testname, $repo, 'commit', '-m', $testname, { env => $all_env } );
    return 1;
}

sub check_cannot_commit {    ## no critic (Subroutines::ProhibitManyArgs)
    my ( $testname, $regex, $file, $action, $data, $env ) = @_;
    my $all_env  = { %git_test_env, %{$env} };
    my $filename = modify_file( $testname, $file, $action, $data );
    my $exit =
      $regex
      ? test_nok_match( $testname, $regex, $repo, 'commit', '-m', $testname, { env => $all_env } )
      : test_nok( $testname, $repo, 'commit', '-m', $testname, { env => $all_env } );
    $repo->run(qw/reset --hard/);
    return $exit;
}

setup_repos();

# Normal config
$repo->run( qw/config user.name My Self/,             { env => {%git_test_env} } );
$repo->run( qw/config user.email myself@example.com/, { env => {%git_test_env} } );

# Overriding variables (because you never know...)
my %env = (
    GIT_AUTHOR_NAME     => 'My Self',
    GIT_AUTHOR_EMAIL    => 'myself@example.com',
    GIT_COMMITTER_NAME  => 'My Self',
    GIT_COMMITTER_EMAIL => 'myself@example.com',
);

check_can_commit( 'commit sans configuration', 'file.txt', undef, undef, \%env );

check_can_commit( 'commit .mailmap', '.mailmap', 'truncate', $mailmap, \%env );

$repo->run( qw/config githooks.plugin Git::MoreHooks::CheckCommitAuthorFromMailmap/, { env => {%git_test_env} } );

check_cannot_commit( 'fail commit file', undef, 'file.txt', undef, undef, \%env );

$repo->run( qw/config user.name MeIMyself/,          { env => {%git_test_env} } );
$repo->run( qw/config user.email me.myself@comp.xx/, { env => {%git_test_env} } );
%env = (
    GIT_AUTHOR_NAME     => 'MeIMyself',
    GIT_AUTHOR_EMAIL    => 'me.myself@comp.xx',
    GIT_COMMITTER_NAME  => 'MeIMyself',
    GIT_COMMITTER_EMAIL => 'me.myself@comp.xx',
);

check_can_commit( 'commit file', 'file.txt', undef, undef, \%env );

done_testing();
