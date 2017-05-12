########################################################################
# housekeeping
########################################################################

package Testify;
use v5.20;
use FindBin::libs;

use Test::More;

use Keyword::TreeFold;

use Digest::SHA qw( sha256  );
use Benchmark   qw( :hireswallclock );

########################################################################
# package variables
########################################################################

my @namz 
= qw
(
    splice_stack_0
    splice_stack_1
    fp_explicit
    tree_fold_block
    tree_fold_lexicals
);

my @subz
= map
{
    __PACKAGE__->can( $_ )
    or BAIL_OUT "Bogus test: unknown '$_'";
}
@namz;

########################################################################
# utility subs
########################################################################

sub one_trial
{
    my $subref  = shift;
}

########################################################################
# benchmark subs
########################################################################

sub splice_stack_0
{
    @_ > 1
    or return $_[0];

    my $count = @_ / 2 + @_ % 2;

    @_
    = map
    {
        @_ > 1
        ? sha256 splice @_, 0, 2
        : $_[0]
    }
    ( 1 .. $count );

    goto __SUB__
}

sub splice_stack_1
{
    @_ > 1
    or return $_[0];

    @_ = 
    (
        (
            map
            {
                sha256 splice @_, 0, 2
            }
            ( 1 .. @_ / 2 )
        ),
        @_ % 2 ? shift : ()
    );

    goto __SUB__
}


sub fp_explicit
{
    @_  > 1 or return $_[0];

    my $last
    = @_ % 2
    ? @_ / 2
    : @_ / 2 - 1
    ;

    @_
    = map
    {
        my $i = 2 * $_;

        $_[ $i + 1 ]
        ? sha256 @_[ $i, $i + 1 ]
        : $_[ $i ]
    }
    ( 0 .. $last );

    goto __SUB__
}

tree_fold tree_fold_block
{
    my $last
    = @_ % 2
    ? @_ / 2
    : @_ / 2 - 1
    ;

    map
    {
        my $i   = 2 * $_;

        $_[ 1 + $i ]
        ? sha256 @_[ $i, 1 + $i ]
        : $_[ $i ]
    }
    ( 0 .. $last )
}

tree_fold tree_fold_lexicals ( $left, $rite )
{
    $rite
    ? sha256 $left, $rite
    : $left
}

########################################################################
# buffer tests
########################################################################

for my $n ( 1 .. 20 )
{
    my @stack   = map { sha256 $_ } ( 1 .. $n );

    my @valz    
    = map 
    {
        unpack 'H*' => $_->( @stack )
    }
    @subz;

    my $expect  = $valz[0];

    note "Expected value: $expect";

    is $valz[$_], $expect, "$namz[0] == $namz[$_]"
    for ( 1 .. $#valz );
}

done_testing;

# this is not a module
0
__END__
