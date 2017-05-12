use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;

use File::pushd qw(pushd);

my $zilla = Builder->from_config(
    {dist_root => 'dzil-tester/DZT'},
    {
        add_files => {
            'source/dist.ini' => dist_ini(
                {
                    name             => 'DZT-Sample',
                    abstract         => 'Sample DZ Dist',
                    author           => 'Name Lastname <example@example.org>',
                    license          => 'GPL_3',
                    copyright_holder => 'Name Lastname',
                    version          => '0.1'
                },
                'GatherDir',
                'MakeMaker',
                [
                    'LaunchpadPPA' =>
                      {ppa => 'test', debuild_args => '-S -sa -us -uc', dput_args => '--simulate --unchecked'}
                ]
            )
        }
    }
);

my $pushd = pushd($zilla->tempdir->subdir('source'));

$zilla->release;

ok(scalar(grep {/^\Q[LaunchpadPPA]   Simulated upload.\E$/} @{$zilla->log_messages}), 'Checking uploaded status');

undef($pushd);

done_testing;
