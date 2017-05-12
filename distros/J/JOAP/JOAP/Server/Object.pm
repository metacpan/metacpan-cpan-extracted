# JOAP::Server::Object -- Base Class for Things Servable By JOAP Servers
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

# tag: JOAP server object base class

package JOAP::Server::Object;
use base qw/Exporter Class::Data::Inheritable/;

use 5.008;
use strict;
use warnings;
use Net::Jabber qw/Component/;
use JOAP;
use Error qw(:try);
use Symbol;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;
our $AUTOLOAD;

# Class data

JOAP::Server::Object->mk_classdata('Description');
JOAP::Server::Object->mk_classdata('Attributes');
JOAP::Server::Object->mk_classdata('Methods');

# Set these up -- default to none

JOAP::Server::Object->Description(undef);
JOAP::Server::Object->Attributes({});
JOAP::Server::Object->Methods({});

# Simple, straightforward constructor. I think.

sub new {

    my($proto) = shift;
    my($class) = ref($proto) || $proto;
    my($self) = {};

    bless($self, $class);

    %$self = (ref($proto)) ? %$proto : @_;

    return $self;
}

# Translucent accessor. If this is an object, and there are attributes
# defined for the object, use those. Otherwise, return the class's
# attribute descriptor hash.
# For classes, just passes through to Attributes.

sub attributes {

    my($self) = shift;

    if (ref($self)) {
        $self->{attributes} = shift if @_;
        return (defined $self->{attributes}) ?
          $self->{attributes} : $self->Attributes;
    } else {
        return $self->Attributes(@_);
    }
}

# Like attributes, except for methods.

sub methods {

    my($self) = shift;

    if (ref($self)) {
        $self->{methods} = shift if @_;
        return (defined $self->{methods}) ?
          $self->{methods} : $self->Methods;
    } else {
        return $self->Methods(@_);
    }
}

# similarly for the description

sub description {

    my($self) = shift;

    if (ref($self)) {
        $self->{description} = shift if @_;
        return (defined $self->{description}) ?
          $self->{description} : $self->Description;
    } else {
        return $self->Description(@_);
    }
}

# What to do when we get an IQ.

sub on_iq {
    my($self) = shift;
    my($iq) = shift;
    my($ns) = $iq->GetQuery()->GetXMLNS();

    if ($ns eq 'jabber:iq:rpc') {
        return $self->on_method($iq);
    } elsif ($ns eq $JOAP::NS) {
        my($verb) = $iq->GetQuery()->GetTag();
        if ($verb eq 'read') {
            return $self->on_read($iq);
        } elsif ($verb eq 'edit') {
            return $self->on_edit($iq);
        } elsif ($verb eq 'add') {
            return $self->on_add($iq);
        } elsif ($verb eq 'search') {
            return $self->on_search($iq);
        } elsif ($verb eq 'delete') {
            return $self->on_delete($iq);
        } elsif ($verb eq 'describe') {
            return $self->on_describe($iq);
        }
    }

    return undef;
}

# Everything can be read, so we implement here.  Since this is pretty
# complete, subclasses should probably just implement the attribute_*
# methods.

sub on_read {

    my($self) = shift;
    my($reqiq) = shift;

    my $respiq = $self->reply($reqiq);

    if (my($code, $text) = $self->_validate_read($reqiq)) {
	$respiq->SetType('error');
	$respiq->SetErrorCode($code);
	$respiq->SetError($text);
	return $respiq;
    }

    # use the names in the request, or default read names.

    my @names = $reqiq->GetQuery->GetName;

    if (!@names) {
	 @names = $self->_attribute_read_names;
    }

    my($resp) = $respiq->GetQuery;

    foreach my $respattr (@names) {
        my $value = $self->_attribute_get_value($respattr);
        my $v = $resp->AddAttribute(name => $respattr)->AddValue();
	# I wish there were an easier way to do this
	JOAP->copy_value($value, $v);
    }

    $resp->SetTimestamp($self->timestamp());

    return $respiq;
}


