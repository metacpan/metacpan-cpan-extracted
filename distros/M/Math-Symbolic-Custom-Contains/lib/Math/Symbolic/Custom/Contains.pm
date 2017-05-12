package Math::Symbolic::Custom::Contains;

use 5.006;
use strict;
use warnings;
use Carp qw/croak carp cluck confess/;

use Math::Symbolic::Custom::Base;
BEGIN { *import = \&Math::Symbolic::Custom::Base::aggregate_import }

use Math::Symbolic::ExportConstants qw/:all/;
our $VERSION = '1.01';

our $Aggregate_Export = [qw/contains_operator/];

sub contains_operator {
    my ( $f, $op ) = @_;

    my @nodes = ($f);
    while (@nodes) {
        my $n = shift @nodes;
        if ( ref $n eq 'Math::Symbolic::Operator' ) {
            if ( not defined $op ) {
                return $n;
            }
            else {
                if ( $n->type() == $op ) {
                    return $n;
                }
                else {
                    my @ops = $n->descending_operands();
                    push @nodes, @ops;
                }
            }
        }
        else {
            next;
        }
    }
    return (undef);
}

1;
__END__

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Contains - Find subtrees in Math::Symbolic expressions

=head1 SYNOPSIS

  use Math::Symbolic qw/:all/;
  use Math::Symbolic::Custom::Contains;
  
  my $formula = parse_from_string('a*b+c');

  print 'found product' if $formula->contains_operator(B_PRODUCT);
  # works
  print 'found division' if $formula->contains_operator(B_DIVISION);

=head1 DESCRIPTION

This module extends the functionality of Math::Symbolic by offering
facilities to test a Math::Symbolic tree for existance of a specific
subtree in the Math::Symbolic tree.

As of version 0.10, this has only been implemented for operators via
the contains_operator method.

The module adds methods to all Math::Symbolic objects.

=head2 $ms_tree->contains_operator( [Operator type] )

This method does not modify the Math::Symbolic tree itself, but instead
tests the tree for existance of an operator of the specified operator
type. It returns undef if no such operator exists in the tree and returns
a reference to the first occurrance of the operator if there are such
operators.

Operator types are constants exported by Math::Symbolic. Please refer to the
Math::Symbolic manual for details.

If the operator type is omitted, the match will be performed for B<any>
operator. That means if the tree contains any operators at all, a reference
to the top-most operator will be returned. (Which will always be the top-most
node of the tree anyway.)

=head1 AUTHOR

Please send feedback, bug reports, and support requests to one of the
contributors or the Math::Symbolic mailing list.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

L<Math::Symbolic>

L<Math::Symbolic::Custom>,
L<Math::Symbolic::Custom::Base>,
L<Math::Symbolic::Custom::DefaultTests>

=cut

