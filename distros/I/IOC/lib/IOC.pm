
package IOC;

use strict;
use warnings;

our $VERSION = '0.29';

use IOC::Exceptions;

use IOC::Container;
use IOC::Service;
use IOC::Service::Literal;
use IOC::Registry;
use IOC::Proxy;

1;

__END__

=head1 NAME

IOC - A lightweight IOC (Inversion of Control) framework

=head1 SYNOPSIS

  use IOC;
  
  my $container = IOC::Container->new();
  $container->register(IOC::Service::Literal->new('log_file' => "logfile.log"));
  $container->register(IOC::Service->new('logger' => sub { 
      my $c = shift; 
      return FileLogger->new($c->get('log_file'));
  }));
  $container->register(IOC::Service->new('application' => sub {
      my $c = shift; 
      my $app = Application->new();
      $app->logger($c->get('logger'));
      return $app;
  }));

  $container->get('application')->run();   

=head1 DESCRIPTION

This module provide a lightweight IOC or Inversion of Control framework. 
Inversion of Control, sometimes called Dependency Injection, is a component 
management style which aims to clean up component configuration and provide 
a cleaner, more flexible means of configuring a large application.

=head2 What is Inversion of Control

My favorite 10 second description of Inversion of Control is, "Inversion 
of Control is the inverse of Garbage Collection". This comes from Howard 
Lewis Ship, the creator of the HiveMind IoC Java framework. His point is 
that the way garbage collection takes care of the destruction of your 
objects, Inversion of Control takes care of the creation of your objects. 
However, this does not really explain why IoC is useful, for that you will 
have to read on.

You may be familiar with a similar style of component management called a 
Service Locator, in which a global Service Locator object holds instances 
of components which can be retrieved by key. The common style is to create 
and configure each component instance and add it into the Service Locator. 
The main drawback to this approach is the aligning of the dependencies of 
each component prior to inserting the component into the Service Locator. 
If your dependency requirements change, then your initialization code must 
change to accommodate. This can get quite complex when you need to re-arrange 
initialization ordering and such. The Inversion of Control style alleviates 
this problem by taking a different approach.

With Inversion of Control, you configure a set of individual Service objects, 
which know how to initialize their particular components. If these components 
have dependencies, the will resolve them through the IOC framework itself. 
This results in a loosely coupled configuration which places no expectation 
upon initialization order. If your dependency requirements change, you need 
only adjust your Service's initialization routine, the ordering will adapt 
on it's own.

For links to how other people have explained Inversion of Control, see the 
L<SEE ALSO> section.

=head2 Why Do I Need This?

Inversion of Control is not for everyone and really is most useful in larger 
applications. But if you are still wondering if this is for you, then here 
are a few questions you can ask yourself.

=over 4

=item Do you have more than a few Singletons in your code? 

If so, you are a likely candidate for IOC. Singletons can be very useful tools, 
but when they are overused, they quickly start to take on all the same problems 
of global variables that they were meant to solve. With the IOC framework, you 
can reduce several singletons down to one, the IOC::Registry singleton, and 
allow for more fine grained control over their life-cycles.

=item Is your initialization code overly complex?

One of the great parts about IOC is that all initialization of dependencies 
will get resolved through the IOC framework itself. This allows your application 
to dynamically reconfigure it load order without you having to recode anything 
but the actual dependency change. 

=item Are you using some kind of Service Locator?

My whole reasoning for creating this module was that I was using a Service 
Locator object from which I dispensed all my components. This created a lot 
of delicate initialization code which would frequently be caused issues, and 
since the Service Locator was initialized I<after> all the services were, it 
was necessary to resolve dependencies between components manually. 

=back

=head2 Inversion of Control in detail

The authors of the PicoContainer IoC framework defined 3 types of Dependency 
Injection; Constructor Injection, Setter Injection and Interface Injection. 
This framework provides the the ability to do all three types within the 
default classes using a pseudo-type, which I call Block Injection (for lack 
of a better term). This framework allows a service to be defined by an 
anonymous subroutine, which gives a large degree of flexibility. However, 
we also directly support both constructor injection and setter injection 
as well. Interface injection support is on the to-do list, but I feel 
that interface injection is better suited to more 'type-strict' languages 
like Java or C# and is really not appropriate to perl. 

