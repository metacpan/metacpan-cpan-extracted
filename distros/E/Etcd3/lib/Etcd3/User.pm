use utf8;
package Etcd3::User;

use strict;
use warnings;

use Moo;
use Carp;
use Etcd3::User::Role;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use Data::Dumper;

with 'Etcd3::Role::Actions';

use namespace::clean;

=head1 NAME

Etcd3::User

=cut

our $VERSION = '0.007';

=head1 DESCRIPTION

User class

=cut

=head1 ACCESSORS

=head2 endpoint

=cut

has endpoint => (
    is       => 'rwp',
    isa      => Str,
);

=head2 name

name of user

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 password

=cut

has password => (
    is       => 'ro',
    isa      => Str,
);

=head1 PUBLIC METHODS

=head2 add

$etcd->user({ name =>'foo' password => 'bar' })->add

=cut

sub add {
    my $self = shift;
    $self->{endpoint} = '/auth/user/add';
    confess 'password required for ' . __PACKAGE__ . '->add'
      unless $self->{password};
    $self->request;
    return $self;
}

=head2 delete

$etcd->user({ name =>'foo' })->delete

=cut

sub delete {
    my $self = shift;
    $self->{endpoint} = '/auth/user/delete';
    $self->request;
    return $self;
}

1;
