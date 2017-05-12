=head1 Name

Math::Groups - Find automorphisms of groups and isomorphisms between groups.

=head1 Synopsis

  use Math::Groups;
  use Data::Dump qw(dump);
  use Math::Cartesian::Product;

  # Print a cyclic group of order 4

  print dump(Group{($_[0]*$_[1]) % 5} 1..4)."\n";

  #   elements => {
  #                 1 => { 1 => 1, 2 => 2, 3 => 3, 4 => 4 },
  #                 2 => { 1 => 2, 2 => 4, 3 => 1, 4 => 3 },
  #                 3 => { 1 => 3, 2 => 1, 3 => 4, 4 => 2 },
  #                 4 => { 1 => 4, 2 => 3, 3 => 2, 4 => 1 },
  #               },
  #   identity => 1,
  #   inverses => { 1 => 1, 2 => 3, 3 => 2, 4 => 4 },
  #   orders   => { 1 => 0, 2 => 4, 3 => 4, 4 => 2 },


  # Find the automorphisms of the cyclic group of order 4

  autoMorphisms {print dump({@_})."\n"}
    Group{($_[0]+$_[1]) % 4} 0..3;

  #   { 1 => 1, 2 => 2, 3 => 3 }
  #   { 1 => 3, 2 => 2, 3 => 1 }

  # Find the automorphisms of dihedral group of order 4

  my $corners = [cartesian {1} ([1,-1]) x 2];
  my $cornerNumbers;
  map {my ($a, $b) = @{$$corners[$_]};
		   $cornerNumbers->{$a}{$b} = $_
		  } 0..$#$corners;

  autoMorphisms {print dump({@_})."\n"}
    Group
     {my ($a, $b, $c, $d) = map {@$_} @$corners[@_];
	    $cornerNumbers->{$a*$c}{$b*$d}
     } 0..$#$corners;

  #   { 1 => 1, 2 => 2, 3 => 3 }
  #   { 1 => 1, 2 => 3, 3 => 2 }
  #   { 1 => 2, 2 => 1, 3 => 3 }
  #   { 1 => 3, 2 => 1, 3 => 2 }
  #   { 1 => 2, 2 => 3, 3 => 1 }
  #   { 1 => 3, 2 => 2, 3 => 1 }
=cut

package Math::Groups;

#-------------------------------------------------------------------------------
# Mathematical Groups
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2015
#-------------------------------------------------------------------------------

use v5.18;
use warnings FATAL => qw(all);
use Carp;
use strict;
use utf8;
use Math::Cartesian::Product;
use Math::Permute::List;
use Data::Dump qw(dump);

sub Elements {qw(elements)}                                                     # Constants
sub Identity {qw(identity)}
sub Inverses {qw(inverses)}
sub Orders   {qw(orders)}

sub 𝗲($) {$_[0]->{&Elements}}                                                   # Multiplication table
sub e($) {$_[0]->{&Identity}}                                                   # Identity
sub i($) {$_[0]->{&Inverses}}                                                   # Inverses

sub o($$$;$$)                                                                   # Add one or two products to the group or retrieve a prior product
 {my ($g, $a, $b, $c, $𝗰) = @_;                                                 # Group, first element $a, second element $b, $a*$b, $b*$a
  my $𝗲 = 𝗲($g);                                                                # Elements
  if (@_ == 3)                                                                  # Retrieve a prior product
   {return $𝗲->{$a}{$b};
   }
  if (@_ == 4 or @_ == 5)                                                       # Add a product to the group for a*b
   {$g->{&Identity} = $g->{&Inverses} = undef;                                                     # Destroy cached identity and inverses as we have modified the group
	 }
  if (@_ == 4)                                                                  # Add a product to the group for a*b
   {$𝗲->{$a}{$b} = $c;
		return $g;                                                                  # Return group to allow for chaining if desired
	 }
  if (@_ == 5)                                                                  # Add products to the group for a*b and b*a
   {$𝗲->{$a}{$b} = $c;
    $𝗲->{$b}{$a} = $𝗰;
		return $g;                                                                  # Return group to allow for chaining if desired
	 }
	confess "Wrong number of parameters, should be 3 to get a prior product or 4 for single put or 5 for double put!";
 }

