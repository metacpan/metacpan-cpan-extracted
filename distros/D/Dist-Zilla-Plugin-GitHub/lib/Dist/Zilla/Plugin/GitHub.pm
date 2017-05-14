package Dist::Zilla::Plugin::GitHub; # git description: v0.43-3-g82b44d8
# ABSTRACT: Plugins to integrate Dist::Zilla with GitHub
use strict;
use warnings;

our $VERSION = '0.44';

use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use HTTP::Tiny;
use Git::Wrapper;
use Class::Load qw(try_load_class);

has remote => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => 'origin'
);

has repo => (
    is      => 'ro',
    isa     => 'Maybe[Str]'
);

has api  => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.github.com'
);

has prompt_2fa => (
    is  => 'rw',
    isa => 'Bool',
    default => 0
);

#pod =head1 DESCRIPTION
#pod
#pod B<Dist::Zilla::Plugin::GitHub> is a set of plugins for L<Dist::Zilla> intended
#pod to more easily integrate L<GitHub|https://github.com> in the C<dzil> workflow.
#pod
#pod The following is the list of the plugins shipped in this distribution:
#pod
#pod =over 4
#pod
#pod =item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on dzil new
#pod
#pod =item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release
#pod
#pod =item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to META.{yml,json}
#pod
#pod =back
#pod
#pod This distribution also provides an additional C<dzil> command (L<dzil
#pod gh|Dist::Zilla::App::Command::gh>) and a L<plugin
#pod bundle|Dist::Zilla::PluginBundle::GitHub>.
#pod
#pod =cut

sub _get_credentials {
    my ($self, $nopass) = @_;

    my ($login, $pass, $token, $otp);

    my %identity = Config::Identity::GitHub->load
        if try_load_class('Config::Identity::GitHub');

    if (%identity) {
        $login = $identity{login};
    } else {
        $login = `git config github.user`;  chomp $login;
    }

    if (!$login) {
        my $error = %identity ?
            "Err: missing value 'user' in ~/.github" :
            "Err: Missing value 'github.user' in git config";

        $self->log($error);
        return;
    }

    if (!$nopass) {
        if (%identity) {
            $token = $identity{token};
            $pass  = $identity{password};
        } else {
            $token = `git config github.token`;    chomp $token;
            $pass  = `git config github.password`; chomp $pass;

            # modern "tokens" can be used as passwords with basic auth, so...
            # see https://help.github.com/articles/creating-an-access-token-for-command-line-use
            $pass ||= $token if $token;
        }

        $self->log("Err: Login with GitHub token is deprecated")
            if $token && !$pass;

        if (!$pass) {
            $pass = $self->zilla->chrome->prompt_str(
                "GitHub password for '$login'", { noecho => 1 },
            );
        }

        if ($self->prompt_2fa) {
            $otp = $self->zilla->chrome->prompt_str(
                "GitHub two-factor authentication code for '$login'",
                { noecho => 1 },
            );
        }
    }

    return ($login, $pass, $otp);
}

sub _get_repo_name {
    my ($self, $login) = @_;

    my $repo;
    my $git = Git::Wrapper->new('./');

    $repo = $self->repo if $self->repo;

    my $url;
    {
        local $ENV{LANG}='C';
        ($url) = map /Fetch URL: (.*)/,
            $git->remote('show', '-n', $self->remote);
    }

    $url =~ /github\.com.*?[:\/](.*)\.git$/;
    $repo = $1 unless $repo and not $1;

    $repo = $self->zilla->name unless $repo;

    if ($repo !~ /.*\/.*/) {
        ($login, undef, undef) = $self->_get_credentials(1);
        if (defined $login) {
            $repo = "$login/$repo";
        }
    }

    return $repo;
}

sub _check_response {
    my ($self, $response) = @_;

    try {
        my $json_text = decode_json($response->{content});

        if (!$response->{success}) {
            return 'redo' if (($response->{status} eq '401') and
                              ($response->{headers}{'x-github-otp'} =~ /^required/));

            $self->log("Err: ", $json_text->{message});
            return;
        }

        return $json_text;
    } catch {
        if ($response and !$response->{success} and
            $response->{status} eq '599') {
            #possibly HTTP::Tiny error
            $self->log("Err: ", $response->{content});
            return;
        }

        $self->log("Err: Can't connect to GitHub");

        return;
    }
}

1; # End of Dist::Zilla::Plugin::GitHub

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub - Plugins to integrate Dist::Zilla with GitHub

=head1 VERSION

version 0.44

=head1 DESCRIPTION

B<Dist::Zilla::Plugin::GitHub> is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<GitHub|https://github.com> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on dzil new

=item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release

=item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to META.{yml,json}

=back

This distribution also provides an additional C<dzil> command (L<dzil
gh|Dist::Zilla::App::Command::gh>) and a L<plugin
bundle|Dist::Zilla::PluginBundle::GitHub>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GitHub>
(or L<bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org>).

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alessandro Ghedini Karen Etheridge Mike Friedman Dave Rolsky Jeffrey Ryan Thalhammer Doherty Rafael Kitover Ricardo Signes Vyacheslav Matyukhin Alexandr Ciornii Brian Phillips Chris Weyl Ioan Rogers Jose Luis Perez Diez Mohammad S Anwar

=over 4

=item *

Alessandro Ghedini <alessandro@ghedini.me>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Rafael Kitover <rkitover@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Ioan Rogers <ioan.rogers@gmail.com>

=item *

Jose Luis Perez Diez <jluis@escomposlinux.org>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
