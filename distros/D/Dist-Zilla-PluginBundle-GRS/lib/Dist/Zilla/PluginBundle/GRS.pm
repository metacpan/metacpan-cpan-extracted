#
# This file is part of Dist-Zilla-PluginBundle-GRS
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::PluginBundle::GRS;

# ABSTRACT: Dist::Zilla like GRS

use strict;
use warnings;

our $VERSION = '0.08';    # VERSION

use Moose;
use Class::MOP;
with 'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover';

my $PERLTIDY_SAMPLE = <<'EOF'
#Perl Best Practice Conf
-l=78
-i=4
-ci=4
#-st
-se
-vt=2
-cti=0
-pt=1
-bt=1
-sbt=1
-bbt=1
-nsfs
-nolq
-wbb="% + - * / x != == >= <= =~  !~ < > | & >= < = **= += *= &= <<= &&= -= /= |= >>= ||= .= %= ^= x="
EOF
    ;
my $PERLCRITIC_SAMPLE = <<'EOF'
severity        = 3
verbose         = 6
top             = 50
theme           = pbp || core || bugs || security || maintenance
criticism-fatal = 1
color           = 1
allow-unsafe    = 1
EOF
    ;

sub before_build {
    my $self = shift;
    unless ( -d 'xt' ) {
        mkdir('xt');
    }
    unless ( -e 'xt/perltidy.rc' ) {
        if ( open my $f, '>', 'xt/perltidy.rc' ) {
            print $f $PERLTIDY_SAMPLE;
            close $f;
        }
    }
    unless ( -e 'xt/perlcritic.rc' ) {
        if ( open my $f, '>', 'xt/perlcritic.rc' ) {
            print $f $PERLCRITIC_SAMPLE;
            close $f;
        }
    }
    return;
}

sub configure {
    my $self = shift;

    #init some file like perltidy and perlcritic rc files
    $self->before_build;

    $self->add_bundle( 'Filter',
        { bundle => '@Basic', remove => [ 'MakeMaker', 'UploadToCPAN' ] } );
    $self->add_plugins(
        'ModuleBuild',
        'ReportVersions',
        'OurPkgVersion',
        [ 'Prepender' => { copyright => 1 } ],
        'AutoPrereqs',
        'Prereqs',
        'MinimumPerl',
        'Test::Compile',
        'Test::UnusedVars',
        'PodCoverageTests',
        'PruneFiles',
        'ReadmeMarkdownFromPod',
        'MetaJSON',
        [   'MetaResourcesFromGit' =>
                { 'bugtracker.web' => 'https://github.com/%a/%r/issues' }
        ],
        'MetaConfig',
        [ 'PodWeaver'          => { 'config_plugin' => '@GRS' } ],
        [ 'PerlTidy'           => { 'perltidyrc'    => 'xt/perltidy.rc' } ],
        [ 'Test::Perl::Critic' => { 'critic_config' => 'xt/perlcritic.rc' } ],
        ['Test::Kwalitee::Extra'],
    );

    return;
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::GRS - Dist::Zilla like GRS

=head1 VERSION

version 0.08

=head1 OVERVIEW

This is the bundle for GRS (Git Redmine Suite), and is equivalent to create this dist.ini :

  [@Filter]
  -bundle = @Basic
  -remove = MakeMaker
  -remove = UploadToCPAN
  [ModuleBuild]
  [ReportVersions]
  [OurPkgVersion]
  [Prepender]
  copyright = 1
  [AutoPrereqs]
  [Prereqs]
  [MinimumPerl]
  [Test::Compile]
  [Test::UnusedVars]
  [PodCoverageTests]
  [PruneFiles]
  [ReadmeMarkdownFromPod]
  [MetaJSON]
  [MetaResourcesFromGit]
  bugtracker.web = https://github.com/%a/%r/issues
  [MetaConfig]
  [PodWeaver]
  config_plugin = @GRS
  [PerlTidy]
  perltidyrc = xt/perltidy.rc
  [Test::Perl::Critic]
  critic_config = xt/perlcritic.rc
  [Test::Kwalitee::Extra]

It also install :

  Devel::Cover
  Dist::Zilla::App::Command::cover

Here a simple dist.ini :

  name = MyTest
  license = Perl_5
  copyright_holder = celogeek <me@celogeek.com>
  copyright_year = 2011
  
  [@GRS]

Here my .gitignore :

    xt/perltidy.rc
    xt/perlcritic.rc
    MyTest-*
    *.swp
    *.bak
    *.tdy
    *.old
    .build
    .includepath
    .project
    .DS_Store

You need to create and commit at least the .gitignore Changes and dist.ini and your lib first. Then any release will be automatic.

When you will release, by invoking 'dzil release', it will automatically:

=over 2

=item * increment the version number (you dont add it in your program)

=item * collect change found in your Changes after the NEXT

=item * collect the markdown for github

=item * commit Changes, dist.ini and README.mkdn with a simple message (version and changes)

=item * add a tag

=item * push origin

=back

=head1 METHODS

=head2 before_build

Setup default config file if your project lack of them

=head2 configure

Configuration of Dist::Zilla::PluginBundle::Easy

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://tasks.celogeek.com/projects/perl-modules-dist-zilla-pluginbundle-gr
s

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
