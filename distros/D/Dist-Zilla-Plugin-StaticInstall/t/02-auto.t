use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';

{
    package MyMetadata;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider',
        'Dist::Zilla::Role::PrereqSource';
    our $metadata;
    our $prereqs;
    sub metadata { $metadata }
    sub register_prereqs {
        my $self = shift;
        foreach my $phase (keys %$prereqs) {
            foreach my $type (keys %{ $prereqs->{$phase} }) {
                $self->zilla->register_prereqs(
                    { phase => $phase, type => $type },
                    %{ $prereqs->{$phase}{$type} },
                );
            }
        }
    }
}

{
    package MyOtherInstallTool;
    use Moose;
    with 'Dist::Zilla::Role::InstallTool';
    sub setup_installer {}
}

my $munge_line;
{
    package MyMunger;
    use Moose;
    with 'Dist::Zilla::Role::FileMunger';
    sub munge_files {
        my $self = shift;
        foreach my $file (grep { $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } @{ $self->zilla->files }) {
            $file->content($file->content . "\nETHER WUZ HERE\n");  $munge_line = __LINE__;
        }
    }
}

my @tests = (
    {
        test_name => 'dynamic_config => 1',
        metadata => { dynamic_config => 1 },
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'dynamic_config is true',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'extra config prereq',
        metadata => { prereqs => { configure => { requires => { 'My::Custom::Installer' => '0' } } } },
        zilla_config_pre => [
            [ MakeMaker => ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'found configure prereq My::Custom::Installer',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'extra build prereq',
        metadata => { prereqs => { build => { requires => { 'My::Custom::Builder' => '0' } } } },
        zilla_config_pre => [
            [ MakeMaker => ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'found build prereq My::Custom::Builder',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'execdir outside of script/',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ ExecDir => ],
        ],
        zilla_files => [
            path(qw(source bin hello-world)) => qq{#!/usr/bin/perl\nprint "hello world!\\xa\n"},
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'found ineligible executable dir \'bin\'',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'execdir outside of script/, but not used',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ ExecDir => ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'found ineligible executable dir \'bin\' configured: better to avoid',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'module sharedir',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ ModuleShareDirs => { 'Foo::Bar' => 'shares/foo_bar' } ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'found module sharedir for Foo::Bar',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'install plugin order',
        zilla_config_post => [
            [ MakeMaker => ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'this plugin must be after Dist::Zilla::Plugin::MakeMaker',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'no recognized install plugin',
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'a recognized installer plugin must be used',
            'setting x_static_install to 0',
        ],
    },
    {
        # this also catches the case of a plugin munging a file in the installer phase
        test_name => 'foreign install tools',
        zilla_config_pre => [
            [ '=MyOtherInstallTool' ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'found install tool MyOtherInstallTool that will add extra content to Makefile.PL, Build.PL',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'install file munged (munging phase)',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ '=MyMunger' => ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'Makefile.PL content set by unknown (MyMunger line __MUNGE_LINE__)',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'no META.json',
        zilla_config_pre => [
            [ MakeMaker => ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'META.json is not being added to the distribution',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'no META using meta-spec v2',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ MetaJSON => { version => '1.4' } ],
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'META.json is using meta-spec version 1.4',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => '.xs files',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ MetaJSON => ],
        ],
        zilla_files => [
            path(qw(source Foo.xs)) => qq{#include "perl.h"\n},
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'checking for .xs files',
            'found .xs file Foo.xs',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => '.pm, .pod, .pl files in root',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ MetaJSON => ],
        ],
        zilla_files => [
            path(qw(source Bar.pm)) => "package Bar;\n1;\n",
            path(qw(source blah.pl)) => "#!/usr/bin/perl;\nexit 0;\n1;\n",
            path(qw(source README.pod)) => "This distribution is awesome\n",
            path(qw(source examples demo.pl)) => "#!/usr/bin/perl;\nexit 0;\n1;\n",
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'found Bar.pm, README.pod, blah.pl in the root',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => '.pm, .pod, .pl files in BASEEXT',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ MetaJSON => ],
        ],
        zilla_files => [
            path(qw(source Baz Bar.pm)) => "package Bar;\n1;\n",
            path(qw(source Baz blah.pl)) => "#!/usr/bin/perl;\nexit 0;\n1;\n",
            path(qw(source Baz README.pod)) => "This distribution is awesome\n",
            path(qw(source examples demo.pl)) => "#!/usr/bin/perl;\nexit 0;\n1;\n",
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'found Bar.pm, README.pod, blah.pl in Baz/',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => '.PL, .pmc files',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ MetaJSON => ],
        ],
        zilla_files => [
            path(qw(source lib Bar.pmc)) => "package Bar;\n1;\n",
            path(qw(source example Foo.PL)) => "#!/usr/bin/perl;\nexit 0;\n1;\n",
        ],
        x_static_install => 0,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'checking for .PL, .pmc files',
            'found example/Foo.PL, lib/Bar.pmc',
            'setting x_static_install to 0',
        ],
    },
    {
        test_name => 'static distribution, [MakeMaker]',
        zilla_config_pre => [
            [ MakeMaker => ],
            [ MetaJSON => ],
        ],
        x_static_install => 1,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'setting x_static_install to 1',
        ],
    },
    {
        test_name => 'static distribution, [ModuleBuildTiny]',
        zilla_config_pre => [
            [ ModuleBuildTiny => ], # see other test files for use of 'static' config option
            [ MetaJSON => ],
        ],
        x_static_install => 1,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Build.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'setting x_static_install to 1',
        ],
    },
    {
        test_name => 'static distribution, [ModuleBuildTiny::Fallback]',
        zilla_config_pre => [
            [ 'ModuleBuildTiny::Fallback' ],
            [ MetaJSON => ],
        ],
        x_static_install => 1,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Build.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'setting x_static_install to 1',
        ],
    },
    {
        test_name => 'static distribution, [MakeMaker::Fallback] and [ModuleBuildTiny]',
        zilla_config_pre => [
            [ 'MakeMaker::Fallback' => ],
            [ ModuleBuildTiny => ], # see other test files for use of 'static' config option
            [ MetaJSON => ],
        ],
        x_static_install => 1,
        messages => [
            'checking dynamic_config',
            'checking configure prereqs',
            'checking build prereqs',
            'checking execdirs',
            'checking sharedirs',
            'checking installer plugins',
            'checking for munging of Makefile.PL',
            'checking META.json',
            'checking for .xs files',
            'checking .pm, .pod, .pl files',
            'setting x_static_install to 1',
        ],
    },
);

