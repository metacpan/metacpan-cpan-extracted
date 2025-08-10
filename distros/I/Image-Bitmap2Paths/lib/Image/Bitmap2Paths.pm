package Image::Bitmap2Paths;

#use 5.022002;
use strict;
use utf8;
use warnings;
use Data::Flow qw(0.09);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::Bitmap2Paths ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

BEGIN { my $debug = $ENV{DEBUG_BITMAP2PATHS} || 0;
#	$debug++ while @ARGV and $ARGV[0] eq '-d' and shift;
        eval ( $debug ? 'sub dwarn { warn @_, ("@_" =~ /\n$/ ? q() : "\n") }' : 'sub dwarn {1}') ;
        eval "sub debug () { $debug }";
}
my $extend_tip = 1/3;		# Crashes of fontforge; see issues #3239 #3240 #3242
my($marked, $marked2);

sub marks_clear() {$marked = $marked2 = undef}
sub marks() {($marked, $marked2)}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Follow the approach in Audio::FindChunks
my %defaults = (
     coarse_blobs => 0,
  );

my %mirror_from = (	# May be set separately, otherwise are synonims
#    min_actual_silence_sec => 'min_silence_sec',
  );

my @recognized =	# these default to undef, but accessing them is not fatal
  qw(width height);

my %subelements = (
    LbRb =>	[qw(Lb Rb)],
    stageOne => [qw(offs cnt cntmin near nearmin doublerays)],
    stage10  => [qw(rays10 longedges10 seenlong10 inLong10 midLong10)],
    stage20  => [qw(edge20 cntedge20 lastedge20 rays20 longedges20 seenlong20 midLong20 inLong20 Simple)],
    stage30  => [qw(edge30 cntedge30 lastedge30 blobs30 blob30 skipExtraBlob)],
    stage40  => [qw(edge40 cntedge40 lastedge40)],
    stage50  => [qw(edge50 cntedge50 lastedge50 rays50 longedges50 seenlong50 midLong50 inLong50)],
    stage60  => [qw(edge60 cntedge60 lastedge60)],
    stage70  => [qw(edge70 cntedge70 lastedge70 longedges70 seenlong70 midLong70 inLong70)],
    stage80  => [qw(edge80 cntedge80 lastedge80 tailEdge)],
    stage90  => [qw(edge90 cntedge90 lastedge90)],
    stageA0  => [qw(strokes nextEdgeBlob entryPointBlob inCalcEdge)],
  );

