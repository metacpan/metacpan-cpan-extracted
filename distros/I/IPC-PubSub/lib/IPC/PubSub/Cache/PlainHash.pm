package IPC::PubSub::Cache::PlainHash;
use strict;
use warnings;
use base 'IPC::PubSub::Cache';

my %cache;

use constant new => __PACKAGE__;

sub fetch {
    my $self = shift;
    @cache{@_};
}

sub store {
    my ($self, $key, $val, $time, $expiry) = @_;
    $cache{$key} = [$time => $val];
}

sub publisher_indices {
    my ( $self, $chan ) = @_;
    +{ %{ $cache{$chan} || {} } };
}

sub add_publisher {
    my ($self, $chan, $pub) = @_;
    $cache{$chan}{$pub} = 0;
}

sub remove_publisher {
    my ($self, $chan, $pub) = @_;
    delete $cache{$chan}{$pub};
}

sub get_index {
    my ($self, $chan, $pub) = @_;
    $cache{$chan}{$pub};
}

sub set_index {
    my ($self, $chan, $pub, $idx) = @_;
    $cache{$chan}{$pub} = $idx;
}

1;
