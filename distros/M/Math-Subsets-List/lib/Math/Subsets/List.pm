=head1 Name

Math::Subsets::List - Generate all the subsets of a list.

=head1 Synopsis

 use Math::Subsets::List;

 subsets {say "@_"} qw(a b c);

 #    
 #  a 
 #  b
 #  c
 #  a b 
 #  a c 
 #  b c
 #  a b c

=cut

package Math::Subsets::List;

use strict;

sub subsets(&@)        # Generate all the subsets of a list  
 {my $s = shift;       # Subroutine to call to process each subset

  my $n = scalar(@_);  # Size of list to be subsetted
  my $l = 0;           # Current item
  my @p = ();          # Current subset
  my @P = @_;          # List to be subsetted

  my $p; $p = sub      # Generate each subset
   {if ($l < $n)
     {++$l;
      &$p();
      push @p, $P[$l-1];
      &$p();
      pop @p;
      --$l
     }
    else 
     {&$s(@p)
     }
   };

  &$p;
  $p = undef;          # Break memory loop per Philipp Rumpf    
  
  2**$n;
 }

# Export details
 
require 5;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(subsets);
$VERSION = '1.008'; # Friday 30 Jan 2015

=head1 Description

Generate all the subsets of a list and process them using the standard
Perl metaphor. 

C<subsets()> returns the number of subsets. Please note that this
includes the empty set as it is a subset of all sets.

Please note that the order in which the subsets are generated is
not guaranteed, so please do not rely on it.

C<subsets()> is easy to use and fast. It is written in 100% Pure Perl.

=head1 Export

The C<subsets()> function is exported.

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

=head1 Acknowledgments

With lots of help and advice from Philip Rumpff to who I am most grateful.

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Disarrange::List>

=item L<Math::Permute::List>

=back

=head1 Copyright

Copyright (c) 2009 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut

1;
__END__
