use strict;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';
use Path::Tiny;
use Test::DZil;
use Test::Differences;

use Dist::Zilla::Plugin::PodnameFromClassname;

my $tzil = Builder->from_config(
    {   dist_root => 't/corpus/' },
    {   add_files => {
            'source/lib/TestFor/PodnameFromClassname.pm' => path('t/corpus/lib/TestFor/PodnameFromClassname.pm')->slurp,
            'source/dist.ini' => simple_ini(
                ['GatherDir'],
                ['PodnameFromClassname'],
            ),
        },
    },
);

$tzil->build;

my $expected_output = q{use 5.10.0;

our $VERSION = '0.0101';
# PODNAME: TestFor::PodnameFromClassname
class TestFor::PodnameFromClassname {

}
};

my $generated_file = $tzil->slurp_file('build/lib/TestFor/PodnameFromClassname.pm');

eq_or_diff $generated_file, $expected_output, 'Correctly inserted PODNAME';

done_testing;
