# JOAP::Proxy -- Base Class for Things JOAP Clients Use
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

# tag: JOAP client object base class

package JOAP::Proxy;
use base qw/Exporter Class::Data::Inheritable/;

use 5.008;
use strict;
use warnings;
use Net::Jabber qw/Client/;
use JOAP;
use Error qw(:try);
use Symbol;
use JOAP::Proxy::Error;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;
our $AUTOLOAD;

JOAP::Proxy->mk_classdata('Connection');

sub get {

    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    my $address = shift;
    my $self = bless({_address => $address}, $pkg);

    $self->_read();

    return $self;
}

sub refresh {

    my $self = shift;

    # XXX: anything else?

    return $self->_read;
}

sub save {

    my $self = shift;

    # XXX: anything else?

    return $self->_edit;
}

sub address {
    my $self = shift;
    return $self->{_address};
}

sub timestamp {
    my $self = shift;
    return $self->{_timestamp};
}

sub _set_timestamp {
    my $self = shift;
    return $self->{_timestamp} = shift;
}

sub description {
    my $self = shift;
    return $self->{_description};
}

sub _set_description {
    my $self = shift;
    return $self->{_description} = shift;
}

sub attributes {
    my $self = shift;
    return (@_) ? $self->{_attributes} = shift : $self->{_attributes};
}

sub methods {
    my $self = shift;
    return (@_) ? $self->{_methods} = shift : $self->{_methods};
}

sub _attribute_descriptor {
    my $self = shift;
    my $name = shift;
    return $self->attributes->{$name};
}

sub _method_descriptor {
    my $self = shift;
    my $name = shift;
    return $self->methods->{$name};
}

sub _described {
    my $self = shift;
    return $self->timestamp;
}

sub _read {

    my $self = shift;
    my $con = $self->Connection;

    if (!$con) {
	throw JOAP::Proxy::Error::Local("No JOAP proxy connection set.");
    }

    if (!$self->_described) {
        $self->_describe;
    }

    my $iq = new Net::Jabber::IQ;

    $iq->SetTo($self->address);
    $iq->SetType('get');
    $iq->NewQuery($JOAP::NS, 'read');

    # XXX: configure to allow reading just some attributes

    my $resp = $con->SendAndReceiveWithID($iq);

    if ($resp->GetType eq 'error') {
	my $code = $resp->GetErrorCode;
	my $text = $resp->GetError;
	throw JOAP::Proxy::Error::Remote($text, $code);
    }

    my $read = $resp->GetQuery;

    my @attrs = $read->GetAttribute;

    foreach my $attr (@attrs) {
        my $name = $attr->GetName;
        # XXX: check returned attributes for type
        my $value = JOAP->decode($attr->GetValue);
        $self->_set($name, $value);
    }

    # FIXME: what should we return?

    return $resp;
}

sub _set {

    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{$name} = $value;
}

sub _edit {

    my $self = shift;
    my $con = $self->Connection;

    if (!$con) {
	throw JOAP::Proxy::Error::Local("No JOAP proxy connection set.");
    }

    if (!$self->_described) {
        $self->_describe;
    }

    my $iq = new Net::Jabber::IQ;

    $iq->SetTo($self->address);
    $iq->SetType('set');
    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    my $attrs = $self->_default_edit_attrs();

    while (my($name, $descriptor) = each %$attrs) {
        no strict 'refs';
        my $loc = $self->$name;
        use strict 'refs';
        my $tval = JOAP->encode($descriptor->{type}, $loc);
        my $val = $edit->AddAttribute(name => $name)->AddValue;
        JOAP->copy_value($tval, $val);
    }

    my $resp = $con->SendAndReceiveWithID($iq);

    if ($resp->GetType eq 'error') {
	throw JOAP::Proxy::Error::Remote($resp->GetError, $resp->GetErrorCode);
    }

    return $resp;
}

sub _default_edit_attrs {

    my $self = shift;

    my $attrs = $self->attributes;

    # find names of writable attributes

    my @writable = grep { $attrs->{$_}->{writable} } keys %$attrs;

    # make that into a hash

    my %write = map {($_, $attrs->{$_})} @writable;

    # return a reference to that hash

    return \%write;
}

