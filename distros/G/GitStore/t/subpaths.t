use strict;
use warnings;

use Test::More;

use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

plan skip_all => 'Test needs Git::Repository'
    unless eval "use Git::Repository; 1";

plan tests => 2;

my $directory = 't/test';
dir($directory)->rmtree;

Git::PurePerl->init( directory => $directory );
my $gs = GitStore->new($directory);
$gs->set( 'one/two', "something else" );
$gs->commit( "from GS" );

chdir 't/test' or die;

$directory = '.';

my $gr = Git::Repository->new( work_tree => $directory );

$gr->run( 'reset' => '--hard' );

is file('one/two')->slurp => 'something else', 
    "Gitstore saves at the right place";

mkdir "$directory/foo";
open my $fh, '>', "$directory/foo/baz";
print $fh "stuff";
close $fh;

$gr->run( 'add', 'foo/baz' );
$gr->run( 'commit', '-m', 'adding foo/baz' );

$gs = GitStore->new($directory);
is $gs->get( 'foo/baz' ) => 'stuff' ;