# Everything can be edited, so we implement here.  Since this is
# pretty complete, subclasses should probably just implement the
# attribute_* methods.

sub on_edit {

    my($self) = shift;
    my($reqiq) = shift;

    my($respiq) = $self->reply($reqiq);

    if (my($code, $text) = $self->_validate_edit($reqiq, $respiq)) {
	$respiq->SetType('error');
	$respiq->SetErrorCode($code);
	$respiq->SetError($text);
	return $respiq;
      }

    # Set the values.

    foreach my $toset ($reqiq->GetQuery->GetAttribute) {
        $self->_attribute_set_value($toset->GetName(), $toset->GetValue());
    }

    # Return the response.

    return $respiq;
}

# everything can be described, and the mechanism is simple, so we do
# it here.  subclasses like ::Server and ::Class add on extra info
# after calling this default.

sub on_describe {

    my($self) = shift;
    my($reqiq) = shift;
    my($respiq) = $self->reply($reqiq);
    my($desc) = $respiq->GetQuery;

    if ($reqiq->GetType ne 'get') {
	$respiq->SetType('error');
        $respiq->SetErrorCode(406); # Not acceptable
        $respiq->SetError('Describe verbs must have type get');
        return $respiq;
    }

    if ($self->description) {
        $desc->SetDesc($self->description);
    }

    foreach my $name ($self->_attribute_names()) {
        $desc->AddAttributeDescription(name => $name,
                                         type => $self->_attribute_type($name),
                                         writable => $self->_attribute_writable($name),
                                         required => $self->_attribute_required($name),
                                         allocation => $self->_attribute_allocation($name),
                                         desc => $self->_attribute_desc($name));
    }

    foreach my $meth ($self->_method_names()) {

        my $m = $desc->AddMethodDescription(name => $meth,
	    returnType => $self->_method_returntype($meth),
	    allocation => $self->_method_allocation($meth),
	    desc => $self->_method_desc($meth));

	my $p = $m->AddParams();

	foreach my $param (@{$self->_method_params($meth)}) {
	    $p->AddParam(name => $param->{name},
		type => $param->{type},
		desc => $param->{desc});
	}
    }

    # subclasses will use this to add superclasses, classes

    return $respiq;
}

# This can only be sent to instances, so by default we return a 405.

sub on_delete {

    my($self) = shift;
    my($iq) = shift;
    my($respiq) = $self->reply($iq);

    $respiq->SetType('error');
    $respiq->SetErrorCode(405);  # Not allowed
    $respiq->SetError("Not allowed.");

    return $respiq;
}

# This can only be sent to classes, so by default we return a 405.

sub on_add {

    my($self) = shift;
    my($iq) = shift;
    my($respiq) = $self->reply($iq);

    $respiq->SetType('error');
    $respiq->SetErrorCode(405);  # Not allowed
    $respiq->SetError("Not allowed.");

    return $respiq;
}

# This can only be sent to classes, so by default we return a 405.

sub on_search {

    my($self) = shift;
    my($iq) = shift;
    my($respiq) = $self->reply($iq);

    $respiq->SetType('error');
    $respiq->SetErrorCode(405);  # Not implemented
    $respiq->SetError("Not allowed.");  # Not implemented

    return $respiq;
}

# This is called when we get a method.

sub on_method {

    my $self = shift;
    my $iq = shift;
    my $respiq = $self->reply($iq);

    if (my($code, $text) = $self->_validate_method($iq)) {
	$respiq->SetType('error');
	$respiq->SetErrorCode($code);
	$respiq->SetError($text);
	return $respiq;
    }

    my $query = $iq->GetQuery;
    my $call = $query->GetMethodCall;
    my $meth = $call->GetMethodName;
    my $fn = $self->_method_function($meth);

    my @actuals = $call->GetParams->GetParams; # Ugh, that's so dumb

    my @trans = map {JOAP->decode($_->GetValue)} @actuals;

    my $resp = $respiq->GetQuery->AddMethodResponse;
    my @results;

    try {
	@results = $self->$fn(@trans);
	my $v = $resp->AddParams->AddParam->AddValue;
	JOAP->copy_value(JOAP->encode($self->_method_returntype($meth), @results), $v);
    } catch Error with {
	my $err = shift;
	my $str = $resp->AddFault->AddValue->AddStruct;
        $str->AddMember(name => 'faultCode')->AddValue(i4 => $err->value);
        $str->AddMember(name => 'faultString')->AddValue(string => $err->text);
    };

    return $respiq;
}

