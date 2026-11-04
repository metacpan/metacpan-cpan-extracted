use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Build ();

plan skip_all => 'shell scripts stand in for xcrun here' if $^O eq 'MSWin32';

my $tools = File::Temp->newdir;
my $clang = XSCoverTest::fake_script($tools, 'clang', 'echo "Apple clang version 21.0.0 (clang-2100.1.1.101)"');
my $found = XSCoverTest::fake_script($tools, 'llvm-cov', 'echo "LLVM version 21.0.0"');
my $plain = File::Spec->catfile($tools, 'llvm-cov-plain');
open my $fh, '>', $plain or die "$plain: $!";
close $fh;
chmod 0644, $plain;
my $asked = File::Spec->catfile($tools, 'asked');

my $bin = File::Temp->newdir;
local $ENV{PATH} = "$bin";

{
    local $^O = 'darwin';
    XSCoverTest::fake_script($bin, 'xcrun', ": > '$asked'\ntrue");
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        ['gcov'], 'clang with no tool on the path and nothing from xcrun is left with plain gcov');
    ok(-f $asked, 'xcrun was asked');

    XSCoverTest::fake_script($bin, 'xcrun', "echo '$plain'");
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        ['gcov'], 'a find that is not executable is no tool');

    XSCoverTest::fake_script($bin, 'xcrun', "echo '$found'");
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        [$found, 'gcov'], 'the llvm-cov xcrun finds runs as llvm-cov gcov');
}

{
    local $^O = 'linux';
    unlink $asked;
    XSCoverTest::fake_script($bin, 'xcrun', ": > '$asked'\necho '$found'");
    is_deeply(Devel::XSCover::Build->new(cc => $clang)->gcov_command,
        ['gcov'], 'off macOS the fallback is plain gcov');
    ok(!-e $asked, 'and xcrun is never asked');
}

done_testing;
