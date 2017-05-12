package Math::Systems;
$VERSION = "0.01";
use 5.006;
use Math::Matrix;
use strict;
use Carp;

sub new
{
  my ($self, @matrix) = @_;
  return bless (\@matrix, $self);
}

sub solve
{
  my ($self) = @_; #OO
  my @matrix = @{$self}; #Get the Data passed from constuctor. Hopefully a Matrix.
  my (@answers, @back, @solutions, $x); #Some Declarations
  for my $rows (@matrix)
  {
    #For each of the Matrix rows
    push (@answers, pop @{$rows}); #Take off the last one; that's the answer
    push (@back, [@{$rows}]); #Backup!!
  }
  my $denominator = Math::Matrix->new (@matrix)->determinant; #Get the determinant of the main matrix.
  foreach my $a (0 .. $#matrix) { #For all of the Matrixes
  foreach (0 .. $#matrix) { #For all of the Rows
  splice (@{$matrix[$_]},$a, 1, $answers[$_]); #Subsitute a column 1 by one with the answers
}
push (@solutions, Math::Matrix->new (@matrix)->determinant / $denominator); #Magically, the new matrix created by this's determinant over the previous determinent is the value of the subsituted column's variable. Huh?
delete (@matrix[0 .. $#matrix]);
for my $rows (@back)
{
  push (@matrix, [@{$rows}]); #Restart the Matrix Variable!
}


}
return @solutions; #This should be the Solutions. If not, Call Krammer.
}



1;
__END__

=head1 NAME

Math::Systems - Perl extension solving systems of Equations.

=head1 SYNOPSIS

  use Math::Systems;
  $a = Math::Systems->new(
     [1,  2,   3],
     [1,  -2 ,  -3],
  )
  @solutions = $a->solve;

=head1 DESCRIPTION

Solves systems of equations using Krammer's rule.
If you look at the Solve method you'll understand Krammer's rule (I think?)

Basically a system of equations is more than one equation/variable your solving.
This module REQUIRES you have 1 equation per each coefficent. Try not to use
too many equations. 3 equations is probably the limit of reason. But if you don't
mind long compilation time, go for as many as you want.

This module uses (and ovbiously requires you have) Math::Matrix to do all the
Matrix work. Please take a look at that module for details do you can see exactly
what is happening. There are no arguements in this module except for the Matrix
which will be brought to Math::Matrix.

Also, keep in mind, there are no error messenging. I will of course change that
someday, but for now I'm satisfied that I can solve systems of equations. Don't
allow error-prone things to be written in. But, there are of course times when
you won't be able to figure out the stupid answer and this module will absolutly
act like it did a great job, and at the same time, fail. So, keep that
in mind.

BETA means something. It's not good.

=head1 METHODS

=head2 new

Pass the Equation coeffients/answers to this. The same way you do it in Math::Matrix.
This is the constructor. If the equations are 2x + 3y = 10 and 3x + 2y = 10 then

     Math::Systems->new(
           [2, 3, 10],
           [3, 2, 10]
     );

=head2 solve

Solves it. Returns list of solutions in order. Take no arguements. Ever.

=head1 AUTHOR

Will Gunther <lt>williamgunther@aol.com<gt>

=head1 SEE ALSO

L<perl>. L<Math::Matrix>

=cut