my %filters = (
  bitmap => [sub {my $i=shift; [[], (map {['', @$_ ,'']} @$i), []]}, 'minibitmap'],
  width  => [sub {my $i=shift; $#{$i->[1]}-1}, 'bitmap'],
  height  => [sub {my $i=shift; $#$i-1},     'bitmap'],
  LbRb => [\&LbRb,, 'bitmap', 'width', 'height'],
#  Lb => [sub { my $LbRb = shift; $LbRb->[0] }, 'LbRb'],	# (Extended) index of the last  blank column at start
#  Rb => [sub { my $LbRb = shift; $LbRb->[1] }, 'LbRb'],	# (Extended) index of the first blank column at end
  stageOne => [\&stageOne, 		   qw(bitmap width height)],
  stage10  => [\&doRays, 		   qw(bitmap width height offs cnt cntmin near nearmin)],
  stage20  => [\&do_Simple_and_edges,	   qw(width height rays10 offs cnt longedges10 seenlong10 inLong10 midLong10)],
  stage30  => [\&nnn_do_Simple_and_edges,  qw(width height offs bitmap edge20 cntedge20 lastedge20)],
  stage40  => [\&nnn0_do_Simple_and_edges, qw(width height edge30 cntedge30 lastedge30 rays20 inLong10 blob30)],
  stage50  => [\&nnn1_do_Simple_and_edges,
		qw(width height edge40 cntedge40 lastedge40 rays20 inLong10 midLong10 seenlong10 longedges10 blob30 offs cnt)],
  stage60  => [\&scan_degree_rays,
		qw(width height edge50 cntedge50 lastedge50 rays50 midLong50 offs cnt)],
  stage70  => [\&nnn3_do_Simple_and_edges,
		qw(width height edge60 cntedge60 lastedge60 longedges50 seenlong50 midLong50 inLong50 cnt)],
  stage80  => [\&nnn4_do_Simple_and_edges,
		qw(width height edge70 cntedge70 lastedge70 rays50 offs cnt)],
  stage90  => [\&nnn5_do_Simple_and_edges,
		qw(width height edge80 cntedge80 lastedge80 rays50 offs inLong70 cnt near)],
  stageA0  => [\&nnn6_do_Simple_and_edges,
		qw(width height edge90 cntedge90 lastedge90 rays50 offs longedges70 blob30 bitmap skipExtraBlob tailEdge coarse_blobs)],
  );

my %recipes = (
  map(($_ => {default => $defaults{$_}}), keys %defaults),
  map(($_ => {filter => [sub {shift}, $mirror_from{$_}]}), keys %mirror_from),
  map( ($_ => {default => undef}),
	@recognized),
  map(($_ => {filter => $filters{$_}}), keys %filters),
  (map {my $coll = $_; my $e = $subelements{$coll};		# For each subelement, create an entry
        map {$e->[$_] => do {my $i=$_; {filter => [sub {shift()->[$i]}, $coll]}}} 0..$#$e} keys %subelements),
#  map(($_ => {prerequisites => ['rms_data']}), 'chunks', 'min', 'max'),
);

# As in Audio::FindChunks
sub new {
  my $class = shift;
  my $s = new Data::Flow \%recipes;
  $s->set(@_);
  bless \$s, $class;
}
sub set ($$$) { ${$_[0]}->set($_[1],$_[2]); $_[0] }
sub get ($$)  { ${$_[0]}->get($_[1]) }

my $height = 16;		# Should be a multiple of 4
my @dx = (0,1,1,1,0,-1,-1,-1);	# Start from "up", go clockwise
my @dy = (-1,-1,0,1,1,1,0,-1);	# +-direction is "down"

sub LbRb ($$$) {
  my($bm,$width,$height) = (shift, shift, shift);
  my($Lb, $Rb) = ($width, 1);
  for my $i (1..$height) {
    my $P = $bm->[$i];
    $P->[$_] and $Lb = $_-1, last for 1..$Lb;
    $P->[$_] and $Rb = $_+1, last for reverse($Rb..$width);
  }		# Rb and Lb are one off from the rightmost and leftmost pixels
  [$Lb, $Rb]
}

sub stageOne ($$$) {
  my($bm,$width,$height) = (shift, shift, shift);
  my(@near, @cnt, @offs, @doublerays, @cntmin, @nearmin);
  for my $y (1..$height) {	# Enumerate neighbors of the pixel, doublearys, directions having neighbors on both sides
    for my $x ( 1..$width ) {
      next unless $bm->[$y][$x];
      my($prev, @OFF) = 0;
      for my $n (0..7) {
        my $dx = $dx[$n];
        my $dy = $dy[$n];
#	      warn 'dx' unless defined $dx;
#	      warn 'dy' unless defined $dy;
        next unless $bm->[$y + $dy][$x+$dx];
        $near[$y][$x][$n] = 1; 
        push @OFF, $n;
        next unless $bm->[$y + 2*$dy][$x + 2*$dx];
        $doublerays[$y][$x]++;
      }
      $cntmin[$y][$x] = $cnt[$y][$x] = @OFF if @OFF;
      $nearmin[$y][$x] = [ @{ $near[$y][$x] } ] if $near[$y][$x];	# deep copy
      $offs[$y][$x]  = \@OFF;
    }
  }
  [\@offs, \@cnt, \@cntmin, \@near, \@nearmin, \@doublerays];
}

############################################## Stage 10 (two!)

# Note that if a fake-curve is continued on the other side, we may prefer this to joining it to the dependent star
#  In presence of dependencies below, the type of ray below is conditional on the eventual type of the dependency vertex.
#  So the “name” below is preliminary, and may be changed later to a “derived type”.

# Dictionary of ray candidates: Dense (>=7 neighbors at dist 1 or 2) (dot denotes an empty place; d is a dependency: rays must be good)
#                       . .        . /   |.              d .                  .               \                          .... ..
# doubleray: *-- curve: *-.  Fork: *d.  ./-  fake-curve: *-.  d/-    rhombus: *d.  tail: --*-  *- ish;  serif --*  notch:.-* ..*
#           .|/          .\   |    . \  *.       \         \  *.       d * d  .|\        .|.  /   .|/           |        ./. ./|.
#    fork4: *d.  Near-corner: *.         m-joint: ||       elses-ray: *|  /      3fork3: *d.      *d.      Sharp: *---   /.  ..|
#           .|\              .d--                 *d                   d d               .|\   .  ..\     \..      \-       \
#  Note that dependent is not a neighbor for diagonal elses-ray (and is not unique)            -          .d-     ...\       \
#     fork4 and one flavor of fork3 are particular cases of fork!		Corner-curve: *.\ 3fork3: *|    bend-sharp: --*
#   Later may put: ignore, Ignore, Tail, 2fork3, Enforced, Arrow/(x-)arrow,     Probable-curve:    *|    Joint???: d*-.
#     1Spur, MFork; Rhombus-frce, Zh/K-fake-curve is intended to be ½-of-segment                  .|-
#     Btail, 4fork, xFork, °. (Also allow longer shaft on Sharp)                                   |.
#	Opposite-direction pair tail/doubleray is converted to Tail/MFork if tail has cnt==3 (as on top of “M”).
#	Likewise for a symmetrized case (as at bottom of “V”): if it is C<fake-curve>/C<Fork> with C<cnt!=1> and the opposite is
#	unrecognized/C<1Spur>/C<Probable-curve> (instead of C<doubleray>).

sub inspect_ray ($$$$$$$$$) { # returns: type, curvature or undef (0 for tail), is multiplicity checked, dependents, remove, unignore, actions.
 my($x, $y, $cnt, $cntmin, $px, $pxmin, $near, $nearmin, $dirs, @res) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);	# dependent of m-joint should be checked separately
 for my $dir (@$dirs) {			# dependency: $x, $y, $dir,$dir1,...
  my $dx = $dx[$dir];
  my $dy = $dy[$dir];
  my($N, $Nmin) = ($near->[$y+$dy][$x+$dx], $nearmin->[$y+$dy][$x+$dx]);
  my($cNmin, $cN, $cN0min) = ($cntmin->[$y+$dy][$x+$dx], $cnt->[$y+$dy][$x+$dx], $cntmin->[$y][$x]);
  push @res, ['Dense'] and next if 6 < $cNmin;
  my($N0, $N0min) = ($near->[$y][$x], $nearmin->[$y][$x]);
  if ($cNmin <= 1) {					# below, if @perp, we automatically are diagonal
    push @res, ['tail', 0, 1, undef, undef, undef, ['t']] and next 
      if $N0->[($dir+4)%8] or $cN0min <= 2;
    unless (grep $N0min->[($dir+$_)%8], -1,1) {
      my @perp = grep $N0min->[($dir+$_)%8], -2,2;
      push @res, ['1Spur', 0, 1] and next if @perp <= 1; # with @perp==1, allow 2 at 135°: a continuation of perp, and of us
    }
  }
  if ($N->[$dir]) {
    my $cNN = $cntmin->[$y+2*$dy][$x+2*$dx] || 0;
    push @res, ['Dense'] and next if 6 < $cNN and $Nmin->[$dir];	# Nmin: be most forgiving
    push @res, ['doubleray', 0] and next
  }			# Now know no straight continuation; check 2 next neighbors
  my($seen_next2, %is_next, $d, $across2);
  $Nmin->[($dir+$_)%8] and $seen_next2++, $d = $_, $is_next{$_}++ for -1, 1;
  my($step, @NEAR) = 2 - ($dir & 0x1);	# detect notches in diag directions, and serifs in HV directions; also for forks
  # by seen_next2: 2: fork[3,4]   1: curve fake-curve diamond sharp fork3    0: tail(ish) notch serif near-corner m-joint elses-ray Corner-curve
  unless ($seen_next2) {		# No suitable curved continuation
    for my $D (-1, 1) {			# Protrusion?  ($dir is serif/notch/ maybe-m-joint???)
      my $DD = ($dir+$step*$D)%8;	# close H-or-V direction
      my $dx1 = $dx[$DD];
      my $dy1 = $dy[$DD];
      $across2++ if $nearmin->[$y+$dy1][$x+$dx1][$DD];	# can go 2 steps in the close H-or-V direction
      next if not $N0min->[$DD] or $N0min->[($DD+4)%8];	# Skip if extends on the other side
      my $extra = $D * ($cNmin <= 3 and $cN >= 3 and not $dir & 0x1 and !!$N->[$DD]);	# Bottom join of M - m-joint (above: with dir=2, DD=0)
      my $curved = $nearmin->[$y+$dy1][$x+$dx1][($DD + $extra)%8];	# for m-joint: extra=1, and we have sloped perp continuation
      # ???? next if $other_dir and ($dir & 0x1 or );
      # x[2]: straight perp continuation for m-joints
      push @NEAR, [$D, $extra, $curved, $nearmin->[$y+$dy1][$x+$dx1][$DD], $cntmin->[$y+$dy1][$x+$dx1] < 5];	# if not ($dir & 0x1 and '???');	# found long stem nearby
    }						# At most one element in @NEAR...
    my $n0;
    if (@NEAR) {
      $n0 = $NEAR[0][0];		# Avoid autovivication, do only if @NEAR...
      push @res, ['notch', $n0, 1, undef, [$x+$dx, $y+$dy], [$x+$dx, $y+$dy, ($dir+4)%8],	# Don't cancel each other: double-notches 02d0
                  ['I', $x+$dx, $y+$dy, ($dir+2*$n0)%8, ($dir+3*$n0)%8], ['n', $x+$dx, $y+$dy, ($dir+4)%8]] and next	# Force ignoring other neighbors
        if $NEAR[0][2] and $cNmin <= 3 and $cN >= 3 and $dir & 0x1
           and not $N0min->[($dir + 2*$n0)%8] and not grep $N0min->[($dir + $_*$n0+4)%8], 1, 2;
      push @res, ['serif', $n0, 1, undef, [$x+$dx, $y+$dy], undef, ['I', $x+$dx, $y+$dy, ($dir+3*$n0)%8], ['E', $x+$dx, $y+$dy, ($dir+4)%8]]
        and next if $NEAR[0][2] and $cNmin <= 2 and not ($dir & 0x1);
# warn("m: $x $y $dir\n"),
      push @res, ['m-joint', $n0, 1, ['`', [$x + $dx, $y + $dy, ($dir+4)%8]],
                  undef, undef, ['L', $x, $y, ($dir+2*$n0)%8, -$n0, 1, 1, 2]] and next	# check separately???
        if not ($dir & 0x1) and $NEAR[0][1] and ($NEAR[0][2] xor $NEAR[0][3]) and (not $NEAR[0][3] or $NEAR[0][4]) and $cN0min <= 3;
    }
    @NEAR = grep $_->[2], @NEAR;	# only curved!
    my($nnn, $DD, @NEAR1, $nnn1);	# What remains is Near-corner, elses-ray, Corner-curve, bend-sharp, and diagonal notch
    for my $D (-1, 1) {			# Allow a neighbor come from a ray of the protrusion
      next unless $Nmin->[($dir+2*$D)%8];
      $nnn++, $DD = $D;
    }						# Here dy goes down!!! vvv
    if ($nnn) {				# Have a neighbor near end in perpendicular direction
      push @res, ['elses-ray', undef, 0, ['″', [$x+$dx+$dy,$y+$dy-$dx,($dir+2)%8], [$x+$dx-$dy,$y+$dy+$dx,($dir-2)%8]]] and next 
        if $nnn == 2;		# ??? Do we NEED to check the opposite dir:
      if (($N0->[($dir+4)%8] or not($dir & 0x1) and $cN0min == 3) # and $N0min->[($dir+4-$DD)%8])	# do not allow bending away from the corner
           and not $N0min->[($dir+2*$DD)%8] 
           and ($px->[$y + $dy + 2*$DD*$dx][$x + $dx - 2*$DD*$dy]		# do not allow bending away from us
                or not($dir & 0x1) and $cntmin->[$y + $dy + $DD*$dx][$x + $dx - $DD*$dy] <= 3)) {
#        warn "thisC=$cN0min targC=$cNmin notchC=$cntmin->[$y + $dy + $DD*$dx][$x + $dx - $DD*$dy], and ", grep +($N0min->[($dir+4+$_)%8] ? 0 : 1), 1, -1;
        if( $cN0min == 3 and $cNmin == 2 and not($dir % 2) and $cntmin->[$y + $dy + $DD*$dx][$x + $dx - $DD*$dy] == 2
	    and my @back = grep $N0min->[($dir+4+$_)%8], 1, -1 ) {
#	  $marked++;
          push @res, ['Btail', $DD, 0, undef, undef, undef,
			['N', $x+$dx, $y+$dy, ($dir+2*$DD)%8], ['N', $x+$dx-$DD*$dy, $y+$dy+$DD*$dx, ($dir-2*$DD)%8],
			['I', $x+$dx-$DD*$dy, $y+$dy+$DD*$dx, ($dir+4+$DD)%8],
			(@back ? ['E', $x, $y, ($dir+4+$back[-1])%8] : ())] and next
	}
        push @res, ['Near-corner', $DD, 0, [',', [$x + $dx, $y + $dy, ($dir+2*$DD)%8]], undef, undef,
                    ($dir & 0x1 ? () 		# TRY: remove the litation on not bending away
                     : (['I', $x, $y, ($dir+$DD)%8], ['Ef', $x+$dx, $y+$dy, ($dir+4)%8]) )] and next
                                     # and $px->[$y + 2*$DD*$dx][$x - 2*$DD*$dy]);
      }
      push @res, ['Corner-curve', $DD, 1] and next if $dir & 0x1 and not $N0min->[($dir+$DD)%8] and $cNmin <= 2;
      push @res, ['arrow', $DD, 0, ['…', [$x+$dx, $y+$dy, ($dir + 4)%8, ($dir + 4 - $DD)%8, ($dir + 4 - 2*$DD)%8]], # On barb going to tip
		  undef, undef, ['a', $DD]] and next 							# remove, unignore, @rest
        if $cNmin == 3 and $dir & 0x1 and $nnn == 1 and $N0min->[($dir+4)%8]
	   and $Nmin->[($dir + 4 - $DD)%8] and $Nmin->[($dir + 4 - 2*$DD)%8];
    } elsif (not @NEAR and $cNmin == 2 and $N0min->[($dir+4)%8]
    	     and $cN0min <= 3 + ($dir & 0x1) and $cnt->[$y][$x] >= 3 + ($dir & 0x1)) {	# bend-sharp?
      my $DDD;
      for my $D (-1,1) {
        $DDD=$D, last if $N0min->[($dir+$D*$step)%8];
      }
      die "bend-sharp: panic" unless $DDD;
      my $dx1 = $dx[($dir+$DDD*$step)%8];
      my $dy1 = $dy[($dir+$DDD*$step)%8];
      push @res, ['bend-sharp', $DDD, 1] and next if $cntmin->[$y+$dy1][$x+$dx1] <= 4 - ($dir & 0x1) 
        and $nearmin->[$y+$dy1][$x+$dx1][($dir+4-$DDD)%8];
    }
    push @res, ['?'] and next if $dir & 0x1;
    for my $D (-1, 1) {			# Allow a neighbor come from a ray of the protrusion
      next unless $Nmin->[($dir+$D)%8];
      $nnn1++, $DD = $D;
    }						# Here dy goes down!!! vvv
    push @res, ['notch', $n0, 1, undef, [$x+$dx, $y+$dy]] and next 
      if $cNmin <= 2 and not($dir & 0x1) and $nnn1 and not $N0min->[($dir + $DD + 4)%8];	# Miss double-notch=arrow
    push @res, ['Arrow'] and next 								# On shaft going to tip
      if $cNmin == 3 and not($dir & 0x1 or $nnn1 or $across2 or $N->[($dir+2)%8] or $N->[($dir-2)%8]);
    push @res, ['?'] and next;
  } elsif (2 == $seen_next2) {	# Only forks, Zh, K's here...	#   |.                    . /
    my($c, $DDD) = 0;						#  ./-	$c counts dots    *-
    $N0min->[($dir+$step*$_)%8] and $c++, $DDD=$_ for -1, 1;	#  *.                     . \
    if ($c == 1 and not($dir & 0x1)) {				# Work around ties between legs of K
      my $x1 = $x + $dx[($dir+$DDD*$step)%8];
      my $y1 = $y + $dy[($dir+$DDD*$step)%8];
      my($NNN, $dir1) = ($near->[$y1][$x1], ($dir-$DDD)%8);
      if ($NNN->[$dir] and $NNN->[$dir1]) {
        push @res, ['elses-ray', -$DDD, 0, ['"', [$x1, $y1, $dir, $dir1]]];
        next;
      }
    } elsif ($c == 1) {
      push @res, ['Probable-curve', $DDD] and next;
    } elsif ($c == 2 and $dir & 0x1 and $N0min->[($dir+4)%8] and not $N0min->[($dir+3)%8] and not $N0min->[($dir+5)%8]) {# K-joint of Ж; repeat what we do below with K-joint
# warn "K-joint: ($x,$y) $dir + $d\n";
      my @R;
      for my $d (-1, 1) {
        my $x1 = $x + $dx[($dir+$d)%8];
        my $y1 = $y + $dy[($dir+$d)%8];
        my($NNN, $dir1) = ($near->[$y1][$x1], ($dir+2*$d)%8);
        push @R, ['Zh-fake-curve', $d] if $NNN->[$dir] and not $NNN->[($dir1+1)%8] and not $NNN->[($dir1-1)%8];
      }
      push(@res, @R), next if @R == 1;
    }
    push @res, ['?'] and next if $c;
#    $N->[($dir+2*$_)%8] and $c++ for -1, 1;
#    push @res, ['fork4'] and next if $c and $c == 2;
    my $opp = ($dir + 4)%8;
    my @dep = grep { $_ ne $opp and $Nmin->[$_]} 0..7;
    push @res, ['Fork', undef, 1, ['°', [$x+$dx, $y+$dy, @dep]]] and next;	# join all forks with next2==2
  }			# Now have one secondary ray only, $d-curving:    curve fake-curve diamond sharp fork3
  my $baddir = ($dir - $step*$d)%8;
  my $bad = $N0min->[$baddir];		# on fake-curve only
  if ( $N0min->[($dir+$d)%8] ) {	# Parallelogram - essentially, two curves with the same end (diamond sharp fork3)
    if ($bad and $dir & 0x1 and $N0min->[($dir+4)%8] and not $N0min->[($dir+3)%8] and not $N0min->[($dir+5)%8]) { # may be a K-joint
      my $x1 = $x + $dx[($dir+$d)%8];
      my $y1 = $y + $dy[($dir+$d)%8];
      my($NNN, $dir1) = ($near->[$y1][$x1], ($dir+2*$d)%8);
      if ($NNN->[$dir] and not $NNN->[($dir1+1)%8] and not $NNN->[($dir1-1)%8]) {
        push @res, ['K-fake-curve', $d];
        next;
      }
    }
    push @res, ['?'] and next if $bad or not ($dir & 0x1) and $N0min->[($dir + 2*$d)%8];	# Check last . on diamond and fork3
    if ($dir & 0x1 and $Nmin->[($dir + 2*$d)%8] and not $Nmin->[($dir - 2*$d)%8]) {	# Avoid the situation in K
      my $dx1 = $dx[($dir + $d)%8];
      my $dy1 = $dy[($dir + $d)%8];
      my $last;
      if ($pxmin->[$y+$dy + 2*$dy1][$x+$dx + 2*$dx1]) {	# 1D469 𝑩 ; 1D483 𝒃;
#        ++$marked,
        push @res, ['Sharp', $d, 0, undef, undef, undef, ['L', $x+$dx, $y+$dy, ($dir+$d)%8, $d, 2, 2, 3, 2+$last], # 2nd 'S' optional now???
                    ['S', $x+$dx, $y+$dy, ($dir+4)%8], ['S', $x+$dx1, $y+$dy1, ($dir+4+$d)%8],	# Enforce line at dist=3
                    ($px->[$y + 2*$dy + $dy1][$x + 2*$dx + $dx1]
                    	? (['I1', $x + 2*$dx + $dx1, $y + 2*$dy + $dy1, ($dir+4)%8], ['II', $x + $dx + $dx1, $y + $dy + $dy1, $dir]) : ()),
                    ['T',($dir + $d + 4)%8,$d]] and next
          if $px->[$y+3*$dy1][$x+3*$dx1]	# This is heavily hand-crafted to avoid false positives!
             and ( $px->[$y + 2*$dy + 2*$dy1][$x + 2*$dx + 2*$dx1] xor $px->[$y + 2*$dy + $dy1][$x + 2*$dx + $dx1] )	# 1F590 🖐
             and ( not $px->[$y + 2*$dy + $dy1][$x + 2*$dx + $dx1] or $cnt->[$y][$x] < 5 and $cnt->[$y+$dy1][$x+$dx1] < 6) # ऄ ፼
             and not $px->[$y + $dy + 3*$dy1][$x + $dx + 3*$dx1]
             and $cntmin->[$y][$x] < 6						# 0994 ঔ 210C ℌ
#             and ( $cntmin->[$y][$x] + $cntmin->[$y+3*$dy1][$x+3*$dx1] < 10 )	# not needed: 1F5FD 🗽
             and (not $px->[$y-$dy1][$x-$dx1] or $cntmin->[$y][$x] + $cntmin->[$y-$dy1][$x-$dx1] < 10)	# 1D4CC 𝓌
             and (not $px->[$y-$dy+$dy1][$x-$dx+$dx1] or $cnt->[$y][$x] + $cnt->[$y-$dy+$dy1][$x-$dx+$dx1] < 9) # 11C17 𑰗, 1F38E 🎎
             and (not $px->[$y+4*$dy1][$x+4*$dx1] or not $px->[$y+5*$dy1][$x+5*$dx1]
                  or $cntmin->[$y][$x] + $cntmin->[$y+4*$dy1][$x+4*$dx1] + $cntmin->[$y+5*$dy1][$x+5*$dx1] < 15)	# 1D4C9 𝓉
             and grep !$px->[$y + $_*$dy1 - $dy][$x + $_*$dx1 - $dx], 2,3,4	# 16B6 ᚶ
             and ( not $px->[$y + 2*$dy + $dy1][$x + 2*$dx + $dx1] 		# 114C7 𑓇
                   or ( ( grep $px->[$y + 4*$dy1 + $_*($dy-$dy1)][$x + 4*$dx1 + $_*($dx-$dx1)],0,1	# 1160F 𑘏
                          or $px->[$y - $dy1][$x - $dx1] )			# 1F590 🖐
                        and $cntmin->[$y+3*$dy1][$x+3*$dx1] < 6)		# 1D752 𝝒
                        and $cnt->[$y+2*$dy+$dy1][$x+2*$dx+$dx1] > 2)		# 1D7C5 𝟅
             and ($last = !!$px->[$y + 4*$dy1][$x + 4*$dx1] or $px->[$y + 5*$dy1 - $dy][$x + 5*$dx1 - $dx]);	# 1D491 𝒑
      } else {
        push @res, ['Sharp', $d, 0, undef, undef, undef, ['L', $x+$dx, $y+$dy, ($dir+$d)%8, $d, 1, 2, 2+$last], # 2nd 'S' optional now (N)
                    ['S', $x+$dx, $y+$dy, ($dir+4)%8], ['S', $x+$dx1, $y+$dy1, ($dir+4+$d)%8],
                    ['T',($dir + $d + 4)%8,$d]] and next	# Enforce line at dist=2
          if ($last = !!$px->[$y+3*$dy1][$x+3*$dx1] or $px->[$y + 4*$dy1 - $dy][$x + 4*$dx1 - $dx])
             and $px->[$y + 2*$dy + $dy1][$x + 2*$dx + $dx1] and ($last or !$px->[$y + 3*$dy1 - $dy][$x + 3*$dx1 - $dx])
             and ($last or $cntmin->[$y+$dy1][$x+$dx1] < 6	# with $last, not beneficial
             		and ($cntmin->[$y][$x] < 6
             		     and ($cntmin->[$y][$x] < 5 or $px->[$y-$dy1][$x-$dx1] and $cntmin->[$y-$dy1][$x-$dx1] < 4))); # 1d54d 𝕍
      }
    }					# Now general catch-all:
    my $opp = ($dir + 4)%8;
    my @dep = grep { $_ ne $opp and $Nmin->[$_]} 0..7;
# warn "generic: $x,$y, $dir, $d; (@dep);; $seen_next2;;; ", map $N->[$_] || 0, 0..7;
    push @res, [($Nmin->[($dir - 2*$d)%8] ? '3fork3' : 'rhombus'),  $d, 0, ['´', [$x + $dx, $y + $dy, @dep]]] and next;
  }
#  warn "maybe curve: ($x,$y,$dir): ", $bad||0,"\n";
  push @res, ['curve', $d, undef, undef, undef, undef, ['C', $d]] and next unless $bad;
  if ($N0min->[($dir + 4)%8] and $cN0min <= 4 and $dir & 0x1) {	# check for double-arrow joint (21a0, 0239)
    my($mirY, $mirX) = ($y + 2*$dy[$baddir], $x + 2*$dx[$baddir]);
    push @res, ['arrow', -$d, 0, ['…', [$x+$dx, $y+$dy, ($dir + 4)%8, ($dir + 4 + $d)%8, ($dir + 4 + 2*$d)%8]], # On barb going to tip
		  undef, undef, ['a', -$d, 1]] and next 							# remove, unignore, @rest
      if $px->[$mirY][$mirX] and $cntmin->[$mirY][$mirX] <= 4 and $cnt->[$mirY][$mirX] >= 4 and $nearmin->[$mirY][$mirX][($dir-2*$d)%8];
  }
  push @res, ['fake-curve', $d, 0, ['curve', [$x + $dx[$baddir], $y + $dy[$baddir], ($dir+$d)%8]]] and next;
 }
 return \@res;
}			# dependent for a parallelogram (HV one) should be submitted only once...

sub clear_edge ($$$$) {
  my ($e, $edge, $cntedge, $lastedge) = (shift, shift, shift, shift);
  my($x, $y, $dir, $x1, $y1) = @$e;
#            warn "clear $x, $y, $dir, $x1, $y1";
  my $dir1 = ($dir+4)%8;
  $edge->[$y][$x][$dir] = 0;	$edge->[$y1][$x1][$dir1] = 0;
  $cntedge->[$y][$x]--;		$cntedge->[$y1][$x1]--;
  for my $l ([$x, $y], [$x1, $y1]) {
    next if $cntedge->[$l->[1]][$l->[0]] != 1;
    my $D = -1;
    $edge->[$l->[1]][$l->[0]][$_] and $D = $_, last for 0..7;
    $lastedge->[$l->[1]][$l->[0]] = $D;		# Good only for 1-edge pixels
  }
}

sub add_edge ($$$$) {
  my($e, $edge, $cntedge, $lastedge) = (shift, shift, shift, shift);
  my($x, $y, $dir, $x1, $y1) = @$e;
#            warn "adding $x, $y, $dir, $x1, $y1";
  my $dir1 = ($dir+4)%8;
  $edge->[$y][$x][$dir]++;	$edge->[$y1][$x1][$dir1]++;
  $cntedge->[$y][$x]++;		$cntedge->[$y1][$x1]++;
  $lastedge->[$y][$x] = $dir;	$lastedge->[$y1][$x1] = $dir1;
}

sub add_longedge ($$$$$) {
  my($e, $longedges, $seenlong, $midLong, $inLong) = (shift, shift, shift, shift, shift);
  my($x, $y, $dir, $x1, $y1, $rot) = @$e;
  push @$longedges, [$x, $y, $x1,$y1, scalar @$longedges, $dir, $rot];
  $seenlong->{$x, $y, $x1,$y1} = $seenlong->{$x1,$y1,$x, $y} = $longedges->[-1];
  $midLong->{$x+$x1,$y+$y1}++;
  $inLong->{$x1,$y1}++;
  $inLong->{$x,$y}++;
}

sub clear_longedge ($$$$$) {
  my($e, $longedges, $seenlong, $midLong, $inLong) = (shift, shift, shift, shift, shift);
  my($x, $y, $x1, $y1, $offset) = @$e;
  $longedges->[$offset] = 'erased';
  delete $seenlong->{$x,$y,$x1,$y1};
  delete $seenlong->{$x1,$y1,$x,$y};
  $midLong->{$x+$x1,$y+$y1}--;
  $inLong->{$x1,$y1}--;
  $inLong->{$x,$y}--;
}

sub post_inspect_ray ($$$$;$) { # Not finished (and it is not exactly clear for what it is best to check...)
 my($x, $y, $dir, $rays, $basetype) = (shift, shift, shift, shift, shift || '');
 $rays = $rays->[$y][$x];
 my $ray = $rays->[$dir] or die "Panic: x=$x, y=$y, dir=$dir - missing ray in post_inspect_ray($basetype)";
 return 1 if $ray->[0] =~ /^m/ and $basetype =~ /^m/;
 for my $next (1,-1) {
   warn "Checking x=$x, y=$y, dir=$dir in post_inspect_ray($basetype) 1=", $rays->[($dir+1)%8] && $rays->[($dir+1)%8][0],
	" -1=", $rays->[($dir-1)%8] && $rays->[($dir-1)%8][0], "\n" if debug && $basetype =~ /^m/;
   return if $rays->[($dir+$next)%8] and $rays->[($dir+$next)%8][0] =~ /^[Dr3\WP]/;	# 'Probable-curve' put here as an experiment XXX
 }
# warn "Checking2: $ray->[0]\n" if $basetype =~ /^3/;
 # Putting 'elses-ray' into the allowed list is not a good idea 
 # (although it may help half-way with some, like ɫ, у, and helps with Ѭ); maybe allow the caller to permit it???
 $ray->[0] =~ /^[dctB1fKZE]/; # doubleray, curve, (B)tail, 1Spur, [Zh/K-]fake-curve, Enforced with no ?/Dense/rhombus/3fork3 nearby
}					# True if we want to keep the basetype

sub remove_px ($$$$$$) {
  my($x, $y, $cnt, $px, $near, $off) = (shift, shift, shift, shift, shift, shift);
  for my $dir ( @{ $off->[$y][$x] } ) {
    my $dx = $dx[$dir];
    my $dy = $dy[$dir];
    $near->[$y+$dy][$x+$dx][($dir+4)%8] = 0;
    $cnt->[$y+$dy][$x+$dx]--;
  }
  undef $px->[$y][$x];
}

sub force_line ($$) {	# enforces 1 edge in this direction; inserts 'ignore' in $rem1 dirs at point, and in $rem2 dirs at next pt
  my($how, $rays) = (shift, shift);
  my($L, $x, $y, $dir, $rot, $len, @ROTS) = @$how;	# $L ==eq== 'L' ignored
# warn "In force_line($L, $x, $y, $dir, $rot...)";
  my $dx = $dx[$dir];
  my $dy = $dy[$dir];
  for my $i (0..($len - 1)) {
    $rays->[$y+$i*$dy][$x+$i*$dx][$dir] = ['Enforced', 0, 1];
    $rays->[$y+($i+1)*$dy][$x+($i+1)*$dx][($dir+4)%8] = ['Enforced', 0, 1];
  }
  return unless $rot;
  my $dx1 = -$rot*$dy;
  my $dy1 =  $rot*$dx;
  for my $i (0..$#ROTS) {
    my @rot = ($i ? (2,3,1) : (1,2));	# Supported now: 0,1,2,3	(horizontal/vertical only)
    @rot = @rot[0..($ROTS[$i]-1)];
    for my $Rot (@rot) {
      if ($Rot == 3) {
        $rays->[$y+$i*$dy][$x+$i*$dx][($dir+3*$rot)%8][0] = 'ignore';			# 135° direction ($i > 0)
        $rays->[$y+($i-1)*$dy+$dy1][$x+($i-1)*$dx+$dx1][($dir-$rot)%8][0] = 'ignore';
      } elsif ($Rot == 2) {
        $rays->[$y+$i*$dy][$x+$i*$dx][($dir+2*$rot)%8][0] = 'ignore';		# Perpendicular direction on ≥1
        $rays->[$y+$i*$dy+$dy1][$x+$i*$dx+$dx1][($dir-2*$rot)%8][0] = 'ignore';
      } elsif ($Rot == 1) {
        $rays->[$y+$i*$dy][$x+$i*$dx][($dir+$rot)%8][0] = 'ignore';			#  45° direction on ≥3
        $rays->[$y+($i+1)*$dy+$dy1][$x+($i+1)*$dx+$dx1][($dir-3*$rot)%8][0] = 'ignore';
      } else { die "Rot=$Rot" }
    }
  }
}

sub doRays ($$$$$$$$$) {
  my($bm,$width,$height, $offs, $cnt, $cntmin, $near, $nearmin) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);
  my(@offs, @cnt, @cntmin, @near, @nearmin);
  @offs = @$offs; @cnt = @$cnt; @cntmin = @$cntmin; @near = @$near; @nearmin = @$nearmin;
  my @pixelsmin = map [@$_], @$bm;		# deep copy
  my($ER, @rays, @longedges, %seenlong, %inLong, %midLong) = (['']);

 DO_RAYS:
  for my $ray_round (0,1) {	# On the second round, some pixels may be decided to be insignificant, and removed
     for my $y (1..$height) {	# Inspect angular neighborhods in the directions from $offs
       my(@r, @row) = [];
       for my $x ( 1..$width ) {
         push @r, [] and next unless my $o = $offs[$y][$x];
         my $r = $rays[$y][$x];
         my @o = grep { !$r->[$_] or $r->[$_][0] =~ /^[D\WP]/ } @$o;	# 'Probable-curve' put here as an experiment XXX; Dense
         my @rr;
         @rr = @$r if $r;
         @rr[ @o ] = @{ inspect_ray $x, $y, \@cnt, \@cntmin, $bm, \@pixelsmin, \@near, \@nearmin, \@o };
         push @r, \@rr;
       }
       $rays[$y] = \@r;
     }
     my(@b_postpone, @g_postpone, @rem_postpone, @un_postpone, @protect, @rhombi, %rhombi, @extra_postpone);
     for my $y (1..$height) {	# 2nd order inspection: check identified dependencies (all dependencies must match;
       for my $x ( 1..$width ) {	#			every dependency must be good in at least one direction)
         for my $dir ( @{$offs[$y][$x]} ) {
           my $ray = $rays[$y][$x][$dir] || next;
           my($keep, $TO, $type, $rot, $checked, $DEP, $remove, $unignore, @rest) = (1, undef, @$ray);
           next unless $DEP or @rest or $remove;
           my @DEP = (($DEP and not ref $DEP->[0]) ? $DEP : ($DEP ? @$DEP : ()));
           for my $ddep (@DEP) {	# Switch to the first "alternative variant" with non-satisfied dependencies
             # Preferred alternatives are grouped by a new-type $ddep->[0], and list of dependent points/dirs;
             # the alternative is chosen out of those for which one of points has all dirs “good”, 
             $keep = 0;
             for my $depPt (@$ddep[1..$#$ddep]) {	# we are OR-ing over the dependencies: we keep if any one matches
               my($KEEP,$X,$Y,@DIR) = (1, @$depPt);
               for my $DIR (@DIR) {	# we are AND-ing over the directions of a dependence: KEEP if all match
                 $KEEP = 0, last unless post_inspect_ray($X, $Y, $DIR, \@rays, $type);	# Can be optimized by merging neighbors???
               }
               $keep = 1, last if $KEEP;
             }
             $TO = $ddep->[0] || '.', last unless $keep;
           }
           push @rem_postpone, $remove if $remove and $keep;
           push @un_postpone, $unignore if $unignore and $keep;
           push @g_postpone, [$y, $x, $dir, @rest] if @rest and $keep;
           push @b_postpone, [$y, $x, $dir, $TO] unless $keep;
           if ($keep and $type =~ /^[3r]/) {{		# 3fork3, rhombus
             my($dx,$dy) = ($dx[$dir],$dy[$dir]);
             next unless $rays[$y+$dy][$x+$dx][($dir+4)%8][0] =~ /^([dcfs])/;	# part of a curve (maybe falsely fake) doubleray curve fake-curve serif
             $rhombi{$x,$y,$dir}++ unless $1 eq 's';	# serif
             push @rhombi, [$x, $y, $dir, $rot, $dx, $dy, "$1"];
           }}
           push @g_postpone, [$y, $x, $dir, [$TO]] if !$keep and $TO eq '´';	# 3fork3, rhombus; check for Q-joins
         }
       }
     }
     while (my $p = shift @rhombi) {
       my($x, $y, $dir, $rot, $dx, $dy, $t)  = @$p;
       my $dir1 = ($dir+$rot)%8;
       my($dx1,$dy1, @opp) = ($dx[$dir1],$dy[$dir1]);
       unless (@opp = grep $rhombi{$x+$dx+$dx1,$y+$dy+$dy1,($_+4)%8}, $dir, $dir1) {
         $rays[$y][$x][$dir][0] = 'Rhombus-force' if $t eq 's' and $cnt[$y+$dy1][$x+$dx1] <= 4;	# As in д, and skip dense
         next;
       }
       next if $t eq 's';			# Done for in-serif
       # Should watch so that we do not break 0663,0d96,1ba7 ٣ ඖ ᮧ
       if (!($dir%2) and $cnt[$y][$x] == 3 and ($rays[$y][$x][($dir+4)%8] || $ER)->[0] eq 'tail'
           and $cnt[$y+$dy1][$x+$dx1] == 4 and ($rays[$y+$dy1][$x+$dx1][$dir] || $ER)->[0] eq 'doubleray'
           and ($rays[$y+$dy+$dy1][$x+$dx+$dx1][$dir] || $ER)->[0] =~ /^[dc]/) {	# Ддщц   doubleray curve
         $rays[$y][$x][$dir][0] = 'Rhombus-force';
         next;
       }
       if ($cnt[$y+$dy+$dy1][$x+$dx+$dx1] == 3
           and grep +(!($_%2) and ($rays[$y+$dy+$dy1][$x+$dx+$dx1][$_] || $ER)->[0] eq 'tail'), @opp) {
         # Ддщц - on the other side.  Detect which one is better.  Should watch so that we do not break 0663,0d96,1ba7
         my($good, $other) = ([$dir, $dx, $dy], [$dir1, $dx1, $dy1]);			# default
         for my $g ($other) {			# no need to check for $good!
           ($good, $other) = ($g, $good) if $rays[$y+$g->[2]][$x+$g->[1]][($g->[0]+4)%8][0] eq 'doubleray';
         }
         if ($cnt[$y+$good->[2]][$x+$good->[1]] == 4 
             and $rays[$y+$good->[2]][$x+$good->[1]][($good->[0]+4)%8][0] eq 'doubleray'
             and $rays[$y][$x][($good->[0]+4)%8][0] =~ /^[dc]/) {		# doubleray curve
           $rays[$y][$x][$other->[0]][0] = $rays[$y+$other->[2]][$x+$other->[1]][($other->[0]+4)%8][0] = 'ignore';
           push @extra_postpone, ['R', $y, $x, $good->[0]];	# may be changed to ' very soon; postpone until this
           next;
         }
       }
       $rays[$y][$x][$dir][0] = '2fork3';
       add_longedge([$x, $y, $dir, $x+$dx+$dx1, $y+$dy+$dy1, $rot], \@longedges, \%seenlong, \%midLong, \%inLong)
         unless $seenlong{$x, $y, $x+$dx+$dx1,$y+$dy+$dy1};
     }
     while (my $p = shift @b_postpone) {
       my($y, $x, $dir, $what)  = @$p;
       $rays[$y][$x][$dir][0] = $what;
     }
     while (my $p = shift @un_postpone) {
       my($x, $y, $dir)  = @$p;
       $protect[$y][$x][$dir]++
     }
     while (my $p = shift @g_postpone) {
       my($Y, $X, $DIR, @p)  = @$p;
       for my $pp (@p) {
#       warn "rays0 $rays[8][5][0] @$pp ", $rays[8][5][0] && "<$rays[8][5][0][0]>";
#  warn "In g_postpone: (@$p)";
         if ($pp->[0] =~ /^I((I)|1)?$/) {				# (only fix '?' if II, and only in one direction unless I
           (undef, my ($x, $y, @pp)) = @$pp;
           for my $dir (@pp) {
             next if $protect[$y][$x][$dir] or $2 and $rays[$y][$x][$dir][0] ne '?';
             $rays[$y][$x][$dir][0] = 'ignore';
             next if $1;
             my $dx = $dx[$dir];
             my $dy = $dy[$dir];
             $rays[$y+$dy][$x+$dx][($dir+4)%8][0] = 'ignore';
           }
           next
         }
         force_line($pp, \@rays), next if $pp->[0] eq 'L';
         if ($pp->[0] =~ /^E([Ef])?(m)?$/) {				# Enforce a sane type (only on '?' if EE, on f if Ef)
           (my($T, $m), undef, my ($x, $y, $dir)) = ($1, !!$2, @$pp);
#		 warn "t[0]=", ord $rays[$y][$x][$dir][0], "; ", ($rays[$y][$x][$dir][0] =~ /^[\WP]/), "; T=$rays[$y][$x][$dir][0]" if $m;
           next unless $rays[$y][$x][$dir][0] =~ ($T ? ($T eq 'f' ? qr/^f/ : qr/^[?P]/) : qr/^[\WP]/);	# '?' fake-curve Probable-curve
           $rays[$y][$x][$dir][0] = 'Enforce';
#		 warn " -> t[0]=", ord $rays[$y][$x][$dir][0], "; ", ($rays[$y][$x][$dir][0] =~ /^[\WP]/), "; T=$rays[$y][$x][$dir][0]" if $m;
#		 $marked++ if $m;
           next;
         }
         if (lc $pp->[0] eq 'n') {				# Enforce notch
           (undef, my ($x, $y, $dir)) = @$pp;
           my $C = 2 + ($pp->[0] eq 'n');
           next unless $cnt[$y][$x] == $C and $rays[$y][$x][$dir][0] eq '?';
           $rays[$y][$x][$dir][0] = 'Enforce';
           next;
         }
         if ($pp->[0] eq 'S') {				# Enforce Sharp
           (undef, my ($x, $y, $dir)) = @$pp;
           next unless $cnt[$y][$x] == 4 and $rays[$y][$x][$dir][0] =~ /^[?fP´r]/; # '?' Probable-curve fake-curve rhombus '´'
           $rays[$y][$x][$dir][0] = 'Enforce';
           next;
         }
         if ($pp->[0] eq 'T') {				# Enforce tip (on M etc.)
           (undef, my($DIR, $rot)) = @$pp;
#                 warn "$X,$Y,$DIR";
           next unless $cnt[$Y][$X] == 3 and $rays[$Y][$X][$DIR] and ($rays[$Y][$X][$DIR][0] || '') =~ /^t/; # tail
           my $x = $X + $dx[$DIR];
           my $y = $Y + $dy[$DIR];
           my $dir = ($DIR+4)%8;
           next unless $cnt[$y][$x] == 1 and $rays[$y][$x][$dir] and ($rays[$y][$x][$dir][0] || '') =~ /^d/; # doubleray
           @{$rays[$y][$x][$dir]}[0,1] = ('MFork',-$rot);	# was doubleray    ____   TM
           $rays[$Y][$X][$DIR][0] = 'Tail';			# was tail          _/
           next;
         }
         if ($pp->[0] =~ 'a') {				# Check arrow backwards
           my $t = $rays[$Y][$X][($DIR+4)%8][0];
           push @extra_postpone, ['a', $Y, $X, $DIR, @$pp[1,2], $t];
           next if $t =~ /^[dctNC]/;		# doubleray, curve, tail, Near-corner or Corner-curve
           $rays[$Y][$X][$DIR][0] = '…';
           next;
         }
         if ($pp->[0] =~ 't') {				# tail; check cedilla
           my $dx = $dx[$DIR];
           my $dy = $dy[$DIR];
           my $T = $rays[$Y+$dy][$X+$dx][($DIR+4)%8];
           next unless $T->[0] =~ /^c/;
           my $rot = $T->[1];
           next unless $rays[$Y][$X][($DIR+$rot+4)%8][0] =~ /^d/;	# doubleray
           my $dx1 = $dx[($DIR+$rot+4)%8];
           my $dy1 = $dy[($DIR+$rot+4)%8];
           next unless $cnt[$Y+$dy1][$X+$dx1] == 4;
           next unless $rays[$Y+$dy1][$X+$dx1][($DIR+$rot+4)%8][0] =~ /^d/;	# doubleray
           next unless $cnt[$Y+2*$dy1][$X+2*$dx1] == 3;				# See 6a81
#		warn "... <$ER> #=$#{$rays[$Y+$dy1][$X+$dx1]} [@{$rays[$Y+$dy1][$X+$dx1]}] <$rays[$Y+$dy1][$X+$dx1][($DIR+2*$rot+4)%8]> x=", $X+$dx1, ", y=", $Y+$dy, ", dir=", ($DIR+2*$rot+4)%8;
# warn($rays->[10][7][6] ? "### <$rays->[10][7][6]> [@{$rays->[10][7][6]}] " . (defined $rays->[10][7][6][0]?'d':'u'):"###### not yet");
           next unless ($rays[$Y+$dy1][$X+$dx1][($DIR+2*$rot+4)%8] || $ER)->[0] =~ /^e/;	# elses-ray (opp fake-curve)
           next unless ($rays[$Y+$dy1][$X+$dx1][($DIR+3*$rot+4)%8] || $ER)->[0] =~ /^f/;	# fake-curve
           my $dx2 = $dx[($DIR+2*$rot+4)%8];
           my $dy2 = $dy[($DIR+2*$rot+4)%8];
           next unless $cnt[$Y+$dy1+$dy2][$X+$dx1+$dy2] == 3;
           next unless ($rays[$Y+$dy1+$dy2][$X+$dx1+$dx2][($DIR+2*$rot)%8] || $ER)->[0] =~ /^f/;	# fake-curve
           $rays[$Y+$dy1][$X+$dx1][($DIR+$rot+4)%8][0] = $rays[$Y+2*$dy1][$X+2*$dx1][($DIR+$rot)%8][0] = 'ignore';
           $rays[$Y+$dy1][$X+$dx1][($DIR+2*$rot+4)%8][0] = 'Enforced';
           $rays[$Y+$dy1+$dy2][$X+$dx1+$dx2][($DIR+2*$rot)%8][0] = 'curve';
           next;
         }
         if ($pp->[0] =~ 'C') {				# Check spurious connectors
           my $dx = $dx[$DIR];
           my $dy = $dy[$DIR];
           my $T = $rays[$Y+$dy][$X+$dx][($DIR+4)%8];
           next if $T->[0] !~ /^(c)/i or $midLong{2*$X+$dx,2*$Y+$dy};
           my($opp, $good) = ($1);
           # For curves (in both directions), check that going their intendend continuation (which is long) in opposite direction
           # has another choice (is a Fork) that this (spurious!) line.
           if ($opp eq 'c') {
             my($seen, $arrows, $deg_corner) = ('', 0);
             for my $C ([$X,$Y,($DIR + 4 + $T->[1])%8, $T->[1]], [$X+$dx,$Y+$dy,($DIR+$pp->[1])%8,$pp->[1]]) {
               my($XX,$YY,$DD,$R) = @$C;
               my $dx1 = $dx[$DD];
               my $dy1 = $dy[$DD];
#                     warn "$X, $Y, $DIR; $XX, $YY, $DD, $R;  $rays[$YY+$dy][$XX+$dx][($DD+4)%8] $rays[$YY][$XX][$DD]"
#                       unless defined $rays[$YY+$dy][$XX+$dx][($DD+4)%8] and defined $rays[$YY][$XX][$DD];
               # Combination of 1 (Tail) and F is good (2af7, 0593)
               $good = 1 unless $rays[$YY+$dy1][$XX+$dx1][($DD+4)%8][0] =~ /^([F°])/
                            and ($1 eq 'F' or $rays[$YY][$XX][($DD-3*$R)%8][0] =~ /^C/ and $deg_corner=1)	# see 2aa1, 2af7
                            and $rays[$YY][$XX][$DD][0] =~ /^([cF1d])/	# Inserting d here requires test for 22, and hurts ῳ
                            and not ((my $m1 = $1) eq 'd' and $rays[$YY+$dy1][$XX+$dx1][$DD][0] =~ /^d/);
               $seen .= $m1 unless $good;		# Matchess succeeded!
               $arrows++ if $rays[$YY][$XX][$DD][0] =~ /^d/			# doubleray
                            and $rays[$YY+$dy1][$XX+$dx1][$DD][0] =~ /^a/
                            and $rays[$YY+$dy1][$XX+$dx1][$DD][1] == -$R;	# arrow 21f6 but not 222e
             }
             $good = 1 if !$good and $seen =~ /F1|1F|(11)/ and ($1 or not $deg_corner);
             $good = 0 if $arrows == 2;
           } else {	# E.g., 2a85
             for my $C ([$X,$Y,($DIR + 4 + 2*$T->[1])%8, 1, $T->[1]], [$X+$dx,$Y+$dy,($DIR+$pp->[1])%8, 0, $pp->[1]]) {
               my($XX,$YY,$DD,$rev,$R) = @$C;
               my $dx1 = $dx[$DD];
               my $dy1 = $dy[$DD];
               if ($rev) {	# Went in the direction of 'Corner-curve'
                 $good = 1 unless $rays[$YY+$dy1][$XX+$dx1][($DD+4)%8][0] =~ /^C/
                              and $rays[$YY][$XX][$DD][0] =~ /^c/ and $rays[$YY][$XX][$DD][1] == $R;
               } else {
                 $good = 1 unless $rays[$YY+$dy1][$XX+$dx1][($DD+4)%8][0] =~ /^°/
                              and ($rays[$YY][$XX][($DD-3*$R)%8] || $ER)->[0] =~ /^([1])/	# cC break a lot of stuff
                                   and ($1 ne 'C' 
                                        or $rays[$YY][$XX][($DD-3*$R)%8][1] == $R)
                              and $rays[$YY][$XX][$DD][0] =~ /^([cd])/;
               }
             }
           }
           unless ($good) {
             $rays[$Y][$X][$DIR][0] = '¢';
             $opp =~ tr/cC/¢₡/;
             $rays[$Y+$dy][$X+$dx][($DIR+4)%8][0] = $opp;
           }
           next;
         }
         if ($pp->[0] eq '´') {				# Q-join
           my $dx = $dx[$DIR];
           my $dy = $dy[$DIR];
           my $T = $rays[$Y+$dy][$X+$dx][($DIR+4)%8];	# stop if the opposite ray is already Enforce⸣d:
           my $B = $T->[1] || 0;
           my $dx0 = $dx[($DIR+$B)%8];
           my $dy0 = $dy[($DIR+$B)%8];
           my $dx1 = $dx[($DIR-$B)%8];
           my $dy1 = $dy[($DIR-$B)%8];
           my ($extra, @LOOP) = $nearmin[$Y+$dy1][$X+$dx1][($DIR-2*$B)%8];
           if ($T->[0] eq 'Probable-curve') {
             next unless (not @rem_postpone or $ray_round == 1)		# Otherwise: triggered on Ӿ
                  and $rays[$Y-$dy0][$X-$dx0][($DIR+$B)%8][0] eq '´'	# The last condition: OK on ɚӿޗ; false positive: ೫.
                  and not ($nearmin[$Y+$dy][$X+$dx][($DIR+2*$B)%8] and $nearmin[$Y-$dy0][$X-$dx0][($DIR+4)%8]);
#		   warn "X=$X, Y=$Y, DIR=$DIR, invROT = $B";
             $rays[$Y][$X][$DIR][0] = 'Enforce';				# Was '´'
             $rays[$Y+$dy][$X+$dx][($DIR+4)%8][0] = 'Enforce';		# Was 'Probable-curve'
             $rays[$Y][$X][($DIR+4+$B)%8][0] = 'Enforce';			# Often is 'f....'
             $rays[$Y-$dy0][$X-$dx0][($DIR+$B)%8][0] = 'Enforce';		# Was '´'
             # $rays[$Y][$X][($DIR+$B+4)%8][0] =~ s/^\W.*/Enforce/ if $cntmin[$Y-$B*$dx1][$X+$B*$dy1] < 3;	    # length=1; Ȼ
#		   $marked = 1;
             next unless $rays[$Y+$dy+$dy1][$X+$dx+$dx1][($DIR+4-$B)%8][0] eq '´';
             $rays[$Y+$dy][$X+$dx][($DIR-$B)%8][0] =~ s/^\W.*/Enforce/;
             $rays[$Y+$dy+$dy1][$X+$dx+$dx1][($DIR+4-$B)%8][0] = 'Enforce';		# Was '´'
             next unless $cntmin[$Y+$dy1][$X+$dx1] <= 4 + !!$extra;
             $LOOP[0]++ if $nearmin[$Y][$X][($DIR+4-$B)%8];
             $LOOP[1]++ if $nearmin[$Y+$dy][$X+$dx][($DIR+$B)%8];
           } elsif ($T->[0] eq '´' and $B == -$rays[$Y][$X][$DIR][1]) {	# part of a convex curve
             # Allow extra spurs coming in from outside/inside (see `Q´).
             my @Ex = ($nearmin[$Y][$X][($DIR+2*$B)%8], $nearmin[$Y+$dy][$X+$dx][($DIR+2*$B)%8]);
#		   warn "[@$T], inC=$cntmin[$Y+$dy1][$X+$dx1], afterTargC=$cntmin[$Y+$dy+$dy1][$X+$dx+$dx1], preC=$cntmin[$Y-$B*$dx1][$X+$B*$dy1]";
             next unless $cntmin[$Y+$dy1][$X+$dx1] <= 4 + !!$extra
                     and $cntmin[$Y+$dy+$dy1][$X+$dx+$dx1] <= 3 and $cntmin[$Y-$B*$dx1][$X+$B*$dy1] <= 3;
             next unless $cntmin[$Y][$X] <= 3 + !!$Ex[0] and $cntmin[$Y+$dy][$X+$dx] <= 3 + !!$Ex[1];
             $rays[$Y][$X][$DIR][0] = 'Enforce';
             $rays[$Y+$dy][$X+$dx][($DIR+4)%8][0] = 'Enforce';
             $rays[$Y-$B*$dx1][$X+$B*$dy1][($DIR+$B)%8][0] = 'Enforce';
             $rays[$Y][$X][($DIR+$B+4)%8][0] =~ s/^\W.*/Enforce/ if $cntmin[$Y-$B*$dx1][$X+$B*$dy1] < 3;	    # length=1; Ȼ
             $rays[$Y+$dy+$dy1][$X+$dx+$dx1][($DIR-$B+4)%8][0] = 'Enforce';
             $rays[$Y+$dy][$X+$dx][($DIR-$B)%8][0] =~ s/^\W.*/Enforce/ if $cntmin[$Y+$dy+$dy1][$X+$dx+$dx1] < 3; # length=1; Ȼ
             next if $extra;
           } else {
             next;
           }	 		# Emulate a double-width stroke:
           for my $semiEdge (($LOOP[0] ? ([$Y,      $X, ($DIR-$B)%8],       [$Y+$dy1, $X+$dx1, ($DIR+4-$B)%8])
                                       : ([$Y+$dy1, $X+$dx1, ($DIR+4)%8],   [$Y+$dy1-$dy, $X+$dx1-$dx, $DIR])),
                             ($LOOP[1] ? ([$Y+$dy,  $X+$dx, ($DIR+$B+4)%8], [$Y+$dy1, $X+$dx1, ($DIR+$B)%8])
                                       : ([$Y+$dy1, $X+$dx1, $DIR],         [$Y+$dy1+$dy, $X+$dx1+$dx, ($DIR+4)%8]))) {
#		     $rays[$semiEdge->[0]][$semiEdge->[1]][$semiEdge->[2]][0] =~ s/^\W.*/Enforce/;
             $rays[$semiEdge->[0]][$semiEdge->[1]][$semiEdge->[2]][0] = 'Enforce'; # Otherwise would not be considered simple due to ??
           }
           for my $semiEdge (($LOOP[0] ? () : ([$Y,      $X, ($DIR-$B)%8],       [$Y+$dy1, $X+$dx1, ($DIR+4-$B)%8])),
                             ($LOOP[1] ? () : ([$Y+$dy,  $X+$dx, ($DIR+$B+4)%8], [$Y+$dy1, $X+$dx1, ($DIR+$B)%8]))) {
             $rays[$semiEdge->[0]][$semiEdge->[1]][$semiEdge->[2]][0] =~ s/^\w.*/Ignored/
#			   and $marked++;
           }
           next;
         }
         die "Unknown postpone action: <$pp->[0]>"
       }
       # $rays[$y][$x][$dir][0] = $what;
     }
     while (my $p = shift @extra_postpone) {
       my($type, $Y, $X, $DIR, @p)  = @$p;
       if ($type eq 'a') {			# Check for 'a' on the other side of the arrow
         my $x = $X + 2*$dx[($DIR+$p[0])%8];
         my $y = $Y + 2*$dy[($DIR+$p[0])%8];
         my $dir = ($DIR-2*$p[0])%8;
         $rays[$Y][$X][$DIR][0] = ($p[1] ? 'x-arrow' : '…')
           unless $rays[$y][$x][$dir][0] =~ /^a/ and (not $p[1] or $rays[$y][$x][($dir+4)%8][0] eq $p[2]);
       }
       if ($type eq 'R') {			# Check for 'a' on the other side of the arrow
         $rays[$Y][$X][$DIR][0] = 'Rhombus-force';
       }
     }
     last DO_RAYS unless @rem_postpone;
     my @SEEN;
     while (my $r = shift @rem_postpone) {
       my($x, $y)  = @$r;
       remove_px($x, $y, \@cntmin, \@pixelsmin, \@nearmin, \@offs) unless $SEEN[$y][$x]++;
     }
  }				# end DO_RAYS
  for my $y (1..$height) {	# In a pair '?'/'f', change '?' to 'Ignore'
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays[$y][$x];
      next unless @$RAYS;
      for my $dir (@{$offs[$y][$x]}) {
        next unless $RAYS->[$dir][0] =~ /^(f)/i;			# fake-curve/Fork
        next if (my $code = $1) eq 'F' and $cnt[$y][$x] != 1;	# Sharp corners (as in V) may result in fork with |stem|=1
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        my $dir1 = ($dir+4)%8;
        $rays[$y1][$x1][$dir1][0] =~ s/^[?1P].*/Tail/ and (@{$RAYS->[$dir]}[0,1] = ('MFork',0)), next	# symmetric MFork
          if $code eq 'F';							# '?', 'Probable-curve', '1Spur'
        $rays[$y1][$x1][$dir1][0] =~ s/^[?P""].*/Ignore/;				# '?', 'Probable-curve', '"'
      }
    }
  }
  die '$ER corrupted' unless @$ER == 1 and $ER->[0] eq '';
  [\@rays, \@longedges, \%seenlong, \%inLong, \%midLong];
}

sub do_Simple_and_edges ($$$$$$$$$) {
  my($ER, $width, $height, $RAYS, $offs, $cnt, $longedges, $seenlong, $inLong, $midLong)
    = ([''], shift, shift, shift, shift, shift, shift, shift, shift, shift);
  my @rays = @$RAYS;
  my(@Simple, @simpleray, @edge, @cntedge, @lastedge, @update);	# Simple points/rays; decided edges
  for my $y (1..$height) {	# Identify simple points/rays
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays[$y][$x];
      next unless @$RAYS;		# Contamination???
      $Simple[$y][$x] = 1, next unless grep { $RAYS->[$_][0] =~ /^[D\WP]/ } @{$offs->[$y][$x]};	# Dense; junk
    }
  }
  for my $y (1..$height) {	# In a pair '?'/'e' with simple neighbor, change '?' to 'Ignore'
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays[$y][$x];
      next unless @$RAYS;
      next unless $Simple[$y][$x];
      for my $dir (@{$offs->[$y][$x]}) {
        next unless $RAYS->[$dir][0] =~ /^e/;
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        my $dir1 = ($dir+4)%8;
        $rays[$y1][$x1][$dir1][0] =~ s/^[?P""].*/Ignore/;		# 'Probable-curve', '?' '"'
      }
    }
  }
####  warn "... <@{$rays[7][2][0]||['undef']}> <@{$rays[7][2][1]||['undef']}>";
  for my $y (1..$height) {	# Identify simple points/rays
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays[$y][$x];
      next unless @$RAYS;		# Contamination???
#            next if $Simple[$y][$x];
          # Recalc simple:
      $Simple[$y][$x] = 1, next unless grep { $RAYS->[$_][0] =~ /^[D\WP]/ } @{$offs->[$y][$x]};	# Dense; junk; Probable-curve
     FIND_GOOD:
      for my $dir ( @{$offs->[$y][$x]} ) {	# For non-simple vertices, find simple directions (it+neighbors non-dense/junk)
        next if $RAYS->[$dir][0] =~ /^[D\WP]/;
        for my $rot (1, -1) {				# Skip if closest angular neighbor is bad (Dense/Probable)
####		warn "miss dir: (x,y,dir,rot)=($x,$y,$dir,$rot); lst=$#$RAYS, ", grep defined $RAYS->[$_], 0..$#$RAYS unless $RAYS->[($dir+$rot)%8];
          next FIND_GOOD if ($RAYS->[($dir+$rot)%8] || $ER)->[0] =~ /^[D\WP]/ and not $RAYS->[$dir][0] =~ /^[BE]/; # Btail/Enforce are checked already!
        }
        $simpleray[$y][$x][$dir]++;
#	      warn "Simple RAY at x=$x y=$y dir=$dir\n";
      }
    }
  }
#	      warn "Simple RAY ====\n";
  for my $y (1..$height) {	# Identify simple edges (should be simple in both directions, and of non-fake types)
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays[$y][$x];
      my $ok = $Simple[$y][$x] 
        or my $smpl = $simpleray[$y][$x];			# Not cleared if $ok; we do not care
      for my $dir ( @{$offs->[$y][$x]} ) {
        last if $dir > 3;					# Inspect one end only
        my $semi_bad = 0;
        next unless $ok or $smpl->[$dir] or 2 >= $cnt->[$y][$x] and $RAYS->[$dir][0] eq '°' and ++$semi_bad; # ° = not confirmed Fork
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        my $dir1 = ($dir+4)%8;
        next unless $Simple[$y1][$x1] or $simpleray[$y1][$x1][$dir1]
             or 2 >= $cnt->[$y1][$x1] and $rays[$y1][$x1][$dir1][0] eq '°' and ++$semi_bad < 2;
# warn "Candidate for °-ray at x=$x y=$y dir=$dir\n" if $semi_bad;
# doubleray, curve, notch, serif, (B)tail, 1Spur, [M]Fork, Enforced, Sharp, m-joint, Near-corner, Corner-curve, bend-sharp,
# Tail, A/arrow, Rhombus-force
        #   Omit: [Zh/K-]fake-curve, Ignore, rhombus, i, fork4, elses-ray, 3fork3, 2fork3, 4fork, xFork, Dense, x-arrow, \W-junk
        next unless 2 - $semi_bad == grep /^[dcnstB1FMESmNCbTAaR]/, $RAYS->[$dir][0], $rays[$y1][$x1][$dir1][0];
        add_edge([$x, $y, $dir, $x1, $y1], \@edge, \@cntedge, \@lastedge);	# Good only for 1-edge pixels
      }
    }
  }
  my %candidates_way_out;
  for my $y (1..$height) {	# Identify singletons with a valid way out (one d in a group of d,e,f,K)
    for my $x ( 1..$width ) {
      next unless $Simple[$y][$x] and ($cntedge[$y][$x] || 0) <= 1;	# If already have two edges, do not try to find complicated...
#            die "x=$x, y=$y, Simple=$Simple[$y][$x], rays=<@{$rays[$y][$x]}>" unless defined $cnt->[$y][$x];
      next if $cnt->[$y][$x] > 6;					# Give up if too many neighbors
      my @Neighbors = @{$offs->[$y][$x]};			# Deep copy
      push @Neighbors, shift @Neighbors while $Neighbors[-1] == ($Neighbors[0] + 7)%8; # Rotate to start of a run
      my(@res, $bad, @good, @maybe, %forced, $L, @Zh);
      my $RAYS = $rays[$y][$x];
      # Before, we assumed that at most one edge is present
      $L = $lastedge[$y][$x] if $cntedge[$y][$x];	# Connect only as a curve continuation, and only if it continues back
      for my $d ( 0..$#Neighbors ) {
        my $dir = $Neighbors[$d];
        (!$bad and (   @Zh == 1 and @good == 1 and push @res, [$Zh[0]] 
                    or @good == 1  and push @res, [$good[0]]
                    or @maybe == 1 and push @res, [$maybe[0], 1])), # Finish previous group
          $bad=0, @good = @maybe = @Zh = ()			# Start processing a new group
            if $dir != ($Neighbors[$d-1] + 1)%8;			#   if $dir is after a gap
        $bad++, next unless $RAYS->[$dir][0] =~ /^[dKZfIeiFMxR]/;	# doubleray,[Zh/K-]fake-curve,Ignore,elses-ray,ignore,[M]Fork,x-arrow,Rhombus-force
        my $sharp_angle = (defined $L and abs(4 - abs($L-$dir)) >= 2);
        push(@good, $dir), next
          if $RAYS->[$dir][0] =~ /^[dR]/ and not $sharp_angle;		# Pick up doubleray, Rhombus-force
        $forced{$dir}++, push(@maybe, $dir), next
          if $RAYS->[$dir][0] =~ /^[FM]/ and defined $L and not $sharp_angle;	# [M]Fork; pairs of Fc should end here...
        $forced{$dir}++, push(@Zh, $dir), next if $RAYS->[$dir][0] =~ /^Z/;	# special-case Zh-joint
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        my $rays1 = $rays[$y1][$x1] or next;
        my $R = $rays1->[($dir+4)%8] or next;
        $forced{$dir}++, push(@good, $dir),  next if $RAYS->[$dir][0] =~ /^e/    and $R->[0] =~ /^d/; # reversed doublerays
        $forced{$dir}++, push(@maybe, $dir), next if $RAYS->[$dir][0] =~ /^[fK]/ and $R->[0] =~ /^d/; # reversed doublerays
      }
      !$bad and (   @Zh == 1 and @good == 1 and push @res, [$Zh[0]]
                 or @good == 1  and push @res, [$good[0]]
                 or @maybe == 1 and push @res, [$maybe[0], 1]);
#   warn "c=$c, x=$x, y=$y ==> ways out @res (out of @Neighbors): ", join '|', map $RAYS->[$_][0], @Neighbors;
      next if @res > 2;		# Do not get too carried away...
      if ($cntedge[$y][$x]) {		# Connect only as a curve continuation, and only if it continues back
        @res = grep 1 >= abs(4 - abs($L-$_->[0])), @res;	# i.e., almost opposite
        # Maybe if two are left, chose by good vs maybe?
        if (0 and @res > 1) {{	# does not actually change anything...
          my @r = grep !$_->[1], @res or last;
          @r < @res or last;
          @res = @r;
        }}
# warn "filtered: (@res)\n";
      }
      $candidates_way_out{$y,$x} = {map {+( $_->[0] => [$forced{$_->[0]}, @$_] )} @res} if @res;
    }
  }
  for my $y (1..$height) {	# Finish identifying singletons with a valid way out (one d in a group of d,e,f,K)
    for my $x ( 1..$width ) {
      next unless my $cand = $candidates_way_out{$y,$x};
      my @ways = values %$cand;
      my @res;
      # Before, we assumed that at most one edge is present
#            my $L = $cntedge[$y][$x] and $lastedge[$y][$x]; # Connect only as a curve continuation, and only if it continues back
      if ($cntedge[$y][$x]) {		# Connect only as a curve continuation, and only if it continues back
        # Do not connect to something which is not a simple edge — or at least doubleray or curve!
        for my $d (@ways) {
          my $dir = $d->[1];
          push(@res, $dir), next if $d->[0];	# forced
          my $x1 = $x + $dx[$dir];
          my $y1 = $y + $dy[$dir];
          my $good = ($edge[$y1][$x1][$dir] or $rays[$y1][$x1][$dir][0] =~ /^[dcR]/	# doubleray curve Rhombus-force
                      or $candidates_way_out{$y1,$x1}{$dir});
          unless ($good) {
            my $x2 = $x + 2*$dx[$dir];
            my $y2 = $y + 2*$dy[$dir];
            my $dir2 = ($dir+4)%8;
            $good = $candidates_way_out{$y2,$x2}{$dir2};
          }
          push @res, $dir if $good;
        }
        last if @res > 1;
      } else {
        @res = map $_->[1], @ways;
      }
# warn "filtered:: (@res)\n";
      push @update, [$x,$y,@res];
    }
  }
  my %updated;
  while (my $u = shift @update) {
    my($x, $y, @res) = @$u;
    for my $dir (@res) {
      my $x1 = $x + $dx[$dir];
      my $y1 = $y + $dy[$dir];
      my $dir1 = ($dir+4)%8;
      next if $updated{$x,$y,$dir}++ or $updated{$x1,$y1,$dir1}++;
      add_edge([$x, $y, $dir, $x1, $y1], \@edge, \@cntedge, \@lastedge);
#warn "Update: $x,$y --> $x1,$y1\n";
    }
  }
  for my $e (@$longedges) {	# If a prefered way is found elsewhere, replace longedge by the prefered way
    next if not ref $e and $e eq 'erased';
    my($x, $y, $x1,$y1, $offset, $dir, $rot) = @$e;
    my $dir0 = ($dir+$rot)%8;
    my @atBEG = grep $edge[$y][$x][$_],         $dir, $dir0;
    my @atEND = grep $edge[$y1][$x1][($_+4)%8], $dir, $dir0;
    next unless @atBEG or @atEND;
    my @add;	# Had a longedge since couldn’t choose 1 of 2 ways around a rhombus; looks like something made a preference…
    unless (@atBEG and @atEND) {	# If have a joiner on both sides, may just drop the longedge altogether
      my @have = (@atBEG, @atEND);	# actually, one of them
      next if @have == 2;			# XXX It is not clear what to add, so do not drop!  ???
      my $DIR = ($dir + (($have[0] == $dir) && $rot))%8;	# Add $dir+$rot on the OTHER side.
      my($dx,$dy) = ($dx[$DIR],$dy[$DIR]);
      if (@atEND) {
        @add = [$x, $y, $DIR, $x + $dx, $y + $dy];
      } else {
        @add = [$x1, $y1, ($DIR+4)%8, $x1 - $dx, $y1 - $dy];
      }
    }
    add_edge($_, \@edge, \@cntedge, \@lastedge) for @add;
    clear_longedge([$x, $y, $x1, $y1, $offset], $longedges, $seenlong, $midLong, $inLong);
  }
  die '$ER corrupted' if $ER and (@$ER != 1 or $ER->[0] ne '');
  [\@edge, \@cntedge, \@lastedge, \@rays, $longedges, $seenlong, $midLong, $inLong, \@Simple];
}

