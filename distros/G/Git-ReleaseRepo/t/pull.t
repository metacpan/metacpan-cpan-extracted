
use Test::Most;
use Cwd qw( getcwd );
use File::Temp;
use Test::Git;
use Git::ReleaseRepo::Test qw( run_cmd get_cmd_result create_module_repo repo_tags repo_branches 
                            create_clone repo_root commit_all last_commit current_branch repo_refs 
                            create_release_repo );
use File::Spec::Functions qw( catdir catfile );
use File::Slurp qw( read_file write_file );
use File::Basename qw( basename );
use Git::ReleaseRepo;
use YAML qw( LoadFile );

my $cwd = getcwd;
END { chdir $cwd };

# Set up
subtest pull => sub {
    my $module_repo = create_module_repo( repo_root, 'pull-module' );
    my $module_readme = catfile( $module_repo->work_tree, 'README' );
    my $other_repo = create_module_repo( repo_root, 'pull-other' );
    my $other_readme = catfile( $other_repo->work_tree, 'README' );
    my $origin_repo = create_release_repo( repo_root, 'pull-origin',
        'pull-module' => $module_repo,
        'pull-other' => $other_repo,
    );
    my $clone_dir = repo_root;
    my $deploy_repo;
    subtest setup => sub {
        chdir $origin_repo->work_tree;
        run_cmd( 'commit' );
        run_cmd( 'push' );

        # First deploy
        chdir $clone_dir;
        run_cmd( 'deploy', 'file://' . $origin_repo->work_tree, 'pull-deploy', '--version_prefix', 'v' );
        $deploy_repo = Git::Repository->new( work_tree => catdir( $clone_dir, 'pull-deploy' ) );

        # Then release a new bugfix
        $module_repo->run( checkout => 'v0.1' );
        write_file( $module_readme, 'BUGFIX' );
        commit_all( $module_repo );
        $module_repo->run( checkout => 'master' );
        chdir $origin_repo->work_tree;
        run_cmd( 'checkout', '--bugfix' );
        run_cmd( 'pull' );
        run_cmd( 'update', '-a' );
        run_cmd( 'commit' );
        run_cmd( 'push' );

        # Also add another bugfix, not part of the release
        $other_repo->run( checkout => 'v0.1' );
        write_file( $other_readme, 'BUGFIX OTHER' );
        commit_all( $other_repo );
        $other_repo->run( checkout => 'master' );
        chdir $origin_repo->work_tree;
        run_cmd( 'checkout', '--bugfix' );
        run_cmd( 'update', '-a' );
    };
    subtest pull => sub {
        chdir $deploy_repo->work_tree;
        run_cmd( 'pull' );
        is read_file( catfile( $deploy_repo->work_tree, 'pull-module', 'README' ) ), 'BUGFIX';
        isnt read_file( catfile( $deploy_repo->work_tree, 'pull-other', 'README' ) ), 'BUGFIX OTHER';
    };
};


chdir $cwd;

done_testing;
