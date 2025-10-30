#!/bin/perl -w
use strict;
use Dumpvalue;

my $log2inv = 1/log 2;
my $PI = 4*atan2 1, 1;
sub tan ($) { sin($_[0]) / cos($_[0])  }
my $max_mismatch_ang = 5;			# When angles at ends of a segment differ that many times, do not draw the perp

# We operate on a convex or concave broken line $l with given vertices (and the assumed vertex at (*,+oo) or (*,-oo)).
# Non-first elements of @$l have the form [x,y,slope_prev]
# Add a point strictly on the right of the line; if this removes elements from end of @$l, put them into @$undo inverting the order

my($ROT, $dbg, $dbg2, $dbg3) = 0;

# Time linear in the number of removed elements
#    Probably would also work if we add to the left of a curve with x strictly decreasing, and $convx is inverted???
sub convex_hull_add1_undo ($$$;$) {	# $convx == 1, -1 (with -1 for concave)
  my ($o, $l, $undo, $convx) = (shift, shift, shift, shift || 1);	# every elt of @$l a pair [x,y] with x strictly increasing
#  return $l if @$l < 3;
  push @$o, [@$l] and return $o unless @$o;	# 1-level deep copy
  if ($l->[0] == $o->[-1][0]) {
    warn "replacing inplace at x=$l->[0]: y = $o->[-1][1] -> $l->[1]; sum_was=", $o->[-1][3] || 'N/A' if $dbg3;
    ($dbg3 and warn(' ... inplace: ignore')), return if ($l->[1] - $o->[-1][1])*$convx >= 0;	# Ignorable
    $o->[-1][1] = $l->[1], return $o unless $#$o;
    push @$undo, pop @$o;
  }
  {
    my $slope = ($l->[1] - $o->[-1][1])/($l->[0] - $o->[-1][0]);	# slope connecting at end
    push @$o, [@$l, $slope] and last if 1 == @$o;

    my $diff = $slope - $o->[-1][2];
    if ($diff * $convx >= 0) {
        push @$undo, pop @$o unless $diff;
        push @$o, [@$l, $slope]
    } else {
        push @$undo, pop @$o;			# automatically holds: if @$o > 1;
	redo;
    }
  }
  $o;
}		# @$undo allows easily undoing this operation!

