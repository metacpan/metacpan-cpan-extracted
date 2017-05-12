package Dist::Zilla::PluginBundle::Starter;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer',
  'Dist::Zilla::Role::PluginBundle::PluginRemover';
use namespace::clean;

our $VERSION = '0.005';

# Revisions can include entries with the standard plugin name, array ref of plugin/name/config,
# or coderefs which are passed the pluginbundle object and return a list of plugins in one of these formats.
my %revisions = (
  1 => [
    'GatherDir',
    'PruneCruft',
    'ManifestSkip',
    'MetaConfig',
    'MetaProvides::Package',
    ['MetaNoIndex' => { directory => [qw(t xt inc share eg examples)] }],
    'MetaYAML',
    'MetaJSON',
    'License',
    'ReadmeAnyFromPod',
    'ExecDir',
    'ShareDir',
    'PodSyntaxTests',
    'Test::ReportPrereqs',
    ['Test::Compile' => { xt_mode => 1 }],
    'MakeMaker',
    'Manifest',
    'TestRelease',
    'RunExtraTests',
    'ConfirmRelease',
    \&_releaser,
  ],
  2 => [
    'GatherDir',
    'PruneCruft',
    'ManifestSkip',
    'MetaConfig',
    ['MetaProvides::Package' => { inherit_version => 0 }],
    ['MetaNoIndex' => { directory => [qw(t xt inc share eg examples)] }],
    'MetaYAML',
    'MetaJSON',
    'License',
    'Pod2Readme',
    \&_execdir,
    'ShareDir',
    'PodSyntaxTests',
    'Test::ReportPrereqs',
    ['Test::Compile' => { xt_mode => 1 }],
    \&_installer,
    'Manifest',
    'TestRelease',
    'RunExtraTests',
    'ConfirmRelease',
    \&_releaser,
  ],
);

my %allowed_installers = (
  MakeMaker => 1,
  'MakeMaker::Awesome' => 1,
  ModuleBuildTiny => 1,
  'ModuleBuildTiny::Fallback' => 1,
);

my %option_requires = (
  installer => 2,
);

sub configure {
  my $self = shift;
  my $revision = $self->payload->{revision};
  $revision = '1' unless defined $revision;
  die "Unknown [\@Starter] revision specified: $revision\n"
    unless exists $revisions{$revision};
  my @plugins = @{$revisions{$revision}};
  
  foreach my $option (keys %option_requires) {
    my $required = $option_requires{$option};
    my $value = $self->payload->{$option};
    die "Option $option requires revision $required\n"
      if defined $value and $required > $revision;
  }
  
  foreach my $plugin (@plugins) {
    if (ref $plugin eq 'CODE') {
      $self->add_plugins($plugin->($self));
    } else {
      $self->add_plugins($plugin);
    }
  }
}

sub _execdir {
  my ($self) = @_;
  my $installer = $self->payload->{installer};
  if (defined $installer and $installer =~ m/^ModuleBuildTiny/) {
    return ['ExecDir' => {dir => 'script'}];
  } else {
    return 'ExecDir';
  }
}

sub _installer {
  my ($self) = @_;
  my $installer = $self->payload->{installer};
  return 'MakeMaker' unless defined $installer;
  die "Unsupported installer $installer\n"
    unless $allowed_installers{$installer};
  return $installer;
}

