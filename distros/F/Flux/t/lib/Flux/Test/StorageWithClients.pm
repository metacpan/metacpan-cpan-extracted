package Flux::Test::StorageWithClients;

# ABSTRACT: Test::Class-based collection of tests for storages with clients

use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;
use Params::Validate qw(:all);

sub new {
    my $class = shift;
    my ($storage_gen) = validate_pos(@_, { type => CODEREF });
    my $self = $class->SUPER::new;
    $self->{storage_gen} = $storage_gen;
    return $self;
}

sub setup :Test(setup) {
    my $self = shift;
    $self->{storage} = $self->{storage_gen}->();
}

sub teardown :Test(teardown) {
    my $self = shift;
    delete $self->{storage};
}

sub inital_client_names :Test(1) {
    my $self = shift;
    is_deeply(
        [$self->{storage}->client_names()],
        [],
        'client_names initally returns empty list',
    );
}

sub register_unregister :Test(1) {
    my $self = shift;
    my $storage = $self->{storage};
    $storage->register_client('aaa');
    $storage->register_client('bbb');
    $storage->register_client('bbb'); # registering one client twice!
    $storage->register_client('ccc');
    $storage->register_client('ddd');
    $storage->unregister_client('ddd');
    $storage->register_client('ddd'); # re-register client after unregistering
    $storage->unregister_client('ccc');
    is_deeply(
        [sort $storage->client_names],
        [qw/ aaa bbb ddd /],
        'storage_names after several register/unregister calls'
    );
}

1;