sub find_blobs ($$$$$$;$$) {
  my($blob, $width, $height, $pixels, $cntedge, $offs, $lastedge, $skip, $c) = (shift, shift, shift, shift, shift, shift, shift, shift, 0);
  $blob->[0] = [];
  for my $y (1..$height) {
    $blob->[$y] = [];
    for my $x ( 1..$width ) {
      next unless $pixels->[$y][$x]; 
      $blob->[$y][$x] = 1, $c++ unless $cntedge->[$y][$x];
    }
  }
  push @$blob, [];
  my @doblob;
  if ($lastedge) {		# Add "better consider the same as blob" non-blob pixels
    for my $y (1..$height) {
      for my $x ( 1..$width ) {
        next if $blob->[$y][$x] or ($cntedge->[$y][$x] || 0) != 1; 
        my $D = ($lastedge->[$y][$x] + 4)%8;
        next unless $blob->[$y + $dy[$D]][$x + $dx[$D]];
        my($C, $CC);
        for my $rot ( 1, -1, ($D % 2 ? (): (-2,2)) ) {	# 22b6 ⊶
          $CC++, last if $blob->[$y + $dy[($D+$rot)%8]][$x + $dx[($D+$rot)%8]];
        }
        for my $dir ( @{$offs->[$y][$x]} ) {
          $C++, last if $dir != $D and $blob->[$y + $dy[$dir]][$x + $dx[$dir]];
        }
        push(@doblob, [$y,$x]), $c++, ($CC or $marked++) if $C and not $skip->{$y,$x};
      }
    }
  }
  $blob->[$_->[0]][$_->[1]]++ for @doblob;
  for my $y (1..$height) {	# Replace 1 by 1 + count of neighbor blobs
    next unless $blob->[$y];
    for my $x ( 1..$width ) {
      next unless $blob->[$y][$x]; 
      for my $dir ( @{$offs->[$y][$x]} ) {
        $blob->[$y][$x]++ if $blob->[$y + $dy[$dir]][$x + $dx[$dir]];
      }
    }
  }
  $c;
}

