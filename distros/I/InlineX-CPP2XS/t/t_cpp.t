use warnings;
use strict;
use InlineX::CPP2XS qw(cpp2xs);

print "1..10\n";

cpp2xs('Math::Geometry::Planar::GPC::Inherit', 'main');

my $ok = 1;
my @rd1;
my $count = 0;


if($ok) {
  if(!open(RD1, '<', 'Inherit.xs')) {
    warn "unable to open Inherit.xs for reading: $!\n";
    print "not ok 1\n";
    $ok = 0;
  }
}


if($ok) {
  @rd1 = <RD1>;
}

close RD1 or warn "Couldn't close Inherit.xs\n";

if($ok) {
  for(@rd1) {
     $count++ if $_ =~ /#include <iostream/;		#2
     $count++ if $_ =~ /class Foo/;			#1
     $count++ if $_ =~ /protected:/;			#1
     $count++ if $_ =~ /class Bar/;			#1
     $count++ if $_ =~ /PACKAGE/;			#3
     $count++ if $_ =~ /Foo::DESTROY/;			#1
     $count++ if $_ =~ /Bar::DESTROY/;			#1
     $count++ if $_ =~ /PROTOTYPES: DISABLE/;		#3
     $count++ if $_ =~ /BOOT/;				#1
     $count++ if $_ =~ /PREINIT:/;			#2
     $count++ if $_ =~ /PPCODE:/;			#2
     $count++ if $_ =~ /set_secret/;			#6
  }
}

if($ok && ($count != 24)) {
  warn "Inherit.xs not as expected\n";
  print "not ok 1\n";
}

elsif($ok) {print "ok 1\n"}

if(!unlink('Inherit.xs')) { warn "Couldn't unlink Inherit.xs\n"}

$ok = 1;

###########################################################################

$count = 0;

if(!open(RD1, '<', 'INLINE.h')) {
  warn "unable to open INLINE.h for reading: $!\n";
  print "not ok 2\n";
  $ok = 0;
}


if($ok) {
  @rd1 = <RD1>;
}

if($ok) {
  for(@rd1) {
     $count++ if $_ =~ /dXSARGS/;	#1
     $count++ if $_ =~ /items/;		#2
     $count++ if $_ =~ /ST\(x\)/;	#1
     $count++ if $_ =~ /sp = mark/;	#1
     $count++ if $_ =~ /XPUSHs\(x\)/;	#1
     $count++ if $_ =~ /PUTBACK/;	#1
     $count++ if $_ =~ /XSRETURN\(x\)/;	#1
     $count++ if $_ =~ /XSRETURN\(0\)/;	#1
  }
}

if($ok && ($count != 9)) {
  warn "INLINE.h not as expected\n";
  print "not ok 2\n";
}

elsif($ok) {print "ok 2\n"}

close(RD1) or warn "Unable to close INLINE.h after reading: $!\n";
if(!unlink('INLINE.h')) { warn "Couldn't unlink INLINE.h\n"}

#############################################################################

$ok = 1;
$count = 0;

if(!open(RD1, "CPP.map")) {
  warn "unable to open CPP.map for reading: $!\n";
  print "not ok 3\n";
  $ok = 0;
}


if($ok) {
  @rd1 = <RD1>;
}

if($ok) {
  for(@rd1) {
     $count++ if $_ =~ /O_Inline_CPP_Class/;	#4
     $count++ if $_ =~ /TYPEMAP/;		#1
     $count++ if $_ =~ /OUTPUT/;		#1
     $count++ if $_ =~ /INPUT/;			#1
     $count++ if $_ =~ /sv_isobject/;		#1
     $count++ if $_ =~ /XSRETURN_UNDEF/;	#1
  }
}

if($ok && ($count != 9)) {
  warn "CPP.map not as expected\n";
  print "not ok 3\n";
}

elsif($ok) {print "ok 3\n"}

close(RD1) or warn "Unable to close CPP.map after reading: $!\n";
if(!unlink('CPP.map')) { warn "Couldn't unlink CPP.map\n"}


eval{cpp2xs('Math::Geometry::Planar::GPC::Inherit', 'main', '.', '');};

if($@ =~ /Fourth arg to cpp2xs/) {print "ok 4\n"}
else {print "not ok 4\n"}

eval{cpp2xs('Math::Geometry::Planar::GPC::Inherit', 'main', {'TYPEMAPS' => ['/foo/non/existent/typemap.txt']});};

if($@ =~ /Couldn't locate the typemap \/foo\/non\/existent\/typemap.txt/) {print "ok 5\n"}
else {print "not ok 5\n"}

eval{cpp2xs('Math::Geometry::Planar::GPC::Polygon', 'Math::Geometry::Planar::GPC::Polygon', '/foo/non/existent/typemap.txt');};

if($@ =~ /\/foo\/non\/existent\/typemap\.txt is not a valid directory/) {print "ok 6\n"}
else {print "not ok 6\n"}

eval{cpp2xs('Math::Geometry::Planar::GPC::Inherit', 'Math::Geometry::Planar::GPC::Inherit', {'typemaps' => ['/foo/non/existent/typemap.txt']});};

if($@ =~ /is an invalid config option/) {print "ok 7\n"}
else {print "not ok 7\n"}

eval{cpp2xs('Math::Geometry::Planar::GPC::Inherit', 'main', {'TYPEMAPS' => ['foo']}, {'TYPEMAPS' => ['foo']});};

if($@ =~ /Incorrect usage \- there should be no arguments/) {print "ok 8\n"}
else {print "not ok 8\n"}

eval{cpp2xs('MyMod', 'main', {'CODE' => 'void foo(){}', 'SRC_LOCATION' => 'C:/file.c'});};

if($@ =~ /You can provide either CODE/) {print "ok 9\n"}
else {
  warn $@, "\n";
  print "not ok 9\n";
}

eval{cpp2xs('MyMod', 'main', {'SRC_LOCATION' => './non_existent.crap'});};

if($@ =~ /Can't open/) {print "ok 10\n"}
else {
  warn $@, "\n";
  print "not ok 10\n";
}
