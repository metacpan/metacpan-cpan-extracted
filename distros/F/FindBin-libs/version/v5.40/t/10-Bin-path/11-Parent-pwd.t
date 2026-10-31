package Testophile;

use v5.40;
use lib;

use Test::More;

my $madness = 'FindBin::Parents';
my @importz
= qw
(
    dir_paths
    clear_parent_cache
);

use_ok $madness => @importz;
can_ok __PACKAGE__, $_ for @importz;

SKIP:
{
    # FindBin::Bin is already loaded as a dependency of FindBin::Parents.
    # pwd() caches the startup CWD via a state variable (like "pwd -L").
    # Calling it by full package name avoids a compile-time 'use' that
    # would fail when the lib is not yet in @INC during 'perl -wc'.

    my $cwd = FindBin::Bin::pwd();

    my @via_sentinel;

    if( @via_sentinel = dir_paths( 'pwd' ) )
    {
        ok 1, "'pwd' sentinel returns a list";
    }
    else
    {
        BAIL_OUT "'pwd' sentinel returns empty list";
    }

    is $via_sentinel[0], $cwd,
        "first element is FindBin::Bin::pwd()";

    # scalar context returns the same content as an arrayref

    my $ref_sentinel;

    if( $ref_sentinel = dir_paths( 'pwd' ) )
    {
        is_deeply $ref_sentinel, \@via_sentinel,
            "scalar context returns arrayref matching list context";
    }
    else
    {
        BAIL_OUT "'pwd' sentinel returns false in scalar context";
    }

    # sentinel must be equivalent to passing pwd() as a literal path

    my @via_call = dir_paths( $cwd );

    is_deeply \@via_sentinel, \@via_call,
        "'pwd' sentinel matches dir_paths( pwd() )";

    # clear_parent_cache resets the dir_paths memo-table but does not
    # affect pwd() (which uses a state variable).  Result must be stable.

    clear_parent_cache();

    my @after_clear = dir_paths( 'pwd' );

    is_deeply \@after_clear, \@via_sentinel,
        "result is stable after clear_parent_cache";

    is $after_clear[0], $cwd,
        "first element still equals FindBin::Bin::pwd() after clear";
}

done_testing;

__END__
