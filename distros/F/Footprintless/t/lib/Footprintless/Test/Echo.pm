use strict;
use warnings;

package Footprintless::Test::Echo;

use Footprintless::Util qw(
    dumper
);

sub new {
    return bless( {}, shift )->_init(@_);
}

sub echo {
    my ( $self, $key ) = @_;
    return $self->{spec}{$key};
}

sub _init {
    my ( $self, $factory, $coordinate ) = @_;

    $self->{spec} = $factory->entities()->get_entity($coordinate);

    return $self;
}

1;
