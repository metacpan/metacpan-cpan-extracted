use strict;
use warnings;
use File::Object;
use Test::More;

use File::Find::Rule;
use File::Find::Rule::ConflictMarker;

my $test_dir = File::Object->new->dir('test_dir')->set;

is_deeply(
    [ sort File::Find::Rule->conflict_marker->relative->in($test_dir->s) ],
    [qw/
        base.txt
        conflicting.txt
        devider.txt
        source.txt
        target.txt
    /]
);

done_testing;
