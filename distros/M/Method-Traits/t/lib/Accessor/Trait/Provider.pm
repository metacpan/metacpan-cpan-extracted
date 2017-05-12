package # hide from PAUSE ...
    Accessor::Trait::Provider;
use strict;
use warnings;

use Method::Traits ':for_providers';

sub Accessor : OverwritesMethod {
    my ($meta, $method, $type, $slot_name) = @_;

    my $method_name = $method->name;

    $meta->add_method( $method_name => sub {
        die 'ro accessor' if $_[1];
        $_[0]->{$slot_name};
    })
        if $type eq 'ro';

    $meta->add_method( $method_name => sub {
        $_[0]->{$slot_name} = $_[1] if $_[1];
        $_[0]->{$slot_name};
    })
        if $type eq 'rw';
}

1;