# Utility to create replies; By default, Net::Jabber::IQ leaves all
# the bits inside the query in the reply, too. And "Remove" doesn't
# work for "children" elements.

sub reply {
    my $self = shift;
    my $iq = shift;

    my $reply = new Net::Jabber::IQ();

    $reply->SetTo($iq->GetFrom);
    $reply->SetFrom($iq->GetTo);
    $reply->SetID($iq->GetID) if $iq->GetID;
    $reply->SetType('result');

    my $query = $iq->GetQuery;
    $reply->NewQuery($query->GetXMLNS, $query->GetTag);

    return $reply;
}

# utility for creating timestamps

sub timestamp {

    my $self = shift;
    # just reuse the main modules conversion.
    return JOAP->coerce('dateTime.iso8601', time);
}

# This helps let subclasses add validation code

sub _validate_read {

    my $self = shift;
    my $reqiq = shift;

    if ($reqiq->GetType ne 'get') {
        return(406, 'Read verbs must have type get');
    }

    my(@attrs);
    @attrs = $self->_attribute_names();

    my(@names);
    @names = $reqiq->GetQuery()->GetName();

    my(@unmatched);

    @unmatched = grep { my($a) = $_; ! grep {/$a/} @attrs } @names;

    if (@unmatched) {
        return(406, join("\n", map {"No such attribute '$_'."} @unmatched));
    }

    return ();
}

# again, validation code can be done in subclasses

sub _validate_method {

    my $self = shift;
    my $iq = shift;

    if ($iq->GetType ne 'set') {
        return (406, 'RPC calls must be of type set');
    }

    my $query = $iq->GetQuery;
    my $call = $query->GetMethodCall;

    if (!$call) {
        return (406, 'No method call');
    }

    my $meth = $call->GetMethodName;

    if (!$meth) {
        return (406, 'No method name');
    }

    my $fn = $self->_method_function($meth);

    if (!$fn) {
	return (406, 'No such method');
    }

    my $params = $self->_method_params($meth);

    my @actuals = $call->GetParams->GetParams; # Ugh, that's so dumb

    if (scalar(@actuals) != scalar(@$params)) {
        return (406, 'Wrong number of parameters');
    }

    # check param types

    my $i;
    my @badvals;

    for ($i = 0; $i <= $#actuals; $i++) {
	if (! $self->_type_match($params->[$i]->{type}, $actuals[$i]->GetValue)) {
	    push @badvals, $params->[$i]->{name};
	}
    }

    if (@badvals) {
	return (406, join("\n", map { "Bad value for parameter $_" } @badvals));
    }

    # empty list means OK

    return ();
}

# validate an <edit>; validation code can be done in subclasses

sub _validate_edit {

    my $self = shift;
    my $reqiq = shift;

    if ($reqiq->GetType ne 'set') {
        return (406, 'Edit verbs must have type get');
    }

    my(@attrs);
    @attrs = $self->_attribute_names();

    my(@toset);
    @toset = $reqiq->GetQuery()->GetAttribute();

    my(@names);
    @names = map { $_->GetName() } @toset;

    # Check for attribute names that aren't in our object.

    my(@unmatched);
    @unmatched = grep { my($a) = $_; ! grep {/$a/} @attrs } @names;

    if (@unmatched) {
        return (406, join("\n", map {"No such attribute '$_'."} @unmatched));
    }

    # Check for stuff that isn't writable.

    my(@notallowed);
    @notallowed = grep { !$self->_attribute_writable($_) } @names;

    if (@notallowed) {
	return (403, join("\n", map {"Cannot edit attribute '$_'."} @notallowed));
    }

    # Check for attribute values that are of the wrong type, or
    # invalid in some other way.

    my(@notok);
    @notok = grep {!$self->_attribute_ok($_->GetName(), $_->GetValue())} @toset;

    if (@notok) {
	return (406, join("\n", map {"Value for attribute '" . $_->GetName . "' not acceptable."} @notok));
    }

    return ();
}