subtest $_->{test_name} => sub
{
    my $config = $_;

    plan skip_all => 'Dist::Zilla is too old to be adding Makefile.PL during the file gathering phase'
        if eq_deeply($config->{zilla_config_pre}, supersetof(supersetof('=MyMunger')))
            and not Dist::Zilla::Plugin::MakeMaker->does('Dist::Zilla::Role::FileGatherer');

    foreach my $plugin (qw(ModuleBuildTiny ModuleBuildTiny::Fallback MakeMaker::Fallback))
    {
        plan skip_all => "[$plugin] is not installed"
            if eq_deeply($config->{zilla_config_pre}, supersetof(supersetof($plugin)))
                and not eval { require_module("Dist::Zilla::Plugin::$plugin") };
    }

    plan skip_all => '[MetaJSON] (as of 6.007) is no longer capable of generating files using metaspec version 1.4'
        if eq_deeply($config->{zilla_config_pre}, supersetof([ 'MetaJSON' => { version => '1.4' } ]))
            and eval { +require Dist::Zilla::Plugin::MetaJSON; Dist::Zilla::Plugin::MetaJSON->VERSION('6.007') };

    local $MyMetadata::metadata = $config->{metadata} || {};
    local $MyMetadata::prereqs = $config->{metadata}{prereqs};

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    {   # merge into root section
                        name => 'Foo-Bar-Baz',
                    },
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ '=MyMetadata' ],
                    @{ $config->{zilla_config_pre} || [] },
                    [ StaticInstall => { mode => 'auto' } ],
                    @{ $config->{zilla_config_post} || [] },
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                @{ $config->{zilla_files} || [] },
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_static_install => $config->{x_static_install},
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::StaticInstall',
                        config => {
                            'Dist::Zilla::Plugin::StaticInstall' => {
                                mode => 'auto',
                                dry_run => 0,
                            },
                        },
                        name => 'StaticInstall',
                        version => Dist::Zilla::Plugin::StaticInstall->VERSION,
                    },
                ),
            }),
        }),
        "metadata contains auto-computed value ($config->{x_static_install}), and dumped configs",
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    cmp_deeply(
        [ map { colorstrip($_) } @{ $tzil->log_messages } ],
        supersetof(map { s/__MUNGE_LINE__/$munge_line/; '[StaticInstall] ' . $_ } @{ $config->{messages} }),
        $config->{test_name},
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
