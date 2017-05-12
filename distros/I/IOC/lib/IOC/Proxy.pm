
package IOC::Proxy;

use strict;
use warnings;

our $VERSION = '0.07';

use Scalar::Util qw(blessed);

use IOC::Exceptions;

sub new {
    my ($_class, $config) = @_;
    my $class = ref($_class) || $_class;
    my $proxy_server = {};
    bless($proxy_server, $class);
    $proxy_server->_init($config);
    return $proxy_server;
}

sub _init {
    my ($self, $config) = @_;
    $self->{config} = $config;
}

sub wrap {
    my ($self, $obj) = @_;
    (blessed($obj)) 
        || throw IOC::InsufficientArguments "You can only wrap other objects";
    my $obj_class = $self->_getObjectClass($obj);

    my $methods = {};
    $self->_collectAllMethods($obj_class, $methods);
    (keys %{$methods}) || throw IOC::OperationFailed "No methods could be found in '$obj_class'";

    my $proxy_package = $self->_createProxyPackageName($obj_class);

    eval $self->_createPackageString($obj_class, $proxy_package);
    throw IOC::OperationFailed "Could not create proxy package '$proxy_package' for object '$obj'" => $@ if $@;

    $self->_installMethods($obj_class, $proxy_package, $methods);
    
    $self->onWrap($obj, $proxy_package);
    bless $obj, $proxy_package;
}

sub onMethodCall {
    my ($self, $method_name, $method_full_name, $current_args) = @_;
    if (exists ${$self->{config}}{on_method_call}) {
        $self->{config}->{on_method_call}->($self, $method_name, $method_full_name, $current_args);
    }
}

sub onWrap {
    my ($self, $object, $proxy_package) = @_;
    if (exists ${$self->{config}}{on_wrap}) {
        $self->{config}->{on_wrap}->($self, $object, $proxy_package);
    }    
}

# PRIVATE METHODS

sub _collectAllMethods {
    my ($self, $obj_class, $methods, $cache) = @_;
    $cache ||= {};
    return if exists ${$cache}{$obj_class};
    $cache->{$obj_class}++;
    
    no strict 'refs';
    do { 
        $methods->{$_} = { 
            full_name => "${obj_class}::$_", 
            code => \&{"${obj_class}::$_"}  
        } unless exists ${$methods}{$_}
    } foreach 
        grep { defined &{"${obj_class}::$_"} } 
            keys %{"${obj_class}::"};
    
    $self->_collectAllMethods($_, $methods, $cache) foreach @{"${obj_class}::ISA"};
}

sub _createPackageString {
    my ($self, $obj_class, $proxy_package) = @_;
    my $overload = "";
    unless ($obj_class->can('(""')) {
        $overload = q|use overload '""' => sub {
                        my $real = overload::StrVal($_[0]);
                        $real =~ s/\:\:\_\:\:Proxy//;
                        return $real;
                    }, fallback => 1|;
    }
    return qq|
        package $proxy_package; 
        our \@ISA = ('$obj_class');
        $overload;
    |;
}

sub _installMethods {
    my ($self, $obj_class, $proxy_package, $methods) = @_;    
    no strict 'refs';
    while (my ($method_name, $method) = each %{$methods}) {
        next if defined &{"${proxy_package}::$method_name"};
        next if $method_name eq '()'; # this is the overloaded indicator, we shouldn't proxy this
        if ($method_name eq 'AUTOLOAD') {
            *{"${proxy_package}::$method_name"} = sub { 
                            my $a = our $AUTOLOAD;
                            # we cannot call this here as it will create a new
                            # reference to the object (in the \@_) and that will
                            # defeat the use of DESTORY, so we just ignore this
                            # if we get called by destroy
                            if ($a =~ /DESTROY/) {
                                $self->onMethodCall($method_name, $method->{full_name}, []);                            
                            }
                            else {
                                $self->onMethodCall($method_name, $method->{full_name}, [ @_ ]);
                            }
                            $a =~ s/\:\:\_\:\:Proxy//;
                            ${"${obj_class}::AUTOLOAD"} = $a;
                            goto &{$method->{code}};
                        };        
        }
        elsif ($method_name eq 'DESTROY') {
            *{"${proxy_package}::$method_name"} = sub { 
                            # we cannot call onMethodCall this here as it will create a new
                            # reference to the object (in the \@_) and that will
                            # defeat the use of DESTORY, so we just ignore this
                            # if we get called by destroy
                            $self->onMethodCall($method_name, $method->{full_name}, []);                            
                            goto &{$method->{code}};
                        };        
        }        
        else {
            *{"${proxy_package}::$method_name"} = sub { 
                            $self->onMethodCall($method_name, $method->{full_name}, [ @_ ]);
                            goto &{$method->{code}};
                        };
        }
    }
}

