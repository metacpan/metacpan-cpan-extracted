package Testophile;

use v5.8;
use lib;

use Test::More;

my $madness = 'FindBin::Parents';
my @importz
= qw
(
    dir_paths
    clear_parent_cache
);

my $path    = '/foo/bar/bletch';
my $expect =
[
    qw
    (
        /foo/bar/bletch
        /foo/bar
        /foo
        /
    )
];

note "INC is:\n" => explain \@INC;

use_ok $madness => $_
for @importz;

ok __PACKAGE__->can( $_ ), "$madness exports $_"
for @importz;

SKIP:
{
    if( my @found = clear_parent_cache() )
    {
        fail 'clear_cached_parents returns data:';
        diag explain \@found;
    }
    else
    {
        pass 'clear_cached_parents returns empty.';
    }

    if( my @found = dir_paths( $path ) )
    {
        is_deeply \@found, $expect, "Parents of '/foo/bar/bletch'";
    }
    else
    {
        BAIL_OUT "parent_dirs returns empty list for /foo/bar/bletch";
    }

    if( my $found = dir_paths( $path ) )
    {
        is_deeply $found, $expect, "Parents of '/foo/bar/bletch'";
    }
    else
    {
        BAIL_OUT "parent_dirs returns empty scalar for /foo/bar/bletch";
    }

    shift @$expect;

    if( my @found = dir_paths( $path, '' ) )
    {
        is_deeply \@found, $expect, "Parents of '/foo/bar/bletch', ''";
    }
    else
    {
        fail 'Non-matching paths.';
        diag
          , "Expect:\n", explain \@expect
          , "Found:\n" , explain \@found
          ;
    }

    if( my $found = dir_paths( $path, '' ) )
    {
        is_deeply $found, $expect, "Parents of '/foo/bar/bletch', ''";
    }
    else
    {
        fail "Non-matching paths.";
        diag
          , "Expect:\n", explain \@expect
          , "Found:\n" , explain \@found
          ;
    }
}

done_testing;

__END__
