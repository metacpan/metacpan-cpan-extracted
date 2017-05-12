use Test::More tests => 2;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

profile_code(<<'END', "make sure constants are being included in profiles");
use constant CONSTANT1 => 1;
use constant CONSTANT2 => [ 'foo', 'bar' ];
sub CONSTANT3 () { '...' }
sub NONCONSTANT1 { $_++ }
sub NONCONSTANT2 ($) { "fooey" }
sub NONCONSTANT3 { 1; }
CONSTANT1();
CONSTANT2();
CONSTANT3();
$_ = 1;
NONCONSTANT1();
NONCONSTANT2($_);
$_ = NONCONSTANT3();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::NONCONSTANT1
main::NONCONSTANT2
main::NONCONSTANT3
END
