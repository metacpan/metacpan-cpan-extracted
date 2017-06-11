use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

print "1..5\n";

eval {
 require Inline;
 Inline->import (C =><<'EOC');

 int foo() {
   return 42;
 }

EOC
};

if($@) {
  *foo =\&bar;
}

my $x = foo();

if($x == 42) {print "ok 1\n"}
else {
  warn "\n\$x: $x\n";
  print "not ok 1\n";
}

$x = bar();

if($x == 43) {print "ok 2\n"}
else {
  warn "\n\$x: $x\n";
  print "not ok 2\n";
}

eval {
 require Inline;
 Inline->import(C => Config =>
                #BUILD_NOISY => 1,
                CC => 'missing_compiler');
 Inline->import (C =><<'EOC');

 int fu() {
   return 44;
 }

EOC
};

if($@) {
  *fu =\&fubar;
}

$x = fu();

if($x == 45) {print "ok 3\n"}
else {
  warn "\n\$x: $x\n";
  print "not ok 3\n";
}

$x = fubar();

if($x == 45) {print "ok 4\n"}
else {
  warn "\n\$x: $x\n";
  print "not ok 4\n";
}

if($@ =~ /missing_compiler/) {print "ok 5\n"}
else {
  warn "\n\$\@ not as expected\n";
  print "not ok 5\n";
}

sub bar {
  return 43;
}

sub fubar {
  return 45;
}

