use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;

use Git::Wrapper;
use File::pushd qw(pushd);

my ($zilla, $pushd);

sub init_zilla {
    undef($pushd);

    $zilla = Builder->from_config(
        {dist_root => 'dzil-tester/DZT'},
        {
            add_files => {
                'source/dist.ini' => dist_ini(
                    {
                        name             => 'DZT-Sample',
                        abstract         => 'Sample DZ Dist',
                        author           => 'Name Lastname <example@example.org>',
                        license          => 'GPL_2',
                        copyright_holder => 'Name Lastname',
                    },
                    ['@QBit' => {from_test => 1, ppa => 'test'}],
                ),
                'source/.gitignore' => "DZT-Sample-*\nDZP-git*\n",
            }
        }
    );

    $pushd = pushd($zilla->tempdir->subdir('source'));

    print "# ";
    system "git init";

    my $git = Git::Wrapper->new('.');
    $git->config('user.name'  => 'dzp-git test');
    $git->config('user.email' => 'dzp-git@test');

    $git->add(-f => '.gitignore', 'dist.ini', 'lib/DZT.pm', 'debian/');
    $git->commit({message => 'Initial commit'});
}

init_zilla();

$zilla->release;

ok(scalar(grep {/Fake release happening/} @{$zilla->log_messages}), 'Checking uploaded status');

is(`git tag`, "0.001\n", 'Checking tag');

undef($pushd);

done_testing;