sub _describe {

    my $self = shift;
    my $con = $self->Connection;

    if (!$con) {
	throw JOAP::Proxy::Error::Local("No JOAP proxy connection set.");
    }

    my $iq = new Net::Jabber::IQ;

    $iq->SetTo($self->address);
    $iq->SetType('get');
    $iq->NewQuery($JOAP::NS, 'describe');

    my $resp = $con->SendAndReceiveWithID($iq);

    if ($resp->GetType eq 'error') {
	throw JOAP::Proxy::Error::Remote($resp->GetError, $resp->GetErrorCode);
    }

    my $desc = $resp->GetQuery;

    # FIXME: handle multiple descriptions

    if ($desc->DefinedDesc) {
        $self->_set_description($desc->GetDesc);
    }

    my $attrs = {};

    my @attrdescs = $desc->GetAttributeDescription;

    foreach my $attrdesc (@attrdescs) {

        my $name = $attrdesc->GetName;
        my $type = $attrdesc->GetType;
        my $required = $attrdesc->GetRequired || 0;
        my $writable = $attrdesc->GetWritable || 0;
        my $allocation = $attrdesc->GetAllocation || 'instance';
        my $desc = $attrdesc->GetDesc || '';

	$attrs->{$attrdesc->GetName} = {name => $name,
                                        type => $type,
                                        required => $required,
                                        writable => $writable,
                                        allocation => $allocation,
                                        desc => $desc};
    }

    $self->attributes($attrs);

    my $meths = {};

    my @methdescs = $desc->GetMethodDescription;

    foreach my $methdesc (@methdescs) {
	$meths->{$methdesc->GetName} = {name => $methdesc->GetName,
                                        returnType => $methdesc->GetReturnType,
                                        allocation => $methdesc->GetAllocation,
                                        desc => $methdesc->GetDesc};

        my $params = [];
        my @params = $methdesc->GetParams->GetParams;

        foreach my $param (@params) {
            push @$params, {name => $param->GetName,
                            type => $param->GetType,
                            desc => $param->GetDesc};
        }

        $meths->{$methdesc->GetName}->{params} = $params;
    }

    $self->methods($meths);

    # save the timestamp

    $self->_set_timestamp($desc->GetTimestamp);

    return $resp;
}

# This allows us to say $self->can('autoloadedmethod'). AUTOLOAD (below)
# uses this method to create methods if necessary.

sub can {

    my($self) = shift;
    my($name) = shift;
    my($func) = $self->SUPER::can($name); # See if it's findable by standard lookup.

    if (!$func) { # if not, see if it's something we should make ourselves.
	if (my $methdesc = $self->_method_descriptor($name)) {
            $func = $self->_proxy_method($methdesc);
	} elsif (my $attrdesc = $self->_attribute_descriptor($name)) {
            $func = $self->_proxy_accessor($attrdesc);
        }
    }

    return $func;
}

sub _proxy_method {

    my $self = shift;
    my $methdesc = shift;

    my @param_types = map { $_->{type} } @{$methdesc->{params}};
    my $param_cnt = scalar(@param_types);

    my $name = $methdesc->{name};

    return sub {

        my $self = shift;

        my $con = $self->Connection || throw JOAP::Proxy::Error::Local("Can't call remote method if not connected.");

        my @args = @_;

        # XXX: allow named parameters if scalar(@args) == $param_cnt * 2

        if (scalar(@args) != $param_cnt) {
            throw JOAP::Proxy::Error::Local("Wrong number of parameters (need $param_cnt) for method '$name'.");
        }

        my $iq = new Net::Jabber::IQ;
        $iq->SetIQ(to => $self->address, type => 'set');

        my $mc = $iq->NewQuery('jabber:iq:rpc')->AddMethodCall;

        $mc->SetMethodName($name);

        my $params = $mc->AddParams;

        my $i;

        for ($i = 0; $i < $param_cnt; $i++) {
            my $pv = $params->AddParam->AddValue;
            my $tv = JOAP->encode($param_types[$i], $args[$i]);
            JOAP->copy_value($tv, $pv);
        }

        my $resp = $con->SendAndReceiveWithID($iq);

        if ($resp->GetType eq 'error') {
            throw JOAP::Proxy::Error::Remote($resp->GetError, $resp->GetErrorCode);
        }

        my $mr = $resp->GetQuery->GetMethodResponse;

        if ($mr->DefinedFault) {

            my $struct = $mr->GetFault->GetValue->GetStruct;
            my ($code, $text);

            foreach my $member ($struct->GetMembers()) {
                if ($member->GetName eq 'faultCode') {
                    $code = JOAP->decode($member->GetValue);
                } elsif ($member->GetName eq 'faultString'){
                    $text = JOAP->decode($member->GetValue);
                }
            }

            throw JOAP::Proxy::Error::Fault($text, $code);

        } else {
            # FIXME: check return type
            my @results = map { JOAP->decode($_->GetValue) } $mr->GetParams->GetParams;
            return @results;
        }
    };
}

sub _proxy_accessor {

    my $self = shift;
    my $descriptor = shift;

    my $name = $descriptor->{name};
    my $writable = $descriptor->{writable};
    my $type = $descriptor->{type};

    my $func = undef;

    if ($writable) {
        $func = sub {
            my $self = shift;
            return (@_) ? $self->{$name} = JOAP->coerce($type, shift) : $self->{$name};
        };
    } else {
        $func = sub {
            my $self = shift;
            if (@_) {
                throw JOAP::Proxy::Error::Local("Can't modify read-only attribute $name.");
            }
            return $self->{$name};
        };
    }

    return $func;
}

