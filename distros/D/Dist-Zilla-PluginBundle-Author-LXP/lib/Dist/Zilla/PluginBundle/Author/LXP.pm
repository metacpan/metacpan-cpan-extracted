package Dist::Zilla::PluginBundle::Author::LXP;
{
  $Dist::Zilla::PluginBundle::Author::LXP::VERSION = '1.0.1';
}
# ABSTRACT: configure Dist::Zilla like LXP


use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::Plugin::CheckChangesHasContent ();
use Dist::Zilla::Plugin::Git (); # for ::Check, ::Commit, ::Tag, ::Push
use Dist::Zilla::Plugin::InstallGuide ();
use Dist::Zilla::Plugin::MetaProvides::Package ();
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::NoTabsTests ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::PrereqsClean ();
use Dist::Zilla::Plugin::ReadmeAnyFromPod ();
use Dist::Zilla::Plugin::Test::Compile ();
use Dist::Zilla::Plugin::Test::EOL ();
use Dist::Zilla::Plugin::Test::Kwalitee ();
use Dist::Zilla::Plugin::Test::PodSpelling ();
use Dist::Zilla::Plugin::Test::Version ();
use Pod::Weaver::PluginBundle::Author::LXP ();

sub configure {
    my $self = shift;

    # PHASE: metadata
    $self->add_plugins(
        [ 'MetaNoIndex' => { directory => 't' } ],
        [ 'MetaProvides::Package' => { meta_noindex => 1 } ],
    );

    # PHASE: gather files
    $self->add_plugins(
        'GatherDir',
        'License',
        'MetaJSON',
        'MetaYAML',
        'Manifest',
        'Test::Compile',
        'Test::Version',
        'PodCoverageTests',
        'PodSyntaxTests',
        [ 'Test::PodSpelling' => { stopwords => 'semver' } ],
        'MetaTests',
        'Test::EOL',
        'NoTabsTests',
        'Test::Kwalitee',
    );

    # PHASE: prune files
    $self->add_plugins('PruneCruft');

    # See also: ReadmeAnyFromPod configurations below, apparently.

    # PHASE: munge files
    $self->add_plugins(
        'PkgVersion',
        [ 'PodWeaver' => { config_plugin => '@Author::LXP' } ],
        [ 'NextRelease' => {
            format      => '%-7v %{yyyy-MM-dd}d',
            time_zone   => 'UTC',
        } ],
        'ExtraTests',
    );

    # PHASE: "register prerequisites"

    # See also: PodCoverageTests configuration above.
    # See also: PodSyntaxTests configuration above.
    # See also: MetaTests configuration above.

    $self->add_plugins(
        'AutoPrereqs',
        'MinimumPerl',
        'PrereqsClean',
    );

    # See also: MakeMaker configuration below.

    # PHASE: "install tool"
    $self->add_plugins(
        'ReadmeAnyFromPod',
        [ 'ReadmeAnyFromPod' => 'PodRoot' ],
        'MakeMaker',
        'InstallGuide',
    );

    # PHASE: before release
    $self->add_plugins(
        'CheckChangesHasContent',
        [ 'Git::Check' => {
            allow_dirty => [qw{ Changes dist.ini README.pod }],
        } ],
        'TestRelease',
        'ConfirmRelease',
        'UploadToCPAN',
    );

    # PHASE: releaser
    # See also: UploadToCPAN configuration above.

    # PHASE: after release
    # See also: NextRelease configuration above.

    $self->add_plugins(
        [ 'Git::Commit' => {
            allow_dirty => [qw{ Changes dist.ini README.pod }],
            time_zone   => 'UTC',
        } ],
        [ 'Git::Tag' => { tag_message => '' } ],
        'Git::Push',
    );

    # PHASE: test runner
    # See also: MakeMaker configuration above.

    # PHASE: build runner
    # See also: MakeMaker configuration above.
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=for :stopwords Alex Peters cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::PluginBundle::Author::LXP - configure Dist::Zilla like LXP

=head1 VERSION

This module is part of distribution Dist-Zilla-PluginBundle-Author-LXP v1.0.1.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 SYNOPSIS

In F<dist.ini>:

    [@Author::LXP]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin bundle configures Dist::Zilla the way CPAN
author C<LXP> uses it, achieving the same result as these entries in a
F<dist.ini> file:

    ;; PHASE: METADATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Don't allow PAUSE/CPAN to index test libraries.  Not sure whether
    ; this is strictly needed, but better safe than sorry...
    [MetaNoIndex]
    directory = t

    ; More of the same thing.  Must appear after MetaNoIndex
    ; configuration.
    [MetaProvides::Package]
    meta_noindex = 1

    ;; PHASE: GATHER FILES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Without a GatherDir plugin, Dist::Zilla sees no files.
    [GatherDir]

    ; Add a LICENSE file to the build.  The generated POD for each
    ; module will also reference this file.
    [License]

    ; Distributions released to the CPAN include a META.json/META.yml
    ; file.  Emit both of these.
    [MetaJSON]
    [MetaYAML]

    ; Add a MANIFEST file.
    [Manifest]

    ; Add a test to ensure that all of the source code actually
    ; compiles.
    [Test::Compile]

    ; Test that everything has a $VERSION defined.
    [Test::Version]

    ; Ensure that everything is appropriately documented...
    [PodCoverageTests]

    ; ...and properly...
    [PodSyntaxTests]

    ; ...and without typos.  "semver" is added to each file by a plugin
    ; defined in Pod::Weaver::PluginBundle::Author::LXP (see PodWeaver
    ; configuration below), so explicitly whitelist that "word" here.
    [Test::PodSpelling]
    stopwords = semver

    ; Test correctness of the META.yml file.
    [MetaTests]

    ; Add some more tests for source code formatting.
    [Test::EOL]
    [NoTabsTests]

    ; Assess the distribution's readiness for CPAN.
    [Test::Kwalitee]

    ;; PHASE: PRUNE FILES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; GatherDir...but we don't want to include old builds within new
    ; ones.
    [PruneCruft]

    ; See also: ReadmeAnyFromPod configurations below, apparently.

    ;; PHASE: MUNGE FILES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Write a $VERSION declaration into each module.
    [PkgVersion]

    ; Rewrite POD into complete documents.
    [PodWeaver]
    config_plugin = @Author::LXP

    ; On build, update the version number in the built Changes file.
    ; After release, create a new section in the source Changes file.
    ; Conform to the date/time format specified by CPAN::Changes::Spec.
    [NextRelease]
    format = %-7v %{yyyy-MM-dd}d
    time_zone = UTC

    ; All of the extra tests need to be moved into the main test
    ; directory of the build in order to run.
    [ExtraTests]

    ;; PHASE: REGISTER PREREQUISITES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; See also: PodCoverageTests configuration above.
    ; See also: PodSyntaxTests configuration above.
    ; See also: MetaTests configuration above.

    ; Programmatically determine the distribution's dependencies.
    ; This information is needed for the META.* and Makefile.PL files.
    [AutoPrereqs]

    ; Determine the minimum Perl version required for the distribution.
    [MinimumPerl]

    ; Don't explicitly declare dependencies that are part of Perl
    ; itself.  This needs to be declared after all other plugins in
    ; this phase.
    [PrereqsClean]

    ; See also: MakeMaker configuration below.

    ;; PHASE: INSTALL TOOL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Add a README file to the build, generated from the finalised POD
    ; for the main module.
    [ReadmeAnyFromPod]

    ; Also generate a README POD file for the repository root.
    ; (This does not form part of the final build.)
    [ReadmeAnyFromPod / PodRoot]

    ; Emit a Makefile.PL file in the build.  This permits testing via
    ; "dzil test".
    [MakeMaker]

    ; Emit an INSTALL file with installation instructions.
    ; (Must be defined after MakeMaker configuration.)
    [InstallGuide]

    ;; PHASE: BEFORE RELEASE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Ensure that the Changes file documents somehing for the release.
    [CheckChangesHasContent]

    ; Don't allow a release to occur while there are dirty files (other
    ; than those that may have new version information written as part
    ; of the build process).
    [Git::Check]
    allow_dirty = Changes
    allow_dirty = dist.ini
    allow_dirty = README.pod

    ; Ensure that all tests pass.
    [TestRelease]

    ; If all is well, publish the distribution.
    [ConfirmRelease]
    [UploadToCPAN]

    ;; PHASE: RELEASER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; See also: UploadToCPAN configuration above.

    ;; PHASE: AFTER RELEASE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; See also: NextRelease configuration above.

    ; Commit changes to the files modified after a release.
    ; (Must be defined after NextRelease configuration.)
    [Git::Commit]
    allow_dirty = Changes
    allow_dirty = dist.ini
    allow_dirty = README.pod
    time_zone = UTC

    ; Tag releases.  Do this before pushing so that the tag is still
    ; created locally if pushing fails for some reason.  Don't create
    ; an annotated tag since another commit occurs at release time
    ; anyway.
    [Git::Tag]
    tag_message =

    ; Push changes to the remote repository when a release is made.
    [Git::Push]

    ;; PHASE: TEST RUNNER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; See also: MakeMaker configuration above.

    ;; PHASE: BUILD RUNNER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; See also: MakeMaker configuration above.

=for Pod::Coverage configure

=head1 ACKNOWLEDGEMENTS

L<Dist::Zilla::AppCommand::dumpphases>, which adds a C<dumpphases>
command to C<dzil>, was invaluable to me in better understanding
L<Dist::Zilla>'s phase ordering and better identifying which plugins
run during which phase (or in some cases, phases).

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-pluginbundle-author-lxp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-Author-LXP>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The source code for this distribution is available online in a L<Git|http://git-scm.com/> repository.  Please feel welcome to contribute patches.


L<https://github.com/lx/perl5-Dist-Zilla-PluginBundle-Author-LXP>

  git clone git://github.com/lx/perl5-Dist-Zilla-PluginBundle-Author-LXP

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
'LICENSE' file included with this distribution.

=cut
