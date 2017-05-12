# JOAP::Server -- Base Class for JOAP Object Servers
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

# tag: JOAP server class

package JOAP::Server;
use base qw/Exporter JOAP::Server::Object/;

use 5.008;
use strict;
use warnings;
use Net::Jabber qw/Component/;
use JOAP;
use JOAP::Server::Object;

# necessary Exporter hoohaw

our %EXPORT_TAGS = ( 'all' => [ ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = $JOAP::VERSION;

JOAP::Server->mk_classdata('Name');
JOAP::Server->mk_classdata('Version');
JOAP::Server->mk_classdata('Classes');

JOAP::Server->Name('JOAP::Server');
JOAP::Server->Version($VERSION);
JOAP::Server->Classes({});

# These are a couple of default attributes, kinda just for show.

sub version_info;

JOAP::Server->Attributes(
    {time => {type => 'dateTime.iso8601',
              writable => 0,
              getter => \&time_info,
	      desc => 'Current time at this server.'},
    version => {type => 'struct',
	        writable => 0,
	        getter => \&version_info,
	        desc => 'Version info for this server. Name of software and version number.'},
    });

sub new {

    my($proto) = shift;
    my($package) = ref($proto) || $proto;
    my($self) = JOAP::Server::Object::new($package, @_);

    $self->{component} = new Net::Jabber::Component(@_)
      unless $self->{component};

    $self->{component}->SetIQCallBacks($JOAP::NS =>
                                       {
                                        get => sub { $self->handle_joap($_[1]) },
                                        set => sub { $self->handle_joap($_[1]) },
                                       },
                                       'jabber:iq:rpc' =>
                                       {
                                        set => sub { $self->handle_joap($_[1]) },
                                       });

    $self->{component}->Info($self->name, $self->version);

    return $self;
}

# Just pass these through to the component.

sub execute { shift->{component}->Execute(@_) }
sub connect { shift->{component}->Connect(@_) }
sub disconnect { shift->{component}->Disconnect(@_) }
sub connected { shift->{component}->Connected(@_) }

# translucent accessors

sub name {

    my($self) = shift;

    if (ref($self)) {
        $self->{name} = shift if @_;
        return (defined $self->{name}) ?
          $self->{name} : $self->Name;
    } else {
        return $self->Name(@_);
    }
}

sub version {

    my($self) = shift;

    if (ref($self)) {
        $self->{version} = shift if @_;
        return (defined $self->{version}) ?
          $self->{version} : $self->Version;
    } else {
        return $self->Version(@_);
    }
}

sub classes {

    my($self) = shift;

    if (ref($self)) {
        $self->{classes} = shift if @_;
        return (defined $self->{classes}) ?
          $self->{classes} : $self->Classes;
    } else {
        return $self->Classes(@_);
    }
}

sub version_info {
    my $self = shift;
    return {name => $self->name, version => $self->version};
}

sub time_info {
    my $self = shift;
    return time;
}

sub on_joap {

    my $self = shift;
    my $iq = shift;

    my $recipient = $self->_jid_to_object($iq->GetTo('jid'));

    my $respiq = undef;

    if (!$recipient) {
	$respiq = $self->reply($iq);
	$respiq->SetType('error');
	$respiq->SetErrorCode(404); # not found
	$respiq->SetError('Not found');
    }
    else {
	$respiq = $recipient->on_iq($iq);
    }

    return $respiq;
}

sub handle_joap {

    my $self = shift;
    my $iq = shift;

    my $respiq = $self->on_joap($iq);

    $self->{component}->Send($respiq) if ($respiq);

    my $le = $self->log_entry($iq, $respiq);

    # XXX: use Net::Jabber::Log instead of debug

    $self->{component}->{DEBUG}->Log0($le);
}

# We have to add classes.

sub on_describe {

    my($self) = shift;
    my($iq) = shift;
    my($respiq) = $self->SUPER::on_describe($iq);

    my $addr = $iq->GetTo;

    if ($respiq->GetType() ne 'error') { # If that worked out OK...
	my $qry = $respiq->GetQuery;
        foreach my $class (keys %{$self->Classes}) {
	    my $jid = new Net::Jabber::JID($addr);
	    $jid->SetUserID($class);
            $qry->SetClass($jid->GetJID('full'));
        }
	$qry->SetTimestamp($self->timestamp);
    }

    return $respiq;
}

sub make_address {

    my($self) = shift;
    my(%args) = @_;

    my($jid) = new Net::Jabber::JID();

    $jid->SetServer(($args{server}) ? $args{server} : $self->componentname);

    $jid->SetUserID(($args{classname}) ? $args{classname} :
                    ($args{class}) ? $self->get_class($args{class}) :
                    ($args{instance}) ? $self->get_class(ref($args{instance})) : undef);

    $jid->SetResource(($args{instid}) ? $args{instid} :
                      ($args{instance}) ? $args{instance}->id() : undef);
}

sub get_class {

    my($self) = shift;
    my($classname) = shift;

    return $self->classes->{$classname};
}

# Note: this is kind of dodgy, since more than one classname can come
# to a class.

sub get_classname {

    my($self) = shift;
    my($class) = shift;

    my %rev = (reverse %{$self->classes});

    return $rev{$class};
}

sub _jid_to_object {

    my($self) = shift;
    my($jid) = shift;

    my($classname) = $jid->GetUserID();

    if (!$classname) {
        return $self;           # Stuff without a classname is for the server
    } else {

        my($class) = $self->get_class($classname);

        return undef unless $class;

	# XXX: require class here?

        my($instid) = $jid->GetResource();

        if ($instid) {
            return $class->get($instid);
        } else {
            return $class;
        }
    }
}

# XXX: make this work with jabberd component logging

sub log_entry {

    my $self = shift;
    my $iq = shift;
    my $resp = shift;
    my $le = {};

    my $timestamp = JOAP->int_to_datetime(time);
    my $from = $iq->GetFrom;
    my $to = $iq->GetTo;
    my $input = $self->_summarize_input($iq);
    my $output = $self->_summarize_output($resp);
    my $error = $self->_error($resp);

    # FIXME: print to a configurable log file

    return sprintf("%s : \"%s\" - \"%s\" : %s -> %s (%s)", $timestamp, $from, $to,
      $input, $output, $error);
}

sub _error {

    my $self = shift;
    my $iq = shift;

    if ($iq->GetType ne 'error') {
	return "OK";
    }
    else {
	return $iq->GetErrorCode;
    }
}

sub _summarize_input {

    my $self = shift;
    my $iq = shift;
    my $ns = $iq->GetQuery->GetXMLNS;

    if ($ns eq 'jabber:iq:rpc') {
	return $self->_summarize_method_in($iq);
    } elsif ($ns eq $JOAP::NS) {
        my($verb) = $iq->GetQuery->GetTag;
        if ($verb eq 'read') {
            return $self->_summarize_read_in($iq);
        } elsif ($verb eq 'edit') {
            return $self->_summarize_edit_in($iq);
        } elsif ($verb eq 'add') {
            return $self->_summarize_add_in($iq);
        } elsif ($verb eq 'search') {
            return $self->_summarize_search_in($iq);
        } elsif ($verb eq 'delete') {
            return $self->_summarize_delete_in($iq);
        } elsif ($verb eq 'describe') {
            return $self->_summarize_describe_in($iq);
        }
    }

    return undef;
}

sub _summarize_output {

    my $self = shift;
    my $iq = shift;
    my $ns = $iq->GetQuery->GetXMLNS;

    if ($iq->GetType eq 'error') {
	return $iq->GetError;
    } else {
	if ($ns eq 'jabber:iq:rpc') {
	    return $self->_summarize_method_out($iq);
	} elsif ($ns eq $JOAP::NS) {
	    my($verb) = $iq->GetQuery->GetTag;
	    if ($verb eq 'read') {
		return $self->_summarize_read_out($iq);
	    } elsif ($verb eq 'edit') {
		return $self->_summarize_edit_out($iq);
	    } elsif ($verb eq 'add') {
		return $self->_summarize_add_out($iq);
	    } elsif ($verb eq 'search') {
		return $self->_summarize_search_out($iq);
	    } elsif ($verb eq 'delete') {
		return $self->_summarize_delete_out($iq);
	    } elsif ($verb eq 'describe') {
		return $self->_summarize_describe_out($iq);
	    }
	}
    }

    return undef;
}

sub _summarize_method_in {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my $call = $qry->GetMethodCall || return "(method -- bad format)";
    my $name = $call->GetMethodName || return "(method -- bad format)";

    my @actuals = $call->GetParams->GetParams;

    my @params = map { $self->_summarize_param($_) } @actuals;

    return "method $name (" . join(", ", @params) . ")";
}

sub _summarize_method_out {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my $resp = $qry->GetMethodResponse || return "(method -- bad format)";

    if ($resp->DefinedFault) {
	my $fs = JOAP->decode($resp->GetFault->GetValue);
	return ("FAULT #" . $fs->{faultCode} . ": " . $fs->{faultString});
    }
    else {
	my @actuals = $resp->GetParams->GetParams;
	my @params = map { $self->_summarize_param($_) } @actuals;
	return "(" . join(", ", @params) . ")";
    }
}

sub _summarize_read_in {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my @names = $qry->GetName;

    return "read (" . ((@names) ? join(", ", @names) : "*") . ")";
}

sub _summarize_read_out {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my @attrs = $qry->GetAttribute;

    my @attrsums = map { $self->_summarize_attr($_) } @attrs;

    return "(" . join(", ", @attrsums) . ")";
}

sub _summarize_edit_in {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my @attrs = $qry->GetAttribute;

    my @attrsums = map { $self->_summarize_attr($_) } @attrs;

    return "edit (" . join(", ", @attrsums) . ")";
}

sub _summarize_edit_out {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;

    if ($qry->DefinedNewAddress) {
	return $qry->GetNewAddress;
    } else {
	return "";
    }
}

sub _summarize_add_in {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my @attrs = $qry->GetAttribute;

    my @attrsums = map { $self->_summarize_attr($_) } @attrs;

    return "add (" . join(", ", @attrsums) . ")";
}

sub _summarize_add_out {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;

    return $qry->GetNewAddress;
}

sub _summarize_delete_in {
    return "delete";
}

sub _summarize_delete_out {
    return "";
}

sub _summarize_search_in {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my @attrs = $qry->GetAttribute;

    my @attrsums = map { $self->_summarize_attr($_) } @attrs;

    return "search (" . ((@attrs) ? join(", ", @attrsums) : "*") . ")";
}

sub _summarize_search_out {

    my $self = shift;
    my $iq = shift;
    my $qry = $iq->GetQuery;
    my @items = $qry->GetItem;
    my $size = scalar(@items);

    if ($size > 4) {
	return "(" . join(",", @items[0,3]) . "... [$size total])";
    } else {
	return "(" . join(",", @items) . ")";
    }
}

sub _summarize_describe_in {
    return "describe";
}

sub _summarize_describe_out {
    # FIXME: actually write out description, wimp!
    return "[description]";
}

sub _summarize_attr {

    my $self = shift;
    my $attr = shift;
    my $name = $attr->GetName;
    my $value = $attr->GetValue;
    my $type = JOAP->value_type($value);
    my $val = JOAP->decode($value);

    return $name . " => \"" . $self->_ellipsize($val) . "\" [" . $type . "]";
}

sub _summarize_param {

    my $self = shift;
    my $param = shift;
    my $value = $param->GetValue;
    my $type = JOAP->value_type($value);
    my $val = JOAP->decode($value);

    return "\"" . $self->_ellipsize($val) . "\" [" . $type . "]";
}

sub _ellipsize {

    my $self = shift;
    my $string = shift;

    if (length($string) > 32) {
	return (substr($string, 29) . "...");
    } else {
	return $string;
    }
}

1;

__END__

=head1 NAME

JOAP::Server - Base Class for JOAP Object Servers

=head1 SYNOPSIS

    package MyServer;
    use JOAP::Server;
    use base qw(JOAP::Server);
    use MyPerson;

    MyServer->Description(<<'END_OF_DESCRIPTION');
    A simple server to illustrate the features of the server Perl
    package. Serves one class, Person.
    END_OF_DESCRIPTION

    MyServer->Attributes(
        {
            %{ JOAP::Server->Attributes() }, # inherit defaults
              'logLevel' => { type => 'i4',
                              desc => 'Level of verbosity for logging.' }
        } );

    MyServer->Methods (
        {
            'log' => {
                returnType => 'boolean',
                params => [
                    {
                        name => 'message',
                          type => 'string',
                          desc => 'message to write to log file.'
                    }
                ],
                desc => 'Log the given message to the log file. Return true for success.'
            }
        });

    MyServer->Classes (
        {
            Person => 'MyPerson'
        });

    sub log {

        my($self) = shift;
        my($message) = shift;

        push @{$self->{messages}}, $message
          if ($self->logLevel > 0);

        return 1;
    }

    1;

    package main;

    # create a server with Net::Jabber::Component arguments

    my $srv = new MyServer(debuglevel => 0,
                           logLevel => 4, # JOAP object argument
                           debugtime => 1);

    # execute the server

    $srv->execute(hostname => 'example.com',
                  port => 7010,
                  componentname => 'joap.example.com',
                  secret => 'JOAP is K00l',
                  connectiontype => 'accept');

=head1 ABSTRACT

JOAP::Server is a base class for creating JOAP object servers. It
handles the necessary Jabber component tasks, such as connecting to a
Jabber server. Secondly, it routes JOAP and RPC messages to the
appropriate objects. Finally, it acts as a JOAP object itself,
exposing attributes and methods.

=head1 DESCRIPTION

This is an abstract base class that can be used to quickly and easily
define a JOAP server, ready to run on the Jabber network. You
shouldn't instantiate or use this package directly; instead, create a
sub-class of JOAP::Server and muck around with it, instead.

There are three distinct interfaces to this class:

=over

=item Component

The class (and subclasses) act as Jabber components, connecting to a
Jabber server and fielding JOAP and RPC requests.

=item Container

It routes JOAP and RPC requests to classes and instances it serves,
and logs requests and responses.

=item JOAP Object

It exposes its own attributes and methods through JOAP.

=back

This POD describes these interfaces in order.

=head2 Component Interface

The class handles a subset of the interface defined for
Net::Jabber::Component objects. I just added the ones that seemed the
most valuable, and was too lazy to add more.

=over

=item Package->new(attr1 => $value1, attr2 => $value2, ...)

This is a class method that acts as a constructor. The name-value
pairs passed as arguments will be used to initialize both the
JOAP::Server::Object part of the server, and the Net::Jabber::Component part.

See L<Net::Jabber::Component> for the name and format of its
constructor parameters.

=item $obj->execute(%named_args)

Executes and runs the Jabber component. This does pretty much
everything you need your server to do: it connects to the upstream
Jabber server, authenticates, and runs a data pump, receiving messages
and handling them or dispatching them to the right object, then
returning the results back upstream. If the connection fails, it will
try to reconnect.

You really shouldn't bother with any other component stuff.

The named arguments are the same as used for the
L<Net::Jabber::Component> C<Execute> method. Since this is the
preferred way to start a JOAP::Server, I list the main ones here:

=over

=item componentname

The name of this component, in domain-name format.

=item hostname

The upstream Jabber server's hostname.

=item port

The port that the upstream Jabber server is listening on for our
connection.

=item secret

The secret password we need to use to tell the upstream Jabber server
that we are who we say we are.

=item connectiontype

The type of component connection. Usually this should just be
'accept', meaning that the server is listening on a port to accept our
connection.

=back

=item $obj->connect(%named_args)

Connect to a host server. See L<Net::Jabber::Component> for the proper
named arguments.

Also, use C<execute> instead.

=item $obj->disconnect(%named_args)

Disconnect from a host server. See L<Net::Jabber::Component> for the
proper named arguments.

Also, use C<execute> instead.

=item $obj->connected(%named_args)

Check if we're still connected to the host server. See
L<Net::Jabber::Component> for the proper named arguments.

Also, use C<execute> instead.

=back

=head2 Container Interface

OK, well, this isn't really so much an interface as a set of
behaviors, now that I think about it. The JOAP::Server instance routes
important events to the object an event was sent to, using the
L<JOAP::Server::Object/Container Interface> to pass in and out
requests and results.

Note that there's no way for the objects themselves to find out much
about the server. This is by design -- I wanted to keep JOAP classes
ignorant of their containing server, and have them concentrate on
their own behavior. It seems to work out fine, and when necessary the
classes can figure out important stuff like their own address from the
incoming IQ fields.

JOAP::Server uses a class accessor to determine what Perl classes are
exposed as JOAP classes by this server.

=over

=item Classes($classmap)

This class mutator takes as a parameter a reference to a hashtable
which maps JOAP class names to Perl module names that implement that
class. Note that only the class name, and not the full class address,
is used.

Modules specified in the class map are not automatically C<use>'d. You
need to include C<use> statements in your subclass module for each
module you expose.

The classes in the class map B<must> expose the same Container
interface as L<JOAP::Server::Class>.

=back

=head3 Log Format

JOAP::Server object log JOAP and RPC events by default. The logging
mechanism is pretty loosey-goosey right now, but the basic log format
is this:

    $timestamp : "$from" - "$to" : $request (@args) -> (@results) ($status)

Here the parts of the log format look like this:

=over

=item $timestamp

An ISO 8601 timestamp when the results of an event were returned. See
L<JOAP::Types> for the format of a timestamp.

=item $from

The remote user who sent the request.

=item $to

The local object (object server, class, or instance) that the request was sent to.

=item $request

The type of request; one of 'read', 'edit', 'add', 'delete', 'search',
'describe', or 'method'.

=item @args

Any arguments that the request contained. The format of the args is
request-dependent.

=item @results

The results that the object returned. Again, this is request
dependent, and one of these days I'll get around to defining it fully. B-)

=item $status

The status of the request. If there was an error, this is the numeric
error code returned to the requester. If not, this is the string "OK".

=back

=head2 JOAP Object Interface

This interface is how subclasses of JOAP::Server declare their
methods, attributes, and human-readable description to the library
(and thence to the world).

Note that the C<Classes> method listed above is also exposed as part
of the server object's interface.

=over

=item Description($string)

Sets the human-readable description of the object server, which is
returned in 'describe' verbs. Note that JOAP allows multiple
descriptions for different human languages; this implementation does
not, but that may change in the future.

=item Attributes($hashref)

This sets the publicly available attributes for the object
server. $hashref is a reference to a hashtable mapping attribute names
to attribute descriptors. See L<JOAP::Descriptors> for the format of
this data structure.

Besides the fields listed there, the attribute descriptor can also
contain the following fields:

=over

=item getter

=item setter

=item accessor

These work in the same way as with L<JOAP::Server::Object>, which see.

=back

=item Methods($hashref)

This sets the publicly available methods for the object
server. $hashref is a reference to a hashtable mapping method names to
method descriptors; see L<JOAP::Descriptors> for the format of method
descriptors.

As well as the fields described normally for method descriptors, the
following fields are also used:

=over

=item function

This is the name of, or reference to, a function that acts as this
method. If the field is not provided, the function with the same name
in this package will be used.

=back

=back

Note that the JOAP::Server class itself exposes a couple of attributes
by default, just for kicks. You can expose these attributes in your
subclass server by interpolating the C<JOAP::Server->Attributes> hash
into your own hash, as shown above in the synopsis.

=head2 EXPORT

None by default.

=head1 BUGS

I think the delegation mechanism is probably flipped around the wrong
way. Instead of being a JOAP::Server::Object and containing a
Net::Jabber::Component, it should probably be a Net::Jabber::Component
and contain a single JOAP::Server::Object. But, y'know, no biggie.

The server isn't terribly robust -- it doesn't trap errors very well,
nor does it recover from error situations with any measure of grace.

It's all single-threaded, which loses.

The server doesn't automagically use Perl modules exposed as classes,
nor does it have a default mechanism for mapping class names to Perl
modules.

=head1 SEE ALSO

L<JOAP> contains general information about JOAP, as well as contact
information for the author of this package.

L<JOAP::Server::Object> goes into more detail about the container
interface for JOAP objects.

L<JOAP::Server::Class> is good for defining classes exposed by a JOAP
server.

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