# Update two convex hulls; undo this and return if y-sum of these hulls crosses below x-axis.  (y-sum adds as graphs of functions)
# Not very TESTED: when x-ranges are different.  The sum is kept in $O->[*][*][3] when it makes sense.
sub convex_hull2_add1_undo2 ($$$) {				# $which == 0, 1 (to which element to add)
  my ($O, $l, $which) = (shift, shift, shift);		# every elt of $O->[0], $O->[1] is a pair (x,y,slope_prev,sum), x increasing strictly
  convex_hull_add1_undo(my $o = $O->[$which], $l, my $undo = [])		# ^^^ (but the first elt has slope_prev undefined)
    or return [], [0], 'ignored';			# Success;	@$undo_sums is (LAST_IDX, SUMS___REVERSED) = (0)
#    Dumpvalue->new(veryCompact => 1)->dumpValue($O->[$which]) if $which;
  my($othO, $sum, @sum_othO, $UNDO) = $O->[1 - $which];	# Non-last elts of $o have a correct sum already
  my($lst_idx, $last_eq) = ($#$othO,0);					# idx of the last elt of $othO before the right end of the intersection
warn "===== wh=$which (@$l)" if $dbg3;
  my $slope = (@$o > 1 ? $o->[-1][2] : 0);		# dows not matter if @$o == 1
  my $b = $l->[1] - $slope*$l->[0];
  for my $i (0..$#$othO) {
    my $p = $othO->[-1-$i];
    my $d = $p->[0] -  $l->[0];
    $last_eq = 1, $lst_idx-- unless $d;			# As if we use "$d>=0" below, but no "next"
    $lst_idx--, next if $d>0;				# Sum makes no sense here; ">" since cannot do next on "=="
    last if @$o > 1 ? $p->[0] <= $o->[-2][0] : $p->[0] < $o->[-1][0];	# Sum already correct here (and on the left)
    my $SUM = $b + $p->[0]*$slope + $p->[1];
    $UNDO++, last if $SUM <= 0;
    push @sum_othO, $SUM;
  }
#  warn "...... adding [@$l] to body$which; sum2[1]=", (defined($O->[1][1][3]) ? $O->[1][1][3] : 'undef') if defined $O->[1][1] and $dbg3;
  if ($UNDO) {					# Do nothing
  } elsif ($lst_idx<$#$othO and ($lst_idx>=0 or @$othO and $othO->[0][0] ==  $l->[0])) {		# The added-x is "in $othO" between last_idx and last_idx+1, or to the left of $othO
#    next if $lst_idx + @$o > 0;
    my $p = $othO->[$lst_idx+1];
    $dbg3 and warn "lst_idx=$lst_idx ##othO=$#$othO o00=$othO->[0][0] l0=$l->[0]" unless defined $p->[2];
#    $UNDO++ if ($sum = $l->[1] + $p->[1] + ($lst_idx >= 0 ? $p->[2] : 0)*($l->[0] - $p->[0])) < 0;
    if (($sum = $l->[1] + $p->[1] + ($lst_idx >= 0 ? $p->[2] : 0)*($l->[0] - $p->[0])) < 0) {
      $UNDO++
    } else {
      $o->[-1][3] = $sum;	# Attach sum to the last elt of $o
    }
  }
#  warn "...... adding [@$l] to body$which; sum2[1]=", (defined($O->[1][1][3]) ? $O->[1][1][3] : 'undef') if defined $O->[1][1] and $dbg3;
  if ($UNDO) {
    pop @$o;
    push @$o, reverse @$undo;
    return
  }
  warn "Fixing sums: last_idx=$lst_idx, #sums=$#sum_othO; sums=@sum_othO; lstX_othr=",
  		(@sum_othO ? $othO->[$lst_idx+$last_eq][0]-0.5 : '-'), "; ##othO=$#$othO" if $dbg3;
  my @undo_sums;
  for my $i (0..$#sum_othO) {
    push @undo_sums, $othO->[$lst_idx+$last_eq-$i][3];
    $othO->[$lst_idx+$last_eq-$i][3] = $sum_othO[$i];
  }
#  warn "...... added  [@$l] to body$which; sum2[1]=", (defined($O->[1][1][3]) ? $O->[1][1][3] : 'undef') if defined $O->[1][1] and $dbg3;
  return $undo, [$lst_idx+$last_eq, @undo_sums]
}

my $EPS = 1e-9;

# Quadratic???  If we remove an excessive point on the edge, we redo sums on the whole edge, not on the added part of this edge.

# Also: if top are at (k,k²), and bottom is (-1,-1), (n+k,-n+k), this is also quadratic!

# The last problem may we worked out: adding new points moves the distance-minimizing intervals to the right only.

# However, the last solution is not applicable if we can add points on the left and on the right.  Returns 1 on success.
			# Untested, fixes not propagated from convex_hull2_add1_undo2()
sub convex_hull2_add_pair ($$$;$) {				# $which == 0, 1 (to which of arrays the first point goes)
  my ($O, $l, $which, $l2) = (shift, shift, shift, shift);	# every elt a pair (x,y) with x strictly monotonically increasing
  return unless my($undo, $undo_sums, $ignored) = convex_hull2_add1_undo2($O, $l, $which);
#       warn "no undo: $pre, ", scalar @$o, ": ", scalar @$undo if @$o <= $pre and not @$undo;
  return 1 if convex_hull2_add1_undo2($O, $l2, 1-$which);
  return if $ignored;
  warn "undoing... #undo=$#$undo, undo_sums=$#$undo_sums;\twh=$which\t#0=$#{$O->[0]}, #1=$#{$O->[1]}" if $dbg3;
  pop  @{$O->[$which]};
  push @{$O->[$which]}, reverse @$undo;
  my($last_idx, $othO) = (shift @$undo_sums, $O->[1-$which]);		# @$undo_sums is (LAST_IDX, SUMS_REVERSED)
  warn "undoing sums: last_idx=$last_idx, ##=$#$undo_sums" if $dbg3;
  $othO->[$last_idx-$_][3] = $undo_sums->[$_] for 0..$#$undo_sums;
  return;
}  

sub convex_hull2 ($$) {
  my($L, $LL) = (shift, shift);		# every elt of @$L and @$LL a pair (x,y) with x strictly increasing
  my($i, $ii) = (0,0);
  my $O = [[], []];
  while (1) {
    my $which;
    if ($i <= $#$L) {
      if ($ii <= $#$LL and $LL->[$ii][0] < $L->[$i][0]) {
        $which = 1;
      } else {
        $which = 0;
      }
    } else {
      last unless $ii <= $#$LL;
      $which = 1;
    }
    ($which ? $ii-- : $i--), last unless convex_hull2_add1_undo2($O, ($which ? $LL->[$ii++] : $L->[$i++]), $which);
#    Dumpvalue->new(veryCompact => 1)->dumpValue($O->[$which]) if $which;
  }
  return $O, [$i, $ii] if $i <= $#$L or $ii <= $#$LL;
  return $O;					# complete success
}

sub intervals_intersect ($$$$$$$$$$$$) {	#  y=a*x+b over [$x,$x1]; returns empty or (x,y) of the intersection
  my($x,$x1,$pinv,$a,$b,$inv, $X,$X1,$PINV,$A,$B,$INV) = (shift,shift,shift,shift,shift,shift,shift,shift,shift,shift,shift,shift);	# del_eX, del_eY is in the same coordinate system as segL; the rest is shifted
  warn "[$x,$x1],$pinv,{$a,$b},$inv,\t[$X,$X1],$PINV,{$A,$B},$INV" if $dbg2;	# "INV" are about switch of x/y-coordinates
  if (!$inv != !$INV) {						# can compose
    my($onTheSameAxis, $doLeftFirst, $zz) = !$pinv != !$PINV;	# order of composition
    $doLeftFirst = !$pinv == !$inv if $onTheSameAxis;	# if 2 inversions in the 1st group the same, recalc other limits to that axis
    my($AA, $BB) = ($a*$A, $doLeftFirst ? $A*$b+$B : $a*$B+$b);
    if ($AA == 1) {
      return if $BB != 0;			# Now the lines coincide
      my($xx, $xx1, $yy, $yy1, $zz,$zz1) = ($x, $x1);
      if (!$pinv != !$PINV) {			# the intervals are on different axes
        ($x, $x1, $X, $X1, $pinv, $PINV) = ($X, $X1, $x, $x1, $PINV, !$pinv) if !$pinv != !$inv;  # Now they match $a, $b, $A, $B
        $_ = $_*$A+$B  for $X, $X1;
        ($X, $X1) = ($X1, $X) if $A < 0;
      }						# Now the intervals are on the same axis
      $x = $X if $x < $X;
      $x1 = $X1 if $x1 > $X1;
      return if $x1 < $x;
      $x = ($x+$x1)/2;			# Mid-points of the intersection of the segments
      my $y = (!$inv == !$pinv ? $a*$x+$b : $A*$x+$B);
      return $pinv ? ($y,$x) : ($x,$y);
    }
    my $xx = $BB/($AA-1);
    my $yy = $doLeftFirst ? $a*$xx + $b : $A*$xx + $B;
    my $inv_xx = $doLeftFirst ? $pinv : $PINV;
    return if ($zz = (($pinv xor $inv_xx) ? $yy : $xx)) < $x or $zz > $x1;
    return if ($zz = (($PINV xor $inv_xx) ? $yy : $xx)) < $X or $zz > $X1;
    return $inv_xx ? ($yy, $xx) : ($xx, $yy);
#    die "axis inversion support not finished yet: <inv=$inv> <INV=$INV>" if $inv or $INV;
  }					#######	  Now $inv == $INV
  if (!$pinv == !$PINV) {			# On the same axis
    $x = $X if $x < $X;
    $x1 = $X1 if $x1 > $X1;    
    return unless $x <= $x1;
  } elsif (!$pinv != !$inv) {			# Make $pinv == $inv==$INV
    ($x, $x1, $X, $X1, $pinv, $PINV) = ($X, $X1, $x, $x1, $PINV, $pinv);
  }					#######	  Now either $X,$X1 may be ignored (and $pinv==$PINV), or $pinv matches $inv==$INV
  if (!$pinv == !$inv) {			# $pinv matches $inv==$INV (??? But still may need to check [$X,$X1] on the other axis)
    my @d = map +($a-$A)*$_ + $b-$B, $x, $x1;	# ??? This code is broken if, say, $x1 = 1e300
    return unless $d[0]*$d[1] <= 0;
    if ($d[0] or $d[1]) {
       $x = ($x*$d[1] - $x1*$d[0])/($d[1] - $d[0]);
       my $y = ($a+$A)/2*$x + ($B+$b)/2;
       return if !$pinv != !$PINV and ($y < $X or $y > $X1);
       return $inv ? ($y, $x) : ($x, $y);
    }					#######	  Now lines coincide
    if (!$pinv == !$PINV) {			# Intervals has been merged above, so: No other checks; return the midpoint
      $x = ($x+$x1)/2;
      my $y = ($a+$A)/2*$x + ($B+$b)/2;
      return $inv ? ($y, $x) : ($x, $y);
    }						# Check translated $x,$x1 agains $X, $X1
    my($fX,$fX1,$y,$y1) = (0, 0, map +($a+$A)/2*$_ + ($B+$b)/2, $x, $x1);
    ($y,$y1) = ($y1,$y) if $a+$A < 0;
    my($Y,$Y1) = ($y,$y1);
    $Y  = $X,  $fX =($X-$y)  /($y1-$y) if $y < $X;  # Intersect with [$X,$X1]
    $Y1 = $X1, $fX1=($y1-$X1)/($y1-$y) if $y1 > $X1;# Find fractions to cut off near ends of [$x,$x1]
    return if $Y > $Y1;
    ($fX,$fX1) = ($fX1,$fX) if $a+$A < 0;
    $x = $x + ($x1-$x)*(1+$fX-$fX1)/2;		# mid of $fX and 1-$fX1
    $y = ($a+$A)/2*$x + ($B+$b)/2;		# recalculate back into the other axis
    return $inv ? ($y, $x) : ($x, $y);
  }					#######	  Now $X,$X1 are already merged, and $pinv(==$PINV) is opposite to $inv==$INV
  die "range inversion not supported yet: inv=INV=<$inv>; <pinv=$pinv> <PINV=$PINV>" if !$pinv != !$inv or !$PINV != !$INV;
  $X = 0;					# A reference point inside the interval
  if ($x*$x1>0) {				# Need to fix???
  }
  if ($a == $A) {
    return if $b != $B;
    die "intervals on the OTHER axis not supported yet with overlapping intervals: inv=INV=<$inv>; <pinv=$pinv> <PINV=$PINV>";
  }						# Now lines intersect at a point.  Translate interval both ways to the "independent" axis
  if ($a) {
    ($X,$X1)     = map +($_-$b)/$a, $x, $x1;
    ($X,$X1)   = ($X1,$X)   if $a < 0;
  }
  if ($A) {
    my($XX,$XX1) = map +($_-$B)/$A, $x, $x1;
    ($XX,$XX1) = ($XX1,$XX) if $A < 0;
    if ($a) {
     $X = $XX   if $X < $XX;
     $X1 = $XX1 if $X1 > $XX1;
    } else {
     ($X,$X1)   = ($XX,$XX1);
    }
  }
  return if $X > $X1;				# Now the intervals intersect "roughly"
  die "both intervals on the OTHER axis (w.r.t. both functions) not supported yet with intersecting intervals: inv=INV=<$inv>; <pinv=$pinv> <PINV=$PINV>";
}

# Given limits from above and limits from below to a linear function, find the largest subsegment where they are not contradictory
# Find a "best" straight line threading between two convex bodies
sub line_between2convex_bodies ($) {	# Returns [undef,pos] if such a line may be vertical; otherwise (a,b) for the best line y=ax+b going through the bottleneck.  (How much overlap do we require???)
  my($O, $did) = (shift, 0);	# $O->[0|||1]: The convex hull data for the bottom (y-reflected) and the top limits
  my @OO = map [$_], @$O;	# Wrap convex curves in an extra level of an array: $OO[0|||1][0][idx] is a vertex on the convex curve
  for my $j (0, 1) {		#	(Later will append cached data)
    my $oo = $OO[$j];
    my($min, $pos, $POS, $i, $I) = 1e300;		# "infinity"; first and last positions
    for my $pI (0..$#{$oo->[0]}) {
      my $p = $oo->[0][$pI];
      next unless defined (my $d = $p->[3]);		# distance between convex hulls at this point
      $POS = $p, $I = $pI if $min >= $d;
      $min = $d, $pos = $p, $i = $pI if $min > $d;	# Find the run ON A PARTICULAR CURVE where the distance is minimal
    }							# the run is $i..$I of width $min between points $pos and $POS
    $did |= ($j+0x1), @$oo[1,2,3,4,5] = ($min, $pos, $POS, $i, $I) if defined $pos;	# Append (cache) the found runs
#    warn "j=$j, min=$min, i=$i, OO[0][1]=$OO[0][1]" if defined $pos;
  }	# $did is a bitmap: which of the curves has vertices on the overlap
  unless ($did) {				# No overlap! (This flag shows which of the curves have vertices with distance $min
    my $left_idx = $O->[0][0][0] > $O->[1][0][0];	# Which curve is on the left of the other
    return 0, ($O->[$left_idx][-1][0] + $O->[1-$left_idx][0][0])/2, 'invert';
  }
  my($DID, $x1, $x2, $y1, $y2, $slope, $min) = $did;
  if ($DID != 3) {				# Vertices in overlap only on one convex curve
    $min = $OO[$DID-1][1];
  } elsif ($OO[0][1] > $OO[1][1]) {		# Keep only the real min
    undef $OO[0][1];	$did &= 0x2;
    $min = $OO[1][1];
  } elsif ($OO[0][1] < $OO[1][1]) {
    undef $OO[1][1];	$did &= 0x1;
    $min = $OO[0][1];
  } else {
    $min = $OO[0][1];
  }						# Found the minimal vertical distance, and bits of $did show on which of curves it is
#  print "$_: @{$OO[$_]}[1,4,5] [@{$OO[$_][2]}] [@{$OO[$_][3]}]\n" for grep $did & (1<<$_), 0, 1;
  # If min is taken in two different values of x, it is easy to find the slope (both x-values work for both top/bottom boundaries)
  if ($did == 3 and ($x1 = $OO[0][2][0]) != ($x2 = $OO[1][2][0])) {	# starting x of runs on the curves
    $y1 = $OO[0][2][1];
    $slope = ($x1 <=> $x2)*$OO[$x2 > $x1][2][2];	# Take larger of $x1 and $x2 (automatically is not-1st, so has left slope)
  } elsif ($did & 0x1 and ($x1 = $OO[0][2][0]) != $OO[0][3][0]) {	# Different $pos and $POS
    $y1 = $OO[0][2][1];
    $slope = $OO[0][3][2];
  } elsif ($did == 0x2 and ($x1 = $OO[1][2][0]) != $OO[1][3][0]) {	# Different $pos and $POS
    $y1 = $min - $OO[1][2][1];
    $slope = -$OO[1][3][2];				# slope of the preceding edge
  } elsif ($did == 3) {					# Now: top/bottom are achieved at the same x-coordinate, both at one point
    ($x1, $y1) = @{$OO[0][2]}[0,1];
    my($slopeMin, $slopeMax, $haveMin, $haveMax) = (-1e300, +1e300, 0, 0);
#    warn "OO[0][1]=$OO[0][1], OO[0][4]=$OO[0][4]";
    $haveMin++, $slopeMin =  $OO[0][2][2] if $OO[0][4];	# [2] gives the slope on the left of the points, so idx must be >0; [4] gives the index
    $haveMax++, $slopeMax = -$OO[1][2][2] if $OO[1][4]; # [0] is the top one; on the left it gives the lower limit; [1] is -bottom
    warn "min/max: haveMin/Max=$haveMin/$haveMax -> $slopeMin .. $slopeMax" if $dbg2;
    if ($OO[0][5] != $#{$OO[0][0]}) {			# Not right end
      my $sl = $OO[0][0][$OO[0][5] + 1][2];
      $haveMax++, $slopeMax = $sl if $slopeMax > $sl;	# Choose the smallest of maxima
    }
    if ($OO[1][5] != $#{$OO[1][0]}) {			# Not right end
      my $sl = -$OO[1][0][$OO[1][5] + 1][2];
      $haveMin++, $slopeMin = $sl if $slopeMin < $sl;	# Choose the largest of minima
    }
    warn
     "min/max: haveMin/Max=$haveMin/$haveMax -> $slopeMin .. $slopeMax ($OO[0][5] vs. $#{$OO[0][0]}; $OO[1][5] vs. $#{$OO[1][0]})"
       if $dbg2;
    $slopeMin = $slopeMax = 0 unless $haveMin or $haveMax;	# Only with single points for top/bottom
    $slopeMin = $slopeMax unless $haveMin;		# ??? Is this the most reasonable fallback???
    $slopeMax = $slopeMin unless $haveMax;
    $slope = ($slopeMin + $slopeMax)/2;
  } else {
    my $side = $did - 0x1; # Find slope at the other side; min dist on the other side is on immediate left or right of this x-value
    ($x1, $y1) = @{$OO[$side][2]}[0,1];
    $y1 = $min - $y1 if $side;
    my $other = 1 - $side;
    my $p;						# is immediately to the right of $x1
    if ($DID == 3) {
      $p = $OO[$other][2];				# is immediately to the left or to the right of $x1
#    	warn "$x1, $y1 \@$side -> [@$p]";
      $p = $OO[$other][0][$OO[$other][4] + 1] if $p->[0] < $x1;	# Find point on the right of $x1
    } else {
      my $i = 0;
      $i++ until ($p = $OO[$other][0][$i])->[0] > $x1;
    }
#    	warn "$x1, $y1 \@$side -> [@$p]";
    $slope = $p->[2]*(1-2*$other);
#    warn "did=$DID\->$did; ($x1, $y1) min=$min; slope=$slope; p=(@$p)"
  }
  ($slope, $y1 - $min/2 - $x1*$slope, !'invert')	# (a,b) for y=ax+b
}

sub offset2dir32 ($$) {	# dx, dy;  dir is in 0..15 (mod 16), 0 for 0x-directioin, 4 for 0y.
  my($x,$y) = (shift, shift);
  if ($x*$y*($x*$x-$y*$y)) {		# Not compass direction; do in steps of 30, recalcing to non-divisible to 4
    my $o = int(24+atan2($y, $x)/$PI*12);	# In units of 15°; 0 is between going right and above right (int() rounds to 0, not down!)
    $o %= 24;				# Make >= 0
    $o += int($o/3);			# Recalc to syncronize with 45°/4
    return $o+1				# 1 is slightly above going right.
  }
#  int(0.5 + atan2($y, $x)/$PI*16);	# In units of 45°/4; 0 is going right
  my $o = 4*int(0.5 + 32 + atan2($y, $x)/$PI*4); # Compass directions; in units of 45°/4; 0 is going right
#  warn "dir o=$o";			# int() rounds to 0, not down!
  return $o % 32;			# Make >= 0
}

# Find the maximal prefix-run where the directions of edges remains in a not-too-large angle
# $maxL is the maximal number of possible directions in such an angle (boosted by 1 if the start direction has no bits in $notBoost)
sub pre_linearizable_piece ($$$$$;$) {		# dirs (as dy or [dx,dy]), start_idx, end_idx  ( start_idx > end_idx means go-left )
  my($snake, $i, $end, $maxL, $notBoost, $keepPow2, $mod) = (shift, shift, shift, shift, shift, !!shift, 16);	# max len of the arc; allowed dirs
  my $step = ($end <=> $i) || 1;		# directions between $D and $DD, inclusive, cyclic order if $DD < $D
  $end += $step;	# Micro-optimization for the stop condition below
  # Old version returned 1 on <<-overflow; newer ones return 0
  my($bitmap, $halfB) = ((((0x1<<($mod-1)) - 1)<<1)+1, (0x1<<($mod-$maxL)) - 1); # Allowed positions of the start of the arc; the mask bits 0..$mod-$maxL-1
  my $filterBitmap = $bitmap / ((0x1<<(1<<$keepPow2))-1); # Continue while bits at positions proportional to (1<<$keepPow2) exist
  while ($i != $end) {	# Return the range [$D,$DD] with at most $maxL elements (so $DD may be opposite to $D), or empty otherwise
    my $dir = $snake->[$i];
    $dir = [1, $dir] unless ref $dir;		# the “old” encoding
#    warn "pre $i $end dir=<@$dir>";
    my $D = $dir = offset2dir32 $dir->[0], $dir->[1];	# In units of 360°/32; 0 is going right
    $dir = ($dir >> 1) | ($dir & 0x1);		# Merge 2 lowest bits into 1 (follow semantic of offset2dir32 with 16 instead of 32)
    my $remover = ($notBoost > 0 and not ($dir & $notBoost)) ? ($halfB>>1) : $halfB;  # Be more permissibe (by 1) unless bits are present
#    warn sprintf "post dir16=$dir ($D of 32), bitmap=%#4x, halfB=%#4x, remover=%#4x", $bitmap, $halfB, $remover;
    my $remove = ($remover<<($dir+1));		# Remove $mod - $maxL - “boosted” bits: from $dir+1 to $dir+1-$maxL-1+$mod
    $remove |= ($remove >> ($mod));		# Wrap the bits down
    if ((my $n = ($bitmap & ~$remove)) & $filterBitmap) {
      $bitmap = $n;
      $i += $step;
      next;
    }						# Found it!  Got a sequence of cyclically consecutive bits
  }
#  warn sprintf "done: bitmap=%#4x, halfB=%#4x", $bitmap, $halfB;
#  $bitmap |= $bitmap << 1 if $onlyOdd;	# Make bits continuous again (adding one bit at the high end)
  my($lowbit, $highbit);
  if ($bitmap & (0x1<<($mod-1)) and $bitmap & 0x1) {	# wraparound
    $bitmap+=1;
    $highbit = ($bitmap & (-$bitmap))>>1;	# lowest bit of $bitmap; see below
    $bitmap ^= ($highbit<<1);
    $lowbit = $bitmap & (-$bitmap);	# lowest bit again
  } else {
    $lowbit = ($bitmap & (-$bitmap)); # ~$bitmap is 0xFF..FF - $bitmap = -1 - $bitmap; hence -$x is ~$x+1; only the bottom 1 will be flipped up by +1
    $highbit = ($bitmap + $lowbit)>>1;
  }
#  $highbit >>= 1 if $onlyOdd;			# Remove the effect the added earlier bit at the end
  return $i-$step, map int(0.5+$log2inv*log $_), $lowbit, $highbit	# We do not filter to what is masked by $keepPow2
}

sub min($$) {my($x,$y)=(shift,shift); $x<$y ? $x:$y}
sub max($$) {my($x,$y)=(shift,shift); $x>$y ? $x:$y}
sub fmt_ptPairs (@) {
  my($f, @s) = (sub() {my @o = map {defined()?$_:'undef'} @_; "[@o]"});
  @s = map {ref() ? $f->(@$_) : $_} @_ ;
  "@s"
}

sub dir32ToOffset ($) {	# $dir is in 0..31 (mod 32), 0 for 0x-directioin, 8 for 0y.  Return offset of the fence (clockwise of $dir)
  return 0,-0.5 unless my $dir = shift;
  ($dir>0)-0.5, 0;
}

sub rot16($$$) { # Rot is in 0..15 (mod 16) with 0 for id and 4 for counterclockwise rotation by 90 degrees; only multiples of 4 now
  my($x,$y,$rot) = (shift, shift, shift);
  ($x,$y) = (-$x,-$y) if $rot & 0x8;
  ($x,$y) = (-$y,-$x) if $rot & 0x4;
  ($x,$y)
}
sub rot16line($$$$) { # Rot is in 0..15 (mod 16) with 0 for id and 4 for counterclockwise rotation by 90 degrees; only multiples of 4 now
  my($a,$b,$inv,$rot) = (shift, shift, shift, shift);
  $b *= -1 if $rot & 0x8;
  if ($rot & 0x4) {	# 90 degrees rotation followed by inversion is the reflection in 0x; preceded by inversion: in 0y
    if ($inv) {		# reflect in 0y
      $a *= -1;
    } else {		# reflect in 0x
      ($a,$b) = (-$a,-$b);
    }
    $inv = !$inv;
  }
  ($a,$b,$inv)
}

# Assumes x's grow monotonically; an elt of ptPairs is (Xb,Yb) of the bottom limit, (Xt,Yt) is the top limit (up to a T/B flip=+-1)
# debugging output not touched (and most of the rest too!
sub longest_linearizable_piece ($$$$$;$$) { # point pairs, start_idx, end_idx (with go-left OK), ROT16, which pt is convex (+-1), forced_gap, retLine
  my($ptPairs, $i, $end, $ROT16, $flip, $eps, $retLine, $L, $LL) = (shift, shift, shift, shift, shift, (shift||0)/2, shift, [], []);
  warn "ptPairs: ", fmt_ptPairs(@$ptPairs[min($i,$end)..max($i,$end)]), "; $i..$end of ", fmt_ptPairs(@$ptPairs) if $dbg2;
  my $step = ($end <=> $i) || 1;
  my($hulls, $abort, $pre, $post) = ([[], []], 0, ($step < 0 ? ($i < $#$ptPairs, !!$end) : (!!$i, $end < $#$ptPairs)));
#  $end += $step;	# Micro-optimization for the stop condition below
 POINT_PAIR:
  while (1) {
    my($xB, $yB, $xT, $yT) = @{$ptPairs->[$i]};
    ($xB, $yB, $xT, $yT) = (rot16($xB, $yB, $ROT16), rot16($xT, $yT, $ROT16)) if $ROT16;
#    $dbg = 1 if $x == 4;
#    warn "... Xb,Yb=$xB,$yB;  Xt,Yt=$xT,$yT;\ti=$i;\tROT=$ROT16, flip=$flip" if $dbg3;
    $abort++, $i-=$step, last POINT_PAIR unless convex_hull2_add_pair($hulls, [$xT, $flip*$yT-$eps], 0, [$xB, -$flip*$yB-$eps]); # Succeeds on steps 0,1
#    warn "... Added i=$i end=$end";
#      warn "0: ", scalar @{$hulls->[0]}, ", ", scalar @{$hulls->[1]}, (@{$hulls->[1]} ? "; $hulls->[0][-1][0], $hulls->[1][-1][0]" : '');
#    $abort++, last POINT_PAIR unless convex_hull2_add_pair($hulls, [$x, -$y ], 1);
#      warn "1: ", scalar @{$hulls->[0]}, ", ", scalar @{$hulls->[1]}, (@{$hulls->[1]} ? "; $hulls->[0][-1][0], $hulls->[1][-1][0]" : '');
    last if $i == $end;
#    warn "ptPairs=@$ptPairs, #=$#$ptPairs, i=$i" unless defined $dy;
    $i += $step;
# warn "y += $ptPairs->[$i] at $i, cnt=$cnt" if $dbg2;
  }
  $post ||= $abort;
#  warn "ptPairs -> i=$i ...; abort=$abort" if $dbg2;		# Had: D=($xP,$yP)
  return $hulls, $pre, $post, $i, $abort unless $retLine;
  my($a, $b, $inv) = line_between2convex_bodies $hulls;
  return $a, $b, $inv, $pre, $post, $i, $abort;
}	# $pre and $post show whether the line does not go to the end of $ptPairs, $pre at $i, post at $end

# If (continuations of) two overlapping intervals intersect within 1 datapoint of the overlap region, can join at the intersection.
# If not, can connect points at x-coordinates of “1 datapoint away from the overalp”.

	# XXXX ??? Add a first fake entry to a snake to carry the top/horiz direction for the first vertex?
sub longest_linearizable_pieces ($$$;$$) {		# pointPairs, ROT16, T/B flip (semantic same as for longest_linearizable_piece()), 
  my($ptPairs,$ROT16,$flip, $eps, $eps_backwards, $doneS, @atS) = (shift, shift, shift, shift || 0, shift, 0);  # count_done_at_start/end, 0th elt fake
  $eps_backwards = $eps * 1.5 unless defined $eps_backwards;
#  $doneS++ unless $ptPairs->[0][0] or $ptPairs->[0][1];	# carries the top/horiz direction for the first vertex
  while (1) {
    my($hulls,$pre,$post,$idx,$partial) = longest_linearizable_piece $ptPairs, $doneS, $#$ptPairs, $ROT16, $flip, $eps; # , 'retLine'
#    warn("idx=$idx, partial=$partial;   ROT16=$ROT16, flip=$flip, hulls -> ", 1+$#{$hulls->[0]}, ' ',1+$#{$hulls->[1]});
    warn("!!! Panic: No hulls found: ", 1+$#{$hulls->[0]}, ' ',1+$#{$hulls->[1]}), last unless @{$hulls->[0]} and @{$hulls->[1]};
#  print "====\n";
   Dumpvalue->new(veryCompact => 1)->dumpValues($hulls) if $dbg2;
#  print "====\n";
    my($a, $b, $inv) = line_between2convex_bodies $hulls;	# Hulls is rotated!
    $_ *= $flip for $a, $b;
    ($a, $b, $inv) = rot16line $a, $b, $inv, (-$ROT16)%16;	# Rotate back into the original coordinate system
    push @atS, [$hulls, $a, $b, $inv, $doneS, $idx, $pre, $post, $ROT16];
    last unless $partial;			# $cnt >= 2 if input is long enough and consists of 0, 1 only
    	# $cnt,$y,$x,

    #    Used part of the snake: $doneS..$idx) with $cnt segments (and $cnt+1 pairs of points!).  $doneS+$cnt is AFTER THE END
#    	warn "Panic: #=$#$ptPairs;   pre=$pre, post=$post, cnt=$cnt, y=$y, x=$x, part=$partial" if $doneS+$cnt > $#$ptPairs;
    my($hulls1,$post1,$pre1,$idx_b,$partial1) = longest_linearizable_piece $ptPairs, $idx+1, $doneS,
        (my $r1 = ($ROT16+8)%16), -$flip, $eps_backwards;							# central symmetry reflects T/B
    warn("Panic: (left) overshoot on backstep: idx=$idx, partial1=$partial1, idx_b=$idx_b, doneS=$doneS"), last unless $partial1 and $idx_b > $doneS;
    if ($idx+1 == $#$ptPairs) {		# Optimization: what follows completes the backwards search.
      Dumpvalue->new(veryCompact => 1)->dumpValues($hulls1) if $dbg2;
      my($A, $B, $INV) = line_between2convex_bodies $hulls1;	# Rotated extra 180°
      $_ *= -$flip for $A, $B;
#   	warn "... #=$#$ptPairs; A=$A, B=$B;   pre=$pre1, post=$post1, cnt=$cnt_b, y=$y1, x=$x1, part=$partial1";
      ($A, $B, $INV) = rot16line $A, $B, $INV, (-$r1)%16;		# Rotate back into the original coordinate system
      push @atS, [$hulls1, $A, $B, $INV, $idx + 1, $idx_b, $pre1, $post1, $r1, 'ender']; # post/pre inverted above
#      warn " -> @{$atS[-1]}";
      last
    }	# We maximally extended to the left; an optimization would now max-entend to the right, - but there is no such API yet XXXX
    $doneS = $idx_b;
  }
  return \@atS;			# [top/bottom convex hulls], $A, B (ROT16-rotated), start_idx, end_idx, conflict on left/right, ROT16, backwards
}

sub X_Y_DIR_2_ptPair ($$$) {
  my($X,$Y,$DIR) = (shift, shift, shift);
  my($dXb,$dYb) = ($DIR ? ($DIR/2, 0): (0, -0.5));
  [$X+$dXb,$Y+$dYb, $X-$dXb,$Y-$dYb]
}

sub encoded_stroke_2_bounds ($$$$) {
  my($rot,$sides,$addL,$addR) = (shift, shift, shift, shift);
  my(@sides, $ss) = @$sides;
  $sides = [@sides];				# 1-deep copy
  push @$sides, 1 if $addR;
  unshift @$sides, 1 if $addL;
  $ss = shift @$sides if ref $sides->[0];
  my @dDIRS = (0, [0,-1], [-1,0], [0,1]); # @dirs starts with a fake element  to carry the top/horiz direction for the first vertex:
  my($i, $Xini, $Yini, $D, @dirs) = (-1, 0.5, 0.5, $rot%4, [], ($dDIRS[$rot%4+(!!$ss and $ss->[0])]) x (shift(@$sides) - 1));	# Assume starts with a number > 0
  unshift @$sides, $ss if defined $ss;
  while (++$i <= $#$sides) {	# N 0s in @$sides mean jump up by N+1 (as expected); negatives denote jump down, N []s for extra jump right N
    my($U, $R, $s) = (1, 1, $sides->[$i]);	# [1] and [-1] for extra clockwise (or anti) rotation
    $D = ($D + $s->[0])%4, next if ref $s and @$s ;	# , warn("...D=$D")
    $U=$s , $s = $sides->[++$i]  if not ref $s and $s < 0;	# Assume ends with a number > 0
    warn "Panic: negative followed by 0: i=$i of 0..$#$sides, sides=@$sides" if $U<0 and not $s ;    
    $U++, $s = $sides->[++$i]    while $i <= $#$sides and not $s;	# Assume ends with a number > 0

    $R++, $s = $sides->[++$i] while $i <= $#$sides and ref $s and not @$s;	# Assume ends with a number > 0
    warn "Panic: unexpected order of special entries: i=$i of 0..$#$sides, sides=@$sides" if ref $s or $s <= 0;
    $_ *= -1 for ($D&0x2) ? ($R,$U) : ();	# 	  rotation by 180°
    ($R,$U) = ($U, -$R) if $D&0x1;		# (extra) rotation by  90°
    push @dirs, ($R!=1 ? [$R,$U] : $U), ($dDIRS[$D]) x ($s - 1);
  }
#####  push @dirs, 1, (0) x ($_ - 1) for @$sides;
#  my($X,$Y) = (0.5 - !!$addL, -!!$addL);
  my($X, $Y, $dX, $lastDx) = ($Xini, $Yini, ($#dirs and ref($dirs[1]) ? $dirs[1][0] : 1));
  $lastDx = $dX;
  unless ($lastDx) {			# inspect the tail to find the direction x changes
    for my $ii (2..$#dirs) {
      my $dd = $dirs[$ii];
      my $ddX = (ref($dd)?$dd->[0]:1);
      $lastDx = $ddX, last if $ddX;
    }
#    warn "The stroke consists of one column" unless $lastDx;
  }
  my($DIRy, @ptPairs, @dXYs) = ($#dirs and ((ref($dirs[1]) ? $dirs[1][1] : $dirs[1]) > 0)||-1);
  $DIRy *= -1 if $lastDx < 0;
  $DIRy = 0 if $dX;
  my($P, $Oslopes, @XYs) = ("$X/$Y/$DIRy", [[], []], [$X,$Y,$DIRy]);
  $dirs[0][2] = $DIRy;
  push @ptPairs, X_Y_DIR_2_ptPair($X,$Y,$DIRy);
  for my $i (1..$#dirs) {
    my $d = $dirs[$i];
    my $DX = my $dx = (ref($d)?$d->[0]:1);
    if ($DX and $i < $#dirs) {			# Check whether we are a part of a column of squares
      my $dd = $dirs[$i+1];
#      warn "Hor/Vert: i=$i, was=$DX, ", ref($dd) ? "[@$dd]" : $dd;
      $DX = (ref($dd)? $dd->[0] : 1);		# Is 0 if we are in a column
    }
    $X += $dx;  $Y += (my $dy = (ref($d)?$d->[1]:$d));
    my $DIR = ($dy > 0)||-1;
    $DIR *= -1 if $lastDx < 0;			# Does not work in the columns on left/right "edge" conctinued up AND down ??? XXXX
    $DIR = 0 if $DX;
    $P .= ",$X/$Y/$DIR";			# 0 = bounds vertically aligned, otherwise sign of derivative
    push @XYs, [$X,$Y,$DIR];			# Used only for the plot (now disabled!) of slants
    push @dXYs, [$dx,$dy];
    (ref $dirs[$i] or $dirs[$i] = [1,$dirs[$i]]), $dirs[$i][2] = $DIR if $DIR;
    push @ptPairs, X_Y_DIR_2_ptPair($X,$Y,$DIR);
  }						# Y-coord of the base of the rightmost square; X is of its center
  warn $P if $dbg3;
  (\@sides, \@dirs, \@XYs, \@dXYs, $P, \@ptPairs)
}

sub test_encodes_line($$$$$$$$$) {	# Expected_slope, Ignored, Lengths_of_joined_rectangles, add_square_on_left/right
  my($rot,$A,$B,$sides,$addL,$addR, $how, $maxDx, $maxRoAng) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);
  $A = 1/$A if defined $A;
  my($sidesEX, $dirs, $XYs, $dXYs, $P, $ptPairs) = encoded_stroke_2_bounds($rot, $sides,$addL,$addR);
  my($upto, $minDir16,$maxDir16) = pre_linearizable_piece $dXYs, 0, $#$dXYs, 8, 0x1;
  $_ = ($_+4)%16 for $minDir16, $maxDir16;
#  warn 'dXYs=', join ', ', map "[@$_]", @$dXYs;
  warn "upto=$upto, end=$#$dXYs, minDir16=$minDir16, maxDir16=$maxDir16" unless $upto==$#$dXYs;
  my $lines = longest_linearizable_pieces $ptPairs, 0, 1, 1/(2<<7); # 0-rotation, no flip (in +-1), $eps; two arrays of convex_data,A,B,S,E-S,deltaY, pre,post with B relative to S+.5
  return if $how =~ /^draw(curved|ender)/ and @$lines == 1;
  return if $how =~ /^drawcurved(\d+)/ and @$lines < $1;
  return if $how =~ /^drawconvex/ and @$lines < 3;

  my(@slopes, $L, $Ender) = map [1e300,-1e300], (1) x (1+@$dirs); # pre/post show where the line starts to contradict the restrictions if extended
  my(@xyIntercept, $oSt, $oEnd, $Oa, $Ob, $Oinv) = $XYs->[0];	# Ends of segments of the constructed broken line
  for my $i (0..$#$lines) {
    my $R = $lines->[$i];	# [$hulls1, $A, $B, etc...
    my(undef, $A,$B, $inv, $stc, $endc, $pre, $post, $rot16, $ender) = @$R;		# $c, $x (vs $st!) ??? not used
    $Ender++ if $ender;
#    $l = $X+0.5 unless defined $l;
#    my $REV = $l < 0;			# calculated right-to-left
#    $l = abs($l);
#    $b -= $a*($st+0.5) - $y;			# recalculate from x=0.5+$st to x=0
    my($S,$E) = sort {$a <=> $b} $XYs->[$stc][!!$inv], $XYs->[$endc][!!$inv];
    $S -= 0.5;   $E += 0.5;
    $_ ||= 0, $_ -= 0.5, ($_ < 0 and $_ = 0) for $pre, $post;
    push @$L, [(!!$inv)||0,$A,$B,$S,$E,$pre,$post];		# Found lines
    for my $j ($stc..$endc) {	# Interval of $c dirs covers $c+1 coordinates; skip $stc first points
      $slopes[$j][0] = $A if $slopes[$j][0] > $A;
      $slopes[$j][1] = $A if $slopes[$j][1] < $A;
    }
    ($oSt, $oEnd, $Oa, $Ob, $Oinv) = ($S, $E, $A, $B, $inv), next unless $i;
    # Apparently, a connector may be intersected by (the continuation) of a line only in its corresponding (left/right) part! ???
    (my($xInt, $yInt) = intervals_intersect($oSt - $maxDx,$oEnd  + $maxDx, $Oinv, $Oa, $Ob, $Oinv,
      					    $S  - $maxDx, $E     + $maxDx, $inv,  $A,  $B,  $inv)) 	# Same inversion of A/B/S/E
		or warn("Panic: intersection: [$oSt,$oEnd] vs [$S,$E]; ($Oa,$Ob) vs ($A,$B)"), next;	# next is bad here!!! ??? XXXX;
     push @xyIntercept, [$xInt,$yInt];
#     warn "Panic: intersection with inverted answer" if $_inv;
    ($oSt, $oEnd, $Oa, $Ob, $Oinv) = ($S, $E, $A, $B, $inv);
  }
#  warn " L of 1+$#$L: 0 -> <<@{$L->[0]}>>; lines of 1+$#$lines -> <@{$lines->[0]}> --> <<<@{$lines->[0][0][0][0]}>>> <<<@{$lines->[0][0][1][0]}>>>" if $#$L >= 0 and $#$lines >= 0;
  return if $how eq 'drawender' and not $Ender;
  push @xyIntercept, $XYs->[-1];	# The last segment of the constructed broken line ends at the right end
  my $SL    = join ',', map "$XYs->[$_][0]/$slopes[$_+1][0]/$slopes[$_+1][1]", 0..$#$XYs;	# @slopes, as @dirs, starts with a fake elt
#  warn "#xyIntercept = $#xyIntercept";
  my $SLint = join ',', map "$xyIntercept[$_][$L->[$_][0]]/$xyIntercept[$_+1][$L->[$_][0]]/$L->[$_][1]/$L->[$_][0]", 0..$#xyIntercept - 1;

  my @Ang  = map +($L->[$_][0] ? atan2(1, $L->[$_][1]) : atan2($L->[$_][1], 1)), 0..$#xyIntercept - 1;
  my @dAng = map $Ang[$_+1] - $Ang[$_],  0..$#Ang - 1;
  my @skipDAng = map {my $r; $dAng[$_+1] * $dAng[$_] <= 0 or ($r = $dAng[$_+1]/$dAng[$_]) > $maxRoAng or $r < 1/$maxRoAng}
  	0..$#dAng - 1;	# Shifted by 1 w.r.t. @Ang
  my @likeCirc = grep !$skipDAng[$_-1], 1..@skipDAng;	# Indices as for @Ang
  return if $how =~ /^drawconvex/ and not @likeCirc;
#  warn "likeCirc=@likeCirc\t\tdAng=@dAng" if $how =~ /^drawconvex/;

  my @Perp;
  for my $i (grep !$skipDAng[$_-1], 1..@skipDAng) {	# Indices as for @Ang
    my $ang = ($Ang[$i+1] - $Ang[$i-1])/4;		# Use bisectrix between $Ang[$i+1] and $Ang[$i] (same for -1); in ±PI/2
    my $xMid      = ($xyIntercept[$i+1][0] + $xyIntercept[$i][0])/2;
    my $yMid      = ($xyIntercept[$i+1][1] + $xyIntercept[$i][1])/2;
    my($perpSegmX, $perpSegmY);
    if (abs($ang) <= $PI/4) {
      my $segmHalfX = ($xyIntercept[$i+1][0] - $xyIntercept[$i][0])/2;
      $perpSegmY = $segmHalfX/tan $ang;
      $perpSegmX = -$perpSegmY * tan $Ang[$i];
    } else {
      my $segmHalfY = ($xyIntercept[$i+1][1] - $xyIntercept[$i][1])/2;
      $perpSegmX = $segmHalfY/tan($PI/2 - $ang);
      $perpSegmY = -$perpSegmX * tan($PI/2 - $Ang[$i]);
    }
    my $l = sqrt($perpSegmX*$perpSegmX + $perpSegmY*$perpSegmY);
    push @Perp, [$xMid, $yMid, $perpSegmX, $perpSegmY, $l, $xMid + $perpSegmX, $yMid + $perpSegmY, $i]
  }
  for my $i (0..$#Perp) {			# Average as 2/3 1/3 at the ends of runs, as 1/4 1/2 1/4 inside runs
    my($p0,$p,$p1,$pp, @C) = map $Perp[($i+$_) % @Perp], -1..1;	# We fix wraprounds next
#    warn "-- $p0,$p,$p1";
    undef $p0 if !$i        or $p->[7] != $p0->[7]+1;
    undef $p1 if $i==$#Perp or $p->[7] != $p1->[7]-1;
#    $p = [@$p];				# 1-deep copy
    if ($p0 and $p1) {
      @C = map +($p0->[$_]+2*$p->[$_]+$p1->[$_])/4, 5, 6;
    } else {
      $pp = ($p0 or $p1);
    }
    if ($pp) {
      @C = map +($pp->[$_]+2*$p->[$_])/3, 5, 6;
    }
    @C = @$p[5,6] unless @C;		# Center
#    $C[$_) -= $p->[$_] for 0,1;	# Radius-vector from mid-segment
    push @$p, @C;
  }
  my $Perp = join ', ', map {join '/', map {1+sprintf "%.10g", $_-1} @$_} grep $_->[4]<10000, @Perp;	# TeX may bulk out on large numbers
 
#      push @{$L}, "$a/$b/$S/$E/$pre/$post";
  my @DIRS  = map {ref() ? ($_->[0]==1 ? $_->[1] : "[@$_[0,1]]") : $_} @$dirs[1..$#$dirs];
  my @SIDES = map {ref() ? "[@$_]" : $_} @$sidesEX;
  my($PRE,$POST) = (!!$addL && '(1) ',!!$addR && ' (1)');
  warn "not OK: (@DIRS) [@SIDES] (", !!$addL,", ", !!$addR, ') [', (defined($A) ? $A : 'undef'), ' vs ', (@$L>1 ? 'undef': $L->[0][1]),']',
      (defined($B) ? " {$B vs " . (@$L>1 ? 'undef': $L->[0][2]) . '}' : ''), "\n"
    unless (defined $A) == (@$lines == 1)
	   and (not defined $A or abs($A - $L->[0][1]) < 0.0001) and (not defined $B or abs($B - $L->[0][2]) < 0.0001) ;
  # @$dirs are for the join-the-centers broken line (1 for 45 degrees, 0 for horizontal)
  for my $l (@$L) {
    $l->[$_] = 1+sprintf "%.12g", $l->[$_]-1 for 1, 2;	# Round also values close to 0
  }
  print "\\doCase{$P}{$PRE@SIDES$POST}{", (join ', ', map +(join '/', @$_), @$L), "}{$Perp}{$minDir16\\dots $maxDir16}	% (@DIRS) [@SIDES] (", !!$addL,", ", !!$addR, ")\n";
  print "%\\doSlopes{$SL}{$SLint}	%\n" unless @$lines <= 2;
}

sub test_encodes_line_prologue {
  <<'EOP';
\documentclass{amsart}
\usepackage[margin=0.4in,landscape,nohead,nofoot]{geometry}	% may need a4paper/letterpaper
\usepackage{tikz}

\newcommand\doCase[5]{%		1: points (X/Y) 2: descr 3: lines (A/B/x0/x1/extend_dotted_left_dx/extend_dotted_right_dx)  y=A*x+B
  \fbox{\tikz[scale=0.3]{%	4: perpendiculars X Y dX dY len
    \foreach \X/\Y/\how in {#1} {%
      \draw[gray!75,densely dotted] (\X-0.5,\Y-0.5) rectangle ++(1,1);%
      \pgfmathsetmacro\DIR{\how<0?-1:1}%
%      \pgfmathsetmacro\isVERT{\how==0}%
      \ifnum \how=0 %
        \fill[blue] (\X,\Y-0.5) circle (0.2em);%
        \fill[red] (\X,\Y+0.5) circle (0.2em);%
      \else		% \how=-1: decreasing; lower bound on the left, upper on the right; 1: opposite
        \fill[blue] (\X+\DIR/2,\Y) circle (0.2em);% lower
        \fill[red]  (\X-\DIR/2,\Y) circle (0.2em);% upper
      \fi
    }%
    \foreach [count=\c] \inv/\A/\B/\x/\X/\pre/\post in {#3} {%
      \pgfmathsetmacro\COL{{"orange","purple"}[mod(\c,2)]}%
      \pgfmathtruncatemacro\DO{\pre>0}%
      \pgfmathtruncatemacro\DOii{\post>0}%
      \ifnum \inv=0 %
        \draw[\COL] (\x,\x*\A+\B) -- (\X,\X*\A+\B);%
        \ifnum \DO > 0 %
          \draw[\COL,densely dotted] (\x-\pre,\x*\A-\pre*\A+\B) -- (\x,\x*\A+\B);%
        \fi
        \ifnum \DOii > 0 %
          \draw[\COL,densely dotted] (\X+\post,\X*\A+\post*\A+\B) -- (\X,\X*\A+\B);%
        \fi
      \else		% exchange 1st and 2nd coordinate
        \draw[\COL] (\x*\A+\B,\x) -- (\X*\A+\B,\X);%
        \ifnum \DO > 0 %
          \draw[\COL,densely dotted] (\x*\A-\pre*\A+\B,\x-\pre) -- (\x*\A+\B,\x);%
        \fi
        \ifnum \DOii > 0 %
          \draw[\COL,densely dotted] (\X*\A+\post*\A+\B,\X+\post) -- (\X*\A+\B,\X);%
        \fi
      \fi
    }%
    \foreach [count=\c] \x/\y/\dx/\dy/\len/\X/\Y/\i/\XX/\YY in {#4} {%
      \pgfmathtruncatemacro\DO{\len<30}%
      \ifnum \DO > 0 %
        \draw[] (\x,\y) -- ++(\dx,\dy) coordinate (e);%
        \fill[] (e) circle (0.28em);%			vs thickness of "thick"
        \draw[violet,thick] (e) -- (\XX,\YY) coordinate (ee);%
        \fill[violet] (ee) circle (0.28em);%
      \fi
    }%
  \node[below left, overlay] at (current bounding box.north east) {#5};%
  }}\llap{\small #2 }\hfil}


\newcommand\doSlopes[2]{%		points (X/Ymin/Ymax)
  {\color{blue}\fbox{\tikz[scale=0.3]{%
    \foreach \Z/\ZZ/\slope/\inv in {#2} {%
      \draw[gray!66,very thick] (\Z,\slope*5) -- (\ZZ,\slope*5);%
    }%
    \foreach \Z/\Umin/\Umax in {#1} {%
      \fill[blue] (\Z,\Umin*5) circle (0.2em);%
      \fill[red] (\Z,\Umax*5) circle (0.2em);%
    }%
    }}}\hfil}

\begin{document}

\noindent
EOP
}

sub _decode_expectations ($) {
  my $in = shift;
  return $in, undef unless ref $in;
  $in->[0], $in->[1]
}

# Encoding: numbers>=0 --> adjacent "horizontal" runs of this many tiles (1 level above the previous reference height, and change 
# this height); [N]: rotate whatever "increments" follow N * 90 degrees clockwise; numbers<0: change the reference height so that 
# the next run of tiles is that much below the preceding one.
sub _test_encodes_lines($$$$) {	# Need to check incredible amount of branches...
  my($how, $rot, $maxDx, $maxRoAng) = (shift, shift, shift, shift);
  print test_encodes_line_prologue;
  # Actually, the slopes below are for the old algorithm; the new one gives slightly different fits.
  my @exp;
  (@exp = _decode_expectations $_->[0]), test_encodes_line($rot, $exp[0], $exp[1], $_->[1], $_->[2], $_->[3], $how, $maxDx, $maxRoAng) 
#    for [undef, [7, 5], 0, 1]; 0
#    for [undef, [3,3,4,4,3], 1]; 0
#    for [[1, 0], [1,1]]; 0
#    for [undef, [1,3,1,1,3,1]]; 0
#    for [3, [3], 0, 1]; 0
#    for [undef, [7, 9], 1, 1]; 0
#    for [undef, [7, 9], 1]; 0
#    for [undef, [9, 7], 1, 1]; 0
#    for [undef, [1,1,1,2,2,2,5], 1]; 0
#    for [1,     [1,1]]; 0
#    for [undef, [4,4,4,3,3], 0, 1], ; 0
#    for [undef, [1,-2,1,-1,1,-1,2,-1,5,2,1,1,0,1]], [undef, [[1], 1,[],1,[-1],-1,1,-1,2,-1,5,2,1,1,0,1]], ; 0
#    for [undef, [[1], 2,1]], ; 0
#    for [undef, [[1], 1, 2,1]], ; 0
#    for [undef, [[1], 1,2]], [undef, [[1], 1,2,1]], [undef, [[1], 1,2,1,1]], ; 0
#    for [undef, [[1], 1,2, [-1], -1,1,-1,2,-1,5,2,1,1,0,1]], ; 0
#    for [undef, [[1], 1,2, [-1], -1,1,-1,2,-1, 5]], ; 0
#    for [undef, [[1], 1,2, [-1], -1,1,-1,2]], ; 0
#    for [undef, [[1], 1,2, [-1], -1,1,-1,2,-1,5,2,1,[-1],-1,2,-1,1]], ; 0
#    for [undef, [[1], 5, 1]], [-1/5, [[1], 5, 2]], ; 0
#    for [undef, [[1], 5, 1]], ; 0
#    for [-1/5, [[1], 5, 2]], ; 0
    for [7, [7], 1, 1], [7, [7], 0, 1], 
        [7, [7], 1], [undef, [7, 9], 1, 1], [undef, [7,9], 1], [undef, [5,7], 1], [undef, [7, 5], 0, 1], 
        [9, [7, 9], 0, 1], [9, [7,9]], [5.5, [5,6], 1], [5.5, [6, 5], 0, 1], 
    	[9, [7, 9], 0, 1], [9, [9, 7], 1], [7.5, [7,8], 1], [4.5, [5,4], 0, 1], [15, [7, 15], 0, 1], [15, [15, 12], 1], 
    	[9, [7, 9]], [9, [9, 7]],
        [undef, [2,2,3,3], 1], [undef, [2,2,3,4,3]], [undef, [2,2,4,3]], [undef, [2,3,3,4], 1], [undef, [4,3,3,2], 0, 1], 
        [2+2/3, [2,2,3,3]], [2.75, [2,2,3,3,3]], [3.5, [2,3,4,3]], [2.75, [2,3,3,3], 1], [3+1/3, [4,3,3,2]], 
        [3, [2,3,3,3], 0, 1], [3, [1,3,3,3], 0, 1], [3, [2,3,3,3]], [3, [1,3,3,3]], [3, [1,3,3,3,1]], 
        [3, [3,3,3,2], 1], [3, [3,3,3,1], 1], [3, [3,3,3,2]], [3, [3,3,3,1]], 
        [2+1/3, [3,2,2,2], 1], [2+1/3, [3,2,2,2]], [2+1/3, [2,2,2,3], 0, 1], [2+1/3, [2,2,2,3]], 
        [3-1/3, [2,3,3,2], 1], [3-1/3, [2,3,3,2], 0, 1], [3-1/3, [2,3,3,2], 1, 1], 
        [undef, [3,3,2,2,3]],    [undef, [3,2,2,3,3]],       [undef, [3,3,2,2,2]],    [undef, [2,2,2,3,3]], 
        [undef, [3,3,4,4,3], 1], [undef, [3,4,4,3,3], 0, 1], [undef, [3,3,4,4,4], 1], [undef, [4,4,4,3,3], 0, 1], 

        [2+1/3, [2,3,2,2,3]],    [2+2/3, [2,3,3,2,2]],       [2.75, [3,3,3,2,2]],    [2.75, [2,2,3,3,3]], 
        [3+2/3, [3,3,4,4,3]],    [3+2/3, [3,4,4,3,3]],       [3.75, [3,3,4,4,4]],    [3.75, [4,4,4,3,3]], 

        [5.5, [5,6,5,6,5,6]],       [5.5, [5,6,5,6,5,5]],    [5.5, [5,5,6,5,6,5,6]], 
        [5.5, [5,6,5,6,5,6], 1, 1], [5.5, [5,6,5,6,5,5], 1], [5.5, [5,5,6,5,6,5,6], 0, 1], 
        [undef, [4,2,3,3]], [undef, [2,2,3,4]], [undef, [2,3,4,3], 1], [undef, [4,3,4,2], 0, 1], 
        [undef, [2,2,2,3,3]], [undef, [2,2,3,3,3], 1], 

        [2+2/3, [3,2,3,3]], [2+2/3, [2,2,3,3]], [3.5, [2,3,4,3]],     [3.5, [4,3,4,2]], 
        [2+1/3, [2,2,2,3,2]], [2.75, [2,2,3,3,3]], 

        [2.4, [3,2,2,3,2,3]], [undef, [3,2,2,2,2,3,2,2,3]], [2 + 2/9, [3,2,2,2,2,3,2,2,2,3]],
        [2 + 2/9, [2,2,3,2,2,2,2,3,2,2,2,3,2]], [2 + 2/9, [1,2,3,2,2,2,2,3,2,2,2,3,1]],
        [2.2, [3,2,2,2,2,3,2,2,2]], 
        [[2,  0.5], [1,2]], # was 5/3, 0.25
        [[2, 0],    [2,1]], # was 5/3, 0.05
        [[2, 0.5], [1,2,2]], 
        [[2, 0.5], [1,2,2,2,2,1]],
        [undef, [1,3,5,3,1]],        [undef, [1,3,4,5,3,1]],        [undef, [1,3,4,2,3,1]],
        [undef, [1,3,1,3,1]], [undef, [1,3,1,1,3,1]], [undef, [1,3,1,1,1,3,1]], [undef, [1,3,1,1,1,1,3,1]],
        [undef, [2,2,1,3,1,3,1,2,2]],
        [undef, [1,3,1,3,1,2,2,2,1,3,1,3,1]],
        [undef, [2,2,2,1,3,1,3,1,2,2,2,1,3,1,3,1,2,2,2]],
        [1+10/11, [2,[],1,[],1,1,[],2,1,[],2,1,[],1,[],1,[],1,1,[],2,1,[],2,1,[],1,[],1,[],1]],
        [undef, [2,[],1,[],1,1,3,1,[],2,1,[],1,[],1,[],1,1,3,1,[],2,1,[],1,[],1,[],1]],
        [undef, [2,[],1,[],1,1,3,1,3,1,[],1,[],1,[],1,1,3,1,3,1,[],1,[],1,[],1]],
        [[1, 0], [1,1]], [undef, [3,1,1,3], 1], [undef, [3,1,3,1,1,2], 1], [undef, [3,1,3,1,2], 1], [undef, [3,1,4,1,2], 1], [undef, [3,1,5,1,2], 1],
        [undef, [1,1,1,2,2,2,5], 1], [undef, [1,1,1,2,1,3,5], 1],
        [0.8, [1,1,1,0,1,1,1], 1], [1.25, [1,1,1,[],1,1,1], 1],
        [undef, [1,-2,1,-1,1,-1,2,-1,5,2,1,1,0,1]], [undef, [[1], 1,[],1,[-1],-1,1,-1,2,-1,5,2,1,1,0,1]],
        [undef, [[1], 1,2, [-1], -1,1,-1,2,-1,5,2,1,1,0,1]], [undef, [[1], 1,2, [-1], -1,1,-1,2,-1, 5]],
        [undef, [[1], 5,2, [-1], -1,1,-1,2,-1, 5]], [-1/5, [[1], 5,2]],, [undef, [[1], 5,1]],
        [undef, [[1], 1,2, [-1], -1,1,-1,2,-1,5,2,1,[-1],-1,2,-1,1]], [undef, [[1], 1,2, [-1], -1,1,-1,2,-1,5,2,1,[-1],-1,2]], 
        [undef, [[1], 5,2, [-1], -1,1,-1,2,-1,5,2,1,[-1],-1,2,-1,5]],
         [undef, [[1], 1,2, [-1], -1,1,-1,2]],
        [-.6, [[1], 1,2]], [-.6, [[1], 1,2,1]], [-5/7, [[1], 1,2,1,1]],  [-0.6, [[1], 2,1]],
        [.6, [[-1], 1,-1,2]], [.6, [[-1], 2,-1,1]], [.6, [[-1], 1,-1,2,-1,1]], [5/7, [[-1], 1,-1,2,-1,1,-1,1]], [1e10, [[1], 2]],
        ;
  print <<'EOP';
\hfill\null

\end{document}
EOP
}

$dbg  = 1, shift if ($ARGV[0] || 0) eq 'dbg';
$dbg2 = 1, shift if ($ARGV[0] || 0) eq 'dbg2';
$dbg3 = 1, shift if ($ARGV[0] || 0) eq 'dbg3';
$ROT = 1, shift if ($ARGV[0] || 0) =~ /^rot=(.*)/;

my $how = shift;

unless ($how) {
#  Dumpvalue->new(veryCompact => 1)->dumpValues(longest_linearizable_pieces(1,1,0,0));
  Dumpvalue->new(veryCompact => 1)->dumpValues(longest_linearizable_pieces [0,0,0,1,0,1], 6, 2);
  exit;
}

if ($how =~ /^draw/) {
  _test_encodes_lines $how, $ROT, 2, $max_mismatch_ang;	# $maxDx, $maxRoAng
  exit;
}

#print "<", Dumpvalue->new->dumpValue(longest_linearizable_piece(1,0,1,0,0,0,1,0,1)), ">\n";
#print "<", Dumpvalue->new->dumpValue(longest_linearizable_piece(1,0,1,0,0,1,0,1)), ">\n";
Dumpvalue->new(veryCompact => 1)->dumpValues(longest_linearizable_pieces [1,0,1,0,0,1,0,1],   8, 4);
Dumpvalue->new(veryCompact => 1)->dumpValues(longest_linearizable_pieces [1,0,1,0,0,0,1,0,1], 9, 4);

exit;

__END__

print join ' ', map qq([@$_]), convex_hull([[0,3], [1,3], [2,2], [6, 1], [7, 2], [8,1], [9,13], [10,13] ]);
print "\n";
print join ' ', map qq([@$_]), convex_hull([[0,3], [1,3], [2,2], [6, 1], [7, 2], [8,1], [9,13], [10,13], [11,-85] ]);

###############################
