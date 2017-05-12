
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
my $clone_dir = repo_root;

subtest 'behind origin' => sub {
    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'behind' );

    subtest 'update origin' => sub {
        write_file( $module_readme, 'TEST ONE' );
        commit_all( $module_repo );

        chdir $origin_repo->work_tree;
        run_cmd( update => 'module' );
        run_cmd( 'commit' );
    };
    subtest 'checkout' => sub {
        chdir $clone_repo->work_tree;
        my $cmd = get_cmd_result( 'checkout', 'master' );
        like $cmd->stdout, qr{git release pull}, 'tells user what to do';
    };
};

#subtest 'ahead of origin' => sub {
#    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'ahead' );

#    subtest 'update clone' => sub {
#        write_file( $module_readme, 'TEST TWO' );
#        $module_repo->run( add => $module_readme );
#        $module_repo->run( 'commit', -m => 'test two' );

#        chdir $clone_repo->work_tree;
#        run_cmd( update => 'module' );
#        run_cmd( 'commit' );
#    };
#    subtest 'checkout' => sub {
#        chdir $clone_repo->work_tree;
#        my $cmd = get_cmd_result( 'checkout', 'master' );
#        like $cmd->stdout, qr{git release push}, 'tells user what to do';
#    };
#    $origin_repo->run( 'submodule', 'update', '--init' );
#};

chdir $cwd;

done_testing;
