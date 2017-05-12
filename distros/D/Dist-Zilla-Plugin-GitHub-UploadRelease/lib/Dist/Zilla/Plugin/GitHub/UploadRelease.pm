package Dist::Zilla::Plugin::GitHub::UploadRelease;

# ABSTRACT: Upload the package to GitHub after release

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use JSON qw(encode_json);
use Moose;
use Try::Tiny;
use Git::Wrapper;
use File::Basename;
use File::Slurp qw(read_file);
use MIME::Base64 qw(encode_base64);

use Dist::Zilla::Plugin::GitHub ();
use Dist::Zilla::Plugin::Git::Tag ();

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::AfterRelease';


has _last_status => (
    is => 'rw',
    isa => 'Int',
);

sub _api_request {
    my ($self, $method, $path, $payload, $headers) = @_;

    my $url = $path =~ m{^https?://}i ? $path :  $self->api . $path;

    $self->log_debug("$method $url");

    $headers //= {};

    my ($login, $pass, $otp) = $self->_get_credentials(0);

    if ($pass) {
        my $basic = encode_base64("$login:$pass", '');
        $headers->{Authorization} = "Basic $basic";
    }

    if ($self->prompt_2fa) {
        $headers->{'X-GitHub-OTP'} = $otp;
        $self->log("Using two-factor authentication");
    }

    my $response = HTTP::Tiny->new->request('POST', $url, {
        content => (ref($payload) ? encode_json($payload) : $payload),
        headers => $headers,
    });

    $self->_last_status($response->{status});

    my $result = $self->_check_response($response);
 
    return unless $result;
 
    if ($result eq 'redo') {
        $self->log("Retrying with two-factor authentication");
        $self->prompt_2fa(1);
        return __CODE__->(@_);
    }

    return $result;
}


sub after_release {
    my ($self, $archive) = @_;

    my $dist_name = $self->zilla->name;

    my ($login) = $self->_get_credentials(1);
    return unless $login;

    my $repo_name = $self->_get_repo_name($login);

    my $git_tag_plugin = $self->zilla->plugin_named('Git::Tag') // $self->log_fatal('Plugin Git::Tag not found');

    my $tag = $git_tag_plugin->tag;

    my ($result, $status);

    $self->log("Create release for $tag in $repo_name");
    $result = $self->_api_request(POST => "/repos/$repo_name/releases", { tag_name => $tag });

    $status = $self->_last_status;
    if ($status ne 201) {
        $self->log_fatal("Release NOT created: $status");
    }

    my $upload_url = $result->{upload_url};
    $upload_url =~ s{\{.*?\}$}{};
    $upload_url .= '?name='.$archive;

    my $payload = read_file($archive);

    $self->log("Upload $archive to GitHub");
    $result = $self->_api_request(POST => $upload_url, $payload, { 'Content-Type' => 'application/gzip' });

    $status = $self->_last_status;
    if ($status ne 201) {
        $self->log_fatal("Release NOT uploaded: $status");
    }
    $self->log('Done');
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::GitHub::UploadRelease - Upload the package to GitHub after release

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    git config --global github.user LoginName
    git config --global github.password GitHubPassword

Alternatively you can install L<Config::Identity> and write your credentials in the (optionally GPG-encrypted) C<~/.github> file as follows:

    login LoginName
    password GitHubpassword

(if only the login name is set, the password will be asked interactively)
then, in your F<dist.ini>:

    [GitHub::UploadRelease]

=head1 DESCRIPTION

This Dist::Zilla plugin uploads the package archive file after a new release is made with I<dzil release>.

=head1 ACKNOWLEGDEMENTS

This module is heavily inspired by L<Dist::Zilla::Plugin::GitHub::Update>. This module is based on their source code and depends on its parent module, L<Dist::Zilla::Plugin::GitHub>.

=head1 TODO

In case of any errors, there is no much output.

=for Pod::Coverage after_release

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/zurborg/libdist-zilla-plugin-github-uploadrelease-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by David Zurborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
