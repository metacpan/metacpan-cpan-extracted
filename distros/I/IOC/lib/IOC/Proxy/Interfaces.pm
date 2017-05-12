
package IOC::Proxy::Interfaces;

use strict;
use warnings;

our $VERSION = '0.02';

use base 'IOC::Proxy';

use IOC::Exceptions;

sub _init {
    my ($self, $config) = @_;
    (exists ${$config}{interface}) 
        || throw IOC::InsufficientArguments "You must specify an interface in the configuration";
    $self->SUPER::_init($config);
}

# PRIVATE METHODS

sub _createPackageString {
    my ($self, $obj_class, $proxy_package) = @_;
	my $package_string = $self->SUPER::_createPackageString($obj_class, $proxy_package);
    my $interface = $self->{config}->{interface};
    $package_string =~ s/\@ISA \= \('$obj_class'\)/\@ISA \= \('$obj_class'\, '$interface'\)/;
	return $package_string;
}

sub _installMethods {
    my ($self, $obj_class, $proxy_package, $methods) = @_;    
    
    my $interface = $self->{config}->{interface};
    my $interface_methods = {};
    $self->_collectAllMethods($interface, $interface_methods);
    (keys %{$interface_methods}) || throw IOC::OperationFailed "No methods could be found in '$interface'";
        
    (exists ${$methods}{$_})
        || throw IOC::IllegalOperation "The class '$obj_class' does not conform to the interface '$interface'"				 		foreach keys %{$interface_methods};
        
    no strict 'refs';
    while (my ($method_name, $method) = each %{$methods}) {     
        if (exists ${$interface_methods}{$method_name}) {
            *{"${proxy_package}::$method_name"} = sub { 
                            $self->onMethodCall($method_name, $method->{full_name}, [ @_ ]);
                            goto &{$method->{code}};
                        };
        }
        else {
            *{"${proxy_package}::$method_name"} = sub { throw IOC::MethodNotFound };            
        }
    }
}

1;

__END__

=head1 NAME

IOC::Proxy::Interfaces - A IOC::Proxy subclasss to proxy objects with a given interface

=head1 SYNOPSIS

  use IOC::Proxy::Interfaces;
  
  my $proxy_server = IOC::Proxy->new({
                        interface => 'AnInterface',
                        # ... add other config values here
                    });
  
  $proxy_server->wrap($object);
  # our $object is now proxied, but only the 
  # methods which are part of the interface 
  # will work, all others will throw exceptions
  
  $object->method_in_interface(); # works as normal
  
  $object->method_not_in_interface(); # will thrown an exception

=head1 DESCRIPTION

This is a subclass of IOC::Proxy which allows for the partial proxing of an object. It will only proxy the methods of a given interface, all other methods will throw a IOC::MethodNotFound exception. This could be used to (in a very weird way) emulate the concept of upcasting in Java, it is also somewhat like the idea of using interfaces with Dynamic Proxies in Java as well (see the article link in L<SEE ALSO>). 

This proxy can be useful if you need to have an object strictly conform to a particular interface in a particular situation. The interface class is also pushed onto the proxies C<@ISA> so that it will respond to C<UNIVERSAL::isa($object, 'Interface')> correctly. Keep in mind that there is no need for the object being proxied to have the interface in it's C<@ISA> prior to being proxied. The proxy is dynamic and only requires that the object conform to the interface when it is being C<wrap>ed but the proxy object.

=head1 METHODS

The only change to the IOC::Proxy API is to require an 'interface' key in the C<$config> hash given to the object constructor. If that key is not present an IOC::InsufficientArguments exception will be thrown.

It should be noted that this module's definition of an interface is really just a package. There are no restrictions on it past that. So in fact it is possible for an interface to be a regular class with implemented methods and all, this proxy will just make sure your proxied object implements all the same methods and proxy them. 

=head1 TO DO

=over 4

=item Work on the documentation

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the CODE COVERAGE section of L<IOC> for more information.

=head1 SEE ALSO

=over 4

=item Dynamic Proxy API in Java

This package is not really an implementation of this concept, but concepts found in this article served as inspiration for this package. It's an interesting read if nothing more.

L<http://www.javaworld.com/javaworld/jw-11-2000/jw-1110-proxy.html>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
