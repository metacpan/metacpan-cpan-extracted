package IPC::PubSub::Subscriber;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/_pubs _cache/);

sub new {
    my $class = shift;
    my $cache = shift;
    my $pubs = { map { $_ => $cache->publisher_indices($_); } @_ };
    bless({ _cache => $cache, _pubs => $pubs });
}

sub channels {
    my $self = shift;
    wantarray
        ? keys(%{$self->_pubs})
        : $self->_pubs;
}

sub subscribe {
    my $self = shift;
    $self->_pubs->{$_} ||= $self->_cache->publisher_indices($_) for @_;
}

sub unsubscribe {
    my $self = shift;
    delete @{$self->_pubs}{@_};
}

sub get_all {
    my $self = shift;
    my $pubs = $self->_pubs;
    my $cache = $self->_cache;
    return {
        map {
            my $orig = $pubs->{$_};
            $pubs->{$_} = $cache->publisher_indices($_);
            $_ => [ grep { defined } $cache->get($_, $orig, $pubs->{$_})];
        } $self->channels
    };
}

sub get {
    my $self    = shift;
    my $pubs    = $self->_pubs;
    my $cache   = $self->_cache;
    my ($chan)  = @_ ? @_ : sort($self->channels) or return;

    my $orig = $pubs->{$chan};
    $pubs->{$chan} = $cache->publisher_indices($chan);
    wantarray
        ? map {$_ ? $_->[1] : ()} $cache->get($chan, $orig, $pubs->{$chan})
        : [map {$_ ? $_->[1] : ()} $cache->get($chan, $orig, $pubs->{$chan})];
}

1;
