use strict;
use warnings;

use Test::More;

use Test::DZil;
use Test::Deep qw();

use Git::Wrapper;
use File::Temp qw();
use File::pushd qw();

use lib qw(lib);
use Dist::Zilla::PluginBundle::Author::GSG;

$ENV{EMAIL} = 'fake@example.com'; # force a default for git
delete $ENV{V}; # because it could mess up Git::NextVersion

{
    my $git = Git::Wrapper->new('.');
    plan skip_all => "No Git!" unless $git->has_git_in_path;

    my $version = $git->version;
    plan skip_all => "Git is too old: $version"
        if $version < version->parse(v1.7.5);

    diag "Have git $version";
}

my $year   = 1900 + (localtime)[5];
my $holder = 'Grant Street Group';

subtest 'Build a basic dist' => sub {
    my $dir = File::Temp->newdir("dzpbag-XXXXXXXXX");

    #local $Git::Wrapper::DEBUG = 1;
    my $git = Git::Wrapper->new($dir);
    my $upstream = 'GrantStreetGroup/p5-OurExternal-Package';

    $git->init;
    $git->remote( qw/ add origin /,
        "https://fake-github.com/$upstream.git" );
    $git->commit( { m => 'init', date => '2001-02-03 04:05:06' },
        '--allow-empty' );

    my $contributor = ( $git->log )[0]->author;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/basic' },
        {   also_copy => { $dir => 'source' },
            add_files => {
                'source/cpanfile' =>
                    "requires 'perl', 'v5.10.0';",
                'source/dist.ini' => dist_ini(
                    { name => 'OurExternal-Package' },
                    '@Author::GSG',
                ),
                'source/README.md'     => 'Excluded',
                'source/LICENSE.txt'   => 'Excluded',
                'source/lib/External/Package.pm' =>
                    "package External::Package;\n# ABSTRACT: ABSTRACT\n# VERSION\n1;",
            }
        }
    );

    is $tzil->plugin_named('@Author::GSG/@Filter/MakeMaker')->eumm_version,
        '7.1101', "Require a newer ExtUtils::MakeMaker";

    my $source_git = Git::Wrapper->new( $tzil->tempdir->child('/source') );
    $source_git->add('.');
    $source_git->commit( -a => { m => "Add new files for Git::GatherDir" });

    $tzil->build;

    Test::Deep::cmp_bag [ map { $_->name } @{ $tzil->files } ], [
       'META.yml',
       'LICENSE',
       'README',
       'Makefile.PL',
       'MANIFEST',
       'META.json',
       'CHANGES',
       'cpanfile',
       'dist.ini',
       'lib/External/Package.pm',
       't/00-compile.t',
       't/00-report-prereqs.t',
       't/00-report-prereqs.dd'
     ], "Gathered the files we expect";

    my $built = $tzil->slurp_file('build/lib/External/Package.pm');
    like $built, qr/\nour \$VERSION = 'v0.0.1';/,
        "Found the correct version in the module";
    like $built,
        qr/\QThis software is Copyright (c) 2001 - $year by $holder./,
        "Put the expected copyright in the module";

    my %resources = (
        resources => {
            'repository' => {
                'type' => 'git',
                'url'  => "git://github.com/$upstream.git",
                'web'  => "https://github.com/$upstream"
            },
        },
    );

    # For reasons I don't understand sometimes the GitHub::Meta
    # Plugin doesn't find the Fetch URL, so we try to do something
    # similar to what they do, but in the correct directory.
    {
        my ($url) = map /Fetch URL: (.*)/,
            $source_git->remote( 'show', '-n', 'origin' );

        unless ( $url =~ /\Q$upstream/ ) {
            diag "Not checking 'resources', invalid Fetch URL [$url]";
            %resources = ();
        }
    }

    my %expect = (
        name           => 'OurExternal-Package',
        abstract       => 'ABSTRACT',
        author         => ['Grant Street Group <developers@grantstreet.com>'],

        version => 'v0.0.1',

        requires => { perl => 'v5.10.0' },
        provides => {
            "External::Package" => {
                file    => "lib/External/Package.pm",
                version => "v0.0.1"
            }
        },

        dynamic_config   => 0,
        x_static_install => 1,
    );

    # the YAML only has the git repository, not the rest.
    $expect{resources}{repository} = $resources{resources}{repository}{url}
        if %resources;

    is_yaml(
        $tzil->slurp_file('build/META.yml'),
        Test::Deep::superhashof(\%expect),
        "Built the expected META.yml"
    );

    %expect = (
        prereqs => Test::Deep::superhashof(
            { runtime => { requires => delete $expect{requires} } }
        ),

        %expect,
        license        => ['artistic_2'],
        release_status => 'stable',
        %resources,
    );

    is_json(
        $tzil->slurp_file('build/META.json'),
        Test::Deep::superhashof(\%expect),
        "Built the expected META.json"
    );
};

