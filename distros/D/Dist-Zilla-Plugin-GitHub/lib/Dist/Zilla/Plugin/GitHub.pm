package Dist::Zilla::Plugin::GitHub; # git description: v0.47-12-g6b55af0
# ABSTRACT: Plugins to integrate Dist::Zilla with GitHub
use strict;
use warnings;

our $VERSION = '0.48';

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

has _login => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_login',
);

has _credentials => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_build_credentials',
);

#pod =head1 DESCRIPTION
#pod
#pod B<Dist-Zilla-Plugin-GitHub> is a set of plugins for L<Dist::Zilla> intended
#pod to more easily integrate L<GitHub|https://github.com> in the C<dzil> workflow.
#pod
#pod The following is the list of the plugins shipped in this distribution:
#pod
#pod =over 4
#pod
#pod =item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on C<dzil new>
#pod
#pod =item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release
#pod
#pod =item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to F<META.{yml,json}>
#pod
#pod =back
#pod
#pod This distribution also provides a plugin bundle, L<Dist::Zilla::PluginBundle::GitHub>,
#pod which provides L<GitHub::Meta|Dist::Zilla::Plugin::GitHub::Meta> and
#pod L<[GitHub::Update|Dist::Zilla::Plugin::GitHub::Update> together in one convenient bundle.
#pod
#pod This distribution also provides an additional C<dzil> command (L<dzil
#pod gh|Dist::Zilla::App::Command::gh>) and a L<plugin
#pod bundle|Dist::Zilla::PluginBundle::GitHub>.
#pod
#pod =cut

sub _build_login {
    my $self = shift;

    my ($login);

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
        return undef;
    }

    return $login;
}

sub _build_credentials {
    my $self = shift;

    my ($login, $pass, $token);

    $login = $self->_login;

    if (!$login) {
        return {};
    }

    my %identity = Config::Identity::GitHub->load
        if try_load_class('Config::Identity::GitHub');

    if (%identity) {
        $token = $identity{token};
        $pass  = $identity{password};
    } else {
        $token = `git config github.token`;    chomp $token;
        $pass  = `git config github.password`; chomp $pass;
    }

    if (!$pass and !$token) {
        $pass = $self->zilla->chrome->prompt_str(
            "GitHub password for '$login'", { noecho => 1 },
        );
    }

    return { login => $login, pass => $pass, token => $token };
}

sub _has_credentials {
    my $self = shift;
    return keys %{$self->_credentials};
}

sub _auth_headers {
    my $self = shift;

    my $credentials = $self->_credentials;

    my %headers = ( Accept => 'application/vnd.github.v3+json' );
    if ($credentials->{pass}) {
        require MIME::Base64;
        my $basic = MIME::Base64::encode_base64("$credentials->{login}:$credentials->{pass}", '');
        $headers{Authorization} = "Basic $basic";
    }
    elsif ($credentials->{token}) {
       $headers{Authorization} = "token $credentials->{token}";
    }

    # This can't be done at object creation because we autodetect the
    # need for 2FA when GitHub says we need it, so we won't know to
    # prompt at object creation time.
    if ($self->prompt_2fa) {
        my $otp = $self->zilla->chrome->prompt_str(
            "GitHub two-factor authentication code for '$credentials->{login}'",
            { noecho => 1 },
        );

        $headers{'X-GitHub-OTP'} = $otp;
        $self->log([ "Using two-factor authentication" ]);
    }

    return \%headers;
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
        $login = $self->_login;
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
                              (($response->{headers}{'x-github-otp'} // '') =~ /^required/));

            require Data::Dumper;
            $self->log("Err: ", Data::Dumper->new([ $response ])->Indent(2)->Terse(1)->Sortkeys(1)->Dump);
            return;
        }

        return $json_text;
    } catch {
        $self->log("Error: $_");
        if ($response and !$response->{success} and
            $response->{status} eq '599') {
            #possibly HTTP::Tiny error
            $self->log("Err: ", $response->{content});
            return;
        }

        $self->log("Error communicating with GitHub: $_");

        return;
    };
}

__PACKAGE__->meta->make_immutable;
1; # End of Dist::Zilla::Plugin::GitHub

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub - Plugins to integrate Dist::Zilla with GitHub

=head1 VERSION

version 0.48

=head1 DESCRIPTION

B<Dist-Zilla-Plugin-GitHub> is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<GitHub|https://github.com> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on C<dzil new>

=item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release

=item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to F<META.{yml,json}>

=back

This distribution also provides a plugin bundle, L<Dist::Zilla::PluginBundle::GitHub>,
which provides L<GitHub::Meta|Dist::Zilla::Plugin::GitHub::Meta> and
L<[GitHub::Update|Dist::Zilla::Plugin::GitHub::Update> together in one convenient bundle.

This distribution also provides an additional C<dzil> command (L<dzil
gh|Dist::Zilla::App::Command::gh>) and a L<plugin
bundle|Dist::Zilla::PluginBundle::GitHub>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GitHub>
(or L<bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alessandro Ghedini Karen Etheridge Dave Rolsky Mike Friedman Jeffrey Ryan Thalhammer Joelle Maslak Doherty Rafael Kitover Alexandr Ciornii Brian Phillips Chris Weyl Ioan Rogers Jose Luis Perez Diez Mohammad S Anwar Paul Cochrane Ricardo Signes Vyacheslav Matyukhin

=over 4

=item *

Alessandro Ghedini <alessandro@ghedini.me>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=item *

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=item *

Joelle Maslak <jmaslak@antelope.net>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Rafael Kitover <rkitover@cpan.org>

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

=item *

Paul Cochrane <paul.cochrane@posteo.de>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
