use strict;
use warnings;

package Dist::Zilla::PluginBundle::SHANTANU;

# PODNAME: Dist::Zilla::PluginBundle::SHANTANU

our $VERSION = '0.43'; # VERSION

# Dependencies
use 5.010;
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 4.3;

use Dist::Zilla::PluginBundle::Git 2.028;

use Dist::Zilla::Plugin::Git::NextVersion;
use Dist::Zilla::Plugin::AutoMetaResourcesPrefixed;

use Dist::Zilla::Plugin::Git::Contributors;

use Dist::Zilla::Plugin::PruneCruft;
use Dist::Zilla::Plugin::ManifestSkip;

use Dist::Zilla::Plugin::OurPkgVersion;
use Dist::Zilla::Plugin::InsertCopyright;

use Dist::Zilla::Plugin::TaskWeaver;
use Dist::Zilla::Plugin::PodWeaver;
use Pod::Weaver::Section::Badges;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

use Dist::Zilla::Plugin::License;

use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::Test::MinimumVersion;
use Dist::Zilla::Plugin::Test::ReportPrereqs;

use Dist::Zilla::Plugin::Test::PodSpelling;
use Test::Portability::Files 0.06 ();    # buggy before that
use Dist::Zilla::Plugin::Test::Perl::Critic;
use Dist::Zilla::Plugin::Test::Kwalitee::Extra;
use Dist::Zilla::Plugin::MetaTests;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::Test::Portability;
use Dist::Zilla::Plugin::Test::Version;
use Dist::Zilla::Plugin::TravisYML;

use Dist::Zilla::Plugin::MinimumPerl;
use Dist::Zilla::Plugin::MetaNoIndex;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MetaYAML;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::Git::CommitBuild;

use Dist::Zilla::Plugin::PerlTidy;
use Dist::Zilla::Plugin::MakeMaker::Awesome;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::CheckMetaResources;
use Dist::Zilla::Plugin::CheckPrereqsIndexed;
use Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes 0.109;
use Dist::Zilla::Plugin::ChangelogFromGit::Debian;
use Dist::Zilla::Plugin::Control::Debian;
use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::CheckExtraTests;

with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';

#Gather Stopwords that may skip spelling checks in pod testing
sub mvp_multivalue_args { qw/stopwords exclude_filename/ }


has makemaker => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{makemaker}
          ? $_[0]->payload->{makemaker}
          : "MakeMaker::Awesome";
    },
);


has skip_makemaker => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{skip_makemaker} },
);


has no_git => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{no_git} },
);


has no_commitbuild => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{no_commitbuild} },
);


has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{version_regexp}
          ? $_[0]->payload->{version_regexp}
          : '^release-(.+)$',
          ;
    },
);


has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{is_task} },
);


has weaver_config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{weaver_config} || '@SHANTANU' },
);


has no_spellcheck => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_spellcheck}
          ? $_[0]->payload->{no_spellcheck}
          : 0;
    },
);


has exclude_filename => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{exclude_filename}
          ? $_[0]->payload->{exclude_filename}
          : [qw/dist.ini Changes README.pod README.md META.json META.yml/];
    },
);


has stopwords => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{stopwords} ? $_[0]->payload->{stopwords} : [];
    },
);


has no_critic => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_critic} ? $_[0]->payload->{no_critic} : 0;
    },
);


has no_coverage => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{no_coverage}
          ? $_[0]->payload->{no_coverage}
          : 0;
    },
);


has test_kwalitee => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{test_kwalitee}
          ? $_[0]->payload->{test_kwalitee}
          : 1;
    },
);


has test_compile => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{test_compile}
          ? $_[0]->payload->{test_compile}
          : 1;
    },
);


has auto_prereq => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{auto_prereq}
          ? $_[0]->payload->{auto_prereq}
          : 1;
    },
);


has fake_release => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{fake_release} },
);


has tag_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{tag_regexp}
          ? $_[0]->payload->{tag_regexp}
          : '^release-(\d+\.\d+)$',;
    },
);


