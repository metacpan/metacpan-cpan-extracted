package Dist::Zilla::Plugin::GitHub::Update;
# ABSTRACT: Update a GitHub repo's info on release
use strict;
use warnings;

our $VERSION = '0.49';

use JSON::MaybeXS;
use Moose;
use List::Util 'first';

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::AfterRelease';

# deprecated and no longer documented. Use 'metacpan' instead!
has cpan => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has p3rl => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has metacpan => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has meta_home => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

#pod =head1 SYNOPSIS
#pod
#pod Configure git with your GitHub credentials:
#pod
#pod     $ git config --global github.user LoginName
#pod     $ git config --global github.password GitHubPassword
#pod
#pod Alternatively you can install L<Config::Identity> and write your credentials
#pod in the (optionally GPG-encrypted) C<~/.github> file as follows:
#pod
#pod     login LoginName
#pod     password GitHubpassword
#pod
#pod (if only the login name is set, the password will be asked interactively).
#pod
#pod You can also generate an access token for "full control over repositories" by following
#pod L<these instructions|https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/>,
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
#pod This Dist::Zilla plugin updates the information of the GitHub repository
#pod when C<dzil release> is run.
#pod
#pod =cut

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $option = first { $self->$_ } qw(meta_home metacpan p3rl cpan);
    if ($option eq 'cpan') {
        $self->log->warn('the \'cpan\' option has been removed: please use \'metacpan\' instead');
        $option = 'metacpan';
    }

    $config->{+__PACKAGE__} = {
        $option => ($self->$option ? 1 : 0),
    };

    return $config;
};

sub after_release {
    my $self      = shift;
    my ($opts)    = @_;
    my $dist_name = $self->zilla->name;

    return if (!$self->_has_credentials);

    my $repo_name = $self->_get_repo_name($self->_credentials->{login});
    if (not $repo_name) {
        $self->log('cannot update GitHub repository info');
        return;
    }

    my $params = {
        name => ($repo_name =~ /\/(.*)$/)[0],
        description => $self->zilla->abstract,
    };

    my $with;
    if ($self->meta_home && (my $meta_home = $self->zilla->distmeta->{resources}{homepage})) {
        $with = ' using distmeta URL';
        $params->{homepage} = $meta_home;
    } elsif ($self->metacpan) {
        $with = ' using MetaCPAN URL';
        $params->{homepage} = "https://metacpan.org/release/$dist_name/";
    } elsif ($self->p3rl) {
        $with = ' using P3rl URL';
        my $guess_name = $dist_name;
        $guess_name =~ s/\-/\:\:/g;
        $params->{homepage} = "https://p3rl.org/$guess_name";
    }

    $self->log('Updating GitHub repository info'.($with // ''));

    my $url = $self->api."/repos/$repo_name";

    my $current = $self->_current_params($url);
    if ($current &&
        ($current->{name} || '') eq $params->{name} &&
        ($current->{description} || '') eq $params->{description} &&
        ($current->{homepage} || '') eq $params->{homepage}) {

        $self->log("GitHub repo info is up to date");
        return;
    }

    $self->log_debug("Sending PATCH $url");
    my $response = HTTP::Tiny->new->request('PATCH', $url, {
        content => encode_json($params),
        headers => $self->_auth_headers,
    });

    my $repo = $self->_check_response($response);

    return if not $repo;

    if ($repo eq 'redo') {
        $self->log("Retrying with two-factor authentication");
        $self->prompt_2fa(1);
        $repo = $self->after_release($opts);
        return if not $repo;
    }
}

sub _current_params {
    my $self  = shift;
    my ($url) = @_;

    my $http = HTTP::Tiny->new;

    $self->log_debug("Sending GET $url");
    my $response = $http->request('GET', $url);

    return $self->_check_response($response);
}

__PACKAGE__->meta->make_immutable;
1; # End of Dist::Zilla::Plugin::GitHub::Update

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub::Update - Update a GitHub repo's info on release

=head1 VERSION

version 0.49

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively you can install L<Config::Identity> and write your credentials
in the (optionally GPG-encrypted) C<~/.github> file as follows:

    login LoginName
    password GitHubpassword

(if only the login name is set, the password will be asked interactively).

You can also generate an access token for "full control over repositories" by following
L<these instructions|https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/>,

then, in your F<dist.ini>:

    # default config
    [GitHub::Meta]

    # to override the repo name
    [GitHub::Meta]
    repo = SomeRepo

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin updates the information of the GitHub repository
when C<dzil release> is run.

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

=item C<p3rl>

The GitHub homepage field will be set to the p3rl.org shortened URL
(e.g. C<https://p3rl.org/Dist::Zilla::Plugin::GitHub>) if this option is set to true (default is
false).

=item C<metacpan>

The GitHub homepage field will be set to the metacpan.org distribution URL
(e.g. C<https://metacpan.org/release/Dist-Zilla-Plugin-GitHub>) if this option is set to true
(default).

This takes precedence over the C<p3rl> options (if both are
true, metacpan will be used).

=item C<meta_home>

The GitHub homepage field will be set to the value present in the dist meta
(e.g. the one set by other plugins) if this option is set to true (default is
false). If no value is present in the dist meta, this option is ignored.

This takes precedence over the C<metacpan> and C<p3rl> options (if all
three are true, meta_home will be used).

=item C<prompt_2fa>

Prompt for GitHub two-factor authentication code if this option is set to true
(default is false). If this option is set to false but GitHub requires 2fa for
the login, it'll be automatically enabled.

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
