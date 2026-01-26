use strict;
use warnings;

use Test2::V0;

use Test::File::ShareDir 0.3.0
    -share => {
        -dist   => {
            'My-Dist'       => 't/share',
            'My-Other-Dist' => 't/share_non_bundle',
        }
};

use File::ShareDir::Tarball qw/ dist_dir /;

# to check if memoization works
my $times_run = 0;
{
    no warnings 'redefine';
    sub Archive::Tar::list_files { $times_run++; return () }
}

my $dir = dist_dir('My-Dist');

subtest 'memoization' => sub {

    is $times_run => 1, 'first read, no memoization';

    dist_dir('My-Dist');

    is $times_run => 1, 'second read, memoization';
};

ok -f "$dir/foo", 'foo';
ok -f "$dir/bar", 'bar';

is dist_dir('My-Dist') => $dir, "reuse same directory";

open my $fh, '<', dist_dir('My-Other-Dist') . '/foo';

is <$fh> => "foo\n", 'no bundle? no problem';

done_testing();
