#!perl -w
use strict;
use Test::More tests => 10;
use File::Path qw( rmtree );

if (eval { require Test::Differences; 1 }) {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}


my $path = 't/sample';
my $tree = {
    subdir => {},
    file   => 'this is a test file',
};

use_ok qw( File::Slurp::Tree );

eval { rmtree( $path ) };
ok( !-e $path, "no $path at start" );
ok( spew_tree( $path => $tree ), "spewed a tree" );

ok( -e $path, "now a $path" );
ok( -e "$path/file", "there's a file");
is( -s "$path/file", length $tree->{file}, " of the right size" );

ok( -e "$path/subdir", "and a subdirectory" );
is_deeply( [ <$path/subdir/*> ], [], " which is empty" );

is_deeply( slurp_tree( $path ),    $tree, "and slurping works" );
is_deeply( slurp_tree( "$path/" ), $tree, "and slurping works, even with a trailing slash" );
