package Math::SymbolicX::FastEvaluator;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.01';

use Math::Symbolic::Operator;

require XSLoader;
XSLoader::load('Math::SymbolicX::FastEvaluator', $VERSION);


1;
__END__

=head1 NAME

Math::SymbolicX::FastEvaluator - Fast, XS, stack-based formula evaluator

=head1 SYNOPSIS

  use Math::Symbolic qw/:all/;
  use Math::Symbolic::Custom::DumpToFastEval;
  
  my $formula = parse_from_string("a+b^2");
  print "Normal evaluation: " . $formula->value(a => 3.1, b => 2.5), "\n";
  
  my $expression = $formula->to_fasteval;
  print "Much faster: " . $formula->Evaluate([3.1, 2.5]);

=head1 DESCRIPTION

I<WARNING>: Highly experimental! Wrong usage results in segmentation faults
and pain.

There are two was to evaluate a L<Math::Symbolic> formula that come with
the main distribution: Calling the C<value()> method on it or using
the L<Math::Symbolic::Compiler> to produce a Perl subroutine that can
calculate the value much quicker.

However, sometimes that's not quite fast enough. Then, you can use
the L<Math::Symbolic::Custom::CCompiler> module with L<Inline::C>
to compile your formula to C code, compile it, and link it at run-time.
Unfortunately, that requires compiling C code at run-time and caching the
resulting files, etc. Not very user-friendly.

This module is a fourth alternative: Translate it to a stream of C-level
structs in I<Reverse Polish Notation>, then execute it in a fast RPN
evaluator (implemented in C/XS).

The basic usage of this module is to generate the
RPN data with a call to C<my $expr = $formula-E<gt>to_fasteval()> which returns
a C<Math::SymbolicX::FastEvaluator::Expression> object. You can now
get its value by calling C<$expr-E<gt>Evaluate(\@variable_values)>. This will
internally construct a C<Math::SymbolicX::FastEvaluator> object, use it to
evaluate the expression and destroy it when it's done. This is a tiny overhead,
but you can avoid it by constructing a C<FastEvaluator> object yourself
and calling C<$fasteval-E<gt>Evaluate($expr, \@variable_values)>.

=head2 WHY?

Two reasons: Experimentation and the distant hope of passing the expressions
to numeric optimization routines, which are naturally implemented in C,
C++, or even FORTRAN.

=head2 PERFORMANCE

Using all this combersome indirection, the evaluation of C<FastEvaluator>
expressions proceeded at a pace of over 200 million tokens per second on my
1.8GHz Core2 laptop which was busy with various desktop tasks at the same time.
A token is a number, variable or operator. Since I was
testing with a string of multiplications, this translates to roughly
100 MFLOPS. You can consider this fast or slow, but compared to Perl
evaluation, this is at least a factor of ten faster. When variables are added into
the picture, the improvement should be even larger.
Since the overhead of this method is still large compared to the actual
computation time, sums, differences, products and divisions are approximately
equally fast.

=head2 PORTABILITY

The code was developed on Linux and compiled with the GNU compiler collection.
Currently, the C++ compiler is hardwired to C<g++> in the C<Makefile.PL>.
Improvements welcome.

=head1 EXAMPLE

The I<SYNOPSIS> above covers typical usage.

=head2 EXPLICIT CONSTRUCTION

This is the explicit low-level interface.
It's tedious and error prone. If you
construct bad RPN and try to evaluate it, you may crash your perl
interpreter. The RPN evaluator does not check the input as it tries
to be as fast as possible.

This is here for completeness sake. Consider using the L<Math::Symbolic::Custom::DumpToFastEval>
interface (see SYNOPSIS) instead!

  use Math::SymbolicX::FastEvaluator;
  use Math::Symbolic qw/:all/;
  
  my $eval = Math::SymbolicX::FastEvaluator->new(); 
  my $expr = Math::SymbolicX::FastEvaluator::Expression->new(); 
  my $op   = Math::SymbolicX::FastEvaluator::Op->new(); 
  
  # This is RPN based: Essentially, compute "a+b^2"
  $op->SetVariable();
  $op->SetValue(1.0); # first variable (aka a)
  $expr->AddOp($op);
  
  $op->SetVariable();
  $op->SetValue(2.0); # second variable (aka b)
  $expr->AddOp($op);
  
  $op->SetNumber();
  $op->SetValue(2.0); # the exponent
  $expr->AddOp($op);
  
  $op->SetOpType(B_EXP); # see Math::Symbolic for this constant
  $expr->AddOp($op);     # I.e. b^2
  
  $op->SetOpType(U_SUM); # see Math::Symbolic for this constant
  $expr->AddOp($op);     # I.e. a + (b^2)
  
  # Insert variables 1 and 2 (a and b) and evaluate:
  print "The value is: " . $eval->Evaluate($expr, [3.1, 2.5]);
  # should be 3.1+2.5**2 == 9.35

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
