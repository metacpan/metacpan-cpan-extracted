# JOAP::Proxy::Package::Class -- Base package for JOAP Class classes
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

# tag: JOAP proxy class base class

use 5.008;
use strict;
use warnings;

package JOAP::Proxy::Package::Class;
use JOAP::Proxy::Package;
use JOAP::Proxy::Class;
use JOAP::Proxy::Instance;
use JOAP::Proxy::Error;
use Symbol;
use base qw/JOAP::Proxy::Package JOAP::Proxy::Class JOAP::Proxy::Instance/;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;

JOAP::Proxy::Package::Class->mk_classdata('Address');
JOAP::Proxy::Package::Class->mk_classdata('Superclasses');

JOAP::Proxy::Package::Class->Address('');
JOAP::Proxy::Package::Class->Superclasses([]);

sub superclasses {
    my $self = shift;
    return $self->Superclasses(@_);
}

sub address {
    my $self = shift;
    if (!ref($self)) {
        return $self->Address(@_);
    } else {
        return $self->JOAP::Proxy::Instance::address(@_);
    }
}

sub add {

    my $self = shift;

    if (ref($self)) {
        throw JOAP::Proxy::Error::Local("Can't add to an instance.");
    } else {
        $self->SUPER::add(@_);
    }
}

# we meddle with this so we can return our own instance instead of a generic JOAP::Proxy::Instance

sub _get_instance {

    my $self = shift;
    my $addr = shift;

    return $self->get($addr);
}

sub search {

    my $self = shift;

    if (ref($self)) {
        throw JOAP::Proxy::Error::Local("Can't search an instance.");
    } else {
        $self->SUPER::search(@_);
    }
}

sub delete {

    my $self = shift;

    if (!ref($self)) {
        throw JOAP::Proxy::Error::Local("Can't call delete on a class.");
    } else {
        $self->SUPER::delete(@_);
    }
}

sub can {

    my($self) = shift;
    my($name) = shift;
    my($func) = $self->UNIVERSAL::can($name); # See if it's findable by standard lookup.

    if (!defined($func)) { # if not, see if it's something we should make ourselves.
        if (my $methdesc = $self->_method_descriptor($name)) {
            if ($methdesc->{allocation} eq 'class') {
                $func = $self->_proxy_method($methdesc);
            } elsif (ref($self)) {
                $func = $self->_proxy_instance_method($methdesc);
            }
	} elsif (my $attrdesc = $self->_attribute_descriptor($name)) {
            if (ref($self) && $attrdesc->{allocation} ne 'class') {
                $func = $self->_proxy_instance_accessor($attrdesc);
            } elsif ($attrdesc->{allocation} eq 'class') {
                $func = $self->_proxy_class_accessor($attrdesc);
            }
        }
    }

    return $func;
}

# internal setter

sub _set {

    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $allocation = $self->_attribute_descriptor($name)->{allocation};

    if ($allocation eq 'class') {
        my $pkg = ref($self) || $self;
        my $globref = qualify_to_ref($pkg . "::" . $name);
        my $sref = *$globref{SCALAR};
        $$sref = $value;
    } elsif (ref($self)) {
        $self->{$name} = $value;
    }
}

sub _describe {

    my $self = shift;
    my $resp = $self->SUPER::_describe(@_);
    my $describe = $resp->GetQuery;

    my @supers = $describe->GetSuperclass;

    $self->Superclasses(\@supers);

    return $resp;
}

# We need to overload this to get only instance or class attributes,
# depending on the type of self.

sub _default_edit_attrs {

    my $self = shift;

    if (ref($self)) {
        return $self->JOAP::Proxy::Instance::_default_edit_attrs;
    } else {
        return $self->JOAP::Proxy::Class::_default_edit_attrs;
    }
}

sub _proxy_instance_accessor {

    my $self = shift;
    my $descriptor = shift;

    my $name = $descriptor->{name};
    my $writable = $descriptor->{writable};
    my $type = $descriptor->{type};

    my $acc = $self->JOAP::Proxy::Instance::_proxy_accessor($descriptor);

    my $func = sub {
        my $self = shift;
        if (!ref($self)) {
            throw JOAP::Proxy::Error::Local("Can't use instance accessor on a class.");
        }
        return $self->$acc(@_);
    };

    return $func;
}

