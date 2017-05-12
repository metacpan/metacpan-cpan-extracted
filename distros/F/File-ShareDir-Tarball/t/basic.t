use strict;
use warnings;

use Test::More tests => 4;

use Test::File::ShareDir 0.3.0
    -share => {
        -dist   => { 
            'My-Dist'       => 't/share',
            'My-Other-Dist' => 't/share_non_bundle',
        }
};

use File::ShareDir::Tarball qw/ dist_dir /;

my $dir = dist_dir('My-Dist');

ok -f "$dir/foo", 'foo';
ok -f "$dir/bar", 'bar';

is dist_dir('My-Dist') => $dir, "reuse same directory";

open my $fh, '<', dist_dir('My-Other-Dist') . '/foo';

is <$fh> => "foo\n", 'no bundle? no problem';