has compile_for_debian => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);


has tag_format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{tag_format}
          ? $_[0]->payload->{tag_format}
          : 'release-%v',;
    },
);


has git_remote => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{git_remote}
          ? $_[0]->payload->{git_remote}
          : 'origin',;
    },
);

sub configure {
    my $self = shift;

    my @push_to = ( 'origin', 'origin build/master' );
    push @push_to, $self->git_remote if $self->git_remote ne 'origin';

    $self->add_plugins(

# version number use Autoversion Plugin if no_git is set else use Git::NextVersion based on version_regexp or default version regex
        (
            $self->no_git
            ? 'AutoVersion'
            : [
                'Git::NextVersion' =>
                  { version_regexp => $self->version_regexp }
            ]
        ),
        'PerlTidy',

        # contributors
        (
            $self->no_git
            ? ()
            : 'Git::Contributors'
        ),

        [
            'PruneCruft' => {
                except => '\.travis.yml',
              }    # core
        ],

        'ManifestSkip',    # core

        # file munging
        'OurPkgVersion',
        'InsertCopyright',

        (
            $self->is_task
            ? 'TaskWeaver'
            : [ 'PodWeaver' => { config_plugin => $self->weaver_config } ]
        ),

        # generated distribution files
        'ReadmeAnyFromPod',    # in build dir
        [
            ReadmeAnyFromPod => ReadmePodInRoot =>
              {    # also generate README.pod in root for github, etc.
                type     => 'pod',
                filename => 'README.pod',
                location => 'root',
              }
        ],
        [
            ReadmeAnyFromPod => ReadmeMarkdownInRoot =>
              { # also generate README.md (github friendly) file for github, etc.
                type     => 'markdown',
                filename => 'README.md',
                location => 'root',
              }
        ],

        'License',    # core

        # generated t/ tests
        (
            $self->test_compile
            ? [ 'Test::Compile' => { fake_home => 1 } ]
            : ()
        ),
        [ 'Test::MinimumVersion' => { max_target_perl => '5.010' } ],
        'Test::ReportPrereqs',

        # gather and prune
        (
            $self->no_git
            ? [
                'GatherDir' => {
                    exclude_filename => $self->exclude_filename,
                    include_dotfiles => 1,
                },
              ]    # core
            : [
                'Git::GatherDir' => {
                    exclude_filename => $self->exclude_filename,
                    include_dotfiles => 1,
                },
            ]
        ),

        #Automatically put Resources which need not be specified manually
        [
            AutoMetaResourcesPrefixed => {
                'repository.github' => 'user:shantanubhadoria',
                'bugtracker.github' => 'user:shantanubhadoria',
                'bugtracker.rt'     => 0,
                'homepage'          => 'https://metacpan.org/release/%{dist}',
            }
        ],

        # generated xt/ tests
        (
            $self->no_spellcheck ? ()
            : [ 'Test::PodSpelling' => { stopwords => $self->stopwords } ]
        ),
        (
            $self->no_critic ? ()
            : ('Test::Perl::Critic')
        ),
        (
            $self->test_kwalitee
            ? [
                'Test::Kwalitee::Extra' => {
                    has_corpus => 0,
                },
              ]
            : ()
        ),
        'MetaTests',         # core
        'PodSyntaxTests',    # core
        (
            $self->no_coverage
            ? ()
            : ('PodCoverageTests')    # core
        ),
        'Test::Version',

        # metadata
        'MinimumPerl',
        (
            $self->auto_prereq
            ? [ 'AutoPrereqs' => { skip => "^t::lib" } ]
            : ()
        ),

        [
            MetaNoIndex => {
                directory => [qw/t xt examples corpus inc/],
                'package' => [qw/DB/]
            }
        ],
        [ 'MetaProvides::Package' => { meta_noindex => 1 } ]
        ,    # AFTER MetaNoIndex

        'MetaYAML'
        ,    # core : Helps avoid kwalitee croaks and supports older systems
        'MetaJSON',    # core
        [
            'ChangelogFromGit::CPAN::Changes' => {
                tag_regexp             => $self->tag_regexp,
                parse_version_from_tag => 1,
                transform_version_tag  => 1,
                file_name              => 'Changes',
            }
        ],
        (
            $self->compile_for_debian
            ? [
                'ChangelogFromGit::Debian' => {
                    tag_regexp             => $self->tag_regexp,
                    parse_version_from_tag => 1,
                    file_name              => 'debian/changelog',
                    maintainer_name        => 'Shantanu Bhadoria',
                    maintainer_email       => 'shantanu@cpan.org',
                }
              ]
            : ()
        ),
        (
            $self->compile_for_debian
            ? [
                'Control::Debian' => {
                    file_name        => 'debian/control',
                    maintainer_name  => 'Shantanu Bhadoria',
                    maintainer_email => 'shantanu@cpan.org',
                }
              ]
            : ()
        ),

        # build system
        'ExecDir',     # core
        'ShareDir',    # core
        (
            $self->skip_makemaker
            ? ()
            : $self->makemaker
        ),             # core

        # manifest -- must come after all generated files
        'Manifest',    # core

        # before release
        (
            $self->no_git
            ? ()
            : [
                'Git::Check' => {
                    allow_dirty => [
                        qw/dist.ini Changes README.md README.pod META.yml META.json .travis.yml/
                    ]
                }
            ]
        ),
        'CheckMetaResources',
        'CheckPrereqsIndexed',
        'CheckExtraTests',
        'TestRelease',       # core
        'ConfirmRelease',    # core
        (
            $self->no_commitbuild
            ? ()
            : (
                [
                    'Git::CommitBuild' => 'Commit_to_build' => {
                        release_branch  => 'build/%b',
                        release_message => 'Release build of v%v (on %b)'
                    }
                ]
            )
        ),

        # release
        ( $self->fake_release ? 'FakeRelease' : 'UploadToCPAN' ),    # core

        # after release
        # Note -- NextRelease is here to get the ordering right with
        # git actions.  It is *also* a file munger that acts earlier

        # commit dirty Changes, dist.ini, README.pod, META.json, META.yml
        (
            $self->no_git
            ? ()
            : (
                [
                    'Git::Commit' => 'Commit_Dirty_Files' => {
                        allow_dirty => [qw/dist.ini README.md .travis.yml/]
                    }
                ],
                [ 'Git::Tag' => { tag_format => $self->tag_format } ],
            )
        ),

        # bumps Changes
        [
            'NextRelease' => {
                format => '%n%v%n%n%t- %{yyyy-MM-dd HH:mm:ss VVVV}d%n',
            },
        ],    # core (also munges files)

        (
            $self->no_git
            ? ()
            : (
                [
                    'Git::Commit' => 'Commit_Changes' =>
                      { commit_msg => "Bump Changes" }
                ],

                [ 'Git::Push' => { push_to => \@push_to } ],
            )
        ),
    );
}
__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Dist Zilla Plugin Bundle the way I like to use it