sub nnn_do_Simple_and_edges ($$$$$$$) {
  my($width, $height, $offs, $pixels, $edge, $cntedge,,$lastedge)
    = (shift, shift, shift, shift, shift, shift, shift);
  my($do_more, @blob, @clearEdge, %suspectShaft, %skipExtraBlob) = 1;
  my $blobs = find_blobs(\@blob, $width, $height, $pixels, $cntedge, $offs);
  while ($blobs and $do_more) {	# clear edges with two “noisy” surroundings
    for my $y (0..$#$edge) {
      next unless $edge->[$y];
      for my $x ( 0..$#{ $edge->[$y] } ) {
        next unless $edge->[$y][$x]; 
        for my $dir ( 0..3 ) {				# Do only once per edge
          next unless $edge->[$y][$x][$dir ];
          my $x1 = $x + (my $dx = $dx[$dir]);
          my $y1 = $y + (my $dy = $dy[$dir]);
          if ($dir % 2) {
            my(@CC, $CC, $clear);
            for my $rot ( -1, 1 ) {		# Three big, bad blobs on the same side of an edge
              my($dx1, $dy1) = ($rot*$dy, -$rot*$dx);
              my($dx2, $dy2, $c, $C) = (($dy==$dy1 ? (0, $dy1) : ($dx1, 0)), 0, 0);	# dot product with $dxy
              # Go in the natural order of 3 neighbors (projection on $dxy):
              my @DD = (($dy==$dy1 ? ([$y, $x+$dx1], [$y+$dy1,$x]) : ([$y+$dy1,$x], [$y, $x+$dx1])), [$y1+$dy2,$x1+$dx2]);
              for my $DD (0..2) {
                my $D = $DD[$DD];
                $CC[$DD]++, $C++ if ($blob[$D->[0]][$D->[1]] || 0) >= 3 - ($DD==1);	# More forgiving for middle; 0909
                $c++ if $pixels->[$D->[0]][$D->[1]];
              }
              $clear++ and last if $c == 3 and $C >= 2;
              $CC += $C
            }					# This gives reasonable (?) results
            # warn "$c: diag blob? x,y=$x,$y,$dir $clear CC=$CC <@CC>" if $CC >= 2;
            push @clearEdge, [$x, $y, $dir, $x+$dx, $y+$dy] and last if $clear or $CC >= 3 and $CC[1] and ($CC[0] or $CC[2]);
#                      if ($blob[$y][$x+$dx1] || 0) >= 3 and ($blob[$y+$dy1][$x] || 0) >= 3 and ($blob[$y1+$dy2][$x1+$dx2] || 0) >= 3;
          } else {
            my($tot, $done, %neigh, $lastN, $lastR, $lastDx, $lastDy) = (0);
            for my $rot ( -1, 1 ) {		# Two big, bad blobs on the same side of an edge
              my($dx1, $dy1) = (-$rot*$dy, $rot*$dx);
              $neigh{$rot} = [($blob[$y+$dy1][$x+$dx1] || 0) >= 3, ($blob[$y1+$dy1][$x1+$dx1] || 0) >= 3];
              $neigh{$rot}[$_] and ++$tot and ($lastN, $lastR, $lastDx, $lastDy) = ($_, $rot, $dx1, $dy1) for 0, 1;
              ++$done and push @clearEdge, [$x, $y, $dir, $x+$dx, $y+$dy] and last if $neigh{$rot}[0] and $neigh{$rot}[1];
            }
            if (!$done and $cntedge->[$y][$x] == 1 and $cntedge->[$y1][$x1] == 1) {	# Detect bold arrow tips/barbs
              ++$done and push @clearEdge, [$x, $y, $dir, $x+$dx, $y+$dy] if grep 2 == $neigh{1}[$_] + $neigh{-1}[$_], 0, 1;
              if (!$done and $tot == 1) {		# fake serifs near blobs
                my($X, $Y, $D) = ($x, $y);
                if ($lastN) {
                  ($x, $y, $D) = ($x1, $y1, $dir);
                } else {
                  ($dx, $dy, $D, $lastR) = (-$dx, -$dy, ($dir+4)%8, -$lastR);
                }
                if (($blob[$y+$dy][$x+$dx] || 0) >= 3 and ($blob[$y+2*$lastDy][$x+2*$lastDx] || 0) >= 3 
                    and ($blob[$y+$dy+$lastDy][$x+$dx+$lastDx] || 0) >= 3 and not $blob[$y+$dy-$lastDy][$x+$dx-$lastDx]) {
                  push @clearEdge, [$X, $Y, $dir, $x1, $y1];
                  # warn sprintf "barb: $X, $Y, $dir, $x1, $y1 (%d %d %d) $lastN $lastR", $y+2*$lastDy,$x+2*$lastDx,($D+3*$lastR)%8;
                  $suspectShaft{$y+2*$lastDy,$x+2*$lastDx,($D+3*$lastR)%8}++;
                }
              }
            }
          }
        }
      }
    }
    # warn "remove: @$_[0..2]" for @clearEdge;
    # @clearEdge = ();
    $do_more = @clearEdge;
    clear_edge($_,$edge,$cntedge,$lastedge) for @clearEdge;	# [$x, $y, $dir, $x1, $y1]
    @clearEdge = ();
    # my $rep;
    for my $K (keys %suspectShaft) {
      last if $suspectShaft{$K} != 2;
      my($y, $x, $dir) = split /$;/o, $K;
      # warn "rep shafts" unless $rep++;
      # warn "shaft ($c) $x $y, $dir <$K> $suspectShaft{$K}";
      my($x1, $y1) = ($x+$dx[$dir], $y+$dy[$dir]);
      last if ($cntedge->[$y1][$x1] || 0) != 1 or $lastedge->[$y1][$x1] != $dir;
      add_edge([$x, $y, $dir, $x1, $y1], $edge, $cntedge, $lastedge);
      $do_more++;
      $skipExtraBlob{$y,$x}++;
    }
    %suspectShaft = ();
    $blobs = find_blobs(\@blob, $width, $height, $pixels, $cntedge, $offs);
    # warn "blobs: $blobs ($do_more edges removed)";
  }
  [$edge, $cntedge, $lastedge, $blobs, \@blob, \%skipExtraBlob];
}

sub nnn0_do_Simple_and_edges ($$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $rays, $inLong, $blob)
    = (shift, shift, shift, shift, shift, shift, shift, shift);
  my @edgeAdd;
  for my $y (1..$height) {
    for my $x ( 1..$width ) {
      next unless 1 == ($cntedge->[$y][$x] || 0) and not $inLong->{$x,$y};
      my $dir = $lastedge->[$y][$x];
      my $x1 = $x - (my $dx = $dx[$dir]);
      my $y1 = $y - (my $dy = $dy[$dir]);
      next if $inLong->{$x1,$y1};
      if ($dir < 4) {		# symmetric operations
        push @edgeAdd, [$x1, $y1, $dir, $x, $y]
          if 1 == ($cntedge->[$y1][$x1] || 0) and $lastedge->[$y1][$x1] == ($dir+4)%8;	# end-to-end edges
      }
      my $r;
      push @edgeAdd, [$x1, $y1, $dir, $x, $y]			# Not good for 210a 2274 fffd
        if 1 == ($blob->[$y1][$x1] || 0)				# blob singleton
           or !($dir & 0x1) and 1 == ($cntedge->[$y1][$x1] || 0) 	# 04fa
              and 2 == abs(($lastedge->[$y1][$x1] - $dir)%8 - 4)	# perpendicular
              and $rays->[$y][$x][$dir][0] =~ /^([tBdcN])/		# (B)tail doubleray curve Near-corner
              and ($1 ne 'c' or ($r = $rays->[$y][$x][$dir][1]	# curve's curving (04fe)
                                 and not $rays->[$y][$x][($dir+4+$r)%8]));
    }
  }
#            warn("adding @$_"),
  add_edge($_, $edge, $cntedge, $lastedge) for @edgeAdd;
  [$edge, $cntedge, $lastedge];
}

sub calc_Blobby ($$$$$$) {	# (Re-)Count neighbors in blobs
  my ($height, $width, $cntedge, $offs, $cntBlobby, $lastBlobby) = (shift, shift, shift, shift, shift, shift);
  @$cntBlobby = ();
  for my $y (1..$height) {
    for my $x ( 1..$width ) {
      my ($c,$l);
      for my $dir (@{$offs->[$y][$x]}) {
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        $c++, $l=$dir unless $cntedge->[$y1][$x1];
      }
      $cntBlobby->[$y][$x] = $c;
      $lastBlobby->[$y][$x] = $l;
    }
  }
}

sub nnn1_do_Simple_and_edges ($$$$$$$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $rays, $inLong, $midLong, $seenlong, $longedges, $blob, $offs, $cnt)
    = (shift, shift, shift, shift, shift, shift,              shift, shift, shift, shift,        shift, shift, shift);
  my @edgeAdd;
  my(@questEdges,@dblCoordEdges,@cntBlobby,@lastBlobby,@outType,@outCont,@ignore,@toClear,%toClear2,@to4fork,@maybe3Fr);
  calc_Blobby($height, $width, $cntedge, $offs, \@cntBlobby, \@lastBlobby);
  for my $y (1..$height) {	# Detect more rhombi (pairs 3↔P, 3↔I, 3→´)
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays->[$y][$x];
      next unless @$RAYS;
      for my $dir (@{$offs->[$y][$x]}) {
        if ($RAYS->[$dir][0] =~ /^3/) {
          my $d = ($dir + (my $rot = $RAYS->[$dir][1]))%8;
          my $x1 = $x + $dx[$dir] + $dx[$d];
          my $y1 = $y + $dy[$dir] + $dy[$d];
#                warn "$char: 3 vs ";
 #         $marked++ if
          next unless $rays->[$y1][$x1][($d+4)%8][0] =~ /^([PI´Fr])/;	# Probably-curve; Ignore(d); '´' does not actually appear Fork, rhombus
          my $Opp = $1;
#		$marked = ($1 eq "´"), next;
          if ($cnt->[$y1][$x1] > 4) {				# XXXX tmp!!!!!!
            my $blobs = !$cntedge->[$y1][$x1] + ($cntBlobby[$y1][$x1] || 0); # may step outside???
            next unless $blobs < 2;
            # Detect ⧣ ⧤ ⧥ (also 㗬); Assume horizontal/vertical $dir
            my($D,$cntE) = (($dir - $RAYS->[$dir][1])%8);
            next unless grep !$cnt->[$y  + $_*(2*$dy[$dir] - $dy[$d])][$x  + $_*(2*$dx[$dir] - $dx[$d])], -1, 1, 2
                     or grep !$cnt->[$y1 + $_*(2*$dy[$dir] - $dy[$d])][$x1 + $_*(2*$dx[$dir] - $dx[$d])], -1, 1
                     or grep($cntE += !!$rays->[$y  + $_*(2*$dy[$dir] - $dy[$d])][$x  + $_*(2*$dx[$dir] - $dx[$d])][$D], -1, 0, 1),
                        grep($cntE += !!$rays->[$y1 + $_*(2*$dy[$dir] - $dy[$d])][$x1 + $_*(2*$dx[$dir] - $dx[$d])][$D], -1, 0),
                        $cntE < 2;			# 㩄, 㗬: 2
#                $marked++
#                  , warn "edgeTarg=$cntedge->[$y1][$x1]; blobTarg=$cntBlobby[$y1][$x1] (last=$lastBlobby[$y1][$x1]); $x,$y,$dir"
          }
          my $converted;
          next if $Opp =~ /^[Fr]/ and $edge->[$y1][$x1][($d+4)%8];		# May improve??? XXXX 0468 Ѩ 114E ᅎ
          if ($Opp =~ /^[Fr]/ and $rays->[$y + $dy[$dir]][$x + $dx[$dir]][($dir + (2+($dir%2))*$rot)%8]
              and $rays->[$y + $dy[$dir]][$x + $dx[$dir]][($dir + (2+($dir%2))*$rot)%8][0] =~ /^¢/ ) {	# ₨ 㚌
            push @edgeAdd, [$x + $dx[$dir],$y + $dy[$dir],$d,$x1,$y1];
            next
          }
          if (($cntedge->[$y1][$x1] || 0) == 1 and ($cntedge->[$y][$x] || 0) == 1
                        and $edge->[$y1][$x1][$dir] and $edge->[$y][$x][($dir-$RAYS->[$dir][1]+4)%8]) { # tilde: ≁; enforce curve
            my $x2 = $x + $dx[$dir];
            my $y2 = $y + $dy[$dir];
#                  push(@maybe3Fr, [$x,$y,$dir,$x1,$y1,$d]), next if $Opp =~ /^[Fr]/;
            push @edgeAdd, [$x,$y,$dir,$x2,$y2], [$x2,$y2,$d,$x1,$y1];
#       		  $marked++,
            $converted++, next;
          }
#                push(@maybe3Fr, [$x,$y,$dir,$x1,$y1,$d]), next if $Opp =~ /^[Fr]/;
          if ($rays->[$y1][$x1][($dir+4)%8][0] =~ /^F/ and $rays->[$y+$dy[$d]][$x+$dx[$d]][$dir][0] =~ /^d/) { # Fork doubleray
#                  $marked++, next;
            push @ignore, $rays->[$y1][$x1][($dir+4)%8], $rays->[$y+$dy[$d]][$x+$dx[$d]][$dir];
            push @toClear, [$x1, $y1, ($dir+4)%8, $x+$dx[$d], $y+$dy[$d]];
          }
          # Detect when there are extra dd-edges to remove (near 3)
          for my $Side ([-1, qr/^(?:f|([cd]))/], [1, qr/^\?/, 1]) {			# fake-curve '?' curve doubleray
            my $D = ($dir + $Side->[0]*$RAYS->[$dir][1])%8;
            my $x2 = $x + $dx[$D];
            my $y2 = $y + $dy[$D];
            my $rays2 = $rays->[$y2][$x2];
            next unless $rays2->[($D+4)%8] and $rays2->[($D+4)%8][0] =~ /^d/
                    and $RAYS->[$D]        and $RAYS->[$D][0] =~ /^(?:(d)|\?)/;	# doubleray '?'
            if ($1) {
#      		      warn "r2=$rays2->[$D][0]; side=$Side->[1]; allow2=$Side->[2]";
              next unless $rays2->[$D] and $rays2->[$D][0] =~ $Side->[1];
              if ($1) {						# Only ੴ for the choice $d; for $D many: ⱔ, etc; not good for ㉽ 䉸 {
#       		      warn "N=$cntedge->[$y2][$x2]; s=$cntedge->[$y][$x]";
                next unless ($cntedge->[$y2][$x2] || 0) == 3 and ($cntedge->[$y][$x] || 0) == 2
                        and $edge->[$y2][$x2][($d-2*$RAYS->[$dir][1])%8] and grep $edge->[$y][$x][($_+4)%8], $d, $D;
#       		      $marked++;
              }
            } else { next unless not $rays2->[$D]
#       		  			and ++$marked
                   }
#       		  $marked = 1;
            my $cont = ($Side->[2] and $rays->[$y + 2*$dy[$D]][$x + 2*$dx[$D]][($D+4)%8]);
            push @ignore, $RAYS->[$D], $rays2->[($D+4)%8], ( $cont ? $cont : () );
            push @toClear, [$x, $y, $D, $x2, $y2] if $edge->[$y][$x][$D];
          }
          # 3↔P may be repeated opposite to 3↔P or 3↔I: see C481 쒁, F91B 亂.  We remove extra edges for duplicates too.
          push @to4fork, [$x, $y, $dir, $x1, $y1, $RAYS->[$dir][1]] unless $converted;
        }
      }
    }
  }
  $_->[0] = 'ignore' for @ignore;
  for my $e (@toClear) {
    my($x, $y, $dir, $x1, $y1) = @$e;
    clear_edge($e,$edge,$cntedge,$lastedge) unless $toClear2{$x+$x1,$y+$y1}++; # [$x, $y, $dir, $x1, $y1]
  }
  for my $e (@to4fork) {
    my($x, $y, $dir, $x1, $y1, $rot) = @$e;
    next if $seenlong->{$x, $y, $x1, $y1};
    $rays->[$y][$x][$dir][0] = '4fork';
    my $D = ($dir + $rot + 4)%8;
    $rays->[$y1][$x1][$D][0] = 'xFork';
    add_longedge($e, $longedges, $seenlong, $midLong, $inLong);
  }
  add_edge($_, $edge, $cntedge, $lastedge) for @edgeAdd;
  calc_Blobby($height, $width, $cntedge, $offs, \@cntBlobby, \@lastBlobby);	# In fact, this has no practical effect on the next block
  @edgeAdd = ();
  for my $y (1..$height) {	# Upgrade suitable pairs ´´ to edges
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays->[$y][$x];
      next unless @$RAYS;		# Contamination???
      for my $dir (grep { $RAYS->[$_][0] =~ /^[´]/ } @{$offs->[$y][$x]}) {	# '´'
        next if $dir > 3;							# symmetric
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        my $dir1 = ($dir+4)%8;
        next unless $rays->[$y1][$x1][$dir1][0] =~ /^([´])/;		# '´'
        next if $cnt->[$y][$x] + $cnt->[$y1][$x1] > 8;				# 04FE Ӿ
        next if grep +($cntBlobby[$_->[1]][$_->[0]] || 0) > 3, [$x,$y], [$x1,$y1];
        my $cX  = grep !$cntedge->[$_->[1]][$_->[0]], [$x,$y], [$x1,$y1];
        next if grep !$cntedge->[$_->[1]][$_->[0]] && ($cntBlobby[$_->[1]][$_->[0]] || 0) > 1 + ($cX == 2), [$x,$y], [$x1,$y1];
        my $cXX = grep !$cntedge->[$_->[1]][$_->[0]] && ($cntBlobby[$_->[1]][$_->[0]] || 0) > ($cX == 2), [$x,$y], [$x1,$y1];
        my $rot = $RAYS->[$dir][1];
        next unless $rays->[$y1][$x1][$dir1][1] == -$rot;
        my $d = ($dir+$rot)%8;
        my $in = $rays->[$y+$dy[$d]][$x+$dx[$d]];
        next if 2 == $cXX and not ($in and !$cntedge->[$y+$dy[$d]][$x+$dx[$d]] and $cnt->[$y+$dy[$d]][$x+$dx[$d]] < 6); # 0904 ऄ
        push @edgeAdd, [$x,$y,$dir,$x1,$y1];
        for my $opp (0, 1) {
          my($x,$y,$dir,$rot) = ($opp ? ($x1,$y1,$dir1,-$rot) : ($x,$y,$dir,$rot));
          my $out = $RAYS->[($dir-2*$rot)%8];	# Now: the next condition works for ≥1 end
          next if $cnt->[$y][$x] - !!$in - !!$out > 2;	# Now can create the neighbor edges
          my $D = ($dir-$rot+4)%8;
          push @edgeAdd, [$x,$y,$D,$x+$dx[$D],$y+$dy[$D]] if $rays->[$y][$x][$D] and not $edge->[$y][$x][$D];
        }
#              $marked++;
  }}}
  add_edge($_, $edge, $cntedge, $lastedge) for @edgeAdd;
  calc_Blobby($height, $width, $cntedge, $offs, \@cntBlobby, \@lastBlobby);	# In fact, this has no practical effect on the next block
  @edgeAdd = ();
  for my $qRound (0,1) {
# warn($rays->[7][2][7] ? "### <$rays->[7][2][7]> [@{$rays->[7][2][7]}] " . (defined $rays->[7][2][7][0]?'d':'u'):"###### not yet");
    for my $y (1..$height) {	# Upgrade suitable pairs ?c ?d ?° to edges
      for my $x ( 1..$width ) {
        next unless my $RAYS = $rays->[$y][$x];
        next unless @$RAYS;		# Contamination???
        for my $dir (grep { $RAYS->[$_][0] =~ /^[?]/ } @{$offs->[$y][$x]}) {
          my $x1 = $x + $dx[$dir];
          my $y1 = $y + $dy[$dir];
          my $dir1 = ($dir+4)%8;
          next unless $rays->[$y1][$x1][$dir1][0] =~ /^([dc°])/		# 'doubleray', 'curve', disabled-Fork
                            and not $edge->[$y][$x][$dir];
#		warn "0 $1 [$y][$x][$dir] [$y1][$x1][$dir1]\n";
          my($Opp, $inBlob) = "$1";
#		$marked++;
        CHECK_BLOB:
          for my $DD (1, -1) {		# abort if near a blob
            my @Shear = ($dir % 2 ? (-1,1) : 0);
            for my $shear (@Shear) {
              my $D = (2+$shear)*$DD;
              my($dir2, $badD, $bad0, $blobby, $smallBlobby) = (($dir+$D)%8, 0, 0, 0, 0);
              for my $P ([$x,$y], [$x1,$y1]) {
                $bad0 += !$cntedge->[$P->[1]][$P->[0]];
                next unless $rays->[$P->[1]][$P->[0]][$dir2];
                my $x2 = $P->[0] + $dx[$dir2];
                my $y2 = $P->[1] + $dy[$dir2];
#		    $badD++ if $cntmin[$y2][$x2] and $cntmin[$y2][$x2] > 5 and not $cntedge->[$y2][$x2];	# Less strict than for `Dense´
#		    $badD += !!$blob[$y2][$x2];	# Less strict than for `Dense´
#		    $bad0 += !!$blob[$P->[1]][$P->[0]];
                $badD += !$cntedge->[$y2][$x2];
                my $back = $rays->[$P->[1]][$P->[0]][($dir2+4)%8];
                $blobby++ if (!$cntedge->[$P->[1]][$P->[0]] or ($cnt->[$P->[1]][$P->[0]] + !$back) > 5) # इ
                             and (!$cntedge->[$y2][$x2] and (($cntBlobby[$y2][$x2]||0) > 2		  # ध:4; ሯ:3; ऄ इ: 2
                                                           or $cntBlobby[$y2][$x2] and $cnt->[$y2][$x2] > 5)	# 㜰
                                  or ($cntBlobby[$y2][$x2]||0) > 2 and $cnt->[$y2][$x2] > 5);	# ⓲
                $smallBlobby++ if !$cntedge->[$P->[1]][$P->[0]] and !$cntedge->[$y2][$x2] and $cnt->[$y2][$x2] < 5;	# ᎍ
              }
#		  warn "[$x, $y]->$dir: rot=$D: edge:$bad0, near:$badD, blobby:$blobby sm:$smallBlobby (",$cntedge->[$y][$x]||0, " ", $cntedge->[$y1][$x1]||0,")" if not $qRound and $Opp eq 'c';
              my $bad00 = ($bad0 >= 2 - !$shear);				# be stricter on diagonal lines
              $inBlob++, last CHECK_BLOB if $bad00 and $badD > 1			# ᢜ
                                            or $blobby or $smallBlobby and $badD >= 2;
            }
          }
          next if $inBlob and $qRound;
#		warn "1 $Opp [$y][$x][$dir] [$y1][$x1][$dir1] inblob=",!!$inBlob,"\n";
          next if grep +($rays->[$y][$x][($dir+$_)%8] and $rays->[$y][$x][($dir+$_)%8][0] =~ /^A/), 2, -2;	# Arrow
          if ($qRound) {
#		  warn "--> $Opp [$y][$x][$dir] [$y1][$x1][$dir1] [",join(',', map !!$questEdges[$y][$x][($dir+$_)%8], -1,1),"] [",join(',', map !!$questEdges[$y1][$x1][($dir1+$_)%8], -1,1),"]\n";
            next if grep +($questEdges[$y1][$x1][($dir1+$_)%8] or $questEdges[$y][$x][($dir+$_)%8]), 1, -1
              or $dblCoordEdges[$y+$y1][$x+$x1] > 1 or $midLong->{$x+$x1,$y+$y1};
            # Check nearby double-edges
            my(@e2, $e2);
            for my $D (1,-1) {
              push @e2, scalar grep $midLong->{$x+$x1+$D*$dx[($dir+$_)%8],$y+$y1+$D*$dy[($dir+$_)%8]}, -1, 1;
              $e2 += $e2[-1];
            }
#		  $marked++ if $e2;
            if (0 and $e2) {					# DOES NOT APPEAR (at least with 2-2 type only)
              for my $Pt ([$x1,$y1,0],[$x,$y,1]) {		# The far end
                next unless $e2[$Pt->[2]] and $cnt->[$Pt->[1]][$Pt->[0]] > 4;
                my $blobs = !$cntedge->[$Pt->[1]][$Pt->[0]] + ($cntBlobby[$Pt->[1]][$Pt->[0]] || 0); # may step outside???
#		      $marked++ unless $blobs < 2;
              }
            }
            my $compete;
            for my $D (-1, 1) {
              next unless $outType[$y][$x][($dir+2*$D)%8];
              $compete++ unless $edge->[$y1][$x1][($dir+$D)%8] and not $outCont[$y][$x][($dir+2*$D)%8][1+$D];
            }
            next if $compete;
#		  warn "d->[$y][$x][$dir]" and
            (debug and $rays->[$y1][$x1][$dir1][0] =~ s/^d/ⓓ/),
#		  $marked++;	# if $Opp eq 'd';				# For doubleray, too many (???) false positives now
            push @edgeAdd, [$x,$y,$dir,$x1,$y1]; # unless $Opp eq 'd';	# For doubleray, too many (???) false positives now
          } else {
#		  warn "$Opp [$y][$x][$dir] [$y1][$x1][$dir1]\n";
            $questEdges[$y1][$x1][$dir1]++;
            $questEdges[$y][$x][$dir]++;
            $dblCoordEdges[$y+$y1][$x+$x1]++;	# Mark (doubled) midpoint
            $outType[$y][$x][$dir] = $Opp;
            $outCont[$y][$x][$dir][1+$_] = $edge->[$y1][$x1][($dir-$_)%8] for 1, -1;
          }
        }
      }
    }
  }
  add_edge($_, $edge, $cntedge, $lastedge) for @edgeAdd;
  [$edge, $cntedge, $lastedge, $rays, $longedges, $seenlong, $midLong, $inLong];
}

