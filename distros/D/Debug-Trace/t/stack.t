# -*-perl-*-

#########################

use Test;
BEGIN { plan tests => 2 };

# We need to catch the output for verification.
BEGIN { $ENV{PERL5DEBUGTRACE} = ":warn" }

use Debug::Trace qw(x1 :stacktrace x2 :nostacktrace x3 :stacktrace x4);
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
$msg =~ s/', '/','/g;		# to match some older Carps
$msg =~ s/", "/","/g;		# to match some newer Carps
my $result = <<EOD;
TRACE:	main::x1("blah") called at @{[__FILE__]} line $fl package main
TRACE:	main::x2("a","b","c") called at @{[__FILE__]} line $l1
	main::x1('blah') called at @{[__FILE__]} line $fl
TRACE:	main::x3("x","y","z") called at @{[__FILE__]} line $l2 sub main::x2
TRACE:	main::x4(1,2,3) called at @{[__FILE__]} line $l3
	main::x3('x','y','z') called at @{[__FILE__]} line $l2
	main::x2('a','b','c') called at @{[__FILE__]} line $l1
	main::x1('blah') called at @{[__FILE__]} line $fl
TRACE:	main::x4() returned
TRACE:	main::x3() returned
TRACE:	main::x2() returned
TRACE:	main::x1() returned
EOD

# Newer Carp have a slightly different longmess output format.
use Carp ();
$result =~ s/\'/"/g if $Carp::VERSION >= 1.32;

ok($msg,$result);
