# JOAP::Proxy::Server -- Class for Server Objects
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

# tag: JOAP server proxy object class

use 5.008;
use strict;
use warnings;

package JOAP::Proxy::Server;
use JOAP::Proxy;
use base qw/JOAP::Proxy/;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;

sub classes {

    my $self = shift;
    return (@_) ? $self->{_classes} = shift : $self->{_classes};
}

sub _describe {

    my $self = shift;
    my $resp = $self->SUPER::_describe(@_);

    # Need to get the classes, too.

    my @classes = $resp->GetQuery->GetClass;
    $self->classes(\@classes);

    # XXX: update addresses for classes in classmap

    return $resp;
}

1;

__END__

=head1 NAME

JOAP::Proxy::Server -- Class for Proxies of JOAP Servers

=head1 SYNOPSIS

  use JOAP::Proxy::Server;

  # Get a Jabber connection (you're responsible for this)

  my $con = get_net_jabber_connection_somehow();

  # Set it for all proxies

  JOAP::Proxy->Connection($con);

  # initialize the server

  my $server = JOAP::Proxy::Server->get('joap.example.com');

  # read an attribute

  my $foo = $server->logLevel;

  # set an attribute

  $server->logLevel(14);

  # save changed values

  $server->save;

  # refresh attributes from the remote server

  $server->refresh;

  # get a list of addresses of classes served

  my $classes = $server->classes;

  # get those classes

  foreach my $classaddr (@$classes) {
      my $class = JOAP::Proxy::Class->get($classaddr);
  }

=head1 ABSTRACT

This class provides client-side access to the attributes, methods, and
classes of a remote object server.

=head1 DESCRIPTION

This class provides client-side access to the attributes, methods, and
classes of a remote object server. In general, it's preferable to use
the L<JOAP::Proxy::Package::Server> class instead.

This module is mainly useful if you don't know the address of the
server at programming time; for quick one-off scripts where you don't
feel like setting up a local Perl module for the server; and for
scripts that work with the metadata of an object server, like the
L<joappxgen> proxy code generator.

The Perl methods are very similar to those for other JOAP::Proxy
packages, but they are listed here for completeness.

=head2 Class Methods

These methods work on the class.

=over

=item get($address)

Constructor. Creates a new instance of JOAP::Proxy::Server which
proxies for the server at address $address. See L<JOAP::Addresses> for
more information about the proper format for JOAP addresses.

This method also gets the metadata for the server, and retrieves the
current attribute values.

=back

=head2 Instance Methods

These methods work on objects returned by C<get()>.

=head3 Data Manipulation Methods

These are methods for manipulating data on the server.

=over

=item refresh

Read the attributes of this remote object server and store them
locally in the instance. The attributes can then be queried
using the autoloaded accessors.

=item save

Save the local values of attributes to the remote object server. This
will only save writable attributes.

=back

=head3 Metadata Methods

These methods give access to the metadata about the server.

=over

=item address

The address of the remote object server this instance is a proxy
for. See L<JOAP::Addresses> for the acceptable values of an object
server address.

=item attributes

Returns a reference to a hashtable mapping attribute names to
attribute descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item methods

Returns a reference to a hashtable mapping method names to
method descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item timestamp

The date and time that the object server structure description was
downloaded from the remote class. It's in ISO 8601 format; see
L<JOAP::Types> for details.

Note that this is also used internally as a flag to indicate that the
object server structure has been downloaded at all. If you set this
attribute, without setting all the other introspection attributes,
bad things will most definitely occur.

=item description

A human-readable general description of the purpose and behavior of
the class.

=item classes

A reference to a list of addresses of remote classes that are served
by this object server. See L<JOAP::Addresses> for the format of these
addresses. These make a good argument to C<get()> in
L<JOAP::Proxy::Class>.

=back

=head2 Autoloaded Methods

As with other JOAP::Proxy packages, you can just go blithely around
using accessors, mutators, and remote methods of the remote object
server without really having to write any code for them.

For attributes, an eponymous ("same named") accessor will be created
that will return the value of the attribute.

    my $logLevel = $server->logLevel;

If the attribute is writable, the same local method can be used as a
mutator by passing a single value as the argument to the method.

    $server->logLevel(7);

For remote methods, an eponymous local method is created that takes
the same arguments and has the same return type as the remote
method.

    $server->log('Added item foo.');

    my $new_value = $server->logLine(339);

Note that if there are remote methods or attributes that have the same
name as one of the above built-in methods, they won't work. Similarly,
if a remote method and a remote attribute have the same name, the
remote method will be used.

There are also some internal methods that may cause interference with
remote methods and attributes.

=head1 EXPORT

None by default.

=head1 BUGS

The large number of local methods can mask remote methods and
attributes.

=head1 SEE ALSO

If you want a subclass interface for object servers, see
L<JOAP::Proxy::Package::Server>.

You can use L<JOAP::Proxy::Class> to get classes, and
L<JOAP::Proxy::Instance> to get instances.

If you have no clue what all this stuff is about, you should check out
the L<JOAP> package.

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
