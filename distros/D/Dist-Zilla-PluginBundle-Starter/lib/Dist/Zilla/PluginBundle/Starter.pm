package Dist::Zilla::PluginBundle::Starter;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer',
  'Dist::Zilla::Role::PluginBundle::PluginRemover';
use namespace::clean;

our $VERSION = 'v3.0.5';

# Revisions can include entries with the standard plugin name, array ref of plugin/name/config,
# or coderefs which are passed the pluginbundle object and return a list of plugins in one of these formats.
my %revisions = (
  1 => [
    'GatherDir',
    'MetaYAML',
    'MetaJSON',
    'License',
    'ReadmeAnyFromPod',
    'PodSyntaxTests',
    'Test::ReportPrereqs',
    ['Test::Compile' => { xt_mode => 1 }],
    'MakeMaker',
    'Manifest',
    'PruneCruft',
    'ManifestSkip',
    'RunExtraTests',
    'TestRelease',
    'ConfirmRelease',
    sub { $_[0]->pluginset_releaser },
    'MetaConfig',
    ['MetaNoIndex' => { directory => [qw(t xt inc share eg examples)] }],
    'MetaProvides::Package',
    'ShareDir',
    'ExecDir',
  ],
  2 => [
    'GatherDir',
    'MetaYAML',
    'MetaJSON',
    'License',
    'Pod2Readme',
    'PodSyntaxTests',
    'Test::ReportPrereqs',
    ['Test::Compile' => { xt_mode => 1 }],
    sub { $_[0]->pluginset_installer },
    'Manifest',
    'PruneCruft',
    'ManifestSkip',
    'RunExtraTests',
    'TestRelease',
    'ConfirmRelease',
    sub { $_[0]->pluginset_releaser },
    'MetaConfig',
    ['MetaNoIndex' => { directory => [qw(t xt inc share eg examples)] }],
    ['MetaProvides::Package' => { inherit_version => 0 }],
    'ShareDir',
    sub { $_[0]->pluginset_execdir },
  ],
  3 => [
    sub { $_[0]->pluginset_gatherer },
    'MetaYAML',
    'MetaJSON',
    'License',
    'Pod2Readme',
    'PodSyntaxTests',
    'Test::ReportPrereqs',
    ['Test::Compile' => { xt_mode => 1 }],
    sub { $_[0]->pluginset_installer },
    'Manifest',
    'PruneCruft',
    'ManifestSkip',
    'RunExtraTests',
    sub { $_[0]->pluginset_release_management }, # before test/confirm for before-release verification
    'TestRelease',
    'ConfirmRelease',
    sub { $_[0]->pluginset_releaser },
    'MetaConfig',
    ['MetaNoIndex' => { directory => [qw(t xt inc share eg examples)] }],
    sub { $_[0]->pluginset_metaprovides },
    'ShareDir',
    sub { $_[0]->pluginset_execdir },
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
  managed_versions => 3,
  regenerate => 3,
);

has revision => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->payload->{revision} // 1 },
);

has installer => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->payload->{installer} // 'MakeMaker' },
);

has managed_versions => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->payload->{managed_versions} // 0 },
);

has regenerate => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->payload->{regenerate} // [] },
);

sub mvp_multivalue_args { qw(regenerate) }

sub configure {
  my $self = shift;
  my $name = $self->name;
  my $revision = $self->revision;
  die "Unknown [$name] revision specified: $revision\n"
    unless exists $revisions{$revision};
  my @plugins = @{$revisions{$revision}};
  
  foreach my $option (keys %option_requires) {
    my $required = $option_requires{$option};
    die "Option $option requires revision $required\n"
      if exists $self->payload->{$option} and $required > $revision;
  }
  
  foreach my $plugin (@plugins) {
    if (ref $plugin eq 'CODE') {
      $self->add_plugins($plugin->($self));
    } else {
      $self->add_plugins($plugin);
    }
  }
}

sub gather_plugin { 'GatherDir' }

sub pluginset_gatherer {
  my ($self) = @_;
  my @copy = @{$self->regenerate};
  return [$self->gather_plugin => { exclude_filename => [@copy] }] if @copy;
  return $self->gather_plugin;
}

