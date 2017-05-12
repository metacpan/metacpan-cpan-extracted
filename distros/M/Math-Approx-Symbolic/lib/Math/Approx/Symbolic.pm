
=head1 NAME

Math::Approx::Symbolic - Symbolic representation of interpolated polynomials

=head1 SYNOPSIS

  use Math::Approx::Symbolic;
  # ... use as you would use Math::Approx ...
  
  my $symbolic = $approximation->symbolic();
  
  # ... $symbolic is now a Math::Symbolic object.

=head1 DESCRIPTION

This module is a thin wrapper around the Math::Approx module. It subclasses
Math::Approx and adds the "symbolic" subroutine that returns a
Math::Symbolic object representing the calculated approximation.

=head2 EXPORT

None. Ever.

=cut

package Math::Approx::Symbolic;

use 5.006;
use strict;
use warnings;

use Math::Approx;
use Math::Symbolic;

use base 'Math::Approx';

our $VERSION = '0.100';

=head2 symbolic() method

This is the only method added to the ones from Math::Approx.
It takes an optional argument indicating the variable name to use
for the symbolic representation of the approximation polynomial.

It returns a Math::Symbolic object representing the approximation
polynomial.

=cut

sub symbolic {
    my $self = shift;
    my $var  = shift;
    $var = 'x' unless defined $var;
    $var = Math::Symbolic::Variable->new($var)
      unless ref($var) =~ /^Math::Symbolic::Variable/;
    my $degree = $self->{N};
    my @coeff  = @{ $self->{A} };

    my $constant = shift @coeff;

    my $cur_degree = $degree;
    my @exps;
    foreach ( reverse @coeff ) {
        push @exps,
          Math::Symbolic::Operator->new(
            '*',
            Math::Symbolic::Constant->new($_),
            (
                  $cur_degree == 1
                ? $var
                : Math::Symbolic::Operator->new(
                    '^', $var, Math::Symbolic::Constant->new($cur_degree)
                )
            )
          );
        $cur_degree--;
    }
    my $symbolic = shift @exps;
    $symbolic += $_ foreach @exps;
    return $symbolic + Math::Symbolic::Constant->new($constant);
}

1;
__END__

=head1 EXAMPLE

  use Math::Approx::Symbolic;
  
  sub poly {
      my($n,$x) = @_;
      return $x ** $n;
  }
  
  my %x;
  for (1..20) {
      $x{$_} = sin($_/10) * cos($_/30) + 0.3*rand;
  }
  
  my $approx = new Math::Approx::Symbolic (\&poly, 5, %x);
  $approx->print;
  print "Fit: ", $approx->fit, "\n\n";
  
  my $function = $approx->symbolic('x');
  # defaults to using variable 'x' without argument.
  
  print "$function\n";
  
  print $function->value(x => $_),"\n" foreach keys %x;
  
  # Work with the symbolic function now.

=head1 AUTHOR

(c) 2003 by Steffen Müller

Please send feedback, bug reports, and support requests to the author at
approx-symbolic-module at steffen-mueller dot net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

L<Math::Approx>

L<Math::Symbolic>

=cut

