
use Test::Most;
use Cwd qw( getcwd );
use File::Temp;
use Test::Git;
use Git::ReleaseRepo::Test qw( run_cmd get_cmd_result create_module_repo repo_tags repo_branches
                            create_clone repo_root commit_all last_commit current_branch repo_refs
                            create_release_repo );
use File::Spec::Functions qw( catdir catfile );
use File::Slurp qw( write_file );
use File::Basename qw( basename );
use Git::ReleaseRepo;
use YAML qw( LoadFile );

my $cwd = getcwd;
END { chdir $cwd };

# Set up
my $module_repo = create_module_repo( repo_root, 'module' );
my $module_readme = catfile( $module_repo->work_tree, 'README' );
my $other_repo = create_module_repo( repo_root, 'other' );
my $other_readme = catfile( $other_repo->work_tree, 'README' );
my $origin_repo = create_release_repo( repo_root, 'origin',
    module => $module_repo,
    other => $other_repo,
);
our $clone_dir = repo_root;

sub test_clone($$$$) {
    my ( $dir, $name, $modules, $expect_conf ) = @_;
    return sub {
        ok -d catdir( $dir, $name ), 'dir is named correctly';
        subtest 'submodules are initialized' => sub {
            for my $mod ( @$modules ) {
                ok -f catfile( $dir, $name, $mod, 'README' ), "submodule '$mod' is initialized";
            }
        };
        my $conf_file = catfile( $clone_dir, $name, '.git', 'release' );
        ok -f $conf_file, 'config file exists';

        my $conf = LoadFile( $conf_file );
        cmp_deeply $conf, $expect_conf, 'config is complete and correct';
    };
}

subtest 'clone' => sub {
    chdir $clone_dir;
    run_cmd( 'clone', 'file://' . $origin_repo->work_tree, 'clone', '--version_prefix', 'v' );
    subtest 'relative clone is correct'
        => test_clone $clone_dir, 'origin', [qw( module other )], { version_prefix => 'v' };
    chdir $cwd;

    my $name = 'custom-clone';
    my $directory = catfile( $clone_dir, $name );
    run_cmd( 'clone', 'file://' . $origin_repo->work_tree, $directory, '--version_prefix', 'v' );
    subtest 'absolute clone is correct'
        => test_clone $clone_dir, $name, [qw( module other )], { version_prefix => 'v' };
};

subtest 'clone with reference' => sub {
    chdir $clone_dir;
    run_cmd( 'clone', 'file://' . $origin_repo->work_tree, 'referencing', '--reference_root', $clone_dir, '--version_prefix', 'v' );
    subtest 'clone is correct'
        => test_clone $clone_dir, 'referencing', [qw( module other )], { version_prefix => 'v' };
    for my $mod (qw( module other )) {
        my $submodule_git = catfile( $clone_dir, 'referencing', '.git', 'modules', $mod);
        ok -f catfile( $submodule_git, 'objects', 'info', 'alternates' ),
            "submodule '$mod' has alternates reference";
    }
    chdir $cwd;
};

subtest 'error without version_prefix' => sub {
    my ( $code, $stdout, $stderr ) = get_cmd_result( 'clone', 'file://' . $origin_repo->work_tree, 'error' );
    isnt $code, 0, 'error without version_prefix';
};

subtest 'error with too many arguments' => sub {
    my ( $code, $stdout, $stderr ) = get_cmd_result( 'clone', 'file://' . $origin_repo->work_tree, 'error', 'yay' );
    isnt $code, 0, 'error with too many arguments';
};

subtest 'error with not enough arguments' => sub {
    my ( $code, $stdout, $stderr ) = get_cmd_result( 'clone' );
    isnt $code, 0, 'error with not enough arguments';
};

subtest 'default directory' => sub {
    # drop down one dir to avoid cloning over origin
    local $clone_dir = catdir( $clone_dir, 'default' );
    mkdir $clone_dir;

    chdir $clone_dir;
    my $name = basename( $origin_repo->work_tree );
    run_cmd( 'clone', 'file://' . $origin_repo->work_tree, '--version_prefix', 'v' );
    subtest 'clone is correct'
        => test_clone $clone_dir, $name, [qw( module other )], { version_prefix => 'v' };
    chdir $cwd;
};

subtest 'clone after release' => sub {
    my $module_repo = create_module_repo( repo_root, 'module_release' );
    my $module_readme = catfile( $module_repo->work_tree, 'README' );
    my $origin_repo = create_release_repo( repo_root, 'origin_release',
        module_release => $module_repo,
    );
    chdir $origin_repo->work_tree;
    run_cmd( 'commit' );
    run_cmd( 'push' );

    chdir $clone_dir;
    run_cmd( 'clone', 'file://' . $origin_repo->work_tree, 'after_release', '--version_prefix', 'v' );
    subtest 'relative clone is correct'
        => test_clone $clone_dir, 'after_release', [qw( module_release )], { version_prefix => 'v' };

    subtest 'status in newly-cloned repository' => sub {
        chdir catdir( $clone_dir, 'after_release' );
        my $result = run_cmd( 'status' );
        eq_or_diff $result->stdout, "Changes since v0.1\n------------------\n";
    };

    subtest 'checkout bugfix branch' => sub {
        chdir catdir( $clone_dir, 'after_release' );
        run_cmd( 'checkout', '--bugfix' );

        my $repo = Git::Repository->new( work_tree => catdir( $clone_dir, 'after_release' ) );
        is $repo->current_branch, 'v0.1';
    };

    subtest 'bugfix status in newly-cloned repository' => sub {
        chdir catdir( $clone_dir, 'after_release' );
        my $result = run_cmd( 'status' );
        eq_or_diff $result->stdout, "Changes since v0.1.0\n--------------------\n";
    };

    subtest 'release and push bugfix' => sub {
        chdir catdir( $clone_dir, 'after_release' );
        run_cmd( 'commit' );

        my $repo = Git::Repository->new( work_tree => catdir( $clone_dir, 'after_release' ) );
        $repo->release_prefix( 'v' );
        is $repo->current_branch, 'v0.1';
        cmp_deeply [ $repo->list_versions ], bag( 'v0.1.1', 'v0.1.0' );

        run_cmd( 'push' );
        my $origin = Git::Repository->new( work_tree => catdir( $clone_dir, 'origin_release' ) );
        $origin->release_prefix( 'v' );
        cmp_deeply [ $origin->list_versions ], bag( 'v0.1.1', 'v0.1.0' );
    };

    subtest 'status in newly-released repository' => sub {
        chdir catdir( $clone_dir, 'after_release' );
        run_cmd( 'checkout', 'master' );
        my $result = run_cmd( 'status' );
        eq_or_diff $result->stdout, "Changes since v0.1\n------------------\n";
    };

    subtest 'bugfix status in newly-cloned repository' => sub {
        chdir catdir( $clone_dir, 'after_release' );
        run_cmd( 'checkout', '--bugfix' );
        my $result = run_cmd( 'status' );
        eq_or_diff $result->stdout, "Changes since v0.1.1\n--------------------\n";
    };


    chdir $cwd;
};


done_testing;