sub _proxy_instance_method {

    my $self = shift;
    my $descriptor = shift;

    my $meth = $self->JOAP::Proxy::Instance::_proxy_method($descriptor);

    my $func = sub {
        my $self = shift;
        if (!ref($self)) {
            throw JOAP::Proxy::Error::Local("Can't use instance method on a class.");
        }
        return $self->$meth(@_);
    };

    return $func;
}

sub _proxy_class_accessor {

    my $self = shift;
    my $descriptor = shift;
    my $pkg = ref($self) || $self;

    my $name = $descriptor->{name};
    my $writable = $descriptor->{writable};
    my $type = $descriptor->{type};

    my $globref = qualify_to_ref($pkg . "::" . $name);
    my $sref = *$globref{SCALAR};

    my $func = undef;

    # This is kind of wordy, but we need to unwrap the $writable
    # stuff at compile time rather than run time.

    # XXX: choose a coercion function at compile-time

    if ($writable) {
        $func = sub {
            my($self) = shift;
            return (@_) ? $$sref = JOAP->coerce($type, @_) : $$sref;
        };
    } else {
        $func = sub {
            my($self) = shift;
            throw JOAP::Proxy::Error::Local("Read-only attribute $name") if @_;
            return $$sref;
        };
    }

    return $func;
}

sub instance_method {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name);
    my $method = $self->_proxy_instance_method($desc);
}

sub class_method {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name);
    my $method = $self->_proxy_method($desc);
}

sub instance_accessor {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_attribute_descriptor($name);
    my $accessor = $self->_proxy_instance_accessor($desc);
}

sub class_accessor {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_attribute_descriptor($name);
    my $accessor = $self->_proxy_class_accessor($desc);
}

1;  # the loneliest number

__END__

=head1 NAME

JOAP::Proxy::Class - Base class for client-side proxies of JOAP classes

=head1 SYNOPSIS

  package FooProxy;
  use JOAP::Proxy::Package::Class;
  use base qw(JOAP::Proxy::Package::Class);

  FooProxy->Address('Foo@bar.example.com'); # say what class this is proxying for

  package main;

  # do Net::Jabber connection stuff here...

  $con = get_jabber_connection(); # You work this out

  JOAP::Proxy->Connection($con);

  # update class attributes with server values

  FooProxy->refresh;

  # get an attribute value with the automagic accessor

  my $height = FooProxy->height;

  # set an attribute with the automagic accessor

  FooProxy->height($height + 1);

  # save class attributes to server

  FooProxy->save;

  # call a class method, with automagic method thingy

  FooProxy->reindex_all_frozzes('upwards');

  # get a proxy to a remote instance

  my $foo1 = FooProxy->get('Foo@bar.example.com/Number1');

  # refresh instance with attribute values from server

  $foo1->refresh;

  # read an instance attribute using the Magic Accessor

  my $name = $foo1->name;

  # set an instance attribute (did I mention the magic accessors?)

  $foo1->name('Murgatroyd');

  # save to the server

  $foo1->save;

  # call an instance method

  $foo1->scratch_where_it_itches(1, 2, 3);

  # call a class method (not recommended) on an instance

  $foo->reindex_all_frozzes('downwards');

  # read or write a class attribute using an accessor on an instance

  my $height2 = $foo->height;
  $foo->height($height + 17);

  # create a new instance

  my $foo2 = FooProxy->add(name => 'gar', drink => 'beaujolais');

  # search for instances matching criteria

  my @matches = FooProxy->search(name => 'troyd');

  # delete an instance

  $foo2->delete;

=head1 ABSTRACT

This is an abstract superclass for proxies to JOAP classes. Its intent
is to make it easy -- nay, trivial -- to build and use proxy classes.

=head1 DESCRIPTION

JOAP servers support three kinds of objects: servers, classes, and
instances. Ignoring servers for a moment, the most natural map of this
into Perl is to have JOAP classes be Perl classes, and JOAP instances
be instances of the corresponding Perl class.

That's the model that this module supports. You can normally just
treat the proxy class as if it I<were> the remote class, and the proxy
instance as if it I<were> the remote instance.