sub pluginset_installer {
  my ($self) = @_;
  my $installer = $self->installer;
  die "Unsupported installer $installer\n"
    unless $allowed_installers{$installer};
  return "$installer";
}

sub pluginset_release_management {
  my ($self) = @_;
  my $versions = $self->managed_versions;
  my @copy_files = @{$self->regenerate};
  my @plugins;
  push @plugins, 'RewriteVersion',
    [NextRelease => { format => '%-9v %{yyyy-MM-dd HH:mm:ss VVV}d%{ (TRIAL RELEASE)}T' }]
    if $versions;
  push @plugins,
    [CopyFilesFromRelease => { filename => [@copy_files] }],
    ['Regenerate::AfterReleasers' => { plugin => $self->name . '/CopyFilesFromRelease' }],
    if @copy_files;
  push @plugins, 'BumpVersionAfterRelease' if $versions;
  return @plugins;
}

sub pluginset_releaser {
  my ($self) = @_;
  return $ENV{FAKE_RELEASE} ? 'FakeRelease' : 'UploadToCPAN';
}

sub pluginset_metaprovides {
  my ($self) = @_;
  if ($self->managed_versions) {
    return 'MetaProvides::Package';
  } else {
    return ['MetaProvides::Package' => { inherit_version => 0 }];
  }
}

