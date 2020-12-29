use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Dist::Zilla::Plugin::CheckForUnwantedFiles;
use Test::Exception;
use Test::DZil;
use Path::Tiny;
ok 1, 'Loaded';

my $tests = [
    {
        unwanted_paths => [qw//],
        add_paths => [qw{
            source/unwanted.file
        }],
        check => sub {
            my $tzil = shift;
            lives_ok sub { $tzil->build }, 'No unwanted paths';
        },
    },
    {
        unwanted_paths => [qw/unwanted.file/],
        add_paths => [qw{
            source/unwanted.file
        }],
        check => sub {
            my $tzil = shift;
            throws_ok sub { $tzil->build }, qr/\[CheckForUnwantedFiles\] Build aborted./, 'Fail with root file';
        },
    },
    {
        unwanted_paths => [qw{unwanteddir/}],
        add_paths => [qw{
            source/unwanteddir/unwanted.file
        }],
        check => sub {
            my $tzil = shift;
            throws_ok sub { $tzil->build }, qr/\[CheckForUnwantedFiles\] Build aborted./, 'Fail with unwanted directory';
        },
    },
    {
        unwanted_paths => [qw{unwanteddir/subdir}],
        add_paths => [qw{
            source/unwanteddir/subdir/unwanted.file
        }],
        check => sub {
            my $tzil = shift;
            throws_ok sub { $tzil->build }, qr/\[CheckForUnwantedFiles\] Build aborted./, 'Fail with unwanted sub directory';
        },
    },
];

for my $test (@{ $tests }) {
    my $tzil = make_tzil($test->{'unwanted_paths'}, $test->{'add_paths'});
    $test->{'check'}($tzil);
}

done_testing;

sub make_tzil {
    my $unwanted_paths = shift;

    # Add some contents to the files
    my %add_paths = map { $_ => 'contents' } @{ shift() };
    my $ini = simple_ini(
        { version => '0.0002' },
        [ 'CheckForUnwantedFiles', {
            unwanted_file => $unwanted_paths,
        }],
        qw/
            GatherDir
            FakeRelease
        /,
    );

    my $tzil = Builder->from_config(
        {   dist_root => 't/corpus' },
        {
            add_files => {
                'source/dist.ini' => $ini,
                %add_paths,
            },
        },
    );
    $tzil->chrome->logger->set_debug(1);

    return $tzil;
}
