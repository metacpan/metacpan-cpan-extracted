package Dist::Zilla::PluginBundle::GitHub;
# ABSTRACT: GitHub plugins all-in-one
use strict;
use warnings;

our $VERSION = '0.46';

use Moose;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::PluginBundle::Easy';

has '+repo' => (
    lazy    => 1,
    default => sub { $_[0]->payload->{repo} }
);

has '+prompt_2fa' => (
    lazy    => 1,
    default => sub { $_[0]->payload->{prompt_2fa} }
);

# GitHub::Meta

has homepage => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{homepage} ?
                $_[0]->payload->{homepage} : 1
        }
);

has bugs => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{bugs} ?
                $_[0]->payload->{bugs} : 1
        }
);

has wiki => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{wiki} ?
                $_[0]->payload->{wiki} : 0
        }
);

has fork => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{fork} ?
                $_[0]->payload->{fork} : 1
        }
);

# GitHub::Update

# deprecated and no longer documented. Use 'metacpan' instead!
has cpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{cpan} ?
                $_[0]->payload->{cpan} : 1
        }
);

has p3rl => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{p3rl} ?
                $_[0]->payload->{p3rl} : 0
        }
);

has metacpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{metacpan} ?
                $_[0]->payload->{metacpan} : 0
        }
);

has meta_home => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
            defined $_[0]->payload->{meta_home} ?
                $_[0]->payload->{meta_home} : 0
        }
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
#pod (if only the login name is set, the password will be asked interactively)
#pod
#pod then, in your F<dist.ini>:
#pod
#pod     [@GitHub]
#pod     repo = SomeRepo
#pod
#pod =head1 DESCRIPTION
#pod
#pod This bundle automatically adds all the GitHub plugins.
#pod
#pod =cut

sub configure {
    my $self = shift;

    $self->add_plugins(
        ['GitHub::Meta' => {
            repo => $self->repo,
            homepage => $self->homepage,
            bugs => $self->bugs,
            wiki => $self->wiki,
            fork => $self->fork
        }],

        ['GitHub::Update' => {
            repo => $self->repo,
            cpan => $self->cpan,
            p3rl => $self->p3rl,
            metacpan  => $self->metacpan,
            meta_home => $self->meta_home,
            prompt_2fa => $self->prompt_2fa
        }]
    );
}

__PACKAGE__->meta->make_immutable;
1; # End of Dist::Zilla::PluginBundle::GitHub

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::GitHub - GitHub plugins all-in-one

=head1 VERSION

version 0.46

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively you can install L<Config::Identity> and write your credentials
in the (optionally GPG-encrypted) C<~/.github> file as follows:

    login LoginName
    password GitHubpassword

(if only the login name is set, the password will be asked interactively)

then, in your F<dist.ini>:

    [@GitHub]
    repo = SomeRepo

=head1 DESCRIPTION

This bundle automatically adds all the GitHub plugins.

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

=item C<p3rl>

The GitHub homepage field will be set to the p3rl.org shortened URL
(e.g. C<http://p3rl.org/Dist::Zilla::PluginBundle::GitHub>) if this option is set to true (default is
false).

=item C<metacpan>

The GitHub homepage field will be set to the metacpan.org distribution URL
(e.g. C<http://metacpan.org/release/Dist-Zilla-Plugin-GitHub>) if this option is set to true
(default is false).

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
(default is false).

=back

=head1 SEE ALSO

L<Dist::Zilla::Plugin::GitHub::Meta>, L<Dist::Zilla::Plugin::GitHub::Update>

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