# a general attribute validator, used in _validate_* above

sub _attribute_ok {

    my $self = shift;
    my $name = shift;
    my $value = shift;

    my $type = $self->_attribute_type($name);

    # right now, just check for type match

    return $self->_type_match($type, $value);
}

# check to see if a value (as an XML thingy) matches the type

sub _type_match {

    my $self = shift;
    my $type = shift;
    my $value = shift;

    if ($type eq 'i4' || $type eq 'int') {
	return $value->DefinedI4 &&
          ($value->GetI4 =~ /^[+-]?\d+$/);
    }
    elsif ($type eq 'boolean') {
	return $value->DefinedBoolean &&
          ($value->GetBoolean =~ /^[10]$/);
    }
    elsif ($type eq 'string') {
	return $value->DefinedString; # can't mess up a string
    }
    elsif ($type eq 'double') {
	return $value->DefinedDouble &&
          ($value->GetDouble =~ /^(-?(?:\d+(?:\.\d*)?|\.\d+)|([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?)$/);
    }
    elsif ($type eq 'dateTime.iso8601') {
	return $value->DefinedDateTime &&
          (JOAP->datetime_to_array($value->GetDateTime));
    }
    elsif ($type eq 'struct') {
	return $value->DefinedStruct;
    }
    elsif ($type eq 'array') {
	return $value->DefinedArray;
    }
    elsif ($type eq 'base64') {
        return $value->DefinedBase64;
    }

    return undef;
}

# These methods are here to allow a JOAP server class (not necessarily
# ::Class!) to customize the admittedly primitive attribute definition
# method with a more robust mechanism.

sub _attribute_names {

    my $self = shift;

    # Attributes is a hash ref.

    return keys %{$self->attributes};
}

sub _attribute_read_names {
    my $self = shift;
    return $self->_attribute_names;
}

sub _attribute_descriptor {

    my ($self) = shift;
    my ($name) = shift;

    return $self->attributes->{$name};
}

sub _attribute_get_value {

    my($self) = shift;
    my($attr) = shift;

    my($type) = $self->_attribute_type($attr);
    my @raw = $self->_attribute_get($attr);

    return JOAP->encode($type, @raw);
}

sub _attribute_set_value {

    my($self) = shift;
    my($attr) = shift;
    my($value) = shift;

    my($raw) = JOAP->decode($value);

    return $self->_attribute_set($attr, $raw);
}

sub _attribute_get {

    my($self) = shift;
    my($attr) = shift;

    my($getter) = $self->_attribute_getter($attr);

    if (!$getter) {
      throw Error::Simple("No way to get attribute $attr");
    }

    no strict 'refs';

    return $self->$getter();
}

sub _attribute_set {

    my($self) = shift;
    my($attr) = shift;

    my(@value) = @_;
    my($setter) = $self->_attribute_setter($attr);

    # XXX: strict refs

    if (!$setter) {
      throw Error::Simple("No way to set attribute $attr");
    }

    no strict 'refs';

    return $self->$setter(@value);
}

# extract the fields of an attribute description. It's probably
# not really a great idea to try to overload them, since it's not
# guaranteed that they'll be used rather than just retrieving the
# field value in the descriptor directly.

sub _attribute_writable {
    my ($self) = shift;
    my ($attr) = shift;

    my ($desc) = $self->_attribute_descriptor($attr)  || return undef;

    return (!exists $desc->{writable}) ? 1 :
        $desc->{writable};
}

sub _attribute_required {
    my ($self) = shift;
    my ($attr) = shift;

    my ($desc) = $self->_attribute_descriptor($attr) || return undef;

    return (!exists $desc->{required}) ? 0 :
        $desc->{required};
}

sub _attribute_allocation {
    my ($self) = shift;
    my ($attr) = shift;

    my ($desc) = $self->_attribute_descriptor($attr)  || return undef;

    return (!exists $desc->{allocation}) ? 'instance' :
        $desc->{allocation};
}

sub _attribute_desc {
    my ($self) = shift;
    my ($attr) = shift;

    my ($desc) = $self->_attribute_descriptor($attr)  || return undef;

    return (!exists $desc->{desc}) ? undef :
        $desc->{desc};
}

sub _attribute_type {

    my($self) = shift;
    my($attr) = shift;

    my($desc) = $self->_attribute_descriptor($attr) || return undef;

    return $desc->{type};
}

# returns a "getter" method for the attribute. By default, the name of
# the getter is the name of the attribute. It can also be defined in
# the attribute description.

sub _attribute_getter {

    my($self) = shift;
    my($attr) = shift;
    my($desc) = $self->_attribute_descriptor($attr) || return undef;

    my($getter) = $desc->{getter} || $desc->{accessor} || $attr;

    return $getter;
}

# returns a "setter" method for the attribute. By default, the name of
# the setter is the name of the attribute. It can be defined in the
# attribute description.

sub _attribute_setter {

    my($self) = shift;
    my($attr) = shift;
    my($desc) = $self->_attribute_descriptor($attr) || return undef;

    my($setter) = $desc->{setter} || $desc->{accessor} || $attr;

    return $setter;
}

# These methods are here to allow a JOAP server class (not necessarily
# ::Class!) to customize the admittedly primitive method definition
# method with a more robust mechanism.

sub _method_names {

    my ($self) = shift;
    my ($name) = shift;

    # Methods is a hash ref

    return keys %{$self->methods};
}

sub _method_descriptor {

    my ($self) = shift;
    my ($name) = shift;

    # Methods is a hash ref

    return $self->methods->{$name};
}

# These just grab things from the descriptor, or make up semi-reasonable
# defaults.

sub _method_function {

    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name) ||
      return undef;

    return $desc->{function} || $self->can($name);
}

sub _method_returntype {
    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name) ||
      return undef;

    return $desc->{returnType} || 'array';
}

