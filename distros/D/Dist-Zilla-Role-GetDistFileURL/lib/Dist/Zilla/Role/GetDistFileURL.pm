package Dist::Zilla::Role::GetDistFileURL;

use 5.010001;
use namespace::autoclean;
use Moose::Role;
with 'Dist::Zilla::Role::ModuleMetadata';

use URI::Escape::Path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-09'; # DATE
our $DIST = 'Dist-Zilla-Role-GetDistFileURL'; # DIST
our $VERSION = '0.002'; # VERSION

sub get_dist_file_url {
    my ($self, $hosting, $path) = @_;

    # remove leading slashes
    $path =~ s!\A/+!!;

    my $url;
    if ($hosting eq 'metacpan') {

        my $authority = $self->zilla->distmeta->{x_authority};
        $self->$self->log_fatal(["Distribution doesn't have x_authority metadata"]) unless $authority;
        $self->$self->log_fatal(["x_authority is not cpan:"]) unless $authority =~ s/^cpan://;
        my $dist_name = $self->zilla->name;
        my $dist_version = $self->zilla->version;

        $url = sprintf(
            "https://st.aticpan.org/source/%s/%s-%s/%s",
            $authority,
            $dist_name,
            $dist_version,
            uri_escape($path),
        );

    } elsif ($hosting eq 'github' || $hosting eq 'gitlab' || $hosting eq 'bitbucket') {

        my $resources = $self->zilla->distmeta->{resources};
        $self->log_fatal(["Distribution doesn't have resources metadata"]) unless $resources;
        $self->log_fatal(["Distribution resources metadata doesn't have repository"]) unless $resources->{repository};
        $self->log_fatal(["Repository in distribution resources metadata is not a hash"]) unless ref($resources->{repository}) eq 'HASH';
        my $type = $resources->{repository}{type};
        $self->log_fatal(["Repository in distribution resources metadata doesn't have type"]) unless $type;
        my $url = $resources->{repository}{url};
        $self->log_fatal(["Repository in distribution resources metadata doesn't have url"]) unless $url;
        my ($github_user, $github_repo);
        my ($gitlab_user, $gitlab_proj);
        my ($bitbucket_user, $bitbucket_repo);
        if ($hosting eq 'github') {
            $self->log_fatal(["Repository type is not git"]) unless $type eq 'git';
            $self->log_fatal(["Repository URL is not github"]) unless ($github_user, $github_repo) = $url =~ m!github\.com/([^/]+)/([^/]+)\.git!;
        } elsif ($hosting eq 'gitlab') {
            $self->log_fatal(["Repository type is not git"]) unless $type eq 'git';
            $self->log_fatal(["Repository URL is not gitlab"]) unless ($gitlab_user, $gitlab_proj) = $url =~ m!gitlab\.com/([^/]+)/([^/]+)\.git!;
        } elsif ($hosting eq 'bitbucket') {
            $self->log_fatal(["Repository type is not git (mercurial not yet supported)"]) unless $type eq 'git';
            $self->log_fatal(["Repository URL is not bitbucket"]) unless ($bitbucket_user, $bitbucket_repo) = $url =~ m!bitbucket\.org/([^/]+)/([^/]+)\.git!;
        }

        if ($hosting eq 'github') {
            $url = sprintf(
                "https://raw.githubusercontent.com/%s/%s/master/%s",
                $github_user,
                $github_repo,
                uri_escape($path),
            );
        } elsif ($hosting eq 'gitlab') {
            $url = sprintf(
                "https://gitlab.com/%s/%s/raw/master/%s",
                $gitlab_user,
                $gitlab_proj,
                uri_escape($path),
            );
        } else { # bitbucket
            $url = sprintf(
                "https://bytebucket.org/%s/%s/raw/master/%s",
                $bitbucket_user,
                $bitbucket_repo,
                uri_escape($path),
            );
        }

    } else {
        $self->log_fatal(["Unknown hosting value '%s'", $hosting]);
    }

    return $url;
}

1;
# ABSTRACT: Get URL to a file inside a Perl distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::GetDistFileURL - Get URL to a file inside a Perl distribution

=head1 VERSION

This document describes version 0.002 of Dist::Zilla::Role::GetDistFileURL (from Perl distribution Dist-Zilla-Role-GetDistFileURL), released on 2023-11-09.

=head1 PROVIDED METHODS

=head2 get_dist_file_url

Usage:

 my $url = $obj->get_dist_file_url($hosting, $path);

Example:

 my $url = $obj->get_dist_file_url('metacpan', 'share/image/image1.jpg');
 my $url = $obj->get_dist_file_url('github', 'META.json');

Known hosting:

=over

=item * metacpan

This is the default because all distributions uploaded to PAUSE/CPAN will
normally show up on L<metacpan.org>. Note that for images, some people advise
not to abuse metacpan.org to host images because metacpan.org is not an image
hosting service. However, at the time of this writing, I couldn't find any
mention of this in the metacpan.org FAQ or About pages.

=item * github

This can only be used if the distribution specifies its repository in its
metadata, and the repository URL's host is github.com.

=item * gitlab

This can only be used if the distribution specifies its repository in its
metadata, and the repository URL's host is gitlab.org.

=item * bitbucket

This can only be used if the distribution specifies its repository in its
metadata, and the repository URL's host is bitbucket.org.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Role-GetDistFileURL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Role-GetDistFileURL>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-GetDistFileURL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
