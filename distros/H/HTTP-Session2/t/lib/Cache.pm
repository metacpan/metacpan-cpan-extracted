package Cache;
use strict;
use warnings;
use utf8;

our %STORE;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub get {
    my ($self, $key) = @_;
    $STORE{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $STORE{$key} = $value;
}

sub remove {
    my ($self, $key) = @_;
    delete $STORE{$key};
}

1;

