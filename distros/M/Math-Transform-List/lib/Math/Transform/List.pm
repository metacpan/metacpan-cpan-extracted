=head1 Name

Math::Transform::List - Generate specified transformations of a list.

=head1 Synopsis

 use Math::Transform::List;

 transform {say "@_"} [qw(a b c)],   [1..3];

 #  a b c
 #  b c a
 #  c b a

 transform {say "@_"} [qw(a b c d)], [1..2], [3..4];

 #  a b c d
 #  b a c d
 #  a b d c
 #  b a d c

 transform {say "@_"} [qw(a b c d)], [[1, 3], [2, 4]];

 #  a b c d
 #  c d a b

=cut

use strict;

package Math::Transform::List;


sub transform(&$@)
 {my $s = shift;       # Subroutine to process each transformation


# List to be transformed

  my $L = shift;
  ref($L) or die "transform(2): $L not a reference";
   {my @L = @$L;
    if    (@L == 0)
     {return 0
     }
    elsif (@L == 1)
     {&$s(@L);
      return 1
     }
   }
  my ($N1, $N) = (scalar(@$L)-1, scalar(@$L));


# Transformations - check

  for(0..$#_)
   {my @p = @{$_[$_]};
    my $p = grep {ref($_)} @{$_[$_]};
    $p == 0 or $p == @p or die "Transform, transformation(@p) must be all references to cycles or one cycle";
   }


# Transformations - load

  my $T;
  for(0..$#_)
   {ref($_[$_]) or die "transform(".(3+$_).") ".($_[$_])." not a reference";
    my @P = @{$_[$_]};
    for my $P(0..$#P)
     {my $p = $P[$P];
      if (ref($p))
       {my @Q = @$p;
        for my $Q(0..$#Q)
         {my $q = $Q[$Q];
         ("$q" =~ /\A\d+\Z/ and $q > 0 and $q <= $N) or die "transform(".($_+3)."->$P->$Q): $q not a number between 1 and $N";
          if ($Q)
           {my $q1 = $Q[$Q-1];
            !defined($T->[$_][$q1-1]) or die "transform(".($_+3)."->$P->$Q): transformation from $q1 to $q already defined";
             $T->[$_][$q1-1] = $q-1;
           }
         }
        $T->[$_][$Q[-1]-1] = $Q[0]-1;
       }
      else
       {("$p" =~ /\A\d+\Z/ and $p > 0 and $p <= $N) or die "transform(".($_+3)."->$P): $p not a number between 1 and $N";
        if ($P)
         {my $p1 = $P[$P-1];
          !defined($T->[$_][$p1]) or die "transform(".($_+3)."->$P): transformation from $p1 to $p already defined";
          $T->[$_][$p1-1] = $p-1;
         }
       }
     }
    $T->[$_][$P[-1]-1] = $P[0]-1;
   }


# Set unset transforms

  for   my $a(0..$#_)
   {for my $b(0..$N1)
     {$T->[$a][$b] = $b unless defined $T->[$a][$b];
     }
   }


# Initialize transformer

  my @T = ([0..$N1]);  # Transforms stack
  my $S;               # Transforms already processed


# Generate transformations

  my $n = 0;
  for(;@T;)
   {my $a = pop @T;
    for my $b(@$T)
     {my @C = map {$b->[$a->[$_]]} 0..$N1;

      unless ($S->{"@C"}++)
       {push @T, [@C];
        &$s(map {$L->[$C[$_]]} 0..$N1);
        $n++;
       }
     }
   }


  $n                   # Number of transformations
 }


# Export details

require 5.16.0;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(transform);
$VERSION = 20170808;                                                            # Monday 26 Jan 2015

=head1 Description

Generate and process all the all the transformations of a list using the
standard Perl metaphor.

C<transform()> returns the number of transformations in both scalar and
array context.

C<transform()> is easy to use and fast. It is written in 100% Pure Perl.

Please note that the order in which the transformations are generated is not
guaranteed, so please do not rely on it.

The parameters to C<transform()> are:

1: The code to be executed for each transformation.

2: A reference to the list to be transformed. This list is transformed
as specified by the transformations. Each transformation of the list is
handed to the code supplied in parameter 1 to be processed.

3: One or more transformations to be applied to the list. The
transformations are applied repeatedly in all orders until no new
transformations of the list are generated. Each new transformation of the
list is handed to the code supplied in parameter 1 for processing.

Transformations are represented as permutations in cyclic format based from
1 not 0. Two representations can be used to specify transformations.

3a: Single cycle.

  [1,2,3]

The first element of the list will be replaced by the second, the second by
the third, and the third by the first.

3a: Multi cycle.

  [[1,3], [2,4]]

The first element of the list will be replaced by the third and vice versa,
while simultaneously the second element is replaced by the fourth and vice
versa.

  transform {say "@_"} [qw(a b c d)], [[1, 3], [2, 4]];

  #  a b c d
  #  c d a b

If you want to produce all possible transformations of a list you should
consider L<Math::Permute::List> as it is faster and easier to use than the
equivalent:

  transform {} [1..$n], [1,2], [1..$n];

=head1 Export

The C<transform()> function is exported.

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

http://www.appaapps.com

=head1 Acknowledgements

With much help and good natured advice from Philipp Rumpf to whom I am
indebted.

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Disarrange::List>

=item L<Math::Permute::List>

=item L<Math::Subsets::List>

=back

=head1 Copyright

Copyright (c) 2009 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
