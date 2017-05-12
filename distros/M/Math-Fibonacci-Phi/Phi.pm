package Math::Fibonacci::Phi;

use strict;
use warnings;
use Math::Fibonacci;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( Phi phi series_Phi series_phi term_Phi term_phi super_series ) ] );
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} } ;

my $max_prec = 14;
our $Precision = 0;
our $TrailingZeros = 0;
our $VERSION = '0.02';

sub Phi {
   my $fn = Math::Fibonacci::isfibonacci(shift());
   return undef if !$fn;
   my $prev = $fn - 1;
   return 1 if !$prev; # handle number 1 special, 1/1

   return Math::Fibonacci::term($fn) / Math::Fibonacci::term($prev) unless $Precision >= 1 && $Precision <= $max_prec;

   my $gold = sprintf ('%.' . $Precision . 'f', Math::Fibonacci::term($fn) / Math::Fibonacci::term($prev) );
   $gold =~ s/\.?0*$// unless $TrailingZeros;
   return $gold;
}

sub phi {
   my $fn = Math::Fibonacci::isfibonacci(shift());
   return undef if !$fn;
   my $next = $fn + 1;

   return Math::Fibonacci::term($next) / Math::Fibonacci::term($fn) unless $Precision >= 1 && $Precision <= $max_prec;

   my $gold = sprintf ('%.' . $Precision . 'f', Math::Fibonacci::term($next) / Math::Fibonacci::term($fn) );
   $gold =~ s/\.?0*$// unless $TrailingZeros;
   return $gold;
}

sub series_Phi {
   my %Fibo;
   for(Math::Fibonacci::series(shift())) {
      $Fibo{$_} = Phi($_);
   }
   return \%Fibo;
}

sub series_phi {
   my %Fibo;
   for(Math::Fibonacci::series(shift())) {
      $Fibo{$_} = phi($_);
   }
   return \%Fibo;
}

sub term_Phi { Phi(Math::Fibonacci::term(shift())); }

sub term_phi { phi(Math::Fibonacci::term(shift())); }

sub super_series {
   my %Fibo;
   my $posi = 1;
   for(Math::Fibonacci::series(shift())) {
     $Fibo{$_} = {
        position => $posi,
        Phi => Phi($_),
        phi => phi($_)
     };
     $posi++;
   }
   return \%Fibo;
}

1;

__END__

=head1 NAME

Math::Fibonacci::Phi - Perl extension for calculating Phi and phi for Fibonacci numbers.

=head1 SYNOPSIS

  use Math::Fibonacci::Phi;
  use Math::Fibonacci::Phi qw(Phi phi);
  use Math::Fibonacci::Phi ':all'

=head1 DESCRIPTION

=head2 EXPORT

None by default. Everything in the function section below can be imported and ':all' will do all functions.

=head1 Functions

=head2 Phi($fn)

Calculates and returns Phi (The Golden Number) for the given Fibonacci Number. It returns undef if the argument is not part of the Fibonacci sequence.

=head2 phi($fn)

Calculates and returns phi (opposite of Phi, antiPhi) for the given Fibonacci Number. It returns undef if the argument is not part of the Fibonacci sequence.

=head2 series_Phi($n) 

Returns a hashref of the first $n Fibonacci Numbers where each key is the Fibonacci and the value is its Phi.

=head2 series_phi($n)

Returns a hashref of the first $n Fibonacci Numbers where each key is the Fibonacci and the value is its phi.

=head2 term_Phi($nth)

Returns Phi for the $nth Fibonacci number.

=head2 term_phi($nth)

Returns phi for the $nth Fibonacci number.

=head2 super_series($n)

Returns a hashref of the first $n Fibonacci Numbers where each key is the Fibonacci and the value is a hashref that has these 3 keys: 

   'Phi', 'phi', and 'position'

'position' is its location in the sequence (IE same number as the argument you'd give to term_Phi() or term_phi() )

=head1 Format Options

=head2 $Math::Fibonacci::Phi::Precision

This can be a number from 1 - 14 to specify the decimal precision you'd like.

   use Math::Fibonacci::Phi 'Phi';
   print Phi(5), "\n";
   $Math::Fibonacci::Phi::Precision = 7;
   print Phi(5), "\n";

result is:

   1.66666666666667
   1.6666667

=head2 $Math::Fibonacci::Phi::TrailingZeros

If $Math::Fibonacci::Phi::Precision is set then you can set this to true to keep the trailing zeros.

   use Math::Fibonacci::Phi 'Phi';
   $Math::Fibonacci::Phi::Precision = 5;
   print Phi(3), "\n";
   $Math::Fibonacci::Phi::TrailingZeros=1
   print Phi(3), "\n";

result is:

   1.5
   1.50000

=head1 SEE ALSO

L<Math::Fibonacci>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
