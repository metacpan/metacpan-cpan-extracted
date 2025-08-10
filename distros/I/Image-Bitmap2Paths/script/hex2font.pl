#!/usr/bin/perl -w
use strict;
use utf8;

my 	($rcs) = (' $Id: hex2font.pl,v 2.2 2025/08/09 23:21:05 vera Exp $ ' =~ /(\d+(\.\d+)+)/);

#warn substr '·', 0, 1;
# TODO:		
#	Redo looking for stars after reducing the maybe-stars - not productive for ideographics
#	Generalize logic of "somebody else's rays" to ignore also parts of curves which pass next to a star (see circled 17).

# Ends: Ees	Joins: *	Corners: L^v><		Curves: cCfF|-\/u
# Rest: x

my %opt = (coarse_blobs => 0, workaround_bug_expand => 1);
#warn "ARGV = <@ARGV>";
$opt{$1} = (defined($3) ? $3 : 1), shift while ($ARGV[0] || '') =~ /^--(\w+)(=(.*))?$/s;	#;
#$opt{mono} = 0 if $opt{nolayouts};		# But the name will be as if --nolayouts was not given
my $nostroke_rex = $opt{nostroke_rex} && qr/^($opt{nostroke_rex})$/i;
print "$rcs\n" and exit if exists $opt{version};
print(int($rcs*1000+0.5)."\n") and exit if exists $opt{iversion};
die "No version of original font specified" if $opt{sfd} and not exists $opt{oversion};

my $height = 16;		# Should be a multiple of 4
my @dx = (0,1,1,1,0,-1,-1,-1);	# Start from "up", go clockwise
my @dy = (-1,-1,0,1,1,1,0,-1);	# +-direction is "down"
my $can_convert_to_join = qr/[cCsef]/;	# special-case cCs later...  s appears more or less as a bug
my @onebit;
$onebit[1<<$_] = $_ + 1 for 0..8;
$| = 1;
my $fuzzier_adjacent;		# Hard to debug interaction of nearby stars introduced in 1.43
my $extend_tip = 1/3;		# Crashes of fontforge; see issues #3239 #3240 #3242
my $dejavu_sizes = $opt{DejaVu};
my($marked2, $marked) = 1;
$opt{marked} ||= 1 if $opt{marked2};

open my $fea, '>>', 'comb-fea' or die "Cannot open comb-fea for write" if $opt{mono} and $opt{nolayouts} and not $opt{nofea};

BEGIN { my $debug = 0;
	$debug++ while @ARGV and $ARGV[0] eq '-d' and shift;
        eval ( $debug ? 'sub dwarn { warn @_, ("@_" =~ /\n$/ ? q() : "\n") }' : 'sub dwarn {1}') ;
        eval "sub debug () { $debug }";
}

sub c_bits8 ($) { my $n = shift; my $o = 0; $n & (1<<$_) and $o++ for 0..7; $o}
my @c_bits = map c_bits8 $_, 0..0xFF;

_test_encodes_line(), exit if $opt{test_calc_line};

my %filter;
if (exists $opt{filterFile}) {
  my $str = do {local $/; open my $f, '<', $opt{'filterFile'} or die "Cannot open filterfile $opt{'filterFile'}"; <$f>};
  $str =~ s/^\x{feff}?##.*//mg;		# Skip comments and BOM
#  warn "<<$str>>";
  $str =~ s/\b([\dA-F]{4,6})\b/chr hex $1/gei;
  my @c = grep /\S/, split //, $str;
  @filter{@c} = (1) x @c;
}

my @rotate = ([0..0xFF],	# In 90deg increments, act on bitmaps of neighbors
	      [map 0xFF & (($_ << 2) | ($_ >> 6)), 0..0xFF]);
for my $i (2, 3) {
  my $prev = $i - 1;
  $rotate[$i] = [map $rotate[1][ $rotate[$prev][$_] ], 0..0xFF];
}

# Precalculate bitmap of neighbors for curves at angles ±1, ±2; assume we are at angle 0
my @neighb_0 = (	# Array of length 5 may be indexed by -2..2
  [],
  [1<<2, 1<<2, 1<<2, (1<<2) + (1<<1)],	# Array of length 4 may be indexed by -1..2
  [(1<<3) x 4],				# The index is the curvature of the curve (2 for undef)
  [(1<<5) x 4],
  [1<<6, (1<<6) + (1<<7), 1<<6, 1<<6]
);
my @neighb_1 = (	# Same assuming we are at angle 1; index is the relative angle
  [],
  [(1<<4) + (1<<3), 1<<4, 1<<4, (1<<4) + (1<<2)],	# Array of length 4 may be indexed by -1..2
  0,
  0,
  [(1<<6) + (1<<7), (1<<6) + (1<<0), 1<<6, 1<<6]
);

my($E, $ER, $ord) = ([], ['']);
END {die '$E corrupted: ' . "<@$E>" if $E and @$E}
my $ALLGOOD = [(1) x 8];
my $ALLcnt = 69671;	# Std .hex of Unifont for planes 0, 1, e contains this many (+.undef) non-fake entries
print STDERR "# (progressBar valid for full UniFont planes 0, 1, e)\n", '.' x int($ALLcnt/1000), "\r"; # print on 1000th, 2000th etc

sub sfd_start ($$);
my($px_size, $px_descent, $eps_px_size) = (64, 2, 1);
print sfd_start(16*$px_size, $px_descent*$px_size) if $opt{sfd};
my $charcnt = 0;
END {
  print << "END" if $opt{sfd};

EndChars
EndSplineFont
END
}

my %override;
if ($opt{overridefile}) {
  open my $f, '<', $opt{overridefile} or die "file `$opt{overridefile}': $!";
  while (<$f>) {
    next if not /\S/ or /^#/;
    die "unknown format of override line: `$_'" unless /^(\S+):([\da-f]+)$/i or /^(\.null):()$/i;
    $override{lc $1} = $2;
  }
  close $f or die "close `$opt{overridefile}': $!";
}

my $filter_rex = (defined $opt{only} ? ($opt{only} eq '.0' ? qr/^[.0]/ :
							     ($opt{only}) =~ /^\w$/ ? qr/^(?:$opt{only})...$/i
										    : qr/^(?:$opt{only})/i) : qr/ /x);
#warn "filter_rex = $filter_rex";
my $skip_rex = ( defined $opt{skip_rex} ? qr/^(?:$opt{skip_rex})/i : qr/(?!)/ );
# warn "skip_rex = ", $skip_rex;

my $width_to_8_ok = $opt{maxwd}||10;

