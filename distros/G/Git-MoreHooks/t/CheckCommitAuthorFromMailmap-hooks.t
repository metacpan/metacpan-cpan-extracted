#!perl

use 5.010;
use strict;
use warnings;
use Test::Most;
use Git::Hooks::Test ':all';
use Path::Tiny;
use Test::Requires::Git;

my ( $repo, $clone, $T );

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

    unless ( -e $filename ) {
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
    my ( $testname, $file, $action, $data ) = @_;
    modify_file( $testname, $file, $action, $data );
    test_ok( $testname, $repo, 'commit', '-m', $testname );
    return 1;
}

sub check_cannot_commit {
    my ( $testname, $regex, $file, $action, $data ) = @_;
    my $filename = modify_file( $testname, $file, $action, $data );
    my $exit =
      $regex
      ? test_nok_match( $testname, $regex, $repo, 'commit', '-m', $testname )
      : test_nok( $testname, $repo, 'commit', '-m', $testname );
    $repo->run(qw/reset --hard/);
    return $exit;
}

setup_repos();

# Normal config
$repo->run(qw/config user.name My Self/);
$repo->run(qw/config user.email myself@example.com/);

# Overriding variables (because you never know...)
$ENV{'GIT_AUTHOR_NAME'}     = 'My Self';
$ENV{'GIT_AUTHOR_EMAIL'}    = 'myself@example.com';
$ENV{'GIT_COMMITTER_NAME'}  = 'My Self';
$ENV{'GIT_COMMITTER_EMAIL'} = 'myself@example.com';

check_can_commit( 'commit sans configuration', 'file.txt' );

check_can_commit( 'commit .mailmap', '.mailmap', 'truncate', $mailmap );

$repo->run(qw/config githooks.plugin Git::MoreHooks::CheckCommitAuthorFromMailmap/);

check_cannot_commit( 'fail commit file', undef, 'file.txt' );

$repo->run(qw/config user.name MeIMyself/);
$repo->run(qw/config user.email me.myself@comp.xx/);
$ENV{'GIT_AUTHOR_NAME'}     = 'MeIMyself';
$ENV{'GIT_AUTHOR_EMAIL'}    = 'me.myself@comp.xx';
$ENV{'GIT_COMMITTER_NAME'}  = 'MeIMyself';
$ENV{'GIT_COMMITTER_EMAIL'} = 'me.myself@comp.xx';

check_can_commit( 'commit file', 'file.txt' );

done_testing();