sub _method_params {

    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name) ||
      return undef;

    return $desc->{params} || {default => {type => 'array'}};
}

sub _method_allocation {

    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name) ||
      return undef;

    return $desc->{allocation} || 'instance';
}

sub _method_desc {

    my $self = shift;
    my $name = shift;

    my $desc = $self->_method_descriptor($name) ||
      return undef;

    return $desc->{desc};
}

# This allows us to say $self->can('autoloadedmethod'). AUTOLOAD (below)
# uses this method to create methods if necessary.

sub can {

    my($self) = shift;
    my($name) = shift;
    my($func) = $self->SUPER::can($name); # See if it's findable by standard lookup.

    if (!$func) {               # Otherwise, see if it's an attribute.
        my $desc = $self->_attribute_descriptor($name);
        if ($desc) {
            if (($self->_attribute_allocation($name) eq 'class')) {
		my $pkg = ref($self) || $self;
		my $globref = qualify_to_ref($pkg . "::" . $name);
		my $sref = *$globref{SCALAR};
                $func = sub {
		    my $self = shift;
                    return (@_) ? ($$sref = shift) : $$sref;
                };
            } elsif ($self->_attribute_allocation($name) eq 'instance' && ref($self)) {
                $func = sub {
                    my($self) = shift;
                    return (@_) ? ($self->{$name} = shift) : $self->{$name};
                };
            }
        }
    }

    return $func;
}

# use can() to build a closure, install it in the package, call it

