#############################################################################
# Math/Big/Factors.pm -- factor big numbers into prime factors

package Math::Big::Factors;

require  5.006002;  # requires this Perl version or later

use strict;
use warnings;

use Math::BigInt;
use Math::BigFloat;
use Math::Big;
use Exporter;

our $VERSION   = '1.14';
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( wheel factors_wheel
                  );

sub wheel
  {
  # calculate a prime-wheel of order $o
  my $o = abs(shift || 1);              # >= 1

  # some primitive wheels as shortcut:
  return [ Math::BigInt->new(2), Math::BigInt->new(1) ] if $o == 1;

  my @primes = Math::Big::primes($o*5);		# initial primes, get some more

  my $mul = Math::BigInt->new(1); my @wheel;
  for (my $i = 0; $i < $o; $i++)
    {
    #print "$primes[$i]\n";
    $mul *= $primes[$i]; push @wheel,$primes[$i];
    }
  #print "Mul $mul\n";
  my $last = $wheel[-1];                        # get biggest initial
  #print "last is $last\n";
  # now sieve any number that is a multiply of one of the inital ones
  @primes = ();                                 # undef => leftover
  foreach (@wheel)
    {
    next if $_ == 2;                            # dont mark these, we skip 'em
    my $i = $_; my $add = $i;
    while ($i < $mul)
      {
      $primes[$i] = 1; $i += $add;
      }
    }
  push @wheel, Math::BigInt->new(1);
  my $i = $last;
  while ($i < $mul)
    {
    push @wheel,$i if !defined $primes[$i]; $i += 2;    # skip even ones
    }
  \@wheel;
  }

sub _transform_wheel
  {
  # from a given prime-wheel, calculate a increment table that can be used
  # to step trough numbers
  # input:  ref to array with prime wheel
  # output: ($restart,$ref_to_add_table);

  my (@wheel,$we);
  my $add = shift; shift @$add;         # remove the first 2 from wheel

  if (@$add == 1)                       # order 1
    {
    my $two = Math::BigInt->new(2);
    # (2,2) or (2,2,2,2,2,2) etc would do, too
    @wheel = ($two->copy(),$two->copy(),$two->copy(),$two->copy());
    return (1,\@wheel);
    }
  # from the list of divisors above create a add-table which we can take to
  # increment from 3 onwards. The tabe consists of two parts, the second part
  # will be repeatedly used
  my $last = -1; my $mod = 2; my $i = 0;
  # create the increment part for the initial primes (3,5, or 3,5,7 etc)
  while ($add->[$i] != 1)
    {
    $mod *= $add->[$i];
    push @wheel, $add->[$i] - $last if $last != -1;     # skip the first
    #print $wheel[-1],"\n" if $last != -1;
    $last = $add->[$i]; $i++;
    }
  #print "mod $mod\n";
  my $border = $i-1;                                    # account for ++
  my $length = scalar @$add-$i;
  my $ws = $border+$length;                             # remember this
  #print "border: $border length $length $mod\n";

  # now we add two arrays in a row, both are equal except the first element
  # which is in case A a step from the last inital prime to the second in list
  # and in case B a step from '1' to the second in list

  #print "add[border+1]: ",$add->[$border+1]," add[border] $add->[$border]\n";
  $wheel[$border] = $add->[$border+2]-$add->[$border];
  $wheel[$border+$length] = $add->[$border+2]-1;
  # and last add a wrap-around around $mod
  #print "last: ",$add->[-1],"\n";
  $wheel[$border+$length-1] = 1+$mod-$add->[-1];
  $wheel[$border+$length*2-1] = $wheel[$border+$length-1];

  $i = $border + 1;
  # now fill in the rest
  while ($i < $length+$border-1)
    {
    $wheel[$i] = $add->[$i+2]-$add->[$i+1];
    $wheel[$i+$length] = $wheel[$i];
    $i++;
    }
  ($ws,\@wheel);
  }

