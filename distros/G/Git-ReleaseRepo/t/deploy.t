
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
subtest setup => sub {
    chdir $origin_repo->work_tree;
    run_cmd( 'commit' );
};
my $clone_dir = repo_root;

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

subtest 'deploy' => sub {
    chdir $clone_dir;
    run_cmd( 'deploy', 'file://' . $origin_repo->work_tree, 'deploy', '--version_prefix', 'v' );
    subtest 'relative deploy is correct'
        => test_clone $clone_dir, 'deploy', [qw( module other )], { track => 'v0.1', version_prefix => 'v' };
    chdir $cwd;

    my $name = 'prd-deploy';
    my $directory = catfile( $clone_dir, $name );
    run_cmd( 'deploy', 'file://' . $origin_repo->work_tree, $directory, '--version_prefix', 'v' );
    subtest 'absolute deploy is correct'
        => test_clone $clone_dir, $name, [qw( module other )], { track => 'v0.1', version_prefix => 'v' };
};

subtest 'deploy with reference' => sub {
    chdir $clone_dir;
    run_cmd( 'deploy', 'file://' . $origin_repo->work_tree, 'referencing', '--reference_root', $clone_dir, '--version_prefix', 'v' );
    subtest 'deploy is correct'
        => test_clone $clone_dir, 'referencing', [qw( module other )], { track => 'v0.1', version_prefix => 'v' };
    for my $mod (qw( module other )) {
        my $submodule_git = catfile( $clone_dir, 'referencing', '.git', 'modules', $mod);
        ok -f catfile( $submodule_git, 'objects', 'info', 'alternates' ),
            "submodule '$mod' has alternates reference";
    }
    chdir $cwd;
};

subtest 'error without version_prefix' => sub {
    my ( $code, $stdout, $stderr ) = get_cmd_result( 'deploy', 'file://' . $origin_repo->work_tree, 'error' );
    isnt $code, 0, 'error without version_prefix';
};

subtest 'error with too many arguments' => sub {
    my ( $code, $stdout, $stderr ) = get_cmd_result( 'deploy', 'file://' . $origin_repo->work_tree, 'error', 'yay' );
    isnt $code, 0, 'error with too many arguments';
};

subtest 'error with not enough arguments' => sub {
    my ( $code, $stdout, $stderr ) = get_cmd_result( 'deploy' );
    isnt $code, 0, 'error with not enough arguments';
};

subtest 'default directory' => sub {
    chdir $clone_dir;
    my $name = basename( $origin_repo->work_tree ) . '-v0.1';
    run_cmd( 'deploy', 'file://' . $origin_repo->work_tree, '--version_prefix', 'v' );
    subtest 'deploy is correct'
        => test_clone $clone_dir, $name, [qw( module other )], { track => 'v0.1', version_prefix => 'v' };
    chdir $cwd;
};

done_testing;
