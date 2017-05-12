# Basic tests for Debug::Trace			-*-perl-*-

#########################

use Test;
BEGIN { plan tests => 6 };

# We need to catch the output for verification.
BEGIN { $ENV{PERL5DEBUGTRACE} = ":warn" }

use Debug::Trace qw(foo1 foo2);
ok(1); # If we made it this far, we're ok.

#########################

sub foo1 {
    wantarray ? (aa => "bb") : 42;
}
sub foo2 {
    wantarray ? 42 : { aa => "bb" };
}

# warn() interceptor.
my $msg;
$SIG{__WARN__} = sub { $msg .= "@_" };

my $fl;				# file/line
$msg = ""; $fl = join(" line ", __FILE__, __LINE__+1);
foo1("blah");
ok($msg,<<EOD);
TRACE:	main::foo1("blah") called at $fl package main
TRACE:	main::foo1() returned
EOD

$msg = ""; $fl = join(" line ", __FILE__, __LINE__+1);
my @a = foo1(["blah","blech foo"]);
ok($msg,<<EOD);
TRACE:	main::foo1(["blah","blech foo"]) called at $fl package main
TRACE:	main::foo1() returned: ("aa","bb")
EOD

$msg = ""; $fl = join(" line ", __FILE__, __LINE__+1);
foo2(foo1(["blah" => "blech foo"], { "blah","blech foo" }));
ok($msg,<<EOD);
TRACE:	main::foo1(["blah","blech foo"],{blah => "blech foo"}) called at $fl package main
TRACE:	main::foo1() returned: ("aa","bb")
TRACE:	main::foo2("aa","bb") called at $fl package main
TRACE:	main::foo2() returned
EOD

$msg = ""; $fl = join(" line ", __FILE__, __LINE__+1);
if ( foo1("blah","blech foo") ) {}
ok($msg,<<EOD);
TRACE:	main::foo1("blah","blech foo") called at $fl package main
TRACE:	main::foo1() returned: 42
EOD

$msg = ""; $fl = join(" line ", __FILE__, __LINE__+1);
sub bar { foo1(1,2,[3,4]) }
bar(3);
ok($msg,<<EOD);
TRACE:	main::foo1(1,2,[3,4]) called at $fl sub main::bar
TRACE:	main::foo1() returned
EOD
