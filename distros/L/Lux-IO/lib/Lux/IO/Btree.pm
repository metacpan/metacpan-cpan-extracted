package Lux::IO::Btree;
use 5.008001;
use strict;
use warnings;
use Lux::IO;

sub new {
    my ($class, $index_type) = @_;
    btree_new(defined $index_type ? $index_type : Lux::IO::CLUSTER);
}

sub DESTROY {
    my $self = shift;
    btree_free($self);
}

sub open {
    my ($self, $filename, $oflags) = @_;
    btree_open($self, $filename, $oflags || Lux::IO::DB_CREAT);
}

sub close {
    my ($self, $filename, $oflags) = @_;
    btree_close($self);
}

sub get {
    my ($self, $key) = @_;
    btree_get($self, $key);
}

sub put {
    my ($self, $key, $value, $insert_mode) = @_;
    btree_put($self, $key, $value, length $value, $insert_mode || Lux::IO::OVERWRITE);
}

sub del {
    my ($self, $key) = @_;
    btree_del($self, $key);
}

1;
