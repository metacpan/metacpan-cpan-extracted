# JOAP::Proxy::Package::Server -- Base Class for Proxies of JOAP Server
#
# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

# tag: JOAP server proxy base class

package JOAP::Proxy::Package::Server;
use JOAP;
use JOAP::Proxy::Package;
use JOAP::Proxy::Server;
use base qw/JOAP::Proxy::Package JOAP::Proxy::Server/;

use 5.008;
use strict;
use warnings;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;

JOAP::Proxy::Package::Server->mk_classdata('Address');
JOAP::Proxy::Package::Server->mk_classdata('Classes');
JOAP::Proxy::Package::Server->mk_classdata('ClassProxy');

JOAP::Proxy::Package::Server->Address('');
JOAP::Proxy::Package::Server->Classes([]);
JOAP::Proxy::Package::Server->ClassProxy({});

sub classes {
    my $self = shift;
    return $self->Classes(@_);
}

sub address {
    my $self = shift;
    return $self->Address(@_);
}

sub _describe {

    my $self = shift;
    my $resp = $self->SUPER::_describe(@_);

    # Need to get the classes, too.

    my @classes = $resp->GetQuery->GetClass;
    $self->Classes(\@classes);

    # XXX: update addresses for classes in classmap

    return $resp;
}

sub proxy_class {

    my $self = shift;
    my $class_address = shift;

    my $jid = new Net::Jabber::JID($class_address);

    if ($jid->GetServer ne $self->address) {
        return undef;
    }

    my $class_id = $jid->GetUserID;

    if (!$class_id) {
        return undef;
    }

    my $class = $self->ClassProxy->{$class_id};

    if (!$class) {
        return undef;
    }

    $class->Address($class_address);

    $class->refresh;

    return $class;
}

sub method {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name);
    my $method = $self->_proxy_method($desc);

    return $method;
}

sub accessor {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_attribute_descriptor($name);
    my $accessor = $self->_proxy_accessor($desc);

    return $accessor;
}

1;  # gotta return something true

__END__

=head1 NAME

JOAP::Proxy::Package::Server -- Base Class for Proxies of JOAP Server

=head1 SYNOPSIS

  # define the package

  package MyProxyServer;
  use JOAP::Proxy::Package::Server;
  use base qw(JOAP::Proxy::Package::Server);

  # define remote address

  MyProxyServer->Address('joap-server.example.net');

  # define local classes for classes on server

  MyProxyServer->ClassProxy({Person => MyProxy::Person,
                             Foo => MyProxy::Foo});

  1;

  package main;

  # Get a Jabber connection (you're responsible for this)

  my $con = get_net_jabber_connection_somehow();

  # Set it for all the proxies

  JOAP::Proxy->Connection($con);

  # initialize the server

  my $server = MyProxyServer->get;

  # read an attribute

  my $foo = $server->logLevel;

  # set an attribute

  $server->logLevel(14);

  # save changed values

  $server->save;

  # refresh attributes from the remote server

  $server->refresh;

  # determine which local class represents a remote class

  my $local = $server->proxy_class('Person@joap-server.example.net');

=head1 ABSTRACT

This module provides an abstract base class that can be used to create
JOAP object server classes. These classes store metadata about the
object server in the package, making things a little more efficient.

=head1 DESCRIPTION

The benefit of using a package to store object server metadata is
kinda moot, since there's going to be a small (preferably singleton)
number of instances anyways.

The main benefit is that the code generator, L<joappxgen>, can put the
metadata in the package for you, saving a round-trip to the server for
each program invocation. Note that setting up the metadata is a little
tricky and error prone; if you set it up by hand, make sure you get
B<all> the metadata, or you'll have weird errors. If in doubt, just
put in the C<Address> and C<ClassMap>.

Additionally, it lets you map local Perl modules to remote classes.

Note that you don't I<have> to use the remote object server if you
don't want to. You can just talk directly to its classes and
instances.

The Perl methods are very similar to those for other JOAP::Proxy
packages, but they are listed here for completeness.

As a usage note, you should set the C<Connection> class attribute
of the JOAP::Proxy class before using any of the methods in this
package (except maybe C<Address>). See L<JOAP::Proxy> for more
information.

