
use strict;
use warnings;
use Test::Most 'die';
use Test::Git;

use YAML qw( LoadFile );
use Cwd qw( getcwd );
my $CWD = getcwd;
BEGIN {
    diag `git --version`;
};
END {
    chdir $CWD;
};
use File::Spec::Functions qw( catdir catfile );
use File::Slurp qw( read_file write_file );
use File::Temp;

my $foo_repo = test_repository;
my $bar_repo = test_repository;

my $foo_readme = catfile( $foo_repo->work_tree, 'README' );
write_file( $foo_readme, 'Foo version 0.0' );
$foo_repo->run( add => $foo_readme );
$foo_repo->run( commit => -m => 'Added readme' );

my $bar_readme = catfile( $bar_repo->work_tree, 'README' );
write_file( $bar_readme, 'Bar version 0.0' );
$bar_repo->run( add => $bar_readme );
$bar_repo->run( commit => -m => 'Added readme' );

my $rel_root;
if ( $ENV{NO_CLEANUP} ) {
    $rel_root = File::Temp->newdir( CLEANUP => 0 );
    print "# Release root: $rel_root\n";
    END { print "# Release root: $rel_root\n" if $ENV{NO_CLEANUP} }
}
else {
    $rel_root = File::Temp->newdir( CLEANUP => 1 );
}
my $rel_repo;

use Git::ReleaseRepo;
use Git::ReleaseRepo::Command::init;
BEGIN { diag $INC{'Git/ReleaseRepo.pm'} };
use Git::ReleaseRepo::Test qw(
    run_cmd is_repo_clean last_commit repo_branches repo_tags repo_refs
    current_branch is_current_tag
);

sub test_repo_has_refs($%) {
    my ( $repo, %refs ) = @_;
    return sub {
        is_repo_clean $repo;
        # Has release branch and release tag
        if ( $refs{branch} ) {
            my @required = ref $refs{branch} eq 'ARRAY' ? @{$refs{branch}} : $refs{branch};
            my @branches = grep { $_ ne 'master' } repo_branches $repo;
            cmp_deeply \@branches, bag( @required ), 'branches are correct';
        }
        if ( $refs{tag} ) {
            my @required = ref $refs{tag} eq 'ARRAY' ? @{$refs{tag}} : $refs{tag};
            my @tags = repo_tags $repo;
            cmp_deeply \@tags, bag(@required), 'tags are correct';
        }
    };
}

sub test_status($%) {
    my ( $stdout, %modules ) = @_;
    return sub {
        for my $mod ( keys %modules ) {
            if ( not defined $modules{$mod} ) {
                unlike $stdout, qr/^$mod/m, "module '$mod' unchanged and cannot update";
                next;
            }
            my %test = map { $_ => 1 }
                       ref $modules{$mod} eq 'ARRAY' ? @{$modules{$mod}} : $modules{$mod};
            if ( $test{changed} ) {
                like $stdout, qr/^$mod\s+changed/m, "module '$mod' changed";
            }
            else { # unchanged
                unlike $stdout, qr/^$mod\s+changed/m, "module '$mod' unchanged";
            }
            if ( $test{outdated} ) {
                like $stdout, qr/^$mod.*can update/m, "module '$mod' outdated";
            }
            else { # not outdated
                unlike $stdout, qr/^$mod.*can update/m, "module '$mod' outdated";
            }
        }
    };
}

sub test_release_status(%) {
    chdir catdir( $rel_root, 'test-release' );
    run_cmd( 'checkout', 'master' );
    my $result = run_cmd( 'status' );
    return test_status $result->{stdout}, @_;
}

sub test_bugfix_status(%) {
    chdir catdir( $rel_root, 'test-release' );
    run_cmd( 'checkout', '--bugfix' );
    my $result = run_cmd( 'status' );
    return test_status $result->{stdout}, @_;
}

sub test_deploy($%) {
    my ( $dir, %test ) = @_;
    return sub {
        subtest 'deployed repository is correct' => sub {
            my $deploy_dir = catdir( $rel_root, $dir );
            ok -d $deploy_dir, "Deploy directory '$dir' exists";
            my $deploy_repo = Git::Repository->new( work_tree => $deploy_dir );
            is_repo_clean $deploy_repo;
            is_current_tag $deploy_repo, $test{tag};
        };
        subtest 'submodules are initialized' => sub {
            my $sub_dir = catdir( $rel_root, $dir, 'foo' );
            ok -f catfile( $sub_dir, 'README' );
            my $sub_repo = Git::Repository->new( work_tree => $sub_dir );
            is_repo_clean $sub_repo;
            is_current_tag $sub_repo, $test{tag};
        };
        subtest 'deployed configuration is correct' => sub {
            my $conf = LoadFile( catfile( $rel_root, $dir, '.git', 'release' ) );
            cmp_deeply
                $conf,
                {
                    track => $test{branch},
                    version_prefix => 'v',
                },
                'deploy config is complete and correct';
        };
    }
}

sub test_deploy_status($$$) {
    my ( $repo, $from, $to ) = @_;
    return sub {
        chdir catdir( $rel_root, $repo );
        my $result = run_cmd( 'status' );
        like $result->{stdout}, qr/^On release $from/, "Currently on $from";
        if ( $to ) {
            like $result->{stdout}, qr/\(can update to $to\)/, "Can be updated to $to";
        }
        else {
            unlike $result->{stdout}, qr/^On release $from \(can update/, 'Can not be updated';
        }
    }
}

subtest 'initial creation' => sub {
    subtest 'create, use, configure' => sub {
        Git::Repository->run( init => catdir( $rel_root, 'test-release' ) );
        $rel_repo = Git::Repository->new( work_tree => catdir( $rel_root, 'test-release' ) );
        ok -d catdir( $rel_root, 'test-release' );
    };
    subtest 'init' => sub {
        chdir $rel_repo->work_tree;
        my $result = run_cmd( 'init', '--version_prefix', 'v' );
        ok -f catfile( $rel_repo->git_dir, 'release' ), 'config file created';
        my $config = LoadFile( catfile( $rel_repo->git_dir, 'release' ) );
        cmp_deeply $config, {
            version_prefix => 'v',
        }, 'config is complete and correct';
    };
};

subtest 'add new module' => sub {
    chdir $rel_repo->work_tree;
    my $result = run_cmd( 'add', 'foo', 'file://' . $foo_repo->work_tree );

    subtest 'repository is correct' => sub {
        is_repo_clean $rel_repo;
        my @changes = last_commit $rel_repo;
        is scalar @changes, 2, 'only two changes were made';
        cmp_deeply \@changes,
            bag( 
                superhashof( { path_src => '.gitmodules' } ),
                superhashof( { path_src => 'foo' } ),
            ),
            'changes to .gitmodules and foo';

        my $gitmodules = read_file( catfile( $rel_repo->work_tree, '.gitmodules' ) );
        like $gitmodules, qr{\[submodule\s+"foo"\]\s+path\s*=\s*foo}s, 'module has right name and path';
    };

    subtest 'module status is changed'
        => test_release_status foo => 'changed';
};

subtest 'update module' => sub {
    write_file( $foo_readme, 'Foo version 1.0' );
    $foo_repo->run( add => $foo_readme );
    $foo_repo->run( commit => -m => 'Added readme' );

    subtest 'module status is out-of-date'
        => test_release_status foo => [qw( changed outdated )];

    chdir catdir( $rel_root, 'test-release' );
    my $result = run_cmd( 'update', 'foo' );

    subtest 'module status is no longer out-of-date'
        => test_release_status foo => 'changed';
};

subtest 'first release' => sub {
    chdir $rel_repo->work_tree;
    my $result = run_cmd( 'commit' );
    $result = run_cmd( 'push' );

    subtest 'release repository is correct'
        => test_repo_has_refs $rel_repo, branch => 'v0.1', tag => 'v0.1.0';

    subtest 'module repository is correct'
        => test_repo_has_refs $foo_repo, branch => 'v0.1', tag => 'v0.1.0';

    subtest 'module status is unchanged'
        => test_release_status foo => undef;
};

subtest 'add bugfix' => sub {
    # Foo has a bugfix
    my $cmd = $foo_repo->command( checkout => 'v0.1' );
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        fail "Could not checkout Foo 'v0.1'.\nSTDERR: " . $cmd->stderr;
    }
    write_file( $foo_readme, 'Foo version 1.1' );
    $foo_repo->run( add => $foo_readme );
    $foo_repo->run( commit => -m => 'Added bugfix' );
    $foo_repo->command( checkout => 'master' );

    subtest 'bugfix status is out-of-date'
        => test_bugfix_status foo => 'outdated';

    subtest 'release status is not out-of-date'
        => test_release_status foo => undef;

    subtest 'add bugfix update' => sub {
        chdir $rel_repo->work_tree;
        run_cmd( 'checkout', '--bugfix' );
        my $result = run_cmd( 'update', 'foo' );
    };

    subtest 'repo branch "v0.1" status is correct' => sub {
        my $cmd;
        my %refs = repo_refs $rel_repo;
        isnt $refs{'refs/heads/v0.1'}, $refs{'refs/tags/v0.1.0'}, "we've moved past v0.1.0";
        $cmd = $rel_repo->command( checkout => 'v0.1' );
        $cmd->close;
        $cmd = $rel_repo->command( submodule => 'update', '--init' );
        $cmd->close;
        my @changes = last_commit $rel_repo;
        is scalar @changes, 1, 'only one change was made';
        is $changes[0]{path_src}, 'foo', 'only change is to the foo module';
        is $changes[0]{status}, 'M', 'foo was modified';
    };

    subtest 'repo branch "master" status is correct' => sub {
        my $cmd;
        $cmd = $rel_repo->command( checkout => 'master' );
        $cmd->close;
        my %refs = repo_refs $rel_repo;
        is $refs{'refs/heads/master'}, $refs{'refs/tags/v0.1.0'}, "we have not moved past v0.1.0";
    };

    subtest 'bugfix status is changed, not out-of-date'
        => test_bugfix_status foo => 'changed';

    subtest 'release status is still unchanged and up-to-date'
        => test_release_status foo => undef;
};

subtest 'update non-bugfix' => sub {
    run_cmd( 'checkout', 'master' );

    subtest 'add new module' => sub {
        chdir $rel_repo->work_tree;
        my $result = run_cmd( 'add', 'bar', 'file://' . $bar_repo->work_tree );
    };
    subtest 'release status is changed, not out-of-date'
        => test_release_status foo => undef, bar => 'changed';

    subtest 'bugfix status is same as it was'
        => test_bugfix_status foo => 'changed', bar => undef;
};

subtest 'bugfix release' => sub {
    # Only foo is released
    chdir $rel_repo->work_tree;
    run_cmd( 'checkout', '--bugfix' );
    my $result = run_cmd( 'commit' );
    run_cmd( 'push' );

    subtest 'release repository is correct'
        => test_repo_has_refs $rel_repo, branch => 'v0.1', tag => [qw( v0.1.0 v0.1.1 )];

    subtest 'module repository is correct' 
        => test_repo_has_refs $foo_repo, branch => 'v0.1', tag => [qw( v0.1.0 v0.1.1 )];

    subtest 'bugfix branch is clean'
        => test_bugfix_status foo => undef, bar => undef;

    subtest 'release branch is same as it was'
        => test_release_status foo => undef, bar => 'changed';
};

subtest 'second release' => sub {
    chdir $rel_repo->work_tree;
    run_cmd( 'checkout', 'master' );
    my $result = run_cmd( 'commit' );
    run_cmd( 'push' );

    subtest 'release repository is correct'
        => test_repo_has_refs $rel_repo,
            branch  => [qw( v0.1 v0.2 )],
            tag     => [qw( v0.1.0 v0.1.1 v0.2.0 )];

    subtest 'foo module repository is correct'
        => test_repo_has_refs $foo_repo,
            branch  => [qw( v0.1 v0.2 )],
            tag     => [qw( v0.1.0 v0.1.1 v0.2.0 )];

    subtest 'bar module repository is correct'
        => test_repo_has_refs $bar_repo,
            branch  => [qw( v0.2 )],
            tag     => [qw( v0.2.0 )];

    subtest 'module status is unchanged'
        => test_release_status foo => undef, bar => undef;
};

subtest 'deploy latest release' => sub {
    chdir $rel_root;
    my $result = run_cmd( 'deploy', catdir( $rel_root, 'test-release' ), '--version_prefix', 'v' );
    subtest 'deploy test-release-v0.2'
        => test_deploy 'test-release-v0.2',
            branch  => 'v0.2',
            tag     => 'v0.2.0';
};

subtest 'deploy first release as stable' => sub {
    chdir $rel_root;
    my $result = run_cmd( 'deploy', '--branch', 'v0.1', catdir( $rel_root, 'test-release' ), 'stable', '--version_prefix', 'v' );
    subtest 'deploy stable'
        => test_deploy 'stable',
            branch  => 'v0.1',
            tag     => 'v0.1.1';
};