sub factors_wheel
  {
  my $n = shift;
  my $o = abs(shift || 1);

  $n = Math::BigInt->new($n) unless ref $n;
  my $two = Math::BigInt->new(2);
  my $three = Math::BigInt->new(3);

  my @factors = ();
  my $x = $n->copy();

  return ($x) if $x < 4;
  my ($i,$y,$w,$div,$rem);

  #print "Using a wheel of order $o, length ";
  my $wheel = wheel($o);
  #print scalar @$wheel,":\n";
  my ($ws,$add) = _transform_wheel($wheel); undef $wheel;
  my $we = scalar @$add - 1;

  # reduce to odd number (after that, no odd left-over divisior will ocur)
  while (($x->is_even) && (!$x->is_zero))
    {
    push @factors, $two->copy();
    #print "factoring $x (",$x->length(),")\n";
    #print "2\n";
    $x /= $two;
    }
  # 8 => 6 => 3, 7, 6 => 3, 5, 4 => 2 => 1, 3, 2 => 1, are all prime
  # so the first number interesting for us is 9
  my $op = 0;
 OUTER:
  while ($x > 8)
    {
    #print "factoring $x (",$x->length(),")\n";
    $i = $three; $w = 0;
    while ($i < $x)             # should be sqrt()
      {
      # $steps++;
      # $op = 0, print "$i\r" if $op++ == 1024;
      $y = $x->copy();
      ($div,$rem) = $y->bdiv($i);
      if ($rem == 0)
        {
        #print "$i\n";
        push @factors,$i;
        $x = $div; next OUTER;
        }
      #print "$i + ",$add->[$w]," ($w)\n";
      #$i += 2;                                   # trial div by odd numbers
      $i += $add->[$w];
      #print "restart $w $ws\n" if $w == $we;  # wheel of 2,3,5,7...
      $w = $ws if $w++ == $we;                  # wheel of 2,3,5,7...
      #exit if $i > 100000;
      }
    last;
    }
  push @factors,$x if $x != 1 || $n == 1;
  @factors;
  }

sub _factor
  {
  # later: factor ( n => $n, algorithmn => 'wheel', order => 3 );
  }

1;

__END__

#############################################################################

=pod

=head1 NAME

Math::Big::Factors - factor big numbers into prime factors using different algorithmns

=head1 SYNOPSIS

    use Math::Big::Factors;

    $wheel	= wheel (4);			# prime number wheel of 2,3,5,7
    print $wheel->[0],$wheel->[1],$wheel->[2],$wheel->[3],"\n";

    @factors	= factors_wheel(19*71*59*3,1);	# using prime wheel of order 1
    @factors	= factors_wheel(19*71*59*3,7);	# using prime wheel of order 7

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt, Math::BigFloat, Math::Big

=head1 EXPORTS

Exports nothing on default, but can export C<wheel()>, C<factor()>,
C<factors_wheel()>;

=head1 DESCRIPTION

This module contains some routines that may come in handy when you want to
factor big numbers into prime factors.
examples.

=head1 FUNCTIONS

=over

=item wheel()

	$wheel = wheel($o);

Returns a reference to a prime wheel of order $o. This is used for factoring
numbers into prime factors.

A wheel of order 7 saves about 50% of all trial divisions over the normal
trial division factor algorihmn. Higher oder will save less and less, but
a wheel of size 8 takes so long to compute and much memory that it is not
worth the effort, limiting wheels of practicable size to order 7. For very
small numbers the computation of the wheel of order 7 may actually take
longer than the factorization, but anything that has more than 10 digits will
usually benefit from order 7.

=item factors_wheel()

Factor a number into its prime factors and return a list of factors.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-big at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Big>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Big::Factors

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Big>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Big>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-Big>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Big/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Big>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

=over

=item *

Tels http://bloodgate.com 2001-2007.

=item *

Peter John Acklam E<lt>pjacklam@online.noE<gt> 2016.

=back

=cut
