########################################################################
# housekeeping
########################################################################

package Keyword::TreeFold v0.1.1;
use v5.20;

use Keyword::Declare;

########################################################################
# package variables
########################################################################
########################################################################
# utility subs
########################################################################

sub simple_code
{
    my $list_op = shift;
    my $size    = @_;

    qq|\@_ = \ndo $list_op;\n|
}

sub lexical_code
{
    my ( $list_op, @varz ) = @_;

    my $count   = @varz;
    my $offset  = $count - 1;
    my $lexical = join ',' => @varz;

qq
|
    my \$last   
    = \@_ % $count
    ? int( \@_ / $count )
    : int( \@_ / $count ) - 1
    ;

    \@_
    = map
    {
        my ( $lexical ) = \@_[ \$_ .. \$_ + $offset ];

        do
######
$list_op
######
    }
    map
    {
        \$_ * $count
    }
    ( 0 .. \$last );
|

}

sub boilerplate
{
    my ( $name, $guts ) = @_;

    <<"SUBDEF"
sub $name
{
    use Carp qw( croak );

    \@_ > 1 or return \$_[0];

    my \$size = \@_;

    $guts

    croak "Stack not shrinking: \$size elements."
    unless \@_ < \$size;

    goto __SUB__
}
SUBDEF
}

########################################################################
# delcare keywords
########################################################################

sub import
{
    keyword tree_fold( Ident $name, List $argz, Block $list_op )
    {
        my @varz
        = map
        {
            $_->isa( 'PPI::Token::Symbol' )
            ? $_->{ content }
            : ()
        }
        map
        {
            $_->isa( 'PPI::Statement::Expression' )
            ? @{ $_->{ children } }
            : ()
        }
        @{ $argz->{ children } };

        if( @varz > 1 )
        {
            boilerplate $name, lexical_code "$list_op", @varz
        }
        elsif( @varz )
        {
            die
            "Bogus tree_fold: '$name' with single variable '$varz[0]'.";
        }
        else
        {
            boilerplate $name, simple_code  "$list_op"
        }
    }

    keyword tree_fold( Ident $name, Block $list_op )
    {
        boilerplate $name, simple_code  "$list_op";
    }
}

1
__END__

=head1 NAME

Keyword::Treefold - Add keyword for an FP tree-fold.

=head1 SYNOPSIS

    use Keyword::TreeFold;

    # result of block is assigned to @_ while @_ > 1.
    # block consumes the stack.

    tree_fold tree_hash
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

    # same result as above with wrapper code extracting the
    # lexical variables. block can extract any number of 
    # variables > 1.

    tree_fold tree_hash ( $left, $rite )
    {
        $rite
        ? sha256 $left, $rite
        : $left
    }

    # in all cases an exception will be raised if the stack does
    # not shrink after each iteration (e.g., if a block with two
    # parameters outputs two values for each iteration).

=head1 DESCRIPTION

The "fold" pattern is common in FP languages. It is commonly seen
as a "Right Fold" in the form of reduce, which takes a single value
and iterates it with the stack to form a single value (e.g., with
an addition to get a sum). A recursive solution to reduce combines
the first two items from the stack (e.g., by adding them) and then
calls itself with the result and the remaining stack. This chews
through the stack one item at a time.

Tree Fold is a bit different in that it iterates the entire stack
each time before recursing. For example the AWS "tree hash" used
with Glacier uploads does an SHA of every pair of items on the 
stack then recurses a new stack half the size.

One issue with the recursive solution is consuming a huge amount
of stack. The solution to this is tail call elimination, which is a
built-in part of most FP lanuages. While quite doable in Perl5 the
fix is somewhat ugly, requiring an assignment to @_ and use of goto
to restart the current subroutine recycling the stack.

This module implements a tree_fold keyword which wraps the input
block in code that checks the scak, re-assigns @_, and uses goto
to recurse. This avoids the overhad of multiple stack frames with 
minimal overhead.

=head2 Simple Blocks

If the block using tree_fold does not include any parameters it
gets wrapped in code like:

    sub $name
    {
        @_ > 1 or return $_[0];

        @_ = do { code block };

        goto __SUB__
    }


In this case it is up to the block to consume @_ for itself. For
example, the glacier tree hash might look like:

    tree_fold glacier_hash
    {
        my $count
        = @_ % 2
        ? @_ / 2 + 1
        : @_ / 2
        ;
        
        map
        {
            @_ > 1
            ? sha256 splice @_, 0, 2
            : shift
        }
        ( 1 .. $count )
    }

which will convert the current stack into a set of SHA256 values for
each pair of items on the stack.

=head2 Using Parameters

Instead of managing the stack itself, the block can use parameters. The
glacier hash might look like:

    tree_fold glacier_hash( $left, $rite )
    {
        $rite
        ? sha256 $left, $rite
        : $left
    }

which leaves the wrapper produced by tree_fold to splice off the
stack contents and assign them to $left & $rite for each iteration.


=head1 SEE ALSO

=item Keyword::Declare

Which describes how this module constructs the wrapper for each
block.

=item List::Util

Examples of reduce.

=item Neatly Folding a Tree

Talk describing FP solution to a tree-hash including use of 
tail call elimination and constant values:

<http://www.slideshare.net/lembark/neatly-foldingatree-62637403>

Combined talk with Damian Conway on tail call elimination in Perl5
and Perl6:

<http://www.slideshare.net/lembark/neatly-hashing-a-tree-fp-treefold-in-perl5-perl6>

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 LICENSE

This module is licensed under the same terms as Perl-5.22 itself or 
any later version of Perl.


