package LCS::Similar;

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.03';
#use utf8;
#use Data::Dumper;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub LCS {
  my ($self, $X, $Y, $compare, $threshold) = @_;

  $compare //= sub { $_[0] eq $_[1] };

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $c = [];
  my ($i,$j);
  for ($i=0;$i<=$m;$i++) {
    for ($j=0;$j<=$n;$j++) {
      $c->[$i][$j]=0;
    }
  }
  for ($i=1;$i<=$m;$i++) {
    for ($j=1;$j<=$n;$j++) {
      $c->[$i][$j] = $self->max3(
        &$compare(
            $X->[$i-1],
            $Y->[$j-1],
            $threshold
          ) + $c->[$i-1][$j-1],
        $c->[$i][$j-1],
        $c->[$i-1][$j],
      );
    }
  }
  my $path = $self->_lcs($X,$Y,$c,$m,$n,[],$compare, $threshold);
  return $path;
}


sub max { ($_[1] > $_[2]) ? $_[1] : $_[2]; }

sub max3 {
  ($_[1] >= $_[2])
    ? ($_[1] >= $_[3]
      ? $_[1] : $_[3]
    )
    : ($_[2] >= $_[3]
      ? $_[2] : $_[3]
    );
}

sub _lcs {
  my ($self,$X,$Y,$c,$i,$j,$L,$compare, $threshold) = @_;

  while ($i > 0 && $j > 0) {
    if ( &$compare($X->[$i-1],$Y->[$j-1], $threshold) ) {
      unshift @{$L},[$i-1,$j-1];
      $i--;
      $j--;
    }
    elsif ($c->[$i][$j] == $c->[$i-1][$j]) {
      $i--;
    }
    else {
      $j--;
    }
  }
  return $L;
}

1;

__END__

=head1 NAME

LCS::Similar - allow differences in the compared elements of
                 Longest Common Subsequence (LCS) Algorithm

=begin html

<a href="https://travis-ci.org/wollmers/LCS-Similar"><img src="https://travis-ci.org/wollmers/LCS-Similar.png" alt="LCS-Similar"></a>
<a href='https://coveralls.io/r/wollmers/LCS-Similar?branch=master'><img src='https://coveralls.io/repos/wollmers/LCS-Similar/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/LCS-Similar'><img src='http://cpants.cpanauthors.org/dist/LCS-Similar.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/LCS-Similar"><img src="https://badge.fury.io/pl/LCS-Similar.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use LCS::Similar;

  $alg = LCS::Similar->new;
  @lcs = $alg->LCS(\@a,\@b);

=head1 ABSTRACT

LCS::Similar allows differences in the compared elements.

=head1 DESCRIPTION

Pure LCS algorithms can be used for global alignment of two sequencies.

Usually they provide one result, but there can be more than one solution
fulfilling the criterion of being longest.

For example this two sequencies have two possible LCS:

   # solution1
   @sequence1 = qw/a b   d   /;
   @sequence2 = qw/  b a d c /;
   @lcs1      = qw/  b   d   /;

   # solution2
   @sequence1 = qw/  a b d   /;
   @sequence2 = qw/b a   d c /;
   @lcs2      = qw/  a   d   /;

Or an example of mistyping:

   eo___nnnnnicaio
    |   |    ||| |
   commun____icato

This is an actual result of a pure LCS algorithm. Here the letter n
of the second line could align in 5 possible ways with one of the letters n
of the first line, and the LCS will always have a length of 6.

But this solution better maps the mismatches:

   eonnnnnicaio
   ~|~~~ ||||~|
   commu_nicato

Here the tilde ~ represents similarity of the aligned characters.

With a function returning e.g. a similarity of 0.7 for a comparison of
similar characters this module takes similarity into account for alignment.

See examples.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4


=item LCS(\@a,\@b,\&similarity,$threshold)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 2-element array refs.

The third argument is the reference of a subroutine comparing two elements and
returning a number between 0 and 1. Where 0 means unequal and 1 means equal.

Without a subroutine the module falls back to string comparison.

The fourth argument is a threshold passed to the subroutine.

=item max($number1, $number2)

Returns the maximum of two numbers.

=item max3($number1, $number2, $number3)

Returns the maximum of three numbers.

=back

=head2 EXPORT

None by design.

=head1 EXAMPLES

=head2 Aline two textfiles

  use LCS::Similar;
  use LCS;

  binmode(STDOUT,":encoding(UTF-8)");

  open(my $in1,"<:encoding(UTF-8)",'file1')
    or die "cannot open file1: $!";
  open(my $in2,"<:encoding(UTF-8)",'file2')
    or die "cannot open file2: $!";

  my $lines1 = [<$in1>];
  my $lines2 = [<$in2>];

  sub similarity {
    my ($a, $b, $threshold) = @_;

    $a //= '';
    $b //= '';
    $threshold //= 0.7;

    return 1 if ($a eq $b);
    return 1 if (!$a eq !$b); # avoid division by zero

    # length of LCS
    my $llcs = LCS->LLCS(
      [split(//,$a)],
      [split(//,$b)],
    );

    # the standard formula
    my $similarity = (2 * $llcs) / (length($a) + length($b));
    return $similarity if ($similarity >= $threshold);
    return 0;
  }

  # aligned indices of elements similar more than $threshold 0.5
  my $lcs = LCS::Similar->LCS( $lines1, $lines2, \&similarity, 0.5 );

  # map indices and not so similar elements into AoA of lines
  my $aligned = LCS->lcs2align( $lines1, $lines2, $lcs );

  # print them
  for my $chunk (@$aligned) {
    print 'a: ',$chunk->[0];
    print 'b: ',$chunk->[1];
    print "\n";
  }

=head2 Aline two words

  use LCS::Similar;
  use LCS;

  my $word1 = [ split(//, 'eonnnnnicaio') ];
  my $word1 = [ split(//, 'communicato' ) ];

  sub confusable {
    my ($a, $b, $threshold) = @_;

    $a //= '';
    $b //= '';
    $threshold //= 0.7;

    return 1 if ($a eq $b);
    return 1 if (!$a && !$b);

    my $map = {
      'e' => 'c',
      'c' => 'e',
      'm' => 'n',
      'n' => 'm',
      'i' => 't',
      't' => 'i',
    };

    return $threshold if (exists $map->{$a} && $map->{$a} eq $b);
    return 0;
  }

  my $aligned = [
    LCS->align2strings(
      LCS->lcs2align(
        $word1,
        $word2,
        LCS::Similar->LCS( $word1, $word2, \&confusable, 0.7 )
      )
    )
  ];
  print 'a: ',$aligned->[0],"\n"; # eonnnnnicaio
  print 'b: ',$aligned->[1],"\n"; # commu_nicato
  print "\n";


=head1 SEE ALSO

Algorithm::Diff

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