The mainline usage of this module is to create a new Perl class that
is a subclass of JOAP::Proxy::Package::Class, define its address, and
then use it right away. The JOAP::Proxy classes will figure out what
the right accessors, mutators, and methods should be automagically.

You can, if you want to avoid the automagic-figure-stuff-out step,
also define the attributes, methods, and other metadata of a
class. This can be error-prone, however, since typos and stuff will
keep your class from working correctly, in weird ways. It's probably
is not worth the effort of saving one round-trip to the object server
per program invocation if done by hand. There I<is> a tool to do it
automatically, though. See L<joappxgen>, the JOAP proxy code
generator, for details.

As a word of warning, this package is still in early experimental
stage. You're going to have enough gotchas with the recommended
interface, so don't give yourself more trouble by doing things I don't
recommend.

Most of the interface is inherited from various superclasses, but I
document it here for convenience. For terminology, I try to use
'remote method' for JOAP methods of the remote class or instance, and
'local method' for methods of the local Perl package or instance, when
I think the meaning is unclear.

One last thing: it's essential to set the C<Connection> class attribute
of the JOAP::Proxy class before using any of the methods in this
package (except maybe C<Address>). See L<JOAP::Proxy> for more
information.

=head2 Class Methods

There are a number of class methods for different use; I separate them
here for sanity's sake.

=head3 Data Manipulation Methods

These are methods that you're going to use over and over. In general,
they should be called on the class itself, rather than on
instances. Some have different behavior if called on instances (see
below), and some will throw an error if called on instances.

=over

=item get($inst_address)

Returns a proxy version of the instance at $inst_address as an
instance of this class. The instance attributes will be populated with
its current values.

See L<JOAP::Addresses> for more information on properly-formatted
addresses. If you only know some attributes of the instance, you
should use the L</search> method described below.

=item add(attr1 => $value1, attr2 => $value2, ...)

Adds a new instance (remotely) and returns a proxy version as an
instance of this class. All required, writable attributes of the
class must be present for it to work. You can include other
instance attributes, also, but they must be writable.

This will throw an error if called on an instance.

=item search(attr1 => $spec1, attr2 => $spec2, ...)

Returns a list of all remote instances that match all the search
specifications. The specifications are logically ANDed -- only
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

This method will throw an error if called on an instance.

=item refresh()

As a class method, reads the remote class attributes and caches
them. If the metadata has not already been read, will also get that
stuff, too.

In general, calling this method on the class before doing anything
else is a good idea.

Calling this method on an instance has different behavior; see below.

=item save()

Saves the cached values of the class attributes to the remote server.

Calling this method on an instance has different behavior; see below.

=back

=head3 Introspection Methods

These methods return information about the structure of the
class. It's generally a B<bad> idea to use them as mutators (with
arguments), unless you really really know what you're doing.

=over

=item Address()

=item Address($address)

The address of the remote class this class is a proxy for. This is the
only introspection method application code should use as a
mutator. It's mostly useful when several object servers at different
locations use the same interface; you can say which one you're
interested in by changing this classes address.

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

The date and time that the class structure description was downloaded
from the remote class. It's in ISO 8601 format; see L<JOAP::Types> for
details.

Note that this is also used internally as a flag to indicate that the
class structure has been downloaded at all. If you set this attribute,
without setting all the other instrospection attributes, bad things
will most definitely occur.

=item Description

=item description

A human-readable general description of the purpose and behavior of
the class.

=item Superclasses

=item superclasses

A reference to a list of addresses of remote classes that are
superclasses of this class. This implies no local hierarchy of
classes; it's only here to make typing decisions. It's currently not
used in the internals of the proxy code.

=back

=head3 Code-Generation Methods

These methods are of use really only for code generators. Don't use
them to call methods or accessors; use the autoloading interface
instead.

=over

=item class_accessor($name)

Return a closure that would work well as a class accessor for
attribute $name. You can install it in a package like this:

    *some_attribute = Package->class_accessor('some_attribute');

=item class_method($name)

Return a closure that would work well as a class method for
method $name.

=item instance_accessor($name)

Return a closure that would work well as an instance accessor for
attribute $name.

=item instance_method($name)

