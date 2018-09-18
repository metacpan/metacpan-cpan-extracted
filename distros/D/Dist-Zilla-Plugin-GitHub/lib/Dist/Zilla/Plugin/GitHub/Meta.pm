package Dist::Zilla::Plugin::GitHub::Meta;
# ABSTRACT: Add a GitHub repo's info to META.{yml,json}
use strict;
use warnings;

our $VERSION = '0.47';

use JSON::MaybeXS;
use Moose;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::MetaProvider';

has homepage => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has bugs => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has wiki => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has fork => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has require_auth => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

#pod =head1 SYNOPSIS
#pod
#pod Configure git with your GitHub login name:
#pod
#pod     $ git config --global github.user LoginName
#pod
#pod then, in your F<dist.ini>:
#pod
#pod     # default config
#pod     [GitHub::Meta]
#pod
#pod     # to override the repo name
#pod     [GitHub::Meta]
#pod     repo = SomeRepo
#pod
#pod See L</ATTRIBUTES> for more options.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This Dist::Zilla plugin adds some information about the distribution's GitHub
#pod repository to the META.{yml,json} files, using the official L<CPAN::Meta>
#pod specification.
#pod
#pod Note that, to work properly, L<GitHub::Meta> needs the network to connect to
#pod GitHub itself. If the network is not available, it will try to come up with
#pod sensible data, but it may be inaccurate.
#pod
#pod L<GitHub::Meta> currently sets the following fields:
#pod
#pod =over 4
#pod
#pod =item C<homepage>
#pod
#pod The official home of this project on the web, taken from the GitHub repository
#pod info. If the C<homepage> option is set to false this will be skipped (default is
#pod true).
#pod
#pod When offline, this is not set.
#pod
#pod =item C<repository>
#pod
#pod =over 4
#pod
#pod =item C<web>
#pod
#pod URL pointing to the GitHub page of the project.
#pod
#pod =item C<url>
#pod
#pod URL pointing to the GitHub repository (C<git://...>).
#pod
#pod =item C<type>
#pod
#pod This is set to C<git> by default.
#pod
#pod =back
#pod
#pod =item C<bugtracker>
#pod
#pod =over 4
#pod
#pod =item C<web>
#pod
#pod URL pointing to the GitHub issues page of the project. If the C<bugs> option is
#pod set to false (default is true) or the issues are disabled in the GitHub
#pod repository, this will be skipped.
#pod
#pod When offline, this is not set.
#pod
#pod =back
#pod
#pod =back
#pod
#pod =cut

sub metadata {
    my $self    = shift;
    my ($opts)  = @_;
    my $offline = 0;

    my $repo_name = $self->_get_repo_name;
    return {} if (!$repo_name);

    my $http = HTTP::Tiny->new;

    $self->log("Getting GitHub repository info");

    my $url      = $self->api."/repos/$repo_name";
    my $response = $http->request('GET', $url, $self->require_auth ? {headers => $self->_auth_headers} : ());

    my $repo = $self->_check_response($response);
    $offline = 1 if not $repo;

    $self->log("Using offline repository information") if $offline;

    if (!$offline && $repo->{fork} == JSON->true() && $self->fork == 1) {
        my $parent   = $repo->{parent}{full_name};
        my $url      = $self->api.'/repos/'.$parent;
        my $response = $http->request('GET', $url);

        $repo = $self->_check_response($response);
        return if not $repo;
    }

    my ($html_url, $git_url, $homepage, $bugtracker, $wiki);

    $html_url = $offline ?
        "https://github.com/$repo_name" :
        $repo->{html_url};

    $git_url = $offline ?
        "git://github.com/$repo_name.git" :
        $repo->{git_url};

    $homepage = $offline ? undef : $repo->{homepage};

    if (!$offline && $repo->{has_issues} == JSON->true()) {
        $bugtracker = "$html_url/issues";
    }

    if (!$offline && $repo->{has_wiki} == JSON->true()) {
        $wiki = "$html_url/wiki";
    }

    my $meta;
    $meta->{resources} = {
        repository => {
            web  => $html_url,
            url  => $git_url,
            type => 'git'
        }
    };

    if ($self->wiki && $self->wiki == 1 && $wiki) {
        $meta->{resources}{homepage} = $wiki;
    } elsif ($self->homepage && $self->homepage == 1 && $homepage) {
        $meta->{resources}{homepage} = $homepage;

    }

    if ($self->bugs && $self->bugs == 1 && $bugtracker) {
        $meta->{resources}{bugtracker} =
            { web => $bugtracker };
    }

    return $meta;
}

__PACKAGE__->meta->make_immutable;

1; # End of Dist::Zilla::Plugin::GitHub::Meta

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub::Meta - Add a GitHub repo's info to META.{yml,json}

=head1 VERSION

version 0.47

=head1 SYNOPSIS

Configure git with your GitHub login name:

    $ git config --global github.user LoginName

then, in your F<dist.ini>:

    # default config
    [GitHub::Meta]

    # to override the repo name
    [GitHub::Meta]
    repo = SomeRepo

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin adds some information about the distribution's GitHub
repository to the META.{yml,json} files, using the official L<CPAN::Meta>
specification.

Note that, to work properly, L<GitHub::Meta> needs the network to connect to
GitHub itself. If the network is not available, it will try to come up with
sensible data, but it may be inaccurate.

L<GitHub::Meta> currently sets the following fields:

=over 4

=item C<homepage>

The official home of this project on the web, taken from the GitHub repository
info. If the C<homepage> option is set to false this will be skipped (default is
true).

When offline, this is not set.

=item C<repository>

=over 4

=item C<web>

URL pointing to the GitHub page of the project.

=item C<url>

URL pointing to the GitHub repository (C<git://...>).

=item C<type>

This is set to C<git> by default.

=back

=item C<bugtracker>

=over 4

=item C<web>

URL pointing to the GitHub issues page of the project. If the C<bugs> option is
set to false (default is true) or the issues are disabled in the GitHub
repository, this will be skipped.

When offline, this is not set.

=back

=back

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the name will be extracted from
the URL of the remote specified in the C<remote> option, and if that fails the
dist name (from dist.ini) is used. It can also be in the form C<user/repo>
when it belongs to another GitHub user/organization.

=item C<remote>

The name of the Git remote pointing to the GitHub repository (C<"origin"> by
default). This is used when trying to guess the repository name.

=item C<homepage>

The META homepage field will be set to the value of the homepage field set on
the GitHub repository's info if this option is set to true (default).

=item C<wiki>

The META homepage field will be set to the URL of the wiki of the GitHub
repository, if this option is set to true (default is false) and if the GitHub
Wiki happens to be activated (see the GitHub repository's C<Admin> panel).

=item C<bugs>

The META bugtracker web field will be set to the issue's page of the repository
on GitHub, if this options is set to true (default) and if the GitHub Issues happen to
be activated (see the GitHub repository's C<Admin> panel).

=item C<fork>

If the repository is a GitHub fork of another repository this option will make
all the information be taken from the original repository instead of the forked
one, if it's set to true (default).

=item C<require_auth>

If this is true, then the API request will be sent with Authorization
headers. This is useful if you are behind some sort of proxy that is
triggering the GitHub rate limiting.

=item C<prompt_2fa>

Prompt for GitHub two-factor authentication code if this option is set to true
(default is false). If this option is set to false but GitHub requires 2fa for
the login, it'll be automatically enabled.

This is only relevant if C<require_auth> is true.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GitHub>
(or L<bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
