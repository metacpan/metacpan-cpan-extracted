use strict;
use warnings;

use Test::More;

use Git::PurePerl;
use Path::Tiny qw/ tempdir path /;
use GitStore;

use lib 't/lib';
use Utils;

plan skip_all => 'Test needs Git::Repository'
    unless eval "use Git::Repository; 1";

plan tests => 3;

my $gs = new_gitstore();

my @bad_files = (
    '/oops', 
    '///naughty',
);

$gs->set( $_ => $_ ) for @bad_files;

$gs->commit;

subtest 'can retrieve' => sub {
    is $gs->get( $_ ) => $_, $_ for @bad_files;
};

my $clone_dir = tempdir( DIR => 't/stores' );
diag "cloning into $clone_dir";

Git::Repository->run( clone => path($gs->repo)->absolute->stringify, 
    $clone_dir->stringify );

subtest 'file exist in clone' => sub {
    ok path( $clone_dir, $_ )->exists, $_ for @bad_files;
};

$gs->delete($_) for @bad_files;
$gs->commit;

subtest 'not there anymore' => sub {
    is $gs->get($_) => undef, $_ for @bad_files;
};


