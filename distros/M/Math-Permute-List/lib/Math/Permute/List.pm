=head1 Name

Math::Permute::List - Generate all permutations of a list.

=head1 Synopsis

 use Math::Permute::List;

 permute {say "@_"} qw(a b c);

 #  a b c
 #  a c b
 #  b a c
 #  c a b
 #  b c a
 #  c b a

=cut

use strict;

package Math::Permute::List;

sub permute(&@)        # Generate all permutations of a list
 {my $s = shift;       # Subroutine to call to process each permutation
  my $n = scalar(@_);  # Size of array to be permuted
# return 0 unless $n;  # Empty lists cannot be permuted - removed per Philipp Rumpf
  my $l = 0;           # Item being permuted           
  my @p = ();          # Current permutations
  my @P = @_;          # Array to permute   
  my @Q = ();          # Permuted array     

  my $p; $p = sub      # Generate each permutation
   {if ($l < $n) 
     {for(0..$n-1)
       {if (!$p[$_])
         {$Q[$_] = $P[$l];
          $p[$_] = ++$l;
          &$p();
          --$l;
          $p[$_] = 0;
         }
       }
     }
    else 
     {&$s(@Q);
     }
   };

  &$p;

  $p = undef;          # Break memory loop per Philipp Rumpf

  my $i = 1; $i *= $_ for 2..$n;
  $i                   # Number of permutations 
 }

# Export details
 
require 5;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(permute);
$VERSION = '1.007';

=head1 Description

Generate and process all the permutations of a list using the standard
Perl metaphor. 

C<permute()> returns the number of permutations in both scalar and array
context.

C<permute()> is easy to use and fast. It is written in 100% Pure Perl.

Please note that the order in which the permutations are generated is
not guaranteed, so please do not rely on it.

=head1 Export

The C<permute()> function is exported.

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't require
the "./" notation, you can do this:

  perl Build.PL
  Build
  Build test
  Build install

=head1 Author

PhilipRBrenan@appaapps.com

http://www.appaapps.com

=head1 Acknowledgements

With considerable, cogent and unfailing help from Philipp Rumpf for which I am indebted.

http://www.appaapps.com

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Disarrange::List>

=item L<Math::Subsets::List>

=item L<Algorithm::Permute>

=item L<Algorithm::FastPermute>

=back

=head1 Copyright

Copyright (c) 2009 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
