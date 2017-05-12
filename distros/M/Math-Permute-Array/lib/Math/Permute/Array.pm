package Math::Permute::Array;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::Permute::Array ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw()],
                     'Permute' => [ qw(Permute) ],
                     'Apply_on_perms' => [ qw(Apply_on_perms) ]
                   );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
 Permute
 Apply_on_perms
);

our $VERSION = '0.043';


sub new
{
  my $class = shift;
  my $self = {};
  $self->{array}    = shift;
  $self->{iterator} = 0;
  $self->{cardinal} = undef;
  bless($self, $class);
  return undef unless (defined $self->{array});
  return $self;
}

#nice implementation from the cookbook
#but mine seems lightly more efficient
#sub N2Permute
#{
#  my $rank = shift;
#  my $size = shift;
#  my @res;
#
#  my $i=1;
#  while($i<=$size){
#    push @res, $rank % ($i);
#    $rank = int($rank / ($i));
#    $i++;
#  }
#  return @res;
#}

sub Permute
{
  my $rest = shift;
  my $array = shift;
  return undef unless (defined $rest and defined $array);
  my @array = @{$array};
  my @res;

#  my $size = $#$array+1;
# my @perm = N2Permute($k,$size);
#push @res, splice(@array, (pop @perm), 1 )while @perm;

  my $i = 0;
  while($rest != 0){
    $res[$i] = splice @array, $rest % ($#array + 1), 1;
    $rest = int($rest / ($#array + 2));
    $i++;
  }
  push @res, @array;

  return \@res;
}

sub permutation
{
  my $self = shift;
  my $rest = shift;
  return undef unless (defined $rest);
  my @array = @{$self->{array}};
  my @res;
  my $i = 0;
  while($rest != 0){
    $res[$i] = splice @array, $rest % ($#array + 1), 1;
    $rest = int($rest / ($#array + 2));
    $i++;
  }
  push @res, @array;
  return \@res;
}

sub Apply_on_perms(&@)
{
  my $func = shift;
  my $array = shift;
  return undef unless (defined $func and defined $array);
  my $rest;
  my $i;
  my $j;
  my @array = @{$array};
  my $size = $#array+1;
  my $card = factorial($size);
  my @res;
  for($j=0;$j<$card;$j++){
    @res = ();
    $rest = $j;
    $i = 0;
    while($rest != 0){
      $res[$i] = splice @array, $rest % ($#array + 1), 1;
      $rest = int($rest / ($#array + 2));
      $i++;
    }
    push @res, @array;
    &$func(@res);
    @array = @{$array};
  }
  return 0;
}

sub cur
{
  my $self = shift;
  return Math::Permute::Array::Permute($self->{iterator},$self->{array});
}

sub prev
{
  my $self = shift;
  return undef if($self->{iterator} == 0);
  $self->{iterator}--;
  return Math::Permute::Array::Permute($self->{iterator},$self->{array});
}

sub next
{
  my $self = shift;
  return undef if($self->{iterator} >= $self->cardinal() - 1);
  $self->{iterator}++;
  return Math::Permute::Array::Permute($self->{iterator},$self->{array});
}

sub cardinal
{
  my $self = shift;
  unless(defined $self->{cardinal}){
    $self->{cardinal} = factorial($#{$self->{array}} + 1);
  }
  return $self->{cardinal};
}

#this part come from:
# www.theperlreview.com/SamplePages/ThePerlReview-v5i1.p23.pdf
# Author: Alberto Manuel Simoes
sub factorial
{
    my $value = shift;
    my $res = 1;
    while ($value > 1) {
      $res *= $value;
      $value--;
    }
    return $res;
}

1;

__END__

=head1 NAME

Math::Permute::Array - Perl extension for computing any permutation of an array.
The permutation could be access by an index in [0,cardinal] or by iterating with prev, cur and next.


=head1 SYNOPSIS

    use Math::Permute::Array;

    print "permutation with direct call to Permutate\n";
    my $i;
    my @array = (1,2,3);
    foreach $i (0..5){
      my @tmp = @{Math::Permute::Array::Permute($i,\@array)};
      print "@tmp\n";
    }

    print "permutation with counter\n";
    my $p = new Math::Permute::Array(\@array);
    foreach $i (0..$p->cardinal()-1){
      my @tmp = @{$p->permutation($i)};
      print "@tmp\n";
    }

    print "permutation with next\n";
    $p = new Math::Permute::Array(\@array);
      my @tmp = @{$p->cur()};
      print "@tmp\n";
    foreach $i (1..$p->cardinal()-1){
      @tmp = @{$p->next()};
      print "@tmp\n";
    }

    print "permutation with prev\n";
    my $tmp=\@tmp;
    while(defined $tmp){
      @tmp = @{$tmp};
      print "@tmp\n";
      $tmp = $p->prev();
    }

    print "Apply a function on all permutations\n";
    Math::Permute::Array::Apply_on_perms { print "@_\n"} \@array;


the output should be:

    permutation with direct call to Permute
    1 2 3
    2 1 3
    3 1 2
    1 3 2
    2 3 1
    3 2 1
    1 2 3
    permutation with counter
    1 2 3
    2 1 3
    3 1 2
    1 3 2
    2 3 1
    3 2 1
    1 2 3
    permutation with next
    1 2 3
    2 1 3
    3 1 2
    1 3 2
    2 3 1
    3 2 1
    1 2 3
    Apply a function on all permutations
    1 2 3
    2 1 3
    3 1 2
    1 3 2
    2 3 1
    3 2 1
    1 2 3


=head1 DESCRIPTION

This module compute the i^{th} permutation of an array recursively.
The main advantage of this module is the fact that you could access to
any permutation in the order that you want.
Moreover this module doesn't use a lot of memory because the permutation
is compute.
the cost for computing one permutation is O(n).

it could be optimize by doing this iteratively but it seems efficient.
Thus this module doesn't need a lot of memory because the permutation
isn't stored.

=head2 EXPORT

=over

=item Permute [index, $ref_array]

Returns a reference on the index^{th} permutation for the array. This function
should be called directly as in the example.

=item Apply_on_perms [func, $ref_array]

Applies the function on each permutation (this interface is
efficient but limited).

=item new [ref_array]

Returns a permutor object for the given items.

=item next

Called on a permutor, it returns a reference on the array contening the next permutation.

=item prev

Called on a permutor, it returns a reference on the array contening the previous permutation.

=item cur

Called on a permutor, it returns a reference on the array contening the current permutation.

=item permutation [index, @array]

Called on a permutor, it returns a reference on a array contening index^{th} permutation for the array.

=item cardinal

Called on a permutor, it returns the number of permutations

=back

=head2 Internal functions

=over

=item factorial [n]

returns the factorial of n. This is a internal function to calculate the
number of permutations.

=back

=head1 SEE ALSO

=over

=item L<Math::Permute::List>

=item L<Algorithm::Permute>

=item L<Algorithm::FastPermute>

=back

=head1 AUTHOR

jean-noel quintin, E<lt>quintin_at_imag_dot_frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by jean-noel quintin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
