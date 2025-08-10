# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Image-Bitmap2Paths.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 39;
BEGIN { use_ok('Image::Bitmap2Paths') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @bm = map {[map $_ ne '-', split //]} split /\n/, <<EOB;  # At (5,3), (6,4), (7,5)
---------
---------
----x----
-----x---
------x--
---------
EOB

my $bm = Image::Bitmap2Paths->new(minibitmap => \@bm);
ok 1;					# 2
is $bm->get('width'), $#{$bm[1]}+1;
is $bm->get('height'), $#bm + 1;	# 4
is $bm->get('Lb'), 4;			# 5
is $bm->get('Rb'), 8;			# 6	(8-1)-4=3 pixels wide
ok $bm->get('stageOne');		# 7
is $bm->get('cnt')->[4][6], 2;		# 8
ok $bm->get('near')->[4][6][7];		# 9
ok $bm->get('rays10');			# 10
ok $bm->get('stage20');			# 11
ok $bm->get('edge20');			# 12
ok $bm->get('edge30');			# 13
ok $bm->get('edge40');			# 14
ok $bm->get('edge50');			# 15
ok $bm->get('edge60');			# 16
ok $bm->get('longedges70');		# 17
ok $bm->get('edge80');			# 18
ok $bm->get('edge90');			# 19
ok my $S = $bm->get('strokes');		# 20

#warn 'strokes=', scalar @$S, ".  Stroke0: <$S->[0][0]> is_blob=<$S->[0][1]> substrokes=", scalar @{$S->[0][2]}, ' -->  ', join ' | ', map "[@{$S->[0][2][$_]}]", 0..$#{$S->[0][2]};
#warn join(' | ', map "[@{$S->[0][3][$_]}]", 0..$#{$S->[0][3]}), ',    ', "[@{$S->[0][4]}]";
#warn join ' | ', map "[@{$S->[0][4][$_]}]", 0..$#{$S->[0][4]};

is scalar @$S, 1;			# 21	  [['', 0'' [[7,7,5,6,4], [7,6,4,5,3]], [[0], [2]], [0]]]
is $S->[0][1], !'blob';			# 22
is scalar @{$S->[0][2]}, 2;		# 23	Why 2 substrokes?!
is_deeply $S->[0][2][0], [7,7,5,6,4];	# 24
is_deeply $S->[0][2][1], [7,6,4,5,3];	# 25
is_deeply $S->[0][3], [[0], [2]];	# 26
is $S->[0][0], !'loop';			# 27
is_deeply $S->[0][4], [0];		# 28

## warn '#rays=', $#$R;
## warn '#rays[6]=', $#{$R->[6]};
## warn 'rays[5][7][7]=', "[@{$R->[5][7][7]}]", ' (y,x,dir)';	# doubleray 0
# warn 'rays[5][7][7]=', "[@{$bm->get('rays')->[5][7][7]}]", ' (y,x,dir)';	# doubleray 0
#warn 'rays[2][7]=', $R->[2][7], ' (y,x,dir)';	# doubleray 0

my $R = $bm->get('rays50');
warn '#rays[2][7]=', $#{$R->[2][7]}, ' (y,x,dir)';	# doubleray 0
warn '#rays[3][5]=', $#{$R->[3][5]}, ' (y,x,dir)';	# doubleray 0

my @LINES = (qw( | / - \ ) x 2);
my @LINESL = (qw( ◫ ⧄ ⊟ ⧅ ) x 2);
my $withblob = {qw( ! ‼ * ⊛)};
my $noblob = {qw( ! ! * *)};
my $E=[];
sub output_human_readable ($$$$$$$$$$) {
  my($width, $height, $pixels, $rays, $edge, $cntedge, $cnt, $Simple, $InLong, $blob) 
    = (shift, shift, shift, shift, shift, shift, shift, shift, shift, shift);
  for my $y (1..$height) {	# Print out identifications of rays
    my(@row, @row1);
    for my $x ( 1..$width ) {
      my $rays = $rays->[$y][$x] || $E;		# May fill $E to $M if (map {} @rays[$N..$M]) is accessed
      my $smpl = $edge->[$y][$x] || $E;
      my $inLong = $InLong->{$x,$y};
      my @bad = grep defined($rays->[$_]) && !defined($rays->[$_][0]), 0..7;
      warn "$x,$y  [@bad]" if @bad;
      push @row,  [ map { defined() ? substr $_->[0], 0, 1 : ' ' } @$rays[0..7] ];
      my @r = map { $smpl->[$_] ? ($inLong->{$_} ? $LINESL[$_] : $LINES[$_]) : $row[-1][$_] } 0..7;
      push @row1, \@r;
    }
    for my $subrow ([7,0,1],[6,8,2],[5,4,3]) {	# 8 will be converted to * below
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
      warn "$o\n";
    }
  }
}

	output_human_readable($bm->get('width'), $bm->get('height'), $bm->get('bitmap'), $bm->get('rays50'), $bm->get('edge90'), $bm->get('cntedge90'), $bm->get('cnt'),
			      $bm->get('Simple'), $bm->get('inCalcEdge'), $bm->get('blob30'));

$bm = Image::Bitmap2Paths->new(bitmap => \@bm);
is $bm->get('width'), $#{$bm[1]}-1;	# 29
is $bm->get('height'), $#bm - 1;	# 30
is $bm->get('Lb'), 3;			# 31
is $bm->get('Rb'), 7;			# 32	(7-1)-3=3 pixels wide
ok $S = $bm->get('strokes');		# 33
is_deeply  $S, [['', '', [[7,6,4,5,3], [7,5,3,4,2]], [[0], [2]], [0]]]; #34

	output_human_readable($bm->get('width'), $bm->get('height'), $bm->get('bitmap'), $bm->get('rays50'), $bm->get('edge90'), $bm->get('cntedge90'), $bm->get('cnt'),
			      $bm->get('Simple'), $bm->get('inCalcEdge'), $bm->get('blob30'));

is @{$bm->get('near')}, 5;		# 35
ok 1;					# 36
ok 1;					# 37
ok 1;					# 38
ok 1;					# 39

__END__
ok 1;					# 10
ok 1;					# 11
ok 1;					# 12
ok 1;					# 13
ok 1;					# 14
ok 1;					# 15
ok 1;					# 16
ok 1;					# 17
ok 1;					# 18
ok 1;					# 19