=head2 Instance Methods

=over

=item refresh

Read the attributes of this remote object server and store them
locally in the instance. The attributes can then be queried
using the autoloaded accessors.

=item save

Save the local values of attributes to the remote instance. This will
only save writable attributes.

=item proxy_class($classaddress)

Return the local proxy class that proxies for the remote class at
address $classaddress. The class will also be initialized with its
class metadata and attribute values.

See L<JOAP::Addresses> for the acceptable values of a class address.

=back

=head2 Class Methods

Most of the class methods are concerned with setting and getting
metadata.

=over

=item Address()

=item Address($address)

The address of the remote object server this class is a proxy
for. This is the only introspection method application code should use
as a mutator. It's mostly useful when several object servers at
different locations use the same interface; you can say which one
you're interested in by changing the address.

See L<JOAP::Addresses> for the acceptable values of an object server
address.

=item Attributes

=item attributes

Returns a reference to a hashtable mapping attribute names to
attribute descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item Methods

=item methods

Returns a reference to a hashtable mapping method names to
method descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item Timestamp

=item timestamp

The date and time that the object server structure description was
downloaded from the remote class. It's in ISO 8601 format; see
L<JOAP::Types> for details.

Note that this is also used internally as a flag to indicate that the
object server structure has been downloaded at all. If you set this
attribute, without setting all the other introspection attributes,
bad things will most definitely occur.

=item Description

=item description

A human-readable general description of the purpose and behavior of
the class.

=item Classes

=item classes

A reference to a list of addresses of remote classes that are
served by this object server.

=item ClassMap

A reference to a hashtable mapping the class name ('Person', not
'Person@joap-server.example.net') of a remote class to the package
name of a local class that acts as its proxy.

=item accessor($name)

Returns a closure which would make a good accessor for attribute
$name. This is used by the code generator like this:

    *foo = MyServerProxy->accessor('foo');

=item method($name)

Returns a closure which would make a good local method for the remote
method $name. This is used by the code generator like this:

    *bar = MyServerProxy->method('bar');

=back

=head2 Autoloaded Methods

As with other JOAP::Proxy packages, you can just go blithely around
using accessors, mutators, and remote methods of the remote class or
instance without really having to write any code for them.

For attributes, an eponymous ("same named") accessor will be created
that will return the value of the attribute.

    my $logLevel = $server->logLevel;

If the attribute is writable, the same local method can be used as a
mutator by passing a single value as the argument to the method.

    $server->logLevel(7);

For remote methods, an eponymous local method is created that takes
the same arguments and has the same return type as the remote
method. This works for both class and instance methods.

    $server->log('Added item foo.');

    my $new_value = $server->logLine(339);

There's no problems with class versus instance methods or attributes
with this package, as with JOAP::Proxy::Package::Class; all methods
and accessors should be called on the server instance.

Note that if there are remote methods or attributes that have the same
name as one of the above built-in methods, they won't work. Similarly,
if a remote method and a remote attribute have the same name, the
remote method will be used.

There are also some internal methods that may cause interference with
remote methods and attributes.

=head1 EXPORT

None by default.

=head1 BUGS

I'm not entirely satisfied with how this class works. I think it
should update the addresses of classes in the classmap when its
address is updated.

The whole storing-metadata-in-a-package thing is only so useful unless
you use the code generator.

It's not a highlander class.

If the address of the server is updated, it doesn't automatically
update the addresses of proxy classes in the classmap.

=head1 SEE ALSO

If you have no clue what all this stuff is about, you should check out
the L<JOAP> package.

This is more useful if you generate the code using L<joappxgen>, the
code generator.

You should also probably use it in conjunction with
L<JOAP::Proxy::Package::Class>, especially in your ClassMap.

If you just need a one-off server instance, and you don't want to
create a package for it, you should try L<JOAP::Proxy::Server>.

You should see L<JOAP::Proxy> for info on how the C<Connection> class
attribute works.

More info about how to contact the author can be found in the L<JOAP>
documentation.

=head1 AUTHOR

Evan Prodromou E<lt>evan@prodromou.san-francisco.ca.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, Evan Prodromou E<lt>evan@prodromou.san-francisco.ca.usE<gt>.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut
