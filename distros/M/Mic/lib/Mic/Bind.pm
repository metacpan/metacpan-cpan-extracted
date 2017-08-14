package Mic::Bind;
use strict;

sub import {
    my (undef, %binding) = @_;

    foreach my $class ( keys %binding ) {
        $Mic::Bound_implementation_of{$class} = $binding{$class};
    }
    strict->import();
}

1;

__END__

=head1 NAME

Mic::Bind

=head1 SYNOPSIS

    use Mic::Bind
        'Foo' => 'Foo::Fake', 
        'Bar' => 'Bar::Fake', 
    ;
    use Foo;
    use Bar;

=head1 DESCRIPTION

The implementation of a class can be easily changed from user code e.g. after the above code runs, 
Foo and bar will be bound to fake implementations (e.g. to aid with testing), instead of the implementations defined in
their respective modules.
