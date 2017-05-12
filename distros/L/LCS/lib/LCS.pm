package LCS;

use strict;
use warnings;

use 5.006;
our $VERSION = '0.11';

use Data::Dumper;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub align {
  my ($self, $X, $Y) = @_;

  return $self->lcs2align(
    $X, $Y, $self->LCS($X,$Y)
  );
}

sub lcs2align {
  my ($self, $X, $Y, $LCS) = @_;

  my $hunks = [];

  my $Xcurrent = -1;
  my $Ycurrent = -1;
  my $Xtemp;
  my $Ytemp;

  for my $hunk (@$LCS) {
    while ( ($Xcurrent+1 < $hunk->[0] ||  $Ycurrent+1 < $hunk->[1]) ) {
      $Xtemp = '';
      $Ytemp = '';
      if ($Xcurrent+1 < $hunk->[0]) {
        $Xcurrent++;
        $Xtemp = $X->[$Xcurrent];
      }
      if ($Ycurrent+1 < $hunk->[1]) {
        $Ycurrent++;
        $Ytemp = $Y->[$Ycurrent];
      }
      push @$hunks,[$Xtemp,$Ytemp];
    }

    $Xcurrent = $hunk->[0];
    $Ycurrent = $hunk->[1];
    push @$hunks,[$X->[$Xcurrent],$Y->[$Ycurrent]]; # elements
  }
  while ( ($Xcurrent+1 <= $#$X ||  $Ycurrent+1 <= $#$Y) ) {
    $Xtemp = '';
    $Ytemp = '';
    if ($Xcurrent+1 <= $#$X) {
      $Xcurrent++;
      $Xtemp = $X->[$Xcurrent];
    }
    if ($Ycurrent+1 <= $#$Y) {
      $Ycurrent++;
      $Ytemp = $Y->[$Ycurrent];
    }
    push @$hunks,[$Xtemp,$Ytemp];
  }
  return $hunks;
}

sub sequences2hunks {
  my ($self, $a, $b) = @_;
  return [ map { [ $a->[$_], $b->[$_] ] } 0..$#$a ];
}

sub clcs2lcs {
  my ($self, $clcs) = @_;
  my $lcs = [];
  for my $entry (@$clcs) {
    for (my $i = 0; $i < $entry->[2];$i++) {
      push @$lcs,[$entry->[0]+$i,$entry->[1]+$i];
    }
  }
  return $lcs;
}

sub lcs2clcs {
  my ($self, $lcs) = @_;
  my $clcs = [];
  for my $entry (@$lcs) {
    if (@$clcs && $clcs->[-1]->[0] + $clcs->[-1]->[2] == $entry->[0]) {
      $clcs->[-1]->[2]++;
    }
    else {
      push @$clcs,[$entry->[0],$entry->[1],1];
    }
  }
  return $clcs;
}

sub hunks2sequences {
  my ($self, $hunks) = @_;

  my $a = [];
  my $b = [];

  for my $hunk (@$hunks) {
    push @$a, $hunk->[0];
    push @$b, $hunk->[1];
  }
  return ($a,$b);
}

sub align2strings {
  my ($self, $hunks,$gap) = @_;
  #$gap //= '_';
  $gap = (defined $gap) ? $gap : '_';

  my $a = '';
  my $b = '';

  for my $hunk (@$hunks) {
    my ($ae,$be) = $self->fill_strings($hunk->[0],$hunk->[1],$gap);
    $a .=  $ae;
    $b .=  $be;
  }
  return ($a,$b);
}

sub fill_strings {
  my ($self, $string1,$string2, $gap) = @_;
  #$gap //= '_';
  $gap = (defined $gap) ? $gap : '_';

  my @m = $string1 =~ m/(\X)/g;
  my @n = $string2 =~ m/(\X)/g;
  my $max = max(scalar(@m),scalar(@n));
  if ($max - scalar(@m) > 0) {
    for (1..$max-scalar(@m)) {
      $string1 .= $gap;
    }
  }
  if ($max - scalar(@n) > 0) {
    for (1..$max-scalar(@n)) {
      $string2 .= $gap;
    }
  }
  return ($string1,$string2);
}

sub LLCS {
  my ($self,$X,$Y) = @_;

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $c = [];

  for my $i (0..1) {
    for my $j (0..$n) {
      $c->[$i][$j]=0;
    }
  }

  my ($i,$j);

  for ($i=1; $i <= $m; $i++) {
    for ($j=1; $j <= $n; $j++) {
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[1][$j] = $c->[0][$j-1]+1;
      }
      else {
        $c->[1][$j] = max($c->[1][$j-1],$c->[0][$j]);
      }
    }
    for ($j = 1; $j <= $n; $j++) {
      $c->[0][$j] = $c->[1][$j];
    }
  }
  return ($c->[1][$n]);
}


sub LCS {
  my ($self,$X,$Y) = @_;

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
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[$i][$j] = $c->[$i-1][$j-1]+1;
      }
      else {
        $c->[$i][$j] = max($c->[$i][$j-1], $c->[$i-1][$j]);
      }
    }
  }
  my $path = $self->_lcs($X,$Y,$c,$m,$n,[]);

  return $path;
}