sub AUTOLOAD {

    my ($self) = $_[0];
    my ($sub) = $AUTOLOAD;

    my ($pkg,$name) = ($sub =~ /(.*)::([^:]+)$/);
    my ($func) = $self->can($name);

    if ($func) {
	no strict 'refs';
	*$sub = $func; # save it for later
        goto &$sub;
    } else {
        throw Error::Simple("No method to get $name");
    }
}

# This keeps us from calling AUTOLOAD for DESTROY

sub DESTROY { }

1;
__END__

=head1 NAME

JOAP::Server::Object - Base Class for Things Servable By JOAP Servers

=head1 SYNOPSIS

    [N/A]

=head1 ABSTRACT

This verbosely-named OO package -- sorry about that -- is the base
class for object servers, classes, and instances inside a JOAP
server. It is probably not such a hunky-dory idea to inherit from this
class itself -- use JOAP::Server::Class or JOAP::Server
instead. However, it does lay out the framework for how those classes
works -- thus, this POD.

=head1 DESCRIPTION

When it comes down to it, JOAP is about defining objects and making
their attributes and methods available across the Jabber network. This
class does the meat of that.

(Unfortunate note: this is a Perl class for defining JOAP objects. It
uses Perl attributes to make JOAP attributes, and Perl methods to make
JOAP methods. The terminology is confusing, so I'll try and use the
prefixes 'Perl' and 'JOAP' where possible.)

There are three interfaces for this module.

=over

=item Container

This interface consists of a constructor and a set of 8 "handler"
methods, which are appropriate for folks who want to create JOAP
servers that can serve Perl classes (JOAP::Server is one
piece of software that uses this interface).

=item Simple Subclass

This interface is a set of rules for defining data and methods in a
Perl module that is a subclass of JOAP::Server::Object,
so that it can be seen by the world as a JOAP class.

This interface is documented in L<JOAP::Server> and
L<JOAP::Server::Class> for object servers and classes,
respectively. It's repeated here for completeness.

=item Complex Subclass

This interface is a whole bunch of itty-bitty methods that subclasses
can overload if they want to subvert the 'standard' way of defining a
JOAP server class in Perl. It'd be appropriate for, say, creating
gateways to other object systems, or having more robust and scalable
systems written in Perl than the one implemented here.

The complex subclass interface is still in flux and remains
undocumented for now.

=back

=head2 Simple Subclass Interface

This interface is how subclasses declare their methods, attributes,
and human-readable description to the library. JOAP::Server::Object
uses this information to validate incoming requests, and to format
outgoing responses. By using this interface, subclasses cut down on
the amount of JOAP-level hoohaw they have to deal with, and can
concentrate on application-specific logic that deals with marshalled
Perl values.

Application code B<SHOULD NOT> subclass from JOAP::Server::Object
directly. Use L<JOAP::Server> for object servers, and
L<JOAP::Server::Class> for classes and their instances.

=over

=item Description($string)

Sets the human-readable description of the object, which is returned
in 'describe' verbs. Note that JOAP allows multiple descriptions for
different human languages; this implementation does not, but that may
change in the future.

=item Attributes($hashref)

This sets the publicly available attributes for the object. $hashref
is a reference to a hashtable mapping attribute names to attribute
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

=back

=head2 Container Interface

The container interface is made up of one constructor, C<new>, and
eight "event" methods, to be called for events (presumably, when IQs
representing the events come in over a Jabber network, although it's
perfectly acceptable to use them for testing, too (or whatever)).

=over

=item Package->new(attrib1 => 'value 1', attrib2 => 'value 2', ...)

This creates a new object that's ready to receive events. The
attributes should be writable attributes declared in the package's
C<Attributes> class variable.

=item $obj->on_iq($iq)

Main dispatcher for Jabber IQ stanzas. The default implementation
checks the query tag and namespace and calls the more appropriate
specific event handler.

It returns a Jabber IQ stanza as a reply.

In general, containers should probably just call this, and let objects
do their own dispatching.

=item $obj->on_describe($iq)

This method takes an IQ that should be a JOAP 'describe' verb, and
returns a 'describe' verb containing the object's description.

