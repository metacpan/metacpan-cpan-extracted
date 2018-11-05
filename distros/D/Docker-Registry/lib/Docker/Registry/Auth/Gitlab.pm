package Docker::Registry::Auth::Gitlab;
use Moo;
use Types::Standard qw/Str/;
use namespace::autoclean;

# ABSTRACT: Authentication module for gitlab registry

with 'Docker::Registry::Auth';

use Docker::Registry::Types qw(DockerRegistryURI);
use HTTP::Tiny;
use JSON::MaybeXS qw(decode_json);

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has access_token => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has jwt => (
    is      => 'ro',
    isa     => DockerRegistryURI,
    coerce  => 1,
    default => 'https://gitlab.com/jwt/auth',
);

sub _build_token_uri {
    my ($self, $scope) = @_;

    my $uri = $self->jwt->clone;

    $uri->query_form({
        service       => 'container_registry',
        scope         => $scope,
        client_id     => 'docker',
        offline_token => 'true',
    });

    $uri->userinfo(join(':', $self->username, $self->access_token));
    return $uri;
}

sub get_bearer_token {
    my ($self, $scope) = @_;

    my $uri = $self->_build_token_uri($scope);

    my $ua = HTTP::Tiny->new();
    my $res = $ua->get($uri);

    if ($res->{success}) {
        return decode_json($res->{content})->{token};
    }

    die "Unable to get token from gitlab!";
}

sub authorize {
    my ($self, $request, $scope) = @_;

    my $bearer_token = $self->get_bearer_token($scope);

    $request->header('Authorization', 'Bearer ' . $bearer_token);
    $request->header('Accept',
        'application/vnd.docker.distribution.manifest.v2+json');

    return $request;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 DESCRIPTION

Authenticate against gitlab registry

=head1 SYNOPSIS

    use Docker::Registry::Auth::Gitlab;
    use HTTP::Tiny;

    my $auth = Docker::Registry::Auth::Gitlab->new(
        username => 'foo',
        access_token => 'bar',
    );

    my $req = $auth->authorize(HTTP::Request->new('GET', 'https://foo.bar.nl'));
    my $res = HTTP::Tiny->new()->get($req);

=head1 ATTRIBUTES

=head2 username

Your username at gitlab.

=head2 access_token

The access token you get from
L<gitlab|https://gitlab.com/profile/personal_access_tokens> with
'read_registry' access.

=head2 repo

The repository you request access to.

=head2 jwt

The endpoint to request the JWT token from, defaults to
'https://gitlab.com/jwt/auth'. You can use a 'Str' or an URI object.

=head1 METHODS

=head2 get_bearer_token

The builder of the C<bearer_token> attribute.

=head2 authorize

Implements the method as required by L<Docker::Registry::Auth>. Add the
"Authorization" header to the request with the "Bearer" token.

=head2 SEE ALSO

L<Docker::Registry::Auth>, L<Docker::Registery::Types> and L<Docker::Registry::Gitlab>.
