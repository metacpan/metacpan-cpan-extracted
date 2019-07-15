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
                'source/lib/External/Package.pm' =>
                    "package External::Package;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    my $source_git = $tzil->plugin_named('@Author::GSG/Git::Commit')->git;
    $source_git->add('.');
    $source_git->commit( -a => { m => "Add new files for Git::GatherDir" });

    $tzil->build;

    my $built = $tzil->slurp_file('build/lib/External/Package.pm');
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
                $tzil->plugin_named('@Author::GSG/Git::Push')
                    ->git->remote( 'show', '-n', 'origin' );

        unless ( $url =~ /\Q$upstream/ ) {
            diag "Not checking 'resources', invalid Fetch URL [$url]";
            %resources = ();
        }
    }

    my %expect = (
        name           => 'OurExternal-Package',
        abstract       => 'ABSTRACT',
        author         => ['Grant Street Group <developers@grantstreet.com>'],
        x_contributors => [$contributor],

        version => '0.0.1',

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

done_testing;