sub scan_degree_rays ($$$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $rays, $midLong, $offs, $cnt)
    = (shift, shift, shift, shift, shift, shift,              shift, shift, shift);
  my($cntBlobby, $lastBlobby) = ([], []);
  calc_Blobby($height, $width, $cntedge, $offs, $cntBlobby, $lastBlobby);
  my(@todoDegree,%candDegree);
  for my $y (1..$height) {	# Detect candidates °c °f °d
    for my $x ( 1..$width ) {
      next unless my $RAYS = $rays->[$y][$x];
      next unless @$RAYS;
      for my $dir (@{$offs->[$y][$x]}) {
        if ($RAYS->[$dir][0] =~ /^°/) {		# '°'
          my $x1 = $x + $dx[$dir];
          my $y1 = $y + $dy[$dir];
          my($dir1, @rot) = ($dir+4)%8;
          my $goodNearLong = sub ($$$$$$) {	# returns false if the edge is a bad candidate
            my($x,$y,$dir,$rot,$x1,$y1)=(shift,shift,shift,shift,shift,shift);
            my $x2 = $x1 + $dx[($dir+$rot)%8];
            my $y2 = $y1 + $dy[($dir+$rot)%8];
            my $r = $rays->[$y2][$x2][($dir+4)%8];
            return 1 unless $r and $r->[0] =~ /^[4x2]/;		# longEdge is going in the inspected direction
            return 1 unless grep $edge->[$y2][$x2][($dir+$rot*$_)%8], -1..2;	# XXX Is this needed??? Good way out of long
            return 1 if 1 == ($cntedge->[$y1][$x1] || 0) and grep $edge->[$y1][$x1][($dir-$rot*$_)%8], 0, 1, 2;	# Good way out
            return;
          };
          my(@cont, $Opp);
          my $goodCont = sub ($$$$$$) {	# returns ROTATION if the edge has a good continuation, undef/empty otherwise
            my($x,$y,$dir,$x1,$y1,$dir1)=(shift,shift,shift,shift,shift,shift);
            return @rot && $rot[0] if
              @rot = grep $edge->[$y] [$x] [($dir1+$_)%8], 0,-1, 1		# has a way out (doing exactly 1 is worse)
              or @rot = grep $midLong->{2*$x+$dx[$dir1]+$dx[($dir1+$_)%8],2*$y+$dy[$dir1]+$dy[($dir1+$_)%8]}, -1, 1
                        # not beneficial on diagonal lines:
              or !($dir%2) and (2 == grep $edge->[$y][$x][($dir+$_)%8], -2, 2	# ends on a stroke ⇽ 🉡
                                or !$cntedge->[$y][$x] and 2 == grep $edge->[2*$y-$y1][2*$x-$x1][($dir+$_)%8], -2, 2
                                   and !grep $edge->[2*$y-$y1][2*$x-$x1][($dir+$_)%8], 1, 0, -1
                                   and push @cont, [$x,$y,$dir1,2*$x-$x1,2*$y-$y1]); # a stroke at dist=1
            if (!$cntedge->[$y][$x] and 1 == ($cntBlobby->[$y][$x] || 0)) {{	# ⾘ XXXX but easier???
              my $D = $lastBlobby->[$y][$x];
              last unless @rot = (grep $D == ($dir1 + $_)%8, -1, 0, 1);
              my $x2 = $x + $dx[$D];
              my $y2 = $y + $dy[$D];
              # Not beneficial on 𐃶; CONT is not beneficial on ⪵.  Do not CONT if $midLong???
              push @cont, [$x,$y,$D,$x2,$y2] and return $rot[0]
                if 1 == ($cntBlobby->[$y2][$x2] || 0) and (!$midLong->{$x+$x2,$y+$y2}	# we will be “connected” to Pt2 anyway
                                                         or $cnt->[$y2][$x2] == 3);	# Apparently, always true with midLong!
            }}
            return undef;
          };
          my $goodConts = sub () {	# returns ROTATION if the edge has a good continuation, undef/empty otherwise
            my($x,$y,$dir,$x1,$y1,$dir1) = ($x,$y,$dir,$x1,$y1,$dir1);
            my(@out, $rot) = ($goodCont->($x,$y,$dir,$x1,$y1,$dir1), $goodCont->($x1,$y1,$dir1,$x,$y,$dir));
            return @out unless 1 == (($rot, my $junk) = grep defined, @out) and $rot;	# 1 way out found, not straight
            # Now try to punch through at slope 2 or ½ at the other end.
            my($try) = grep !$out[$_], 0, 1;		# Have exactly one defined; it is not 0
            ($x,$y,$dir,$x1,$y1,$dir1) = ($x1,$y1,$dir1,$x,$y,$dir) unless $out[0];
            my $D = ($dir+$rot)%8;
            my $x2 = $x1 + $dx[$D];
            my $y2 = $y1 + $dy[$D];
#	          warn "($x,$y,$dir,$x1,$y1,$dir1) $out[0],$out[1]: $x2,$y2,$D [$edge->[$y2][$x2][$dir],$edge->[$y2][$x2][($dir+4)%8]]";
            push @cont, [$x1,$y1,$D,$x2,$y2] and $out[$try] = $rot if ($edge->[$y2][$x2] and $edge->[$y2][$x2][$dir]
                    and not grep $edge->[$y2][$x2][($dir+$_)%8], 4);	# Having 3,5 here is not beneficial.
            @out
          };				# Below: °e is not beneficial, °C does not appear
#warn "$x,$y,$dir  ($edge->[$y] [$x] [($dir+$_)%8], ";
          next unless not $edge->[$y][$x][$dir] and $rays->[$y1][$x1][$dir1][0] =~ /^([cdfF])/	# doubleray (fake-)curve Fork
#       		  and not ((grep $edge->[$y] [$x] [($dir1+$_)%8], -1, 0, 1		# has a way out (doing exactly 1 is worse)
#       		  	    or grep $midLong{2*$x+$dx[$dir1]+$dx[($dir1+$_)%8],2*$y+$dy[$dir1]+$dy[($dir1+$_)%8]}, -1, 1)
#       		  and (grep $edge->[$y1][$x1][($dir+$_)%8],  -1, 0, 1
#       		  	    or grep $midLong{2*$x1+$dx[$dir]+$dx[($dir+$_)%8],2*$y1+$dy[$dir]+$dy[($dir+$_)%8]}, -1, 1))
#       		  and 2 == grep defined, (@out = $goodConts->(\$cont,\$cont1))
            and $Opp = $1
            and not grep $edge->[$y] [$x] [($dir+$_)%8], -1, 1		# no nearby edges
            and not grep $edge->[$y1][$x1][($dir1+$_)%8],  -1, 1		# XXX Չ ڼ
#		and (warn("10 $x,$y,$dir  (2+!$cntedge->[$y1][$x1] > $cntBlobby->[$y][$x])"),1)
            and 2 + !$cntedge->[$y1][$x1] > ($cntBlobby->[$y][$x] || 0)	# not near blobs (Not beneficial at all).
#		and (warn("20 $x,$y,$dir  (2+!$cntedge->[$y][$x] > $cntBlobby->[$y1][$x1])"),1)
            and 2 + !$cntedge->[$y][$x] > ($cntBlobby->[$y1][$x1] || 0)	#   (not counting the other side of this edge!)
#		and (warn("30 $x,$y,$dir"),1)
            and not grep $rays->[$y][$x][($dir+$_)%8] && (($rays->[$y][$x][($dir+$_)%8][0] || '') =~ /^[4x2]/) # not near long edges
                          && !$goodNearLong->($x,$y,$dir,$_,$x1,$y1), -1, 1 # 4fork does not appear
#		and (warn("40 $x,$y,$dir"),1)
            and not grep $rays->[$y1][$x1][($dir1+$_)%8] && (($rays->[$y1][$x1][($dir1+$_)%8][0] || '') =~ /^[4x2]/)
                          && !$goodNearLong->($x1,$y1,$dir1,$_,$x,$y), -1, 1; # 2fork3 xFork (!3fork2!!!)
#		and (warn("50 $x,$y,$dir"),1);
          my @out = $goodConts->();
          push @todoDegree, [$x,$y,$dir,$x1,$y1,$dir1,$Opp,@out,@cont];
          $candDegree{$x,$y,$dir} = $candDegree{$x1,$y1,$dir1} = $Opp;
  }}}}
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet ($#todoDegree [@{$todoDegree[0]||[]}] [@{$todoDegree[1]||[]}] [@{$todoDegree[2]||[]}])");
  for my $cand (@todoDegree) {	# °f-candidates are not good as continuations; some candidates which work as continuation would not be revived
    my($x,$y,$dir,$x1,$y1,$dir1,$Opp,$out,$out1,@cont,$c) = @$cand;	# below: 3: U+10054 (OK); 2: 𝔉 (not OK)
    $out++  if not defined $out  and $c = grep 'f' ne ($candDegree{$x,$y,($dir1+$_)%8} || 'f'), -1, 0, 1  and $c != 2;
    $out1++ if not defined $out1 and $c = grep 'f' ne ($candDegree{$x1,$y1,($dir+$_)%8} || 'f'), -1, 0, 1 and $c != 2;
    next unless defined $out and defined $out1;
#	  $marked++;
    $edge->[$_->[1]][$_->[0]][$_->[2]] or add_edge($_, $edge, $cntedge, $lastedge) for [$x,$y,$dir,$x1,$y1], @cont;
#	  warn "($x,$y,$dir,$x1,$y1,$dir1,$Opp)";
  }
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet ($#todoDegree [@{$todoDegree[0]||[]}] [@{$todoDegree[1]||[]}] [@{$todoDegree[2]||[]}])");
  [$edge, $cntedge, $lastedge];
}

sub nnn3_do_Simple_and_edges ($$$$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $longedges, $seenlong, $midLong, $inLong, $cnt)
    = (shift, shift, shift, shift, shift, shift,          shift, shift, shift, shift);
  for my $e (@$longedges) {	# De-longedge if there is a loners nearby.  Probably, it would be better to do earlier;
    next if not ref $e and $e eq 'erased';		# however, this would break tuneups which historically came first.
    my($x, $y, $x1,$y1, $offset, $dir, $rot) = @$e;
    my $dir0 = ($dir+$rot)%8;
    my @atBEG = grep $edge->[$y][$x][$_],         $dir, $dir0;
    my @atEND = grep $edge->[$y1][$x1][($_+4)%8], $dir, $dir0;
#          next unless @atBEG or @atEND;
    my @add;	# Had a longedge since couldn’t choose 1 of 2 ways around a rhombus; looks like something made a preference…
    if (not (@atBEG or @atEND)) {	# Check for loner singletons on one side
      my @DIR = grep 3 == $cnt->[$y+$dy[$_]][$x+$dx[$_]], $dir, $dir0;
      next unless 1 == @DIR;
      my($dx,$dy) = ($dx[$DIR[0]],$dy[$DIR[0]]);
#            $marked++;
#            next;
      @add = ([$x, $y, $DIR[0], $x + $dx, $y + $dy], [$x1, $y1, ($dir + $dir0 - $DIR[0] + 4)%8, $x + $dx, $y + $dy]);
    }
    add_edge($_, $edge, $cntedge, $lastedge) for @add;
    clear_longedge([$x, $y, $x1, $y1, $offset], $longedges, $seenlong, $midLong, $inLong);
  }
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet");
  [$edge, $cntedge, $lastedge, $longedges, $seenlong, $midLong, $inLong];
}

sub nnn4_do_Simple_and_edges ($$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $rays, $offs, $cnt)
    = (shift, shift, shift, shift, shift, shift,         shift, shift);
  my(@edgeAdd, $tailEdge);
  for my $y (0..$#$edge) {			# Force the edges near tips
    next unless $edge->[$y];
    for my $x ( 0..$#{ $edge->[$y] } ) {
      for my $dir ( 0..$#{ $edge->[$y][$x] } ) {
        next unless $edge->[$y][$x][$dir] and $rays->[$y][$x][$dir][0] eq 'Tail';	# don't include in the end/nextEdge, special-case later
        my $X = $x + $dx[$dir];
        my $Y = $y + $dy[$dir];
        my $DIR = ($dir+4)%8;
        next unless $rays->[$Y][$X][$DIR][0] eq 'MFork';
        # next if grep !$edge->[$y][$x][($dir+$_)%8], 3,5;				# A branch of a fork may be non-recognized
        $tailEdge->{$x,$y} = [$x, $y, $dir, my $rot = $rays->[$Y][$X][$DIR][1]];			
#            next unless $edge->[$y][$x] and $tailEdge->{$x,$y};
#            warn "tail @($x,$y)";
#            my $dir = $tailEdge->{$x,$y}[2];
        next unless $cnt->[$y][$x] == 3 and $cntedge->[$y][$x] < 3;
#              warn "tail \@($x,$y,$dir)";
        my @bends;
        for my $d (grep $_ != $dir, @{$offs->[$y][$x]}) {
          next if # $edge->[$y][$x][$d] or
                  ($cntedge->[$y+$dy[$d]][$x+$dx[$d]] || 0) != 1 + !!$edge->[$y][$x][$d];
          my ($l) = $edge->[$y][$x][$d] ? grep((($_-$d+4)%8 and $edge->[$y+$dy[$d]][$x+$dx[$d]][$_]), 0..7)
                                    : ($lastedge->[$y+$dy[$d]][$x+$dx[$d]] || 0);
          my $b = ($l - $d + 4)%8 - 4;
#                warn "tail \@($x,$y,$dir): $d, $b";
          next if 1 < abs $b;
          my $d0 = ($d - $dir)%8 - 4;
          next if $b and grep $edge->[$y+$dy[$d]+$dy[$l]][$x+$dx[$d]+$dx[$l]][($l + $_*$d0)%8], 1, 2; # ཹ ᰑ ᶒ 1D06C 𝁬  11184 𑆄;  but: 㨓
          push @bends, [$d, $b, $d0*$b, $d0];
#                warn "bends: ($d0,$b) \@($x,$y,$dir)";
        }
        if ( @bends == 2 and 2 == grep $_->[3], @bends and 1 == (my @O = grep $_->[2] == 1, @bends)
             and !grep $_->[2] == -1, @bends ) {		# connect the two continuations; ¤ µ; not good: ᰑ ᶒ 㨓 11184 𑆄
          my $d = $O[0][0];
          my $D = ($d + $O[0][1] + 4)%8;
          push @edgeAdd, [$x+$dx[$d], $y+$dy[$d], $D, $x+$dx[$d]+$dx[$D], $y+$dy[$d]+$dy[$D]];
#                $marked++;
        } else {						# extend extendable
          for my $B (@bends) {
            my $d = $B->[0];
            push @edgeAdd, [$x, $y, $d, $x+$dx[$d], $y+$dy[$d]] unless $edge->[$y][$x][$d];
          }
        }
      }
    }
  }
  add_edge($_, $edge, $cntedge, $lastedge) for @edgeAdd;
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet");
  [$edge, $cntedge, $lastedge, $tailEdge];
}

sub nnn5_do_Simple_and_edges ($$$$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $rays, $offs, $inLong, $cnt, $near)
    = (   shift, shift, shift, shift, shift, shift,          shift, shift, shift, shift);
