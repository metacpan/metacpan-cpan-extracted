package Javonet::Sdk::Core::TypesHandler;
use strict;
use warnings FATAL => 'all';
use Exporter qw(import);
our @EXPORT = qw(is_primitive_or_none);

sub is_primitive_or_none {
    my ($self, $item) = @_;
    return (!defined $item || $item =~ /^(?:-?\d+(?:\.\d+)?|true|false)$/ || !ref $item);
}


1;