subtest 'NextVersion' => sub {
    my $dir = File::Temp->newdir("dzpbag-XXXXXXXXX");

    #local $Git::Wrapper::DEBUG = 1;
    my $git = Git::Wrapper->new($dir);
    my $upstream = 'GrantStreetGroup/p5-Versioned-Package';

    $git->init;
    $git->remote( qw/ add origin /,
        "https://fake-github.com/$upstream.git" );
    $git->commit( { m => 'init', date => '2001-02-03 04:05:06' },
        '--allow-empty' );

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/versioned' },
        {   also_copy => { $dir => 'source' },
            add_files => {
                'source/dist.ini' => dist_ini(
                    { name => 'Versioned' },
                    '@Author::GSG',
                ),
                'source/lib/Versioned.pm' =>
                    "package Versioned;\n# ABSTRACT: ABSTRACT\n# VERSION\n1;",
            }
        }
    );

    is $tzil->version, 'v0.0.1', 'First version is v0.0.1';

    my ($version_plugin)
        = $tzil->plugin_named('@Author::GSG/Git::NextVersion');
    my ($changelog_plugin)
        = $tzil->plugin_named('@Author::GSG/ChangelogFromGit');

    $version_plugin->git->commit( { m => $_ }, '--allow-empty' ) for (
        q{Merge branch 'ABC-123'},
        q{Merge remote-tracking branch 'origin/master' into test},
        q{Merge remote-tracking branch 'origin/test' into stage},
        q{Merge remote-tracking branch 'origin/stage' into prod},
        q{Merge pull request #123 in GHT/gsg-test from internal to master},
        q{Merge pull request #321 from GrantStreetGroup/external},
    );

    my @versions = (
        [ 'v0.0.1'              => 'v0.0.2' ],
        [ 'v1.2.3.4'            => 'v1.2.4' ],
        [ 'dist/v2.31.1.2/prod' => 'v2.31.2' ],
    );

    my @expected_changes = { changes => ["init\n"] };
    for (@versions) {
        my ($have, $expect) = @{ $_ };
        sleep 1; # ugh, ChangelogFromGit uses the commit date
        delete $version_plugin->{_all_versions};
        delete $changelog_plugin->{releases};

        $version_plugin->git->tag($have);
        $version_plugin->git->commit( { m => "Version $expect" },
            '--allow-empty' );

        $expected_changes[-1]{version} = $have;
        push @expected_changes, { changes => ["Version $expect\n"] };

        is $version_plugin->provide_version, $expect,
            "Version after $have is $expect";
    }

    $version_plugin->git->tag('v3.0.0');
    $expected_changes[-1]{version} = 'v3.0.0';

    {
        my $dir = File::pushd::pushd( $version_plugin->git->dir )
            or die "Unable to chdir source: $!";
        $changelog_plugin->gather_files;
    }

    my @got = map { {
        version => $_->version,
        changes => [ map { $_->description } @{ $_->changes } ]
    } } $changelog_plugin->all_releases;

    is_deeply \@got, \@expected_changes,
        "Expected Changes generated";
};

subtest "Override MetaProvides subclass" => sub {
    {   package Dist::Zilla::Plugin::MetaProvides::Fake;
        use Moose;
        with 'Dist::Zilla::Role::MetaProvider';
        sub metadata { +{} }
    }

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/metaprovides_subclass' },
        {   add_files => {
                'source/dist.ini' => dist_ini(
                    { name           => 'External-Fake' },
                    [ '@Author::GSG' => { meta_provides => 'Fake' } ],
                ),
                'source/lib/External/Fake.pm' =>
                    "package External::Fake;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    my @meta_provides_plugins = grep {/\bMetaProvides\b/}
        map { $_->plugin_name } @{ $tzil->plugins_with( -MetaProvider ) };

    Test::Deep::cmp_bag(
        \@meta_provides_plugins,
        ['@Author::GSG/MetaProvides::Fake'],
        "Correctly only have the fake MetaProvides Plugin"
    );
};

subtest "Pass through Git::GatherDir params" => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/git-gather_dir' },
        {   add_files => {
                'source/dist.ini' => dist_ini(
                    { name           => 'External-Fake' },
                    [ '@Author::GSG' => {
                        include_dotfiles => 1,
                        exclude_filename => [ qw< foo bar > ],
                        exclude_match => [ q{baz}, q{qu+x} ],
                    } ],
                ),
            }
        }
    );

    my ($plugin)
        = grep { $_->plugin_name =~ /\bGit::GatherDir\b/ }
        @{ $tzil->plugins };

    ok $plugin->include_dotfiles, "Enabled include_dotfiles";

    Test::Deep::cmp_bag(
        $plugin->exclude_filename,
        [qw< foo bar README.md LICENSE.txt >],
        "Added to the exclude_filename list"
    );

    Test::Deep::cmp_bag(
        $plugin->exclude_match,
        [q{baz}, q{qu+x}],
        "Added to the exclude_match list"
    );
};

done_testing;
