package Dist::Zilla::Plugin::GitHubREADME::Badge;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.34';

use Moose;
use Moose::Util::TypeConstraints qw(enum);
use namespace::autoclean;
use Dist::Zilla::File::OnDisk;
use Path::Tiny;

# same as Dist::Zilla::Plugin::ReadmeAnyFromPod
with qw(
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
  Dist::Zilla::Role::FileMunger
);

has badges => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { ['travis', 'coveralls', 'cpants'] },
);
sub mvp_multivalue_args { ('badges') }

has 'place' => ( is => 'rw', isa => 'Str', default => sub { 'top' } );
has 'branch' => (is => 'rw', isa => 'Str', default => sub { 'master' });

has phase => (
    is      => 'ro',
    isa     => enum([qw(build release filemunge)]),
    default => 'build',
);

has readme_file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @candidates = qw/ README.md README.mkdn README.markdown /;


        # only for the filemunge phase do we look
        # in the slurped files
        if( $self->phase eq 'filemunge' ) {
            for my $file ( @{ $self->zilla->files } ) {
                return $file if grep { $file->name eq $_ } @candidates;
            }
        }
        else {
            # for the other phases we look on disk
            my $root = path($self->zilla->root);

            return Dist::Zilla::File::OnDisk->new(
                name    => "$_",
                content => $_->slurp_raw,
                encoding => 'bytes',
            ) for grep { -f $_ } map { $root->child($_) } @candidates
        }

        $self->log_fatal('README file not found');
    },
);

sub after_build {
    my ($self) = @_;
    $self->add_badges if $self->phase eq 'build';
}

sub after_release {
    my ($self) = @_;
    $self->add_badges if $self->phase eq 'release';
}

sub munge_files {
    my $self = shift;

    $self->add_badges if $self->phase eq 'filemunge';
}


