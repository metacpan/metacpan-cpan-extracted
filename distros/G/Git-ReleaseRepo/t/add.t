
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

sub test_add {
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

subtest 'add a new module' => sub {
    my $new_mod = create_module_repo;
    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'add-new' );
    chdir $clone_repo->work_tree;
    run_cmd( 'add', 'new-mod', $new_mod->work_tree );
    subtest 'new module added' => test_add( $clone_repo, master => 'new-mod', '.gitmodules' );
};

subtest 'add with reference' => sub {
    my $new_mod = create_module_repo;

    # create reference
    chdir $clone_dir;
    my (@lines) = Git::Repository->run( clone => "file://" . $new_mod->work_tree, 'reference-mod' );

    my $clone_repo = create_clone( $clone_dir, $origin_repo, 'add-reference' );
    chdir $clone_repo->work_tree;
    run_cmd( 'add', 'reference-mod', $new_mod->work_tree, '--reference_root', $clone_dir );
    subtest 'new module added' => test_add( $clone_repo, master => 'reference-mod', '.gitmodules' );

    my $submodule_git = catfile( $clone_repo->git_dir, 'modules', 'reference-mod');
    ok -f catfile( $submodule_git, 'objects', 'info', 'alternates' ),
        "submodule has alternates reference";
};

chdir $cwd;

done_testing;