sub AUTOLOAD {

    my ($self) = $_[0];
    my ($sub) = $AUTOLOAD;

    my ($pkg,$name) = ($sub =~ /(.*)::([^:]+)$/);
    my ($func) = $self->can($name);

    if ($func) {
        &$func(@_);
    } else {
        throw JOAP::Proxy::Error::Local("No attribute or method '$name'");
    }
}

# skip autoload hoohaw for DESTROY

sub DESTROY { }

1; # of these days, Alice

__END__

=head1 NAME

JOAP::Proxy - Base class for client-side proxies of JOAP objects

=head1 SYNOPSIS

  use Net::Jabber qw(Client);
  use JOAP::Proxy;

  # set up a Net::Jabber connection (your responsibility)

  sub jabber_con {

    my $user = shift;
    my $server = shift;
    my $password = shift;
    my $port = shift || 5222;
    my $resource = shift || 'JOAPProxy';

    if (!$user || !$server || !$password) {
        return undef;
    }

    my $con = new Net::Jabber::Client;

    my $status = $con->Connect(hostname => $server,
                               port => $port);

    if (!(defined($status))) {
        return undef;
    }

    my @result = $con->AuthSend(username => $user,
                                password => $password,
                                resource => $resource);

    if ($result[0] ne "ok") {
        $con->Disconnect;
        return undef;
    }

    $con->RosterGet();
    $con->PresenceSend(priority => 0);

    return $con;
  }

  my $con = jabber_con('me', 'example.com', 'very secret') ||
    die("Can't connect.");

  # Make that available to all proxy objects

  JOAP::Proxy->Connection($con);

=head1 ABSTRACT

This is an abstract base class for local, client-side proxies to
remote JOAP objects -- object servers, classes, and instances. It
provides some default behavior for subclasses, and contains a class
variable for Jabber connectivity, but otherwise it should not be used
directly.

=head1 DESCRIPTION

All of the classes that proxy for remote JOAP objects are subclasses
of JOAP::Proxy. This package defines a lot of common behavior, but
almost none of it should be used directly. Consequently, the
appropriate methods and such are documented in the subclasses; see
below for links to these classes.

=head2 Class Methods

There's really only one method in this package that you should care
about, and that's the one to set up the Jabber connection used by all
the proxies.

=over

=item Connection

=item Connection($con)

This is the Jabber connection used to send and receive messages about
proxy information. You should use this method as a mutator in your
programs as early as possible, and definitely before using any of the
other proxy classes.

The argument $con is a L<Net::Jabber::Protocol> object. It can be a
L<Net::Jabber::Client> object or a L<Net::Jabber::Component> object,
and possibly even a L<Net::Jabber::Server> object if you're adventurous.

The synopsis above has a good example of setting up the
connection. You should avoid setting any callbacks on the connection,
or at least setting any that interfere with JOAP's namespace or the
'jabber:iq:rpc' namespace.

This is a translucent, inheritable class data accessor. What that
means is that you can, in theory, set the C<Connection> class
attribute for subclasses of this package, and it will only affect that
subclass. For example:

  package FooProxy;
  use JOAP::Proxy::Package::Class;
  use base qw(JOAP::Proxy::Package::Class);

  FooProxy->Address('Foo@bar.example.com'); # say what class this is proxying for

  package main;

  # set up the connection for all proxies

  my $con1 = jabber_con('me', 'example.com', 'very secret') ||
    die("Can't connect.");

  JOAP::Proxy->Connection($con1);

  # set up a different connection just for foo proxies

  my $con2 = jabber_con('you', 'example.net', 'also secret') ||
    die("Can't connect.");

  JOAP::Proxy->Connection($con2);

This is pretty untested, and I wouldn't rely on it too much if I were
you. But the possibility is there to use different connections for
different proxy packages.

=back

=head1 EXPORT

None by default.

=head1 SEE ALSO

You can create a proxy for a remote JOAP object server using
L<JOAP::Proxy::Package::Server> (preferred) or L<JOAP::Proxy::Server>.

You can create a proxy for a remote JOAP class using
L<JOAP::Proxy::Package::Class> (preferred) or L<JOAP::Proxy::Class>.

You can create a proxy for a remote JOAP instance using
L<JOAP::Proxy::Package::Class> (preferred) or L<JOAP::Proxy::Instance>.

L<JOAP> has more general JOAP information, as well as bug-reporting
and contact information.

L<Net::Jabber> has more information on setting up, and tearing down,
Jabber connections.

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