sub _releaser {
  my ($self) = @_;
  return $ENV{FAKE_RELEASE} ? 'FakeRelease' : 'UploadToCPAN';
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::PluginBundle::Starter - A minimal Dist::Zilla plugin bundle

=head1 SYNOPSIS

  ; dist.ini
  name    = My-Cool-Distribution
  author  = Example Jones <jones@example.com>
  license = Perl_5
  copyright_holder = Example Jones
  copyright_year   = 2017
  version = 0.001
  
  [@Starter]           ; all that is needed to start
  revision = 2         ; always defaults to revision 1
  
  ; configuring examples
  -remove = GatherDir  ; to use [Git::GatherDir] instead, for example
  ExecDir.dir = script ; change the directory used by [ExecDir]

=head1 DESCRIPTION

The C<[@Starter]> plugin bundle for L<Dist::Zilla> is designed to do the
minimal amount of work to release a complete distribution reliably. It is
similar in purpose to L<[@Basic]|Dist::Zilla::PluginBundle::Basic>, but with
additional features to stay up to date and allow greater customization. The
selection of included plugins is intended to be unopinionated and unobtrusive,
so that it is usable for any well-formed CPAN distribution. If you're just
getting started with L<Dist::Zilla>, check out the tutorials at
L<http://dzil.org>.

Migrating from C<[@Basic]> is easy for most cases. Most of the bundle is the
same, so just make sure to remove any extra plugins that C<[@Starter]> already
includes, and configure the included plugins if needed (see L</"CONFIGURING">).
Migrating a more complex set of plugins, including some that interact with the
additional generated files, may require more careful consideration.

C<[@Starter]> composes the L<PluginRemover|Dist::Zilla::Role::PluginBundle::PluginRemover>
and L<Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer> roles to
make it easier to customize and extend. Also, it supports bundle revisions
specified as an option, in order to incorporate future changes to distribution
packaging and releasing practices. Existing revisions will not be changed to
preserve backwards compatibility.

The C<FAKE_RELEASE> environment variable is supported as in L<Dist::Milla> and
L<Minilla>. It replaces the L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN>
plugin with L<[FakeRelease]|Dist::Zilla::Plugin::FakeRelease>, to test the
release process (including any version bumping and commits!) without actually
uploading to CPAN.

  $ FAKE_RELEASE=1 dzil release

For one-line initialization of a new C<[@Starter]>-based distribution, try
L<Dist::Zilla::MintingProfile::Starter>.

Another simple way to use L<Dist::Zilla> is with L<Dist::Milla>, an opinionated
bundle that requires no configuration and performs all of the tasks in
L</"EXTENDING"> by default.

=head1 OPTIONS

C<[@Starter]> currently only has a few direct options; it can be further
configured by the composed roles, as in L</"CONFIGURING">.

=head2 revision

  [@Starter]
  revision = 2

Selects the revision to use, from L</"REVISIONS">. Defaults to revision 1.

=head2 installer

Requires revision 2 or higher.

  [@Starter]
  revision = 2
  installer = ModuleBuildTiny

  [@Starter]
  revision = 2
  installer = MakeMaker::Awesome
  MakeMaker::Awesome.WriteMakefile_arg[0] = (clean => { FILES => 't/generated/*' })

The default installer is L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker>, which
works with no extra configuration for most cases. The C<installer> option can
be used to replace it with one of the following supported installers, which can
then be configured in the same way as shown in L</"CONFIGURING">.

L<[MakeMaker::Awesome]|Dist::Zilla::Plugin::MakeMaker::Awesome> is useful if
you need to customize the generated F<Makefile.PL>.

L<[ModuleBuildTiny]|Dist::Zilla::Plugin::ModuleBuildTiny> will generate a
simple F<Build.PL> using L<Module::Build::Tiny>, but this may not work
correctly with old versions of the L<CPAN>.pm installer or if you use features
incompatible with L<Module::Build::Tiny>.

L<[ModuleBuildTiny::Fallback]|Dist::Zilla::Plugin::ModuleBuildTiny::Fallback>
generates a more complex F<Build.PL> that uses L<Module::Build::Tiny> by
default, but falls back to L<Module::Build> on old versions of the L<CPAN>.pm
installer that don't understand configure dependencies.

When using a L<Module::Build::Tiny>-based installer, the
L<[ExecDir]|Dist::Zilla::Plugin::ExecDir> plugin will be set to mark the
F<script/> directory for executables instead of the default F<bin/>.

=head1 REVISIONS

The C<[@Starter]> plugin bundle supports the following revisions.

=head2 Revision 1

Revision 1 is the default and is equivalent to using the following plugins:

=over 2

=item L<[GatherDir]|Dist::Zilla::Plugin::GatherDir>

=item L<[PruneCruft]|Dist::Zilla::Plugin::PruneCruft>

=item L<[ManifestSkip]|Dist::Zilla::Plugin::ManifestSkip>

=item L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>

=item L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>

=item L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex>

  directory = t
  directory = xt
  directory = inc
  directory = share
  directory = eg
  directory = examples

=item L<[MetaYAML]|Dist::Zilla::Plugin::MetaYAML>

=item L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON>

=item L<[License]|Dist::Zilla::Plugin::License>

=item L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod>

=item L<[ExecDir]|Dist::Zilla::Plugin::ExecDir>

=item L<[ShareDir]|Dist::Zilla::Plugin::ShareDir>

=item L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>

=item L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>

=item L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>

  xt_mode = 1

=item L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker>

=item L<[Manifest]|Dist::Zilla::Plugin::Manifest>

=item L<[TestRelease]|Dist::Zilla::Plugin::TestRelease>

=item L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests>

=item L<[ConfirmRelease]|Dist::Zilla::Plugin::ConfirmRelease>

=item L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN>

=back

This revision differs from L<[@Basic]|Dist::Zilla::PluginBundle::Basic> as
follows:

=over 2

=item *

Uses L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod>
instead of L<[Readme]|Dist::Zilla::Plugin::Readme>.

=item *

Uses L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests> instead of
L<[ExtraTests]|Dist::Zilla::Plugin::ExtraTests>.

=item *

Includes the following additional plugins:
L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON>,
L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>,
L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>,
L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex>,
L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>,
L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>,
L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>.

=back

=head2 Revision 2

Revision 2 is similar to Revision 1, with these differences:

=over 2

=item *

Sets the option
L<"inherit_version" in [MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package/"inherit_version">
to 0 by default, so that C<provides> metadata will use individual module
versions if they differ from the distribution version.

=item *

L<[Pod2Readme]|Dist::Zilla::Plugin::Pod2Readme> is used instead of
L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod> to generate the
plaintext F<README>, as it is a simpler plugin for this purpose. It takes the
same C<filename> and C<source_filename> options, but does not allow further
configuration, and does not automatically use a C<.pod> file as the source.

=item *

The L</"installer"> option is now supported to change the installer plugin.

=back

=head1 CONFIGURING

By using the L<PluginRemover|Dist::Zilla::Role::PluginBundle::PluginRemover> or
L<Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer> role options,
the C<[@Starter]> bundle's included plugins can be customized as desired. Here
are some examples:

=head2 GatherDir

If the distribution is using git source control, it is often helpful to replace
the default L<[GatherDir]|Dist::Zilla::Plugin::GatherDir> plugin with
L<[Git::GatherDir]|Dist::Zilla::Plugin::Git::GatherDir>.

  [Git::GatherDir]
  [@Starter]
  -remove = GatherDir

The included L<[GatherDir]|Dist::Zilla::Plugin::GatherDir> plugin can
alternatively be configured directly. (See
L<Config::MVP::Slicer/"CONFIGURATION SYNTAX"> for an explanation of the
subscripts for slicing array attributes.)

  [@Starter]
  GatherDir.include_dotfiles = 1
  GatherDir.exclude_filename[0] = foo_bar.txt
  GatherDir.prune_directory[] = ^temp

=head2 Readme

The L<[Pod2Readme]|Dist::Zilla::Plugin::Pod2Readme> or
L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod> plugin (depending
on bundle revision) generates a plaintext F<README> from the POD text in the
distribution's L<Dist::Zilla/"main_module"> by default, but can be configured
to look elsewhere. The standard F<README> should always be plaintext, but in
order to generate a non-plaintext F<README> in addition,
L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod> can simply be used
separately. Note that POD-format F<README>s should not be included in the
distribution build because they will get indexed and installed due to an oddity
in CPAN installation tools.

  [@Starter]
  revision = 2
  Pod2Readme.source_filename = bin/foobar
  
  [ReadmeAnyFromPod / Markdown_Readme]
  type = markdown
  filename = README.md
  
  [ReadmeAnyFromPod / Pod_Readme]
  type = pod
  location = root ; do not include pod readmes in the build!

=head2 ExecDir

Some distributions use the F<script/> directory instead of F<bin/> (the
L<[ExecDir]|Dist::Zilla::Plugin::ExecDir> default) for executable scripts.

  [@Starter]
  ExecDir.dir = script

=head2 MetaNoIndex

The distribution may include additional files or directories that should not
have their contents indexed as CPAN modules. (See
L<Config::MVP::Slicer/"CONFIGURATION SYNTAX"> for an explanation of the
subscripts for slicing array attributes.)

  [@Starter]
  MetaNoIndex.file[0] = eggs/FooBar.pm
  MetaNoIndex.directory[a] = eggs
  MetaNoIndex.directory[b] = bacon

=head2 MetaProvides

The L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>
plugin will use the distribution's version (as set in F<dist.ini> or by a
plugin) as the version of each module when populating the C<provides> metadata
by default. If the distribution does not have uniform module versions, the
plugin can be configured to reflect each module's hardcoded version where
available, by setting the C<inherit_version> option to 0 (the default in bundle
L</"Revision 2">).

  [@Starter]
  MetaProvides::Package.inherit_version = 0 ; default in revision 2

With this option set to 0, it will use the main distribution version as a
fallback for any module where a version is not found. This can also be
overridden, so that if no version is found for a module, no version will be
specified for it in metadata, by setting C<inherit_missing> to 0 as well.

  [@Starter]
  MetaProvides::Package.inherit_version = 0
  MetaProvides::Package.inherit_missing = 0

=head1 EXTENDING

This bundle includes a basic set of plugins for releasing a distribution, but
there are many more common non-intrusive tasks that L<Dist::Zilla> can help
with simply by using additional plugins in the F<dist.ini>.

=head2 Name

To automatically set the distribution name from the current directory, use
L<[NameFromDirectory]|Dist::Zilla::Plugin::NameFromDirectory>.

=head2 License and Copyright

To extract the license and copyright information from the main module, and
optionally set the author as well, use
L<[LicenseFromModule]|Dist::Zilla::Plugin::LicenseFromModule>.

=head2 Versions

A common approach to maintaining versions in L<Dist::Zilla>-managed
distributions is to automatically extract the distribution's version from the
main module, maintain uniform module versions, and bump the version during or
after each release. To extract the main module version, use
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> (which also rewrites
your module versions to match the main module version when building) or
L<[VersionFromMainModule]|Dist::Zilla::Plugin::VersionFromMainModule>. To
automatically increment module versions in the repository after each release,
use L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>.
Alternatively, you can use
L<[ReversionOnRelease]|Dist::Zilla::Plugin::ReversionOnRelease> to
automatically increment your versions in the release build, then copy the
updated modules back to the repository with
L<[CopyFilesFromRelease]|Dist::Zilla::Plugin::CopyFilesFromRelease>. Don't mix
these two version increment methods!

=head2 Changelog

To automatically add the new release version to the distribution changelog,
use L<[NextRelease]|Dist::Zilla::Plugin::NextRelease>. To ensure the release
has changelog entries, use
L<[CheckChangesHasContent]|Dist::Zilla::Plugin::CheckChangesHasContent>.

=head2 Git

To better integrate with a git workflow, use the plugins from
L<[@Git]|Dist::Zilla::PluginBundle::Git>. To automatically add contributors to
metadata from git commits, use L<[Git::Contributors]|Dist::Zilla::Plugin::Git::Contributors>.

=head2 Resources

To automatically set resource metadata from an associated GitHub repository,
use L<[GithubMeta]|Dist::Zilla::Plugin::GithubMeta>. To set resource metadata
manually, use L<[MetaResources]|Dist::Zilla::Plugin::MetaResources>.

=head2 Prereqs

To automatically set distribution prereqs from a L<cpanfile>, use
L<[Prereqs::FromCPANfile]|Dist::Zilla::Plugin::Prereqs::FromCPANfile>. To
specify prereqs manually, use L<[Prereqs]|Dist::Zilla::Plugin::Prereqs>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::PluginBundle::Basic>, L<Dist::Milla>,
L<Dist::Zilla::MintingProfile::Starter>
