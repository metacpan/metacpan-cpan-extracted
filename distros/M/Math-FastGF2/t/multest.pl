#!/usr/bin/perl -w

use Math::FastGF2::Matrix;

my @mat8x8 = (
	      ["35","36","82","7A","D2","7D","75","31"],
	      ["0E","76","C3","B0","97","A8","47","14"],
	      ["F4","42","A2","7E","1C","4A","C6","99"],
	      ["3D","C6","1A","05","30","B6","42","0F"],
	      ["81","6E","F2","72","4E","BC","38","8D"],
	      ["5C","E5","5F","A5","E4","32","F8","44"],
	      ["89","28","94","3C","4F","EC","AA","D6"],
	      ["54","4B","29","B8","D5","A4","0B","2C"],
	     );
my @inv8x8= (
	     ["3E","02","23","87","8C","C0","4C","79"],
	     ["5D","2B","2A","5B","7E","FE","25","36"],
	     ["F2","A9","B5","57","A2","F6","A2","7D"],
	     ["11","5E","E4","61","59","F4","B9","42"],
	     ["D5","16","B8","5B","30","85","1E","72"],
	     ["3B","F7","1B","5B","4C","55","35","04"],
	     ["58","95","73","33","8A","77","1C","F4"],
	     ["59","C0","7B","13","9F","8B","BE","E3"],
	    );
my @identity8x8= (
	    [1,0,0,0,0,0,0,0],
	    [0,1,0,0,0,0,0,0],
	    [0,0,1,0,0,0,0,0],
	    [0,0,0,1,0,0,0,0],
	    [0,0,0,0,1,0,0,0],
	    [0,0,0,0,0,1,0,0],
	    [0,0,0,0,0,0,1,0],
	    [0,0,0,0,0,0,0,1],
	   );

# in-place conversion of hex strings to decimal values
map { map { $_ = hex } @$_ } @mat8x8;
map { map { $_ = hex } @$_ } @inv8x8;

my ($r,$c,$m8x8,$i8x8,$r8x8,$id8x8);
$m8x8 = Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);
$i8x8 = Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);
$id8x8= Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);

for $r (0..7) {
  for $c (0..7) {
    $m8x8 ->setval($r,$c,$mat8x8[$r][$c]);
    $i8x8 ->setval($r,$c,$inv8x8[$r][$c]);
    $id8x8->setval($r,$c,$identity8x8[$r][$c]);
  }
}

$r8x8=$m8x8->multiply($i8x8);

print "Matrix 1:\n";
for $r (0..7) {
  print "[ ";
  for $c (0..7) {
    printf "%02x ", $m8x8->getval($r,$c);
  }
  print " ]\n";
}
print "Times:\n";
for $r (0..7) {
  print "[ ";
  for $c (0..7) {
    printf "%02x ", $i8x8->getval($r,$c);
  }
  print " ]\n";
}

print "Result:\n";
for $r (0..7) {
  print "[ ";
  for $c (0..7) {
    printf "%02x ", $r8x8->getval($r,$c);
  }
  print " ]\n";
}

$r8x8=$i8x8->multiply($m8x8);
print "Multiply the other way:\n";
for $r (0..7) {
  print "[ ";
  for $c (0..7) {
    printf "%02x ", $r8x8->getval($r,$c);
  }
  print " ]\n";
}

# Now use the new invert routine...
print "Calling invert on matrix:\n";
$r8x8=undef;
$r8x8=$m8x8->invert;
for $r (0..7) {
  print "[ ";
  for $c (0..7) {
    printf "%02x ", $r8x8->getval($r,$c);
  }
  print " ]\n";
}

