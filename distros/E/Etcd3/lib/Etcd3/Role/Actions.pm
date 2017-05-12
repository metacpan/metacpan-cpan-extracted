use utf8;
package Etcd3::Role::Actions;

use strict;
use warnings;

use Moo::Role;
use JSON;
use HTTP::Tiny;
use MIME::Base64;
use Types::Standard qw(InstanceOf);
use Data::Dumper;

use namespace::clean;

=encoding utf8

=head1 NAME

Etcd3::Role::Actions

=cut

our $VERSION = '0.005';

has _client => (
    is  => 'ro',
    isa => InstanceOf ['Etcd3::Client'],
);

=head2 headers

=cut

has headers => ( is => 'ro' );

=head2 request

=cut

has request => ( is => 'lazy', );

sub _build_request {
    my ($self) = @_;
    my $request = HTTP::Tiny->new->request(
    'POST',
        $self->_client->api_path
          . $self->{endpoint} => {
            content => $self->{json_args},
            headers => $self->headers
          },
    );
    return $request;
}

=head2 get_value

returns single decoded value or the first.

=cut

sub get_value {
    my ($self)   = @_;
    my $response = $self->request;
    my $content  = from_json( $response->{content} );
#    print STDERR Dumper($content);
    my $value = $content->{kvs}->[0]->{value};
    $value or return;
    return decode_base64($value);
}

=head2 all

returns list containing for example:

  {
    'mod_revision' => '3',
    'version' => '1',
    'value' => 'bar',
    'create_revision' => '3',
    'key' => 'foo0'
  }

where key and value have been decoded for your pleasure.

=cut

sub all {
    my ($self)   = @_;
    my $response = $self->request;
    my $content  = from_json( $response->{content} );
    my $kvs      = $content->{kvs};
    for my $row (@$kvs) {
        $row->{value} = decode_base64( $row->{value} );
        $row->{key}   = decode_base64( $row->{key} );
    }
    return $kvs;
}

=head2 authenticate

returns an Etcd3::Auth::Authenticate object

=cut

sub authenticate {
    my ( $self, $options ) = @_;
    return Etcd3::Auth::Authenticate->new(
        _client => $self,
        ( $options ? %$options : () ),
    )->init;
}

1;

