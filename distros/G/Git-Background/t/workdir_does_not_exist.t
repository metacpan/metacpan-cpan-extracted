#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use Git::Background 0.003;

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

note('workdir does not exist');
my $dir = tempdir();

my $obj = Git::Background->new( File::Spec->catdir( $dir, 'no_such_directory' ), { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background', 'new returned object' );

my $f = $obj->run;
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );

my ( undef, $category, undef, undef, $rc ) = $f->failure;
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );
is( $category, 'Proc::Background', 'error contains correct category' );
ok( !defined $rc, 'return code is not defined' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
