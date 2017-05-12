use warnings;
use strict;
use InlineX::C2XS qw(c2xs);

print "1..10\n";

my ($ok, $ok2) = (1, 1);
my @rd1;
my @rd2;

c2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon',
    {PREFIX => 'remove_', BOOT => 'printf("Hi from bootstrap\n");'});

if(!rename('Polygon.xs', 'Polygon.txt')) {
  warn "couldn't rename Polygon.xs\n";
  print "not ok 1\n";
  $ok = 0;
}

if($ok) {
  if(!open(RD1, "Polygon.txt")) {
    warn "unable to open Polygon.txt for reading: $!\n";
    print "not ok 1\n";
    $ok = 0;
  }
}

if($ok) {
  if(!open(RD2, "expected_c.txt")) {
    warn "unable to open expected_c.txt for reading: $!\n";
    print "not ok 1\n";
    $ok = 0;
  }
}

if($ok) {
  @rd1 = <RD1>;
  @rd2 = <RD2>;
}

if($ok) {
  if(scalar(@rd1) != scalar(@rd2)) {
    warn "Polygon.txt does not have the expected number of lines\n";
    print "not ok 1\n";
    $ok = 0;
  }
}

if($ok) {
  for(my $i = 0; $i < scalar(@rd1); $i++) {
       # Try to take care of platform/machine-specific issues
       # regarding line endings and whitespace.
       $rd1[$i] =~ s/\s//g;
       $rd2[$i] =~ s/\s//g;
       #$rd1[$i] =~ s/\r//g;
       #$rd2[$i] =~ s/\r//g;

     if($rd1[$i] ne $rd2[$i]) {
       warn "At line ", $i + 1, ":\n     GOT:", $rd1[$i], "*\nEXPECTED:", $rd2[$i], "*\n";
       $ok2 = 0;
       last;
     }
  }
}

if(!$ok2) {
  warn "Polygon.txt does not match expected_c.txt\n";
  print "not ok 1\n";
}

elsif($ok) {print "ok 1\n"}

close(RD1) or warn "Unable to close Polygon.txt after reading: $!\n";
close(RD2) or warn "Unable to close expected_c.txt after reading: $!\n";
if(!unlink('Polygon.txt')) { warn "Couldn't unlink Polygon.txt\n"}

($ok, $ok2) = (1, 1);

###########################################################################

if(!open(RD1, "INLINE.h")) {
  warn "unable to open INLINE.h for reading: $!\n";
  print "not ok 2\n";
  $ok = 0;
}

if($ok) {
  if(!open(RD2, "expected.h")) {
    warn "unable to open expected.h for reading: $!\n";
    print "not ok 2\n";
    $ok = 0;
  }
}

if($ok) {
  @rd1 = <RD1>;
  @rd2 = <RD2>;
}

if($ok) {
  if(scalar(@rd1) != scalar(@rd2)) {
    warn "INLINE.h does not have the expected number of lines\n";
    print "not ok 2\n";
    $ok = 0;
  }
}

if($ok) {
  for(my $i = 0; $i < scalar(@rd1); $i++) {
       # Try to take care of platform/machine-specific issues
       # regarding line endings and whitespace.
       $rd1[$i] =~ s/\s//g;
       $rd2[$i] =~ s/\s//g;
       #$rd1[$i] =~ s/\r//g;
       #$rd2[$i] =~ s/\r//g;

     if($rd1[$i] ne $rd2[$i]) {
       warn "At line ", $i + 1, ":\n     GOT:", $rd1[$i], "*\nEXPECTED:", $rd2[$i], "*\n";
       $ok2 = 0;
       last;
     }
  }
}

if(!$ok2) {
  warn "INLINE.h does not match expected.h\n";
  print "not ok 2\n";
}

elsif($ok) {print "ok 2\n"}

close(RD1) or warn "Unable to close INLINE.h after reading: $!\n";
close(RD2) or warn "Unable to close expected.h after reading: $!\n";
if(!unlink('INLINE.h')) { warn "Couldn't unlink INLINE.h\n"}

eval{c2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon', '.', '');};

if($@ =~ /Fourth arg to c2xs/) {print "ok 3\n"}
else {print "not ok 3\n"}

eval{c2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon', '.', '');};

if($@ =~ /Fourth arg to c2xs/) {print "ok 4\n"}
else {print "not ok 4\n"}

eval{c2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon', {'TYPEMAPS' => ['/foo/non/existent/typemap.txt']});};

if($@ =~ /Couldn't locate the typemap \/foo\/non\/existent\/typemap\.txt/) {print "ok 5\n"}
else {print "not ok 5\n"}

eval{c2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon', '/foo/non/existent/typemap.txt');};

if($@ =~ /\/foo\/non\/existent\/typemap\.txt is not a valid directory/) {print "ok 6\n"}
else {print "not ok 6\n"}

eval{c2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon', {'typemaps' => ['/foo/non/existent/typemap.txt']});};

if($@ =~ /is an invalid config option/) {print "ok 7\n"}
else {print "not ok 7\n"}

eval{c2xs('Math::Geometry::Planar::GPC::Polygon', 'main', {'TYPEMAPS' => ['foo']}, {'TYPEMAPS' => ['foo']});};

if($@ =~ /Incorrect usage \- there should be no arguments/) {print "ok 8\n"}
else {print "not ok 8\n"}

eval{c2xs('MyMod', 'main', {'CODE' => 'void foo(){}', 'SRC_LOCATION' => 'C:/file.c'});};

if($@ =~ /You can provide either CODE/) {print "ok 9\n"}
else {
  warn $@, "\n";
  print "not ok 9\n";
}

eval{c2xs('MyMod', 'main', {'SRC_LOCATION' => './non_existent.crap'});};

if($@ =~ /Can't open/) {print "ok 10\n"}
else {
  warn $@, "\n";
  print "not ok 10\n";
}
