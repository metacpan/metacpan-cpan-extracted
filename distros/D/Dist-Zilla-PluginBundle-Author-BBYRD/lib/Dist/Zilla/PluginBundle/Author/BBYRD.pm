package Dist::Zilla::PluginBundle::Author::BBYRD;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.06'; # VERSION
# ABSTRACT: DZIL Author Bundle for BBYRD

use Moose;

use sanity;

with 'Dist::Zilla::Role::PluginBundle::Merged' => {
   mv_plugins => [ qw(
      Git::GatherDir OurPkgVersion PodWeaver Test::ReportPrereqs @TestingMania
      PruneCruft @Prereqs CheckPrereqsIndexed MetaNoIndex CopyFilesFromBuild
      Git::CheckFor::CorrectBranch @Git TravisYML Test::EOL
   ) ],
};
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';
with 'Dist::Zilla::Role::BundleDeps';

sub configure {
   my $self = shift;
   $self->add_merged(
      # [ReportPhase]
      #
      # ; Makefile.PL maker
      # [MakeMaker]
      #
      qw( ReportPhase MakeMaker ),

      # [Authority]
      # authority = cpan:BBYRD
      # locate_comment = 1
      [Authority => {
         authority      => 'cpan:BBYRD',
         locate_comment => 1,
      }],

      # [Git::NextVersion]
      # first_version = 0.90
      $self->config_short_merge('Git::NextVersion', { first_version => '0.90' }),

      #
      # [Git::GatherDir]
      #
      # ; File modifiers
      # [OurPkgVersion]
      qw( Git::GatherDir OurPkgVersion ),

      # [PodWeaver]
      # config_plugin = @Author::BBYRD
      $self->config_short_merge('PodWeaver', { config_plugin => '@Author::BBYRD' }),

      #
      # ; File pruners
      # [PruneCruft]
      #
      # ; Extra file creation
      # [ChangelogFromGit::CPAN::Changes]
      # file_name = CHANGES
      # copy_to_root = 0
      $self->config_short_merge('ChangelogFromGit::CPAN::Changes' => {
         file_name    => 'CHANGES',
         copy_to_root => 0,
      }),

      #
      # [ManifestSkip]
      # [Manifest]
      # [License]
      qw( PruneCruft ManifestSkip Manifest License ),

      # [ReadmeAnyFromPod / ReadmePodInRoot]    ; Pod README for Root (for GitHub, etc.)
      # [ReadmeAnyFromPod / ReadmeTextInBuild]  ; Text README for Build
      # [ReadmeAnyFromPod / ReadmeHTMLInBuild]  ; HTML README for Build (never POD, so it doesn't get installed)
      [ReadmeAnyFromPod => ReadmePodInRoot   => {}],
      [ReadmeAnyFromPod => ReadmeTextInBuild => {}],
      [ReadmeAnyFromPod => ReadmeHTMLInBuild => {}],

      #
      # [InstallGuide]
      # [ExecDir]
      qw( InstallGuide ExecDir ),

      #
      # ; Many tests
      # [@TestingMania]
      # disable = Test::Perl::Critic
      # disable = Test::EOL
      # disable = Test::Kwalitee
      # disable = Test::Pod::LinkCheck
      # disable = MetaTests
      # changelog = CHANGES
      $self->config_short_merge('@TestingMania' => {
         disable => [
            (map { 'Test::'.$_ } qw( Perl::Critic EOL Kwalitee Pod::LinkCheck )),
            qw( MetaTests ),
         ],
         changelog => 'CHANGES'
      }),

      #
      # ; POD tests
      # ;[Test::PodSpelling]  ; Win32 install problems
      #
      # ; Other xt/* tests
      # [RunExtraTests]
      # ;[MetaTests]  ; until Test::CPAN::Meta supports 2.0
      qw( RunExtraTests ),

      # [Test::EOL]
      # trailing_whitespace = 0
      $self->config_short_merge('Test::EOL', { trailing_whitespace => 0 }),

      # [Test::CheckDeps]
      # ;[Test::Pod::LinkCheck]  ; Both of these are borked...
      # ;[Test::Pod::No404s]     ; ...I really need to create my own
      # [Test::ReportPrereqs]
      # [Test::CheckManifest]
      (map { 'Test::'.$_ } qw(CheckDeps ReportPrereqs CheckManifest)),

      #
      # ; Prereqs
      # [@Prereqs]
      # minimum_perl = 5.10.1
      $self->config_short_merge('@Prereqs', { minimum_perl => '5.10.1' }),

      #
      # [CheckPrereqsIndexed]
      #
      # ; META maintenance
      # [MetaConfig]
      # [MetaJSON]
      # [MetaYAML]
      qw( CheckPrereqsIndexed MetaConfig MetaJSON MetaYAML ),

      #
      # [MetaNoIndex]
      # directory = t
      # directory = xt
      # directory = examples
      # directory = corpus
      $self->config_short_merge('MetaNoIndex', { directory => [qw(t xt examples corpus)] }),

      #
      # [MetaProvides::Package]
      # meta_noindex = 1        ; respect prior no_index directives
      $self->config_short_merge('MetaProvides::Package', { meta_noindex => 1 }),

      #
      # [GithubMeta]
      # issues = 1
      # user   = SineSwiper
      [GithubMeta => {
         issues => 1,
         user   => 'SineSwiper',
      }],

      #
      # [ContributorsFromGit]
      'ContributorsFromGit',
   );

   # Handle $resources->{x_IRC}
   my $x_IRC = $self->payload->{x_IRC} || $self->payload->{x_irc};
   $self->add_merged(
      #
      # [MetaResources]  ; only loaded if needed
      # x_IRC = $x_IRC

      [MetaResources => {
         x_IRC => $x_IRC,
      }],
   ) if $x_IRC;

   $self->add_merged(
      #
      # ; Post-build plugins
      # [CopyFilesFromBuild]
      # move = .gitignore
      # move = README.pod
      $self->config_short_merge('CopyFilesFromBuild', {
         move => [qw(.gitignore README.pod)],
      }),

      #
      # ; Post-build Git plugins
      # [TravisYML]
      # notify_email = 0
      # notify_irc = irc://irc.perl.org/#sanity
      # ; used for Travis::TestRelease
      # support_builddir = 1
      # ; keep sanity from balking at these
      # post_before_install_build = cpanm --quiet --notest --skip-satisfied autovivification indirect multidimensional
      $self->config_short_merge('TravisYML', {
         notify_email     => 0,
         notify_irc       => 'irc://irc.perl.org/#sanity',
         support_builddir => 1,
         post_before_install_build => 'cpanm --quiet --notest --skip-satisfied autovivification indirect multidimensional',
      }),

      #
      # [Git::CheckFor::CorrectBranch]
      'Git::CheckFor::CorrectBranch',

      # [Git::CommitBuild]
      # branch =
      # release_branch = build/%b
      # release_message = Release build of v%v (on %b)
      $self->config_short_merge('Git::CommitBuild', {
         branch          => '',
         release_branch  => 'build/%b',
         release_message => 'Release build of v%v (on %b)',
      }),

      #
      # [@Git]
      # allow_dirty = dist.ini
      # allow_dirty = .travis.yml
      # allow_dirty = README.pod
      # changelog =
      # commit_msg = Release v%v
      # push_to = origin master:master
      # push_to = origin build/master:build/master
      $self->config_short_merge('@Git', {
         allow_dirty => [qw(dist.ini .travis.yml README.pod)],
         changelog   => '',
         commit_msg  => 'Release v%v',
         push_to     => ['origin master:master', 'origin build/master:build/master'],
      }),

      #
      # [GitHub::Update]
      # metacpan = 1
      $self->config_short_merge('GitHub::Update', { metacpan => 1 }),

      #
      # [TestRelease]
      'TestRelease',

      # [Travis::TestRelease]
      # create_builddir = 1
      $self->config_short_merge('Travis::TestRelease', {
         create_builddir => 1,
         open_status_url => 1,
      }),

      # [ConfirmRelease]
      # [UploadToCPAN]
      # [InstallRelease]
      # [Clean]
      qw( ConfirmRelease UploadToCPAN InstallRelease Clean ),
   );
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::BBYRD - DZIL Author Bundle for BBYRD

=head1 SYNOPSIS

    ; Very similar to...
 
    [ReportPhase]
 
    ; Makefile.PL maker
    [MakeMaker]
 
    [Authority]
    authority = cpan:BBYRD
    locate_comment = 1
 
    [Git::NextVersion]
    first_version = 0.90
 
    [Git::GatherDir]
 
    ; File modifiers
    [OurPkgVersion]
    [PodWeaver]
    config_plugin = @Author::BBYRD
 
    ; File pruners
    [PruneCruft]
 
    ; Extra file creation
    [ChangelogFromGit::CPAN::Changes]
    file_name = CHANGES
    copy_to_root = 0
 
    [ManifestSkip]
    [Manifest]
    [License]
    [ReadmeAnyFromPod / ReadmePodInRoot]    ; Pod README for Root (for GitHub, etc.)
    [ReadmeAnyFromPod / ReadmeTextInBuild]  ; Text README for Build
    [ReadmeAnyFromPod / ReadmeHTMLInBuild]  ; HTML README for Build (never POD, so it doesn't get installed)
    [InstallGuide]
    [ExecDir]
 
    ; Many tests
    [@TestingMania]
    disable = Test::Perl::Critic
    disable = Test::EOL
    disable = Test::Kwalitee
    disable = Test::Pod::LinkCheck
    disable = MetaTests
    changelog = CHANGES
 
    ; POD tests
    ;[Test::PodSpelling]  ; Win32 install problems
 
    ; Other xt/* tests
    [RunExtraTests]
    ;[MetaTests]  ; until Test::CPAN::Meta supports 2.0
    [Test::EOL]
    trailing_whitespace = 0
 
    [Test::CheckDeps]
    ;[Test::Pod::LinkCheck]  ; Both of these are borked...
    ;[Test::Pod::No404s]     ; ...I really need to create my own
    [Test::ReportPrereqs]
    [Test::CheckManifest]
 
    ; Prereqs
    [@Prereqs]
    minimum_perl = 5.10.1
 
    [CheckPrereqsIndexed]
 
    ; META maintenance
    [MetaConfig]
    [MetaJSON]
    [MetaYAML]
 
    [MetaNoIndex]
    directory = t
    directory = xt
    directory = examples
    directory = corpus
 
    [MetaProvides::Package]
    meta_noindex = 1        ; respect prior no_index directives
 
    [GithubMeta]
    issues = 1
    user   = SineSwiper
 
    [ContributorsFromGit]
 
    [MetaResources]  ; only loaded if needed
    x_IRC = $x_IRC
 
    ; Post-build plugins
    [CopyFilesFromBuild]
    move = .gitignore
    move = README.pod
 
    ; Post-build Git plugins
    [TravisYML]
    notify_email = 0
    notify_irc = irc://irc.perl.org/#sanity
    ; used for Travis::TestRelease
    support_builddir = 1
    ; keep sanity from balking at these
    post_before_install_build = cpanm --quiet --notest --skip-satisfied autovivification indirect multidimensional
 
    [Git::CheckFor::CorrectBranch]
    [Git::CommitBuild]
    branch =
    release_branch = build/%b
    release_message = Release build of v%v (on %b)
 
    [@Git]
    allow_dirty = dist.ini
    allow_dirty = .travis.yml
    allow_dirty = README.pod
    changelog =
    commit_msg = Release v%v
    push_to = origin master:master
    push_to = origin build/master:build/master
 
    [GitHub::Update]
    metacpan = 1
 
    [TestRelease]
    [Travis::TestRelease]
    create_builddir = 1
 
    [ConfirmRelease]
    [UploadToCPAN]
    [InstallRelease]
    [Clean]
 
    ; sanity deps
    ; authordep autovivification
    ; authordep indirect
    ; authordep multidimensional

=head1 DESCRIPTION

L<I frelling hate these things|sanity>, but several releases in, I found myself
needing to keep my C<<< dist.ini >>> stuff in sync, which requires a single module to
bind them to.

=head1 NAMING SCHEME

I'm a strong believer in structured order in the chaos that is the CPAN
namespace.  There's enough cruft in CPAN, with all of the forked modules,
legacy stuff that should have been removed 10 years ago, and confusion over
which modules are available vs. which ones actually work.  (Which all stem
from the same base problem, so I'm almost repeating myself...)

Like I said, I hate writing these personalized modules on CPAN.  I even bantered
around the idea of using L<MetaCPAN's author JSON input|https://github.com/SineSwiper/Dist-Zilla-PluginBundle-BeLike-You/blob/master/BeLike-You.pod>
to store the plugin data.  However, keeping the Author plugins separated from the
real PluginBundles is a step in the right direction.  See
L<KENTNL's comments on the Author namespace|Dist::Zilla::PluginBundle::Author::KENTNL/NAMING-SCHEME>
for more information.

=head1 CAVEATS

This uses L<Dist::Zilla::Role::PluginBundle::Merged>, so all of the plugins'
arguments are available, using Merged's rules.  Special care should be
made with arguments that might not be unique with other plugins.  (Eventually,
I'll throw these into C<<< config_rename >>>.)

If this is a problem, you might want to consider using L<@Filter|Dist::Zilla::PluginBundle::Filter>.

One exception is C<<< x_IRC >>>, which is detected and passed to L<MetaResources|Dist::Zilla::Plugin::MetaResources>
properly.

=head1 SEE ALSO

In building my ultimate C<<< dist.ini >>> file, I did a bunch of research on which
modules to cram in here.  As a result, this is a pretty large set of plugins,
but that's exactly how I like my DZIL.  Feel free to research the modules
listed here, as there's a bunch of good modules that you might want to include
in your own C<<< dist.ini >>> andE<sol>or Author bundle.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Author-BBYRD>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::BBYRD/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Author-BBYRD/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 CONTRIBUTOR

=for stopwords Sergey Romanov

Sergey Romanov <complefor@rambler.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
