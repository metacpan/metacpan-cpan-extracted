# Copyright 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

# MyOEIS.pm is shared by several distributions.
#
# MyOEIS.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyOEIS.pm is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyOEIS;
use strict;
use Carp 'croak';
use File::Spec;
use List::Util 'sum';

# uncomment this to run the ### lines
# use Smart::Comments;

my $without;

sub import {
  shift;
  foreach (@_) {
    if ($_ eq '-without') {
      $without = 1;
    } else {
      die __PACKAGE__." unknown option $_";
    }
  }
}

# Return $aref, $i_start, $filename
sub read_values {
  my ($anum, %option) = @_;
  ### read_values() ...

  if ($without) {
    return;
  }

  my $i_start;
  my $filename;
  my $next;
  if (my $seq = eval { require Math::NumSeq::OEIS::File;
                       Math::NumSeq::OEIS::File->new (anum => $anum) }) {
    ### from seq ...
    $next = sub {
      my ($i, $value) = $seq->next;
      return $value;
    };
    $filename = $seq->{'filename'};
    $i_start = $seq->i_start;
  } else {
    require Math::OEIS::Stripped;
    my @values = Math::OEIS::Stripped->anum_to_values($anum);
    if (! @values) {
      MyTestHelpers::diag ("$anum not available");
      return;
    }
    ### from stripped ...
    $next = sub {
      return shift @values;
    };
    $filename = Math::OEIS::Stripped->filename;
  }

  my $desc = $anum; # has ".scalar(@bvalues)." values";
  my @bvalues;
  for (;;) {
    my $value = &$next();
    if (! defined $value) {
      $desc .= " has ".scalar(@bvalues)." values";
      last;
    }
    if ((defined $option{'max_count'} && @bvalues >= $option{'max_count'})
       || (defined $option{'max_value'} && $value > $option{'max_value'})) {
      $desc .= " shortened to ".scalar(@bvalues)." values";
      last;
    }
    push @bvalues, $value;
  }
  if (@bvalues) {
    $desc .= " to $bvalues[-1]";
  }

  MyTestHelpers::diag ($desc);
  return (\@bvalues, $i_start, $filename);
}

# with Y reckoned increasing downwards
sub dxdy_to_direction {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # south
  if ($dy < 0) { return 3; }  # north
}


sub compare_values {
  my %option = @_;
  require MyTestHelpers;
  my $anum = $option{'anum'} || croak "Missing anum parameter";
  my $func = $option{'func'} || croak "Missing func parameter";
  my ($bvalues, $lo, $filename) = MyOEIS::read_values
    ($anum,
     max_count => $option{'max_count'},
     max_value => $option{'max_value'});
  my $diff;
  if ($bvalues) {
    if (my $fixup = $option{'fixup'}) {
      &$fixup($bvalues);
    }
    my ($got,@rest) = &$func(scalar(@$bvalues));
    if (@rest) {
      croak "Oops, func return more than just an arrayref";
    }
    if (ref $got ne 'ARRAY') {
      croak "Oops, func return not an arrayref";
    }
    $diff = diff_nums($got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join_values($bvalues));
      MyTestHelpers::diag ("got:     ",join_values($got));
    }
  }
  if (defined $Test::TestLevel) {
    require Test;
    local $Test::TestLevel = $Test::TestLevel + 1;
    Test::skip (! $bvalues, $diff, undef, "$anum");
  } elsif (defined $diff) {
    print "$diff\n";
  }
}

sub join_values {
  my ($aref) = @_;
  if (! @$aref) { return ''; }
  my $str = $aref->[0];
  foreach my $i (1 .. $#$aref) {
    my $value = $aref->[$i];
    if (! defined $value) { $value = 'undef'; }
    last if length($str)+1+length($value) >= 275;
    $str .= ',';
    $str .= $value;
  }
  return $str;
}

sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  my $diff;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely pos=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (defined $got != defined $want) {
      if (defined $diff) {
        return "$diff, and more diff";
      }
      $diff = "different pos=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    unless ($got =~ /^[0-9.-]+$/) {
      if (defined $diff) {
        return "$diff, and more diff";
      }
      $diff = "not a number pos=$i got='$got'";
    }
    unless ($want =~ /^[0-9.-]+$/) {
      if (defined $diff) {
        return "$diff, and more diff";
      }
      $diff = "not a number pos=$i want='$want'";
    }
    if ($got != $want) {
      if (defined $diff) {
        return "$diff, and more diff";
      }
      $diff = "different pos=$i numbers got=$got want=$want";
    }
  }
  return $diff;
}

# counting from 1 for prime=2
sub ith_prime {
  my ($i) = @_;
  if ($i < 1) {
    croak "Oops, ith_prime() i=$i";
  }
  require Math::Prime::XS;
  my $to = 100;
  for (;;) {
    my @primes = Math::Prime::XS::primes($to);
    if (@primes >= $i) {
      return $primes[$i-1];
    }
    $to *= 2;
  }
}

#------------------------------------------------------------------------------

sub first_differences {
  my $prev = shift;
  return map { my $diff = $_-$prev; $prev = $_; $diff } @_;
}

#------------------------------------------------------------------------------
# unit square boundary

{
  my %lattice_type_to_dfunc = (square => \&path_n_to_dboundary,
                               triangular => \&path_n_to_dhexboundary);
  sub path_n_to_figure_boundary {
    my ($path, $n_end, %options) = @_;
    my $boundary = 0;
    my $dfunc = $lattice_type_to_dfunc{$options{'lattice_type'} || 'square'};
    foreach my $n ($path->n_start .. $n_end) {
      # print "$n  ",&$dfunc($path, $n),"\n";
      $boundary += &$dfunc($path, $n);
    }
    return $boundary;
  }
}