There are a number of benefits and drawbacks to each approach, I will now 
attempt to list them.

=over 4

=item B<Constructor Injection>

Constructor injection tends to encourages what are called Good Citizen Objects, 
which are objects who are fully initialized once they are constructed. It is 
also easy to analyze dependency relationships since the components are stored 
in the constructor parameters.

One drawback to this approach is that it requires the component to be a class, 
as well as requires the class to be a Good Citizen. Which is okay if you are 
writing the class, but maybe not when it is a 3rd party class.

=item B<Setter Injection>

Setter injection has its benefits as well. Since all object initialization is 
done through setter methods, it allows for a cleaner object design when there 
are a lot of dependencies. Where in a constructor injection, it would cause 
an explosion of parameters in the constructor. Setter injection dependencies 
can also be easily analyzed programmatically, since the dependencies are stored 
in the setter parameters.

However, as with constructor injection, some of the the benefits can also be 
drawbacks. Sometimes having public setters for initialization is not what 
you would want normally in your class.

=item B<IOC-style Block Injection>

This style is, in my opinion the most perl-ish approach. It is also, arguably, 
the simplest approach since it requires very little on the part of the 
component class, and easily allows for non-object services. It can be used 
to mix both constructor and setter injection in the same service object.

One major drawback is that since the initialization is "hidden" within the 
anonymous subroutine, it is very difficult to programatically analyze the 
dependency relationships.

To give credit where credit is due, this style is not my own invention, but 
instead was derived from an IoC Ruby implementation in the article mentioned 
in the L<SEE ALSO> section.

=back

=head2 Is this module ready to use?

Yes, I have been using this actively in production for a couple years now, 
and it has worked without issue.

=head1 CLASSES

This section will provide a short description of each of the classes in the 
framework and how they fit within the framework. For more information about 
each class, please go to the individual classes documentation.

=over 4

=item L<IOC>

This package mostly serves as a namespace placeholder and to load the base 
framework. This will load IOC::Registry, IOC::Container and IOC::Service.

=item L<IOC::Registry>

This is a singleton registry which can be used to store and search 
IOC::Container objects/hierarchies.

=item L<IOC::Proxy>

This package can be used alone or as a base class and be used to proxy 
service instances. 

=item L<IOC::Proxy::Interfaces>

This IOC::Proxy subclass which proxies an object, but only implements a 
specified interface.

=back

=head2 Configuration Classes

=over

=item L<IOC::Config::XML>

This module allows you to configure an IOC::Registry object using XML.

=back

=head2 Container Classes

Containers classes can hold references to both IOC::Service objects as well 
as other IOC::Containers. Containers are central to the framework as they 
provide the means of managing, storing and retrieving IOC::Service objects. 

=over 4

=item L<IOC::Container>

This is the base Container object. In most cases, this class will be all 
you need.

=item L<IOC::Container::MethodResolution>

This is a subclass of IOC::Container, and adds the ability to retrieve 
services and sub-containers with a method call syntax, instead of passing 
a string key to a retrieval method. 

=back

=head2 Service Classes

Service classes are the even more central to the framework since they are 
what hold and dispense the dependency objects. There are a number of types 
of service class, all of which are derived at some point from the base 
IOC::Service class.

=over 4

=item L<IOC::Service>

This is the base Service object. In most cases, this class will be all you need.

=item L<IOC::Service::ConstructorInjection>

This extends the IOC::Service object to allow for a constructor injection style.

=item L<IOC::Service::SetterInjection>

This extends the IOC::Service object to allow for a setter injection style.

=item L<IOC::Service::Parameterized>

This extends the IOC::Service object to allow for additional parameters to 
be passed during service creation. Since there is an unbound parameter, these
services will work like the prototyped services and return a new instance each 
time.

=back

=head2 Prototyped Services

Most services are singletons, meaning there is only one instance of each 
service in the system. However, sometimes this is not what you would want, 
and sometimes you want to set up a prototypical instance of a component 
and get a new instance each time. This set of Service classes provide 
just such functionality. 

