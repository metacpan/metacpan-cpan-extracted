package Dist::Zilla::Plugin::GitHubREADME::Badge;

use strict;
use 5.008_005;
our $VERSION = '0.22';

use Moose;
use Moose::Util::TypeConstraints qw(enum);
use namespace::autoclean;
use Dist::Zilla::File::OnDisk;
use Path::Tiny;

# same as Dist::Zilla::Plugin::ReadmeAnyFromPod
with qw(
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
);

has badges => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { ['travis', 'coveralls', 'cpants'] },
);
sub mvp_multivalue_args { ('badges') }

has 'place' => ( is => 'rw', isa => 'Str', default => sub { 'top' } );

has phase => (
    is      => 'ro',
    isa     => enum([qw(build release)]),
    default => 'build',
);

sub after_build {
    my ($self) = @_;
    $self->add_badges if $self->phase eq 'build';
}

sub after_release {
    my ($self) = @_;
    $self->add_badges if $self->phase eq 'release';
}

sub add_badges {
    my ($self) = @_;

    my $distname = $self->zilla->name;
    my $distmeta = $self->zilla->distmeta;
    my $repository = $distmeta->{resources}->{repository}->{url};
    return unless $repository;
    my ($base_url, $user_name, $repository_name) = ($repository =~ m{^\w+://(.*)/([^\/]+)/(.*?)(\.git|\/|$)});
    return unless $repository_name;

    my $file;
    foreach my $filename ('README.md', 'README.mkdn', 'README.markdown') {
        $file = path($self->zilla->root)->child($filename);
        last if -e "$file";
    }
    $self->log_fatal('README file not found') if ! -e "$file";

    my $readme = $file;

    # We are lazy and dealing with only encoded bytes.
    # If we need to decode we could probably get the encoding from the zilla file object (if Dist::Zilla->VERSION >= 5).
    my $content = $readme->slurp_raw;

    my @badges;
    foreach my $badge (@{$self->badges}) {
        if ($badge eq 'travis') {
            push @badges, "[![Build Status](https://travis-ci.org/$user_name/$repository_name.svg?branch=master)](https://travis-ci.org/$user_name/$repository_name)";
        } elsif ($badge eq 'appveyor') {
            push @badges, "[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/$user_name/$repository_name?branch=master&svg=true)](https://ci.appveyor.com/project/$user_name/$repository_name)";
        } elsif ($badge eq 'coveralls') {
            push @badges, "[![Coverage Status](https://coveralls.io/repos/$user_name/$repository_name/badge.svg?branch=master)](https://coveralls.io/r/$user_name/$repository_name?branch=master)"
        } elsif ($badge eq 'gitter') {
            push @badges, "[![Gitter chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/$user_name/$repository_name)";
        } elsif ($badge eq 'cpants') {
            push @badges, "[![Kwalitee status](http://cpants.cpanauthors.org/dist/$distname.png)](http://cpants.charsbar.org/dist/overview/$distname)";
        } elsif ($badge eq 'issues') {
            push @badges, "[![GitHub issues](https://img.shields.io/github/issues/$user_name/$repository_name.svg)](https://github.com/$user_name/$repository_name/issues)";
        } elsif ($badge eq 'github_tag') {
            push @badges, "[![GitHub tag](https://img.shields.io/github/tag/$user_name/$repository_name.svg)]()";
        } elsif ($badge eq 'license') {
            push @badges, "[![Cpan license](https://img.shields.io/cpan/l/$distname.svg)](https://metacpan.org/release/$distname)";
        } elsif ($badge eq 'version') {
            push @badges, "[![Cpan version](https://img.shields.io/cpan/v/$distname.svg)](https://metacpan.org/release/$distname)";
        } elsif ($badge eq 'codecov') {
            push @badges, "[![codecov](https://codecov.io/gh/$user_name/$repository_name/branch/master/graph/badge.svg)](https://codecov.io/gh/$user_name/$repository_name)";
        } elsif ($badge eq 'gitlab_ci') {
            push @badges, "[![build status](https://$base_url/$user_name/$repository_name/badges/master/build.svg)]($repository/$user_name/$repository_name/commits/master)";
        } elsif ($badge eq 'gitlab_cover') {
            push @badges, "[![coverage report](https://$base_url/$user_name/$repository_name/badges/master/coverage.svg)]($repository/$user_name/$repository_name/commits/master)";
        }
    }

    if ($self->place eq 'bottom') {
        $content = $content . "\n\n" . join("\n", @badges);
    } else {
        $content = join("\n", @badges) . "\n\n" . $content;
    }

    $readme->spew_raw($content);
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
    place = bottom
    phase = release

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

=head2 place

    [GitHubREADME::Badge]
    place = bottom

Place the badges at the top or bottom of the README. Defaults to top.

=head2 phase

    [GitHubREADME::Badge]
    phase = release

Which Dist::Zilla phase to add the badges: build or release.
The default is build.

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
