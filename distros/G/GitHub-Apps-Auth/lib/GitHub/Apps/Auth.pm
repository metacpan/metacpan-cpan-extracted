package GitHub::Apps::Auth;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use Class::Accessor::Lite (
    rw => [qw/token expires installation_id/],
    ro => [qw/_furl private_key app_id/],
);

use Carp;
use Crypt::PK::RSA;
use Crypt::JWT qw/encode_jwt/;
use Furl;
use JSON qw/decode_json/;
use Time::Moment;

sub _lazy(&) {
    return GitHub::Apps::Auth::Lazy->new($_[0]);
}

use overload
    "\"\"" => sub { shift->issued_token },
    "." => sub {
        my ($self, $other, $reverse) = @_;
        return $reverse ?
            _lazy { "$other" . "$self" } :
            _lazy { "$self" . "$other" };
    };

sub new {
    my ($class, %args) = @_;
    if (!exists $args{private_key} || !$args{private_key}) {
        croak "private_key is required.";
    }
    if (!exists $args{app_id} || !$args{app_id}) {
        croak "app_id is required.";
    }
    if (!$args{installation_id} && !$args{login}) {
        croak "must be set installation_id or login.";
    }

    my $pk = Crypt::PK::RSA->new($args{private_key});

    my $klass = {
        private_key => $pk,
        installation_id => $args{installation_id},
        app_id => $args{app_id},
        expires => 0,
        _furl => Furl->new,
    };
    my $self = bless $klass, $class;

    if (!$self->installation_id) {
        my $installations = $self->installations;
        if (!exists $installations->{$args{login}}) {
            croak $args{login} . " is not found in installations."
        }
        my $installation_id = $installations->{$args{login}};
        $self->installation_id($installation_id);
    }

    return $self;
}

sub installations {
    my $self = shift;

    my $header = $self->_generate_request_header();

    my $resp = $self->_furl->get(
        "https://api.github.com/app/installations",
        $header,
    );
    if (!$resp->is_success) {
        croak "fail to fetch installations: ". $resp->content;
    }

    my $content = decode_json $resp->content;
    my %ids_by_account = map { $_->{account}{login} => $_->{id} } @$content;
    return \%ids_by_account;
}

sub _generate_jwt {
    my $self = shift;

    my $jwt = encode_jwt(
        payload => {
            iat => time(),
            exp => time() + 60,
            iss => $self->app_id,
        },
        alg => "RS256",
        key => $self->private_key,
    );

    return $jwt;
}

sub _generate_request_header {
    my $self = shift;
    my $jwt = $self->_generate_jwt();

    return [
        Authorization => 'Bearer ' . $jwt,
        Accept => "application/vnd.github.machine-man-preview+json",
    ];
}

sub _fetch_access_token {
    my $self = shift;

    my $installation_id = $self->installation_id;
    my $header = $self->_generate_request_header();
    my $resp = $self->_post_to_access_token($installation_id, $header);

    if (!$resp->is_success) {
        croak "cannot fetch access_token: ". $resp->content;
    }

    my $content = decode_json $resp->content;
    my $token = $content->{token};
    $self->token($token);
    my $expires = $content->{expires_at};
    my $tm = Time::Moment->from_string($expires);
    $self->expires($tm->epoch);

    return $token;
}

sub _post_to_access_token {
    my ($self, $installation_id, $header) = @_;

    return $self->_furl->post(
        "https://api.github.com/app/installations/$installation_id/access_tokens",
        $header,
    );
}

sub _is_expired_token {
    my $self = shift;

    return time() > $self->expires;
}

sub issued_token {
    my $self = shift;

    if ($self->_is_expired_token) {
        return $self->_fetch_access_token;
    }

    return $self->token;
}

package
    GitHub::Apps::Auth::Lazy;


sub _lazy(&) {
    return GitHub::Apps::Auth::Lazy->new($_[0]);
}

use overload
    '""'   => sub { shift->{sub}->() . "" },
    "." => sub {
        my ($self, $other, $reverse) = @_;
        return $reverse ?
            _lazy { "$other" . "$self" } :
            _lazy { "$self" . "$other" };
    };

sub new {
    my ($class, $sub) = @_;
    return bless { sub => $sub }, $class;
}

1;
__END__

=encoding utf-8

=head1 NAME

GitHub::Apps::Auth - The fetcher that get a token for GitHub Apps

=head1 SYNOPSIS

    use GitHub::Apps::Auth;
    my $auth = GitHub::Apps::Auth->new(
        private_key     => "<filename>", # when read private key from file
        private_key     => \$pk,         # when read private key from variable
        app_id          => <app_id>,
        login           => <organization or user>
    );
    # This method returns the cached token inside an object.
    # However, refresh expired token automatically.
    my $token  = $auth->issued_token;

    # If you want to use with Pithub
    use Pithub;
    # GitHub::Apps::Auth object behaves like a string.
    # This object calls the `issued_token` method
    # each time it evaluates as a string.
    my $ph = Pithub->new(token => $auth, ...);

=head1 DESCRIPTION

GitHub::Apps::Auth is the fetcher for getting a GitHub token of GitHub Apps.

This module provides a way to get a token that need to be updated regularly for GitHub API.

=head1 CONSTRUCTOR

=head2 new

    my $auth = GitHub::Apps::Auth->new(
        private_key     => "<filename>",
        app_id          => <app_id>,
        installation_id => <installation_id>
    );

Constructs an instance of C<GitHub::Apps::Auth> from credentials.

=head3 parameters

=head4 private_key

B<Required: true>

This parameter is a private key of the GitHub Apps.

This must be a filename or string in the pem format. You can get a private key from Settings page of GitHub Apps. See L<Generating a private key|https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps/#generating-a-private-key>.

=head4 app_id

B<Required: true>

This parameter is the App ID of your GitHub Apps. Use the C<App ID> in the About section of your GitHub Apps page.

=head4 installation_id

B<Required: exclusive to> C<login>

A C<installation_id> is an identifier of installation Organizations or repositories in GitHub Apps. This value is can be obtained from a webhook that is fired during installation. Also can be obtained from webhook's C<Recent Deliveries> of GitHub apps settings.

=head4 login

B<Required: exclusive to> C<installation_id>

C<login> is used for detecting installation_id. If not set C<installation_id> and set C<login>, search C<installation_id> from the list of installations.

=head1 METHODS

=head2 issued_token

    my $token  = $auth->issued_token;

C<issued_token> returns a API token in string. This token is cached while valid.

When calling this method with condition that expired token, this method refreshes a token automatically.

=head2 token

This method returns an API token. Unlike C<issued_token>, this method not refresh an expired token.

=head2 expires

This returns the token expiration date in the epoch.

=head1 OPERATOR OVERLOADS

C<GitHub::Apps::Auth> is overloaded so that C<issued_token> is called when evaluated as a string. So probably be usable in GitHub client that use raw string API token. Ex L<Pithub>.

=head1 SEE ALSO

L<Authenticating with GitHub Apps|https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps>

=head1 LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mackee E<lt>macopy123@gmail.comE<gt>

=cut
