=head1 Name

Math::Disarrange::List - Generate all the disarrangements of a list.

=head1 Synopsis

 use Math::Disarrange::List;

 disarrange {say "@_"} qw(a b c);

 #  c a b
 #  b c a

=cut

package Math::Disarrange::List;
our $VERSION = '20170828';                                                      # Monday 26 Jan 2015
use v5.8.0;
use warnings FATAL => qw(all);
use strict;

sub disarrange(&@)     # Generate all the disarrangements of a list
 {my $s = shift;       # Subroutine to call to process each disarrangement

  my $n = scalar(@_);  # Size of array to be disarranged
# return 0 if $n < 2;  # Require at least two elements to disarrange - per Philipp Rumpf
  my $m = 0;           # Number of disarrangements
  my $l = 0;           # Item being disarranged
  my @p = ();          # Current disarrangements
  my @P = @_;          # Array to disarrange
  my @Q = ();          # Disarranged array

  my $p; $p = sub      # Generate each disarrangement
   {if ($l < $n)
     {for(0..$n-1)
       {next if $l == $_;
        if (!$p[$_])
         {$Q[$_] = $P[$l];
          $p[$_] = ++$l;
          &$p();
          --$l;
          $p[$_] = 0;
         }
       }
     }
    else
     {&$s(@Q); ++$m;
     }
   };

  &$p;
  $p = undef;          # Break memory loop per Philipp Rumpf
  $m
 }

# Export details

require 5;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(disarrange);

=head1 Description

Generate and process all the disarrangements of a list using the standard
Perl metaphor. A disarrangement is a permutation of the original list in
which no element is in its original position.

C<disarrange()> returns the number of disarrangements in both scalar and
array context.

C<disarrange()> is easy to use and fast. It is written in 100% Pure Perl.

Please note that the order in which the disarrangements are generated is not
guaranteed, so please do not rely on it.

=head1 Export

The C<disarrange()> function is exported.

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't require the
"./" notation, you can do this:

  perl Build.PL
  Build
  Build test
  Build install

=head1 Author

PhilipRBrenan@appaapps.com

http://www.appappps.com

=head1 Acknowledgements

With extensive and unfailing advice from Philipp Rumpf to whom I am greatly
indebted.

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Permute::List>

=item L<Math::Subsets::List>

=back

=head1 Copyright

Copyright (c) 2009-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