Return a closure that would work well as an instance method for
method $name.

=back

=head2 Instance Methods

The following methods are for use on instances. Some of them will
throw errors when called on a class; others have different behavior
when called on a class.

=head3 Data Manipulation Methods

=over

=item refresh

Read the attributes of this remote instance and store them locally in
the proxy instance. The attributes can then be queried using the
accessors.

Note that the behavior of this method is different when called on a
class.

=item save

Save the local values of attributes to the remote instance. This will
only save writable, instance attributes.

Some classes have instance addresses that are calculate from their
attribute values; you should not count on an instance address being
the same after a C<save()>. Of course, the Perl reference will be the
same.

If the instance has read-only attributes, it's a good idea to call
C<refresh()> after each save to ensure that all attributes are sync'd.

Note that the behavior of this method is different when called on a
class.

=item delete

Delete the remote instance. The local proxy will still have all its
attributes, so you can query them, but it will no longer be "linked"
to the remote instance. Calling remote methods, or any of the data
manipulation methods, will most likely result in an error.

=back

=head3 Introspection Methods

You can call any of the class introspection methods on an instance,
but it looks funny and is not recommended. The following is really the
only introspection method that makes sense:

=over

=item address

The address of the remote instance. This value is set when the object
is constructed using C<get> or C<add>; it can sometimes be changed by
C<save>.

See L<JOAP::Addresses> for more details on the format of JOAP
addresses.

=back

=head2 Autoloaded Methods

One of the key bennies to this package is that you can just go
blithely around using accessors, mutators, and remote methods of the
remote class or instance without really having to write any code for
them.

For attributes, an eponymous ("same named") accessor will be created
that will return the value of the attribute.

    my $gar = $foo->gar;

If the attribute is writable, the same local method can be used as a
mutator by passing a single value as the argument to the method.

    $foo->gar('gar gar gar!');

If the attribute is also a class attribute, it can be called on the
class:

    my $height = FooProxy->height;
    FooProxy->height(7);

Calling an accessor for an instance attribute on a class will cause a
runtime error. So don't do that.

For remote methods, an eponymous local method is created that takes
the same arguments and has the same return type as the remote
method. This works for both class and instance methods.

    FooProxy->reindex_all_frozzes('upward');

    my $new_value = $foo->increment_counter;

A runtime error will be thrown if you call an instance method on a
class.

Note that if there are remote methods or attributes that have the same
name as one of the above built-in methods, they won't work. Similarly,
if a remote method and a remote attribute have the same name, the
remote method will be used.

There are also some internal methods that may cause interference with
remote methods and attributes.

=head1 EXPORT

None by default.

=head1 BUGS

The name of this package is real long.

There's a conceptual disconnect between mutators and methods. For
performance reasons, mutators keep the values set in the local proxy
until a C<save()> call. But methods are called immediately. So, the
following code will probably not do what you expect:

    # set an attribute using a mutator
    $object->counter(42);
    # call a method that changes that attribute as a side-effect
    my $result = $object->increment_counter;

The C<increment_counter> method will use the value on the server, not the
local cached value of 42, of C<counter>. You need to do this:

    # set an attribute using a mutator
    $object->counter(42);
    # save it
    $object->save;
    # call a method that changes that attribute as a side-effect
    my $result = $object->increment_counter;

Future versions may call C<save()> before executing a method if the
local proxy has been changed and not yet saved.

You can use mutators on instances for class attributes, but you have
to call the class C<save()> method to save them.

Mapping a single subclass of this class to two different servers is
asking for trouble.

The thread-safety attributes aren't specified for methods defined in
this package nor for autoloaded methods.

There's currently no workaround for name clashes between attributes
and methods and between local built-in methods and either of these.

There are probly lots more bugs lurking silently.

=head1 SEE ALSO

You should see L<JOAP::Proxy> to figure out how to make your initial
Jabber connection.

L<JOAP::Types> has more info on JOAP data types.

L<JOAP::Descriptors> has more info on the structure of attribute and
method descriptors. L<JOAP::Addresses> has some clues about the
structure of JOAP addresses.

L<joappxgen>, the JOAP proxy generator, can be used to pre-cook
subclasses of this class for a small bump in performance.

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
