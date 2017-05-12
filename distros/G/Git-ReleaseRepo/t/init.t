
use strict;
use warnings;
use Test::Most;
use Test::Git;
use Cwd qw( getcwd );
my $CWD = getcwd;
END {
    chdir $CWD;
};
use File::Spec::Functions qw( catfile );
use YAML qw( LoadFile );
use File::Slurp qw( write_file );
use Git::ReleaseRepo;
use Git::ReleaseRepo::Test qw( run_cmd get_cmd_result );

sub make_repo(%) {
    my ( %files ) = @_;
    my $foo_repo = test_repository;
    for my $file ( keys %files ) {
        my $foo_file = catfile( $foo_repo->work_tree, $file );
        write_file( $foo_file, $files{$file} );
        $foo_repo->run( add => $foo_file );
        $foo_repo->run( commit => -m => "Added $file" );
    }
    return $foo_repo;
}

subtest 'works with an existing repo' => sub {
    my $foo_repo = make_repo README => 'Foo readme 0.0';
    chdir $foo_repo->work_tree;
    run_cmd( 'init', '--version_prefix', 'v' );
    ok -f catfile( $foo_repo->git_dir, 'release' ), 'config file created';
    my $config = LoadFile( catfile( $foo_repo->git_dir, 'release' ) );
    cmp_deeply $config, {
        version_prefix => 'v',
    }, 'config is complete and correct';
};

subtest 'works with a new repo' => sub {
    my $foo_repo = make_repo;
    chdir $foo_repo->work_tree;
    run_cmd( 'init', '--version_prefix', 'v' );
    ok -f catfile( $foo_repo->git_dir, 'release' ), 'config file created';
    my $config = LoadFile( catfile( $foo_repo->git_dir, 'release' ) );
    cmp_deeply $config, {
        version_prefix => 'v',
    }, 'config is complete and correct';
};

subtest 'requires a version_prefix' => sub {
    my $foo_repo = make_repo README => 'Foo readme 0.0';
    chdir $foo_repo->work_tree;
    my $result = get_cmd_result( 'init' );
    ok $result->error;
    isnt $result->exit_code, 0;
};

subtest 'cannot initialize twice' => sub {
    my $foo_repo = make_repo README => 'Foo readme 0.0';
    chdir $foo_repo->work_tree;
    run_cmd( 'init', '--version_prefix', 'v' );
    my $result = get_cmd_result( 'init', '--version_prefix', 'v' );
    ok $result->error;
    isnt $result->exit_code, 0;
};

done_testing;
