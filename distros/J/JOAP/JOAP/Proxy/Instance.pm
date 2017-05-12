# JOAP::Proxy::Instance.pm - class for Instances
#
# Copyright (c) {$YEAR}, {$NAME} {$EMAIL}.
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

# tag: JOAP class proxy instance class

package JOAP::Proxy::Instance;
use JOAP::Proxy;
use base qw/JOAP::Proxy/;

use 5.008;
use strict;
use warnings;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;
our $AUTOLOAD;

sub get {

    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    my $address = shift;
    my $self = bless({_address => $address}, $pkg);

    my %named = @_;

    # If these are passed in, we don't have to do a describe.

    if (defined $named{methods} &&
        defined $named{attributes} &&
        defined $named{superclasses} &&
        defined $named{timestamp} &&
        defined $named{description})
      {
        $self->methods($named{methods});
        $self->attributes($named{attributes});
        $self->superclasses($named{superclasses});
        $self->_set_timestamp($named{timestamp});
        $self->_set_description($named{description});
    }

    $self->_read();

    return $self;
}

sub superclasses {
    my $self = shift;
    return (@_) ? $self->{_superclasses} = shift : $self->{_superclasses};
}

sub _describe {
    my $self = shift;
    my $resp = $self->SUPER::_describe(@_);

    my @classes = $resp->GetQuery->GetSuperclass;
    $self->superclasses(\@classes);

    return $resp;
}

sub _edit {

    my $self = shift;
    my $resp = $self->SUPER::_edit(@_);
    my $edit = $resp->GetQuery;

    if (ref($self) && $edit->DefinedNewAddress) {
	$self->address($edit->GetNewAddress);
    }

    return $resp;
}

sub _default_edit_attrs {

    my $self = shift;

    # This _should_ return only writable attributes

    my $attrs = $self->SUPER::_default_edit_attrs;

    my @right_alloc = grep { $attrs->{$_}->{allocation} ne 'class' } keys %$attrs;

    # make that into a hash

    my %write = map {($_, $attrs->{$_})} @right_alloc;

    # return a reference to that hash

    return \%write;
}

sub delete {

    my $self = shift;

    my $con = $self->Connection || throw JOAP::Proxy::Error::Local("Can't delete without a connection.");

    my $iq = new Net::Jabber::IQ();

    $iq->SetIQ(to => $self->address, type => 'set');
    $iq->NewQuery($JOAP::NS, 'delete');

    my $resp = $con->SendAndReceiveWithID($iq);

    if ($resp->GetType eq 'error') {
	throw JOAP::Proxy::Error::Remote(value => $resp->GetErrorCode, text => $resp->GetError);
    }

    return 1;
}

sub can {
    my $self = shift;
    my $name = shift;
    my $func = $self->UNIVERSAL::can($name); # See if it's findable by standard lookup.

    if (!$func) { # if not, see if it's something we should make ourselves.
        my $methdesc = $self->_method_descriptor($name);

        if ($methdesc && $methdesc->{allocation} ne 'class') {
            $func = $self->_proxy_method($methdesc);
	} else {
            my $attrdesc = $self->_attribute_descriptor($name);
            if ($attrdesc && $attrdesc->{allocation} ne 'class') {
                $func = $self->_proxy_accessor($attrdesc);
            }
        }
    }

    return $func;
}

1;  # don't forget to return a true value from the file

__END__


=head1 NAME

JOAP::Proxy::Class - Class for client-side proxy objects of JOAP classes

=head1 SYNOPSIS

  use JOAP::Proxy;
  use JOAP::Proxy::Instance;

  # do Net::Jabber connection stuff here...

  $con = get_jabber_connection(); # You work this out

  # set the Jabber connection

  JOAP::Proxy->Connection($con);

  # get an object that represents a remote class

  $foo = JOAP::Proxy::Instance->get('Foo@joap.example.net/gar');

  # refresh instance with attribute values from server

  $foo->refresh;

  # read an instance attribute using the Magic Accessor

  my $name = $foo->name;

  # set an instance attribute (did I mention the magic accessors?)

  $foo->name('Murgatroyd');

  # save to the server

  $foo->save;

  # call an instance method

  $foo->scratch_where_it_itches(1, 2, 3);

  # delete an instance

  $foo->delete;

=head1 ABSTRACT

This class is for proxies to JOAP instance.

=head1 DESCRIPTION

This class provides client-side access to the attributes, methods, and
superclasses of a remote JOAP instance. In general, it's preferable to
use the L<JOAP::Proxy::Package::Class> package to make real Perl
packages for remote classes, and have instances be instances of their
class's class. But if you want to be difficult, use this package
instead.

This module is mainly useful if you don't have information about the
instance's class at programming time, and for quick one-off scripts
where you don't feel like setting up a local Perl module for the
class.

