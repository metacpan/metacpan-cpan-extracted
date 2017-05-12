
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
my $other_repo = create_module_repo( repo_root, 'other' );
my $other_readme = catfile( $other_repo->work_tree, 'README' );
my $origin_repo = create_release_repo( repo_root, 'origin',
    module => $module_repo,
    other => $other_repo,
);
my $clone_dir = repo_root;

sub test_update {
    my ( $repo, $branch, @modules ) = @_;
    return sub {
        # A commit has happened
        my @changes = last_commit $repo;
        # The commit contained only what we want
        cmp_deeply [ map { $_->{path_src} } @changes ], bag(@modules), 'expected changes' or diag explain \@changes;
        # We have not changed branches
        is current_branch( $repo ), $branch, 'still on same branch';
        # We have not pushed
        my %refs = repo_refs $repo;
        isnt $refs{'refs/heads/' . $branch }, $refs{'refs/remotes/origin/' .  $branch }, 'not pushed';
        # Modules are on the same branch
        for my $mod ( @modules ) {
            next unless -d catdir( $repo->work_tree, $mod );
            my $mod_repo = Git::Repository->new( work_tree => catdir( $repo->work_tree, $mod ) );
            is current_branch( $mod_repo ), $branch, "module repo $mod is $branch";
        }
    };
}

subtest 'update an existing module' => sub {
    write_file( $module_readme, "ADD EXISTING" );
    commit_all( $module_repo );

    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'add-existing' );
    chdir $clone_repo->work_tree;
    run_cmd( 'update', 'module' );

    subtest 'existing module added' => test_update( $clone_repo, master => 'module' );
};

subtest 'update all' => sub {
    write_file( $module_readme, "Add all" );
    commit_all( $module_repo );
    write_file( $other_readme, "Add all" );
    commit_all( $other_repo );
    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'add-all' );
    chdir $clone_repo->work_tree;
    run_cmd( 'update', '-a' );
    subtest 'all existing modules updated' => test_update( $clone_repo, master => 'module', 'other' );
};

chdir $cwd;

done_testing;