# warn "... reached ($#$near)";
  my($cntBlobby, $lastBlobby, @edgeAdd) = ([], []);
  calc_Blobby($height, $width, $cntedge, $offs, $cntBlobby, $lastBlobby);	# In fact, seems like may use the older version???
  for my $y (1..$height) {	# Last round of: Identify singletons with a valid way out (one d in a group of d,e,f,K)
    for my $x ( 1..$width ) {
      next unless $cnt->[$y][$x]				# If already have two edges, do not try to find complicated...
        and ($cntedge->[$y][$x] || 0) <= 1 and !$inLong->{$x,$y};
#            next if not $Simple[$y][$x] and $cntedge->[$y][$x];
# warn "... reached ($x,$y) c=$cnt->[$y][$x] cB=", $cntBlobby->[$y][$x];
      next if $cnt->[$y][$x] + ($cntBlobby->[$y][$x] || 0) > 6;	# Give up if too many neighbors (count bad neighbors as 2)
      # Before, we assumed that at most one edge is present
      my $L = $cntedge->[$y][$x] ? $lastedge->[$y][$x] : 100;	# Connect only as a curve continuation, and only if it continues back
      next if 1 + ($L!=100) > (my @Neighbors = @{$offs->[$y][$x]});
#            next if grep $_ == ($L-1)%8, @Neighbors;
      @Neighbors = grep $rays->[$y][$x][$_][0] !~ /^([i¢₡])/, @Neighbors;	# , warn "($x,$y,$L)" ignore, ¢urve, ₡urve
      push @Neighbors, shift @Neighbors while $Neighbors[-1] == ($Neighbors[0] + 7)%8; # Rotate to start of a run
      my $e = 0;
      $e++ while $e < $#Neighbors and $Neighbors[$e+1] == ($Neighbors[$e] + 1)%8;
#            warn "($x,$y) $e [@Neighbors] <$cntedge->[$y][$x]>";
      my $premark;
# warn "... reached";
      if (!$cntedge->[$y][$x]) {
# warn "... reached e=$e #N=$#Neighbors ($x,$y)";
         next unless $e == $#Neighbors and $e == 2 and not grep !$cntedge->[$y+$dy[$_]][$x+$dx[$_]], @Neighbors;
# warn "... reached e=$e #N=$#Neighbors";
      } else {
        my $e1 = $e++;
        $e++ while $e < $#Neighbors and $Neighbors[$e+1] == ($Neighbors[$e] + 1)%8;	# find second run
        next unless $e == $#Neighbors;			# Now: have exactly 2 groups
        if (grep $_ == $L, @Neighbors[0..$e1]) {
          splice @Neighbors, 0, $e1 + 1;
        } else {
          splice @Neighbors, $e1 + 1, @Neighbors - $e1 - 1;
        }							# Now only the non-entry group remains
        next if @Neighbors > 3
          or grep !$cntedge->[$y+$dy[$_]][$x+$dx[$_]], @Neighbors 	# See ֍
             and (@Neighbors > 1 or grep $near->[$y+$dy[$Neighbors[0]]][$x+$dx[$Neighbors[0]]][($Neighbors[0]+$_)%8], 2,3,-2,-3);
#              $premark++ if @Neighbors == 1 and grep !$cntedge->[$y+$dy[$_]][$x+$dx[$_]], @Neighbors;
      }
# warn "... reached";
#	    $marked++ if grep $rays->[$y][$x][$_][0] =~ /^([i¢₡])/, @Neighbors;	# , warn "($x,$y,$L)"	ignore, ¢urve, ₡urve
      my @cont = grep $edge->[$y+$dy[$_]][$x+$dx[$_]][$_], @Neighbors;
      my $mid = $Neighbors[int(@Neighbors/2)];
#                warn("    ($x,$y,$L): <@cont> <@Neighbors>");
      if (@cont >= 2) {					# Use only if 2-neighbors are in this 45° sector
        next if @cont > 2 or @Neighbors > 2 or grep $cnt->[$y+$dy[$_]][$x+$dx[$_]] > 4, @Neighbors
                  or $L < 8 and grep 1 < abs(($L-$_)%8 - 4), @cont;
        # next if !$cntedge->[$y][$x];
      } elsif (@cont) {					# Use only if perp to a stroke, or continues incoming
# warn "... reached";
        if (@Neighbors == 3) {				# The only case compatible with no-incoming-edge
          next if $mid%2 or grep !$edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2;	# Now: we are next to a stroke
          next unless $mid == $cont[0] and ($L > 7 or 2 > abs(($L-$cont[0])%8 - 4)) or ($cont[0] + 4)%8 == $L;
        } elsif (@Neighbors == 2) {		# Use only if extends incoming, or is close, and incoming can't go straight
          my $ang = abs(($cont[0] - $L)%8 - 4);
          next if $ang and ($ang > 1 or $near->[$y][$x][($L+4)%8]);	# “Being close” is not beneficial for ƈ ۜ 
#              } elsif (@Neighbors == 1 and $mid%2) {			# OK, just use @cont
#                next unless grep !$edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2;	# ֍ but not ą
        } elsif (@Neighbors == 1) {			# OK, just use @cont
           next if $L < 8 and 1 < abs(($L-$cont[0])%8 - 4);
        }
      } else {
# warn "... reached";
        if (@Neighbors == 3) {				# The only case compatible with no-incoming-edge
# warn "... reached";
          next if $mid%2 or grep !$edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2;	# Now: we are next to a stroke
          @cont = ($L > 7 ? $mid : grep $_ == ($L+4)%8, @Neighbors);
          # next unless $mid == $cont[0] or ($cont[0] + 4)%8 == $L;
        } elsif (@Neighbors == 2) {			# Use only if extends incoming
# warn "... reached";
          @cont = grep $_ == ($L+4)%8, @Neighbors;
          # next unless ($cont[0] + 4)%8 == $L;
        } elsif (@Neighbors == 1) {
# warn "... reached";
          if ($mid%2) {			# ֍ but not ą; what about γ, צ???
# warn "... reached";
            my @NN    = grep $_ != ($mid+4)%8, @{$offs->[$y+$dy[$mid]][$x+$dx[$mid]]};
            my @ed = grep $near->[$y+$dy[$mid]][$x+$dx[$mid]][$_], map +($mid + $_)%8, 2, -2;
            next if grep !$edge->[$y+$dy[$mid]][$x+$dx[$mid]][$_], @ed;	# The present perpendicular directions must be edges
#                  $marked++ if @ed and ($L > 7 or abs(($L-$mid)%8 - 4) < 2);
# warn "... reached ($#$near,$#{$near->[$y+$dy[$mid]]}) near0=[@$near] near1=[@{$near->[$y+$dy[$mid]]}], x=", $x+$dx[$mid], ", y=", $y+$dy[$mid];
# warn "... reached NN=[@NN] mid=$mid  ed=(@ed) L=$L CNT=$cnt->[$y][$x] near=[@{$near->[$y+$dy[$mid]][$x+$dx[$mid]]}]";
            next if grep abs(($_+4-$mid)%8 - 4) > 1, @NN
                          and not (@ed and ($L > 7 or abs(($L-$mid)%8 - 4) < 2) and $cnt->[$y][$x] < 3);
# warn "... reached";
          } else {
# warn "... reached";
#		  $marked++ if grep $edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2	# Allow one edge (Ԃ) if there is no neighbor in other direction
#		  		and not grep +($near->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8] and not $edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8]), 2, -2;
            next if grep !$edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2
                    and not ( grep $edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2	# Allow one edge (Ԃ) if there is no neighbor in other direction
                              and not grep +($near->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8]
                                             and not $edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8]), 2, -2 );
          }
# warn "... reached";
#                next if ($mid%2) or grep !$edge->[$y+$dy[$mid]][$x+$dx[$mid]][($mid+$_)%8], 2, -2;	# ֍ but not ą
          @cont = @Neighbors if $L < 8 and 2 > abs(($L-$Neighbors[0])%8 - 4);
        }
      }
#            $marked++ if $premark;
#            $marked++
#            , next
#		if @cont and not $Simple[$y][$x] and $cntedge->[$y][$x];
#            next;
#                warn(": ($x,$y,$_,$x+$dx[$_],$y+$dy[$_])"),
      push @edgeAdd, [$x,$y,$_,$x+$dx[$_],$y+$dy[$_]] for @cont;
    }
  }
# warn($edge->[12][3][5] ? "### <$edge->[12][3][5]>" : "###### not yet");	#  ($#todoDegree [@{$todoDegree[0]||[]}] [@{$todoDegree[1]||[]}] [@{$todoDegree[2]||[]}])
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet #=$#edgeAdd [@{$edgeAdd[0]||['N/A']}]");
  add_edge($_, $edge, $cntedge, $lastedge) for @edgeAdd;
# warn($edge->[12][3][5] ? "### <$edge->[12][3][5]>" : "###### not yet");	#  ($#todoDegree [@{$todoDegree[0]||[]}] [@{$todoDegree[1]||[]}] [@{$todoDegree[2]||[]}])
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet");
  [$edge, $cntedge, $lastedge];
}

# How to recognize rasterization of 1px-wide line?
# Going along a line, there are only two types of delta (neighbors, one 
# diagonal, one coordinate). 
# For slopes <= 1/2 diagonal delta cannot come in pairs; for slopes above 1/2 
# horizontal cannot come in pairs.  Hence one gets stretches of one type
# of delta, separated by single deltas of the other type.

# Be more specific: which stretches may appear?  Use continuous fractions!

# May assume slope M >= 1, take intersection of the line with the vertical grid 
# line.  Make a path between two copies of the line shifted +- 1/2 
# horizontally; color squares with centers inside the path.  
# Hence the diagonal-UR delta appears after a square with center (A + .5,B + .5) 
# if y-coordinate of the intersection with x = A+1 is between B+0.5 and B+1.5.

# Hence stretches are determined by closest integers to Mn + b, n in Z.  Hence 
# they are related if M' = +-M + M0 with integer M0.  Hence may reduce to
# 0 < M <= 0.5.  Hence stretches are of (max) 2 lengths (differing by 1);
# one of the lengths appears single, the other comes in groups (2-stretches).

# Which 2-stretches may appear?  Boundaries are determined by when the line
# intersects y = n + 0.5 with n in Z.  Now exchanging x and y and doing M=1/M
# reduces to the previous step.

# How deep one may go on 24x24 grid?  The shortest non-constant stretch is 1,2;
# such 3-stretch gives the shortest 2-stretch 2,1,1; this gives the shortest
# stretch 1,1,2,1,2,1,2 which is -/-/--/-/--/-/-- which is 19-long.  Hence
# 3-stretches may appear...  On the other hand, it may be interpreted as a part
# of 2,1 repeated indefinitely (prepend -); is avoided by prepending /...

#                xxx
#              xx
#           xxx
#         xx
#      xxx
#    xx
#  xx
# x

# This also can take into account that the line may be cut into interval
# somewhere inside a stretch...

# These transformation may also define "the best" b in y=Mx+b.  When we
# reduce to 0 < M <= 0.5 with constant stretches (pattern ----/ repeated),
# the best line passes through middles of /-deltas.

# On the next layer: if 2-stretches are constant (so stretches are n,m with
# m single, and n coming in groups of N), the line passes through the middle
# of m-stretches.


# http://www.sourcecodebrowser.com/autotrace/0.31.1/pxl-outline_8h.html
# http://tug.org/texinfohtml/fontu.html#Limn
# http://stuff.mit.edu/afs/athena/astaff/project/tex/fontutil/fontutils-0.6/limn/fit.c

# ???  After we found "long strokes", remove them, but keep pixels which
# on both vertical (or horizontal; or diag?) sides have "remaining pixels".
# Try to find strokes in remaining+kept pixels...  -- works for "#"

# ??? Try to find long vert/hor strokes by brute force.  Exclude those who
# have too many pixels on neighboring lines.  -- works for "$".
# Considering striked-snakes (such as $): k neighbors for 2k-1 is not "too many"

# Currency ¤ is tricky...  -- too many "extendable" lines.

# Ec   E	3/4	Note that ^ in 4 is genuine one, but v is fake...
#   >  c
#  <  / 
#   xx  
# Ex x  
#   x  *
#   x CC
#  / x f
# c  Lxx
# E    v

# Input encodes a sequence of rectangles made of grid squares; rectangles share UR/LL corners:
#                □	is encoded as 2,4,4,3,1 (all positive)
#             □□□
#         □□□□
#     □□□□
#   □□
# We want to find a line which rasterizes to these squares, i.e., intersect the (“red”) vertical disector of every square.
#
# It is the same as intersecting a (“green”) horizontal line of length=1 centered at the shared corners, 
# plus intersecting the red lines of the leftmost and the rightmost square.  Suppose that non-on-edge rectanles
# are only of two sizes, s and s+1.  Swapping x and y axis, and subtracting y'=y-sx moves the green lines to a
# collection of red lines of a new configuration of rectanges.  This gives a step of recursion.  Above configuration is moved to
#     □□
#    □
#   □
# On this picture, the “old” red lines (“pink”, two at edges) become sloped lines with slope -s, with horizontal projection 1
# (ending on horizontal grid lines, below the center of first square, and below the center of the last square.  

# The right end of the left pink line is below the new-red line of the leftmost new square; hence it is below any fitting
# line.  One must only check that the left end of the left pink line is above the fitting line.  If this left end is on level 
# (or above) the top of the left square, everything is OK.  

# If it is on the level or below the bottom of the left square, then draw a new green line: horizontal line of lenght 1 going right
# from the left end of the pink like.  Obviously, the fitting line intersects the pink line iff it intersects the new green line.

# There are several cases when we may exclude the new green line being below the bottom of the left square:
#    • if all rectangles are actually squares, one could replace s by s+1 above, and have one rectangle instead; exclude this;
#    • if there is one rectangle longer than 2 (or two of length 2) the slope of the fitting line is < 1, so intersection with 
#      such green line is impossible;
#    • If there is one rectangle of length 2, and the rest are squares, the green line may be 1 unit below the bottom (and it
#      is unique; this may be repeated on both ends).

# Only two cases remain: the rectangles consist of 1 square (total), and that with a pink line which may be either forgotten,
# or replaced by an “additional” green line.  (The additional green lines have no associated red lines, so on the NEXT step of induction
# they would give no pink lines.)  

# In the first (“trivial”) case, the preceding step is of two rectangles with no added green lines.

# So induction step:  We start with n rectangles with k≤2 added green lines; coordinate change gives rectangles of total length 
# n-1+k with 2-k pink lines.  A pink line is either forgotten, or impossible, or gives a unique solution, or is convertible to
# a green line.  So either we exclude a configuration, or find a unique solution or a trivial case, or get rectangles with n-1+k 
# squares and ≤2-k added green lines.  The only cases when the number of squares did not decrease is:
#    All rectangles at start are squares except one of length 2; we had 2 added green lines.
# But then on the next step we have no added green lines, so the next step is the trivial one.

# (To avoid the trivial step [which is tricky] we ensure that we call recursively, there are at least two squares.
#  This means at least two green intervals on the previous stage.)
# Provided that this case is handled in the caller, the additional green lines appear when the length of the start/end rectangle
# is s+1; if it is above s+1, this is an impossible situation.

# In particular, every case is reduced to a “unique solution” one, or the “trivial” one.  The last one is equivalent to
# having 3 equidistant paralle lines with an an interval [AB] on the middle one (the preimage [AB] of the last red line), and
# opposite to each other rays XA' and YB' on the other two lines.  The fitting line must intersect all 3 of them. 
# Oone of ray may be the whole line).  It is easy to see that this is equivalent to the line intersecting intervals [XA], [AB] 
# and [BY].  If the quadrilateral XAYB is not convex, it may be decreased (so that X,A,B,Y are 3 vertices of a △, and a point
# on a side.  If it is convex, then intersecting [AB] is a corollary of other two.  ???

# Possibly unknown squares: the 2nd and 3rd row “share” a x-coordinate; assume that intersecting a red line in any of them is OK.
#                □	This is equivalent to having the red line of double length, which is equivalent to
#             □□□		the green line of double length at this position (assuming it is not at edge).
#         □□□□		Hence this allows the induction step as well.
#     □□□□□		(Encode ignoring the extra square at second line, with second line marked as: $extended->{1}=1.)
#   □□

