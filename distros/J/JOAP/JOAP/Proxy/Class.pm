# JOAP::Proxy::Class.pm - class for classes that are classes
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

# tag: JOAP class proxy object class

package JOAP::Proxy::Class;
use JOAP::Proxy;
use JOAP::Proxy::Instance;
use base qw/JOAP::Proxy/;

use 5.008;
use strict;
use warnings;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;
our $AUTOLOAD;

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

sub _default_edit_attrs {

    my $self = shift;

    # This _should_ return only writable attributes

    my $attrs = $self->SUPER::_default_edit_attrs;

    my @right_alloc = grep { $attrs->{$_}->{allocation} eq 'class' } keys %$attrs;

    # make that into a hash

    my %write = map {($_, $attrs->{$_})} @right_alloc;

    # return a reference to that hash

    return \%write;
}

sub can {
    my $self = shift;
    my $name = shift;
    my $func = $self->UNIVERSAL::can($name); # See if it's findable by standard lookup.

    if (!$func) { # if not, see if it's something we should make ourselves.
        my $methdesc = $self->_method_descriptor($name);

        if ($methdesc && $methdesc->{allocation} eq 'class') {
            $func = $self->_proxy_method($methdesc);
	} else {
            my $attrdesc = $self->_attribute_descriptor($name);
            if ($attrdesc && $attrdesc->{allocation} eq 'class') {
                $func = $self->_proxy_accessor($attrdesc);
            }
        }
    }

    return $func;
}

sub add {

    my $self = shift;

    my %args = @_;

    my $con = $self->Connection || throw JOAP::Proxy::Error::Local("Can't add without a connection.");

    # Servers will of course do these checks for us, because they need
    # to preserve their data integrity. However, we save some time
    # failing early if we know what the problem is.

    # check to see that all params are in our class

    my @unmatched = grep { !$self->_attribute_descriptor($_) } keys %args;

    if (@unmatched) {
        throw JOAP::Proxy::Error::Local("Unknown attributes: " . join(",", @unmatched));
    }

    # check to see that all params are writable

    my @unwritable = grep { ! $self->_attribute_descriptor($_)->{writable} } keys %args;

    if (@unwritable) {
        throw JOAP::Proxy::Error::Local("Read-only attributes: " . join(",", @unwritable));
    }

    # check to see that all params are instance

    my @noninst = grep { $self->_attribute_descriptor($_)->{allocation} ne 'instance' } keys %args;

    if (@noninst) {
        throw JOAP::Proxy::Error::Local("Non-instance attributes: " . join(",", @noninst));
    }

    my $attrdesc = $self->attributes;

    # check to see that all required, writable instance attrs are present

    my @reqwrite =
      grep { my $desc = $attrdesc->{$_};
             $desc->{required} &&
               $desc->{writable} &&
               ($desc->{allocation} eq 'instance')} keys %$attrdesc;

    my @unfulfill = grep { ! exists $args{$_} } @reqwrite;

    if (@unfulfill) {
        throw JOAP::Proxy::Error::Local("Required, writable instance attributes not provided: " . join (",", @unfulfill));
    }

    # Hooray! We're validated. Let's send the message already.

    my $iq = new Net::Jabber::IQ();
    $iq->SetIQ(to => $self->address, type => 'set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    while (my ($name, $arg) = each %args) {
        my $attr = $add->AddAttribute(name => $name);
        my $value = $attr->AddValue;
        my $enc = JOAP->encode($self->_attribute_descriptor($name)->{type}, $arg);
        JOAP->copy_value($enc, $value);
    }

    my $resp = $con->SendAndReceiveWithID($iq);

    if ($resp->GetType eq 'error') {
	throw JOAP::Proxy::Error::Remote($resp->GetError, $resp->GetErrorCode);
    }

    my $addr = $resp->GetQuery->GetNewAddress;

    return $self->_get_instance($addr);
}

# We want to be able to overload this in subclasses.