sub need_char ($) {
  my $c = shift;
  return if $opt{'filterFile'} and not $filter{chr hex $c};
  return if $c eq '0000' and $opt{skip0000};	# Does not help with .notdef...
  return if $c =~ /^00[01].$/ and $opt{skipctrl};	# THESE conflict with console's .notdef
  return if $c =~ /^000.$/ and $opt{skipctrl0};	# THESE conflict with console's .notdef
  return if $c =~ /^000[09acd]$/i and $opt{skipctrlwhite};	# it is not THESE which conflict with console...
  return if $c =~ /^000[0-7]$/i and $opt{skipctrl08};	# THESE conflict with console's .notdef
  return if $c =~ /^000[0-3]$/i and $opt{skipctrl04};	# THESE conflict with console's .notdef
  return if $c =~ /^000[0-1]$/i and $opt{skipctrl02};	# THESE conflict with console's .notdef
  return if $opt{skiprex}    and $c =~ /^($opt{skiprex})$/io;	# 000[01] were needed here to have .notdef active in Windows' console (now hidded by .add)
  return if $opt{nocjk}      and $c =~ /^([5-9b-e]|4[ef])/i;
  return if $opt{nocjkPP}    and $c =~ /^([4-9b-e].|3[3-9a-f])..$/i;
  return if $opt{'cjk-all'}  and $c !~ /^([4-9b-e].|3[3-9a-f])..$/i;	# /^([5-9b-e]|4[ef])/i;;
  return if $opt{'cjk-only'} and $c !~ /^([5-9]|4[ef])/i;
  return if $opt{'cjk-rest'} and $c !~ /^[b-e]/i;
#warn "Doing <$c> filter=$filter_rex";
  return unless $c =~ $filter_rex;
#  warn("reject <$c>\n"),
  return if     $c =~ $skip_rex;
#warn "Doing <$c> !";
  return 1;
}

