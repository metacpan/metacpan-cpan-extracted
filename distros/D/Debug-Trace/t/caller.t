# -*-perl-*-

#########################

use Test;
BEGIN { plan tests => 2 };

# We need to catch the output for verification.
BEGIN { $ENV{PERL5DEBUGTRACE} = ":warn" }

use Debug::Trace qw(x1 :nocaller x2 :caller x3 :nocaller x4);
ok(1); # If we made it this far, we're ok.

#########################

my $l1 = __LINE__ + 1;
sub x1 { x2(qw(a b c)) }
my $l2 = __LINE__ + 1;
sub x2 { x3(qw(x y z)) }
my $l3 = __LINE__ + 1;
sub x3 { x4(qw(1 2 3)) }
my $l4 = __LINE__ + 1;
sub x4 { "foo" }

# warn() interceptor.
my $msg;
$SIG{__WARN__} = sub { $msg .= "@_" };

my $fl;
$msg = ""; $fl = __LINE__ + 1;
x1("blah");
ok($msg,<<EOD);
TRACE:	main::x1("blah") called at @{[__FILE__]} line $fl package main
TRACE:	main::x2("a","b","c")
TRACE:	main::x3("x","y","z") called at @{[__FILE__]} line $l2 sub main::x2
TRACE:	main::x4(1,2,3)
TRACE:	main::x4() returned
TRACE:	main::x3() returned
TRACE:	main::x2() returned
TRACE:	main::x1() returned
EOD