sub _get_instance {

    my $self = shift;
    my $addr = shift;

    # XXX: This is a little iffy, since it requires a round-trip to
    # the server, even though we know some of the attributes. But a
    # re-read is probably the safest thing.

    return JOAP::Proxy::Instance->get($addr,
                                      methods => $self->methods,
                                      attributes => $self->attributes,
                                      superclasses => $self->superclasses,
                                      description => $self->description,
                                      timestamp => $self->timestamp);
}

sub search {

    my $self = shift;

    my %args = @_;

    my $con = $self->Connection || throw JOAP::Proxy::Error::Local("Can't search without a connection.");

    # Servers will of course do these checks for us, because they need
    # to preserve their data integrity. However, we save some time
    # failing early if we know what the problem is.

    # Are there any attrs to search that aren't in our object?

    my @unknown = grep { !$self->_attribute_descriptor($_) } keys %args;

    if (@unknown) {
	throw JOAP::Proxy::Error::Local("Unknown attributes: " . join(",", @unknown));
    }

    # Are there any class attributes in there?

    my @classattrs = grep {$self->_attribute_descriptor($_)->{allocation} eq 'class'} keys %args;

    if (@classattrs) {
	throw JOAP::Proxy::Error::Local("Can't search on class attributes: " . join(",", @classattrs));
    }

    # Well, that's about all we can do.

    my $iq = new Net::Jabber::IQ();
    $iq->SetIQ(to => $self->address, type => 'get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    while (my ($name, $arg) = each %args) {
        my $attr = $search->AddAttribute(name => $name);
        my $value = $attr->AddValue;
        my $enc = JOAP->encode($self->_attribute_descriptor($name)->{type}, $arg);
        JOAP->copy_value($enc, $value);
    }

    my $resp = $con->SendAndReceiveWithID($iq);

    if ($resp->GetType eq 'error') {
	throw JOAP::Proxy::Error::Remote(value => $resp->GetErrorCode, text => $resp->GetError);
    }

    # This is going to be a list of address strings

    my @items = $resp->GetQuery->GetItem;

    return @items;
}

1;  # don't forget to return a true value from the file

__END__

=head1 NAME

JOAP::Proxy::Class - Class for client-side proxy objects of JOAP classes

=head1 SYNOPSIS

  use JOAP::Proxy;
  use JOAP::Proxy::Class;

  # do Net::Jabber connection stuff here...

  $con = get_jabber_connection(); # You work this out

  # set the Jabber connection

  JOAP::Proxy->Connection($con);

  # get an object that represents a remote class

  $fooclass = JOAP::Proxy::Class->get('Foo@joap.example.net');

  # update class attributes with server values

  $fooclass->refresh;

  # get an attribute value with the automagic accessor

  my $height = $fooclass->height;

  # set an attribute with the automagic accessor

  $fooclass->height($height + 1);

  # save class attributes to server

  $fooclass->save;

  # call a class method, with automagic method thingy

  $fooclass->reindex_all_frozzes('upwards');

  # create a new instance

  my $foo = $fooclass->add(name => 'gar', drink => 'beaujolais');

  # search for instances matching criteria

  my @matches = $fooclass->search(name => 'troyd');

=head1 ABSTRACT

This class is for proxies to JOAP classes. The proxy is a Perl object,
not a class.

=head1 DESCRIPTION

This class provides client-side access to the attributes, methods, and
superclasses of a remote JOAP class. In general, it's preferable to
use the L<JOAP::Proxy::Package::Class> class instead.

This module is mainly useful if you don't know the address of the
class at programming time; for quick one-off scripts where you don't
feel like setting up a local Perl module for the class; and for
scripts that work with the metadata of a class, like the L<joappxgen>
proxy code generator.

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

=item get($class_address)

Returns a proxy version of the class at $class_address as an Perl
object. The class attributes will be populated with its current
values, and metadata will also be stored.

See L<JOAP::Addresses> for more information on properly-formatted
addresses.

=back

=head2 Instance Methods

These are methods on the Perl proxy object that represents the remote
class.

=head3 Data Manipulation Methods

These are methods you use to manipulate the data itself.

=over

=item refresh()

Reads the remote class attributes and caches them. If the metadata has
not already been read, will also get that stuff, too.