sub add_badges {
    my ($self) = @_;

    my $distname = $self->zilla->name;
    my $distmeta = $self->zilla->distmeta;
    my $dist_version = $self->zilla->version;
    my $repository = $distmeta->{resources}->{repository}->{url};
    return unless $repository;
    my ($base_url, $user_name, $repository_name) = ($repository =~ m{^\w+://(.*)/([^\/]+)/(.*?)(\.git|\/|$)});
    return unless $repository_name;

    my $branch = $self->branch || 'master'; # backwards

    my @badges;
    foreach my $badge (@{$self->badges}) {
        if ($badge eq 'travis' or $badge eq 'travis-ci.org') {
            push @badges, "[![Build Status](https://travis-ci.org/$user_name/$repository_name.svg?branch=$branch)](https://travis-ci.org/$user_name/$repository_name)";
        } elsif ($badge eq 'travis-ci.com') {
            push @badges, "[![Build Status](https://travis-ci.com/$user_name/$repository_name.svg?branch=$branch)](https://travis-ci.com/$user_name/$repository_name)";
        } elsif ($badge eq 'appveyor') {
            push @badges, "[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/$user_name/$repository_name?branch=$branch&svg=true)](https://ci.appveyor.com/project/$user_name/$repository_name)";
        } elsif ($badge eq 'coveralls') {
            push @badges, "[![Coverage Status](https://coveralls.io/repos/$user_name/$repository_name/badge.svg?branch=$branch)](https://coveralls.io/r/$user_name/$repository_name?branch=$branch)"
        } elsif ($badge eq 'gitter') {
            push @badges, "[![Gitter chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/$user_name/$repository_name)";
        } elsif ($badge eq 'cpants') {
            push @badges, "[![Kwalitee status](https://cpants.cpanauthors.org/dist/$distname.png)](https://cpants.cpanauthors.org/dist/$distname)";
        } elsif ($badge eq 'issues') {
            push @badges, "[![GitHub issues](https://img.shields.io/github/issues/$user_name/$repository_name.svg)](https://github.com/$user_name/$repository_name/issues)";
        } elsif ($badge eq 'github_tag') {
            push @badges, "[![GitHub tag](https://img.shields.io/github/tag/$user_name/$repository_name.svg)]()";
        } elsif ($badge eq 'license') {
            push @badges, "[![Cpan license](https://img.shields.io/cpan/l/$distname.svg)](https://metacpan.org/release/$distname)";
        } elsif ($badge eq 'version') {
            push @badges, "[![Cpan version](https://img.shields.io/cpan/v/$distname.svg)](https://metacpan.org/release/$distname)";
        } elsif ($badge eq 'codecov') {
            push @badges, "[![codecov](https://codecov.io/gh/$user_name/$repository_name/branch/$branch/graph/badge.svg)](https://codecov.io/gh/$user_name/$repository_name)";
        } elsif ($badge eq 'gitlab_ci') {
            push @badges, "[![build status](https://$base_url/$user_name/$repository_name/badges/$branch/build.svg)]($repository/$user_name/$repository_name/commits/$branch)";
        } elsif ($badge eq 'gitlab_cover') {
            push @badges, "[![coverage report](https://$base_url/$user_name/$repository_name/badges/$branch/coverage.svg)]($repository/$user_name/$repository_name/commits/$branch)";
        } elsif ($badge eq 'docker_automated') {
            push @badges, "[![Docker Automated Build](https://img.shields.io/docker/automated/\L$user_name/$repository_name\E.svg)](https://github.com/$user_name/$repository_name)";
        } elsif ($badge eq 'docker_build') {
            push @badges, "[![Docker Build Status](https://img.shields.io/docker/build/\L$user_name/$repository_name\E.svg)](https://hub.docker.com/r/\L$user_name/$repository_name\E/)";
        } elsif ($badge =~ m{^github_actions/(.+)}) {
            push @badges, "[![Actions Status](https://github.com/$user_name/$repository_name/workflows/$1/badge.svg)](https://github.com/$user_name/$repository_name/actions)";
        } elsif ($badge eq 'cpancover') {
            push @badges, "[![CPAN Cover Status](https://cpancoverbadge.perl-services.de/$distname-$dist_version)](https://cpancoverbadge.perl-services.de/$distname-$dist_version)";
        }
    }

    my $readme = $self->readme_file;

    my $content = $readme->encoded_content;

    if ($self->place eq 'bottom') {
        $content = $content . "\n\n" . join("\n", @badges);
    } else {
        $content = join("\n", @badges) . "\n\n" . $content;
    }

    $readme->content($content);

    # need to write it to disk if we're in a
    # phase that is not filemunge
    path( $readme->name )->spew_raw( $readme->encoded_content )
        if $self->phase ne 'filemunge';
}

1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::GitHubREADME::Badge - Dist::Zilla - add badges to github README.md

=head1 SYNOPSIS

    # in dist.ini
    [GitHubREADME::Badge]

    # configure it yourself
    [GitHubREADME::Badge]
    badges = travis
    badges = travis-ci.com
    badges = appveyor
    badges = coveralls
    badges = gitter
    badges = cpants
    badges = issues
    badges = github_tag
    badges = license
    badges = version
    badges = codecov
    badges = gitlab_ci
    badges = gitlab_cover
    badges = docker_automated
    badges = docker_build
    badges = github_actions/test
    badges = cpancover
    place = bottom
    phase = release
    branch = main

=head1 DESCRIPTION

Dist::Zilla::Plugin::GitHubREADME::Badge adds badges to GitHub README.md

=head1 CONFIG

=head2 badges

Currently only travis, coveralls, codecov, gitter, cpants and GH issues are
supported. However patches are welcome.

The default goes to travis, coveralls and cpants.

    [GitHubREADME::Badge]
    badges = travis
    badges = coveralls
    badges = gitter
    badges = cpants

=head2 branch

    [GitHubREADME::Badge]
    branch = main

defaults to 'master'. you need set to 'main' for new github repos

=head2 place

    [GitHubREADME::Badge]
    place = bottom

Place the badges at the top or bottom of the README. Defaults to top.

=head2 phase

    [GitHubREADME::Badge]
    phase = release

Which Dist::Zilla phase to add the badges: C<build>, C<release> or C<filemunge>.
For the C<build> and C<release> phases, the README that is on disk will
be modified, whereas for the C<filemunge> it's the internal zilla version of
the README that will be modified.

The default is C<build>.

=head1 SEE ALSO

L<Minilla>, L<Dist::Zilla::Plugin::TravisCI::StatusBadge>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
