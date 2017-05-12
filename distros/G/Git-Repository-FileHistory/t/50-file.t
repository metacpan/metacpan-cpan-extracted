use strict;
use warnings;
use Test::More;
use Test::Git;
use Test::Requires::Git;

use File::Temp qw/tempdir/;
use File::Spec;
use Cwd qw/cwd abs_path/;
use Git::Repository;

test_requires_git '1.5.0';

delete @ENV{qw/ GIT_DIR GIT_WORK_TREE /};

my $r       = test_repository;
my $dir     = $r->work_tree;
my $gitdir  = $r->git_dir;

# some test data
my %commit = (
    1 => {
        tree    => 'df2b8fc99e1c1d4dbc0a854d9f72157f1d6ea078',
        parent  => [],
        subject => 'empty file',
        body    => '',
        extra   => '',
    },
    2 => {
        tree    => '6820ead72140bd33a7a821965a05f9a1e89bf3c8',
        parent  => [],
        subject => 'one line',
        body    => "of data\n",
        extra   => '',
    },
);

use_ok( 'Git::Repository::FileHistory' );

# create an empty file and commit it
my $file = File::Spec->catfile( $dir, 'file' );
do { open my $fh, '>', $file; };
$r->run( add => 'file' );

eval {
    $r->run( commit => '-m', $commit{1}{subject} );
};
my $err = $@;
if ($err =~ /fatal: unable to auto-detect email address/) {
    note 'git error';
    done_testing; exit;
}

my $git_file = Git::Repository::FileHistory->new($r, 'file');

ok( $git_file->created_at - time() < 60 , 'created_at');
ok( $git_file->created_at == $git_file->last_modified_at , 'last_modified_at');
ok( $git_file->updated_at == $git_file->last_modified_at , 'updated_at');

my @logs = $git_file->logs;
ok( @logs == 1 );
ok( $_->isa('Git::Repository::Log'), 'log is Git::Repository::Log') for @logs;

sleep 1;

do { open my $fh, '>', $file; print $fh 'line 1'; };
$r->run( add => 'file' );
$r->run( commit => '-m', "$commit{2}{subject}\n\n$commit{2}{body}" );
my $git_file2 = Git::Repository::FileHistory->new($r, 'file');

ok( $git_file->created_at == $git_file2->created_at , 'created_at');
ok( $git_file2->created_at != $git_file2->last_modified_at , 'last_modified_at');
ok( $git_file->updated_at == $git_file->last_modified_at , 'updated_at');

@logs = $git_file2->logs;
ok( @logs == 2 );
ok( $_->isa('Git::Repository::Log'), 'log is Git::Repository::Log') for @logs;

done_testing;
