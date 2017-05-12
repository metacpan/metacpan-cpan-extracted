use utf8;
package Etcd3::Auth::UserGrantRole;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use JSON;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3:::Auth::UserGrantRole

=cut

our $VERSION = '0.005';

=head1 DESCRIPTION

Add role to user

=head2 endpoint

=cut

has endpoint => (
    is       => 'ro',
    isa      => Str,
    default => '/auth/user/grant'
);

=head2 user

name of role

=cut

has user => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


=head2 role

name of role

=cut

has role => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


=head2 json_args

arguments that will be sent to the api

=cut

has json_args => (
    is => 'lazy',
);

sub _build_json_args {
    my ($self) = @_;
    my $args;
    for my $key ( keys %{ $self }) {
        unless ( $key =~  /(?:_client|json_args|endpoint)$/ ) {
            $args->{$key} = $self->{$key};
        }
    }
    return to_json($args);
}

=head2 init

=cut

sub init {
    my ($self)  = @_;
    my $init = $self->json_args;
    $init or return;
    return $self;
}

1;
