package Test::Hessian::Service ;


use strict;
use warnings;

use parent qw(Test::Class);

use Test::More;
use Test::Deep ();
use Test::Exception;
use Module::Build;

__PACKAGE__->SKIP_CLASS(1);


sub prep01_network_check :Test(startup) {
    my $self = shift;
    my $current = Module::Build->current();
    $self->SKIP_ALL("No network connection available."
        ." No point in continuing.") unless $current->notes("network_available");
}


1;

__END__