The default behavior is to return a description with all attributes
and methods, as well as a timestamp. Subclasses like ::Server and
::Class add superclass or class information, as necessary.

It returns a Jabber IQ stanza as describe reply.

=item $obj->on_read($iq)

This method responds to a 'read' verb with the requested
attributes. The default implementation validates that requested
attribute names are appropriate, and then uses configured or
autoloaded accessors to determine the values of the attributes and
returns them. If no attribute names are passed in, it returns a
default set of attributes for the object.

It returns a Jabber IQ stanza as describe reply.

=item $obj->on_edit($iq)

Responds to an 'edit' verb. The default implementation checks that the
incoming attribute names and values are acceptable, and uses
configured or autoloaded mutators to set the values of the attributes.

As with other event handlers, this method returns a result IQ.

=item $obj->on_add($iq)

Responds to an 'add' verb. The default implementation returns an error
IQ, as only JOAP class objects respond to 'add'. The
L<JOAP::Server::Class> package overloads this to create and store a
new instance.

As with other event handlers, this method returns a result IQ.

=item $obj->on_search($iq)

Responds to a 'search' verb. The default implementation returns an
error IQ, as only JOAP class objects respond to 'search'. The
L<JOAP::Server::Class> package overloads this to search for instances
matching the search criteria specified in the IQ.

This method returns a result IQ.

=item $obj->on_delete($iq)

Responds to a 'delete' verb. The default implementation returns an
error IQ, as only JOAP class objects respond to 'search'. The
L<JOAP::Server::Class> package overloads this to delete an instance.

This method returns a result IQ.

=item $obj->on_method($iq)

Responds to a 'jabber:iq:rpc' RPC method. The default implementation
checks that the method is declared in the C<Methods> class variable,
and that the parameters of the IQ match the number and types of the
declared parameters. It then calls the declared or eponymous function
for the method, and returns the results.

If the function throws an L<Error>, the value and text of the error
are returned as an XML-RPC C<faultCode> and C<faultString>
respectively.

This method returns a 'jabber:iq:rpc' result IQ.

=back

=head2 Autoloaded Accessors

If a C<getter> or C<setter> or C<accessor> is not defined for an
attribute named in the Attributes map, the JOAP server libraries try
to use a function by the same name as a Perl method to retrieve or set
the attribute. If no Perl method by the same name is defined, the
library creates a method to act as an accessor. This happens when the
attribute is first used.

The default autoloaded accessor for instance attributes will store the
attribute value as a field in the instance. For class attributes, the
value will be stored as a symbol in the class package.

You can use this for attributes that are calculated from the values of
other attributes, or to create side-effects from getting or setting an
attribute.

It's generally better practice to use accessors for attributes in your
custom code, rather than using the instance fields or class variables
directly.

=head2 EXPORT

None by default.

=head1 BUGS

The default methods go poking around in subclasses to find classes,
attributes, methods, and so forth. This is probably the Wrong Thing
and will have Perl OO fanatics crawling all over me.

There's not a lot of validation of the input to the Simple Subclass
interface. This lets simple typos cause unexpected and
difficult-to-trace errors at run time rather than load time.

Using huge hashes-of-hashes and lists-of-hashes and stuff to do the
metadata is kind of clunky. I might try and figger out Perl-level
attributes (like 'lock' and 'method') to do these declarations
instead.

The complex subclass interface is untested, undocumented, and probably
insufficient.

The metadata stuff doesn't really handle Perl-level inheritance
well. You have to explicitly declare all attributes and methods, even
if you have a Perl superclass that already declares most or some of
them. This is probly the Wrong Thing, also.

=head1 SEE ALSO

Unless you really really have to, and you really really know what
you're doing, you probably shouldn't use this class directly. Most
people will need to use L<JOAP::Server::Class>, and folks creating new
JOAP servers would want to use L<JOAP::Server>.

Look at L<Error> to see how to throw an error from custom code.

L<Net::Jabber::IQ> contains more information on handling IQ stanzas.

L<JOAP> contains more general information, as well as contact
information for the author.

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