BEGIN {
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  sub path_n_to_dboundary {
    my ($path, $n) = @_;
    my ($x,$y) = $path->n_to_xy($n) or return 0;
    {
      my @n_list = $path->xy_to_n_list($x,$y);
      if ($n > $n_list[0]) {
        return 0;
      }
    }
    my $dboundary = 4;
    foreach my $i (0 .. $#dir4_to_dx) {
      my $an = $path->xy_to_n($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
      $dboundary -= 2*(defined $an && $an < $n);
    }
    return $dboundary;
  }
  sub path_n_to_dsticks {
    my ($path, $n) = @_;
    my ($x,$y) = $path->n_to_xy($n) or return 0;
    my $dsticks = 4;
    foreach my $i (0 .. $#dir4_to_dx) {
      my $an = $path->xy_to_n($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
      $dsticks -= (defined $an && $an < $n);
    }
    return $dsticks;
  }
}


#------------------------------------------------------------------------------

# Return the area enclosed by the curve N=n_start() to N <= $n_limit.
#
# lattice_type => 'triangular'
#    Means take the six-way triangular lattice points as adjacent and
#    measure in X/2 and Y*sqrt(3)/2 so that the points are unit steps.
#
sub path_enclosed_area {
  my ($path, $n_limit, %options) = @_;
  ### path_enclosed_area() ...
  my $points = path_boundary_points($path, $n_limit, %options);
  ### $points
  if (@$points <= 2) {
    return 0;
  }
  require Math::Geometry::Planar;
  my $polygon = Math::Geometry::Planar->new;
  $polygon->points($points);
  return $polygon->area;
}

{
  my %lattice_type_to_divisor = (square => 1,
                                 triangular => 4);

  # Return the length of the boundary of the curve N=n_start() to N <= $n_limit.
  #
  # lattice_type => 'triangular'
  #    Means take the six-way triangular lattice points as adjacent and
  #    measure in X/2 and Y*sqrt(3)/2 so that the points are unit steps.
  #
  sub path_boundary_length {
    my ($path, $n_limit, %options) = @_;
    ### path_boundary_length(): "n_limit=$n_limit"

    my $points = path_boundary_points($path, $n_limit, %options);
    ### $points

    my $lattice_type = ($options{'lattice_type'} || 'square');
    my $triangular_mult = ($lattice_type eq 'triangular' ? 3 : 1);
    my $divisor = ($options{'divisor'} || $lattice_type_to_divisor{$lattice_type});
    my $side = ($options{'side'} || 'all');
    ### $divisor

    my $boundary = 0;
    foreach my $i (($side eq 'all' ? 0 : 1)
                   ..
                   $#$points) {
      ### hypot: ($points->[$i]->[0] - $points->[$i-1]->[0])**2 + $triangular_mult*($points->[$i]->[1] - $points->[$i-1]->[1])**2

      $boundary += sqrt(((  $points->[$i]->[0] - $points->[$i-1]->[0])**2
                         + $triangular_mult
                         * ($points->[$i]->[1] - $points->[$i-1]->[1])**2)
                        / $divisor);
    }
    ### $boundary
    return $boundary;
  }
}
{
  my @dir4_to_dxdy = ([1,0], [0,1], [-1,0], [0,-1]);
  my @dir6_to_dxdy = ([2,0], [1,1], [-1,1], [-2,0], [-1,-1], [1,-1]);
  my %lattice_type_to_dirtable = (square => \@dir4_to_dxdy,
                                  triangular => \@dir6_to_dxdy);

  # Return arrayref of points [ [$x,$y], ..., [$to_x,$to_y]]
  # which are the points on the boundary of the curve from $x,$y to
  # $to_x,$to_y inclusive.
  #
  # lattice_type => 'triangular'
  #    Means take the six-way triangular lattice points as adjacent.
  #
  sub path_boundary_points_ft {
    my ($path, $n_limit, $x,$y, $to_x,$to_y, %options) = @_;
    ### path_boundary_points_ft(): "$x,$y to $to_x,$to_y"
    ### $n_limit

    # my @dirtable = $path->_UNDOCUMENTED__dxdy_list; # $lattice_type_to_dirtable{$lattice_type};
    my $lattice_type = ($options{'lattice_type'} || 'square');
    my @dirtable = @{$lattice_type_to_dirtable{$lattice_type}};
    my $dirmod = scalar(@dirtable);
    my $dirrev = $dirmod / 2 - 1;
    ### @dirtable
    ### $dirmod
    ### $dirrev

    my $arms = $path->arms_count;
    my @points;
    my $dir = $options{'dir'} // 1;
    my @n_list;

    # FIXME: can be on boundary without having untraversed edge
    if (! defined $dir) {
      foreach my $i (0 .. $dirmod) {
        my ($dx,$dy) = @{$dirtable[$i]};
        if (! defined ($path->xyxy_to_n($x,$y, $x+$dx,$y+$dy))) {
          $dir = $i;
          last;
        }
      }
      if (! defined $dir) {
        die "Oops, $x,$y apparently not on boundary";
      }
    }

  TOBOUNDARY: for (;;) {
      @n_list = $path->xy_to_n_list($x,$y)
        or die "Oops, no n_list at $x,$y";
      foreach my $i (1 .. $dirmod) {
        my $test_dir = ($dir + $i) % $dirmod;
        my ($dx,$dy) = @{$dirtable[$test_dir]};
        my @next_n_list = $path->xy_to_n_list($x+$dx,$y+$dy);
        if (! any_consecutive(\@n_list, \@next_n_list, $n_limit, $arms)) {
          ### is boundary: "dxdy = $dx,$dy  test_dir=$test_dir"
          $dir = ($test_dir + 1) % $dirmod;
          last TOBOUNDARY;
        }
      }
      my ($dx,$dy) = @{$dirtable[$dir]};
      if ($x == $to_x && $y == $to_y) {
        $to_x -= $dx;
        $to_y -= $dy;
      }
      $x -= $dx;
      $y -= $dy;
      ### towards boundary: "$x, $y"
    }

    ### initial: "dir=$dir  n_list=".join(',',@n_list)." seeking to_xy=$to_x,$to_y"

    for (;;) {
      ### at: "xy=$x,$y  n_list=".join(',',@n_list)
      push @points, [$x,$y];
      $dir = ($dir - $dirrev) % $dirmod;
      my $found = 0;
      foreach (1 .. $dirmod) {
        my ($dx,$dy) = @{$dirtable[$dir]};
        my @next_n_list = $path->xy_to_n_list($x+$dx,$y+$dy);
        ### consider: "dir=$dir  next_n_list=".join(',',@next_n_list)
        if (any_consecutive(\@n_list, \@next_n_list, $n_limit, $arms)) {
          ### yes, consecutive, go: "dir=$dir  dx=$dx,dy=$dy"
          @n_list = @next_n_list;
          $x += $dx;
          $y += $dy;
          $found = 1;
          last;
        }
        $dir = ($dir+1) % $dirmod;
      }
      if (! $found) {
        die "oops, direction of next boundary step not found";
      }

      if ($x == $to_x && $y == $to_y) {
        ### stop at: "$x,$y"
        unless ($x == $points[0][0] && $y == $points[0][1]) {
          push @points, [$x,$y];
        }
        last;
      }
    }
    return \@points;
  }
}

# Return arrayref of points [ [$x1,$y1], [$x2,$y2], ... ]
# which are the points on the boundary of the curve N=n_start() to N <= $n_limit
# The final point should be taken to return to the initial $x1,$y1.
#
# lattice_type => 'triangular'
#    Means take the six-way triangular lattice points as adjacent.
#
sub path_boundary_points {
  my ($path, $n_limit, %options) = @_;
  ### path_boundary_points(): "n_limit=$n_limit"
  ### %options

  my $x = 0;
  my $y = 0;
  my $to_x = $x;
  my $to_y = $y;
  if ($options{'side'} && $options{'side'} eq 'right') {
    ($to_x,$to_y) = $path->n_to_xy($n_limit);

  } elsif ($options{'side'} && $options{'side'} eq 'left') {
    ($x,$y) = $path->n_to_xy($n_limit);
  }
  return path_boundary_points_ft($path, $n_limit, $x,$y, $to_x,$to_y, %options);
}

# $aref and $bref are arrayrefs of N values.
# Return true if any pair of values $aref->[a], $bref->[b] are consecutive.
# Values in the arrays which are > $n_limit are ignored.
sub any_consecutive {
  my ($aref, $bref, $n_limit, $arms) = @_;
  foreach my $a (@$aref) {
    next if $a > $n_limit;
    foreach my $b (@$bref) {
      next if $b > $n_limit;
      if (abs($a-$b) == $arms) {
        return 1;
      }
    }
  }
  return 0;
}

# Return the count of single points in the path from N=Nstart to N=$n_end
# inclusive.  Anything which happends beyond $n_end does not count, so a
# point which is doubled somewhere beyond $n_end is still reckoned as single.
#
sub path_n_to_singles {
  my ($path, $n_end) = @_;
  my $ret = 0;
  foreach my $n ($path->n_start .. $n_end) {
    my ($x,$y) = $path->n_to_xy($n) or next;
    my @n_list = $path->xy_to_n_list($x,$y);
    if (@n_list == 1
        || (@n_list == 2
            && $n == $n_list[0]
            && $n_list[1] > $n_end)) {
      $ret++;
    }
  }
  return $ret;
}

# Return the count of doubled points in the path from N=Nstart to N=$n_end
# inclusive.  Anything which happends beyond $n_end does not count, so a
# point which is doubled somewhere beyond $n_end is not reckoned as doubled
# here.
#
sub path_n_to_doubles {
  my ($path, $n_end) = @_;
  my $ret = 0;
  foreach my $n ($path->n_start .. $n_end) {
    my ($x,$y) = $path->n_to_xy($n) or next;
    my @n_list = $path->xy_to_n_list($x,$y);
    if (@n_list == 2
        && $n == $n_list[0]
        && $n_list[1] <= $n_end) {
      $ret++;
    }
  }
  return $ret;
}

# # Return true if the X,Y point at $n is visited only once.
# sub path_n_is_single {
#   my ($path, $n) = @_;
#   my ($x,$y) = $path->n_to_xy($n) or return 0;
#   my @n_list = $path->xy_to_n_list($x,$y);
#   return scalar(@n_list) == 1;
# }

# Return the count of distinct visited points in the path from N=Nstart to
# N=$n_end inclusive.
#
sub path_n_to_visited {
  my ($path, $n_end) = @_;
  my $ret = 0;
  foreach my $n ($path->n_start .. $n_end) {
    my ($x,$y) = $path->n_to_xy($n) or next;
    my @n_list = $path->xy_to_n_list($x,$y);
    if ($n_list[0] == $n) {  # relying on sorted @n_list
      $ret++;
    }
  }
  return $ret;
}

#------------------------------------------------------------------------------

sub gf_term {
  my ($gf_str, $i) = @_;
  my ($num,$den) = ($gf_str =~ m{(.*)/(.*)}) or die $gf_str;
  $num = Math::Polynomial->new(poly_parse($num));
  $den = Math::Polynomial->new(poly_parse($den));
  my $q;
  foreach (0 .. $i) {
    $q = $num->coeff(0) / $den->coeff(0);
    $num -= $q * $den;
    $num->coeff(0) == 0 or die;
  }
  return $q;
}
sub poly_parse {
  my ($str) = @_;
  ### poly_parse(): $str
  unless ($str =~ /^\s*[+-]/) {
    $str = "+ $str";
  }
  my @coeffs;
  my $end = 0;
  ### $str
  while ($str =~ m{\s*([+-])     # +/- between terms
                   (\s*(-?\d+))? # coefficient
                   ((\s*\*)?     # optional * multiplier
                     \s*x        # variable
                     \s*(\^\s*(\d+))?)?  # optional exponent
                   \s*
                }xg) {
    ### between: $1
    ### coeff  : $2
    ### x      : $4
    $end = pos($str);
    last if ! defined $2 && ! defined $4;
    my $coeff = (defined $2 ? $2 : 1);
    my $power = (defined $7 ? $7
                 : defined $4 ? 1
                 : 0);
    if ($1 eq '-') { $coeff = -$coeff; }
    $coeffs[$power] += $coeff;
    ### $coeff
    ### $power
    ### $end
  }
  ### final coeffs: @coeffs
  $end == length($str)
    or die "parse $str fail at pos=$end";
  foreach (@coeffs) { $_ ||= 0 }
  require Math::Polynomial;
  return Math::Polynomial->new(@coeffs);
}

#------------------------------------------------------------------------------
# boundary iterator

sub path_make_boundary_iterator {
  my ($path, %option) = @_;
  my $x = $option{'x'};
  my $y = $option{'y'};
  if (! defined $x) {
    ($x,$y) = $path->n_to_xy($path->n_start);
  }
  my $dir = $option{'dir'};
  if (! defined $dir) { $dir = 1; }
  my @n_list = $path->xy_to_n_list($x,$y);

  # my $dirmod = scalar(@$dirtable);
  # my $dirrev = $dirmod / 2 - 1;
  # ### $dirmod
  # ### $dirrev
  #
  # my $arms = $path->arms_count;
  # my @points;
  # my $dir = $options{'dir'} // 1;

  return sub {
    my $ret_x = $x;
    my $ret_y = $y;

    return ($ret_x,$ret_y);
  };
}


#------------------------------------------------------------------------------
# recurrence guess

# sub guess_recurrence {
#   my @values = @_;
#
#   require Math::Matrix;
# }

#------------------------------------------------------------------------------
# polynomial partial fractions
#

# $numerator / product(@denominators) is a polynomial fraction.
# Return a list of polynomials p1,p2,... which are numerators of partial
# fractions so
#
#      p1   p2                $numerator
#      -- + -- + ... =  ----------------------
#      d1   d2          product(@denominators)
#
sub polynomial_partial_fractions {
  my ($numerator, @denominators) = @_;
  ### denominators: "@denominators"

  my $total_degree = sum(map {$_->degree} @denominators);
  ### $total_degree
  ### numerator degree: $numerator->degree
  if ($numerator->degree >= $total_degree) {
    croak "Numerator degree should be less than total denominators";
  }

  require Math::Matrix;
  my $m = math_matrix_new_zero($total_degree);
  my @prods;

  {
    my $r = 0;
    foreach my $i (0 .. $#denominators) {
      my $degree = $denominators[$i]->degree;
      if ($degree < 0) {
        croak "Zero denominator";
      }

      # product of denominators excluding this $denominators[$i]
      my $prod = Math::Polynomial->new(1);
      foreach my $j (0 .. $#denominators) {
        if ($i != $j) {
          $prod *= $denominators[$j]
        }
      }
      push @prods, $prod;
      my $prod_degree = $prod->degree;
      ### prod: "$prod"
      ### $prod_degree

      foreach my $c (0 .. $degree-1) {
        foreach my $j (0 .. $prod_degree) {
          $m->[$r][$c+$j] += $prod->coeff($j);
        }
        $r++;
      }
    }
  }
  ### m: "\n$m"

  $m = $m->transpose;
  ### transposed: "\n$m"

  ### det: $m->determinant
  if ($m->determinant == 0) {
    die "Oops, matrix not invertible";
  }

  my $v = Math::Matrix->new(map {[$numerator->coeff($_)]} 0 .. $total_degree-1);
  ### vector: "\n$v"

  $m = $m->concat($v);
  ### concat: "\n$m"

  my $s = $m->solve;
  ### solve: "\n$s"

  my @ret;
  {
    my $check = Math::Polynomial->new(0);
    my $r = 0;
    foreach my $i (0 .. $#denominators) {
      if ($denominators[$i]->degree < 0) {
        croak "Zero denominator";
      }
      my @coeffs;
      foreach my $j (1 .. $denominators[$i]->degree) {
        push @coeffs, $s->[$r][0];
        $r++;
      }
      my $ret = Math::Polynomial->new(@coeffs);
      push @ret, $ret;

      $check += $ret * $prods[$i];
    }

    unless ($check == $numerator) {
      die "Oops, multiply back as check not equal to original numerator, got $check want $numerator\n
numerators: ",join(' ',@ret);
    }
  }

  return @ret;
}

# Return a Math::Matrix which is $rows x $columns of zeros.
# If $columns is omitted then square $rows x $rows.
sub math_matrix_new_zero {
  my ($rows, $columns) = @_;
  if (! defined $columns) {
    $columns = $rows;
  }
  return Math::Matrix->new(map { [ (0) x $columns ]
                               } 0 .. $rows-1);
}

# a + b*x + c*x^2     d         2 + 2*x^2
# ---------------- + --- = ---------------------
#  1 - x - 2*x^3     1-x   (1 - x - 2*x^3)*(1-x)
#
# (a + b*x + c*x^2)*(1-x) + d*(1 - x - 2*x^3) = 2 + 2*x^2
#
#    a - a*x
#        b*x - b*x^2
#              c*x^2 - c*x^3
#    d  -d*x         -2d*x^3
# =  2       + 2*x^2
#  m = [1,0,0,1; -1,1,0,-1; 0,-1,1,0; 0,0,-1,-2]
#   v = [2;0;2;0]
#  matsolve(m,v)
#
# a = -2    4
# b =  2    2
# c =  4    4
# d =  4   -2
#
# (-2 + 2*x + 4*x^2)/(1 - x - 2*x^3)   + 4 /(1-x) ==  (2 + 2*x^2)/(1 - x - 2*x^3)*(1-x)

1;
__END__
