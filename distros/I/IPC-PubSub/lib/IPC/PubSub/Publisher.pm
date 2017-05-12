package IPC::PubSub::Publisher;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/expiry/);
__PACKAGE__->mk_ro_accessors(qw/_indice uuid _cache/);

sub new {
    my $class   = shift;
    my $cache   = shift;

    require Data::UUID;

    my $uuid    = Data::UUID->new->create_b64;
    my $self    = bless({
        expiry  => 0,
        _cache  => $cache,
        _indice => { map { $_ => 1 } @_ },
        uuid    => $uuid,
    });
    $cache->add_publisher($_, $uuid) for @_;
    return $self;
}

sub channels {
    my $self = shift;
    wantarray
        ? keys(%{$self->_indice})
        : $self->_indice;
}

sub publish {
    my $self = shift;
    $self->_indice->{$_} ||= do {
        $self->_cache->add_publisher($_, $self->uuid);
        1;
    } for @_;
}

sub unpublish {
    my $self = shift;
    delete($self->_indice->{$_}) and $self->_cache->remove_publisher($_, $self->uuid) for @_;
}

sub msg {
    my $self    = shift;
    my $uuid    = $self->uuid;
    my $indice  = $self->_indice;
    my $expiry  = $self->expiry;
    foreach my $msg (@_) {
        while (my ($channel, $index) = each %$indice) {
            $self->_cache->put($channel, $uuid, $index, $msg, $expiry);
            $indice->{$channel} = $index+1;
        }
    }
}

no warnings 'redefine';
sub DESTROY {
    my $self = shift;
    return unless $self->_cache;
    $self->_cache->remove_publisher($_, $self->uuid) for $self->channels;
}

1;