Most of the interface is inherited from various superclasses, but I
document it here for convenience. For terminology, I try to use
'remote' for JOAP classes, instances, attributes and methods of the
remote class or instance, and 'local' for methods of the local Perl
package or instance, as well as instances of this class, etc., when I
think the meaning is unclear.

One last thing: it's essential to set the C<Connection> class attribute
of the JOAP::Proxy class before using any of the methods in this
package (except maybe C<Address>). See L<JOAP::Proxy> for more
information.

=head2 Class Methods

There's only one class method of any significance.

=over

=item get($inst_address)

Returns a proxy version of the instance at $inst_address as an Perl
object. The instance's attributes will be populated with its current
values, and metadata will also be stored.

See L<JOAP::Addresses> for more information on properly-formatted
addresses.

=back

=head2 Instance Methods

These are methods on the Perl proxy object that represents the remote
instance.

=head3 Data Manipulation Methods

These are methods you use to manipulate the data itself.

=over

=item refresh()

Reads the remote instance attributes and caches them. If the metadata
has not already been read, will also get that stuff, too.

=item save()

Saves the cached values of the instance attributes to the remote
server.

=item delete()

Delete the remote instance. The local proxy will still have all its
attributes, so you can query them, but it will no longer be "linked"
to the remote instance. Calling remote methods, or any of the data
manipulation methods, will most likely result in an error.

=back

=head3 Introspection Methods

These methods return information about the structure of the
instance. It's generally a B<bad> idea to use them as mutators (with
arguments), unless you really really know what you're doing.

=over

=item address

The address of the remote instance this object is a proxy for.

=item attributes

Returns a reference to a hashtable mapping attribute names to
attribute descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item methods

Returns a reference to a hashtable mapping method names to
method descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item timestamp

The date and time that the instance structure description was
downloaded from the remote class. It's in ISO 8601 format; see
L<JOAP::Types> for details.

Note that this is also used internally as a flag to indicate that the
instance structure has been downloaded at all. If you set this
attribute, without setting all the other instrospection attributes,
bad things will most definitely occur.

=item description

A human-readable general description of the purpose and behavior of
the class the JOAP instance is an instance of.

=item superclasses

A reference to a list of addresses of remote classes that are
superclasses of this instance's JOAP class. This implies no local
hierarchy of classes; it's only here to make typing decisions. It's
currently not used in the internals of the proxy code.

=back

=head2 Autoloaded Methods

As with other JOAP::Proxy classes, you can just go blithely around
using accessors, mutators, and remote methods of the remote class
really having to write any code for them.

For attributes, an eponymous ("same named") accessor will be
autoloaded that will return the value of the attribute.

    my $gar = $foo->gar;

If the attribute is writable, the same local method can be used as a
mutator by passing a single value as the argument to the method.

    $foo->gar('gar gar gar!');

Calling an accessor for a class attribute on a JOAP::Proxy::Instance
will cause a runtime error. So don't do that.

For remote methods, an eponymous local method is autoloaded that takes
the same arguments and has the same return type as the remote
method.

    $fooclass->reindex_all_frozzes('upward');

A runtime error will be thrown if you call a class method on a
JOAP::Proxy::Instance object.

Note that if there are remote methods or attributes that have the same
name as one of the above built-in methods, they won't work. Similarly,
if a remote method and a remote attribute have the same name, the
remote method will be used.

There are also some internal methods that may cause interference with
remote methods and attributes.

=head1 EXPORT

None by default.

=head1 BUGS

There's a lot of wasteful overhead in storing the metadata in each
instance; smart programmers will use L<JOAP::Proxy::Package::Class>
for regular use.

You can't get at class data or methods.

The thread-safety attributes aren't specified for methods defined in
this package nor for autoloaded methods.

There's currently no workaround for name clashes between attributes
and methods and between local built-in methods and either of these.

There are probly lots more bugs lurking silently.

=head1 SEE ALSO

An easier, more Perlish, and more efficient mechanism for proxying
remote instances can be found in L<JOAP::Proxy::Package::Class>.

You should see L<JOAP::Proxy> to figure out how to make your initial
Jabber connection.

You can get a proxy to the instance's class using
L<JOAP::Proxy::Class>.

L<JOAP::Types> has more info on JOAP data types. L<JOAP::Descriptors>
has more info on the structure of attribute and method
descriptors. L<JOAP::Addresses> has some clues about the structure of
JOAP addresses.

There's more information in the L<JOAP> documentation about how to
contact the author of this package.

=head1 AUTHOR

Evan Prodromou E<lt>evan@prodromou.san-francisco.ca.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, Evan Prodromou E<lt>evan@prodromou.san-francisco.ca.usE<gt>

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
