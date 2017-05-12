# Testing the :maxlen modifier		-*-perl-*-

#########################

use Test;
BEGIN { plan tests => 3 };

# We need to catch the output for verification.
BEGIN { $ENV{PERL5DEBUGTRACE} = ":warn" }

use Debug::Trace qw(:maxlen(56) x1 :nomaxlen x2);
ok(1); # If we made it this far, we're ok.

#########################

sub x1 { "foo" }
sub x2 { "bar" }

# warn() interceptor.
my $msg;
$SIG{__WARN__} = sub { $msg .= "@_" };

my $fl;
$msg = ""; $fl = __LINE__ + 1;
my @foo = x1(qw(abcde abcdef abcdefg));
ok($msg,<<EOD);
TRACE:	main::x1("abcde","abcdef","abcdefg") called at...
TRACE:	main::x1() returned: ("foo")
EOD

$msg = ""; $fl = __LINE__ + 1;
my $bar = x2(qw(abcde abcdef abcdefg));
ok($msg,<<EOD);
TRACE:	main::x2("abcde","abcdef","abcdefg") called at @{[__FILE__]} line $fl package main
TRACE:	main::x2() returned: "bar"
EOD
