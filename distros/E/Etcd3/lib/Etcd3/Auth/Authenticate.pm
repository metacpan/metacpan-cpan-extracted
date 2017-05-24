use utf8;
package Etcd3::Auth::Authenticate;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;
use Data::Dumper;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3:Auth::Authenticate

=cut

our $VERSION = '0.006';

=head1 DESCRIPTION

Authentication request

=head2 endpoint

=cut

has endpoint => (
    is       => 'ro',
    isa      => Str,
    default => '/auth/authenticate'
);

=head2 username

the actual api uses name so we handle this in json_args

=cut

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 password

=cut

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 token

=cut

sub token {
    my ($self)  = @_;
    $self->json_args;
    my $response = $self->request;
    my $content = from_json($response->{content});
    print STDERR Dumper($content);
    my $token = $content->{token};
    return $token;
}

1;
