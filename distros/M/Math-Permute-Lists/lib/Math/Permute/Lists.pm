=head1 Name

Math::Permute::Lists - Generate all the permutations of zero or more nested lists.

=head1 Synopsis

 use Math::Permute::Lists;

 permute {say "@_"}  [1,2],[3,4];

 # 1 2 3 4
 # 1 2 4 3
 # 2 1 3 4
 # 2 1 4 3
 # 3 4 1 2
 # 3 4 2 1
 # 4 3 1 2
 # 4 3 2 1

 permute {say "@_"} 1,[2,[3,4]];

 # 1 2 3 4
 # 1 2 4 3
 # 1 3 4 2
 # 1 4 3 2
 # 2 3 4 1
 # 2 4 3 1
 # 3 4 2 1
 # 4 3 2 1

=cut

package Math::Permute::Lists;
our $VERSION = '20170828';
use v5.16.0;
use warnings FATAL => qw(all);
use strict;

sub permute(&@)                                                                 # Generate permutations of lists - user interface
 {my $s = shift;                                                                # Subroutine to call to process each permutation
  &Permute($s, undef, @_);                                                      # Perform permutations
 }

sub Permute                                                                     # Generate and expand permutations - private
 {my $S = shift;                                                                # User subroutine to call to process each permutation
  my $R = shift;                                                                # Subroutine to expand replacements

  my $Single = __PACKAGE__.'Single';                                            # User supplied item
  my $Expand = __PACKAGE__.'Expand';                                            # Sub permutations of user items
  my $mirror; $mirror = sub                                                     # Mirror permutation structure
   {my @p;                                                                      # Items to be permuted discovered at this level
    for(@_)
     {if (ref eq "ARRAY" or ref eq $Expand)                                     # Array of sub items to be permuted together
       {push @p, bless [0, bless $_, $Expand], $Single;                         # Not in use, sublist
       }
      else                                                                      # A single item
       {push @p, bless [0, $_], $Single;                                        # Not in use, user item
       }
     }
    @p                                                                          # Result
   };

  my $M = [&$mirror(@_)];                                                       # Mirrors the user supplied permutation structure but with additional data
  my @Q = ();                                                                   # Permuted array = output area
  my $N = 0;                                                                    # Number of permutations encountered

  my $replace; $replace = sub                                                   # Replace sub permutations with their expansions
   {my @q = @_;                                                                 # Fully or partially expanded row
    if (grep {ref($_) eq $Expand} @q)                                           # Check whether results if fully expanded yet
     {my @p;                                                                    # Prefix elements that are fully expanded
      for(;@q;)                                                                 # Remove leading block of items that do not need expansion
       {my $q = shift @q;                                                       # Each element, leaving trailing elements
        if (ref($q) ne $Expand)                                                 # Leading expanded elements
         {push @p, $q;                                                          # Save leading expanded element
         }
        else                                                                    # First element requiring expansion
         {&Permute($S, sub {&$replace(@p, @_, @q);}, @$q);                      # Expand sub permutation and use it to expand the current row
          return;
         }
       }
     }
    else                                                                        # Fully expanded - call user processing routine
     {++$N;                                                                     # Number of permutations encountered
      &$S(@q);                                                                  # Pass to user
     }
   };

  my $permute; $permute = sub                                                   # Generate permutations
   {if (scalar(@Q) == scalar(@$M))                                              # Row has been generated when it has enough elements
     {($R ? $R : $replace)->(map {$_->[1]} @Q);                                 # Subsequent or first replacement of user data
      return;
     }

    my ($P) = @_;                                                               # Permutations to be performed
    for my $p(@$P)                                                              # Find an item that has not been used so far in this permutation
     {if (!$p->[0])                                                             # Not in use
       {push @Q, $p;                                                            # Place it in the next position in the output area
        $p->[0] = 1;                                                            # Mark it as in use
        &$permute($P);                                                          # Choose again
        $p->[0] = 0;                                                            # Mark it as available
        pop @Q;                                                                 # Free space in output area
       }
     }
   };

  &$permute($M);                                                                # Permute per user
  $mirror = $replace = $permute = undef;                                        # Break memory cycles
  $N                                                                            # Return number of permutations performed
 }

# Export details

require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(permute);

=head1 Description

Generate all the permutations of zero or more nested lists using the standard
Perl metaphor.

C<permute()> returns the number of permutations in both scalar and array
context.

C<permute()> is 100% Pure Perl.

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

From a suggestion by Philipp Rumpf.

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Disarrange::List>

=item L<Math::Permute::List>

=item L<Math::Subsets::List>

=item L<Algorithm::Permute>

=item L<Algorithm::FastPermute>

=back

=head1 Copyright

Copyright (c) 2009 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
