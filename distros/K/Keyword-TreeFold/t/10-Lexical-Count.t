########################################################################
# housekeeping
########################################################################

package Testify;
use v5.20;
use FindBin::libs;

use Test::More;

use Keyword::TreeFold;

use Digest::SHA qw( sha256  );

########################################################################
# package variables
########################################################################

my @stack   = map { sha256 $_ } ( 1 .. 9 );

my @subz
= qw
(
    tree_fold_0_lexicals
    tree_fold_2_lexicals
);

########################################################################
# utility subs
########################################################################

########################################################################
# benchmark subs
########################################################################

tree_fold tree_fold_0_lexicals ()
{
    my $last    = @_ / 2 - 1;

    (
        (
            map
            {
                sha256 @_[ $_, 1 + $_ ]
            }
            map
            {
                2 * $_;
            }
            ( 0 .. $last )
        ),
        @_ % 2
        ? $_[-1]
        : ()
    )
}

tree_fold tree_fold_2_lexicals ( $left, $rite )
{
    $rite
    ? sha256 $left, $rite
    : $left
}

########################################################################
# buffer tests
########################################################################

my @valz
= map
{
    eval { unpack 'H*' => __PACKAGE__->can( $_ )->( @stack ) }
}
@subz;

note "Extracted values:\n", explain \@valz;

is $valz[0], $valz[1], 'Matching values.';

done_testing;

# this is not a module
0
__END__
