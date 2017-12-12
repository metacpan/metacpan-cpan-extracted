package Dist::Zilla::PluginBundle::YANICK;
our $AUTHORITY = 'cpan:YANICK';
$Dist::Zilla::PluginBundle::YANICK::VERSION = '0.28.0';
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

sub not_for_travis {
    return $ENV{TRAVIS} ? () : @_;
}






use Type::Tiny;
use Types::Standard qw/ Str ArrayRef /;

sub version_range {
    my( $from, $to ) = @_;
    return join ',', grep { not $_ % 2 } $from..$to;
}

my $TravisPerlVersions = Type::Tiny->new(
    name => 'TravisPerlVersions',
    parent => ArrayRef,
)->plus_coercions(
    Str ,=> sub {
        my $vre = qr/([\d.]+)/;
        s/$vre\.\.$vre/version_range($1,$2)/eg;
        return [ map { '5.' . $_ } split /\s*,\s*/, $_ ];
    },
);

has travis_perl_versions => (
    is => 'ro',
    isa => $TravisPerlVersions,
    coerce => 1,
    default => '14..26' 
);


sub configure {
    my ( $self ) = @_;
    my $arg = $self->payload;

    my $release_branch = $arg->{release_branch} || 'releases';
    my $dev_branch     = $arg->{dev_branch}     || 'master';
    my $upstream       = $arg->{upstream}       || 'github';

    my %mb_args;
    $mb_args{mb_class} = $arg->{mb_class} if $arg->{mb_class};

    my $builder = $arg->{builder} || 'MakeMaker';

    $self->add_plugins([ $builder, ( \%mb_args ) x ($builder eq 'ModuleBuild' ) ]);

    $self->add_plugins(
        qw/ 
            Git::Contributors
            ContributorsFile
            Test::Compile
            CoalescePod
            InstallGuide
            Covenant
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
        not_for_travis( 'MatchManifest' ),
        qw/  ManifestSkip /,
        [ 'Git::GatherDir' => {
            include_dotfiles => $arg->{include_dotfiles},
            exclude_filename => 'cpanfile',
        } ],
        [ CopyFilesFromBuild => { copy => 'cpanfile' } ],
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
        [ TravisCI => [
            verbose => 0,
            install => 'cpanm --installdeps -n .',
            script => 'prove -l t',
            
            map { ( perl_version => $_ ) } $self->travis_perl_versions->@*
        ]  ]
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
            [ Twitter => {
                tweet_url =>
                    'https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}/',
                tweet => 
                    'Released {{$DIST}}-{{$VERSION}}{{$TRIAL}} {{$URL}} !META{resources}{repository}{web}',
                url_shortener => 'none',
            } ],
        ) if not defined $arg->{tweet} or $arg->{tweet};

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
        [ 'CPANFile' ],
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

version 0.28.0

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
        push_to = github master releases

    [InstallRelease]
    install_command = cpanm .

    [Twitter]
    [SchwartzRatio]


    [RunExtraTests]
    [Test::UnusedVars]

    [DOAP]
    process_changes = 1

    [TravisCI]
    verbose = 0

    [CPANFile]

    [CopyrightYearFromGit]

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
L<Dist::Zilla::Plugin::InstallRelease> and
L<Dist::Zilla::Plugin::Twitter>.

Can also be triggered via the I<FAKE> environment variable.

=head3 builder 

C<ModuleBuild> or C<MakeMaker>. Defaults to C<MakeMaker>.

=head3 mb_class

Passed to C<ModuleBuild> plugin.

=head3 include_dotfiles

For C<Git::GatherDir>. Defaults to false.

=head3 tweet

If a tweet should be sent. Defaults to C<true>.

=head3 doap_changelog

If the DOAP plugin should generate the project history
off the changelog. Defaults to I<true>.

=head3 dev_branch

Master development branch.

Defaults to C<master>.

=head3 release_branch

Branch on which the CPAN images are commited.

Defaults to C<releases>.

=head3 upstream

The name of the upstream repo.

Defaults to C<github>.

=head3 travis_perl_versions

    travis_perl_versions = 14,16,18,20,22,24,26

Comma-separated list of perl versions (without the leading '5') that
travis should test. Ranges can be given (C<14..16>), for which the
odd numbers will be skipped. So C<14..26> will result in C<14,16,18,...>.

Defaults to C<14..26>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012, 2011, 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