# Returns empty or a,b,db of the line y=ax+b-db which rasterizes to the rectangles of widths @$CC (connected UR ↔ LL corners);
# The other two arguments as as above.  LL corner of the leftmost of bottom squares is at 0,0.
sub encodes_line ($;$$$);		# Refused degenerated cases when there is a unique solution — with choices in rasterization
sub encodes_line ($;$$$) { 		# %$extended should not have negative keys
  my ($CC, $green_at_left, $green_at_right, $extended) = (shift, shift, shift, shift||{}); # Every elt encodes delta between cells
  # A horrible mess of special-cases before we can recognize "runs", and flip axes...
#  warn "Got: [@$CC], $green_at_left, $green_at_right";
  # Banal case: one rectangle
  return 0, 1/2 if 1 >= @$CC and not ($green_at_left or $green_at_right);		# No greens at all; one rectangle
  my(@jumps, $left_red, $right_red, %seen) = @$CC;	# jumps between greens
  if ($green_at_left) { $left_red = $CC->[0] - 1 }
  else { shift @jumps }
  if ($green_at_right) { $right_red = $CC->[-1] - 1 }
  else { pop @jumps }
  # Need to exclude a trivial case
  unless (@jumps) {					# Only one green
    if ($green_at_left or $green_at_right) {		# Maximize some metric (∑distances to mid-red points)
      	my $sl = 3/(4*$CC->[0] - 1);			#    ==> intersects right at height ≈¾.
      	return ($green_at_left ? ($sl, $sl/4) : ($sl, 1/4 - $sl/2)) # Cut the green interval in the same proportion
    } else {						# Two rectangles; likewise: if ratio of lengths is t≤1, use ¾(1+t²)/(1+t³)
      my $addHalf = 0;
      if ($extended->{0} and $CC->[0] < $CC->[1] - 1) {
        $CC = [$CC->[0] + 1, $CC->[1] - 1];
      } elsif ($extended->{0} and $CC->[0] == $CC->[1] - 1) {
        $addHalf = 1;
      }
      if ($CC->[0] + $addHalf == $CC->[1]) {	# Go through the center of symmetry, with intersection of edge red lines as above:
        my $sl = 3/(4*$CC->[0] + 2*$addHalf - 2);
        return($sl, 1/4 - $sl/2);
      } elsif ($CC->[0] < $CC->[1]) {		# One strategy is to continue periodically, then make a best fit; this joints
        # midpoints of rectangles.  If differ by one, this breaks the green line 1:3 (with 1 on the side of longer rectangle).
        #    On the other hand, to avoid close-to pathological rasterizations, we should divide the green line in the middle!
        # The best derasterization of 1+2 cuts the red lines at heights ¾,¼,¾ (the last ¾ makes it also good-in-L²-norm).
        #    (It is also better since there are two ways to treat it: one can consider the main direction to be horizontal,
        #     or to be diagonal.  This “best” approximation is the same in these two approaches.)
        my $t = $CC->[0] / ($CC->[1] - 1);		# Break green as 1:3, but use the slope as above with t-correction
        my $sl = 3*(1+$t*$t)/(1+$t*$t*$t)/(4*$CC->[1] - 2);
        return($sl, 1 - $sl*$CC->[0]);
      } else {				# Likewise
        my $t = $CC->[1] / ($CC->[0] - 1); # If differ by 1, the distances to red lines are ¼, ¾, ⁵⁄₄,... exactly as ½,3/3 for equal lengths
        my $sl = 3*(1+$t*$t)/(1+$t*$t*$t)/(4*$CC->[0] - 2);
        return($sl, 1 - $sl*$CC->[0]);
      }
    }
  }
  # Up to this moment, always successfully return; below, unsuccessful returns indented (the only successful is the last one):
  my %jump_pre_ext = map { ($_ + !!$green_at_left, $extended->{$_}) } keys %$extended;	# shift keys of extended to be pre-jump
  my $tot_jumps = 0;
  $tot_jumps += $_ for @jumps;
  my($slope_min, $slope_max) = (($tot_jumps - !!$jump_pre_ext{0})/@jumps, ($tot_jumps + !!$jump_pre_ext{@jumps})/@jumps);
  if (int($slope_min) != int $slope_max) {	# differ by ≤1 unless @jumps = 1
    # There is a chance that after shear transformation with slope = int $slope_max, we have both increasing and decreasing paths.
    # But then there is also a horizontal path (yes!); choose it.
    my($H, @ok) = (0, (1) x (1+!!$jump_pre_ext{0}));	# Cur min-height; OK-Height of horizontal line (now = before the jump № 0)
    for my $j (0..$#jumps) {
      $H += ( $jumps[$j] - int $slope_max );
      my $add = $jump_pre_ext{$j + 1};
      @ok = grep { $H <= $_ and $H + !!$add >= $_ } @ok or
        return;
    }
    die "Bug: need to fix the constant term for the shear transform";	# XXX ???  And axes flip! Check start/end segments too!
    my $tot = (grep $_, @ok) || 0;	#  □□□□□□□□□□□□□		Example.  (after shear transform)
    return int $slope_max, $tot/@ok;	#  □□□□  □   □□□		@ok = 1, $tot = 1
  } elsif (%$extended) {    #  In general: may always look for non-decreasing path (after flip+shear).
    # Find rightmost consecutive run on each row (of those joining to the preceeding row)
    my($H, @cur) = (0, (1) x (1+!!$jump_pre_ext{0}));	# Cur min-height; OK-Height of horizontal line (now = before the jump № 0)
    my(@starts) = ((0) x (1+!!$jump_pre_ext{0}));
    for my $j (0..$#jumps) {
      $H += ( $jumps[$j] - int $slope_max );
      my $add = !!$jump_pre_ext{$j + 1};
      # if one of cur is above $H + $add, remove the run at this height
      return if $cur[0] > $H + $add;
      pop @starts, pop @cur if $#cur and $cur[1] > $H + $add;
      @cur = grep { $H <= $_ and $H + $add >= $_ } @cur or
        return;
    }
  }
  my($U,$D,@jU,@jD,%seenU,%seenD) = (0,0);	# jumps, seen: modifiable up/down
  $#jU = $#jD = @jumps + 5;			# Make small negative indices access unreachable elts
  $extended->[$_] and $jD[$_ + !!$green_at_left]++ and $jU[$_ + !!$green_at_left - 1]++ for keys %$extended;	# may access -1
  for my $n (0..$#jumps) {
    $seen {$jumps[$n]}++;
    $seenU{$jumps[$n]}++ if $jU[$n];
    $seenD{$jumps[$n]}++ if $jD[$n];
  }
  $seen{$_}++ for @jumps;
#  warn("many keys\n"), 
    return if 2 + !!$U + !!$D < keys %seen;	# There should be at most 2 different jumps (after correction UP/DOWN)
  my @JUMPS = sort {$a <=> $b} keys %seen;
#  print("jumps=@JUMPS\n"), 
  my($min, $max) = @JUMPS[0,-1];
#  warn("jumps=@JUMPS\n"), 
    return if @JUMPS > 1 and $max - $min > 1 + !!$U + !!$D;	# If two different jumps, must differ by 1
  my($min_can_U, $max_can_D) = ($seen{$min} == ($seenU{$min} || 0), $seen{$max} == ($seenD{$max} || 0));
  if ($min_can_U) {	# Cannot correct if two mins are adjacent
    $min_can_U = 0 if grep { $jumps[$_] == $min and $jumps[$_+1] == $min } 0..($#jumps-1);
  }	# min and max cannot conflict!
  if ($max_can_D) {	# Cannot correct if two mins are adjacent
    $max_can_D = 0 if grep { $jumps[$_] == $max and $jumps[$_+1] == $max } 0..($#jumps-1);
  }
#  warn("edge too long, jumps=@JUMPS\n"), 
    return if not $green_at_left  and (my $l_O = $CC->[0]  - $min - 1) > 0  # left end too long (with $green_at_left already done)
      or      not $green_at_right and (my $r_O = $CC->[-1] - $min - 1) > 0; # right end too long
  # Now may do the induction step (the trivial case @JUMPS == 1 and $min = 1 is already excluded)
  my @rect = 1;
  for my $j (@jumps) {
    $rect[-1]++, next if $j == $min;
    push @rect, 1;
  }			# Found new rectangles
    return unless my($sl, $sh) = encodes_line \@rect, (!$green_at_left and !$l_O), (!$green_at_right and !$r_O);
#  print "sub-slant=$sl <-- (@rect), ", (!$green_at_left and !$l_O), ", ", (!$green_at_right and !$r_O), "\n";
  $sh += $sl*0.5;	# Recalc so that the origin is at bottom of the leftmost new-red (=old-green) line
  $sl += $min;		# Undo the shear transformation; now we are in x-y-exchanged coordinate system; origin = bot. of 1st green
  # If we had green_at_left, the first of old green intervals is (in x-y-exchanged coordinate system) vertical, centered at (0,0)
  # Otherwise it was centered at (1,$CC->[0])
  my($X,$Y) = ($green_at_left ? (0,0) : (1, $CC->[0]));
  $Y -= 0.5;
  $sh += $Y - $X*$sl;	# Now $sh is w.r.t. the unshifed x-y-exchanged coordinate system
  return (1/$sl, -$sh/$sl);	# Finally, exchange the axes back
}

sub stroke_2_line ($) {
  my($s, %seen, %dup) = shift;		# $s->[$i][0] is dir∈(0..7);
  my @d = map $_->[0], @$s;
  $seen{$_}++ for @d;
  2 >= (my @D = keys %seen) or return;
  if (@D == 1) {
    my($dx,$dy) = ($dx[$d[0]], $dy[$d[0]]);
    return [0,0, @d * $dx, @d * $dy, 0,0, 2*$D[0]];	# move-beg, vector, move-end, 2*dir
  }					# now @D == 2;
  $d[$_-1] == $d[$_] and $dup{$d[$_]}++ for 1..$#d;
# warn "@d --> dup ", join(' ', %dup), "\n";
  1 >= (my @DD = keys %dup) or return;
  my $dup = @DD ? $DD[0] : $d[$d[0] % 2];	# if @DD is empty, two dirs alternate; assume that the odd one is a separator; ==>
  my $dir = $D[0] + $D[1];
  my $sep = $dir - $dup;		# directional-independence — there is no guarantie that y=x-y preserves the best fit
  $dir += 8 if $dir == 7 and !($D[0] * $D[1]);
  # Do not “optimize” horizontal/vertical lines of len>2 with one diag stroke at the end (excluding tips):
  if ($sep % 2 and $seen{$sep} and $seen{$sep} <= 2 and @d > 2 and $seen{$sep} == (my @eSEP = grep $d[$_] == $sep, 0, -1)) {
    @eSEP = grep !$s->[$_][5], @eSEP;
    return if @eSEP <= 1;
  }
#  return if $sep % 2 and $seen{$sep} == 1 and @d > 2 and grep $_ == $sep, @d[0,-1];
  my($i,$col,@col) = (0,1);
  while ($i < @d) {
    if ($d[$i] == $sep) {
      push @col, $col;
      $col = 1;
    } else {
      $col++;
    }
    $i++;
  }
  push @col, $col;
# warn "Scan of col: @col\n";
  my($slope, $offset) = encodes_line \@col or return;
  $offset -= 0.5 - $slope*0.5;			# Recalc offset to be w.r.t. the center of the first square
#### warn "slope=$slope; offset=$offset of @col; dup=$dup, sep=$sep [in = @d]\n";
  # “Reflection” below moves squares on diagonal to a horizontal sequence of squares; it preserves the square centered at (½,½)
  # Offsets w.r.t. this center are inverted
  ($dup, $sep, $slope, $offset) = ($sep, $dup, 1-$slope, -$offset) if $dup % 2; # goes more diagonally than horizontally/vertically
  # Now $dup is horizontal/vertical, and $sep is diagonal
  my($dx,$dy)   = ($dx[$dup],     $dy[$dup]);
  my($dx1,$dy1) = ($dx[$sep]-$dx, $dy[$sep]-$dy);	# “orthogonal” direction
  my $C = grep $_ == $sep, @d;				# Naive move in “orthogonal” direction
  my $lineC = @d * $slope + $offset;
  my $end_off = $lineC - $C;
  return [$dx1 * $offset, $dy1 * $offset, @d * $dx + $lineC * $dx1, @d * $dy + $lineC * $dy1,	# vectors of start_offset, end_coord,
	  $dx1 * $end_off, $dy1 * $end_off, $dir];						# end_off
}

# Break a “smooth” stroke into convex parts, straight lines, and snakes-not-convertable-to-straight-lines
sub stroke_subdivide ($) {	# We suppose it is known that this is not suitable for calculated lines, but rotates at most by ±1
  my ($edges, $last_snake, $last_r, @runs, @turns, @t_pos, @parts) = (shift, -1, 0, 1);	# @runs starts with the first REAL elt, 1
  $turns[0] = $t_pos[0] = 0;	# Turns are at VERTICES, so they are shifted w.r.t. edges by -½: this 0 means -½ w.r.t. edge nuns
  for my $i (1..$#$edges) {
    next unless my $r = ($edges->[$i][0] - $edges->[$i-1][0])%8;	# One of 0, 1, 7
    $last_r ||= $r;
    push @turns, $r;		# 135° corners:	direction
    push @t_pos, $i;		# same:		ordinal of edge which is after the turn
    next if $r == $last_r;
    push @runs, $#turns;	# Which corner starts a new convex sequence of corners (including sequences of length=1 in snakes!)
    $last_r = $r;
  }	# a run is in turns, from $runs[$j] inclusive to $runs[$j+1] exclusive; has the same direction of turns
  push(@turns, 0); push(@t_pos, scalar @$edges);	# These are not REAL, and not included in @runs due to end-exclusion
  push @runs, $#turns;	# runs are turns between consecutive elts of @runs, begin-inclusive, end-exclusive (REAL elts only!)
  for my $j (1..$#runs) {
    if ($runs[$j] - $runs[$j-1] > 1) {	# a convex run: ≥2 corners, so cannot be a part of a snake
      $parts[-1][1][1] = $runs[$j-2] if $parts[-1] and $parts[-1][1];	# previous part is a snake (unterminated yet); terminate
      push @parts, [[$runs[$j-1], $runs[$j]-1]];	# parts are both-ends-inclusive
    } elsif (++$last_snake != $j) {		# start of a new snake (ends are dealed with on hext non-snake)
      push @parts, [undef, [$runs[$j-1]]];	# Which turn starts a new snake; the termination slot is bogus so far
      $last_snake = $j;
    }
  }
#  $snakes[-1][1] = @turns if $finish_snake;
  $parts[-1][1][1] = $#turns - 1 if $parts[-1][1];	# parts are both-ends-inclusive; include the last REAL element
#my @T = map { $t_pos[$_] . ($turns[$_] > 6 ? '-' : ($turns[$_] ? '+' : '')) } 0..$#turns;
#warn "turns=(@T), runs=(@runs), snake-parts ", (map 0+!!$_->[1], @parts), 
#       ", lines (turn#) ", (map {"$_->[1][0]..$_->[1][1], "} grep $_->[1], @parts),
#       ", lines (edge) ",  (map {($t_pos[$_->[1][0]]-1)."..$t_pos[$_->[1][1]], "} grep $_->[1], @parts), "\n";
  my @parts_edges;
#  @parts_edges = map [$t_pos[$_->[-1][0]] - 1, $t_pos[$_->[-1][0]]], @parts;	# start: edge before corner
  for my $part (@parts) {
    if ($part->[0]) {
      my $mid = $part->[0][1] != $#t_pos;		# Avoid accessing out-of-bound value (will be overwritten later anyway)
      push @parts_edges, [ $t_pos[$part->[0][0] - 1], $t_pos[$part->[0][1] + $mid] - $mid ];	# both sides inclusive
    } else {
      push @parts_edges, [ $t_pos[$part->[1][0]] - 1, $t_pos[$part->[1][1]] ];	# overlaps by 1 the neighbors
    }
  }
#  for my $i (0..$#parts) {
#    my $part = $parts[$i];
#    if ($part->[0]) {
#      my $b = $t_pos[$part->[0][0] - !!$i];
#      my $mid = $i != $#parts;
#      my $e = $t_pos[$part->[0][1] + $mid] - $mid;
#      push @parts_edges, [ $b, $e ];	# both sides inclusive
#    } else {
#      push @parts_edges, [ $t_pos[$part->[1][0]] - 1, $t_pos[$part->[1][1]] ];	# overlaps by 1 the neighbors
#    }
#  }
#warn "predivide 0..$#$edges: ", join(' ', map $_->[0], @$edges), " => ", (map "$_->[0]...$_->[1]" . (!!$_->[2] && ':L') . " ", @parts_edges), "\n";
  # The logic above breaks for first/last segments:
  $parts_edges[0][0]  = 0	 ;#if $parts[0][1];  # incorporate the full preceding segment into the snake,
  $parts_edges[-1][1] = $#$edges ;#if $parts[-1][1]; # and not just one edge of it
#warn "predivide 0..$#$edges: ", join(' ', map $_->[0], @$edges), " => ", (map "$parts_edges[$_]->[0]...$parts_edges[$_]->[1]" . (!!$parts[$_]->[1] && ':S') . " ", 0..$#parts_edges), "\n";
#warn "parts_edges=$#parts_edges, edges=$#$edges; @ -1:  b: $parts_edges[-1][0];   e: $parts_edges[-1][1]\n";
#warn "parts_edges=$#parts_edges, edges=$#$edges; @  2:  b: $parts_edges[2][0];   e: $parts_edges[2][1]\n" if $#parts_edges==2;
  my($J, $donext, @out) = (0, 1);	# up to $J-1 are written to @out
  #
  # We split the sequence of directions into snakes and convex parts.  (May be overlapping where they join.)
  # Currently, we use this info in a very rudimentary way: we try to convert a snake to a line (with the overlap edge, or not);
  # if cannot, we join the "unrecognized" parts together.
  #
  for my $j (0..$#parts) {			# Linearize (sub)snakes; remove overlap between snakes and ???
    next unless $donext++;			# May skip the convex part after an unrecognized snake
    my $part = $parts[$j];
#warn "    fixing... j=$j"; # part=<@$part>";
#warn("  $J <-- $j"), 
    $out[$J++] = $parts_edges[$j], next unless my $snake = $part->[1];	# convex: at start, or after convex/recognized-line
    my($b,$e) = @{ $parts_edges[$j] };
    my @S = @$edges[$b..$e];			# Try first extension by 1 on both sides
    my($line) = stroke_2_line \@S;
#warn "to line: #$j (end: parts=$#parts, parts_edges=$#parts_edges, edges=$#$edges;  b: $b;   e: $e;   OK: ", 0+!!$line,"\n";
##warn "parts_edges=$#parts_edges, edges=$#$edges; @  2:  b: $parts_edges[2][0];   e: $parts_edges[2][1]\n" if $#parts_edges==2 and $j==2;
    if ($line) {
#warn "  longline: j=$j J=$J\n";
       $parts_edges[$j][2] = $line;
       $J and $parts_edges[$J-1][1]--;	# A convex run contains at least 3 edges, so we will not annihilate it completely
       $j == $#parts or $parts_edges[$j+1][0]++;
       $out[$J++] = $parts_edges[$j]; 
       next
    }		# Now last resort: try to shorten to min possible; since stroke_2_line() failed, we know that @S is long enough…
    my($b1, $e1) = ($b + 1, $e - 1);
    $b1 = $b unless $b;
    $e1 = $e if $e == $#$edges;		# Does not make sense to shorten the snake at start/end of the stroke
    @out = @parts_edges, next if $b == $b1 and $e == $e1;		# stroke is a wholesale snake
    @S = @$edges[$b1..$e1];			# Now try shortened by 1 on both sides
    unless (($line) = stroke_2_line \@S) { 
#warn "  no-short-line: j=$j J=$J  end->", ($j || 1 ? '' : '(omitted)' ), $parts_edges[$j + ($j!=$#parts)][1], "\n";
      $out[$J++] = $parts_edges[$j] unless $J;	# create a previous part, if none
      $donext = 0; 
      $out[$J-1][1] = $parts_edges[$j + ($j!=$#parts)][1]; # Extend the preceding part
      next;
    }
#warn "shortened: #$j;  b: $b --> $b1;   e: $e -> $e1\n";
#warn "  short-line: j=$j J=$J\n";
    if ($b == $b1) {
      $J and $parts_edges[$J-1][1]--;
    } else {
      $parts_edges[$j][0]++
    }
    if ($e == $e1) {
      $j == $#parts or $parts_edges[$j+1][0]++;
    } else {
      $parts_edges[$j][1]--
    }
    $parts_edges[$j][2] = $line;
    $out[$J++] = $parts_edges[$j]; 
  }
  @out;
}

sub crosses_line ($$;$$) {	# segL = [stX,stY,eX,eY,del_eX, del_eY]; segL = [stX,stY,eX,eY]  eq = (X-stX)*(eY-stY) - (Y-stY)*(eX-stX)
  my($seg,$segL,$opp, $expand, $endEq, $stEq) = (shift,shift,shift,shift||0);	# del_eX, del_eY is in the same coordinate system as segL; the rest is shifted
  my($stX,$stY,$eX,$eY,$DeX,$DeY) = @$segL;
#  warn "opp=",!!$opp,"\tseg=[@$seg], line=($stX,$stY,$eX,$eY,$DeX,$DeY)";
  my $dF = ($seg->[0] - $seg->[2])*($eY-$stY) - ($seg->[1] - $seg->[3])*($eX-$stX);
  if ($opp) {
    $stEq = ($seg->[0] - $DeX)*($eY-$stY) - ($seg->[1] - $DeY)*($eX-$stX);	# [0,1] is w.r.t. logical end
    $endEq = $stEq - $dF;
  } else {
    $endEq = ($seg->[4] - $stX)*($eY-$stY) - ($seg->[5] - $stY)*($eX-$stX);	# [4,5] is w.r.t. start
    $stEq = $endEq + $dF;
  }
#  warn("st=$stEq end=$endEq"),
  return unless $endEq*$stEq < 0;
  my $frac = $endEq/($endEq - $stEq);
  $frac = 1 - $frac if $opp;
  my $new = $frac*(1+$expand);
  $new = ($frac + 1)/2 if $new > ($frac + 1)/2;		# Do not expand pathologically
  $frac = $new;
  $frac = 1 - $frac if $opp;
  my $out = [($seg->[0]*$frac + $seg->[2]*(1-$frac)), ($seg->[1]*$frac + $seg->[3]*(1-$frac))]; # in coordinates of seg
#  warn "Out=[@$out] st=$stEq end=$endEq";
  $out
}

sub stroke_2_strokes ($$$) {
  # The 1st version should not be applied to smooth closed loops: we assume that 0 is a corner
  my($s, $calc_hash, $closed) = (shift, shift, shift);			# $s->[$i][0] is dir (0..7);
  my @d = map $_->[0], @$s;
# warn "stroke: @d\n";						# start is before the segment with dir = $dir[start]
  my($prev_corner, @corners, @calc) = (0, [0]);	# corners, at index: 0=start; optional: 1=calc_line, 2=start_moved, 3=end_moved
  for my $i (0..$#d) {	# Between $corners[-1] (inclusive) and $prev_corner (exclusive) there is a region without calculated segments
    if ($i == $#d or abs(($d[$i+1] - $d[$i])%8 - 4) <= 2) {		# found a corner at $i+1  (max+1 is AT_END)
      my(@SS, @parts) = @$s[$prev_corner..$i];
      if (@SS <= 1) {
        @parts = [$prev_corner, $i];
      } elsif (2 == @SS) {			# Do not convert to a line — most of the time is not beneficial
        @parts = ([$prev_corner, $i - 1], [$i - 1, $i]);
      } elsif (my($Line) = stroke_2_line \@SS) {
        @parts = [$prev_corner, $i, $Line];
      } else { 
        @parts = stroke_subdivide(\@SS);
#warn "subdivide 0..$#SS: ", join(' ', map $_->[0], @SS), " => ", (map "$_->[0]...$_->[1]" . (!!$_->[2] && ':L') . " ", @parts), " [$s->[0][1], $s->[0][2]] --> [$s->[-1][3], $s->[-1][4]]\n";
	$_->[0] += $prev_corner, $_->[1] += $prev_corner for @parts;
#        @parts = [$prev_corner, $i];
##        $prev_corner = $i+1; 
##        next;	# Not found
      }				# Invariant: between corners, has either 1-edge segments, or a calculated line
      for my $part (@parts) {	# Invariant: $prev_corner >= $corners[-1][0] (this is a candidate for the next corner)
#warn "  prev=$prev_corner line=<@{$part->[2] || []}> part[1]=$part->[1] last=$corners[-1][0]";
        $prev_corner = $part->[1] + 1, next unless my $line = $part->[2];
        # Now we found a calculated segment (at least 2 edges)
        push @corners, [$prev_corner] if $prev_corner != $corners[-1][0];		# create a new unrecognized chunk
        @{$corners[-1]}[1,2,3] = ($line, !($line->[0] == 0 and $line->[1] == 0), !($line->[4] == 0 and $line->[5] == 0));
        push @corners, [$prev_corner = $part->[1]+1];	# start new segment
        next if $part->[0] == $part->[1];
        for my $S (@$s[$part->[0]..$part->[1]]) {
          $calc_hash->{$S->[1],$S->[2]}{$S->[0]}++;	# x,y,d
          my $d1 = ($S->[0] + 4)%8;
          $calc_hash->{$S->[3],$S->[4]}{$d1}++;		# x1,y1,d1
        }
      }
    }
  }
  push @corners, [$#d+1] unless $corners[-1][0] == $#d+1;		# end last segment
  # Fixing involves inserting new segments (making new corners); to avoid changing indices, do it back to front:
  for my $i (reverse(0..$#corners-1)) {		# Try to fix misplaced joints (currently, only on unrecognized/calculated joins
# warn "doing segment=$i; [", (join ', ', map +(ref() ? "[@$_]" : "$_"), @{$corners[$i]}), "]\n";
    unless (0 and $corners[$i][1]) {
      my $move_start = (($i or $closed) and $corners[$i-1][3]) && [@{$corners[$i-1][1]}[4,5]];
      my $move_end   =			    $corners[$i+1][2]  && [@{$corners[$i+1][1]}[0,1]];
#warn "Fixing segment=$i: start=$move_start end=$move_end\n";
      if ($corners[$i][1]) {	# Move start on straight-line segments, and move start and end on runs of 1-edge segments
        # No need to move start on the first segment if either (A) non-closed curve, or (B) last run is made of 1-edge segments.
        next unless ($i or $closed) and $corners[$i-1][1];	# If previous is a run of 1-edge segments, it would be fixed there
        my $my_move_start = $corners[$i][2] ? [@{$corners[$i][1]}[0,1]] : [0,0];
        $move_start ||= [0,0];
        next unless grep $move_start->[$_] != $my_move_start->[$_], 0, 1;  # Just an optimization; the code below is more robust
        # Segments intersect iff ends of each one are on opposite sides of the line of other one.
        my $cross_prev = crosses_line($corners[$i-1][1], $corners[$i][1], !'opp', $extend_tip) or next;
        my $cross_our  = crosses_line($corners[$i][1], $corners[$i-1][1], 'opp',  $extend_tip) or next;
#        warn "Fixing... prev=[@$cross_prev] (@{$corners[$i-1][1]}[2,3]) our=[@$cross_our] (@{$corners[$i][1]}[0,1])";
        #  Try one: just cut off at the intersection
        my @prev;
        $prev[$_] = ($corners[$i-1][1][4+$_] += $cross_prev->[$_] - $corners[$i-1][1][2+$_]) for 0, 1;
        $corners[$i-1][1][2+$_] = $cross_prev->[$_] for 0, 1;
        $corners[$i][1][$_] = $cross_our->[$_] for 0, 1;
        $corners[$i-1][3] = 0;				# No longer have a mismatch
        $corners[$i][2] = 0;				# No longer have a mismatch
        my @targ = map +($move_start->[$_] + $my_move_start->[$_])/2, 0, 1;
        my($r,$r1) = map $corners[$i-$_][1][6], 0, 1;
        $r1 = ($r1 + 8)%16;
        my $rot = ($r + $r1  + 16*(abs($r - $r1) >= 8))%32;
        splice @corners, $i, 0, [$corners[$i][0], [@prev, @targ, @targ, ($rot + 16)%32/2, 1]],
        			[$corners[$i][0], [@targ, @$cross_our, @$cross_our, $rot/2, 1]];
#        $marked++;
        next;
      }
      next unless $move_start or $move_end;
#warn "Fixing segment=$i: start=$move_start end=$move_end\n";
      my $len = $corners[$i+1][0] - $corners[$i][0];
      my @do = (($move_start ? 0 : ()), ($move_end ? $len-1 : ()));
      $#do = 0 if @do == 2 and not $do[1];	# len = 1
      my $kill = (@do == $len);
      for my $seg (reverse @do) {		# reverse: as above
        my $start = ($move_start and not $seg) ? $move_start : [0,0];
        my $end = ($move_end and $seg == $len-1) ? $move_end : [0,0];        
        my $dir = $d[$corners[$i][0] + $seg];				# direction before correction (1 after 2*$dir means approx)
    warn "i=$i, seg=$seg d=<@d> #d=$#d corners[$i]=<@{$corners[$i]}> #corners=$#corners\n\tcorners=<",
		join('> <', map "@$_", @corners), '>' unless defined $dir;
        my $line = [$start->[0], $start->[1], $end->[0] + $dx[$dir], $end->[1] + $dy[$dir], $end->[0], $end->[1], 2*$dir, 1];
        if ($seg) {
          $corners[$i+1][2] = 0;		# No longer have a mismatch
          splice @corners, $i+1, 0, [$corners[$i+1][0] - 1, $line]; 		# with no mismatches
        } else {
          my $pos = $corners[$i][0];
          $corners[$i][0]++, splice @corners, $i, 0, [] unless $kill;
          @{$corners[$i]} = ($pos, $line);
          $corners[$i-1][3] = 0 if $i;			# No longer have a mismatch
          $corners[$i+1][2] = 0 if $corners[$i+1];	# No longer have a mismatch
        }
# warn "Fixed segment=$i: start=[@$move_start] end=[@$move_end]\n" if $move_start and $move_end;
      }
    }
  }
  for my $i (reverse(0..$#corners-1)) {
#    warn "doing segment=$i; [", (join ', ', map +(ref() ? "[@$_]" : "$_"), @{$corners[$i]}), "]\n";
  }
  my @breaks = 0;			# Meaning: $corner[$break] starts a new sub-stroke
  for my $i (0..$#corners-2) {		# check for mismatch at end
    push @breaks, $i+1 if $corners[$i][3] or $corners[$i+1][2];
  }
  \@corners, \@breaks, \@calc;
}

sub traverse_boundary($$$$$) {	# The blob is on our right
  my ($x, $y, $dir, $blob, $nextEdge, $c) = (shift, shift, shift, shift, shift, 1);
#  warn "Enter traverse_boundary()\n";
  while (1) {			# Greedy algorithm: we always go left if we can  
# warn "... x=$x, y=$y, d=$dir\n";
    my $dir1 = ($dir - 2) %8;
    my $dx = $dx[$dir];
    my $dy = $dy[$dir];
    my $dx1 = $dx[$dir1];
    my $dy1 = $dy[$dir1];
    my($x1, $y1) = ($x+$dx+$dx1, $y+$dy+$dy1);
    if ($blob->[$y1][$x1]) {			# Turn Left (already precalculated)
    } elsif ($blob->[$y + $dy][$x + $dx]) {	# Continue
      $x1 = $x + $dx;  $y1 = $y + $dy;  $dir1 = $dir;
    } else {					# Turn Right
      ($x1, $y1, $dir1) = ($x, $y, ($dir + 2) % 8);
    }
    $nextEdge->[$dir][$y][$x] = [$x1, $y1, $dir1];
    ($x, $y, $dir) = ($x1, $y1, $dir1);
    return $c if $nextEdge->[$dir][$y][$x];
    $c++;
  }
}

sub _traverse_boundary($$$$$) {	# The blob is on our right
  my ($x, $y, $dir, $blob, $nextEdge, $p, $dirOffset) = (shift, shift, shift, shift, shift, [], []);
#  warn "Enter _traverse_boundary()\n";
  return if $nextEdge->[$dir][$y][$x];
  while (1) {			# Greedy algorithm: we always go left if we can, and only in even directions
# warn "... x=$x, y=$y, d=$dir\n";
    my $dir1 = ($dir - 2) %8;	# $dir - 2 points where there is NO blob
    my $dx = $dx[$dir];
    my $dy = $dy[$dir];
    my $dx1 = $dx[$dir1];
    my $dy1 = $dy[$dir1];
    my($x1, $y1) = ($x+$dx+$dx1, $y+$dy+$dy1);	# diagonal directin
    push @$dirOffset, $dir;
    if ($blob->[$y1][$x1]) {			# Turn Left (already precalculated)
      push @$p, [($dir-1)%8,$x,$y,$x1,$y1,$dirOffset];
      $dirOffset = [];
    } elsif ($blob->[$y + $dy][$x + $dx]) {	# Continue
      $x1 = $x + $dx;  $y1 = $y + $dy;  $dir1 = $dir;
      push @$p, [$dir,$x,$y,$x1,$y1,$dirOffset];
      $dirOffset = [];
    } else {					# Turn Right (In place!)
      ($x1, $y1, $dir1) = ($x, $y, ($dir + 2) % 8);
    }
    $nextEdge->[$dir][$y][$x] = [$x1, $y1, $dir1];
    ($x, $y, $dir) = ($x1, $y1, $dir1);

#    push(@$p, [$dir,$x,$y,$x1,$y1]),
#  warn( '[', join('], [', map "@$_", @$p), ']'),
    if ($nextEdge->[$dir][$y][$x]) {
      unshift @{ $p->[-1][5] }, @$p if @$p;
      push @$p, [undef, $x,$y] unless @$p;	# Singleton
      return $p;
    }
  }
}

# start, end, and the encountered MForks are marked as already visited (into $traversedEdges)
sub traverse_stroke ($$$$$$$;$) {		# XXX Is there a duplication between seen/traversed???
  my($x,$y,$dir,$seenEndEdge,$nextEdge,$traversedEdges,$tips,$endstip) = (shift, shift, shift, shift, shift, shift, shift, shift);
  my($X,$Y) = ($x,$y);
  my @stroke;
  while (1) {
    my $x1 = $x + $dx[$dir];
    my $y1 = $y + $dy[$dir];
    last if $traversedEdges->{$x,$y,$dir}++ and not ($x1==$X and $y1==$Y);	# applicable to loops: looped back (but not to tip)
    $traversedEdges->{$x1,$y1,($dir+4)%8}++;
    push @stroke, [$dir,$x,$y,$x1,$y1];
    $seenEndEdge->{$x1,$y1,($dir+4)%8}++, last unless defined(my $n = $nextEdge->[$y][$x][$dir]);
#warn "found next edge: $x,$y $dir  --> $x1,$y1 +$n\n";
    if (my $tip = $tips->{$x1,$y1}) {
      $tip = $tip->[2];
#      last if $tip == ($dir+4)%8;			# When splitting a loop, happens on the 1st step (but we removed this tip!)
      my $x2 = $x1 + $dx[$tip];
      my $y2 = $y1 + $dy[$tip];
      push @stroke, [$tip,$x1,$y1,$x2,$y2,'tip'];
      push @stroke, [($tip+4)%8,$x2,$y2,$x1,$y1,'tip'];      
      warn "doing tip from ($x1,$y1): dir=$tip, from_dir=$dir, next_dir=", ($dir + $n) % 8, "\n"
        if debug > 4;
      $traversedEdges->{$x1,$y1,$tip}++;		# Protect from code which finds closed loops
      $traversedEdges->{$x2,$y2,($tip+4)%8}++;		# Protect from code which finds closed loops
    }
    ($x,$y,$dir) = ($x1, $y1, ($dir + $n) % 8);
#    last if $seenEndEdge->{$x,$y,$dir};		# applicable to loops: looped back
  }
  warn "found edges in a stroke: ", scalar @stroke, ': (', join(') (', "@{$stroke[0]}[1,2]", map "@$_[3,4]", @stroke), ")\n"
    if debug > 4;
  $stroke[$_][5] = 'tip' for $endstip ? (0, -1) : ();
  \@stroke;
}

sub nnn6_do_Simple_and_edges ($$$$$$$$$$$$$) {
  my($width, $height, $edge, $cntedge,,$lastedge, $rays, $offs, $longedges, $blob, $pixels, $skipExtraBlob, $tailEdge, $coarse_blobs)
    = (shift, shift, shift, shift, shift, shift,              shift, shift, shift, shift, shift, shift, shift);
  my(@nextEdge, @endEdge, %edges, %seenEndEdge, @strokes, %traversedEdges);
  for my $y (0..$#$edge) {	# Effectively, “move” the position of the joint along the spur in MFork/Tail pairs from MFork to Tail
    next unless $edge->[$y];	# But only when there are exactly 3 edges (at Tail vertex, which is the branching point)
    for my $x ( 0..$#{ $edge->[$y] } ) {
      next unless $edge->[$y][$x] and my $t = $tailEdge->{$x,$y};
      my($dir, $rot) = @$t[2,3];
      next unless 3 == $cntedge->[$y][$x];						# was: ¤
      my @d = map +($dir+$_)%8, ($rot == 1) + 3, 5 - ($rot == -1);
      for my $branch (0, 1) {
        my $D = $d[$branch];
        my $x1 = $x + $dx[$D];
        my $y1 = $y + $dy[$D];						# special-case transversal of 2 edges leading into the branch point
        $nextEdge[$y1][$x1][($D+4)%8] = ($d[1-$branch] - $D - 4)%8;	# would special-case transversal of the spur later
      }
    }
  }
  for my $y (0..$#$edge) {	# For every directed-edge, find the next directed-edge.  If none, mark the opposite as end-edge.
    next unless $edge->[$y];			# Except for spurs of the MFork (special-cased later).
    for my $x ( 0..$#{ $edge->[$y] } ) {
      next unless $edge->[$y][$x]; 
      for my $dir ( 0..$#{ $edge->[$y][$x] } ) {
        next unless $edge->[$y][$x][$dir];
        $edges{$x,$y,$dir} = [$x,$y,$dir];
        my $x1 = $x + $dx[$dir];
        my $y1 = $y + $dy[$dir];
        if ($cntedge->[$y1][$x1] == 2) {
          my @o;
          push @o, $_ for grep $edge->[$y1][$x1][$_], 0..7;
          my @oo = grep $_ != -4, map {($_- $dir + 4) % 8 - 4} @o;	# find the other edge (is not it easier to find the sum???)
#warn "found dirs [@o] at ($x,$y) --> $x1 $y1 $dir --> rot=$oo[0]\n";
          $nextEdge[$y][$x][$dir] = $oo[0];
        } elsif ($tailEdge->{$x,$y}) {	# MFork, Tail; don't include in the end/nextEdge, special-case later
#	      } elsif ($rays[$y][$x][$dir][0] =~ /^([MT])/) {	# MFork, Tail; don't include in the end/nextEdge, special-case later
        } elsif ($tailEdge->{$x1,$y1}) {	# Do not start at tail attachment; $nextEdge already set
        } else {
          push(@endEdge, [$x1,$y1,($dir+4)%8]);	# Do not try to drive through junctions
        }
      }
    }
  }
#warn "found endEdges: ", scalar @endEdge, "\n";
  my(@calc, %inCalcEdge);
  for my $edge (@endEdge) {		# Find non-closed strokes (those having end-edge)
    my($x,$y,$dir) = @$edge;
    next if $seenEndEdge{$x,$y,$dir}++;
# warn "endEdge: $x,$y, $dir, $cntedge->[$y][$x].\n";
    my $stroke = traverse_stroke($x,$y,$dir,\%seenEndEdge,\@nextEdge,\%traversedEdges, $tailEdge);	# made of [$dir,$x,$y,$x1,$y1]
    my $closed = $stroke->[0][1] == $stroke->[-1][3] && $stroke->[0][2] == $stroke->[-1][4];
    if ($closed) {
      $closed = -2;			# -2 means smooth, 2 means has a corner.  Presume smooth (but with a junction)
      for my $i (0..$#$stroke) {
        $closed = 2, last unless abs(($stroke->[$i][0] - $stroke->[$i-1][0] + 4)%8 - 4) < 2; # At i=0, wraps back to the end
      }
    }
#	  $closed &&= -2 if abs(($stroke->[0][1] - $stroke->[-1][1] + 4)%8 - 4) < 2;
    my($breaks, $runs) = [0];
    if ($closed < 0) {		# loop known to be smooth; stroke_2_strokes() won't find anything except ends
      $runs = [[0],[$#$stroke+1]];		# fake corners at ends; [0] means: start at 0, no calculated lines until the next
    } else {
      ($runs, $breaks) = stroke_2_strokes($stroke, \%inCalcEdge, $closed);	# Meaning: $runs->[$break] starts a new sub-stroke
    }
    push @strokes, [$closed, !'blob', $stroke, $runs, $breaks];	# (strokes with endpoints: “open”)
  }
# warn "found open strokes: ", scalar @strokes, "\n";
  my(@closedStrokes, %edgesDone);
  my @E;
  for my $E (sort keys %$tailEdge) {	# Best place to cut a closed stroke — if present.
    my $edge = $tailEdge->{$E};		# Need to normalize order, since bugs in fontforge are sensitive to the order
    my($x,$y,$dir,$rot) = @$edge;
    my $D = ($dir+4)%8;
    my $x1 = $x + $dx[$dir];
    my $y1 = $y + $dy[$dir];				# the encountered MForks are marked as already visited (by traverse_stroke())
    push @E, [$x1,$y1,$D,!!'tip',$x,$y,$E,$rot];	# start with MFork end of the tail
  }							#	 (those already encoutnered are ignored by traverse_stroke() anyway)
  push @E, map [@$_,0], @edges{sort keys %edges};
  for my $e (@E) {				# Handle closed strokes (without end-edge, need to loop through all edges)
    my($x,$y,$dir,$T,$x1,$y1,$E,$rot) = @$e;	#      (Need to normalize order, since bugs in fontforge are sensitive to the order)
    next if $traversedEdges{$x,$y,$dir};
    if ($T) {						# starting at MFork; need to redo the structure of “next” edges; we 
      $nextEdge[$y][$x][$dir] = ($rot == 1 ? 0 : 7);	# 	go clockwise (same direction as blobs), assuming the tip is outside
      my $x2 = $x1 + $dx[($dir+($rot != -1))%8];	# (x,y,d) is tip→joint=(x1,y1); we continue same-dir, or 45° counter-clockw
      my $y2 = $y1 + $dy[($dir+($rot != -1))%8];
      $nextEdge[$y2][$x2][($dir+($rot != -1)+4)%8] = (($rot == -1 ? 0 : 7));	# at end of the loop, return to the tip (DUP???)
      delete $tailEdge->{$E};
    }
    push @closedStrokes, traverse_stroke($x,$y,$dir,\%seenEndEdge,\@nextEdge,\%traversedEdges, $tailEdge, $T);	# of [$dir,$x,$y,$x1,$y1]
    push @{ $closedStrokes[-1] }, !'blob';
  }
  my(@nextEdgeBlob, @entryPointBlob);	# With lastedge, includes ends of lines:
  find_blobs($blob, $width, $height, $pixels, $cntedge, $offs, $lastedge, $skipExtraBlob);
  for my $y (1..$height) {
    my $inner = 0;
    for my $x ( 1..$width ) {
      next unless !$blob->[$y][$x] == $inner;
      my $blobX = $x - $inner;
      $inner = 1 - $inner;
      my $dir = $inner ? 0 : 4;			# $dir - 2 is a direction to exit the blob
      next if $nextEdgeBlob[$dir][$y][$blobX];	# already passed through
      if ($coarse_blobs) {
        push @entryPointBlob, [$blobX, $y, $dir];
        $entryPointBlob[-1][3] = traverse_boundary($blobX, $y, $dir, $blob, \@nextEdgeBlob);
      } else {
        push @closedStrokes, _traverse_boundary($blobX, $y, $dir, $blob, \@nextEdgeBlob);
        push @{ $closedStrokes[-1] }, !!'blob';
      }
    }
  }
  for my $stroke (@closedStrokes) {
    my $is_blob = pop @$stroke;
    push(@strokes, [undef, !!'blob', $stroke, undef, [0]]), next
      if @$stroke == 1 and not defined $stroke->[0][0];
    # Try to restart it on а corner (if present)
    my($i,$corner) = (-1, 2);
    while (++$i <= $#$stroke) {
      my($d,$prevd) = ($stroke->[$i][0], $stroke->[$i-1][0]);	# At i=0, wraps back to the end
      last if abs((($d-$prevd) % 8) - 4) <= 2;			# 135° angle is not a corner
    }
    $i = $corner = 0 if $i > $#$stroke;
    $stroke = [@$stroke[$i..$#$stroke, 0..($i-1)]] if $i;
    my($breaks, $runs) = [0];
    if ($corner == 0) {		# loop known to be smooth; stroke_2_strokes() won't find anything except ends
      $runs = [[0],[$#$stroke+1]];		# fake corners at ends; [0] means: start at 0, no calculated lines until the next
    } else {
      ($runs, $breaks) = stroke_2_strokes($stroke, \%inCalcEdge, 'closed'); # Meaning: $runs->[$break] starts a new sub-stroke
    }
    # if $is_blob, we do not want to break loops; so the first element is reset to 0
    push @strokes, [$corner - 1, $is_blob, $stroke, $runs, $breaks];	# loop: 1 if have corners, -1 if smooth
  }
#	return if $opt{marked} and not ($marked and $marked2);
  for my $e (@$longedges) {	# [$x, $y, $x+$dx+$dx1,$y+$dy+$dy1, $offset, $dir, $rot]
    next if not ref $e and $e eq 'erased';
    push @strokes, [0, !'blob', [[-20, @$e[0..3]]]];		# dir==-20
  }
#warn "found strokes: ", scalar @strokes, "\n";
# warn($edge->[8][7][5] ? "### <$edge->[8][7][5]>" : "###### not yet");
  [\@strokes, \@nextEdgeBlob, \@entryPointBlob, \%inCalcEdge];
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=pod

=encoding utf8

=head1 NAME

Image::Bitmap2Paths - Perl extension to convert line-drawing (and font's) bitmaps to paths (of vector formats).

=head1 SYNOPSIS

  use Image::Bitmap2Paths;
  my $bm = Image::Bitmap2Paths->new( minibitmap => my_uncompress($filecontent) );
  my $strokes = $bm->get('strokes');

  my @BM = map {[map $_ ne '-', split //]} split /\n/, <<EOB;  # At (5,3), (6,4), (7,5)
  ---------
  ---------
  ----x----
  -----x---
  ------x--
  ---------
  EOB

=head1 DESCRIPTION

v0.01 is a very early stage of refactoring a generally useful code
out of the script F<hex_parse.pl> used to generate vector fonts on

  http://ilyaz.org/fonts

Hairlines are converted to the corresponding paths (which are assumed to be
visualized by drawing with an appropriate pen).  The rest is converted to “blobs”
with appropriately calculated boundary paths.

Due to the workflow of postprocessing (drawing of hairlines is done by C<ExpandStroke()>
in C<fontforge>, and its programming interface is not flexible enough to treat different
paths differently), the output boundaries of blobs “go through middles of boundary
pixels” — in the same way as for hairlines.

One should keep in mind that currently the overwhelming amount of work focuses on the
detection of “junctions” — the places where hairlines meet and/or cross each other.
Unfortunately, this meant that so far, almost no resources were left to cover “the sexier”
problem of finding “a beautiful curve” approximating the given rough broken line path.
(On the first stage of their processing, the extracted paths connect centers of pixels.
So far, the only “really nice beautification engine” is one to extract the longish
straight segments out of such “pixellated paths”.  The rest of the paths is converted
 to curves in an extremely naive way now.)

(Contrary to my initial expectations, decyphering the geometry of a junction from its
“pixellated version” turned out to be an unimaginably harder process that what one could
predict.  Fortunately — while the code is convoluted, bulky and ugly — the majority of
the complications has been worked out, and this process is now “almost” flawless — as
far as the testbed of C<unifont>’s glyphs shows.  On the other hand, the details of how
hairlines “enter” into blobs are not fully worked out yet.)

=head1 The structure of the API

One runs the process flow by calling methods C<set()> and C<get()> on the fields,
or providing them as pairs of arguments to the C<new()> method.
(The object $obj of this class is actually a wrapped C<Data::Flow> object $$obj;
one can access it directly correspondingly.)

(Currently, the code contains several hardwired “constants” related to workarounds
for bugs in C<fontforge> — as well as for details of working with C<unifont>’s glyphs.
Eventually, these showd better be separated into “configurable” realm — like all
other field.)

The fields one may set are (these docs are very incomplete now; one may need to inspect
the details how these fields are used in the module, and in
C<output_sfd_char()>/C<output_human_readable()> subrounes in the examples):

=over 10

=item C<bitmap>

(Extended) array of arrays (of length C<width+2>, with the first/last elements false).

The external array of the C<bitmap> should have C<height+2> elements; the first/last one should contain
only false entries, and may be empty.  (Essentially, the whole border of this extended 2D bitmap should be blank.)

=item C<minibitmap>

Likewise, but without blank borders (they will be added when the field 'bitmap' is calculated).

=back

The fields to get are

=over 12

=item C<strokes>

The most important output field.

Array with elements like C<[is_loop, is_blob, [@segments], [@runs], [@breaks]]>, with each C<segment> of the form
C<[dir, x0, y0, x1, y2]> (optionally followed by C<'tip'> if this segment comes from C<Tail/MFork> spur).  Here C<dir> is 
one of 8 compass direction in C<0..7> (with step 45°; see C<offs> below), or is C<-20> for "diagonal of a rhombus" strokes.  The
last two elements (C<runs> and C<breaks>) are optional (and do not appear for stroks of one segment???).  C<is_loop> is negative if
the loop is “smooth”: has no corners with angles sharper than 135° (if a loop has such “sharp corners”, the start and the end of the
loop are at such a corner).

The arrays C<runs> and C<breaks> are artefacts of the current (primitive) algorithm.  The meaning is subject to change.

They contain information about how a stroke is subdivided into “smooth” parts.  Currently, the parts are
either straight segments (currently of length ≥3), or convex runs of “edges”, or non-convex runs which cannot be converted to 
straight segments.  The array C<breaks> gives (???) indices of edges in a stroke which start a new “smooth” substroke (without
angles smaller than 135°).  (It always contains C<0>; even for smooth closed loops.)

=item width height

… Of the minibitmap.  In other words, 2 less than for bitmap.

=item C<Lb Rb>

Left and right bearings.  Offsets in the extended bitmap: last blank column at start; likewise, first at end.

=item C<stageOne>

Combines: C<offs cnt cntmin near nearmin doublerays>.

=item C<offs>

At C<[$y][$x]> contains the list of 8 possible directions (in 0..7, with step 45°) where it has a neighbor.  Directions are
consecutive, 0 decreases $y, 2 is to the right,  (This is clockwise from top if C<y> increases going down.)

=item C<cnt>=C<cntmin>

The length of the corresponding list.

=item C<near>=C<nearmin>

Like off, but an array of length 8 with 1 or 0 at each direction 0..7.

=item C<doublerays>

At C<[$y][$x]>, the count of directions in which a ray goes for length >=2.

=item C<stage10>

Combines: C<rays> C<longedges10> C<seenlong10> C<inLong10> C<midLong10> (done in two long iterations of DO_RAYS + a minor
massage)

=item C<rays>

For each C<[$y][$x][$dir]> which corresponds to a known neighbor, contains the (preliminary) result of the deep inspection of the
narrow sector going “about” the direction $dir.  The result is an array; its 0th element is the string describing “the type” of
this sector.  The rest may contain extra info specific to the type.  (Usually, the 1st element is “rotation”: the main “branch” of
how one should “correct” C<dir> when one goes one step “further inside the sector”.)

(Types are indicated on the 3x-magnified debugging output, near each vertex.)  Dictionary of ray candidates: Dense (>=7 neighbors
at dist 1 or 2); otherwise as below (dot denotes an empty place; d is a dependency: rays there “must be good”).  Below C<*> denotes
the vertex C<($x,$y)>; the lines indicate how a vertex in this position “is connected” to the C<*>.  The direction of the sector
startubg at C<*> is not ambiguous in these pictures:

                        . .        . /   |.              d .                  .               \                          .... ..
  doubleray: *-- curve: *-.  Fork: *d.  ./-  fake-curve: *-.  d/-    rhombus: *d.  tail: --*-  *- ish;  serif --*  notch:.-* ..*
            .|/          .\   |    . \  *.       \         \  *.       d * d  .|\        .|.  /   .|/           |        ./. ./|.
     fork4: *d.  Near-corner: *.         m-joint: ||       elses-ray: *|  /      3fork3: *d.      *d.      Sharp: *---   /.  ..|
            .|\              .d--                 *d                   d d               .|\   .  ..\     \..      \-       \
   Note that dependent is not a neighbor for diagonal elses-ray (and is not unique)            -          .d-     ...\       \
      fork4 and one flavor of fork3 are particular cases of fork!		Corner-curve: *.\ 3fork3: *|    bend-sharp: --*
    Later may put: ignore, Ignore, Tail, 2fork3, Enforced, Arrow/(x-)arrow,     Probable-curve:    *|    Joint???: d*-.
      1Spur, MFork; Rhombus-force, Zh/K-fake-curve is intended to be ½-of-segment                  .|-
      Btail, 4fork, xFork, °.     (Also allow longer shaft on Sharp)                                |.

In these docs, the only dependent type which is mentioned corresponds to opposite-direction pair C<tail>/C<doubleray>; it is
converted to C<Tail>/C<MFork> if C<tail> has C<cnt==3> (as on top of the glyph for “M”).  Likewise for a symmetrized case (as at
bottom of “V”): if it is C<fake-curve>/C<Fork> with C<cnt!=1> and the opposite is C<1Spur>/C<Probable-curve>, or unrecognized
(instead of C<doubleray>); here C<rot=0>.  Here C<Tail> is the spur direction going from the branch point, and C<MFork> is the
direction of the spur going into the branch point.

Essentially, the type C<MFork> indicates that a short spur on a very sharp fork (=the handle) is presumed to be the artifact due to
a very sharp angle on a broken line.  The joint of two (long) joining lines should be actually moved to the end of the spur.  (See
also C<tailEdge>.)

    Do we support such a sharp angle “sideways” to another line???  Can two such guys appear on opposite sides when we “punch a
    curve through” a joint???

  Removal of certain points during ray-detection (between two passes) not explained???

=item C<longedges10>

Lists candidates for edges of length √5 going “in between” our 8 compass directions.  This long edge should not be “made” of two
shorter edges since it is “intersected” by another (long) path.  The list element contain 2 coodinates of the start, 2 of the end,
offset in the list, “the approximate” C<$dir> and C<$rot> ≟ ±1. ???

(This corresponds to the ray type C<2fork3>.  There must be a neighbor in the direction $dir.  These are only candidates: we list
them since we do not know which of two ways “around a 45° rhomus” is preferable; in the following stages the answer may become more
clear, and then such candidates are going be removed from the corresponding updated lists.)

=item C<seenlong10>

Hash with the same elements indexed by C<{$x,$y,$x1,$y1}> I<and> by C<{$x1,$y1,$x,$y}>.

=item C<inLong10>

Hash indexed by C<{$X,$Y}>, true of this point is one of the ends of a longedge.

=item C<midLong10>

Likewise for a (doubled) midpoint of the longedge.

=item C<сtage20>

Combines C<edge20>, C<cntedge20>, C<lastedge20>, C<longedges20>, C<seenlong20>, C<midLong20>, C<inLong20>.

=item C<сtage30>

Combines C<edge30>, C<cntedge30>, C<lastedge30>, C<blobs30>, C<blob30>.

   Miss: skipExtraBlob (30)
	 strokes nextEdgeBlob entryPointBlob (A0) <-- coarse_blobs

=item C<stage40>

Combines C<edge40>, C<cntedge40>, C<lastedge40>.

=item C<tailEdge>

Lists the vertices of the type C<Tail> (i.e., opposite to the type C<MFork>; see L<"rays">).  

A hash with “composite keys” (accessed as C<< $tailEdge->{$x,$y} >>) with values C<[x,y,dir,rot]> describing an oriented edge
going from a “C<Tail> node to a node with “the opposite ray” of type C<MFork> with “rotation” C<rot>.  The value is created by

    [$x, $y, $dir, my $rot = $rays->[$Y][$X][$DIR][1]]	# X,Y,DIR are opposite to x,y,dir

  On the last (???) stage we may delete certain entries in this hash!  Fix???

=over

The list above is very cursory.  The parts written are very cursory.  Blah blah blah.

=head2 EXPORT

None by default.

=head2 CAVEATS

Due to inept imperfect incomplete refactoring, the handlers may edit the fields, and may expect that the changes are going to
propagate to the caller.  One (I?!) should not forget to go through this, inspect the code, and introduce new names for edited
duplicates.

  @rays, $cnt, $offs seems to be preserved by stage20

    stage30 etc not even investigated for this yet!!! ???  Force all updates to go through sub calls???

$marked is a placeholder  (The initial intent was that when debugging, one could raise one of these flags seeing a certain
difficulty, and only the output for characters having this problem would be generated.

Since we do not do deep copying of input fields in the filters, some modifications of these arguments may be left unnoticed during
refactoring.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ilya Zakharevich, E<lt>ilyaz@cpan.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
