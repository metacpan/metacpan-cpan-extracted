package Gnuplot::Builder::Lens;
use strict;
use warnings;
use parent qw(Data::Focus::Lens);
use Data::Focus::LensMaker qw(make_lens_from_accessors);

sub new {
    my ($class, $getter_method_name, $setter_method_name, $key) = @_;
    return bless {
        getter => $getter_method_name,
        setter => $setter_method_name,
        key => $key,
    }, $class;
}

sub _getter {
    my ($self, $target) = @_;
    my $getter = $self->{getter};
    return scalar($target->$getter($self->{key}));
}

sub _setter {
    my ($self, $target, $part) = @_;
    my $setter = $self->{setter};
    return $target->$setter($self->{key} => $part);
}

make_lens_from_accessors(\&_getter, \&_setter);

1;
