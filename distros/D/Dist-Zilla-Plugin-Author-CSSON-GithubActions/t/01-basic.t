use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/corpus/lib';
use Dist::Zilla::Plugin::Author::CSSON::GithubActions;
use Test::Exception;
use Test::DZil;
use Path::Tiny;
use YAML::XS qw/LoadFile/;

ok 1, 'Loaded';

my $tests = [
    {
        name => '1',
        settings => {},
        check => sub {
            my $tzil = shift;
            my $yaml = shift;
            is_deeply $yaml->{'on'}{'push'}{'branches'}, ['*'], 'Default push branches' or diag explain $yaml;
        },
    },
    {
        settings => {
            clear_on_push_branches => 1,
        },
        check => sub {
            my $tzil = shift;
            my $yaml = shift;
            is_deeply $yaml->{'on'}{'push'}{'branches'}, [], 'Push branches cleared' or diag explain $yaml;
            is_deeply $yaml->{'on'}{'pull_request'}{'branches'}, ['*'], 'PR branches remains as default' or diag explain $yaml;
        }
    },
    {
        settings => {
            clear_on_pull_request_branches => 1,
        },
        check => sub {
            my $tzil = shift;
            my $yaml = shift;
            is_deeply $yaml->{'on'}{'push'}{'branches'}, ['*'], 'Push branches remains as default' or diag explain $yaml;
            is_deeply $yaml->{'on'}{'pull_request'}{'branches'}, [], 'PR branches cleared' or diag explain $yaml;
        }
    },
    {
        settings => {
            on_pull_request_branches => [qw/this that/]
        },
        check => sub {
            my $tzil = shift;
            my $yaml = shift;
            is_deeply $yaml->{'on'}{'pull_request'}{'branches'}, ['*', 'this', 'that'], 'PR branches added' or diag explain $yaml;
        }
    },
    {
        settings => {
            clear_on_pull_request_branches => 1,
            on_pull_request_branches => [qw/this that/]
        },
        check => sub {
            my $tzil = shift;
            my $yaml = shift;
            is_deeply $yaml->{'on'}{'pull_request'}{'branches'}, ['this', 'that'], 'PR branches replaced' or diag explain $yaml;
        }
    },
    {
        settings => {
            run_before => 'apt-get install nano',
        },
        check => sub {
            my $tzil = shift;
            my $yaml = shift;
            is $yaml->{'jobs'}{'perl-job'}{'steps'}[1]{'run'}, 'apt-get install nano', 'Custom run_before parameter' or diag explain $yaml;
            is scalar @{ $yaml->{'jobs'}{'perl-job'}{'steps'} }, 5, 'Correct number of steps after adding a custom step' or diag explain $yaml;
        }
    }
];

for my $test (@{ $tests }) {
    my $tzil = make_tzil($test->{'settings'});
    my $yaml = LoadFile(path($tzil->tempdir)->child('source/.github/workflows/workflow-test.yml'));

    if (exists $test->{'check'}) {
        $test->{'check'}($tzil, $yaml);
    }
}

done_testing;

sub make_tzil {
    my %settings = %{ shift() };
    my $ini = simple_ini(
        { version => '0.0002' },
        [ 'TestForGithubActions', {
            filename => 'workflow-test.yml',
            %settings,
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
                'source/share/test-workflow.yml' => path('share/workflow-test-with-makefile.yml')->slurp,
            },
        },
    );
    $tzil->build;

    lives_ok(sub { $tzil }, 'Distro built')  || explain $tzil->log_messages;
    return $tzil;
}
