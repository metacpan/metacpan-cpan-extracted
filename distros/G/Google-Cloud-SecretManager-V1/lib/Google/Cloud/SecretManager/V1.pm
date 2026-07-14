package Google::Cloud::SecretManager::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Auth;
use Carp qw(croak);

our $VERSION = '0.01';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $client = Google::gRPC::Client->new(
        target     => 'secretmanager.googleapis.com:443',
        auth_token => $token,
    );
    $self->transport($client);
}

sub call_rpc {
    my ($self, $method, $request_msg, $response_class) = @_;
    croak 'transport not initialized' unless $self->transport;
    return $self->transport->call_unary($method, $request_msg, $response_class);
}

1;

__END__

=head1 NAME

Google::Cloud::SecretManager::V1 - Google Cloud Secret Manager V1 API Client

=head1 SYNOPSIS

    use Google::Cloud::SecretManager::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();
    my $client = Google::Cloud::SecretManager::V1->new(credentials => $auth);

=head1 DESCRIPTION

Google Cloud Secret Manager V1 API Client over high-performance gRPC transport.

=head1 LICENSE

Apache 2.0

=cut
