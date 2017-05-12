package LLVM::Builder;
{
  $LLVM::Builder::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::Builder - LLVM builder class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::Builder> is the means of building instructions and represents a point
within a basic block.

=head1 METHODS

=head2 new( )

Create a new C<LLVM::Builder> object.

=head2 position_at_end( $blk )

Postion the C<LLVM::Builder> at the end of the given L<LLVM::BasicBlock>.

=head1 TERMINATOR INSTRUCTIONS

See the L<LLVM reference|http://llvm.org/docs/LangRef.html#terminators> for more
information about the single instructions.

=head2 ret( $v )

Append a ret instruction to the block. This function takes a L<LLVM::Value>
representing the value to be returned and returns a L<LLVM::Value>.

=head2 ret_void( )

Append a void ret instruction to the block. This function returns a L<LLVM::Value>.

=head2 br( $dest )

Append a branch instruction to the block. This function takes a
L<LLVM::BasicBlock> C<$dest>.

=head2 cond( $if, $then, $else )

Append a conditional instruction to the block. This function takes a
L<LLVM::Value> C<$if> representing the condition (e.g. it can be the value
returned by a icmp or fcmp instruction) and two L<LLVM::BasicBlock>: the first
executed if the condition is true, the second executed otherwise.

=head2 unreachable( )

Append an unreachable instruction to the block.

=head1 BINARY OPERATIONS

The binary operations require two arguments of the same L<LLVM::Type> and
produce a single L<LLVM::Value>.

See the L<LLVM reference|http://llvm.org/docs/LangRef.html#binaryops> for more
information about the single instructions.

=head2 add( $lhs, $rhs, $name )

Append an integer add instruction to the block and name the result C<$name>.

=head2 fadd( $lhs, $rhs, $name )

Append a floating add instruction to the block and name the result C<$name>.

=head2 mul( $lhs, $rhs, $name )

Append a mul instruction to the block and name the result C<$name>.

=head2 fmul( $lhs, $rhs, $name )

Append a floating mul instruction to the block and name the result C<$name>.

=head2 sub( $lhs, $rhs, $name )

Append a sub instruction to the block and name the result C<$name>.

=head2 fsub( $lhs, $rhs, $name )

Append a floating sub instruction to the block and name the result C<$name>.

=head2 udiv( $lhs, $rhs, $name )

Append an unsigned div instruction to the block and name the result C<$name>.

=head2 sdiv( $lhs, $rhs, $name )

Append a signed div instruction to the block and name the result C<$name>.

=head2 fdiv( $lhs, $rhs, $name )

Append a floating div instruction to the block and name the result C<$name>.

=head1 BINARY BITWISE OPERATIONS

The binary bitwise operations require two arguments of the same L<LLVM::Type>
and produce a single L<LLVM::Value>.

See the L<LLVM reference|http://llvm.org/docs/LangRef.html#binaryops> for more
information about the single instructions.

=head2 shl( $lhs, $rhs, $name )

Append a shift left instruction to the block and name the result C<$name>.

=head2 lshr( $lhs, $rhs, $name )

Append a logical shift right instruction to the block and name the result C<$name>.

=head2 ashr( $lhs, $rhs, $name )

Append an arithmetic shift right instruction to the block and name the result C<$name>.

=head2 and( $lhs, $rhs, $name )

Append an and instruction to the block and name the result C<$name>.

=head2 or( $lhs, $rhs, $name )

Append an or instruction to the block and name the result C<$name>.

=head2 xor( $lhs, $rhs, $name )

Append a xor instruction to the block and name the result C<$name>.

=head1 CONVERSION OPERATIONS

See the L<LLVM reference|http://llvm.org/docs/LangRef.html#otherops> for more
information about the single instructions.

=head2 trunc( $ty, $value, $out, $name )

Append a trunc instruction which takes a L<LLVM::Value> and the conversion
output L<LLVM::Type>, and name the result C<$name>.

=head1 OTHER OPERATIONS

See the L<LLVM reference|http://llvm.org/docs/LangRef.html#otherops> for more
information about the single instructions.

=head2 icmp( $pred, $lhs, $rhs, $name )

Append an integer cmp instruction to the block and name the result C<$name>. The
predicate C<$pred> must be one of:

=over 4

=item C<"eq">

equal

=item C<"ne">

not equal

=item C<"ugt">

unsigned greater than

=item C<"uge">

unsigned greater or equal

=item C<"ult">

unsigned less than

=item C<"ule">

unsigned less or equal

=item C<"sgt">

signed greater than

=item C<"sge">

signed greater or equal

=item C<"slt">

signed less than

=item C<"sle">

signed less or equal

=back

=head2 fcmp( $pred, $lhs, $rhs, $name )

Append a float cmp instruction to the block and name the result C<$name>. The
predicate C<$pred> must be one of:

=over 4

=item C<"false">

no comparison, always returns false

=item C<"oeq">

ordered and equal

=item C<"ogt">

ordered and greater than

=item C<"oge">

ordered and greater than or equal

=item C<"olt">

ordered and less than

=item C<"ole">

ordered and less than or equal

=item C<"one">

ordered and not equal

=item C<"ord">

ordered (no nans)

=item C<"ueq">

unordered or equal

=item C<"ugt">

unordered or greater than

=item C<"uge">

unordered or greater than or equal

=item C<"ult">

unordered or less than

=item C<"ule">

unordered or less than or equal

=item C<"une">

unordered or not equal

=item C<"uno">

unordered (either nans)

=item C<"true">

no comparison, always returns true

=back

=head2 call( $func, $name [, $arg ... ] )

Append a call instruction to the block and name the result C<$name>. The
generated instruction will call the L<LLVM::Value> representing a function
C<$func> with the given arguments of type L<LLVM::Value>.

=head2 select( $if, $then, $else, $name )

Append a select instruction to the block and name the result C<$name>. C<$if>,
C<$then> and C<$else> are L<LLVM::Value>s.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::Builder
