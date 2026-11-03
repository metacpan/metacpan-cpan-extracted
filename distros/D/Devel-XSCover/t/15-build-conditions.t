use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Build ();

plan skip_all => 'shell scripts stand in for compilers here' if $^O eq 'MSWin32';

my $bin = File::Temp->newdir;
my $gcc14 = XSCoverTest::fake_script($bin, 'gcc-14', 'echo "gcc (GCC) 14.2.1 20240910"');
my $gcc13 = XSCoverTest::fake_script($bin, 'gcc-13', 'echo "gcc (GCC) 13.3.0"');
my $clang = XSCoverTest::fake_script($bin, 'clang', 'echo "Apple clang version 21.0.0 (clang-2100.1.1.101)"');

my $b = Devel::XSCover::Build->new(cc => $gcc14);
is($b->conditions, 1, 'gcc 14 gets condition coverage');
like(($b->flags)[0], qr/ -fcondition-coverage$/, 'and the flag on OPTIMIZE');
$b = Devel::XSCover::Build->new(cc => $gcc13);
is($b->conditions, 0, 'gcc 13 does not');
unlike(($b->flags)[0], qr/condition/, 'no flag');
$b = Devel::XSCover::Build->new(cc => $clang);
is($b->conditions, 0, 'nor clang');
is(Devel::XSCover::Build->new(cc => $clang, conditions => 1)->conditions, 1, 'unless asked');
is(Devel::XSCover::Build->new(cc => $gcc14, conditions => 0)->conditions, 0, 'and gcc 14 can be told not to');

done_testing;
