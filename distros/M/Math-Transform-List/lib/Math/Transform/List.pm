package Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
our $VERSION = 20170824;

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

sub transform(&$@)                                                              # Transform list
 {my ($sub, $list, @trans) = @_;                                                # Subroutine to process each transformation, list to be transformed, transformations

  my $L = $list;                                                                # List to be transformed
  ref($L) or die "transform(2): $L not a reference";

  if (1)                                                                        # Easy cases
   {my @L = @$L;
    if    (@L == 0)
     {return 0
     }
    elsif (@L == 1)
     {&$sub(@L);
      return 1
     }
   }

  my $N = scalar(@$L); my $N1 = $N - 1;                                         # Size of the list

  for my $trans(0..$#trans)                                                     # Check transformations are valid
   {my @p = @{$trans[$trans]};
    my $p = grep {ref($_)} @p;
    $p == 0 or $p == @p or confess
      "Transformation(@p) must be all references to cycles or one cycle";
   }

  my $T;                                                                        # Transformations
  for my $trans(0..$#trans)                                                     # Load transformations
   {ref($trans[$trans]) or confess
      "Transform(".(3+$trans).") ".($trans[$trans])." not a reference";
    my @P = @{$trans[$trans]};
    for my $P(0..$#P)
     {my $p = $P[$P];
      if (ref($p))                                                              # Multi cycle
       {my @Q = @$p;
        for my $Q(0..$#Q)
         {my $q = $Q[$Q];
         ("$q" =~ /\A\d+\Z/ and $q > 0 and $q <= $N) or confess
            "Transform(".($trans+3)."->$P->$Q):".
            " $q not a number between 1 and $N";
          if ($Q)
           {my $q1 = $Q[$Q-1];
            !defined($T->{$trans}{$q1-1}) or confess
              "transform(".($trans+3)."->$P->$Q): ".
              " transformation from $q1 to $q already defined";
            $T->{$trans}{$q1-1} = $q-1;
           }
         }
        $T->{$trans}{$Q[-1]-1} = $Q[0]-1;
       }
      else                                                                      # Single cycle
       {("$p" =~ /\A\d+\Z/ and $p > 0 and $p <= $N) or confess
         "Transform(".($trans+3)."->$P): $p not a number between 1 and $N";
        if ($P)
         {my $p1 = $P[$P-1];
          !defined($T->{$trans}{$p1}) or confess
          "Transform(".($trans+3)."->$P):".
          " transformation from $p1 to $p already defined";
          $T->{$trans}{$p1-1} = $p-1;
         }
       }
     }
    $T->{$trans}{$P[-1]-1} = $P[0]-1;
   }

  for   my $A(0..$#trans)                                                       # Set unset transforms
   {for my $B(0..$N1)
     {$T->{$A}{$B} //= $B;
     }
   }

  my @T = ([0..$N1]);                                                           # Transforms stack
  my $S;                                                                        # Transforms already processed
  my $n = 0;                                                                    # Number of transformations performed

  while(@T)                                                                     # Generate transformations
   {my $A = pop @T;
    for my $B(sort {$a <=> $b} keys %$T)
     {my @C = map {$T->{$B}{$A->[$_]}} 0..$N1;

      unless ($S->{"@C"}++)
       {push @T, [@C];
        &$sub(map {$L->[$C[$_]]} 0..$N1);
        $n++;
       }
     }
   }

  $n                                                                            # Number of transformations performed
 }

# Export details

require Exporter;

use vars qw(@ISA @EXPORT);

@ISA     = qw(Exporter);
@EXPORT  = qw(transform);

=head1 Description

Generate and process all the all the transformations of a list using the
standard Perl metaphor.

L<transform|/transform> returns the number of transformations in both scalar
and array context.

Please note that the order in which the transformations are generated is not
guaranteed, so please do not rely on it.

The parameters to L<transform|/transform> are:

1: The code to be executed for each transformation.

2: A reference to the list to be transformed. This list is transformed as
specified by the transformations. Each transformation of the list is handed to
the code supplied in parameter 1 to be processed.

3: One or more transformations to be applied to the list. The transformations
are applied repeatedly in all orders until no new transformations of the list
are generated. Each new transformation of the list is handed to the code
supplied in parameter 1 for processing.

Transformations are represented as permutations in cyclic format based from 1
not 0. Two representations can be used to specify transformations.

3a: Single cycle.

  [1,2,3]

The first element of the list will be replaced by the second, the second by the
third, and the third by the first.

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

L<transform|/transform> is fast and easy to use. It is written in 100% Pure
Perl so it is is easy to read, install, use and modify.

=head1 Export

The L<transform|/transform> function is exported.

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Acknowledgements

With much help and good natured advice from Philipp Rumpf to whom I am
indebted.

=head1 Changes

2017.08.25 04:09:29 MM: hashes instead of sparse arrays

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Disarrange::List>

=item L<Math::Permute::List>

=item L<Math::Subsets::List>

=back

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2009-2017 Philip R Brenan

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