sub _createProxyPackageName {
    my ($self, $obj_class) = @_;
    return "${obj_class}::_::Proxy"
}

sub _getObjectClass {
    my ($self, $obj) = @_;
    return ref($obj);
}

1;

__END__

=head1 NAME

IOC::Proxy - Proxy for the IOC Framework

=head1 SYNOPSIS

  use IOC::Proxy;
  
  my $proxy_server = IOC::Proxy->new({
                        on_method_call => sub {
                        my ($proxy_server, $method_name, $method_full_name, $current_method_args) = @_;
                        warn ("Method '$method_name' called with args (" . 
                              (join ", " => @{$current_method_args}) .
                              "), now passing call to '$method_full_name'");
                        }
                    });
  
  $proxy_server->wrap($object);
  # this now wraps the $object in a special proxy package
  # which will intercept all it's calls, while still
  # behaving exactly as if it was not proxied
  
  $object->method();
  # this will warn:
  #    Method 'method' called with args (Class::_::Proxy=HASH(0x859978)), now passing call to 'Class::method'

=head1 DESCRIPTION

This module is a base class for all your IOC::Proxy needs. It can be used on it's own or it can be subclassed. 

The basic idea of the IOC::Proxy is that since we are using the IOC framework to create our object instances, we can do certain things to those instances which we would not easily be able to do otherwise. In this specific case we can wrap the service instance with an IOC::Proxy object and be able to capture calls to the service instance through our proxy. The simplest use for this is some kind of logging. 

The IOC::Proxy object does everything within it's power to make sure that the proxy object can be used as a drop in replacement to the service instance. This means we do not impose our OO-style on you class nor do we mess with your class's symbol table, and we are as transparent as possible. 

=head2 IOC::Proxy guts

All this is accomplished by the creation of a proxy package, which is just you package name followed by C<::_::Proxy>, which inherits from your object's class. We then gather up all the methods of your class by performaing a depth-first search of the inheritance tree (just as perl would do) and we then install these methods into our proxy package. We also check to see if your class has overloaded the stringification operator (C<"">) and if not, we install our own which will remove all trace of the C<::_::Proxy> package from the output, so when you stringify your object it will not show the proxy (unless you use C<overload::StrVal>).

Once our proxied package is all set up, we re-bless your object into the proxy package. One of the benefits of this is that we do not need to worry about the underlying reference type your class is implemented with, and all data storage in your instance is preserved without issue.

All this means that your proxied object will respond as expected to calls to C<isa> and C<can> (including C<UNIVERSAL::isa> and C<UNIVERSAL::can>), and since we use C<goto> all evidence of IOC::Proxy is removed from the output of C<caller> as well. It also respects C<AUTOLOAD>, C<DESTROY> and L<overload>ed operations. And when your object is automatically stringified, it will not show the proxy either. There is only one place where IOC::Proxy will reveal itself, and that is with C<ref>. Short of overloading C<CORE::GLOBAL::ref> this could not be done. 

=head1 METHODS

=over 4

=item B<new ($config)>

This will construct a IOC::Proxy object, but do nothing with it. The C<$config> option is an HASH ref, which can be used to store data with your proxied object since it will not actually be an instance of IOC::Proxy. The C<$config> hash can have anything in it you want, but IOC::Proxy will look for two specific keys; I<on_method_call> and I<on_wrap> which should contain subroutine references and which will get called within C<onMethodCall> and C<onWrap> respectively. 

=item B<wrap ($object)>

This will wrap the C<$object> given to it in a proxy package as described in the L<IOC::Proxy guts> section above. The return value of this method is the proxied object. Theoretically since we actually will re-bless C<$object> you don't actually need to capture that return value since the changes should affect C<$object> as well.

=item B<onWrap ($unwrapped_object, $proxy_package)>

This method is here mostly for subclasses of IOC::Proxy. It will be called when IOC::Proxy wraps an instance. Currently it will look for the value I<on_wrap> in the C<$config> passed to the constructor (see above for more details).

The first argument, C<$unwrapped_object> is the object to be proxied, the second argument C<$proxy_package> is the name of the package it will be proxied with. It is up to you what to do with them.

=item B<onMethodCall ($method, $original_method, $args)>

This method is here mostly for subclasses of IOC::Proxy. It will be called when IOC::Proxy recieves a method call. Currently it will look for the value I<on_method_call> in the C<$config> passed to the constructor (see above for more details).

The first argument, C<$method> is the short (local) name of the method which has been called. The second argument C<$original_method> is the fully qualified name of the method which includes the package where it actually comes from (which in inheritance situations may not be the class of the original proxied object). The third argument C<$args> is a reference to the C<@_> array the method was called with.

=back

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

=item L<Class::Proxy>

=item L<Class::Proxy::Lite>

=item L<Class::Wrap>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
