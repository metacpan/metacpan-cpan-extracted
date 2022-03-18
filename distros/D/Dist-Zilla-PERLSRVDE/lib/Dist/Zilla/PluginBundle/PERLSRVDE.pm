package Dist::Zilla::PluginBundle::PERLSRVDE;

use v5.24;

# ABSTRACT: The plugin bundle we use at Perl-Services.de

use strict;
use warnings;

our $VERSION = '1.0.0'; # VERSION

use namespace::autoclean;

use Dist::Zilla 6.0;

use Dist::Zilla::PluginBundle::Git;
use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Filter ();

use Dist::Zilla::Plugin::ContributorsFile;
use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::SyncCPANfile;
use Dist::Zilla::Plugin::OurPkgVersion;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::Git::Contributors;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::Test::NoTabs;
use Dist::Zilla::Plugin::Test::NoBOM;
use Dist::Zilla::Plugin::Test::Perl::Critic;
use Dist::Zilla::Plugin::ExecDir;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::ReadmeAddDevInfo;
use Dist::Zilla::Plugin::GitHubREADME::Badge;
use Dist::Zilla::Plugin::MetaResources;

use Moose;

with qw(
    Dist::Zilla::Role::PluginBundle::Easy
    Dist::Zilla::Role::PluginBundle::Config::Slicer
    Dist::Zilla::Role::PluginBundle::PluginRemover
);

has 'is_cpan' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{is_cpan} ? $pl->{is_cpan} : 0;
    },
);

has 'repository_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{repository_type} ? $pl->{repository_type} : 'github';
    },
);

has 'repository_path' => (
    is  => 'ro',
    isa => 'Str',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{repository_path} ? $pl->{repository_path} : '';
    },
);

has 'internal_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{internal_type} ? $pl->{internal_type} : 'git';
    },
);

has 'internal_url' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{internal_url} ? $pl->{internal_url} : '';
    },
);

has 'internal_web' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{internal_web} ? $pl->{internal_web} : '';
    },
);

has 'bugtracker' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        exists $pl->{bugtracker} ? $pl->{bugtracker} : '';
    },
);

has 'fake_release' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $pl = $_[0]->payload;
        if ( $pl->{is_cpan} ) {
            $pl->{fake_release} = 0;
        }
        exists $pl->{fake_release} ? $pl->{fake_release} : 1;
    },
);

sub configure {
    my ($self) = @_;

    my @remove_from_basic;
    if ( $self->fake_release ) {
        push @remove_from_basic, 'UploadToCPAN';
    }

    $self->add_plugins(
        [
            'ContributorsFile' => {
                filename => 'CONTRIBUTORS',
            },
        ],
        'CheckChangesHasContent',
        [
            'NextRelease' => {
                format => '%-9v%T %{yyyy-MM-dd HH:mm:ss VVVV}d',
            },
        ],
        qw/
            SyncCPANfile
            OurPkgVersion
            PodWeaver
        /,
        [
            'Git::Contributors' => {
                include_authors => 1,
            },
        ],
        qw/
            PodSyntaxTests
            PodCoverageTests

            Test::NoTabs
            Test::NoBOM
            Test::Perl::Critic

            MetaJSON
            MetaProvides::Package

            ExecDir
        /,
    );

    $self->add_bundle(
        '@Filter' => {
            '-bundle' => '@Basic',
            '-remove' => [ 'Readme', @remove_from_basic ],
        },
    );

    $self->_meta_resources;
    $self->add_bundle('@Git');

    if ( $self->is_cpan ) {
        $self->add_plugins(
            [
                'ReadmeAnyFromPod' => 'GfmInRoot' => {
                    phase    => 'build',
                },
            ],
            [
                'ReadmeAnyFromPod' => 'TextInBuild' => {
                    phase    => 'build',
                },
            ],
            [
                'ReadmeAddDevInfo' => {
                    phase                 => 'build',
                    before                => '# AUTHOR',
                    add_contribution_file => 1,
                },
            ],
            [
                'GitHubREADME::Badge' => {
                    badges => [ qw/cpants issues cpancover license/ ],
                    phase  => 'build',
                    place  => 'top',
                },
            ],
        );
    }
}