NOTE: This is not really the same as prototype-based OO programming, we do 
not actually create a prototypical instance, but instead we just call the 
creation routine each time the component is requested.

=over 4

=item L<IOC::Service::Prototype>

A basic prototype-style Service class.

=item L<IOC::Service::Prototype::ConstructorInjection>

This extends the IOC::Service::Prototype object to allow for a constructor 
injection style.

=item L<IOC::Service::Prototype::SetterInjection>

This extends the IOC::Service::Prototype object to allow for a setter 
injection style.

=back

=head2 Visitor Classes

IOC::Visitor classes are used by other classes in the system to perform 
various search and traversal functions over a IOC::Container hierarchy. 
They are mostly for internal use.

=over 4

=item L<IOC::Visitor::ServiceLocator>

Given a path, this will attempt to locate a service within a IOC::Container 
hierarchy.

=item L<IOC::Visitor::SearchForService>

Given a service name, this will attempt to locate a service within a 
IOC::Container hierarchy by doing a depth first pre-order search.

=item L<IOC::Visitor::SearchForContainer>

Given a container name, this will attempt to locate a service within 
a IOC::Container hierarchy by doing a depth first pre-order search.

=back

=head2 Utility Classes

These classes are really just support classes for the framework.

=over 4

=item L<IOC::Exceptions>

Defines a number of exceptions (with Class::Throwable) used in the system.

=item L<IOC::Interfaces>

Defines a number of interfaces (with Class::Interfaces) used in the system.

=back

=head1 CAVEATS

=over 4

=item Cyclical and Graph Dependencies

Cyclical dependencies now work correctly (for the most part, there are still 
ways to produce infinite recursion, but most of them could be considered 
I<programmer error>) but should still be considered an experimental feature. 
This will need to be documented in more detail to explain the gotchas and 
edge cases. 

Currently proxys and cyclical dependencies are not working together. In order 
to resolve the cyclical dependency issue I need to create a 
IOC::Service::Deferred instance to defer the service creation with. A proxy 
should not wrap the deferred instance, but should only wrap the final 
created instance. Currently this does not happen, so I need to work on it.

=back

=head1 TO DO   

=over 4

=item Work on the documentation

The docs are still very rough in many places and I will be filling in details 
as I go. Of course any suggestions or criticisms of the docs are very welcome 
and will be gladly received. Help writing them will also be gladly received 
as well.

=item Create some more integration tests

I have plenty of unit tests, and the code is pretty well covered (see 
L<CODE COVERAGE> below). However, what is lacking is some more complex 
integration tests to really test how all the modules work together. I 
expect a few such tests to come out my using the module in my projects, 
and I will include them when they do. 

And of course, I am I<always> open to contributions. If you are just 
experimenting with this module to see if it would work for you, chances 
are you will create some code which would be great as an integration 
test. Please before you throw it away, send it to me, I might be able 
to use it. 

=back

=head2 Wishlist

These are things which I have in the back of my head and would someday 
like to create, but just don't have the time right now.

=over 4

=item Dependency Analyzer

I would like to create some kind of Visitor object which would traverse 
a IOC::Container hierarchy and analyze the dependencies in it. This is 
somewhat simple for the ::ConstructorInjection and ::SetterInjection 
Services since they store the keys to their dependencies inside the 
object. However it is more complex with regular IOC::Service objects 
which utilize the Block Injection pseudo-type. For those the 
initialization block would need to probably be run through L<B::Deparse> 
and the dependency code parsed out.

=item Dependency Visualization

