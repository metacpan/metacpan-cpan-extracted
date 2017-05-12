package Flux::Storage::Memory;
{
  $Flux::Storage::Memory::VERSION = '1.03';
}

# ABSTRACT: in-memory storage with support for named clients

use Moo;
with
    'Flux::Out::Role::Easy',
    'Flux::Storage',
    'Flux::Storage::Role::ClientList';

use Carp;
use Flux::Storage::Memory::In;
use List::Util qw(sum);

has 'data' => (
    is => 'ro',
    default => sub { [] },
);

has 'client_pos' => (
    is => 'ro',
    default => sub { {} },
);

has 'client_lock' => (
    is => 'ro',
    default => sub { {} },
);

sub write {
    my $self = shift;
    my ($item) = @_;

    push @{ $self->data }, $item;
}

sub _read {
    my $self = shift;
    my ($pos) = @_;

    return $self->data->[$pos];
}

sub _lag {
    my $self = shift;
    my ($pos) = @_;

    return sum(map { length } @{$self->data}[ $pos .. @{$self->data} - 1 ]) || 0;
}

sub _lock_client {
    my $self = shift;
    my ($client) = @_;

    my $lock = $self->client_lock->{$client};
    if ($lock) {
        # already locked
        return 0;
    }
    $self->client_lock->{$client} = 1;
    return 1;
}

sub _unlock_client {
    my $self = shift;
    my ($client) = @_;

    $self->client_lock->{$client} = 0;
}

sub _get_client_pos {
    my $self = shift;
    my ($client) = @_;

    return $self->client_pos->{$client} || 0;
}

sub _set_client_pos {
    my $self = shift;
    my ($client, $pos) = @_;

    $self->client_pos->{$client} = $pos;
}

sub client_names {
    my $self = shift;
    return keys %{ $self->client_pos };
}

sub register_client {
    my $self = shift;
    my ($name) = @_;

    $self->client_pos->{$name} = 0;
}

sub unregister_client {
    my $self = shift;
    my ($name) = @_;

    delete $self->client_pos->{$name};
    delete $self->client_lock->{$name};
}

sub in {
    my $self = shift;
    my ($client) = @_;

    unless ($self->_lock_client($client)) {
        croak "Constructing two clients with same name '$client' for one MemoryStorage - not implemented yet";
    }
    return Flux::Storage::Memory::In->new({
        storage => $self,
        client => $client,
    });
}

1;

__END__

=pod

=head1 NAME

Flux::Storage::Memory - in-memory storage with support for named clients

=head1 VERSION

version 1.03

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