sub _meta_resources {
    my ($self) = @_;

    my %meta_resources;

    $meta_resources{'bugtracker.web'} = $self->bugtracker if $self->bugtracker;

    my $type = $self->repository_type;

    return if !$type && !%meta_resources;

    my $name = $self->repository_path;

    if ( $type eq 'github' ) {
        $meta_resources{'homepage'} =
        $meta_resources{'repository.web'} =
            sprintf "https://github.com/%s",
                $name
        ;
        $meta_resources{'repository.url'} =
            sprintf "git://github.com/%s.git",
                $name
        ;
        $meta_resources{'repository.type'} = 'git';

        if ( !$self->bugtracker ) {
            $meta_resources{'bugtracker.web'} =
                sprintf "https://github.com/%s/issues",
                    $name
            ;
        }
    }
    elsif ( $type eq 'gitlab' ) {
        $meta_resources{'homepage'} =
        $meta_resources{'repository.web'} =
            sprintf "https://gitlab.com/%s",
                $name
        ;
        $meta_resources{'repository.url'} =
            sprintf "git://gitlab.com/%s.git",
                $name
        ;
        $meta_resources{'repository.type'} = 'git';

        if ( !$self->bugtracker ) {
            $meta_resources{'bugtracker.web'} =
                sprintf "https://gitlab.com/%s/-/issues",
                    $name
            ;
        }
    }
    elsif ( $type eq 'internal' ) {
        $meta_resources{'homepage'} =
        $meta_resources{'repository.web'} =
             $self->internal_web if $self->internal_web;
        $meta_resources{'repository.url'} =
             $self->internal_url if $self->internal_url;
        $meta_resources{'repository.type'} =
             $self->internal_type || 'git';
   }

    return if !%meta_resources;

    $self->add_plugins(
        [ 'MetaResources' => \%meta_resources ],
    );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::PERLSRVDE - The plugin bundle we use at Perl-Services.de

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    ; in dist.ini
    [@PERLSRVDE]

Using L</Options>:

    ; in dist.ini
    [@PERLSRVDE]
    ; we are using an internal git repository
    repository_type = internal
    internal_type   = git
    internal_url    = git://git.internal.example/test.git
    internal_web    = https://git.internal.example/test
    ; but the bugtracker is an other tool
    bugtracker = https://our.bugtracker.example
    ; and it's a CPAN module, so we want to include more
    ; dist::zilla plugins
    is_cpan = 1
    ; but we do not want to upload it ;-)
    fake_release = 1

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle. It lists the plugins we use at L<https://perl-services.de|Perl-Services.de>.
It is roughly equivalent to the following dist.ini:

    [ContributorsFile]
    filename = CONTRIBUTORS
    
    [CheckChangesHasContent]
    
    [NextRelease]
    format=%-9v%T %{yyyy-MM-dd HH:mm:ss VVVV}d
    
    [SyncCPANfile]
    [PkgVersion]
    [PodWeaver]
    
    [@Filter]
    -bundle = @Basic
    -remove = Readme
    -remove = UploadToCPAN
    
    [Git::Contributors]
    include_authors = 1
    
    [PodSyntaxTests]
    [PodCoverageTests]
    [Test::NoTabs]
    [Test::NoBOM]
    [Test::Perl::Critic]
    
    [MetaProvides::Package]
    [MetaJSON]
    
    [ExecDir]
    
    [@Git]
    
    [PerlTidy]
    perltidyrc = .perltidyrc

=for Pod::Coverage configure

=head1 OPTIONS

These options can be used:

=over 4

=item * is_cpan

=item * repository_type

=item * repository_path

=item * internal_type

=item * internal_url

=item * bugtracker

=item * fake_release

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
