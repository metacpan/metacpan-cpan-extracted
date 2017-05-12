########################################################################
# housekeeping
########################################################################

package Testify;
use v5.20;
use lib qw( lib t/lib );

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
    splice_stack_tern
    splice_stack_add
    fp_explicit_tern
    fp_explicit_add
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

my $one_trial
= sub
{
    my ( $runs, $subref ) = splice @_, 0, 2;

    my $value   = 0;

    my $t0  = Benchmark->new();
    $value  = $subref->( @_ ) for ( 1.. $runs );
    my $t1  = Benchmark->new();

    my $t   = do{ timediff $t1, $t0 }->[0] / $runs;

    [
        unpack( 'H*' => $value ),
        $t
    ]
};

my $run_trials
= sub
{
    state $dummy = __PACKAGE__->can( 'dummy' );
    state $runs = 128;

    $runs /= 2
    if $runs > 8;

    my $count   = shift;
    my @stack   = map { sha256 $_ } ( 1 .. $count );

    my $base    = do { $one_trial->( 32, $dummy, @stack ) }->[1];

    my @trialz
    = map
    {
        $one_trial->( $runs, $_, @stack )
    }
    @subz;

    ( $base => @trialz )
};

########################################################################
# benchmark subs
########################################################################

sub dummy { return }

sub splice_stack_tern
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


sub splice_stack_add
{
    @_ > 1
    or return $_[0];

    my $count = @_ / 2;

    @_ =
    (
        (
            map { sha256 splice @_, 0, 2 }
            ( 1 .. $count )
        ),
        @_ % 2 ? shift : ()
    );

    goto __SUB__
}

sub fp_explicit_tern
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

sub fp_explicit_add
{
    @_  > 1 or return $_[0];
    @_ =
    (
        (
            map
            {
                my $i = 2 * $_;

                sha256 @_[ $i, $i + 1 ]
            }
            ( 0 .. @_ / 2 - 1 )
        ),
        @_ % 2 ? $_[-1] : ()
    );

    goto __SUB__
}

tree_fold tree_fold_block
{
    my $last    = @_ / 2 - 1;

    (
        (
            map
            {
                my $i   = 2 * $_;

                sha256 @_[ $i, 1 + $i ]
            }
            ( 0 .. $last )
        ),
        @_ % 2
        ? $_[-1]
        : ()
    )
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

for ( 1 .. 18 )
{
    state $base_fmt = "\t%-24s: %.10f\n";
    state $pass_fmt = "\t%-24s: %.6f\n";

    my $n       = 2 ** $_;

    my ( $base, @trialz ) = $run_trials->( $n );

    my $expect  = $trialz[0][0];

    is $trialz[$_][0], $expect, "$namz[0] == $namz[$_]"
    for ( 1 .. $#trialz );

    note "Stack count: $n";
    note sprintf $pass_fmt => Baseline => $base;

    note sprintf $pass_fmt => $namz[$_], $trialz[ $_ ][1] - $base
    for  0 .. $#trialz;
}

done_testing;

# this is not a module
0
__END__