sub identity($)                                                                 # Find the identity element - assumes that the group has been checked for uniqueness and closure
 {my ($g) = @_;                                                                 # Group
  my $e   = e($g);                                                              # Identity from cache
  return $e if $e;                                                              # Check cache
	my $𝗲 = 𝗲($g);                                                                # Elements
  for my $a(keys %$𝗲)                                                           # Find the identity and confirm that there is only one
	 {my $n = 0;                                                                  # Number of elements for which $a is an identity
    for my $b(keys %$𝗲)
		 {last unless $𝗲->{$a}{$b} eq $b and $𝗲->{$b}{$a} eq $b;                    # Check whether it could be an indentity
		  $n++                                                                      # Possible identity
		 }
		return $g->{&Identity} = $a if $n == keys %$𝗲                               # Save identity in cache
   }
  confess "No identity found!";
 }

sub inverse($$)                                                                 # Find the inverse of an element - assumes that identity has been dound
 {my ($g, $a) = @_;                                                             # Group, element for which an inverse is required
	my $𝗲 = 𝗲($g);                                                                # Elements
	my $i = i($g);                                                                # Inverses
  confess "Not a group element: $a" unless defined $𝗲->{$a};                    # Validate element
  return $i->{$a} if defined($i) and defined($i->{$a});                         # Return if inverse is in cache
  my $e = identity($g);                                                         # Find identity
  for my $b(keys %$𝗲)                                                           # Each element
	 {my ($p, $q) = ($𝗲->{$a}{$b}, $𝗲->{$b}{$a});                                 # Product each way
		if ($p eq $e and $q eq $e)                                                  # Inverse if both products equal identity
		 {$g->{&Inverses}->{$a} = $b;                                               # Cache inverse
			return $b                                                                 # Inverse
		 }
   }
  confess "No inverse found for $a"
 }

sub orders($)                                                                   # Order of each element
 {my ($g) = @_;
	my $e = e($g);                                                                # Identity
	my $𝗲 = 𝗲($g);                                                                # Elements
  for my $A(keys %$𝗲)                                                           # Each element
   {my $a = $A;
    my $o = 1;
		for(1..keys %$𝗲)                                                            # Multiply until we reach the identity
		 {last if $a eq $e;
		  $a = $𝗲->{$a}{$A};
      ++$o;
		 }
		$g->{&Orders}{$A} = $o;                                                     # Save order
   }
  $g->{&Orders}{$e} = 0;                                                        # Correct order of identity
 }

sub order($;$)                                                                  # Order of an element
 {my ($g, $a) = @_;
	my $𝗲 = 𝗲($g);
  return scalar keys %$𝗲 if @_ == 1;                                            # Order of group
  $g->{&Orders}{$a};                                                            # Order of element
 }

sub elements($)                                                                 # Elements in group
 {my ($g) = @_;
	my $𝗲 = 𝗲($g);
  sort keys %$𝗲
 }

sub check($)                                                                    # Check that it really is a group
 {my ($g) = @_;
	my $𝗲 = 𝗲($g);                                                                # Elements
  for   my $a(keys %$𝗲)                                                         # Check each operation
   {my %row; my %col;                                                           # Check each element is unique in each row and in each column
		for my $b(keys %$𝗲)
     {my ($c, $𝗰) = ($𝗲->{$a}{$b}, $𝗲->{$b}{$a});                               # Result of operation each way
      confess "Missing product for $a * $b" unless defined $c;
      confess "Missing product for $b * $a" unless defined $𝗰;
      confess "Group not closed for $c == $a * $b" unless defined $𝗲->{$c};
      confess "Group not closed for $𝗰 == $b * $a" unless defined $𝗲->{$𝗰};
      if (defined(my $p = $row{$c}))                                            # Check each product in a row is unique
       {confess "Duplicate product $c == $a * $b and $a * $p";                  # Helpfully provided duplicated product
			 }
      $row{$c} = $b;                                                            # Record product as already present in this row
      if (defined(my $p = $col{$𝗰}))                                            # Check each product in a column is unique
       {confess "Duplicate product $𝗰 == $b * $a and $b * $p";                  # Helpfully provided duplicated product
		   }
      $row{$c} = $b;                                                            # Record product as already present in this column
     }
   }
  identity($g);                                                                 # Check that the group has an identity
  for my $a(keys %$𝗲)                                                           # Find the identity and confirm that there is only one
   {confess "No inverse for: $a" unless defined inverse($g, $a);                # Helpfully indicate element with no inverse
   }
  orders($g);                                                                   # Order if each element
  1                                                                             # It is a group
 }