#
# This file is part of Dist-Zilla-PluginBundle-SHANTANU
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::SHANTANU - Dist Zilla Plugin Bundle the way I like to use it



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Dist-Zilla-PluginBundle-SHANTANU"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Dist-Zilla-PluginBundle-SHANTANU.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Zilla-PluginBundle-SHANTANU%200.43"><img src="https://badgedepot.code301.com/badge/cpantesters/Dist-Zilla-PluginBundle-SHANTANU/0.43" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Dist-Zilla-PluginBundle-SHANTANU-0.43"><img src="https://badgedepot.code301.com/badge/kwalitee/Dist-Zilla-PluginBundle-SHANTANU/0.43" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.43

=head1 SYNOPSIS

   # in dist.ini
     [@SHANTANU]

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle. The way I use it. While this bundle is
customized to my needs, others might be better of forking this repository and
modifying it to their own needs or using the more mature Plugin bundles that
this is derived from like the one by David Golden.

=head1 ATTRIBUTES

=head2 makemaker

makemaker attribute By default uses [MakeMaker::Awesome] This can be overriden by defining this attribute

=head2 skip_makemaker

Skip Default Makemaker option to add your own plugin for generating makefile

=head2 no_git

no_git attribute

=head2 no_commitbuild

no_commitbuild attribute, do not create a build branch

=head2 version_regexp

version_regexp attribute

=head2 is_task

Use Taskweaver in lieu of PodWeaver

=head2 weaver_config

PodWeaver config_plugin attribute

=head2 no_spellcheck

Skip spelling checks

=head2 exclude_filename

list of filenames to exclude e.g.
    exclude_filename=dist.ini
    exclude_filename=META.json
    exclude_filename=META.yml

=head2 stopwords

Stopwords to exclude for spell checks in pod

=head2 no_critic

Skip Perl Critic Checks

=head2 no_coverage

Skip Pod Coverage tests

=head2 test_kwalitee

Create kwalitee tests.

=head2 test_compile

Create compile tests.

=head2 auto_prereq

Automatically get prerequisites(default 1)

=head2 fake_release

=head2 tag_regexp

Regex for obtaining the version number from git tag

=head2 compile_for_debian

generate debian specific files like control etc. Useful if you are using dh-make-perl for building .deb files from your package

=head2 tag_format

Git Tag format

=head2 git_remote

=for stopwords autoprereq dagolden fakerelease pluginbundle podweaver
taskweaver uploadtocpan dist ini

=for Pod::Coverage configure mvp_multivalue_args

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

=over

=item *

C<<< is_task >>> -- this indicates whether TaskWeaver or PodWeaver should be used.
Default is 0.

=item *

C<<< auto_prereq >>> -- this indicates whether AutoPrereq should be used or not.
Default is 1.

=item *

C<<< tag_format >>> -- given to C<<< Git::Tag >>>.  Default is 'release-%v' to be more
robust than just the version number when parsing versions for
C<<< Git::NextVersion >>>

=item *

C<<< version_regexp >>> -- given to C<<< Git::NextVersion >>>.  Default
is '^release-(.+)$'

=item *

C<<< fake_release >>> -- swaps FakeRelease for UploadToCPAN. Mostly useful for
testing a dist.ini without risking a real release.

=item *

C<<< weaver_config >>> -- specifies a Pod::Weaver bundle.  Defaults to @SHANTANU.

=item *

C<<< stopwords >>> -- add stopword for Test::PodSpelling (can be repeated)

=item *

C<<< no_git >>> -- bypass all git-dependent plugins

=item *

C<<< no_critic >>> -- omit Test::Perl::Critic tests

=item *

C<<< no_spellcheck >>> -- omit Test::PodSpelling tests

=item *

C<<< no_coverage >>> -- omit Pod Coverage tests

=back

When running without git, CE<lt>GatherDirE<gt> is used instead of CE<lt>Git::GatherDirE<gt>,
CE<lt>AutoVersionE<gt> is used instead of CE<lt>Git::NextVersionE<gt>, and all git check and
commit operations are disabled.

This PluginBundle now supports ConfigSlicer, so you can pass in options to the
plugins used like this:

   [@SHANTANU]
   ExecDir.dir = scripts ; overrides ExecDir

=head1 COMMON PATTERNS

=head2 use github instead of RT

   [@SHANTANU]
   :version = 0.32
   AutoMetaResourcesPrefixed.bugtracker.github = user:shantanu
   AutoMetaResourcesPrefixed.bugtracker.rt = 0

=head1 SEE ALSO

=over

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=item *

L<Dist::Zilla::Plugin::TaskWeaver>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-dist-zilla-pluginbundle-shantanu/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-dist-zilla-pluginbundle-shantanu>

  git clone git://github.com/shantanubhadoria/perl-dist-zilla-pluginbundle-shantanu.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Shantanu Bhadoria

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Shantanu Bhadoria <shantanu att cpan dott org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