subtest 'bugfix release: v0.2.1' => sub {
    # Foo has a bugfix
    my $cmd = $foo_repo->command( checkout => 'v0.2' );
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        fail "Could not checkout Foo 'v0.2'.\nSTDERR: " . $cmd->stderr;
    }
    write_file( $foo_readme, 'Foo version 2.1' );
    $foo_repo->run( add => $foo_readme );
    $foo_repo->run( commit => -m => 'Added bugfix' );
    $foo_repo->command( checkout => 'master' );

    subtest 'add bugfix update' => sub {
        chdir $rel_repo->work_tree;
        run_cmd( 'checkout', '--bugfix' );
        my $result = run_cmd( 'update', 'foo' );
    };

    subtest 'bugfix status is changed, not out-of-date'
        => test_bugfix_status foo => 'changed';

    subtest 'release status is unchanged'
        => test_release_status foo => undef, bar => undef;

    subtest 'stable deploy status is unchanged'
        => test_deploy_status 'stable', 'v0.1.1' => undef;
    subtest 'v0.2 deploy status is unchanged'
        => test_deploy_status 'test-release-v0.2', 'v0.2.0' => undef;

    subtest 'release v0.2.1' => sub {
        chdir $rel_repo->work_tree;
        run_cmd( 'checkout', '--bugfix' );
        my $result = run_cmd( 'commit' );
        run_cmd( 'push' );
    };

    subtest 'release repository is correct'
        => test_repo_has_refs $rel_repo,
            branch  => [qw( v0.1 v0.2 )],
            tag     => [qw( v0.1.0 v0.1.1 v0.2.0 v0.2.1 )];

    subtest 'foo module repository is correct'
        => test_repo_has_refs $foo_repo,
            branch  => [qw( v0.1 v0.2 )],
            tag     => [qw( v0.1.0 v0.1.1 v0.2.0 v0.2.1 )];

    subtest 'bugfix status is unchanged, not out-of-date'
        => test_bugfix_status foo => undef;

    subtest 'release status is unchanged'
        => test_release_status foo => undef, bar => undef;

    subtest 'stable deploy status is unchanged, not out-of-date'
        => test_deploy_status 'stable', 'v0.1.1' => undef;
    subtest 'v0.2 deploy status is unchanged, out-of-date'
        => test_deploy_status 'test-release-v0.2', 'v0.2.0' => 'v0.2.1';
};

subtest 'update deployment to v0.2.1' => sub {
    chdir catdir( $rel_root, 'test-release-v0.2' );
    my $result = run_cmd( 'pull' );
    subtest 'bugfix status is unchanged, not out-of-date'
        => test_bugfix_status foo => undef;
    subtest 'release status is unchanged'
        => test_release_status foo => undef, bar => undef;
    subtest 'stable deploy status is unchanged, not out-of-date'
        => test_deploy_status 'stable', 'v0.1.1' => undef;
    subtest 'v0.2 deploy status is changed, not out-of-date'
        => test_deploy_status 'test-release-v0.2', 'v0.2.1' => undef;
};

subtest 'deploy master for everything' => sub {
    # Add a dev change to foo
    my $cmd = $foo_repo->command( checkout => 'master' );
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        fail "Could not checkout Foo 'master'.\nSTDERR: " . $cmd->stderr;
    }
    write_file( $foo_readme, 'Foo version master' );
    $foo_repo->run( add => $foo_readme );
    $foo_repo->run( commit => -m => 'Added bugfix' );

    # Master deploy shows everything!
    chdir $rel_root;
    my $result = run_cmd( 'deploy', '--master', catdir( $rel_root, 'test-release' ), '--version_prefix', 'v' );
    my $sub_foo_readme = catfile( $rel_root, 'test-release-master', 'foo', 'README' );
    is read_file( $sub_foo_readme ), 'Foo version master', 'foo updated to master';
};

subtest 'update master for everything' => sub {
    # Add a dev change to bar
    my $cmd = $bar_repo->command( checkout => 'master' );
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        fail "Could not checkout Bar 'master'.\nSTDERR: " . $cmd->stderr;
    }
    write_file( $bar_readme, 'Bar version master' );
    $bar_repo->run( add => $bar_readme );
    $bar_repo->run( commit => -m => 'Added bugfix' );

    # Master update shows everything!
    chdir catdir( $rel_root, 'test-release-master' );
    my $result = run_cmd( 'pull', '--master' );
    my $sub_bar_readme = catfile( $rel_root, 'test-release-master', 'bar', 'README' );
    is read_file( $sub_bar_readme ), 'Bar version master', 'bar updated to master';
};

done_testing;
