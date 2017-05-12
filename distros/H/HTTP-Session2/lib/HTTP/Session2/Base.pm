package HTTP::Session2::Base;
use strict;
use warnings;
use utf8;
use 5.008_001;

use Digest::SHA;
use Carp ();

use Mouse;

has env => (
    is => 'ro',
    required => 1,
);

has session_cookie => (
    is => 'ro',
    lazy => 1,
    default => sub {
        +{
            httponly => 1,
            secure   => 0,
            name     => 'hss_session',
            path     => '/',
        },
    },
    # Need shallow copy
    trigger => sub {
        my $self = shift;
        $self->{session_cookie} = +{%{$self->{session_cookie}}};
    },
);

has xsrf_cookie => (
    is => 'ro',
    lazy => 1,
    default => sub {
        # httponly must be false. AngularJS need to read this value.
        +{
            httponly => 0,
            secure   => 0,
            name     => 'XSRF-TOKEN',
            path     => '/',
        },
    },
    # Need shallow copy
    trigger => sub {
        my $self = shift;
        $self->{xsrf_cookie} = +{%{$self->{xsrf_cookie}}};
    },
);

has hmac_function => (
    is => 'ro',
    default => sub { \&Digest::SHA::sha1_hex },
);

has is_dirty => (
    is => 'rw',
    default => sub { 0 },
);

has is_fresh => (
    is => 'rw',
    default => sub { 0 },
);

has necessary_to_send => (
    is => 'rw',
    default => sub { 0 },
);

has secret => (
    is => 'ro',
    required => 1,
    trigger => sub {
        my ($self, $secret) = @_;
        if (length($secret) < 20) {
            Carp::cluck("Secret string too short");
        }
    },
);

no Mouse;

sub _data {
    my $self = shift;
    unless ($self->{_data}) {
        $self->load_or_create();
    }
    $self->{_data};
}

sub id {
    my $self = shift;
    unless ($self->{id}) {
        $self->load_or_create();
    }
    $self->{id};
}

sub load_or_create {
    my $self = shift;
    $self->load_session() || $self->create_session();
}

sub load_session   { die "Abstract method" }
sub create_session { die "Abstract method" }

sub set {
    my ($self, $key, $value) = @_;
    $self->_data->{$key} = $value;
    $self->is_dirty(1);
}

sub get {
    my ($self, $key) = @_;
    $self->_data->{$key};
}

sub remove {
    my ($self, $key) = @_;
    $self->is_dirty(1);
    delete $self->_data->{$key};
}

sub validate_xsrf_token {
    my ($self, $token) = @_;

    # If user does not have any session data, user don't need a XSRF protection.
    return 1 unless %{$self->_data};
    return 0 unless defined $token;
    return 1 if $token eq $self->xsrf_token;
    return 0;
}

sub finalize_plack_response {
    my ($self, $res) = @_;

    my @cookies = $self->finalize();
    while (my ($name, $cookie) = splice @cookies, 0, 2) {
        my $baked = Cookie::Baker::bake_cookie( $name, $cookie );
        $res->headers->push_header('Set-Cookie' => $baked);
    }
}

sub finalize_psgi_response {
    my ($self, $res) = @_;
    my @cookies = $self->finalize();
    while (my ($name, $cookie) = splice @cookies, 0, 2) {
        my $baked = Cookie::Baker::bake_cookie( $name, $cookie );
        push @{$res->[1]}, (
            'Set-Cookie' => $baked,
        );
    }
}

sub finalize { die "Abstract method" }

1;
__END__

=head1 NAME

HTTP::Session2 - Abstract base class for HTTP::Session2

=head1 DESCRIPTION

This is an abstract base class for HTTP::Session2.

=head1 Common Methods

=over 4

=item C<< my $session = HTTP::Session2::*->new(%args) >>

Create new instance.

=over 4

=item hmac_function: CodeRef

This module uses HMAC to sign the session data.
You can choice HMAC function for security enhancements and performance tuning.

Default: C<< \&Digest::SHA::sha1_hex >>

=item session_cookie: HashRef

Options for session cookie. For more details, please look L<Cookie::Baker>.

Default:

        +{
            httponly => 1,
            secure   => 0,
            name     => 'hss_session',
            path     => '/',
        },

=item xsrf_cookie: HashRef

HTTP::Session2 generates 2 cookies. One is for session, other is for XSRF token.
This parameter configures parameters for XSRF token cookie.
For more details, please look L<Cookie::Baker>.

Default:

        +{
            httponly => 0,
            secure   => 0,
            name     => 'XSRF-TOKEN',
            path     => '/',
        },

Note: C<httponly> flag should be false. Because this parameter should be readable from JavaScript.
And it does not decrease security.

=back

=item C<< $session->get($key: Str) >>

Get a value from session.

=item C<< $session->set($key: Str, $value:Any) >>

Set a value to session. This means you can set any Serializable data to the storage.

=item C<< $session->remove($key: Str) >>

Remove the value from session.

=item C<< $session->validate_xsrf_token($token: Str) >>

    my $token = $req->header('X-XSRF-TOKEN') || $req->param('XSRF-TOKEN');
    unless ($session->validate_xsrf_token($token)) {
        return Plack::Response->new(
            403,
            [],
            'Missing XSRF token'
        );
    }

Validate XSRF token. If the XSRF token is valid, return true. False otherwise.

=item C<< $session->xsrf_token() >>

Get a XSRF token in string.

=item C<< $session->finalize_plack_response($res: Plack::Response) >>

Finalize cookie headers and inject it to L<Plack::Response> instance.

=back