sub Group(&@)                                                                   # Create a group
 {my $sub = shift;                                                              # Operator, elements
  my $g = bless {&Elements=>{}, &Inverses=>{}, &Orders=>{}};                    # Empty group
  for   my $a(@_)                                                               # Create multiplication table
   {for my $b(@_)
     {$g->{&Elements}{$a}{$b} = &$sub($a, $b);
	   }
	 }
	check($g);                                                                    # Check we have a group
	$g                                                                            # Return results
 }

sub abelian($)                                                                  # Abelian?
 {my ($g) = @_;                                                                 # Group
	my $𝗲 = 𝗲($g);                                                                # Elements
  for   my $a(keys %$𝗲)                                                         # Check each operation
   {for my $b(keys %$𝗲)
     {return 0 unless $g->{&Elements}{$a}{$b} == $g->{&Elements}{$b}{$a};
	   }
	 }
	1                                                                             # Abelian
 }

sub cyclic($)                                                                   # Cyclic - return a generating element or undef if no such element
 {my ($g) = @_;                                                                 # Group
	my $N = order($g);
  while(my ($e, $o) = each %{$g->{&Orders}})                                    # Order of each element
   {return $e if $o && $o == $N;                                                # Return generating element
   }
	undef                                                                         # Not cyclic
 }

sub subGroup($@)                                                                # Sub group
 {my $g = shift;                                                                # Group followed by sub group elements excluding identity
	my %g = map {$_=>1} @_, $g->e;                                                # Add identity as that is always present in a sub group
	for   my $a(@_)                                                               # Check each product
   {for my $b(@_)
     {return 0 unless $g{$g->{&Elements}{$a}{$b}};                              # Not a sub group unless product is within sub group
		 }
	 }
	1                                                                             # Sub group
 }

sub homoMorphic($$@)                                                            # Homomorphism between two groups
 {my $g = shift;                                                                # First group
	my $𝗴 = shift;                                                                # Second group
  ref($𝗴) eq __PACKAGE__ or confess "Second parameter must be a group too!";    # Check it is a group isomorphism
  my %m = @_;                                                                   # Mapping between groups
  $m{e($g)} = e($𝗴);                                                            # Include identity to identity in mapping
	my $e = 𝗲($g);                                                                # Elements in first group
	my $𝗲 = 𝗲($𝗴);                                                                # Elements in second group
  while(my ($a, $b) = each %m)                                                  # Check elements come from the correct groups
   {confess "Not a group element of first group: $a"  unless $e->{$a};
    confess "Not a group element of second group: $b" unless $𝗲->{$b};
	 }
  for   my $a(keys %m)                                                          # Check each product
   {for my $b(keys %m)
     {return 0 unless $m{$e->{$a}{$b}} eq $𝗲->{$m{$a}}{$m{$b}};                 # Apply
		 }
	 }
	1                                                                             # Homomorphic
 }

sub isoMorphic($$@)                                                             # Isomorphic
 {my $g = shift;                                                                # First group
	my $𝗴 = shift;                                                                # Second group
  ref($𝗴) eq __PACKAGE__ or confess "Second parameter must be a group too!";    # Check it is a group isomorphism
  my %m = @_;                                                                   # Mapping between groups
  my %𝗺 = reverse %m;                                                           # Mapping between groups
  keys(%m) == keys(%𝗺) or confess "Please supply a bijective mapping!";         # Check that the mapping is bijective
	$g->homoMorphic($𝗴, %m) && $𝗴->homoMorphic($g, %𝗺)                            # Bijective homomorphism is an isomorphism
 }

