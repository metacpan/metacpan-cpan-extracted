package Dist::Zilla::PluginBundle::Author::DBOOK;

use Moose;
use Scalar::Util 'blessed';
with 'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer',
  'Dist::Zilla::Role::PluginBundle::PluginRemover';
use namespace::clean;
use Data::Section -setup;

our $VERSION = 'v1.0.10';

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
	$self->add_plugins(['GenerateFile::FromShareDir' => 'Generate_Contrib' => { -filename => 'CONTRIBUTING.md', -source_filename => 'CONTRIBUTING.md.tmpl', -dist => 'Dist-Zilla-PluginBundle-Author-DBOOK' }]);
	$self->add_plugins('MetaProvides::Package', 'Prereqs::FromCPANfile', 'PrereqsFile', 'Git::Contributors');
	$self->add_plugins([MetaNoIndex => { directory => [ qw/t xt inc share eg examples/ ] }]);
	
	my $irc = $self->payload->{irc} // '';
	if (length $irc) {
	  $self->add_plugins([MetaResources => { x_IRC => $irc }]);
	}
	my $irc_channel = $self->payload->{irc_channel} // '';
	if (length $irc_channel) {
		my $irc_network = $self->payload->{irc_network} // '';
		my $irc_host = $self->payload->{irc_host} // '';
		my %irc_config = (channel => $irc_channel);
		$irc_config{network} = $irc_network if length $irc_network;
		$irc_config{host} = $irc_host if length $irc_host;
		$self->add_plugins([IRC => \%irc_config]);
	}
	
	my @from_build = qw(LICENSE CONTRIBUTING.md META.json);
	push @from_build, $install_with_makemaker ? 'Makefile.PL' : 'Build.PL';
	my @ignore_files = qw(Build.PL Makefile.PL);
	my @dirty_files = qw(dist.ini Changes README.pod);
	
	# @Git and versioning
	$self->add_plugins(
		'CheckChangesHasContent',
		['Git::Check' => { allow_dirty => \@dirty_files }],
		'RewriteVersion',
		[NextRelease => { format => '%-9v %{yyyy-MM-dd HH:mm:ss VVV}d%{ (TRIAL RELEASE)}T' }],
		[CopyFilesFromRelease => { filename => \@from_build }],
		['Git::Commit' => { allow_dirty => [@dirty_files, @from_build], add_files_in => '/', commit_msg => '%v%n%n%c' }],
		['Git::Tag' => { tag_format => '%v', tag_message => '%v' }],
		[BumpVersionAfterRelease => { munge_makefile_pl => 0, munge_build_pl => 0 }],
		['Git::Commit' => 'Commit_Version_Bump' => { allow_dirty_match => '^', commit_msg => 'Bump version' }],
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
		['Regenerate::AfterReleasers' => { plugins => [$self->name . '/Readme_Github', $self->name . '/CopyFilesFromRelease'] }]);
	# @Basic, with some modifications
	$self->add_plugins(qw/PruneCruft ManifestSkip MetaYAML MetaJSON
		License Readme::Brief ExecDir ShareDir/);
	$self->add_plugins([ExecDir => 'ScriptDir' => { dir => 'script' }]);
	$self->add_plugins($installer);
	$self->add_plugins(qw/RunExtraTests Manifest TestRelease ConfirmRelease/);
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
 
 [GenerateFile::FromShareDir / Generate_Contrib]
 -filename = CONTRIBUTING.md
 -source_filename = CONTRIBUTING.md.tmpl
 -dist = Dist-Zilla-PluginBundle-Author-DBOOK
 
 [MetaProvides::Package]
 [Prereqs::FromCPANfile]
 [PrereqsFile]
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
 filename = LICENSE
 filename = CONTRIBUTING.md
 filename = META.json
 filename = Makefile.PL
 [Git::Commit]
 add_files_in = /
 allow_dirty = dist.ini
 allow_dirty = Changes
 allow_dirty = README.pod
 allow_dirty = LICENSE
 allow_dirty = CONTRIBUTING.md
 allow_dirty = META.json
 allow_dirty = Makefile.PL
 commit_msg = %v%n%n%c
 [Git::Tag]
 tag_format = %v
 tag_message = %v
 [BumpVersionAfterRelease]
 munge_makefile_pl = 0
 munge_build_pl = 0
 [Git::Commit / Commit_Version_Bump]
 allow_dirty_match = ^
 commit_msg = Bump version
 [Git::Push]
 
 [Test::ReportPrereqs]
 [Git::GatherDir]
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
 [Readme::Brief]
 [ExecDir]
 [ExecDir / ScriptDir]
 dir = script
 [ShareDir]
 [MakeMaker]
 [RunExtraTests]
 [Manifest]
 [TestRelease]
 [ConfirmRelease]
 [UploadToCPAN]

This bundle assumes that your git repo has the following: a L<cpanfile>,
F<prereqs.json>, or F<prereqs.yml> with the dist's prereqs, a F<Changes>
populated for the current version (see L<Dist::Zilla::Plugin::NextRelease>),
and a F<.gitignore> including C</Name-Of-Dist-*> but not
C<Makefile.PL>/C<Build.PL> or C<META.json>.

To faciliate building the distribution for testing or installation without
L<Dist::Zilla>, and provide important information about the distribution in
the repository, several files can be copied to the repository from the build
by running L<dzil regenerate|Dist::Zilla::App::Command::regenerate>, and are
copied and committed automatically on release. These files are:
C<CONTRIBUTING.md>, C<LICENSE>, C<Makefile.PL>/C<Build.PL>, and
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
Deprecated; use L</"irc_channel">.

=head2 irc_channel

 irc_channel = distzilla

Set the channel for IRC resource metadata using L<Dist::Zilla::Plugin::IRC>.

=head2 irc_network

 irc_network = perl

Set the network for IRC resource metadata using L<Dist::Zilla::Plugin::IRC>.

=head2 irc_host

 irc_host = irc.perl.org

Set the host for IRC resource metadata using L<Dist::Zilla::Plugin::IRC>.
Only for IRC hosts that cannot be set via L</"irc_network">.

=head2 pod_tests

 pod_tests = 1

Set to a true value to add L<Dist::Zilla::Plugin::PodSyntaxTests> and
L<Dist::Zilla::Plugin::PodCoverageTests>. Set to C<syntax> to only add the
syntax tests.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<book.d.wit@proton.me>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Dist::Zilla>, L<cpanfile>, L<Dist::Zilla::MintingProfile::Author::DBOOK>
