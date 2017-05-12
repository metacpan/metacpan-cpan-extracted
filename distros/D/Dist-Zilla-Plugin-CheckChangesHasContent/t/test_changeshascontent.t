use strict;
use warnings;

use Test::More 0.88;
use Dist::Zilla::Tester;
use Test::Harness;
use Path::Tiny;
use Cwd 'getcwd';
use Capture::Tiny qw/capture/;

my $test_file = path(qw(xt release changes_has_content.t));
my $root = 'corpus/DZ_Test_ChangesHasContent';

sub capture_test_results($)
{
    my $build_dir = shift;

    my $test_file_full = path($build_dir, $test_file)->stringify;
    my $cwd = getcwd;
    chdir $build_dir;

    my ($output, $error, @results) = capture {
      # I'd use TAP::Parser here, except the docs are horrid.
       Test::Harness::execute_tests(tests => [$test_file_full]);
    };

    chdir $cwd;
    return @results, $output;
}

SKIP:
{
    skip '[NextRelease] 6.005 checks for missing Changes file before tests are run', 1
        if eval { require Dist::Zilla::Plugin::NextRelease; Dist::Zilla::Plugin::NextRelease->VERSION('6.005') };

    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => $root },
    );
    ok($tzil, "created test dist with no Changes file");

    $tzil->build_in;
    my ($total, $failed) = capture_test_results($tzil->built_in);
    is($total->{max}, 2, 'two tests planned');
    is($total->{sub_skipped}, 1, 'one test skipped');
    my ($test_name) = keys %$failed;
    is($failed->{$test_name}{canon}, 1, 'the first test failed (Changes file does not exist)');
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => $root },
        {
            add_files => {
                'source/Changes' => <<'END',
Changes

{{$NEXT}}

END
            },
        },
    );
    ok( $tzil, "created test dist with stub Changes file");

    $tzil->build_in;
    my ($total, $failed) = capture_test_results($tzil->built_in);
    is($total->{max}, 2, 'two tests planned');
    is($total->{sub_skipped}, 0, 'no tests skipped');
    is($total->{ok}, 1, 'one test passed');
    my ($test_name) = keys %$failed;
    is($failed->{$test_name}{canon}, 2, 'the second test failed (Changes file has no content)');
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => $root },
        {
            add_files => {
                'source/Changes' => <<'END',
Changes

{{$NEXT}}

1.22    2010-05-12 00:33:53 EST5EDT

  - not really released

END
            },
        },
    );
    ok($tzil, "created test dist with no new Changes");

    $tzil->build_in;
    my ($total, $failed) = capture_test_results($tzil->built_in);
    is($total->{max}, 2, 'two tests planned');
    is($total->{sub_skipped}, 0, 'no tests skipped');
    my ($test_name) = keys %$failed;
    is($failed->{$test_name}{canon}, 2, 'the second test failed (Changes file has no content)');
}

foreach my $version ( '1.23', '1.23-TRIAL' ){
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => $root },
        {
            add_files => {
                'source/Changes' => <<"END",
Changes

$version

  - this is a change note, I promise

1.22    2010-05-12 00:33:53 EST5EDT

  - not really released

END
            },
        },
    );
    ok($tzil, "created test dist with a new Changes entry");

    $tzil->build_in;
    my ($total, $failed) = capture_test_results($tzil->built_in);
    is($total->{max}, 2, 'two tests planned');
    is($total->{sub_skipped}, 0, 'no tests skipped');
    is(scalar(keys %$failed), 0, 'no tests failed');
}

done_testing;