In general, calling this method on the class before doing anything
else is a good idea.

=item save()

Saves the cached values of the class attributes to the remote server.

=item add(attr1 => $value1, attr2 => $value2, ...)

Adds a new JOAP instance and returns a proxy version as an instance of
L<JOAP::Proxy::Instance>. All required, writable attributes of the
JOAP class must be present for it to work. You can include other
instance attributes, also, but they must be writable.

=item search(attr1 => $spec1, attr2 => $spec2, ...)

Returns a list of addresses of all JOAP instances that match all the
search specifications. The specifications are logically ANDed -- only
instances that match I<all> specification values will be returned. An
example:

    my @rectangles = Shape->search(sides => 4, angle => 90.0);

    foreach my $address (@rectangles) {
        my $rect = Shape->get($address);
        $rect->draw();
    }

The semantics of the spec values is somewhat complicated -- see the
JOAP specification for full details. In general, numeric and date
types are matched exactly, while string types are matched if the spec
value is a substring of the instance value.

Class attributes cannot be used as arguments to C<search()>.

As a special case, C<search()> with no arguments returns a list of
B<all> instances.

=back

=head3 Introspection Methods

These methods return information about the structure of the
class. It's generally a B<bad> idea to use them as mutators (with
arguments), unless you really really know what you're doing.

=over

=item address

The address of the remote class this object is a proxy for.

=item attributes

Returns a reference to a hashtable mapping attribute names to
attribute descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item methods

Returns a reference to a hashtable mapping method names to
method descriptors. See L<JOAP::Descriptors> for more information
on these data structures.

=item timestamp

The date and time that the class structure description was downloaded
from the remote class. It's in ISO 8601 format; see L<JOAP::Types> for
details.

Note that this is also used internally as a flag to indicate that the
class structure has been downloaded at all. If you set this attribute,
without setting all the other instrospection attributes, bad things
will most definitely occur.

=item description

A human-readable general description of the purpose and behavior of
the class.

=item superclasses

A reference to a list of addresses of remote classes that are
superclasses of this class. This implies no local hierarchy of
classes; it's only here to make typing decisions. It's currently not
used in the internals of the proxy code.

=back

=head2 Autoloaded Methods

As with other JOAP::Proxy classes, you can just go blithely around
using accessors, mutators, and remote methods of the remote class
really having to write any code for them.

For attributes, an eponymous ("same named") accessor will be
autoloaded that will return the value of the attribute.

    my $gar = $fooclass->gar;

If the attribute is writable, the same local method can be used as a
mutator by passing a single value as the argument to the method.

    $fooclass->gar('gar gar gar!');

Calling an accessor for an instance attribute on a class will cause a
runtime error. So don't do that.

For remote methods, an eponymous local method is autoloaded that takes
the same arguments and has the same return type as the remote
method. This works for both class methods.

    $fooclass->reindex_all_frozzes('upward');

A runtime error will be thrown if you call an instance method on a
class object.

Note that if there are remote methods or attributes that have the same
name as one of the above built-in methods, they won't work. Similarly,
if a remote method and a remote attribute have the same name, the
remote method will be used.

There are also some internal methods that may cause interference with
remote methods and attributes.

=head1 EXPORT

None by default.

=head1 BUGS

The class proxy object is not a Perl class.

The thread-safety attributes aren't specified for methods defined in
this package nor for autoloaded methods.

There's currently no workaround for name clashes between attributes
and methods and between local built-in methods and either of these.

There are probly lots more bugs lurking silently.

=head1 SEE ALSO

An easier, more Perlish, and more efficient mechanism for proxying
remote classes can be found in L<JOAP::Proxy::Package::Class>.

You should see L<JOAP::Proxy> to figure out how to make your initial
Jabber connection.

The C<add()> method creates instances of the L<JOAP::Proxy::Instance>
class.

L<JOAP::Types> has more info on JOAP data types.

L<JOAP::Descriptors> has more info on the structure of attribute and
method descriptors. L<JOAP::Addresses> has some clues about the
structure of JOAP addresses.

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
