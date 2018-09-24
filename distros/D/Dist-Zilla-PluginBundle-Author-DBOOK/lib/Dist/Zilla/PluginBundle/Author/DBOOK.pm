package Dist::Zilla::PluginBundle::Author::DBOOK;

use Moose;
use Scalar::Util 'blessed';
with 'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer',
  'Dist::Zilla::Role::PluginBundle::PluginRemover';
use namespace::clean;
use Data::Section -setup;

our $VERSION = '0.037';

sub configure {
	my $self = shift;
	
	my %accepted_installers = map { ($_ => 1) }
		qw(MakeMaker MakeMaker::Awesome ModuleBuildTiny ModuleBuildTiny::Fallback);
	my $installer = $self->payload->{installer} // 'MakeMaker';
	unless (exists $accepted_installers{$installer}) {
		die "Invalid installer $installer. Possible installers: " .
			join(', ', sort keys %accepted_installers) . "\n";
	}
	my $install_with_makemaker = ($installer =~ /^ModuleBuild/) ? 0 : 1;
	
	my $user = $self->payload->{github_user} // 'Grinnz';
	my %githubmeta_config = (issues => 1);
	$githubmeta_config{user} = $user if length $user;
	$self->add_plugins([GithubMeta => \%githubmeta_config]);
	$self->add_plugins([ReadmeAnyFromPod => 'Readme_Github' => { type => 'pod', filename => 'README.pod', location => 'root', phase => 'release' }]);
	$self->add_plugins([GenerateFile => 'Generate_Contrib' => { filename => 'CONTRIBUTING.md', content => [split /\n/, ${$self->section_data('CONTRIBUTING.md')}] }]);
	$self->add_plugins('MetaConfig');
	$self->add_plugins('MetaProvides::Package', 'Prereqs::FromCPANfile', 'Git::Contributors');
	$self->add_plugins([MetaNoIndex => { directory => [ qw/t xt inc share eg examples/ ] }]);
	
	my $irc = $self->payload->{irc} // '';
	if (length $irc) {
	  $self->add_plugins([MetaResources => { x_IRC => $irc }]);
	}
	
	my @from_build = qw(INSTALL LICENSE CONTRIBUTING.md META.json);
	push @from_build, $install_with_makemaker ? 'Makefile.PL' : 'Build.PL';
	my @ignore_files = qw(Build.PL Makefile.PL);
	my @dirty_files = qw(dist.ini Changes README.pod);
	my $versioned_match = '^(?:lib|script|bin)/';
	
	# @Git and versioning
	$self->add_plugins(
		'CheckChangesHasContent',
		['Git::Check' => { allow_dirty => \@dirty_files }],
		'RewriteVersion',
		[NextRelease => { format => '%-9v %{yyyy-MM-dd HH:mm:ss VVV}d%{ (TRIAL RELEASE)}T' }],
		[CopyFilesFromRelease => { filename => \@from_build }],
		['Git::Commit' => { allow_dirty => [@dirty_files, @from_build], add_files_in => '/' }],
		'Git::Tag',
		[BumpVersionAfterRelease => { munge_makefile_pl => 0, munge_build_pl => 0 }],
		['Git::Commit' => 'Commit_Version_Bump' => { allow_dirty_match => $versioned_match, commit_msg => 'Bump version' }],
		'Git::Push');
	
	# Pod tests
	if ($self->payload->{pod_tests}) {
		$self->add_plugins('PodSyntaxTests');
		$self->add_plugins('PodCoverageTests') unless $self->payload->{pod_tests} eq 'syntax';
	}
	
	# Report prereqs
	my $version_extractor = $install_with_makemaker ? 'ExtUtils::MakeMaker' : 'Module::Metadata';
	$self->add_plugins(['Test::ReportPrereqs' => { version_extractor => $version_extractor }]);
	
	$self->add_plugins(
		['Git::GatherDir' => { exclude_filename => [@ignore_files, @from_build] }],
		['Regenerate::AfterReleasers' => { plugins => ['@Author::DBOOK/Readme_Github', '@Author::DBOOK/CopyFilesFromRelease'] }]);
	# @Basic, with some modifications
	$self->add_plugins(qw/PruneCruft ManifestSkip MetaYAML MetaJSON
		License ReadmeAnyFromPod ExecDir ShareDir/);
	$self->add_plugins([ExecDir => 'ScriptDir' => { dir => 'script' }]);
	$self->add_plugins($installer);
	$self->add_plugins(qw/RunExtraTests InstallGuide Manifest TestRelease ConfirmRelease/);
	$self->add_plugins($ENV{FAKE_RELEASE} ? 'FakeRelease' : 'UploadToCPAN');
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::PluginBundle::Author::DBOOK - A plugin bundle for distributions
built by DBOOK

=head1 SYNOPSIS

 [@Author::DBOOK]
 pod_tests = 1
 installer = MakeMaker::Awesome
 MakeMaker::Awesome.test_file[] = t/*.t
 Git::GatherDir.exclude_filename[0] = bad_file
 Git::GatherDir.exclude_filename[1] = another_file

=head1 DESCRIPTION

This is the plugin bundle that DBOOK uses. It is equivalent to:

 [GithubMeta]
 issues = 1
 user = Grinnz
 
 [ReadmeAnyFromPod / Readme_Github]
 type = pod
 filename = README.pod
 location = root
 phase = release
 
 [GenerateFile / Generate_Contrib]
 filename = CONTRIBUTING.md
 content = ...
 
 [MetaConfig]
 [MetaProvides::Package]
 [Prereqs::FromCPANfile]
 [Git::Contributors]
 [MetaNoIndex]
 directory = t
 directory = xt
 directory = inc
 directory = share
 directory = eg
 directory = examples
 
 [CheckChangesHasContent]
 [Git::Check]
 allow_dirty = dist.ini
 allow_dirty = Changes
 allow_dirty = README.pod
 [RewriteVersion]
 [NextRelease]
 format = %-9v %{yyyy-MM-dd HH:mm:ss VVV}d%{ (TRIAL RELEASE)}T
 [CopyFilesFromRelease]
 filename = INSTALL
 filename = LICENSE
 filename = CONTRIBUTING.md
 filename = META.json
 filename = Makefile.PL
 [Git::Commit]
 add_files_in = /
 allow_dirty = dist.ini
 allow_dirty = Changes
 allow_dirty = README.pod
 allow_dirty = INSTALL
 allow_dirty = LICENSE
 allow_dirty = CONTRIBUTING.md
 allow_dirty = META.json
 allow_dirty = Makefile.PL
 [Git::Tag]
 [BumpVersionAfterRelease]
 munge_makefile_pl = 0
 munge_build_pl = 0
 [Git::Commit / Commit_Version_Bump]
 allow_dirty_match = ^(?:lib|script|bin)/
 commit_msg = Bump version
 [Git::Push]
 
 [Test::ReportPrereqs]
 [Git::GatherDir]
 exclude_filename = INSTALL
 exclude_filename = LICENSE
 exclude_filename = CONTRIBUTING.md
 exclude_filename = META.json
 exclude_filename = Makefile.PL
 exclude_filename = Build.PL
 [Regenerate::AfterReleasers]
 plugin = Readme_Github
 plugin = CopyFilesFromRelease
 [PruneCruft]
 [ManifestSkip]
 [MetaYAML]
 [MetaJSON]
 [License]
 [ReadmeAnyFromPod]
 [ExecDir]
 [ExecDir / ScriptDir]
 dir = script
 [ShareDir]
 [MakeMaker]
 [RunExtraTests]
 [InstallGuide]
 [Manifest]
 [TestRelease]
 [ConfirmRelease]
 [UploadToCPAN]

This bundle assumes that your git repo has the following: a L<cpanfile> with
the dist's prereqs, a C<Changes> populated for the current version (see
L<Dist::Zilla::Plugin::NextRelease>), and a C<.gitignore> including
C</Name-Of-Dist-*> but not C<Makefile.PL>/C<Build.PL> or C<META.json>.

To faciliate building the distribution for testing or installation without
L<Dist::Zilla>, and provide important information about the distribution in
the repository, several files can be copied to the repository from the build
by running L<dzil regenerate|Dist::Zilla::App::Command::regenerate>, and are
copied and committed automatically on release. These files are:
C<CONTRIBUTING.md>, C<INSTALL>, C<LICENSE>, C<Makefile.PL>/C<Build.PL>, and
C<META.json>. The file C<README.pod> will also be generated in the repository
(but not the build) by C<dzil regenerate> and C<dzil release>.

To test releasing, set the env var C<FAKE_RELEASE=1> to run everything except
the upload to CPAN.

 $ FAKE_RELEASE=1 dzil release

=head1 OPTIONS

This bundle composes the L<Dist::Zilla::Role::PluginBundle::Config::Slicer>
role, so options for any included plugin may be specified in that format. It
also composes L<Dist::Zilla::Role::PluginBundle::PluginRemover> so that plugins
may be removed. Additionally, the following options are provided.

=head2 github_user

 github_user = gitster

Set the user whose repository should be linked in metadata. Defaults to
C<Grinnz>, change this when the main repository is elsewhere. Set to an empty
string value to use the GitHub remote URL as found in the local repository, as
L<Dist::Zilla::Plugin::GithubMeta> does by default.

=head2 installer

 installer = MakeMaker::Awesome
 MakeMaker::Awesome.WriteMakefile_arg[] = (clean => { FILES => 'autogen.dat' })
 MakeMaker::Awesome.delimiter = |
 MakeMaker::Awesome.footer[00] = |{
 MakeMaker::Awesome.footer[01] = |  ...
 MakeMaker::Awesome.footer[20] = |}

 installer = ModuleBuildTiny
 ModuleBuildTiny.version_method = installed

Set the installer plugin to use. Allowed installers are
L<MakeMaker|Dist::Zilla::Plugin::MakeMaker>,
L<MakeMaker::Awesome|Dist::Zilla::Plugin::MakeMaker::Awesome>,
L<ModuleBuildTiny|Dist::Zilla::Plugin::ModuleBuildTiny>, and
L<ModuleBuildTiny::Fallback|Dist::Zilla::Plugin::ModuleBuildTiny::Fallback>.
The default is C<MakeMaker>. Options for the selected installer can be
specified using config slicing.

=head2 irc

 irc = irc://irc.perl.org/#distzilla

Set the x_IRC resource metadata using L<Dist::Zilla::Plugin::MetaResources>.

=head2 pod_tests

 pod_tests = 1

Set to a true value to add L<Dist::Zilla::Plugin::PodSyntaxTests> and
L<Dist::Zilla::Plugin::PodCoverageTests>. Set to C<syntax> to only add the
syntax tests.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Dist::Zilla>, L<cpanfile>, L<Dist::Zilla::MintingProfile::Author::DBOOK>

=cut

__DATA__
__[ CONTRIBUTING.md ]__
# HOW TO CONTRIBUTE

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.

The distribution is managed with [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).
This means that many of the usual files you might expect are not in the
repository, but are generated at release time.  Some generated files are kept
in the repository as a convenience (e.g. Build.PL/Makefile.PL and META.json).

Generally, **you do not need Dist::Zilla to contribute patches**.  You may need
Dist::Zilla to create a tarball.  See below for guidance.

## Getting dependencies

If you have App::cpanminus 1.6 or later installed, you can use
[cpanm](https://metacpan.org/pod/cpanm) to satisfy dependencies like this:

    $ cpanm --installdeps --with-develop .

You can also run this command (or any other cpanm command) without installing
App::cpanminus first, using the fatpacked `cpanm` script via curl or wget:

    $ curl -L https://cpanmin.us | perl - --installdeps --with-develop .
    $ wget -qO - https://cpanmin.us | perl - --installdeps --with-develop .

Otherwise, look for either a `cpanfile` or `META.json` file for a list of
dependencies to satisfy.

## Running tests

You can run tests directly using the `prove` tool:

    $ prove -l
    $ prove -lv t/some_test_file.t

For most of my distributions, `prove` is entirely sufficient for you to test
any patches you have. I use `prove` for 99% of my testing during development.

## Code style and tidying

Please try to match any existing coding style.  If there is a `.perltidyrc`
file, please install Perl::Tidy and use perltidy before submitting patches.

## Installing and using Dist::Zilla

[Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) is a very powerful
authoring tool, optimized for maintaining a large number of distributions with
a high degree of automation, but it has a large dependency chain, a bit of a
learning curve and requires a number of author-specific plugins.

To install it from CPAN, I recommend one of the following approaches for the
quickest installation:

    # using CPAN.pm, but bypassing non-functional pod tests
    $ cpan TAP::Harness::Restricted
    $ PERL_MM_USE_DEFAULT=1 HARNESS_CLASS=TAP::Harness::Restricted cpan Dist::Zilla

    # using cpanm, bypassing *all* tests
    $ cpanm -n Dist::Zilla

In either case, it's probably going to take about 10 minutes.  Go for a walk,
go get a cup of your favorite beverage, take a bathroom break, or whatever.
When you get back, Dist::Zilla should be ready for you.

Then you need to install any plugins specific to this distribution:

    $ dzil authordeps --missing | cpanm

You can use Dist::Zilla to install the distribution's dependencies if you
haven't already installed them with cpanm:

    $ dzil listdeps --missing --develop | cpanm

You can instead combine these two steps into one command by installing
Dist::Zilla::App::Command::installdeps then running:

    $ dzil installdeps

Once everything is installed, here are some dzil commands you might try:

    $ dzil build
    $ dzil test
    $ dzil regenerate

You can learn more about Dist::Zilla at http://dzil.org/

## Other notes

This distribution maintains the generated `META.json` and either `Makefile.PL`
or `Build.PL` in the repository. This allows two things:
[Travis CI](https://travis-ci.org/) can build and test the distribution without
requiring Dist::Zilla, and the distribution can be installed directly from
Github or a local git repository using `cpanm` for testing (again, not
requiring Dist::Zilla).

    $ cpanm git://github.com/Author/Distribution-Name.git
    $ cd Distribution-Name; cpanm .

Contributions are preferred in the form of a Github pull request. See
[Using pull requests](https://help.github.com/articles/using-pull-requests/)
for further information. You can use the Github issue tracker to report issues
without an accompanying patch.

# CREDITS

This file was adapted from an initial `CONTRIBUTING.mkdn` file from David
Golden under the terms of the [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/), with inspiration from the
contributing documents from [Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING](https://metacpan.org/pod/Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING)
and [Dist::Zilla::PluginBundle::Author::ETHER](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::ETHER).
__END__
