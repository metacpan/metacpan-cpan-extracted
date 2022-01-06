package Local::FalseThing;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use overload (
    q("")    => '_stringify',
    bool     => sub () { return 0 },
    fallback => 1,
);

sub new {
    my ( $class, $path ) = @_;

    return bless { _thing => $path }, $class;
}

sub _stringify {
    my ($self) = @_;

    return $self->{_thing};
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
