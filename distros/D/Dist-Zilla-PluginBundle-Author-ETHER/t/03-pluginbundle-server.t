use strict;
use warnings;

use Test::More 0.96;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';

use Test::Needs {
    'Dist::Zilla::Plugin::GithubMeta' => 0,
    'Dist::Zilla::Plugin::GitHub::Update' => '0.40',
};

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

# this data should be constant across all server types
my %bugtracker = (
    bugtracker => {
        mailto => 'bug-DZT-Sample@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample',
    },
);

my %server_to_resources = (
    github => {
        %bugtracker,
        homepage => 'https://github.com/karenetheridge/Dist-Zilla-PluginBundle-Author-ETHER',
        repository => {
            type => 'git',
            # note that we use use .git/config in the local repo!
            url => 'https://github.com/karenetheridge/Dist-Zilla-PluginBundle-Author-ETHER.git',
            web => 'https://github.com/karenetheridge/Dist-Zilla-PluginBundle-Author-ETHER',
        },
    },
    gitmo => {
        %bugtracker,
        # no homepage set
        repository => {
            type => 'git',
            url => 'git://git.moose.perl.org/DZT-Sample.git',
            web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/DZT-Sample.git;a=summary',
        },
    },
    ( map {
        $_ => {
            %bugtracker,
            # no homepage set
            repository => {
                type => 'git',
                url => 'git://git.shadowcat.co.uk/' . $_ . '/DZT-Sample.git',
                web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=' . $_ . '/DZT-Sample.git;a=summary',
            },
        },
    } qw(p5sagit catagits)),
);

subtest "server = $_" => sub {
    SKIP: {
    my $server = $_;

    my $tzil;
    my @warnings = warnings {
        $tzil = Builder->from_config(
            { dist_root => 'does-not-exist' },
            {
                # tempdir_root => default
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        'GatherDir',
                        [ '@Author::ETHER' => {
                            server => $server,
                            installer => 'MakeMaker',
                            '-remove' =>  \@REMOVED_PLUGINS,
                            'RewriteVersion::Transitional.skip_version_provider' => 1,
                          },
                        ],
                    ),
                    path(qw(source lib MyModule.pm)) => "package MyModule;\n\n1",
                    path(qw(source Changes)) => '',
                },
            },
        );
    };

    skip('can only test server=github when in the local git repository', 4)
        if $server eq 'github' and not git_in_path($tzil->tempdir);

    if ($server eq 'github' or $server eq 'none')
    {
        warn @warnings if @warnings;
    }
    else
    {
        my $expected = "server = $server: recommend instead using server = github and GithubMeta.remote = $server with a read-only mirror";
        my $ok = cmp_deeply(
            [ map { colorstrip($_) } @warnings ],
            superbagof(re(qr/^\[\@Author::ETHER\] $expected/)),
            'we warn when using other server settings',
        ) or diag explain @warnings;
        @warnings = grep { !m/$expected/ } @warnings;
        warn @warnings if @warnings and $ok;
    }

    assert_no_git($tzil);

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    # check that everything we loaded is properly declared as prereqs
    all_plugins_in_prereqs($tzil,
        exempt => [ 'Dist::Zilla::Plugin::GatherDir' ],     # used by us here
        additional => [
            'Dist::Zilla::Plugin::MakeMaker',       # via installer option
            'Dist::Zilla::Plugin::GithubMeta',      # via server option
            'Dist::Zilla::Plugin::GitHub::Update',
        ],
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            resources => $server_to_resources{$server},
        }),
        'server ' . $server . ': all meta resources are correct',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
} }
foreach sort keys %server_to_resources;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