I hacked out a quick script which created a GraphViz .dot file which 
visualized the dependency tree. It left much to be desired, but it 
served as a proof of concept. I would like to expand that idea into 
a more useful and flexible tool. If anyone is interested in doing 
this one, contact me and I will send you the proof of concept script.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and 
I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is 
the B<Devel::Cover> report on this module test suite.

 --------------------------------------------- ------ ------ ------ ------ ------ ------ ------
 File                                            stmt branch   cond    sub    pod   time  total
 --------------------------------------------- ------ ------ ------ ------ ------ ------ ------
 IOC.pm                                         100.0    n/a    n/a  100.0    n/a    1.4  100.0
 IOC/Exceptions.pm                              100.0    n/a    n/a  100.0    n/a    7.6  100.0
 IOC/Interfaces.pm                              100.0    n/a    n/a  100.0    n/a    2.5  100.0
 IOC/Registry.pm                                100.0   97.6   66.7  100.0  100.0   12.3   97.4
 IOC/Config/XML.pm                              100.0  100.0   66.7  100.0  100.0    6.1   96.0
 IOC/Config/XML/SAX/Handler.pm                  100.0   92.0   70.0  100.0  100.0   16.7   94.2
 IOC/Proxy.pm                                   100.0   92.3   60.0  100.0  100.0    3.2   97.4
 IOC/Proxy/Interfaces.pm                        100.0  100.0    n/a  100.0    n/a    0.7  100.0
 IOC/Container.pm                               100.0   98.3   91.3  100.0  100.0   23.0   98.9
 IOC/Container/MethodResolution.pm              100.0  100.0    n/a  100.0    n/a    5.6  100.0
 IOC/Service.pm                                  89.4   78.6   66.7   88.5  100.0    7.0   85.7
 IOC/Service/Literal.pm                         100.0  100.0   33.3  100.0  100.0    0.7   96.2
 IOC/Service/Prototype.pm                       100.0  100.0    n/a  100.0  100.0    5.8  100.0
 IOC/Service/ConstructorInjection.pm            100.0  100.0   66.7  100.0  100.0    2.2   93.9
 IOC/Service/SetterInjection.pm                 100.0  100.0   66.7  100.0  100.0    1.5   94.3
 IOC/Service/Prototype/ConstructorInjection.pm  100.0    n/a    n/a  100.0    n/a    0.5  100.0
 IOC/Service/Prototype/SetterInjection.pm       100.0    n/a    n/a  100.0    n/a    0.3  100.0
 IOC/Visitor/SearchForContainer.pm              100.0  100.0   66.7  100.0  100.0    0.5   96.6
 IOC/Visitor/SearchForService.pm                100.0  100.0   66.7  100.0  100.0    0.6   96.8
 IOC/Visitor/ServiceLocator.pm                  100.0  100.0   66.7  100.0  100.0    1.8   97.3
 --------------------------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                                           99.1   94.8   70.3   98.7  100.0  100.0   95.9
 --------------------------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

Inversion of Control (or Dependency Injection) is one of the current 
I<hot> buzzwords in the Java/Design patterns/C# community right now. 
However, just because a lot of people are talking about it insufferably 
does not mean it is still not a good idea. Below some links I have 
collected regarding IoC which you might find useful.

=over 4

=item The code here was originally inspired by the code found in this article.

L<http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc>

=item Dependency Injection is the Inverse of Garbage Collection

L<http://howardlewisship.com/blog/2004/08/dependency-injection-mirror-of-garbage.html>

=item This is a decent article on IoC with Java.

L<http://today.java.net/pub/a//today/2004/02/10/ioc.html>

=item An article by Martin Fowler about IoC

L<http://martinfowler.com/articles/injection.html>

=item This is also sometimes called the Hollywood Principle

L<http://c2.com/cgi/wiki?HollywoodPrinciple>

=item An interesting comparison of differnet IoC frameworks

L<http://www.pyrasun.com/mike/mt/archives/2004/11/06/15.46.14/index.html>

=back

Here is a list of some Java IoC frameworks.

=over 4

=item B<HiveMind>

L<http://jakarta.apache.org/hivemind/>

=item B<Spring Framework>

L<http://www.springframework.org/>

Spring also has a .NET version as well.

=item B<PicoContainer>

L<http://www.picocontainer.org>

=item B<Avalon>

L<http://avalon.apache.org/products/runtime/index.html>

=back

Here is a list of Ruby IoC Frameworks

=over 4

=item Copland

L<http://copland.rubyforge.org/>

I have only skimmed this site, but it seems that Copland is inspired by HiveMind.

=item Needle

L<http://needle.rubyforge.org/>

I have only skimmed this site, but it seems that Needle is a lightweight version of Copland.

=item Rico 

L<http://www.picocontainer.org/Rico>

Rico is a Ruby port of the Java Pico Framework.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

