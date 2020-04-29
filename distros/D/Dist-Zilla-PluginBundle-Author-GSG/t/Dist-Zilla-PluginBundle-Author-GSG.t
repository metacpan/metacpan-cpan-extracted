use strict;
use warnings;

use Test::More;

use Test::DZil;
use Test::Deep qw();
use Test::Fatal qw();

use Git::Wrapper;
use File::Spec qw();
use File::Temp qw();
use File::pushd qw();

use Time::Piece;

use lib qw(lib);
use Dist::Zilla::PluginBundle::Author::GSG;

$ENV{EMAIL} = 'fake@example.com'; # force a default for git
delete $ENV{V}; # because it could mess up Git::NextVersion

# Avoid letting tests pick up our "root" git directory
{
    my @path = File::Spec->splitdir( File::Spec->rel2abs(__FILE__) );
    splice @path, -2;    # Remote t/$file.t
    $ENV{GIT_CEILING_DIRECTORIES} = File::Spec->catdir(@path);
}

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
        "https://fake.github.com/$upstream.git" );
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

    my $now = Time::Piece->new - 86400 * 30;

    local $ENV{GIT_AUTHOR_DATE}    = $now->datetime;
    local $ENV{GIT_COMMITTER_DATE} = $ENV{GIT_AUTHOR_DATE};

    $git->init;
    $git->remote( qw/ add origin /,
        "https://fake.github.com/$upstream.git" );
    $git->commit( { m => 'init', date => $now->datetime },
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
        = $tzil->plugin_named('@Author::GSG/ChangelogFromGit::CPAN::Changes');

    my @versions = (
        [ 'v0.0.1'              => 'v0.0.2' ],
        [ 'v1.2.3.4'            => 'v1.2.4' ],
        [ 'dist/v2.31.1.2/prod' => 'v2.31.2' ],
    );

    for (@versions) {
        my ($have, $expect) = @{ $_ };
        delete $version_plugin->{_all_versions};

        $now += 86400;
        $ENV{GIT_AUTHOR_DATE} = $ENV{GIT_COMMITTER_DATE} = $now->datetime;
        $version_plugin->git->commit( { m => "Changes for $have" },
            '--allow-empty' );
        $version_plugin->git->tag($have);

        is $version_plugin->provide_version, $expect,
            "Version after $have is $expect";
    }

    for (
        q{Merge branch 'ABC-123'},
        q{Merge remote-tracking branch 'origin/master' into test},
        q{Merge remote-tracking branch 'origin/test' into stage},
        q{Merge remote-tracking branch 'origin/stage' into prod},
        q{Merge pull request #123 in GHT/gsg-test from internal to master},
        q{Merge pull request #321 from GrantStreetGroup/external},
        q{A New Release},
        )
    {
        $now += 86400;
        $ENV{GIT_AUTHOR_DATE} = $ENV{GIT_COMMITTER_DATE} = $now->datetime;
        $version_plugin->git->commit( { m => $_ },
            '--allow-empty' );
    }
    $version_plugin->git->tag('v3.0.0');

    # For debugging, you can see the log here.
    #diag $_ for $version_plugin->git->RUN('log', '--decorate' );

    {
        my $dir = File::pushd::pushd( $version_plugin->git->dir )
            or die "Unable to chdir source: $!";
        local $ENV{DZIL_RELEASING} = 1;
        $changelog_plugin->gather_files;
    }

    my @changelog = map { [ split /\s+-\s+/ms ] } split /\n\s*\n/ms,
        $tzil->files->[-1]->content;

    my %got;
    for (@changelog) {
        my ($version, @changes) = @{$_};

        $version =~ s/\s+\d{4}-\d{2}-\d{2}T.*$//; # Remove date

        chomp @changes;
        s/\s+/ /gms       for @changes;
        s/\s+\([^)]+\)$// for @changes;

        $got{$version} = \@changes;
    }

    # This is not what I expected in the Changelog.
    # I don't know why "init" and "v0.0.1" changes are in the wrong release.
    my %expect = (
        'Changelog for Versioned' => [],
        'v0.0.1'                  => ['No changes found'],
        'v1.2.3.4'                => ['Changes for v1.2.3.4'],
        'v2.31.1.2'               => [
            'Changes for dist/v2.31.1.2/prod',
            'Changes for v1.2.3.4',
            'Changes for v0.0.1',
            'init'
        ],
        'v3.0.0' => [
            'A New Release',
            'Merge remote-tracking branch \'origin/stage\' into prod',
            'Merge remote-tracking branch \'origin/test\' into stage',
            'Merge remote-tracking branch \'origin/master\' into test',
            'Changes for dist/v2.31.1.2/prod'
        ]
    );

    is_deeply( \%got, \%expect, "Expected Changes generated" )
        || diag explain [ \%got, \%expect ];
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
                    { name => 'External-Fake' },
                    [   '@Author::GSG' => {
                            meta_provides => 'Fake',
                            github_remote => 'fake'
                        }
                    ],
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

# A package similar to our Internal PluginBundle
package  # Hide from the CPAN
    Dist::Zilla::PluginBundle::Fake::WithoutGitHub {
    use Moose;
    with qw( Dist::Zilla::Role::PluginBundle::Easy );

    sub configure {
        my ($self) = @_;

        $self->add_bundle(
            'Filter' => {
                %{ $self->payload },
                -bundle => '@Author::GSG',
                -remove => [ qw(
                    GitHub::Meta
                    Author::GSG::GitHub::UploadRelease
                ) ]
            }
        );
    }

    __PACKAGE__->meta->make_immutable;
}

subtest "Set correct GitHub Remote" => sub {
    my $dir = File::Temp->newdir("dzpbag-XXXXXXXXX");

    #local $Git::Wrapper::DEBUG = 1;
    my $git = Git::Wrapper->new($dir);
    $git->init;
    $git->commit( { m => 'init' }, '--allow-empty' );

    my @config = (
        { dist_root => 'corpus/dist/github' },
        {   also_copy => { $dir => 'source' },
            add_files => {
                'source/dist.ini' =>
                    dist_ini( { name => 'Fake' }, ['@Fake::WithoutGitHub'] ),
                'source/lib/Fake.pm' =>
                    "package Fake;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    ok Builder->from_config(@config),
        "A subclass without any GitHub Plugins doesn't try to find a remote";

    $config[1]{add_files}{'source/dist.ini'} = dist_ini(
        { name => 'Fake' },
        [   '@Filter' => {
                -bundle => '@Author::GSG',
                -remove => [qw( Author::GSG::GitHub::UploadRelease )],
            }
        ],
    );

    ok Builder->from_config(@config),
        "A filter doesn't automatically generate the github_remote";

    $config[1]{add_files}{'source/dist.ini'} = dist_ini(
        { name => 'Fake' },
        [   '@Filter' => {
                -bundle => '@Author::GSG',
                -remove => [qw( Author::GSG::GitHub::UploadRelease )],
                find_github_remote => 1,
            },
        ],
    );

    like(
        Test::Fatal::exception { Builder->from_config(@config) },
        qr/^Unable to find git remote for GitHub /,
        "A filter that requests it, tries to find the github_remote"
    );

    $config[1]{add_files}{'source/dist.ini'}
        = dist_ini( { name => 'Fake' }, ['@Author::GSG',
            find_github_remote => 0 ], );

    ok Builder->from_config(@config),
        "You can disable finding the github_remote";

    $config[1]{add_files}{'source/dist.ini'}
        = dist_ini( { name => 'Fake' }, ['@Author::GSG'], );

    like(
        Test::Fatal::exception { Builder->from_config(@config) },
        qr/^Unable to find git remote for GitHub /,
        "Without a git remote we fail"
    );

    $git->remote(
        add => origin => "https://github.internal.test/Fake.git" );

    like(
        Test::Fatal::exception { Builder->from_config(@config) },
        qr/^Unable to find git remote for GitHub /,
        "Without a git remote we fail"
    );

    $git->remote(
        add => 0 => "https://fake.GitHub.com/GrantStreetGroup/Fake.git" );

    {
        ok my $tzil = Builder->from_config(@config),
            "With a single (falsy) remote we don't get an exception";

        my %set;
        foreach my $plugin ( @{ $tzil->plugins } ) {
            if ( $plugin->isa('Dist::Zilla::Plugin::Git::Push') ) {
                $set{git}++;
                Test::Deep::cmp_bag( $plugin->push_to, [0],
                    "Set push_to on " . $plugin->plugin_name );
            }
            elsif ( $plugin->isa('Dist::Zilla::Plugin::GitHub') ) {
                $set{github}++;
                is $plugin->remote, 0,
                    "Set remote on " . $plugin->plugin_name;
            }
        }

        is $set{git},    1, "Set one Git Plugin";
        is $set{github}, 2, "Set two GitHub Plugins";
    }

    $git->remote(
        add => 1 => "https://fake.GitHub.com/GrantStreetGroup/Fake.git" );

    like(
        Test::Fatal::exception { Builder->from_config(@config) },
        qr/^Multiple git remotes found for GitHub /,
        "Without a git remote we fail"
    );

    $config[1]{add_files}{'source/dist.ini'} = dist_ini( { name => 'Fake' },
        [ '@Author::GSG' => { github_remote => 'fake' } ] );

    {
        ok my $tzil = Builder->from_config(@config),
            "With an overridden github_remote we don't get an exception";

        my %set;
        foreach my $plugin ( @{ $tzil->plugins } ) {
            if ( $plugin->isa('Dist::Zilla::Plugin::Git::Push') ) {
                $set{git}++;
                Test::Deep::cmp_bag( $plugin->push_to, ['fake'],
                    "Set 'fake' push_to on " . $plugin->plugin_name );
            }
            elsif ( $plugin->isa('Dist::Zilla::Plugin::GitHub') ) {
                $set{github}++;
                is $plugin->remote, 'fake',
                    "Set 'fake' remote on " . $plugin->plugin_name;
            }
        }

        is $set{git},    1, "Set one Git::Push Plugin";
        is $set{github}, 2, "Set two Git::Push Plugin";
    }
};

subtest "Pass through Git::GatherDir params" => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/git-gather_dir' },
        {   add_files => {
                'source/dist.ini' => dist_ini(
                    { name           => 'External-Fake' },
                    [ '@Author::GSG' => {
                        github_remote    => 'fake',
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

subtest "Add 'script' ExecDir for StaticInstall" => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/exec_dir' },
        {   add_files => {
                'source/dist.ini' => dist_ini(
                    { name => 'External-Fake' },
                    [ '@Author::GSG' => { github_remote => 'fake' } ],
                ),
            }
        }
    );

    my @dirs = sort map { $_->dir }
        grep { $_->plugin_name =~ /\bExecDir$/ } @{ $tzil->plugins };

    is_deeply \@dirs, [qw< bin script >],
        "Have both bin/ and script/ ExecDirs";
};


subtest "Add 'test_compile_*' config slice" => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/test_compile' },
        {   add_files => {
                'source/dist.ini' => dist_ini(
                    { name => 'Test-Compile' },
                    [   '@Author::GSG' => {
                            github_remote    => 'fake',
                            test_compile_filename  => 'compile.t',
                            test_compile_phase     => 'author',
                            test_compile_skip      => [ 'Foo$', '^Ba[rz]' ],
                            test_compile_file      => ['Foo/Bar.PL'],
                            test_compile_fake_home => 1,
                            test_compile_needs_display    => 0,
                            test_compile_fail_on_warning  => 'author',
                            test_compile_bail_out_on_fail => 1,
                            test_compile_module_finder    => [':FakeModules'],
                            test_compile_script_finder    => [':FakeFiles'],
                            test_compile_xt_mode          => 1,
                            test_compile_switch           => [ '-X', '-Y' ],
                        }
                    ],
                ),
            }
        }
    );

    my ($plugin)
        = grep { $_->plugin_name =~ /\bTest::Compile\b/ } @{ $tzil->plugins };

    is_deeply $plugin->{filename} => 'compile.t', "filename is set";
    is_deeply $plugin->{phase}    => 'author',    "phase is set";
    is_deeply $plugin->{skips}      => [ 'Foo$', '^Ba[rz]' ], "skip is set";
    is_deeply $plugin->{files}      => ['Foo/Bar.PL'], "file is set";
    is_deeply $plugin->{fake_home} => 1, "fake_home is set";
    is_deeply $plugin->{needs_display}   => 0, "needs_display is set";
    is_deeply $plugin->{fail_on_warning} => 'author',
        "fail_on_warning is set";
    is_deeply $plugin->{bail_out_on_fail} => 1, "bail_out_on_fail is set";
    is_deeply $plugin->{module_finder}    => [':FakeModules'],
        "module_finder is set";
    is_deeply $plugin->{script_finder} => [':FakeFiles'],
        "script_finder is set";
    is_deeply $plugin->{xt_mode} => 1, "xt_mode is set";
    is_deeply $plugin->{switches}  => [ '-X', '-Y' ], "switch is set";
};

done_testing;