sub output_char_if_narrow ($$) {
  my ($c, $d) = (shift, shift);
  my $width=length($d)*4/$height;		# 4px per hex digit
#	next if $opt{mono} and $width != 8;
  my $s = unpack ("B*", pack ("H*", $d));

  my(@pixels) = ([]);
  my($Lb, $Rb, @rays, @cntmin, @pixelsmin, @nearmin) = ($width, 1, []);
  for my $i (0..($height - 1)) {
          my $l = substr($s, $i*$width, $width);
          # Extra at the end to make offset -1 "work" (=false)
          my $P = $pixels[$i+1] = ['', (map +($_ ? 'x' : ''), split //, $l), ''];
          $pixelsmin[$i+1] = [ @$P ];	# Deep copy
          $P->[$_] and $Lb = $_-1, last for 1..$Lb;
          $P->[$_] and $Rb = $_+1, last for reverse($Rb..$width);
  }		# Rb and Lb are one off from the rightmost and leftmost pixels
  (my $minwidth = $Rb - $Lb - 1) <= $width_to_8_ok
#	  or not $opt{mono} or $c =~ /^([0-2]|3[0-2]|4d[c-f]|a[0-b]|===f[9b-f]|f[b-f]|===f[a-f]|--f[9a-f])/i or next;
    or not $opt{mono} or (not $opt{wideskiprex} or $c !~ /^($opt{wideskiprex})$/io) or return;	# 3[3-9a-f]..|4[0-9a-cef]..|4d[0-9ab].|[5-9]...|a[c-f]..|[b-e]...|f[0-9a]..
  
  push @pixels, [];	# make offset -1 "work" (=false)
#		print "$l\n";
  output_processed_bitmap($c, \@pixels, $width, $height, $Lb, $Rb);
}

my $nobaseline_blocks = <<EOB;		# Do not need alignment on baseline; align on bounding box
Controls				0000..001f
Controls				007f..009f
Devanagari — Myanmar			0900...109f
Arrows 					21d0-21ff
Pieces etc				231c-2321
Pieces, terminal			239b-23bd
extension				23d0-23d0
Control Pictures			2400..243F
Enclosed, Box, Block 			2460-259f
Dingbats				2700..27BF
Arrows+Braille 				27F0..297F
Symb+Arrows				2B00..2BFF
Hangul Compatibility Jamo — Vai 	3130..A63F
Syloti Nagri — Hangul Jamo Extended-B	A800..D7FF
CJK Compatibility Ideographs		F900..FAFF
CJK Compatibility Forms			FE30..FE4F
EOB
my @nobaseline_blocks = map [(/.*\b(\w+)(-|\.+)(\w+)\s*$/ or die 'Panic') and (hex $1, hex $3)], split /\n/, $nobaseline_blocks;
my $minus1_seen = 0;

my $splineP = 4/3*sqrt(2)/2/(1+sqrt(2)/2);	# works best for 90° angle; for smaller angles, is not best fit, but the mismatch is less important
my $splineQ = 1 - $splineP;

sub run_2_str ($) {				# for dwarn
  my $arr = shift;
  my @a = @$arr;
  $a[1] and ref $a[1] and $a[1] = "[@{$a[1]}]";
  defined or $_ = '' for @a;
  "[@a]"
}

sub output_sfd_char ($$$$$$$$$$$$$) {
  my($c,$width,$height,$px_descent,$Lb,$minwidth,$strokes,$pixels,$cntedge,$offs,$edge, $nextEdge, $entryPoint) 
    = (shift,shift,shift,shift,shift,shift,shift,shift,shift,shift,shift,shift,shift);
  my $DEC  = ($c =~ /^(\.n[.\w]+)$/ ? -1 : hex $c);
  my $dec  = ($c =~ /^(\.n[.\w]+|$opt{hiderex})$/o ? -1 : hex $c);
  my $dec1 = ($c =~ /^(\.n[.\w]+|$opt{hiderex})$/o ? ($opt{manglenotdef} ? 4080+$minus1_seen++ : -1) : hex $c);	# Windows' console makes font-order chars 0,1 into .notdef
  $dec1 = 0x0fff - 3 + $dec1 if $dec1 <= 3;	# Ids 0..3 should be filled by special glyphs. U+0f** are Tibetan; end unused in 6.3
  my $ptwidth = (($opt{mono} and $c ne '.null') ? 8 : $width) * $px_size;
  my $shift_by_truetype = '';
  my $char = ($c =~ /^\./ ? '' : chr hex $c);
  # In non-mono situation, may use width=0 and negative offset; for monospace, must use Position2
  $shift_by_truetype = qq[Position2: "'mark' Zero-Width Marks lookup" dx=-$ptwidth dy=0 dh=-$ptwidth dv=0\n]
    if $char =~ /\p{NonSpacingMark}/ and $opt{mono} and not $opt{nolayouts};
  # if $shift_by_truetype, do not use offsets
  # if mono, do not use offsets (mono and nolayouts: will not show diacritics correct):
  my $no_offset = ($opt{mono} or $shift_by_truetype or not $char =~ /\p{NonSpacingMark}/);
  my $xoff = ($no_offset ? 0 : -($opt{mono} ? 8 : $width)) and $ptwidth = 0;
  my $scale = (($minwidth > 8 and $opt{mono}) ? 7/($minwidth-1) : 1);
  my $yscale = my $yscale_bottom = 1;
  my $yoff = 0;							# ($dejavu_sizes ? 0.9*$scale : $scale);
  if ($dejavu_sizes) {	# Top of DejaVu is at 12⅓, not 14;  bottom is at 3³⁄₁₆, not 2.  Total height is by 1/32 lower
    my $use_baseline = 1;
    for my $b (@nobaseline_blocks) {
# warn "$c: start block [@$b]" if $DEC == $b->[0];
# warn "$c: end   block [@$b]" if $DEC == $b->[1];
      $use_baseline = 0, last if $DEC >= $b->[0] and $DEC <= $b->[1];
    }
    if ($use_baseline) {
      $yscale = 0.9;
      $yoff = 14 * (1 - $yscale);	# Baseline is on $y = 14
      #$yscale_bottom = 1.18;		# So that -2 becomes -2.36, and is rendered the same at the natural size
      $yscale_bottom = $yscale;		# Otherwise need to have a separate offset!
    } else {
      $_ = 31/32 for $yscale, $yscale_bottom;
      $yoff = 14 * (1 - $yscale);	# Baseline is on $y = 14
      $yoff += 5/4;			# 3³⁄₁₆ - ³¹⁄₃₂*2; y grows ↓
    }
  }
  my $lEdge = (($width > 8 and $opt{mono}) ? $Lb+1 : 1);	# Want $ledge to shift to 0.5+$xoff
  if ($lEdge > 1 && $minwidth < 8) {  # Need to decrease right and left bearings symmetrically (if width allows this):
    my $Rb = $width - $minwidth - $Lb;
    my $goodL = (8 - $minwidth)*$Lb/($Lb+$Rb);	# divide proportionally
    my $prefL = $Lb - $goodL;
    my $minL = $Lb - (8 - $minwidth);
    if ($prefL <= $minL) { $lEdge = $minL+1 }
    elsif ($prefL >= $Lb) {}	# Already good
    else { $lEdge = int($prefL+1.5) }
    warn "lEdge=$lEdge; lb=$Lb, rb=$Rb, prefL=$prefL, minL=$minL, minW=$minwidth\n" if debug > 0;
  }
  $xoff = 0.5 + $xoff - $lEdge * $scale;	# $X*$new_scale + $new_xoff = (($X-$lEdge)*$scale+0.5+$xoff)*$px_size
  $_ *= $px_size for $scale, $xoff;
  my $pref = ($c =~ /^((0|1(?=0))?[\da-f])?[\da-f]{4}$/i ? ($1 ? 'u' : 'uni') : '');	# Needed to make cut/paste from Acrobat better
  my $out_comb = $char =~ /\p{NonSpacingMark}/ && "# is_comb $pref$c\n";
  $c =~ s/^\.nx\.//;				# was added to make sorting easier only
  (my $C = $c) =~ s/^0(?=[\dA-F]{5}$)//i;
  my $post = ($c =~ $opt{hiderex}) ? '.hide' : '';	# disable resetting of position via the name
  print $fea "    pos \\$pref$C <-512 0 -512 0>;\n"
    if $fea and not $post and $char =~ /\p{NonSpacingMark}/;
  print << "END";

StartChar: $pref$C$post
Encoding: $dec1 $dec $charcnt
Width: $ptwidth
Flags: HW
TeX: 0 0 0 0
Fore
SplineSet
END
  $charcnt++;

  my $nostroke = $nostroke_rex && $c =~ $nostroke_rex;
  my $avoid_right_angle = $opt{avoid_right_angle} && $c =~ /^($opt{avoid_right_angle})$/oi;
  my $skip_straight = $opt{skip_straight} && $c =~ /^($opt{skip_straight})$/oi;
  for my $Stroke (@$strokes) {
    my(@DO, $BLOB, $break_loop);
   JOIN_PIECES: {
      my($loop, $blob, $stroke, $runs, $breaks) = @$Stroke;
      $BLOB = $blob;
	warn 'stroke' unless $stroke;
	# warn 'breaks' unless $breaks;
	# warn 'runs' unless $runs;
      debug > 0 and warn "processing stroke with ", scalar @$stroke, " edges, loop=$loop, breaks[@{$breaks||[]}]=", scalar @{$breaks||[]}, ", runs=", scalar @{$runs||[]}, ".\n";
      debug > 0 and warn "  runs=", join(', ', map run_2_str($_), @$runs), "\n";
      # fontforge may crash on lines with many segments (expanding stroke)
#     next if @$stroke > 20;
      # Prearranged strokes (coming from longedges) have dir==-20; replace with 1 and it is done
      push(@DO, [-20, @{ $stroke->[0] }[1..4], -20]), last JOIN_PIECES
        if @$stroke == 1 and ($stroke->[0][0] || 0) == -20;	# Always a loner
      push(@DO, [-40, @{ $stroke->[0] }[1,2,1,2], -40]), last JOIN_PIECES
        if @$stroke == 1 and not defined $stroke->[0][0];	# Always a loner
      $break_loop = $loop && !$BLOB;
      my($LOOP, $need_break) = ($loop < 0);	# -1,-2 if closed smooth (-2 if ends are at join); 1,2 if has corners (if 1, starts at a corner)
      if ($skip_straight) {
        $runs = [[0],[$#$stroke+1]];		# fake corners at ends; [0] means: start at 0, no calculated lines until the next
        $breaks = [0];
      } elsif ($loop >= 0) {			# if it is a loop, it is not smooth, so stroke_2_strokes() was called
        $need_break = $loop, $loop = 0 if @$breaks > 1 or $blob;	# @$breaks starts with 0
        if (0 and $loop and $runs->[-2][1]) {		# The last “real” run is a calculated one, so the logic below will not work
          push @$breaks, $#$runs - 1;
          $loop = 0;
        }
      }
      debug > 0 and warn "  need_break=", $need_break || '', "\n";
      my($go_through_start_point, $prev) = (0, 0);
      for my $runn (0..$#$runs - 1) {		# The last one is fake???
        $go_through_start_point = 1, shift @$breaks if @$breaks and $runn == $breaks->[0];
        my $run = $runs->[$runn];
        for my $c ($run->[1] ? $run->[0] : ($run->[0]..$runs->[$runn+1][0]-1)) {	# a calculated stroke is merged into 1 DO
          my $edge = $stroke->[$c];		# $run->[1] (if present) has coordinates relative to $edge
          my($dir,$x,$y,$x1,$y1,undef,undef) = @$edge;
#          warn "\tedge[$c]: $dir,$x,$y,$x1,$y1";
          my $DIR = 2*$dir;
          $prev = $dir unless defined $prev;
          $go_through_start_point = -1 if $go_through_start_point and ($loop or $need_break) and !$blob;	# Insert an extra break
          $need_break = 0;
          $go_through_start_point *= 2 if $go_through_start_point and $LOOP and not $c;
          if ($run->[1]) {				# offset the calculated stroke by the beginning of the first segment
            my @coord = ($x,$y,$x,$y);
            $coord[$_] += $run->[1][$_] for 0..3;
            ($x,$y,$x1,$y1) = @coord;
            undef $dir;					# would be $prev on the next round (unused???)
            $DIR = $run->[1][6];
          } elsif (0 and $loop and $c == $#$stroke 	# break loop into two open parts
                  # Probable reason for fontforge’s crash: sharp turns (45° angle) compressed yet more by 16 --> 8 width transformation.
              or $nostroke
              or $opt{mono} # and $minwidth > 11 and @$stroke > 20 
               and (2 > abs(($dir-$prev)%8-4)
                      or 2==abs(($dir-$prev)%8-4) and ($avoid_right_angle or $minwidth > 11 and 0 == (($dir+$prev)%8)))) {	# \/ or /\

            $go_through_start_point = 1;
          }
    ##warn "DIR undef in $go_through_start_point, $x, $y, $x1, $y1\n" if $#$stroke and not defined $DIR;
          push @DO, [$go_through_start_point, $x, $y, $x1, $y1, $DIR];
          $go_through_start_point = 0;
          $prev = $dir;
        }
      }
    }
    my @prev;
    for my $i (0..$#DO) {
        my($go_through_start_point, $x, $y, $x1, $y1, $dir) = @{ $DO[$i] };	# We will add: 6:length², 7: merge_prev, 8: merge_next
        my($Dx,$Dy) = ($x1-$x, $y1 - $y);				#  9:len² for prev, 10:same for next
        my $D2 = $Dx*$Dx + $Dy*$Dy;
        $DO[$i][6] = $D2;
        {
  #        $DO[$i-1][10] = $D2;
          my $dir1 = $DO[$i-1][5];
#		warn "  c=$c; dir=$dir dir1=$dir1" unless $i;
	  if ($opt{workaround_bug_expand}
	      and !((2*$dir) & 3) and !((2*$dir - 2*$dir1 + 16)%32)	# opposite, precise directions (possible for blobs)
	      and ($i or  $DO[$i-1][3] == $DO[$i][1] and $DO[$i-1][4] == $DO[$i][2])
	      and ((2*$dir) & 7)) {				# Only for diagonal directions (otherwise new bugs!)
	    my $d1 = ($dir1/2+2)%8;
	    my($dx,$dy) = ($dx[$d1], $dy[$d1]);
	    $_ *= $eps_px_size/$px_size for $dx, $dy;		# still locks up if /sqrt(2) or /2
	    $DO[$i-1][1] += $dx;   $DO[$i-1][2] += $dy;   	# move away by a tiny amount
	    $DO  [$i][1] -= $dx;   $DO  [$i][2] -= $dy;   
	    $DO[$i][0] ||= 100;					# force behaviour as if $go_through_start_point: going through the start point
#		warn "Did INSERT (char=$c, i=$i, dir=$dir dir1=$dir1)";
	  }
          #  !$go_through_start_point or ($go_through_start_point > -20 and !$i and abs($go_through_start_point) > 1);	# ignore $go_through_start_point at i=0 if $loop < 0
  #warn "$i: dir=$dir dir1=$dir1; ($go_through_start_point, $x, $y, $x1, $y1, $dir)\n";
	  my $force_connect = ($go_through_start_point > -20 and abs($go_through_start_point) > 1);
          $DO[$i][7] = $DO[$i-1][8] = 1		# Connect through break
	    if (!$go_through_start_point or $force_connect and !$i)	# -40 for singletons
		and $dir != $dir1 and 8 > abs((2*$dir - 2*$dir1 + 16)%32 - 16);	# rotate less than 90°
        }
  #      $i < $#DO and $DO[$i+1][9] = $D2;
  		#  (prev=$DO[$i][9], next=$DO[$i][10])
    }
#    for my $i (0..$#DO) {
#        warn "DO[$i]:\t@{$DO[$i]}[0..5] len2:$DO[$i][6]; merge: prev=",!!$DO[$i][7]," next=",!!$DO[$i][8],"\n";
#    }
  #  warn "empty \@DO; strokes=", scalar @$strokes unless @DO;	# May be purely a blob
    my ($prev_X, $prev_Y, $p_X, $p_Y, $s_X, $s_Y) = @{ $DO[-2] || [(0) x 5] }[3,4];
    $prev_X  =  $prev_X * $scale + $xoff;
    $prev_Y = ($height - $prev_Y*($prev_Y<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
    for my $i ((($DO[0] || [])->[7] ? -1 : 0)..$#DO) {		# If need to connect first and last, do the last at start w/o i/o
        my($go_through_start_point, $x, $y, $x1, $y1, undef, $len2, $merge_prev, $merge_next, $insert_fixbug) = @{ $DO[$i] };
        if ($go_through_start_point == -40) {		# singleton
          my $X  =  $x * $scale + $xoff;
          my $Y = ($height - $y*($y<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
          my $Xl = $X - $eps_px_size;	my $Xr = $X + $eps_px_size;
          my $Yt = $Y + $eps_px_size;	my $Yb = $Y - $eps_px_size;
          print <<EOP;
$Xl $Y m 1
  $X $Yt l 1
  $Xr $Y l 1
  $X $Yb l 1
  $Xl $Y l 1
EOP
          next;
        }
        $_ ||= 0 for $merge_prev, $merge_next;
        my $no_mid;
        if ($merge_prev and $merge_next) {
          if ($len2 > 4) {
            $merge_next = $merge_prev = 1/sqrt($len2);		# Contribute length=1 to the curved part
          } else {
            $no_mid = $merge_prev = $merge_next = 0.5;
          } 
        } elsif ($merge_prev) {
          if ($len2 > 1/0.49) {
            $merge_prev = 1/sqrt($len2);
          } else {
            $merge_prev = 0.7;
          } 
        } elsif ($merge_next) {
          if ($len2 >= 1/0.49) {
            $merge_next = 1/sqrt($len2);
          } else {
            $merge_next = 0.7;
          } 
        }
  #  }
  #  for my $i (0..$#DO) {
  #      my($go_through_start_point, $x, $y, $x1, $y1) = @{ $DO[$i] };
  ##      my $do_end = $i != $#DO;
  ##      $do_end ||= $go_through_start_point1;
        if ($go_through_start_point and $i >= 0) {{	# for blobs, fixbug on $i==0 will be handled by close-loop code
          my $X  =  $x * $scale + $xoff;
          my $Y = ($height - $y*($y<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
          ($X, $Y) = ($prev_X, $prev_Y) if $merge_prev;
          last if $i and $p_X == $X and $p_Y == $Y;
          ($p_X, $p_Y) = ($X, $Y);
          ($s_X, $s_Y) = ($X, $Y) unless $i;
          my ($sp, $how) = ($i ? ('  ', 'l') : ('', 'm'));	# The "breaks" indicate *unwanted* breaks
          print <<EOP;
$sp$X $Y $how 1
EOP
        }}
        if ($merge_prev) {
          my $X  =  $x * $scale + $xoff;
          my $Y = ($height - $y*($y<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
          my $XX = ($x1 - $x) * $merge_prev + $x;
          my $YY = ($y1 - $y) * $merge_prev + $y;
          $XX  =  $XX * $scale + $xoff;
          $YY = ($height - $YY*($YY<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
          my($preX, $preY, $postX, $postY) 
            = ($splineP*$X+$splineQ*$prev_X, $splineP*$Y+$splineQ*$prev_Y, $splineP*$X+$splineQ*$XX, $splineP*$Y+$splineQ*$YY);
          # For going with constant speed along a straight line, use equally distanced control points for cubic spline;
          # At t=.5, the point is the weighted average with weights 1,3,3,1; if we want it to be the middle of the arc connecting
          # endpoints, T must divide the interval I=[point,controlpoint] in ratio 3:1; here T is the intersection of I
          # with the tangent at midpoint of the arc.  If C is the intersection of tangents to the spline at endpoints, then
          # controlpoint divides [point,C] in ratio 2:1 for parabolas (and small arcs), and in ratio 0.55:0.45 for arc of 90°
          # (in general, its position on [point,C] is 4/3 · cos α/(1+cos α) ??? for an arc of 2α).
          if ($i >= 0) {
            print <<EOP;
  $preX $preY $postX $postY $XX $YY c 1
EOP
            $break_loop = 0, $go_through_start_point = 1, print <<EOP if $break_loop and !$i ; # Make it interpreted as non-closed
$XX $YY m 1
EOP
            ($p_X, $p_Y) = ($XX, $YY);
          }
          $prev_X = $XX, $prev_Y = $YY if $no_mid;
        }
        $x1 = ($x1 - $x) * (1 - $merge_next) + $x;
        $y1 = ($y1 - $y) * (1 - $merge_next) + $y;
        unless ($no_mid) {
          my $X1  =  $x1 * $scale + $xoff;
          my $Y1 = ($height - $y1*($y1<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
          $prev_X = $X1;   $prev_Y = $Y1;
          my $is_corner = 1;	# $merge_next ? 0 : 1;
          if ($i >= 0) {
            print <<EOP unless $no_mid;
  $X1 $Y1 l $is_corner
EOP
            $break_loop = 0, $go_through_start_point = 1, print <<EOP if $break_loop and !$i; # Make it interpreted as non-closed
$X1 $Y1 m 1
EOP
            ($p_X, $p_Y) = ($X1, $Y1);
          }
        }
        if ($BLOB and $i == $#DO and ($s_X != $p_X or $s_Y != $p_Y)) {
          print <<EOP;		# finish the loop
  $s_X $s_Y l 1
EOP
        }
    }
  }

  for my $e (@$entryPoint) {		# coarse_blobs
    my($c, $x, $y, $dir, $C) = (0, @$e);
    my $X = $x * $scale + $xoff;
    my $Y = ($height - $y*($y<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
    my($dx,$dy) = ($dx[($dir-2)%8], $dy[($dir-2)%8]);
    $X += $dx * $eps_px_size; $Y -= $dy * $eps_px_size;
    print <<EOP;
$X $Y m 1
EOP
    while ($c++ < $C) {
      ($x,$y,$dir) = @{ $nextEdge->[$dir][$y][$x] };
      $X = $x * $scale + $xoff;
      $Y = ($height - $y*($y<0 ? $yscale_bottom : $yscale) - $yoff - $px_descent + 0.5)*$px_size;
      ($dx,$dy) = ($dx[($dir-2)%8], $dy[($dir-2)%8]);
      $X += $dx * $eps_px_size; $Y -= $dy * $eps_px_size;
    print <<EOP;
  $X $Y l 1
EOP
    }
  }
  print << "END";
EndSplineSet
$out_comb${shift_by_truetype}EndChar
END
}

my @LINES = (qw( | / - \ ) x 2);
my @LINESL = (qw( ◫ ⧄ ⊟ ⧅ ) x 2);
my $withblob = {qw( ! ‼ * ⊛)};
my $noblob = {qw( ! ! * *)};

sub output_human_readable ($$$$$$$$$$) {
  my($width, $height, $pixels, $rays, $edge, $cntedge, $cnt, $Simple, $InLong, $blob) 
    = (shift, shift, shift, shift, shift, shift, shift, shift, shift, shift);
#warn "... <$rays->[7][2][7]> [@{$rays->[7][2][7]}] [[@{$rays->[7][2][7][1]}]] [[[@{$rays->[7][2][7][1][2]}]]]";
  for my $y (1..$height) {	# Print out identifications of rays
    my(@row, @row1);
    for my $x ( 1..$width ) {
      my $rays = $rays->[$y][$x] || $E;		# May fill $E to $M if (map {} @rays[$N..$M]) is accessed
      my $smpl = $edge->[$y][$x] || $E;
      my $inLong = $InLong->{$x,$y};
      my @bad = grep defined($rays->[$_]) && !defined($rays->[$_][0]), 0..7;
      my @bad2 = map @{$rays->[$_][1]}, @bad;
      warn "$x,$y  [@bad] [[@bad2]]" if @bad;
      push @row,  [ map { defined() ? substr $_->[0], 0, 1 : ' ' } @$rays[0..7] ];	# Array with 8 entries per pixel; same below
      my @r = map { $smpl->[$_] ? ($inLong->{$_} ? $LINESL[$_] : $LINES[$_]) : $row[-1][$_] } 0..7;
      push @row1, \@r;
    }						# Compass directions corresponding to the position on 3-refined grid
    for my $subrow ([7,0,1],[6,8,2],[5,4,3]) {	# 8 will be converted to * below (and any missing entry near a black pixel! ???)
      my ($o, $o1) = ('', '');
      for my $x ( 0..$width-1 ) {
        $o  .= join '', map  $row[$x][$_] || ($pixels->[$y][$x+1] ? '*' : ' '), @$subrow;
        $o1 .= join '', map $row1[$x][$_] || ($pixels->[$y][$x+1] 
        				      ? (($cntedge->[$y][$x+1] || !$cnt->[$y][$x+1]) 
        					 ? (($blob->[$y][$x+1] and $cnt->[$y][$x+1]) ? $withblob : $noblob)
        					           ->{$Simple->[$y][$x+1] 
        					    ? '!' : '*'} : 'X')
        					 : ' '), @$subrow;
      }
      $o .= ( ' ' x (56 - length $o) . $o1 );
      $o =~ s/\s+$//;
      s/\s\s+$/\t/ for my @o = ($o =~ /(.{1,8})/g);
      ($o = join('', @o));	# =~ tr/…P""/????/;
      print "$o\n";
    }
  }
}

use Image::Bitmap2Paths;
sub output_processed_bitmap ($$$$$$) {
  my ($c, $px, $width, $height, $Lb, $Rb) = (shift, shift, shift, shift, shift, shift);
  $marked = 0;
  $marked2 = 0 if $opt{marked2};
  my $minwidth = $Rb - $Lb - 1;
  my $bm = Image::Bitmap2Paths->new(bitmap => $px);
### my $R = $bm->get('rays50');
### warn "[@{$R->[1][15][3]}]";
### warn "[@{$R->[1][15][3][-1]}]";
### $bm->get('stage10');
### warn 111000;
### $bm->get('stage20');
### warn 111;
### $bm->get('stage40');
### warn 222;
  my $strokes = $bm->get('strokes');	# Will get a lot of other stuff in between, so $marked/$marked2 has chance to be set
### warn "... <$rays->[7][2][7]> [@{$rays->[7][2][7]}] [[@{$rays->[7][2][7][1]}]] [[[@{$rays->[7][2][7][1][2]}]]]";
#warn "found strokes: ", scalar @strokes, "\n";
  return if $opt{marked} and not ($marked and $marked2);

	if ($opt{sfd}) {
	  output_sfd_char($c,$bm->get('width'), $bm->get('height'), $px_descent, $bm->get('Lb'), $minwidth, $bm->get('strokes'), $bm->get('bitmap'),
			  $bm->get('cntedge90'), $bm->get('offs'), $bm->get('edge90'), $bm->get('nextEdgeBlob'), $bm->get('entryPointBlob'));
	  return;
	}
	print "\t\t\t\t\t$c\t ", (32 < hex $c ? chr hex $c : ''), " \n";
##	output_human_readable($width, $height, $px, $bm->get('rays'), $bm->get('edge90'), $bm->get('cntedge90'), $bm->get('cnt'),
###	output_human_readable($bm->get('width'), $bm->get('height'), $bm->get('bitmap'), $bm->get('rays'), $bm->get('edge90'), $bm->get('cntedge90'), $bm->get('cnt'),
##			      $bm->get('Simple'), $bm->get('inCalcEdge'), $bm->get('blob30'));
	output_human_readable($bm->get('width'), $bm->get('height'), $bm->get('bitmap'), $bm->get('rays50'), $bm->get('edge90'), $bm->get('cntedge90'), $bm->get('cnt'),
			      $bm->get('Simple'), $bm->get('inCalcEdge'), $bm->get('blob30'));

}

my($notdef, $private) = ('00542A542A542A542A542A542A542A00', 'FFB9C5EDD5D5D5D5D5D5D5D5EDB991FF');
my($mynotdef, $notdef_done, @doing_rest, $doing_rest) = 'FF808E9181A2A485A1254581897101FF';
$opt{hiderex} ||= '(?!)';
$opt{hiderex} = qr/^($opt{hiderex})$/i;

my $seen_d1 = '';
while(1) {
	my($c,$d);
	if ($notdef_done++ and not $doing_rest) {		# Step 2
	  $doing_rest++, (@doing_rest = sort keys %override), next unless defined($_ = <>);
	  chomp;
	  ($c,$d)=split(/:/);
	  $d = delete($override{lc $c}) || $d;
	  # unrecognized; distinct from "SHADE" characters; should be done via a glyph for .undef
	  next if $d eq $notdef or $d eq $private;
	  (need_char $c and $override{$c} = $d), next if $opt{sfd} and $c =~ /^00[01].$/;		# Postpone to make SPACE the 4th char in TTF
	} elsif ($doing_rest) {					# Step 3
	  defined ($c = shift @doing_rest) or last;
	  $d = $override{$c};
	} else {						# Step 1
	  next unless $opt{generatenotdef};
	  ($c,$d) = ('.notdef', $mynotdef);
	}
	next unless need_char $c;
	my $d1 = ($ord ? sprintf '%x', int($ord/0x1000) : '');
	print STDERR ($d1 eq $seen_d1 ? '#' : ($seen_d1 = $d1)) if 0 == (++$ord) % 1000;
	output_char_if_narrow($c, $d);
}
close $fea or die "Cannot close comb-fea for write" if $fea;
## my @O = sort keys %override;
## warn "override=<@O>\n";


sub test_encodes_line($$$;$$) {
  my ($out, $out_shift) = (shift, shift);
  my $ret = (my ($res, $shift) = Image::Bitmap2Paths::encodes_line(@_));
  $res = 1/$res if $ret;			# old system was in exchanged coordinate system
  if (defined $out xor $ret) {
   print "! ", ($ret ? " expect: NONE;\t$res <- " : "expect: $out;\tNONE <- ");
  } elsif ($ret and abs($res-$out) < 1e-9) {
   print "OK expect: $out; $res <- ";
  } else {
   print +($ret ? "! expect: $out;\t$res <- " : 'OK NONE <- ');
  }
#  print "\n";
#  return;
  my $in = shift;
  my @r = map {defined() ? $_ : '<undef>'} @_;
  print "[@$in] @r\n";
  if (defined $out_shift) {
    if (abs($shift - $out_shift) <= 1e-9 * (abs($shift) + abs($out_shift))) {
      print "shift OK: $shift\n";
    } else {
      print "! shift OK: $shift; expect = $out_shift\n";
    }
  }
}

sub _test_encodes_line {	# Need to check incredible amount of branches...
  # Actually, the slopes below are for the old algorithm; the new one gives slightly different fits.
  test_encodes_line($_->[0], $_->[1], $_->[2], $_->[3], $_->[4])
    for [7, undef, [7], 1, 1], [7, undef, [7], 0, 1], 
        [7, undef, [7], 1], [undef, undef, [7, 9], 1, 1], [undef, undef, [7,9], 1], [undef, undef, [5,7], 1], [undef, undef, [7, 5], 0, 1], 
        [9, undef, [7, 9], 0, 1], [9, undef, [7,9]], [5.5, undef, [5,6], 1], [5.5, undef, [6, 5], 0, 1], 
    	[9, undef, [7, 9], 0, 1], [9, undef, [9, 7], 1], [7.5, undef, [7,8], 1], [4.5, undef, [5,4], 0, 1], [15, undef, [7, 15], 0, 1], [15, undef, [15, 12], 1], 
    	[9, undef, [7, 9]], [9, undef, [9, 7]],
        [undef, undef, [2,2,3,3], 1], [undef, undef, [2,2,3,4,3]], [undef, undef, [2,2,4,3]], [undef, undef, [2,3,3,4], 1], [undef, undef, [4,3,3,2], 0, 1], 
        [2+2/3, undef, [2,2,3,3]], [2.75, undef, [2,2,3,3,3]], [3.5, undef, [2,3,4,3]], [2.75, undef, [2,3,3,3], 1], [3+1/3, undef, [4,3,3,2]], 
        [3, undef, [2,3,3,3], 0, 1], [3, undef, [1,3,3,3], 0, 1], [3, undef, [2,3,3,3]], [3, undef, [1,3,3,3]], [3, undef, [1,3,3,3,1]], 
        [3, undef, [3,3,3,2], 1], [3, undef, [3,3,3,1], 1], [3, undef, [3,3,3,2]], [3, undef, [3,3,3,1]], 
        [2+1/3, undef, [3,2,2,2], 1], [2+1/3, undef, [3,2,2,2]], [2+1/3, undef, [2,2,2,3], 0, 1], [2+1/3, undef, [2,2,2,3]], 
        [3-1/3, undef, [2,3,3,2], 1], [3-1/3, undef, [2,3,3,2], 0, 1], [3-1/3, undef, [2,3,3,2], 1, 1], 
        [undef, undef, [3,3,2,2,3]],    [undef, undef, [3,2,2,3,3]],       [undef, undef, [3,3,2,2,2]],    [undef, undef, [2,2,2,3,3]], 
        [undef, undef, [3,3,4,4,3], 1], [undef, undef, [3,4,4,3,3], 0, 1], [undef, undef, [3,3,4,4,4], 1], [undef, undef, [4,4,4,3,3], 0, 1], 

        [2+1/3, undef, [2,3,2,2,3]],    [2+2/3, undef, [2,3,3,2,2]],       [2.75, undef, [3,3,3,2,2]],    [2.75, undef, [2,2,3,3,3]], 
        [3+2/3, undef, [3,3,4,4,3]],    [3+2/3, undef, [3,4,4,3,3]],       [3.75, undef, [3,3,4,4,4]],    [3.75, undef, [4,4,4,3,3]], 

        [5.5, undef, [5,6,5,6,5,6]],       [5.5, undef, [5,6,5,6,5,5]],    [5.5, undef, [5,5,6,5,6,5,6]], 
        [5.5, undef, [5,6,5,6,5,6], 1, 1], [5.5, undef, [5,6,5,6,5,5], 1], [5.5, undef, [5,5,6,5,6,5,6], 0, 1], 
        [undef, undef, [4,2,3,3]], [undef, undef, [2,2,3,4]], [undef, undef, [2,3,4,3], 1], [undef, undef, [4,3,4,2], 0, 1], 
        [undef, undef, [2,2,2,3,3]], [undef, undef, [2,2,3,3,3], 1], 

        [2+2/3, undef, [3,2,3,3]], [2+2/3, undef, [2,2,3,3]], [3.5, undef, [2,3,4,3]],     [3.5, undef, [4,3,4,2]], 
        [2+1/3, undef, [2,2,2,3,2]], [2.75, undef, [2,2,3,3,3]], 

        [2.4, undef, [3,2,2,3,2,3]], [undef, undef, [3,2,2,2,2,3,2,2,3]], [2 + 2/9, undef, [3,2,2,2,2,3,2,2,2,3]],
        [2 + 2/9, undef, [2,2,3,2,2,2,2,3,2,2,2,3,2]], [2 + 2/9, undef, [1,2,3,2,2,2,2,3,2,2,2,3,1]],
        [2.2, undef, [3,2,2,2,2,3,2,2,2]], 
        [5/3,  0.25, [1,2]], 
        [5/3, -0.05, [2,1]], 
        [2, 0.5, [1,2,2]], 
        [2, 0.5, [1,2,2,2,2,1]], 
        ;
}

# The following logic looks very productive into decomposition into
# strokes (not implemented yet; does not include recognition of "extra"
# vert/hor/diag strokes, and forced recognition of long "straight strokes"):

# A "star" is a pixel where several strokes ("curves", "rays") join.
# There is one ray per a neighbor of a star.  The logic to recognize a pixel
# as a star: we need to find out where each ray continues on the "second step".

# A) Every ray (essentially: every neighbor pixel) is classified into one
#    of a dozen (or so) types (depending on the angular neighborhood).

# B) If a pixel has a ray of unknown type, the pixel is not a star.
# B-dep) Each ray may have one (or more) "dependent" pixels, which must be
#        (at least "partial") stars for the ray to be recognized.  So if all
#        of dependent pixels are rejected on the step "B", one rejects the ray.
#        Hence the pixel the ray originates from is also not a star.
# B0) What remains are ("isotropic") star-candidates.
# B-recursive: should we do B-dep recursively???

# C) More detailed examination of rays: one wants to find one to which
#    pixel at distance 2 the ray goes (or whether it is a length=1 spur).
#    So we need to find which neighbors of the first pixel of the ray
#    "come from OTHER rays of star-candidates nearby".  (Also: ignore the
#    originating pixel of the ray.  If at most 1 neighbor remains, it is called
#    "the continuation", and the ray is "a confirmed ray-candidate".
 
#      Aside: more on dependencies: it is a combination (by ORing) of several
#                                   neighbors, each of them having several
#				    required directions of "good" rays.

# C-dep) Now re-examine dependencies: check that at least one of dependent
#        pixels has all its required rays "confirmed" on step "C".
# C-recursive) One DOES NOT run dependencies recursively!  If dependent rays
#        "look nice", but one of the "secondary dependent" rays does not,
#	 we do not consider it as a reason to "ignore a ray".

#    Looks like: by the same logic, we should not reject pixels early, on (B).
#    So better: the final answer is "a star, but only in the following sectors"

# Results: Pixels may be marked as
# (0) stars; (1) "the first pixel on a ray"; (2) "the second pixel of a ray";
# (3) (for sharp angles): same with 3rd; (4) "spurs of exactly one star".
# How these may be combined?

# 0x1200 - starts bold; ethiopic.  Do we want to recognize it???

# Also: recognize solid angles: all rays in a certain range are neighbors.
# Join all such neighboring regions together into one blob of paint???
# What to do with pixels on boundary next to incoming angle ("?"s below)???

####
##?#
#?
##

# Returned ray is:
# (*) a tail/notch/serif etc, and multiplicity is checked
# (*) or curve of known curvature, and need to check multiplicity
#		(take into account only the continuation star???)
# (*) or a dependency - then we check _its_ rays instead of ours.
# TRUE???  For sharp, also need to check multiplicity.
#	Looks like for (multiple) dependency, do not need to check multiplicity...

# If a doubleray fails multiplicity check, treat it as dependency on one of two
# pixels.

# Result would be: a pixel is a combination of following possibilities (every
# one wins if comes earlier:

# (*) a star;  (check mult≤2, angle ≥135°; if so, change to a curve).
# (*) on a curve next to a star; (store dir1,dir2 to two neighbors).
# (*) on a curve 2 steps from a star (on a sharp angle); do likewise.

#    In the last two cases, accumulate this info for all neighbor stars;
#	inspect for contradictions (then what???)

# (*) extra step (possible???): if all our neighbors are known to be curves
#     entering us (or missing us???), propagate us to a star (and possibly
#     propagate the star to a curve, as above).

# ==== One should shortcircuit multiplicity check - if succeeds early, mark as OK.

# Do we want to join nearby stars (dependencies - of each other, or only one of another)???

# Put a sharp-joint or round-joint on ^-nodes depending on whether two arcs
# are both straight.

sub sfd_start ($$) {
  my ($height, $descent) = (shift, shift);
  my $ascent = $height - $descent;
  (my $Mono = my $mono = !!$opt{mono} && ' Mono') =~ s/^\s+//;	# Even with --nolayouts, make correct name
  (my $comments = <<EOC) =~ s/\s*\n\s*/ /g;
Created from the version $opt{oversion} of the GNU Unifont
with Ilya Zakharevich's Perl and FontForge scripts
from http://ilyaz.org/software/fonts/ .
See http://www.lgm.cl/trabajos/unifont/index.en.html for
information on the original, Luis Gonzalez Miranda' scripts.
See http://czyborra.com/unifont
and http://unifoundry.com/unifont.html
for information on GNU Unifont.  Copywrite of GNU Unifont is applicable.
EOC
    $comments =~ s/\s+$//g;
    my $cjk = (($opt{'cjk-all'} and $opt{name} and 'CJK') or '');
    $cjk = 'NoCJK' if $opt{nocjk} and $opt{name};
    $cjk = 'NoCJK++' if $opt{nocjkPP} and $opt{name};
    my $cjkS = $cjk && " $cjk";
    my $underline = int(-100/64*$px_size);
    my $underl_wd = int(  40/64*$px_size);
    # Non-0 gap is visible on Window's console (characters which should merge vertically do not)
    my $gap	  = 0;			# int(  72/64*$px_size);
    # Autogenerated: bits 17-19 set:		600f01ff.ffff0000 (cp932 JIS, cp936 Simpl.Chinese, cp949 Korean Wansung)
    my $os2CP = ($opt{noCJKcp} ? "OS2CodePages: 600101ff.ffff0000\n" : '');	# XXXX With --noCJKcp, SHOWS (!) CJK icon in the font viewer???
    my $verApp = (($opt{nocjk} and not $opt{name}) ? '-noCJK' : '');
    $verApp = '-noCJK++' if $opt{nocjkPP} and not $opt{name};
    ### With UnicodeBMP, needed 65536 chars
    return << "END" if $opt{nolayouts};	# The old version; does not allow "Lookup"s. (Apparently, spaces end FontName
SplineFontDB: 1.0
FontName: UnifontSmooth${Mono}$cjk-Medium
FullName: Unifont Smooth$mono$cjkS
FamilyName: Unifont Smooth$mono$cjkS
Weight: Medium
UComments: "$comments"
Version: $opt{oversion}-$rcs$verApp
ItalicAngle: 0
UnderlinePosition: $underline
UnderlineWidth: $underl_wd
Ascent: $ascent
Descent: $descent
FSType: 0
PfmFamily: 33
TTFWeight: 500
TTFWidth: 5
LineGap: $gap
VLineGap: 0
Panose: 2 0 6 9 0 0 0 0 0 0
OS2WinAscent: 0
OS2WinAOffset: 1
OS2WinDescent: 0
OS2WinDOffset: 1
HheadAscent: 0
HheadAOffset: 1
HheadDescent: 0
HheadDOffset: 1
${os2CP}ScriptLang: 1
 1 latn 1 dflt 
Encoding: UnicodeFull
UnicodeInterp: none
DisplaySize: -24
AntiAlias: 1
FitToEm: 1
WinInfo: 0 50 22
TeXData: 1 0 0 346030 173015 115343 0 1048576 115343 783286 444596 497025 792723 393216 433062 380633 303038 157286 324010 404750 52429 2506097 1059062 262144
BeginChars: 1114112 0
END
    my $lookup = qq<Lookup: 257 0 0 "'mark' Zero-Width Marks in Basic"  {"'mark' Zero-Width Marks lookup"  } ['mark' ('DFLT' <> 'cyrl' <'SRB ' 'dflt' > 'grek' <'dflt' > 'latn' <'ISM ' 'KSM ' 'LSM ' 'MOL ' 'NSM ' 'ROM ' 'SKS ' 'SSM ' 'dflt' > ) ]\n>;
    $lookup = '' unless $opt{mono} and not $opt{nolayouts};
    <<EOD;
SplineFontDB: 3.0
FontName: unifont$Mono
FullName: GNU Unifont$mono
FamilyName: unifont$mono
Weight: Medium
UComments: "$comments"
Version: 1.0-$rcs
ItalicAngle: 0
UnderlinePosition: $underline
UnderlineWidth: $underl_wd
Ascent: $ascent
Descent: $descent
LayerCount: 2
Layer: 0 0 "Back"  1
Layer: 1 0 "Fore"  0
FSType: 0
OS2Version: 0
OS2_WeightWidthSlopeOnly: 0
OS2_UseTypoMetrics: 0
PfmFamily: 33
TTFWeight: 500
TTFWidth: 5
LineGap: $gap
VLineGap: 0
Panose: 2 0 6 9 0 0 0 0 0 0
OS2TypoAscent: 0
OS2TypoAOffset: 1
OS2TypoDescent: 0
OS2TypoDOffset: 1
OS2TypoLinegap: 0
OS2WinAscent: 0
OS2WinAOffset: 1
OS2WinDescent: 0
OS2WinDOffset: 1
HheadAscent: 0
HheadAOffset: 1
HheadDescent: 0
HheadDOffset: 1
OS2Vendor: 'PfEd'
Encoding: UnicodeBmp
UnicodeInterp: none
NameList: Adobe Glyph List
DisplaySize: -24
AntiAlias: 1
FitToEm: 1
$lookup# 65536, but a few will be added at end (0000, 0001, .notdef etc)	- with 65520 crashes FF
BeginChars: 65536 0
EOD
}