sub pluginset_execdir {
  my ($self) = @_;
  my $installer = $self->installer;
  if ($installer =~ m/^ModuleBuildTiny/) {
    return ['ExecDir' => {dir => 'script'}];
  } else {
    return 'ExecDir';
  }
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
  revision = 3         ; always defaults to revision 1
  
  ; configuring examples
  installer = ModuleBuildTiny
  -remove = GatherDir  ; to use [Git::GatherDir] instead, for example
  ExecDir.dir = script ; change the directory used by [ExecDir]
  managed_versions = 1 ; uses the main module version, and bumps module versions after release
  regenerate = LICENSE ; copy LICENSE to root after release and dzil regenerate

  [@Starter::Git]      ; drop-in variant bundle for git workflows
  revision = 3         ; requires/defaults to revision 3

=head1 DESCRIPTION

The C<[@Starter]> plugin bundle for L<Dist::Zilla> is designed to do the
minimal amount of work to release a complete distribution reliably. It is
similar in purpose to L<[@Basic]|Dist::Zilla::PluginBundle::Basic>, but with
additional features to stay up to date and allow greater customization. The
selection of included plugins is intended to be unopinionated and unobtrusive,
so that it is usable for any well-formed CPAN distribution.

The L<Dist::Zilla::Starter> guide is a starting point if you are new to
L<Dist::Zilla> or CPAN distribution building. See L</"EXAMPLES"> for example
configurations of this bundle.

For a variant of this bundle with built-in support for a git-based workflow,
see L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git>.

For one-line initialization of a new C<[@Starter]>-based distribution, try
L<Dist::Zilla::MintingProfile::Starter> (or
L<Dist::Zilla::MintingProfile::Starter::Git>).

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

Another simple way to use L<Dist::Zilla> is with L<Dist::Milla>, an opinionated
bundle that requires no configuration and performs all of the tasks in
L</"EXTENDING"> by default. This bundle can also be configured to operate much
like L<Dist::Milla>, as in the L</"Dist::Milla equivalent"> example.

=head1 EXAMPLES

Some example F<dist.ini> configurations to get started with.

=head2 Just the basics

  name    = Acme-Foo
  author  = Jane Doe <example@example.com>
  license = Artistic_2_0
  copyright_holder = Jane Doe
  copyright_year   = 2019
  version = 1.00

  [@Starter]
  revision = 3

  [Prereqs / RuntimeRequires]
  perl = 5.010001
  Exporter = 5.57
  Path::Tiny = 0

  [Prereqs / TestRequires]
  Test::More = 0.88

=head2 Managed boilerplate

  name    = Acme-Foo
  author  = Jane Doe <example@example.com>
  license = Artistic_2_0
  copyright_holder = Jane Doe
  copyright_year   = 2019

  [@Starter::Git]
  revision = 3
  managed_versions = 1
  regenerate = Makefile.PL
  regenerate = META.json
  regenerate = LICENSE

  [AutoPrereqs]

=head2 Dist::Milla equivalent

  [CheckChangesHasContent]

  [ReadmeAnyFromPod]
  type = markdown
  filename = README.md
  location = root
  phase = release
  [Regenerate::AfterReleasers]
  plugin = ReadmeAnyFromPod

  [@Starter::Git]
  revision = 3
  installer = ModuleBuildTiny
  managed_versions = 1
  regenerate = Build.PL
  regenerate = META.json
  regenerate = LICENSE
  ExecDir.dir = script
  Release_Commit.allow_dirty[] = README.md
  BumpVersionAfterRelease.munge_build_pl = 0

  [NameFromDirectory]
  [LicenseFromModule]
  override_author = 1
  [Prereqs::FromCPANfile]
  [StaticInstall]
  mode = auto
  [GithubMeta]
  issues = 1
  [Git::Contributors]

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

=head2 managed_versions

Requires revision 3 or higher.

  [@Starter]
  revision = 3
  managed_versions = 1

With C<managed_versions> set, C<[@Starter]> will use an additional set of
plugins to manage your module versions when releasing, while leaving them in
place in the source files.

L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> will read the
distribution version from the main module, and set all other module versions to
match in the build. L<[NextRelease]|Dist::Zilla::Plugin::NextRelease> replaces
C<{{$NEXT}}> in your F<Changes> file with a line containing the distribution
version and build date/time. Finally,
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease> will
bump the versions in your source module files after a release.

When using this option, you B<must> have the distribution version set in your
main module in a form like C<our $VERSION = '1.234';>, rather than in
F<dist.ini>. Other modules and scripts must also have similar version
declarations to be updated appropriately. You can set your distribution's
version manually by changing the version of your main module, or by setting the
C<V> environment variable when building or releasing. See the documentation for
each plugin mentioned above for details on configuring them, which can be done
in the usual config-slicing way as shown in L</"CONFIGURING">.

This option also enables the C<inherit_version> option for
L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package> since all
module versions are matched to the main module in this configuration.

=head2 regenerate

Requires revision 3 or higher.

  [@Starter]
  revision = 3
  regenerate = INSTALL
  regenerate = README

The specified generated files will be copied to the root directory upon
release using L<[CopyFilesFromRelease]|Dist::Zilla::Plugin::CopyFilesFromRelease>,
and excluded from the C<[GatherDir]> plugin in use. Note: if you remove the
built-in C<[GatherDir]> plugin to use one separately, you must exclude copied
files from that plugin yourself. Additionally,
L<[Regenerate::AfterReleasers]|Dist::Zilla::Plugin::Regenerate::AfterReleasers>
is applied to C<[CopyFilesFromRelease]> to allow these files to be generated
and copied on demand outside of a release using
L<< C<dzil regenerate>|Dist::Zilla::App::Command::regenerate >>.

=head1 REVISIONS

The C<[@Starter]> plugin bundle supports the following revisions.

=head2 Revision 1

Revision 1 is the default and is equivalent to using the following plugins:

=over 2

=item L<[GatherDir]|Dist::Zilla::Plugin::GatherDir>

=item L<[MetaYAML]|Dist::Zilla::Plugin::MetaYAML>

=item L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON>

=item L<[License]|Dist::Zilla::Plugin::License>

=item L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod>

=item L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>

=item L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>

=item L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>

  xt_mode = 1

=item L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker>

=item L<[Manifest]|Dist::Zilla::Plugin::Manifest>

=item L<[PruneCruft]|Dist::Zilla::Plugin::PruneCruft>

=item L<[ManifestSkip]|Dist::Zilla::Plugin::ManifestSkip>

=item L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests>

=item L<[TestRelease]|Dist::Zilla::Plugin::TestRelease>

=item L<[ConfirmRelease]|Dist::Zilla::Plugin::ConfirmRelease>

=item L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN>

=item L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>

=item L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex>

  directory = t
  directory = xt
  directory = inc
  directory = share
  directory = eg
  directory = examples

=item L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>

=item L<[ShareDir]|Dist::Zilla::Plugin::ShareDir>

=item L<[ExecDir]|Dist::Zilla::Plugin::ExecDir>

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
L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>,
L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>,
L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>,
L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>,
L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex>,
L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>.

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

=head2 Revision 3

Revision 3 is similar to Revision 2, but additionally supports the
L</"managed_versions"> and L</"regenerate"> options, and variant bundles like
L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git>.

=head1 CONFIGURING

By using the L<PluginRemover|Dist::Zilla::Role::PluginBundle::PluginRemover> or
L<Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer> role options,
the C<[@Starter]> bundle's included plugins can be customized as desired. Here
are some examples:

=head2 GatherDir

If the distribution is using git source control, it is often helpful to replace
the default L<[GatherDir]|Dist::Zilla::Plugin::GatherDir> plugin with
L<[Git::GatherDir]|Dist::Zilla::Plugin::Git::GatherDir>. (Note: The
L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> variant of this
bundle uses C<[Git::GatherDir]> by default.)

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
  phase = release ; avoid changing files in the root with dzil build or dzil test
  [Regenerate::AfterReleasers] ; allows regenerating with dzil regenerate
  plugin = Pod_Readme

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

=head2 ExecDir

Some distributions use the F<script/> directory instead of F<bin/> (the
L<[ExecDir]|Dist::Zilla::Plugin::ExecDir> default) for executable scripts.

  [@Starter]
  ExecDir.dir = script

=head2 Versions

When using the L</"managed_versions"> option, the additional plugins can be
directly configured in various ways to suit your versioning needs.

  [@Starter]
  revision = 3
  managed_versions = 1
  
  ; configuration examples
  RewriteVersion.global = 1
  BumpVersionAfterRelease.munge_makefile_pl = 0
  NextRelease.filename = ChangeLog
  NextRelease.format = %-5v %{yyyy-MM-dd}d

=head1 EXTENDING

This bundle includes a basic set of plugins for releasing a distribution, but
there are many more common non-intrusive tasks that L<Dist::Zilla> can help
with simply by using additional plugins in the F<dist.ini>. You can install all
plugins required by a F<dist.ini> by running
C<dzil authordeps --missing | cpanm> or with
L<< C<dzil installdeps>|Dist::Zilla::App::Command::installdeps >>.

=head2 Name

To automatically set the distribution name from the current directory, use
L<[NameFromDirectory]|Dist::Zilla::Plugin::NameFromDirectory>.

=head2 License and Copyright

To extract the license and copyright information from the main module, and
optionally set the author as well, use
L<[LicenseFromModule]|Dist::Zilla::Plugin::LicenseFromModule>.

=head2 Changelog

To automatically add the new release version to the distribution changelog,
use L<[NextRelease]|Dist::Zilla::Plugin::NextRelease> as the L</"managed_versions">
option does. To ensure the release has changelog entries, use
L<[CheckChangesHasContent]|Dist::Zilla::Plugin::CheckChangesHasContent>.

=head2 Git

To better integrate with a git workflow, use the plugins from
L<[@Git]|Dist::Zilla::PluginBundle::Git>, as the
L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> variant of this
bundle does. To automatically add contributors to metadata from git commits,
use L<[Git::Contributors]|Dist::Zilla::Plugin::Git::Contributors>.

=head2 Resources

To automatically set resource metadata from an associated GitHub repository,
use L<[GithubMeta]|Dist::Zilla::Plugin::GithubMeta>. To set resource metadata
manually, use L<[MetaResources]|Dist::Zilla::Plugin::MetaResources>.

=head2 Prereqs

To specify distribution prereqs in a L<cpanfile>, use
L<[Prereqs::FromCPANfile]|Dist::Zilla::Plugin::Prereqs::FromCPANfile>. To
specify prereqs in F<dist.ini>, use L<[Prereqs]|Dist::Zilla::Plugin::Prereqs>.
To automatically guess the distribution's prereqs by parsing the code, use
L<[AutoPrereqs]|Dist::Zilla::Plugin::AutoPrereqs>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::PluginBundle::Basic>,
L<Dist::Zilla::Starter>, L<Dist::Zilla::PluginBundle::Starter::Git>,
L<Dist::Zilla::MintingProfile::Starter>, L<Dist::Milla>
