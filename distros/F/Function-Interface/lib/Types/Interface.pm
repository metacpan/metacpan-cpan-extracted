package Types::Interface;

use v5.14.0;
use warnings;

our $VERSION = "0.01";

use Type::Library -base,
    -declare => qw( ImplOf );

use Types::Standard -types;
use Function::Interface::Impl;

__PACKAGE__->add_type({
    name   => 'ImplOf',
    parent => ClassName | Object,
    constraint_generator => sub {
        my ($interface) = @_;
        return sub {
            my ($package) = @_;
            Function::Interface::Impl::impl_of($package, $interface);
        };
    },
});

__PACKAGE__->meta->make_immutable;

__END__
