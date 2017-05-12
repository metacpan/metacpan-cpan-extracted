package Device::TLSPrinter::Mock;
use strict;
use Device::TLSPrinter  qw< FC_OK >;
use Test::More;


use vars qw< @out >;
my $class = __PACKAGE__;


sub init {
    pass("driver $class loaded");
}


sub read {
    return (length FC_OK, FC_OK)
}


sub write {
    my ($self, %args) = @_;
    push @out, $args{data};
    return length $args{data}
}


sub connected {
    return 1
}


1;
