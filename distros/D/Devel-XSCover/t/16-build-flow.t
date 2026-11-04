use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Build ();

plan skip_all => 'fake scripts need a shell' if $^O eq 'MSWin32';
my $dir = File::Temp->newdir;
my %banner = (
    llvm   => 'Apple LLVM version 21.0.0',
    gcc14  => 'gcov (GCC) 14.4.0',
    debian => 'gcov (Debian 12.2.0-14) 12.2.0',
    gcc8   => 'gcov (GCC) 8.5.0',
    odd    => 'something else entirely',
);
my %script = map { $_ => XSCoverTest::fake_script($dir, "gcov-$_", "echo '$banner{$_}'") } keys %banner;

is(Devel::XSCover::Build->new(gcov => $script{llvm}, silent => 1)->flow_kind, 'llvm', 'an LLVM gcov has the dump');
is(Devel::XSCover::Build->new(gcov => $script{gcc14}, silent => 1)->flow_kind, 'gcc', 'gcc 14 has the json');
is(Devel::XSCover::Build->new(gcov => $script{debian}, silent => 1)->flow_kind, 'gcc', 'a distribution banner names its version after the vendor');
is(Devel::XSCover::Build->new(gcov => $script{gcc8}, silent => 1)->flow_kind, '', 'gcc 8 has neither');
is(Devel::XSCover::Build->new(gcov => $script{odd}, silent => 1)->flow_kind, '', 'nor does an unknown tool');
is(Devel::XSCover::Build->new(gcov => $script{gcc8}, flow => 'gcc', silent => 1)->flow_kind, 'gcc', 'the option overrides the detection');
my $b = Devel::XSCover::Build->new(gcov => $script{llvm}, silent => 1);
$b->flow_kind;
is($b->flow_kind, 'llvm', 'and the answer is kept');

done_testing;