sub max {
  ($_[0] > $_[1]) ? $_[0] : $_[1];
}


sub _lcs {
  my ($self,$X,$Y,$c,$i,$j,$L) = @_;

  while ($i > 0 && $j > 0) {
    if ($X->[$i-1] eq $Y->[$j-1]) {
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


sub _all_lcs {
  my ($self,$ranks,$rank,$max) = @_;

  my $R = [[]];

  while ($rank <= $max) {
    my @temp;
    for my $path (@$R) {
      for my $hunk (@{$ranks->{$rank}}) {
        if (scalar @{$path} == 0) {
          push @temp,[$hunk];
        }
        elsif (($path->[-1][0] < $hunk->[0]) && ($path->[-1][1] < $hunk->[1])) {
          push @temp,[@$path,$hunk];
        }
      }
    }
    @$R = @temp;
    $rank++;
  }
  return $R;
}

# get all LCS of two arrays
# records the matches by rank
sub allLCS {
  my ($self,$X,$Y) = @_;

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $ranks = {}; # e.g. '4' => [[3,6],[4,5]]
  my $c = [];
  my ($i,$j);

  for (0..$m) {$c->[$_][0]=0;}
  for (0..$n) {$c->[0][$_]=0;}
  for ($i=1;$i<=$m;$i++) {
    for ($j=1;$j<=$n;$j++) {
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[$i][$j] = $c->[$i-1][$j-1]+1;
        push @{$ranks->{$c->[$i][$j]}},[$i-1,$j-1];
      }
      else {
        $c->[$i][$j] =
          ($c->[$i][$j-1] > $c->[$i-1][$j])
            ? $c->[$i][$j-1]
            : $c->[$i-1][$j];
      }
    }
  }
  my $max = scalar keys %$ranks;
  return $self->_all_lcs($ranks,1,$max);
}

1;
__END__

=encoding utf-8

=head1 NAME

LCS - Longest Common Subsequence

=begin html

<a href="https://travis-ci.org/wollmers/LCS"><img src="https://travis-ci.org/wollmers/LCS.png" alt="LCS"></a>
<a href='https://coveralls.io/r/wollmers/LCS?branch=master'><img src='https://coveralls.io/repos/wollmers/LCS/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/LCS'><img src='http://cpants.cpanauthors.org/dist/LCS.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/LCS"><img src="https://badge.fury.io/pl/LCS.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use LCS;
  my $lcs = LCS->LCS( [qw(a b)], [qw(a b b)] );

  # $lcs now contains an arrayref of matching positions
  # same as
  $lcs = [
    [ 0, 0 ],
    [ 1, 2 ]
  ];

  my $all_lcs = LCS->allLCS( [qw(a b)], [qw(a b b)] );

  # same as
  $all_lcs = [
    [
      [ 0, 0 ],
      [ 1, 1 ]
    ],
    [
      [ 0, 0 ],
      [ 1, 2 ]
    ]
  ];

=head1 DESCRIPTION

LCS is an implementation based on the traditional LCS algorithm.

It contains reference implementations working slow but correct.

Also some utility methods are added to reformat the result.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4


=item LCS(\@a,\@b)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 2-element array refs.

  # position  0 1 2
  my $a = [qw(a b  )];
  my $b = [qw(a b b)];

  my $lcs = LCS->LCS($a,$b);

  # same like
  $lcs = [
      [ 0, 0 ],
      [ 1, 1 ]
  ];

=item LLCS(\@a,\@b)

Calculates the length of the Longest Common Subsequence.

  my $llcs = LCS->LLCS( [qw(a b)], [qw(a b b)] );
  print $llcs,"\n";   # prints 2

  # is the same as
  $llcs = scalar @{LCS->LCS( [qw(a b)], [qw(a b b)] )};

=item allLCS(\@a,\@b)

Finds all Longest Common Subsequences. It returns an array reference of all
LCS.

  my $all_lcs = LCS->allLCS( [qw(a b)], [qw(a b b)] );

  # same as
  $all_lcs = [
    [
      [ 0, 0 ],
      [ 1, 1 ]
    ],
    [
      [ 0, 0 ],
      [ 1, 2 ]
    ]
  ];

The purpose is mainly for testing LCS algorithms, as they only return one of the optimal
solutions. If we want to know, that the result is one of the optimal solutions, we need
to test, if the solution is part of all optimal LCS:

  use Test::More;
  use Test::Deep;
  use LCS;
  use LCS::Tiny;

  cmp_deeply(
    LCS::Tiny->LCS(\@a,\@b),
    any(@{LCS->allLCS(\@a,\@b)} ),
    "Tiny::LCS $a, $b"
  );

=item lcs2align(\@a,\@b,$LCS)

Returns the two sequences aligned, missing positions are represented as empty strings.

  use Data::Dumper;
  use LCS;
  print Dumper(
    LCS->lcs2align(
      [qw(a   b)],
      [qw(a b b)],
      LCS->LCS([qw(a b)],[qw(a b b)])
    )
  );
  # prints

  $VAR1 = [
            [
              'a',
              'a'
            ],
            [
              '',
              'b'
            ],
            [
              'b',
              'b'
            ]
  ];

=item align(\@a,\@b)

Returns the same as lcs2align() via calling LCS() itself.

=item sequences2hunks($a, $b)

Transforms two array references of scalars to an array of hunks (two element arrays).

=item hunks2sequences($hunks)

Transforms an array of hunks to two arrays of scalars.

  use Data::Dumper;
  use LCS;
  print Dumper(
    LCS->hunks2sequences(
      LCS->LCS([qw(a b)],[qw(a b b)])
    )
  );
  # prints (reformatted)
  $VAR1 = [ 0, 1 ];
  $VAR2 = [ 0, 2 ];


=item align2strings($hunks, $gap_character)

Returns two strings aligned with gap characters. The default gap character is '_'.

  use Data::Dumper;
  use LCS;
  print Dumper(
    LCS->align2strings(
      LCS->lcs2align([qw(a b)],[qw(a b b)],LCS->LCS([qw(a b)],[qw(a b b)]))
    )
  );
  $VAR1 = 'a_b';
  $VAR2 = 'abb';


=item fill_strings($string1, $string2, $fill_character)

Returns both strings filling up the shorter with $fill_character to the same length.

The default $fill_character is '_'.

=item clcs2lcs($compact_lcs)

Convert compact LCS to LCS.

=item lcs2clcs($compact_lcs)

Convert LCS to compact LCS.

=item max($i, $j)

Returns the maximum of two numbers.

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.

=head1 REFERENCES

Ronald I. Greenberg. Fast and Simple Computation of All Longest Common Subsequences,
http://arxiv.org/pdf/cs/0211001.pdf

Robert A. Wagner and Michael J. Fischer. The string-to-string correction problem.
Journal of the ACM, 21(1):168-173, 1974.


=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/LCS>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2014- Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
