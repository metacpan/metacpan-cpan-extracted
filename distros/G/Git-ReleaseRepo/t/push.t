
use Test::Most;
use Cwd qw( getcwd );
use File::Temp;
use Test::Git;
use Git::ReleaseRepo::Test qw( run_cmd get_cmd_result create_module_repo repo_tags repo_branches 
                            create_clone repo_root commit_all last_commit current_branch repo_refs 
                            create_release_repo );
use File::Spec::Functions qw( catdir catfile );
use File::Slurp qw( write_file );
use Git::ReleaseRepo;

my $cwd = getcwd;
END { chdir $cwd };

# Set up
my $module_repo = create_module_repo( repo_root, 'module' );
my $module_readme = catfile( $module_repo->work_tree, 'README' );
my $origin_repo = create_release_repo( repo_root, 'origin',
    module => $module_repo,
);
$origin_repo->run( 'branch', 'safe' );
my $clone_dir = repo_root;

subtest 'push master and latest release branch' => sub {
    write_file( $module_readme, 'TEST ONE' );
    commit_all( $module_repo );

    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'push' );
    chdir $clone_repo->work_tree;
    run_cmd( update => 'module' );
    run_cmd( 'commit' );
    $origin_repo->run( 'checkout', 'safe' );
    run_cmd( 'push' );
    $origin_repo->run( 'checkout', 'master' );

    subtest 'origin repo should have the branch and tag' => sub {
        my @branches = repo_branches( $origin_repo );
        cmp_deeply \@branches, bag( 'v0.1', 'master', 'safe' );
        my @tags = repo_tags( $origin_repo );
        cmp_deeply \@tags, bag( 'v0.1.0' );
    };
    subtest 'module repo should have the branch and tag' => sub {
        my @branches = repo_branches( $module_repo );
        cmp_deeply \@branches, bag( 'v0.1', 'master' );
        my @tags = repo_tags( $module_repo );
        cmp_deeply \@tags, bag( 'v0.1.0' );
    };
};

subtest 'problem push, not fast-forward (module)' => sub {
    # Add a change to a module
    write_file( $module_readme, 'TEST TWO' );
    commit_all( $module_repo );

    # Add change to release
    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'not-ff' );
    chdir $clone_repo->work_tree;
    my $result = run_cmd( update => 'module' );
    $result = run_cmd( 'commit' );

    # Add another change to module
    write_file( $module_readme, 'TEST TWO A' );
    commit_all( $module_repo );

    # Try to push release
    chdir $clone_repo->work_tree;
    $origin_repo->run( 'checkout', 'safe' );
    $result = get_cmd_result( 'push' );
    $origin_repo->run( 'checkout', 'master' );
    isnt $result->exit_code, 0;
    like $result->error, qr{ERROR} or diag $result->error;
};

subtest 'problem push, not fast-forward (origin)' => sub {
    # Add a change to a module
    write_file( $module_readme, 'TEST THREE' );
    commit_all( $module_repo );

    # Add change to release
    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'not-ff-origin' );
    chdir $clone_repo->work_tree;
    my $result = run_cmd( update => 'module' );
    $result = run_cmd( 'commit' );

    # Add another change to module
    write_file( $module_readme, 'TEST THREE A' );
    commit_all( $module_repo );

    # Change should be in origin
    $origin_repo->run( checkout => 'master' );
    chdir $origin_repo->work_tree;
    $result = run_cmd( update => 'module' );
    $result = run_cmd( 'commit' );

    # Try to push release
    chdir $clone_repo->work_tree;
    $origin_repo->run( 'checkout', 'safe' );
    $result = get_cmd_result( 'push' );
    $origin_repo->run( 'checkout', 'master' );
    isnt $result->exit_code, 0;
    like $result->error, qr{ERROR} or diag $result->error;
};

chdir $cwd;

done_testing;
