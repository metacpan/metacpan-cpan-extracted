use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Build ();

plan skip_all => 'the path lookup wants an executable bit' if $^O eq 'MSWin32';

my $bin  = File::Temp->newdir;
my $gcov = XSCoverTest::fake_script($bin, 'gcov', 'true');
local $ENV{PATH} = "$bin";

{
    no warnings 'redefine';
    local *Devel::XSCover::Build::_capture = sub { undef };

    is_deeply(Devel::XSCover::Build->new(cc => 'cc')->compiler,
        { cc => 'cc', name => 'unknown', major => 0, banner => '' },
        'a compiler that cannot be run at all is unknown with an empty banner');

    {
        local $^O = 'linux';
        is_deeply(Devel::XSCover::Build->new(compiler => { name => 'clang', major => 21 })->gcov_command,
            [$gcov], 'clang keeps the gcov on the path when it cannot be asked its version');
    }
    {
        local $^O = 'darwin';
        my $empty = File::Temp->newdir;
        local $ENV{PATH} = "$empty";
        is_deeply(Devel::XSCover::Build->new(compiler => { name => 'clang', major => 21 })->gcov_command,
            ['gcov'], 'and falls to plain gcov when xcrun cannot be run either');
    }

    is(Devel::XSCover::Build->new(gcov => $gcov)->flow_kind, '', 'a gcov that cannot be run has no flow graph');
}

done_testing;
