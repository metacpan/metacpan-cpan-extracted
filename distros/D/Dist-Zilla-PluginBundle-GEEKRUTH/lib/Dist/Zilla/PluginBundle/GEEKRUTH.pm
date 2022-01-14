package Dist::Zilla::PluginBundle::GEEKRUTH 1.0001;
use Modern::Perl;

# ABSTRACT: Be like GeekRuthie when you build your dists

use Moose;
use Dist::Zilla;

with qw/
   Dist::Zilla::Role::PluginBundle::Easy
   Dist::Zilla::Role::PluginBundle::Config::Slicer
   /;

use Type::Tiny;
use Types::Standard qw/ Str ArrayRef /;

sub version_range {
   my ( $from, $to ) = @_;
   return join ',', grep { not $_ % 2 } $from .. $to;
}

has badge => (
   isa     => 'ArrayRef',
   is      => 'ro',
   default => sub { [] },
);

sub configure {
   my ($self) = @_;
   my $arg = $self->payload;

   my $release_branch = $arg->{release_branch} || 'releases';
   my $dev_branch     = $arg->{dev_branch}     || 'main';
   my $upstream       = $arg->{upstream}       || 'origin';

   my %mb_args;
   $mb_args{mb_class} = $arg->{mb_class} if $arg->{mb_class};

   my $builder = $arg->{builder} || 'MakeMaker';

   $self->add_plugins(
      [ $builder, ( \%mb_args ) x ( $builder eq 'ModuleBuild' ) ] );
   $self->add_plugins(
      qw/
         Git::Contributors
         ContributorsFile
         Test::Compile
         CoalescePod
         InstallGuide
         Covenant
         ContributorCovenant
         GitLab::Update
         /,
      [
         'GitLab::Meta' => {
            remote   => $upstream,
            p3rl     => 1,
            metacpan => 0,
         }
      ],
      qw/
         MetaYAML
         MetaJSON
         PodWeaver
         License
         /,
      [
         NextRelease => {
            time_zone => 'America/New_York',
         }
      ],
      qw/
         MetaProvides::Package
         Manifest
         ManifestSkip
         Git::GatherDir
         CopyFilesFromBuild
         ExecDir
         /,
      [ PkgVersion => { use_package => 1 } ],
      [
         Authority => {
            authority  => $arg->{authority} // 'cpan:GEEKRUTH',
            do_munging => 0,
         }
      ],
      qw/ Test::ReportPrereqs /,
      [
         AutoPrereqs => {
            ( skip => $arg->{autoprereqs_skip} ) x !!$arg->{autoprereqs_skip}
         }
      ],
      qw/ CheckChangesHasContent
         ReadmeMarkdownFromPod
         TestRelease
         ConfirmRelease
         Git::Check
         CopyrightYearFromGit
         /,

      [
         'Git::CommitBuild' => {
            release_branch       => $release_branch,
            multiple_inheritance => 1,
         }
      ],
      [
         'Git::Tag' => {
            tag_format => 'v%v',
            branch     => $release_branch
         }
      ],
   );

   $self->add_plugins(
      'PreviousVersion::Changelog',
      [
         'NextVersion::Semantic' => {
            major    => 'MAJOR, API CHANGES',
            minor    => 'MINOR, NEW FEATURES, ENHANCEMENTS',
            revision => 'REVISION, BUG FIXES, DOCUMENTATION, STATISTICS',
         }
      ],
      [
         'ChangeStats::Git' => {
            group          => 'STATISTICS',
            develop_branch => $dev_branch,
            release_branch => $release_branch,
         }
      ],
      'Git::Commit',
   );

   if ( $ENV{FAKE} or $arg->{fake_release} ) {
      $self->add_plugins('FakeRelease');
   }
   else {
      $self->add_plugins(
         [
            'Git::Push' => {
               push_to => join q{ }, $upstream, $dev_branch, $release_branch
            }
         ],
         qw/UploadToCPAN/,
         [ 'InstallRelease' => { install_command => 'cpanm .' } ],
      );
   }

   $self->add_plugins(
      qw/
         SchwartzRatio
         Test::UnusedVars
         RunExtraTests
         /,
   );

   if ( my $help_wanted = $arg->{help_wanted} ) {
      $self->add_plugins(
         [
            'HelpWanted' => { map { $_ => 1 } split q{ }, $help_wanted },
         ]
      );
   }

   $self->add_plugins( [ 'CPANFile', 'MinimumPerlFast' ], );

   $self->config_slice('mb_class');

   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::GEEKRUTH - Be like GeekRuthie when you build your dists

=head1 VERSION

version 1.0001

=head1 DESCRIPTION

This is the plugin bundle that Ruthie uses to release
her distributions. It's roughly equivalent to

   [Git::Contributors]
   [ContributorsFile]
   [Test::Compile]
   [CoalescePod]
   [MakeMaker]
   [InstallGuide]
   [Covenant]
   [ContributorCovenant]
   [GitLab::Update]
   [GitLab::Meta]
      p3rl = 1
      metacpan = 0

   [MetaYAML]
   [MetaJSON]
   [PodWeaver]
   [License]
   [NextRelease]
   time_zone = America/New_York
   
   [MetaProvides::Package]
   [Manifest]
   [ManifestSkip]
   [Git::GatherDir]
   [CopyFilesFromBuild]
   [ExecDir]
   [PkgVersion]
   use_package = 1
   
   [Authority]
   do_munging = 0
   
   [Test::ReportPrereqs]
   [TidyAll]
   [AutoPrereqs]
   [CheckChangesHasContent]
   [ReadmeMarkdownFromPod]
   [TestRelease]
   [ConfirmRelease]
   [Git::Check]
   [CopyrightYearFromGit]
   
   [PreviousVersion::Changelog]
   [NextVersion::Semantic]
   major = MAJOR, API CHANGE
   minor = MINOR, ENHANCEMENTS
   revision = REVISION, BUG FIXES
   format = %d.%02d%02d
   
   [ChangeStats::Git]
   group=STATISTICS
   develop_branch=main
   
   [Git::CommitBuild]
   release_branch = releases
   multiple_inheritance = 1
   
   [Git::Tag]
   tag_format = v%v
   branch     = releases
   
   [Git::Commit]
   [UploadToCPAN]
   [Git::Push]
   push_to = origin main releases
   
   [InstallRelease]
   install_command = cpanm .
   
   [SchwartzRatio]
   [RunExtraTests]
   [Test::UnusedVars]
   [CPANFile]
   [MinimumPerlFast]

=head1 ARGUMENTS

=over

=item C<autoprereqs_skip>

Passed as C<skip> to AutoPrereqs.

=item C<authority>

Passed to L<Dist::Zilla::Plugin::Authority>.

Defaults to C<cpan:GEEKRUTH>.

=item C<fake_release>

If given a true value, uses L<Dist::Zilla::Plugin::FakeRelease>
instead of
L<Dist::Zilla::Plugin::Git::Push>,
L<Dist::Zilla::Plugin::UploadToCPAN>, and
L<Dist::Zilla::Plugin::InstallRelease>

Can also be triggered via the I<FAKE> environment variable.

=item C<builder>

C<ModuleBuild> or C<MakeMaker>. Defaults to C<MakeMaker>.

=item C<mb_class>

Passed to C<ModuleBuild> plugin.

=item C<dev_branch>

Master development branch.

Defaults to C<main>.

=item C<release_branch>

Branch on which the CPAN images are commited.

Defaults to C<releases>.

=item C<upstream>

The name of the upstream repo. 

Defaults to C<origin>.

=back

=head1 ACKNOWLEDGEMENT

There is much shameless plagarism here from the work of Yanick Champoux. He never seems to complain.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
