use strict; use warnings;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

print "1..6\n";

my $ret = do "$t/proto1.p";

if(!defined($ret) && $@ =~ /^Too many arguments/) {print "ok 1\n"}
else {
  warn "\n$ret: $ret\n\$\@: $@\n";
  print "not ok 1\n";
}

$ret = do "$t/proto2.p";

if(!defined($ret) && $@ =~ /^Too many arguments/) {print "ok 2\n"}
else {
  warn "\n$ret: $ret\n\$\@: $@\n";
  print "not ok 2\n";
}

$ret = do "$t/proto3.p";

if(!defined($ret) && $@ =~ /^Usage: PROTO3::foo/) {print "ok 3\n"}
else {
  warn "\n$ret: $ret\n\$\@: $@\n";
  print "not ok 3\n";
}

$ret = do "$t/proto4.p";

if(!defined($ret) && $@ =~ /^Usage: PROTO4::foo/) {print "ok 4\n"}
else {
  warn "\n$ret: $ret\n\$\@: $@\n";
  print "not ok 4\n";
}

$ret = do "$t/proto5.p";

if(!defined($ret) && $@ =~ /^PROTOTYPES can be only either 'ENABLE' or 'DISABLE'/) {print "ok 5\n"}
else {
  warn "\n$ret: $ret\n\$\@: $@\n";
  print "not ok 5\n";
}

$ret = do "$t/proto6.p";

if(!defined($ret) && $@ =~ /^PROTOTYPE configure arg must specify a hash reference/) {print "ok 6\n"}
else {
  warn "\n$ret: $ret\n\$\@: $@\n";
  print "not ok 6\n";
}