sub isoMorphisms(&$$)                                                           # Find all the isomorphisms between two groups
 {my ($sub, $g, $𝗴) = @_;                                                       # Sub to call to process found isomorphisms, first group, second group
  ref($𝗴) eq __PACKAGE__ or confess "Second parameter must be a group too!";    # Check it is a group
  order($g) == order($𝗴) or confess "Groups have different orders!";            # Check groups have same order
  my $i = e($g);                                                                # Identity of first group
  my $𝗶 = e($𝗴);                                                                # Identity of second group
  my $e = [grep {$_ ne $i} sort keys %{𝗲($g)}];                                 # Elements of first group in fixed order without identity
  my $𝗲 = [grep {$_ ne $𝗶} sort keys %{𝗲($𝗴)}];                                 # Elements of second group in fixed order without identity
  permute                                                                       # Permute the elements to obtain all possible mappings
   {my %m = map {$$e[$_]=>$$𝗲[$_[$_]]} 0..$#_;                                  # Mapping to test
    &$sub(%m) if isoMorphic($g, $𝗴, %m);                                        # Process mapping if isomorphic
	 } 0..$#$e;                                                                   # Elements to permute
 }

sub autoMorphic($@)                                                             # Automorphic
 {my $g = shift;                                                                # Group
	$g->isoMorphic($g, @_)                                                        # Check
 }

sub autoMorphisms(&$)                                                           # Find all the automorphisms of a group
 {my ($sub, $g) = @_;                                                           # Sub to call to process found automorphisms, group
  &isoMorphisms($sub,$g,$g)
 }

# Export details

require 5;
require Exporter;

use vars qw(@ISA @EXPORT $VERSION);

@ISA     = qw(Exporter);
@EXPORT  = qw(Group autoMorphisms isoMorphisms);

our $VERSION = '1.002'; # Sunday 23 Aug 2015

=head1 Description

Find automorphisms of groups and isomorphisms between groups.

A group automorphism is a bijection on the set of elements of a group which
preserves the group product.

A group isomorphism is a bijection between the sets of elements of two groups
which preserves the group product.

=head2 identity(group)

Returns the identity element.

=head2 inverse(group, element)

Returns the inverse of an element.

=head2 orders(group)

Returns a hash which supplies the order of each element. The identity is
assigned an order of zero.

=head2 order(group, element)

Returns the order of an element with the group.

=head2 elements(group)

Returns a hash whose keys are the elements if the group. The value at each key
of this hash is another hash which gives the product in this group.

=head2 Group sub elements...

Creates a group with the specified elements as multiplied by C<sub>. The first
parameter is a subroutine that forms the product of each pair of elements drawn
from the following list of elements.

=head2 abelian(group)

Returns 1 if the group is Abelian, else 0.

=head2 cyclic(group)

If the group is cyclic, returns an element that generates the group, else
undef.

=head2 subGroup(groups, elements...)

Returns 1 if the elements specified plus the identity element form a sub group
of the group else 0.

=head2 homoMorphic(group1, group2, mapping...)

Returns 1 if mapping forms a homomorphism from group 1 to group 2, else 0.

The mapping is a subset of the Cartesian product of the elements of
group 1 and the elements of group 2 flattened into a list. The pair:

 (identity of group 1, identity of group 2)

is added for you so there is no need to specify it unless you wish to.

=head2 isoMorphic(group1, group2, mapping...)

Returns 1 if the mapping is an isomorphism from group 1 to group 2, else 0.

The mapping is a subset of the Cartesian product of the elements of
group 1 and the elements of group 2 flattened into a list. The pair:

 (identity of group 1, identity of group 2)

is added for you so there is no need to specify it unless you wish to.

=head2 isoMorphisms sub group1, group 2

Finds all the isomorphisms between two groups and calls C<sub> to process each
of them as they are discovered.

The parameter list to sub is a pair for each element of group 1 indicating the
corresponding element of group 2 under the isomorphism.

=head2 autoMorphic(group, mapping)

Returns 1 if the mapping is an automorphism from the group to itself, else 0.

The mapping is a subset of the Cartesian product of the elements of
the group squared flattened into a list. The pair:

 (identity of group, identity of group)

is added for you so there is no need to specify it unless you wish to.

=head2 autoMorphisms sub group

Finds all the automorphisms of the groups and calls C<sub> to process each
of them as they are discovered.

The parameter list to sub is a pair for each element of the group indicating the
corresponding element under the automorphism.

=head1 Export

The C<Group()>, C<isoMorphisms()>, C<autoMorphisms()> functions are exported.

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

Philip R Brenan at gmail dot com

http://www.appaapps.com

=head1 See Also

=over

=item L<Math::Cartesian::Product>

=item L<Math::Permute::List>

=back

=head1 Copyright

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
