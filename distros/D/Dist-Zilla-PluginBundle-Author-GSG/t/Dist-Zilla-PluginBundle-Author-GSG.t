use strict;
use warnings;

use Test::More;

use Test::DZil;
use Test::Deep qw();

use Git::Wrapper;
use File::Temp qw();
use File::pushd qw();

use lib qw(lib);
my $module;
BEGIN {
    $module = 'Dist::Zilla::PluginBundle::Author::GSG';
    use_ok($module);
}

my $year   = 1900 + (localtime)[5];
my $holder = 'Grant Street Group';

#diag( "Testing $module " . $module->VERSION );

subtest 'Build a basic dist' => sub {
    my $dir = File::Temp->newdir("dzpbag-XXXXXXXXX");

    #local $Git::Wrapper::DEBUG = 1;
    my $git = Git::Wrapper->new($dir);
    plan skip_all => "No Git!" unless $git->has_git_in_path;

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

    is_json(
        $tzil->slurp_file('build/META.json'),
        Test::Deep::superhashof( {
            name     => 'OurExternal-Package',
            license  => ['artistic_2'],
            abstract => 'ABSTRACT',
            author   => ['Grant Street Group <developers@grantstreet.com>'],
            x_contributors => [$contributor],

            release_status => 'stable',
            version        => '0.0.1',

            %resources,

            dynamic_config   => 0,
            x_static_install => 1,
        } ),
        "Built the expected META.json"
    );
};

done_testing;
