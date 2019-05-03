use strict;
use warnings;

use Test::More;

use Test::DZil;

use Git::Wrapper;
use File::Temp qw();
use File::pushd qw();

use lib qw(lib);
my $module;

BEGIN {
    $module = 'Dist::Zilla::Plugin::Author::GSG';
    use_ok($module);
}

#diag( "Testing $module " . $module->VERSION );

my $dir = File::Temp->newdir("dzpag-XXXXXXXXX");

{
    my $git = Git::Wrapper->new($dir);
    plan skip_all => "No Git!" unless $git->has_git_in_path;

    $git->init;
    $git->commit( { m => 'init', date => '2001-02-03 04:05:06' },
        '--allow-empty' );
}

my $author = 'Grant Street Group <developers@grantstreet.com>';
my $holder = 'Grant Street Group';
my $year   = 1900 + (localtime)[5];

subtest 'Dist with defaults' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/defaults' },
        {   also_copy => { $dir => 'source' },
            add_files => {
                'source/dist.ini' => dist_ini(
                    {   name    => 'Defaults',
                        version => '1.2.3',
                    },
                    'Author::GSG',
                    'GatherDir',
                ),
                'source/lib/Defaults.pm' =>
                    "package Defaults;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    $tzil->build;

    is_deeply $tzil->authors, [$author], "Correct default author";

    is $tzil->license->name, 'The Artistic License 2.0 (GPL Compatible)',
        "Correct default license";
    is $tzil->license->holder, $holder, "Correct default license holder";
    is $tzil->license->year, "2001 - $year", "Correct default license year";
};

subtest 'Dist with defaults, without git repo' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/defaults' },
        {   add_files => {
                'source/dist.ini' => dist_ini(
                    {   name    => 'Defaults',
                        version => '1.2.3',
                    },
                    'Author::GSG',
                    'GatherDir',
                ),
                'source/lib/Defaults.pm' =>
                    "package Defaults;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    $tzil->build;

    is_deeply $tzil->authors, [$author], "Correct default author";

    is $tzil->license->name, 'The Artistic License 2.0 (GPL Compatible)',
        "Correct default license";
    is $tzil->license->holder, $holder, "Correct default license holder";
    is $tzil->license->year,   $year,   "Correct default license year";
};

subtest 'Dist overriding defaults' => sub {

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/override' },
        {   also_copy => { $dir => 'source' },
            add_files => {
                'source/dist.ini' => dist_ini(
                    {   name    => 'Overrides',
                        version => '1.2.3',
                        author  => 'An Author <an.author@example.test>',
                        license => 'MIT',
                        copyright_holder => 'An Author',
                        copyright_year   => '1995',
                    },
                    'Author::GSG',
                    'GatherDir',
                ),
                'source/lib/Overrides.pm' =>
                    "package Overrides;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    $tzil->build;

    is_deeply $tzil->authors,
        ['An Author <an.author@example.test>'],
        "Correct overridden author";

    is $tzil->license->name, 'The MIT (X11) License',
        "Correct overridden license";
    is $tzil->license->holder, "An Author",
        "Correct overridden license holder";
    is $tzil->license->year, "1995", "Correct overridden license year";
};

done_testing;
