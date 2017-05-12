use warnings;
use strict;
use InlineX::CPP2XS qw(cpp2xs);

print "1..2\n";

my $code = "simple_double  simple(simple_double);\nextra_simple_double x_simple(extra_simple_double);\n\n";

my %config_opts = (
                  'AUTOWRAP' => 1,
                  'AUTO_INCLUDE' => '#include <simple.h>' . "\n" .'#include "src/extra_simple.h"',
                  'TYPEMAPS' => ['src/simple_typemap.txt'],
                  'INC' => '-Isrc',
                  'CODE' => $code,
                  );

cpp2xs('testc', 'testc', '.', \%config_opts);

my $ok = 1;
my $count = 0;
my @rd1;


if($ok) {
  if(!open(RD1, '<', 'testc.xs')) {
    warn "unable to open testc.xs for reading: $!\n";
    print "not ok 1\n";
    $ok = 0;
  }
}


if($ok) {
  @rd1 = <RD1>;
}


if($ok) {
  for(@rd1) {
     $count++ if $_ =~ /#ifndef bool/;				#1
     $count++ if $_ =~ /#include <iostream/;			#2
     $count++ if $_ =~ /#endif/;				#2
     $count++ if $_ =~ /extern/;				#1
     $count++ if $_ =~ /#include \"EXTERN\.h\"/;		#1
     $count++ if $_ =~ /#include \"perl\.h\"/;			#1
     $count++ if $_ =~ /#include \"XSUB\.h\"/;			#1
     $count++ if $_ =~ /#include \"INLINE\.h\"/;		#1
     $count++ if $_ =~ /#ifdef bool/;				#1
     $count++ if $_ =~ /#undef bool/;				#1
     $count++ if $_ =~ /#include <simple\.h>/;			#1
     $count++ if $_ =~ /#include \"src\/extra_simple\.h\"/;	#1
     $count++ if $_ =~ /simple_double/;				#6
     $count++ if $_ =~ /PACKAGE/;				#1
     $count++ if $_ =~ /PROTOTYPES: DISABLE/;			#1
     $count++ if $_ =~ /dummy1/;				#4
  }
}

if($ok && ($count != 26)) {
  warn "testc.xs not as expected\n";
  print "not ok 1\n";
}

elsif($ok) {print "ok 1\n"}

close(RD1) or warn "Unable to close testc.xs after reading: $!\n";
if(!unlink('testc.xs')) { warn "Couldn't unlink testc.xs\n"}

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


