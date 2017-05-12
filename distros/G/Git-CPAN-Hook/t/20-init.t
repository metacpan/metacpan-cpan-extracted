use strict;
use warnings;
use Test::More;
use Test::Git;
use File::Temp qw( tempdir );
use Git::CPAN::Hook;

has_git('1.5.1');

plan tests => my $tests;

# test routine
sub check_repo {     # does 5 tests
    my ( $dir, $commits ) = @_;
    my $r = eval { Git::Repository->new( work_tree => $dir ) };
    isa_ok( $r, 'Git::Repository' );

    is( $r->run(qw( config --bool cpan-hook.active )),
        'true', 'repository activated' );

    my @log = $r->run(qw( log --pretty=format:%H ));
    is( scalar @log, $commits, "$commits initial commit(s)" );

    my @refs = map { ( split / /, $_, 2 )[1] } $r->run(qw( show-ref ));
    is_deeply(
        \@refs,
        [qw( refs/heads/master refs/tags/empty )],
        'Only two refs: master & empty'
    );

    is( $r->run(qw( rev-list -1 empty )),
        $log[0], 'empty points to the first commit' );
}

#
# configuration for Git::CPAN::Hook
#

my $dir;

# init an empty directory
BEGIN { $tests += 5 }

$dir = tempdir( CLEANUP => 1 );
init($dir);
check_repo( $dir, 1 );

# init using @ARGV
BEGIN { $tests += 5 }
$dir = tempdir( CLEANUP => 1 );
{
    local @ARGV = $dir;
    init();
}
check_repo( $dir, 1 );

# local::lib may have installed some files already
BEGIN { $tests += 5 }

$dir = tempdir( CLEANUP => 1 );
open my $fh, '>', File::Spec->catfile( $dir, '.modulebuildrc' );
print $fh "install  --install_base  $dir\n";
close $fh;

init($dir);
check_repo( $dir, 2 );

# the repository may exist and have some commits already
BEGIN { $tests += 5 }
my $r = test_repository;
$dir = $r->work_tree;
open $fh, '>', File::Spec->catfile( $dir, 'TODO' );
print $fh "TODO List\n";
close $fh;
$r->run( commit => -m => "a TODO list" );

init($dir);
check_repo( $dir, 2 );

