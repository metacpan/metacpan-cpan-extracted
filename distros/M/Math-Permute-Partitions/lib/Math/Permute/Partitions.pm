=head1 Name

Math::Permute::Partitions - Generate all the permutations of a partitioned list.

=head1 Synopsis

 use Math::Permute::Partitions;

 permutePartitions {$a .= "@_\n"} [1,2], [3,4];

 # 1 2 3 4
 # 1 2 4 3
 # 2 1 3 4
 # 2 1 4 3
  
=cut

use strict;

package Math::Permute::Partitions;
use Math::Permute::List;
use Math::Cartesian::Product;

sub permutePartitions(&@)                                                       # Generate permutations of a partitioned list
 {my $s = shift;                                                                # Subroutine to call to process each permutation

  my @p;                                                                        # Partitions 
  my $p = 0;                                                                    # Current partitions 
  for(@_)
   {permute {push @{$p[$p]}, [@_]} @$_;                                         # Permute each partition
    ++$p;
   }
  cartesian {&$s(map {@$_} @_)} @p;                                             # form cartesian product of permutations of each partition
 }

# Export details
 
require 5;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(permutePartitions);
$VERSION = '1.001';

=head1 Description

Generate all the permutations of a partitioned list using the standard
Perl metaphor. 

C<permutePartitions()> returns the number of permutations in both scalar and array
context.

C<permutePartitions()> is written in 100% Pure Perl.


=head1 Export

The C<permutePartitions()> function is exported.

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

Based on an idea from Philipp Rumpf

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Disarrange::List>

=item L<Math::Permute::List>

=item L<Math::Permute::Lists>

=item L<Math::Subsets::List>

=item L<Algorithm::Permute>

=item L<Algorithm::FastPermute>

=back

=head1 Copyright

Copyright (c) 2015 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
