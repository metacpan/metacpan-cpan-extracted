package Dist::Zilla::PluginBundle::YANICK;
our $AUTHORITY = 'cpan:YANICK';
$Dist::Zilla::PluginBundle::YANICK::VERSION = '0.32.1';
# ABSTRACT: Be like Yanick when you build your dists

# [TODO] add CONTRIBUTING file


use strict;

use Moose;

use Dist::Zilla;

use experimental 'postderef';

with qw/
    Dist::Zilla::Role::PluginBundle::Easy
    Dist::Zilla::Role::PluginBundle::Config::Slicer
/;

has "doap_changelog" => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        $self->payload->{doap_changelog} //= 1;
    },
);






use Type::Tiny;
use Types::Standard qw/ Str ArrayRef /;


sub version_range {
    my( $from, $to ) = @_;
    return join ',', grep { not $_ % 2 } $from..$to;
}

has badge => (
    isa => 'ArrayRef',
    is => 'ro',
    default => sub { [] },
);

sub configure {
    my ( $self ) = @_;
    my $arg = $self->payload;

    my $release_branch = $arg->{release_branch} || 'releases';
    my $dev_branch     = $arg->{dev_branch}     || 'main';
    my $upstream       = $arg->{upstream}       || 'github';

    my @import_from_build = $arg->{import_from_build} ? split( ',', $arg->{import_from_build} ) :
        qw/ cpanfile AUTHOR_PLEDGE CODE_OF_CONDUCT.md CONTRIBUTING.md /;

    my %mb_args;
    $mb_args{mb_class} = $arg->{mb_class} if $arg->{mb_class};

    my $builder = $arg->{builder} || 'MakeMaker';

    $self->add_plugins([ $builder, ( \%mb_args ) x ($builder eq 'ModuleBuild' ) ]);

    $self->add_plugins(
        qw/
            =Dist::Zilla::PluginBundle::YANICK::Contributing
            Git::Contributors
            ContributorsFile
            Test::Compile
            CoalescePod
            InstallGuide
            Covenant
            ContributorCovenant
        /,
        [ GithubMeta => {
            remote => $upstream,
            issues => 1,
        } ],
        qw/ MetaYAML MetaJSON PodWeaver License
          /,
        [ ReadmeAnyFromPod => { type => 'gfm', filename => 'README.mkdn' } ],
        [ CoderwallEndorse => { users => 'yanick:Yanick' } ],
        [ NextRelease => {
                time_zone => 'America/Montreal',
                format    => '%-9v %{yyyy-MM-dd}d',
            } ],
        'MetaProvides::Package',
        'MatchManifest',
        qw/  ManifestSkip /,
        [ 'Git::GatherDir' => {
            include_dotfiles => $arg->{include_dotfiles},
            exclude_filename => [ @import_from_build ],
        } ],
        [ CopyFilesFromBuild => { copy => [ @import_from_build ] } ],
        qw/ ExecDir
          PkgVersion /,
          [ Authority => {
            authority => $arg->{authority} // 'cpan:YANICK'
          } ],
          qw/ Test::ReportPrereqs
          Signature /,
          [ AutoPrereqs => {
                  ( skip => $arg->{autoprereqs_skip} )
                            x !!$arg->{autoprereqs_skip}
            }
          ],
          qw/ CheckChangesHasContent
          TestRelease
          ConfirmRelease
          Git::Check
          CopyrightYearFromGit
          /,
        [ 'Git::CommitBuild' => {
                release_branch => $release_branch ,
                multiple_inheritance => 1,
        } ],
        [ 'Git::Tag'  => { tag_format => 'v%v', branch => $release_branch } ],
    );


    # Git::Commit can't be before Git::CommitBuild :-/
    $self->add_plugins(
        'PreviousVersion::Changelog',
        [ 'NextVersion::Semantic' => {
            major => 'API CHANGES',
            minor => 'NEW FEATURES, ENHANCEMENTS',
            revision => 'BUG FIXES, DOCUMENTATION, STATISTICS',
        } ],
        [ 'ChangeStats::Git' => {
                group => 'STATISTICS',
                develop_branch => $dev_branch,
                release_branch => $release_branch,
            } ],
        'Git::Commit',
    );

    if ( $ENV{FAKE} or $arg->{fake_release} ) {
        $self->add_plugins( 'FakeRelease' );
    }
    else {
        $self->add_plugins(
            [ 'Git::Push' => { push_to    => join ' ', $upstream, $dev_branch, $release_branch} ],
            qw/ UploadToCPAN /,
        );

        $self->add_plugins(
            [ 'InstallRelease' => { install_command => 'cpanm .' } ],
        );
    }

    $self->add_plugins(
    qw/
        SchwartzRatio
        Test::UnusedVars
        RunExtraTests
    /
    );

    if ( my $help_wanted = $arg->{help_wanted} ) {
        $self->add_plugins([
            'HelpWanted' => {
                map { $_ => 1 } split ' ', $help_wanted
            },
        ]);
    }

    $self->add_plugins(
        [ DOAP => {
            process_changes => $self->doap_changelog,
#            ttl_filename => 'project.ttl',
        } ],
        'CPANFile',
        [ SecurityPolicy => {
            -policy => 'Individual',
            timeframe => '1 month',
            perl_support_years => 5,
        } ],
    );

    $self->config_slice( 'mb_class' );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::YANICK - Be like Yanick when you build your dists

=head1 VERSION

version 0.32.1

=head1 DESCRIPTION

This is the plugin bundle that Yanick uses to release
his distributions. It's roughly equivalent to

    [Git::Contributors]
    [ContributorsFile]

    [Test::Compile]

    [CoalescePod]

    [MakeMaker]

    [InstallGuide]
    [Covenant]
    [PluginBundle::YANICK::Contributing]
    [ContributorCovenant]

    [GithubMeta]
    remote=github

    [MetaYAML]
    [MetaJSON]

    [PodWeaver]

    [License]
    [HelpWanted]

    [ReadmeMarkdownFromPod]

    [CoderwallEndorse]
    users = yanick:Yanick

    [NextRelease]
    time_zone = America/Montreal

    [MetaProvides::Package]

    [MatchManifest]
    [ManifestSkip]

    [Git::GatherDir]
    exclude_filename = cpanfile
    exclude_filename = AUTHOR_PLEDGE
    exclude_filename = CODE_OF_CONDUCT.md

    [CopyFilesFromBuild]
    copy = cpanfile


    [ExecDir]

    [PkgVersion]
    [Authority]

    [Test::ReportPrereqs]
    [Signature]

    [AutoPrereqs]

    [CheckChangesHasContent]

    [TestRelease]

    [ConfirmRelease]

    [Git::Check]

    [PreviousVersion::Changelog]
    [NextVersion::Semantic]

    [ChangeStats::Git]
    group=STATISTICS

    [Git::Commit]
    [Git::CommitBuild]
        release_branch = releases
        multiple_inheritance = 1
    [Git::Tag]
        tag_format = v%v
        branch     = releases

    [UploadToCPAN]

    [Git::Push]
        push_to = github main releases

    [InstallRelease]
    install_command = cpanm .

    [SchwartzRatio]


    [RunExtraTests]
    [Test::UnusedVars]

    [DOAP]
    process_changes = 1

    [CPANFile]

    [CopyrightYearFromGit]

    [GitHubREADME::Badge]

    [SecurityPolicy]
    -policy = Individual
    timeframe = 1 month
    perl_support_years = 5

=head2 ARGUMENTS

=head3 autoprereqs_skip

Passed as C<skip> to AutoPrereqs.

=head3 authority

Passed to L<Dist::Zilla::Plugin::Authority>.

=head3 fake_release

If given a true value, uses L<Dist::Zilla::Plugin::FakeRelease>
instead of
L<Dist::Zilla::Plugin::Git::Push>,
L<Dist::Zilla::Plugin::UploadToCPAN>,
and L<Dist::Zilla::Plugin::InstallRelease>.

Can also be triggered via the I<FAKE> environment variable.

=head3 builder

C<ModuleBuild> or C<MakeMaker>. Defaults to C<MakeMaker>.

=head3 mb_class

Passed to C<ModuleBuild> plugin.

=head3 include_dotfiles

For C<Git::GatherDir>. Defaults to false.

=head3 doap_changelog

If the DOAP plugin should generate the project history
off the changelog. Defaults to I<true>.

=head3 dev_branch

Main development branch.

Defaults to C<main>.

=head3 release_branch

Branch on which the CPAN images are commited.

Defaults to C<releases>.

=head3 upstream

The name of the upstream repo.

Defaults to C<github>.

=head3 import_from_build

    import_from_build = cpanfile,AUTHOR_PLEDGE,CODE_OF_CONDUCT.md,CONTRIBUTING.md

Comma-separated list of files to import in the checked out
repo from the build.

Defaults to C<cpanfile,AUTHOR_PLEDGE,CODE_OF_CONDUCT.md,CONTRIBUTING.md>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
