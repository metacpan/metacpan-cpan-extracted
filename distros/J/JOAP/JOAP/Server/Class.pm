# JOAP::Server::Class -- Base Class for JOAP Server-Side Classes and Instances
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

# tag: JOAP server class framework

package JOAP::Server::Class;
use base qw/Exporter JOAP::Server::Object/;

use 5.008;
use strict;
use warnings;

use Net::Jabber qw/Component/;
use JOAP;
use JOAP::Server::Object;
use JOAP::Server;
use Error;

require Exporter;

our %EXPORT_TAGS = ( 'all' => [] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();

our $VERSION = $JOAP::VERSION;

JOAP::Server::Class->mk_classdata('Instances');
JOAP::Server::Class->mk_classdata('Superclasses');
JOAP::Server::Class->mk_classdata('Id');
JOAP::Server::Class->mk_classdata('IdFormat');
JOAP::Server::Class->mk_classdata('Separator');

JOAP::Server::Class->Instances({}); # Initially, no instances
JOAP::Server::Class->Superclasses([]);
JOAP::Server::Class->Separator (',');
JOAP::Server::Class->Id([]);
JOAP::Server::Class->IdFormat(undef);

# return the instance with the given instance ID

sub get {
    my $self = shift;

    return $self->Instances->{$_[0]};
}

# handle a JOAP <add> verb

sub on_add {

    my($self) = shift;
    my($iq) = shift;

    if (ref $self) {             # Can't call add on instances
        return $self->SUPER::on_add($iq);
    }

    my $respiq = $self->reply($iq);

    if (my($code, $text) = $self->_validate_add($iq)) {
	$respiq->SetType('error');
	$respiq->SetErrorCode($code);
	$respiq->SetError($text);
	return $respiq;
    }

    # this line is too long.

    my(%args) = map {($_->GetName, JOAP->decode($_->GetValue))} $iq->GetQuery->GetAttribute;

    my $id = $self->_make_id(%args);

    # Do we already have one of these?

    if ($self->get_instance($id)) {
	$respiq->SetType('error');
        $respiq->SetErrorCode(406); # not acceptable
        $respiq->SetError("An instance with this ID already exists.");
        return $respiq;
      }

    my $inst = $self->new(%args);

    $self->set_instance($inst->_id, $inst);

    # The address we should return is mostly in the $iq.

    my($jid) = $iq->GetTo('jid');
    $jid->SetResource($inst->_id);

    $respiq->GetQuery->SetNewAddress($jid->GetJID('full'));

    return $respiq;
}

# handle a JOAP <edit> verb

sub on_edit {

    my $self = shift;
    my $pkg = ref($self) || $self;
    my $iq = shift;
    my $respiq = shift;
    my $oldid;

    # Save the old ID if this is an instance.

    if (ref($self)) {
        $oldid = $self->_id();
    }

    # Do the default editing schtuff

    $respiq = $self->SUPER::on_edit($iq);

    # If this is an instance, and the ID has changed, set the newaddress value

    if (ref($self)) {
	my $instid = $self->_id;

        if ($oldid ne $instid) {

	    $self->delete_instance($oldid);
	    $self->set_instance($instid, $self);

            my($jid) = $iq->GetTo('jid');
            $jid->SetResource($self->_id());
            $respiq->GetQuery->SetNewAddress($jid->GetJID('full'));
        }
    }

    return $respiq;
}

# handle a JOAP <delete> verb

sub on_delete {
    my $self = shift;
    my $pkg = ref($self) || $self;
    my $iq = shift;
    my $respiq = $self->reply($iq);

    if (!ref($self)) {             # Can't call delete on a class
        return $self->SUPER::on_delete($iq);
    }

    $pkg->delete_instance($self->_id());

    # XXX: do we need to allow the instance a cleanup?

    return $respiq;
}

# handle a JOAP <search> verb

sub on_search {

    my($self) = shift;
    my($iq) = shift;

    if (ref($self)) {           # class method
        return $self->SUPER::on_search($iq);
    }

    my($respiq) = $self->reply($iq);

    if (my($code, $text) = $self->_validate_search($iq)) {
	$respiq->SetType('error');
	$respiq->SetErrorCode($code);
	$respiq->SetError($text);
	return $respiq;
    }

    # FIXME: This doesn't get instances of subclasses.
    # XXX: This is big, sloppy, dumb, and linear.

    my %match = map {($_->GetName, JOAP->decode($_->GetValue))} $iq->GetQuery->GetAttribute;

    # sneakily add

    my $addr = $iq->GetTo;

    my $resp = $respiq->GetQuery;

    $self->_iterate(sub
      {
          my $inst = $_;

          if (!%match || $inst->_match_all(%match)) {
	      # XXX: this assumes that the item is a direct instance
	      my $jid = new Net::Jabber::JID($addr);
	      $jid->SetResource($inst->_id);
              $resp->SetItem($jid->GetJID('full'));
          }
      });

    return $respiq;
}

# handle a JOAP <describe> verb; we need to add our superclasses.

sub on_describe {

    my($self) = shift;
    my($iq) = shift;
    my($respiq) = $self->SUPER::on_describe($iq);

    if ($respiq->GetType() ne 'error') { # If that worked out OK...
	my $qry = $respiq->GetQuery;
        foreach my $class (@{$self->Superclasses}) {
            $qry->AddSuperclass($self->make_address(classname => $class));
        }
	$qry->SetTimestamp($self->timestamp);
    }

    return $respiq;
}

# validators

# these return a list of ($code, $text) if there's an error, or an
# empty list for success

# validate an incoming <edit> request

sub _validate_edit {

    my $self = shift;
    my $reqiq = shift;

    if (my($code, $text) = $self->SUPER::_validate_edit($reqiq)) {
	return ($code, $text);
    }

    # You can set class variables through instances, but you can't set
    # instance variables through classes.

    if (!ref($self)) {
	my(@names) = map { $_->GetName } $reqiq->GetQuery->GetAttribute;

	my(@inst) = grep { $self->_attribute_allocation($_) ne 'class' } @names;

	if (@inst) {
	    return (406, join("\n", map "Can't edit instance variable $_ in class", @inst));
	}
    }

    # empty list indicates success

    return ();
}

# validate an incoming method

sub _validate_method {

    my $self = shift;
    my $reqiq = shift;

    if (my($code, $text) = $self->SUPER::_validate_method($reqiq)) {
	return ($code, $text);
    }

    # You can call class methods on instances, but not vice versa

    if (!ref($self)) {

	my $method = $reqiq->GetQuery->GetMethodCall->GetMethodName;

	if ($self->_method_allocation($method) ne 'class') {
	    return (406, join("\n", map "Can't call instance method $_ on class", $method));
	}
    }

    return ();
}

# validate an incoming <read> request

sub _validate_read {

    my $self = shift;
    my $reqiq = shift;

    if (my($code, $text) = $self->SUPER::_validate_read($reqiq)) {
	return ($code, $text);
    }

    # Check to see if they're trying to read an instance attribute from a class.

    if (!ref($self)) {
	my(@names) = $reqiq->GetQuery->GetName;

	if (@names) {
	    my(@inst) = grep { $self->_attribute_allocation($_) ne 'class' } @names;

	    if (@inst) {
		return (406, join("\n", map "Can't read instance variable $_ in class", @inst));
	    }
	}
    }

    return ();
}

# validate an incoming <add> request

sub _validate_add {
    my $self = shift;
    my $reqiq = shift;

    my @attrs = $self->_attribute_names;

    my @toset = $reqiq->GetQuery->GetAttribute;

    my @names = map {$_->GetName} @toset;

    # XXX: Move these checks to their own functions

    # Are there any attrs to set that aren't in our object?

    my @unknown = grep {my($a) = $_; ! grep {/$a/} @attrs} @names;

    if (@unknown) {
	return (406, join("\n", map {"No such attribute '$_'."} @unknown));
    }

    # Check for stuff that isn't writable.

    my @notallowed = grep { !$self->_attribute_writable($_) } @names;

    if (@notallowed) {
        return (406, join("\n", map {"Cannot edit attribute '$_'."} @notallowed));
    }

    # Are all required, writable attributes present?

    my @reqwrite = grep {$self->_attribute_required($_) && $self->_attribute_writable($_)} @attrs;

    my @unmatched = grep {my($a) = $_; ! grep {/$a/} @names} @reqwrite;

    if (@unmatched) {
	return (406, join("\n", map {"Required attribute '$_' not set."} @unknown));
    }

    # Are all attribute values acceptable?

    my @notok = grep {!$self->_attribute_ok($_->GetName, $_->GetValue)} @toset;

    if (@notok) {
	return (406, join("\n", map {"Value for attribute '" . $_->GetName . "' not acceptable."} @notok));
    }

    # empty list means "no probs"

    return ();
}

# validate an incoming <search> request

sub _validate_search {

    my $self = shift;
    my $reqiq = shift;

    my @attrs = $self->_attribute_names;

    my @match = $reqiq->GetQuery->GetAttribute;

    my @names = map {$_->GetName} @match;

    # Are there any attrs to set that aren't in our object?

    my @unknown = grep {my($a) = $_; ! grep {/$a/} @attrs} @names;

    if (@unknown) {
	return (406, join("\n", map {"No such attribute '$_'."} @unknown));
    }

    # Are there any class attributes in there?

    my @classattrs = grep {$self->_attribute_allocation($_) eq 'class'} @names;

    if (@classattrs) {
	return (406, join("\n", map {"Can't search on class attribute '$_'."} @classattrs));
    }

    # Are all attribute values acceptable?

    my @notok = grep {!$self->_attribute_match_ok($_->GetName, $_->GetValue)} @match;

    if (@notok) {
	return (406, join("\n", map {"Value for attribute '" . $_->GetName . "' not acceptable."} @notok));
    }

    # empty list means "no probs"

    return ();

}

# right now, just check the type

sub _attribute_match_ok {

    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $type = $self->_attribute_type($name);

    return $self->_type_match($type, $value);
}

# matching semantics

sub _match_all {

    my $self = shift;
    my %match = @_;

    while (my($attr, $value) = each %match) {
	if (!$self->_match($attr, $value)) {
	  return 0;
	}
    }

    return 1;
}

# match a single attribute and value

sub _match {

    my $self = shift;
    my $attr = shift;
    my $match = shift;

    my $value = $self->_attribute_get($attr);
    my $type = $self->_attribute_type($attr);

    if ($type eq 'i4' || $type eq 'int' || $type eq 'double') {
	return $value == $match;
    }
    elsif ($type eq 'boolean') {
	return (($value && $match) || (!$value && !$match));
    }
    elsif ($type eq 'string') {
	return (index($value, $match) != -1);
    }
    elsif ($type eq 'dateTime.iso8601') {
	# XXX: it'd be nicer to use integer-compare here; maybe use dts at
	# ints internally?
	return $value eq $match;
    }
    elsif ($type eq 'struct') {
	# FIXME: make this work
	return 0;
    }
    elsif ($type eq 'array') {
	# FIXME: make this work
	return 0;
    }
}

# store an instance with the given instance ID

sub set_instance {

    my($self) = shift;
    my($pkg) = ref($self) || $self;
    my($instid) = shift;
    my $inst = shift;

    $pkg->Instances->{$instid} = $inst;
}

# get an instance with the given instance ID

sub get_instance {

    my($self) = shift;
    my($pkg) = ref($self) || $self;
    my($instid) = shift;

    return $pkg->Instances->{$instid};
}

# delete an instance with the given instance ID

sub delete_instance {

    my($self) = shift;
    my($pkg) = ref($self) || $self;
    my($instid) = shift;

    return delete $pkg->Instances->{$instid};
}

# Return the string value representing the instance ID

sub _id {

    my $self = shift;
    my $pkg = ref($self);

    my @ids = map {$self->_attribute_get($_)} @{$self->Id};

    return ($self->IdFormat) ?
      sprintf($self->IdFormat, @ids) :
        join($self->Separator, @ids);
}

# Return the string value representing the instance ID given a set of
# attributes

sub _make_id {
    my $self = shift;
    my %attrs = @_;

    my @ids = map {$attrs{$_}} @{$self->Id};

    return ($self->IdFormat) ?
      sprintf($self->IdFormat, @ids) :
        join($self->Separator, @ids);
}

# Iterate some code over all instances of this class

sub _iterate($\&) {

    my($self) = shift;
    my($block) = shift;

    while (my($id, $inst) = each %{$self->Instances}) {
        $_ = $inst;
        eval &$block;
    }
}

# used by _read; defines which attributes should be returned for a
# <read> verb with no arguments

sub _attribute_read_names {

    my $self = shift;
    my @names = $self->_attribute_names;

    if (ref($self)) {
	return grep { $self->_attribute_allocation($_) eq 'instance' } @names;
    }
    else {
	return grep { $self->_attribute_allocation($_) eq 'class' } @names;
    }
}

1;
__END__

=head1 NAME

JOAP::Server::Class - Base Class for JOAP Server-Side Classes and Instances

=head1 SYNOPSIS

    package MyPerson;
    use base qw(JOAP::Server::Class);
    use Error;

    # define class description

    MyPerson->Description(<<'END_OF_DESCRIPTION');
    Basic info on a person.
    END_OF_DESCRIPTION

    # define class attributes

    MyPerson->Attributes (
        {
            given_name => {
                type => 'string',
                required => 1,
                desc => 'Given name of the person.'
            },

            family_name => {
                type => 'string',
                required => 1,
                desc => 'Family name of the person.'
            },

            birthdate => {
                type => 'dateTime.iso8601',
                required => 1,
                desc => 'birthdate of person in GMT'
            },

            age => {
                type => 'i4',
                writable => 0,
                desc => 'Age in years (rounded down) of person at current time',
            },

            species => {
                type => 'string',
                writable => 0,
                allocation => 'class',
                desc => 'species of people'
            },
        });

    # specify methods

    MyPerson->Methods (
        {
            walk => {
                returnType => 'boolean',
                params => [
                    {
                        name => 'steps',
                          type => 'i4',
                          desc => 'how many steps forward to walk, fault if less than zero'
                    }
                ],
                desc => 'Walk forward \'steps\' steps'},
        });

    # specify the class ID

    MyPerson->Id(['family_name', 'given_name']);

    # specify class variables

    our $species = 'homo sapiens';

    # an accessor for an attribute

    sub age {

        my $self = shift;
        my $bd = $self->birthdate;
        my @now = gmtime;

        my @then = JOAP->datetime_to_array($bd);

        my ($y, $m, $d) = ($then[5], $then[4], $then[3]);

        my $age = $now[5] - $y;

        if (($now[4] > $m) ||
            ($now[4] == $m && $now[3] >= $d))
        {
            $age++;
        }

        return $age;
    }

    # an instance method

    sub walk {

        my $self = shift;
        my $steps = shift;

        if ($steps < 0) {
            throw Error::Simple("Never go back.", 5440);
        }

        for (my $i = 0; $i < $steps; $i++) {
            $self->step();
        }

        return 1;
    }

    1;                          # gotta return 1

=head1 ABSTRACT

This is an abstract superclass for creating Perl classes that are
servable through JOAP.

=head1 DESCRIPTION

Well, I haven't been looking forward to writing this POD, but here we
go.

JOAP::Server::Class is the pulsing heart of the JOAP server-side
universe. You use it to create your own JOAP-servable classes, and
things should just work.

The key part of this framework is that you define your class's
structure -- its attributes, methods, and superclasses -- using class
mutators in your class module. The server framework uses this
structural definition to expose your class to the Jabber network, and
handles all JOAP and XML-RPC messages for you. It routes requests for
attributes and methods to the appropriate part of your class
automatically, and it will create data, and methods, in the right
places if you just leave everything at the defaults.

The basic model is that your Perl class becomes a JOAP class, and each
Perl instance becomes a JOAP instance. Instance data is stored in the
instance, and class data is stored in the class. It's pretty simple.

There's also an interface that's exposed to object servers; it's not
documented here (yet).

=head2 Class Methods

This section discusses the class methods you need to call to define
your class. Usually you just call them straight from the class module,
as shown above in the synopsis.

=over

=item Description($string)

Sets the human-readable description of the class.

=item Attributes($hashref)

This sets the publicly available attributes for the class. $hashref is
a reference to a hashtable mapping attribute names to attribute
descriptors. See L<JOAP::Descriptors> for the format of this data
structure.

Besides the fields listed there, the attribute descriptor can also
contain the following fields:

=over

=item getter

This is the name of, or a reference to, a method that returns the
value of the attribute. If no getter is defined, the method in this
package with the same name as the attribute is used. If no such method
is defined, an autoloaded method is defined at runtime (see
L</Autoloaded Accessors> below for details).

=item setter

This is the name of, or a reference to, a method that sets the value
of the attribute. If no setter is defined, the method in this package
with the same name as the attribute is used. If no such method is
defined, an autoloaded method is defined at runtime (see L</Autoloaded
Accessors> below for details).

=item accessor

This is the name of, or a reference to, a method that acts as both
'getter' and 'setter'.

=back

=item Methods($hashref)

This sets the publicly available methods for the class. $hashref is a
reference to a hashtable mapping method names to method descriptors;
see L<JOAP::Descriptors> for the format of method descriptors.

As well as the fields described normally for method descriptors, the
following fields are also used:

=over

=item function

This is the name of, or reference to, a function that acts as this
method. If the field is not provided, the function with the same name
in this package will be used.

=back

=item Superclasses($arrayref)

This sets the visible superclasses for the class. $arrayref is a
reference to an array of strings containing the JOAP addresses of all
superclasses of the class. See L<JOAP::Addresses> for the format of
JOAP addresses.

=item Id($arrayref)

This sets the attributes that will be used to construct instance IDs
for instances of this class. $arrayref is a reference to an array of
attribute names. The IDs will be used in the order defined.

If IdFormat (see below) is defined, that printf-style format string
will be used to construct the instance of the object, with the values
of the listed attributes as parameters. Otherwise, a string will be
constructed joining the values of each attribute with the separator
defined by Separator (see below).

The combination of the attributes used in the Id array should be
sufficient to uniquely identify an instance.

=item IdFormat($fmt)

Sets the string used for formatting the instance IDs. This is a
L<perlfunc/printf> format string. The value of each attribute in
the array will be given, in order, as parameters.

Note that support for this feature is spotty right now; using
Separator below is your safest bet for the near future.

=item Separator($sep)

Sets the string used to separate attributes in the instance
ID. Defaults to ',', but you may want to set it to another value for
classes where, say, a comma may appear in the attribute data.

=back

=head3 Container Interface

This class also has an interface that containers can use to retrieve
instances of the class.

=over

=item Package->get($instid)

This method returns the instance object that has the given instance
ID, or undef if no such instance exists.

=back

=head3 Storage Interface

By default, instances are stored B<in memory> in a hashtable that maps
instance IDs to the instances themselves. This is pretty losey,
doesn't persist the instances through program invocations, and could
stand a lot of work. The interface used internally by
JOAP::Server::Class to retrieve instances looks like this:

=over

=item Package->get_instance($instid)

Returns the instance that has instance ID $instid, or undef if such an
instance doesn't exist.

=item Package->set_instance($instid, $inst)

Maps the instance $inst to instance ID $instid.

=item Package->delete_instance($instid)

Removes the instance with instance ID $instid from the storage map.

=back

=head2 Autoloaded Accessors

If a C<getter> or C<setter> is not defined for an attribute named in
the Attributes map, the JOAP server libraries try to use a function by
the same name as a Perl method to retrieve or set the attribute. You
can use this for attributes that are calculated from the values of
other attributes, like the C<age> attribute in the synopsis above.

If no Perl method by the same name is defined, the library creates a
method to act as an accessor. This happens when the attribute is first
used.

The default autoloaded accessor for instance attributes will store the
attribute value as a field in the instance. For class attributes, the
value will be stored as a symbol in the class package. The C<$species>
attribute in the synopsis is an example of a class attribute in the
package's namespace.

It's generally better practice to use accessors for attributes in your
custom code, rather than using the instance fields or class variables
directly.

=head2 Custom Accessors

As mentioned above, you can define custom accessors if simple data
storage is not sufficient, or if you need to define side-effects from
setting or getting an attribute. (For example, the synopsis above
shows an age attribute defined with a custom accessor that calculates
the value from the birthdate attribute. An alternative would be a
custom accessor for birthdate that calculates and sets the value of
age whenever birthdate is updated.)

Accessors will be called like:

    $self->accessor($value)

...for setting the value, and:

    $value = $self->accessor

...for getting the value. $self will be an instance of the class for
attributes with allocation 'instance', and the class itself for
attributes with allocation 'class'.

Accessors will never be called to set the value of an attribute if
that attribute has its writable flag set to 0.

=head2 Custom Methods

If your class exposes methods for public use, you need to define
custom code for those methods. Your method will be called like:

    $return_value = $self->method($param1, $param2, ...)

Here, $self is either an instance of this class, if the method
allocation is 'instance', or the class itself, if the method
allocation is 'class'. The parameters will be the parameters defined
in the params field, in order.

Your method will never be called with parameters of the wrong type, or
with the wrong number of parameters. That's handled at the library
level.

As mentioned above, for each method, you can either define an
eponymous method in the package, or you can use the C<function> field
of the method descriptor to map another function in as the method.

If there are problems with your method, you can throw an Error
exception as defined in L<Error>. The C<value> and C<text> of the
Error will be mapped to the faultCode and faultString in the resulting
XML-RPC fault.

=head2 Data Marshalling

In your custom code, you shouldn't normally have to worry about JOAP's
funky data types in your custom code. All parameters and attribute
values your code receives as input will already have been marshalled
to native Perl types. You can return values as Perl types, and they'll
be marshalled to the correct JOAP data type.

Some caveats, though:

=over

=item array

Arrays are handled by reference. You should return references to
arrays as return values, and you'll receive references to arrays as
input.

=item struct

Structs are marshalled to hash references. You should return
references to hashes as return values, and you'll receive references
to hashes as input.

=item dateTime.iso8601

These values are B<not> marshalled into any native Perl type, since
there's not really a good native type to marshall them into. Instead,
they come in as ISO 8601 formatted strings. You can use the
C<JOAP->datetime_to_array> method to convert this to an array like the
one returned by L<perlfunc/gmtime>. You can return references to
gmtime-like arrays, or just integers in seconds-since-the-epoch format
(as returned by L<perfunc/time>), or as formatted strings.

=back

=head2 EXPORT

None by default.

=head1 BUGS

This documentation is woefully insufficient.

There's currently no persistence built in to this class, and there's
no documentation on how to implement your own persistence (although
it's possible).

There's no documentation on how to build on-the-fly classes that act
as a gateway to non-JOAP object systems.

=head1 SEE ALSO

See L<JOAP> for general information about JOAP as well as contact
information for the author.

See L<Error> for how to throw Error exceptions.

See L<JOAP::Server::Object> for a bit more information about how this
class works.

See L<JOAP::Server> for defining object servers.

=head1 AUTHOR

Evan Prodromou, E<lt>evan@prodromou.san-francisco.ca.usE<gt>

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

