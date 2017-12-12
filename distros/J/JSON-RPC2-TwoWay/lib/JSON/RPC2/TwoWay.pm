package JSON::RPC2::TwoWay;
use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.03'; # VERSION

# standard perl
use Carp;
use Data::Dumper;

# cpan
use JSON::MaybeXS;

# us
use JSON::RPC2::TwoWay::Connection;

use constant ERR_NOTNOT   => -32000;
use constant ERR_ERR      => -32001;
use constant ERR_BADSTATE => -32002;
use constant ERR_REQ      => -32600;
use constant ERR_METHOD   => -32601;
use constant ERR_PARAMS   => -32602;
use constant ERR_PARSE    => -32700;

sub new {
	my ($class, %opt) = @_;
	my $self = {
		debug => $opt{debug} // 0,
		methods => {},
	};
	return bless $self, $class;
}

sub newconnection {
	my ($self, %opt) = @_;
	my $conn = JSON::RPC2::TwoWay::Connection->new(
		rpc => $self,
		owner => $opt{owner},
		write => $opt{write},
		debug => $self->{debug},
	);
	return $conn
}

sub register {
	my ($self, $name, $cb, %opts) = @_;
	my %defaults = ( 
		by_name => 1,
		non_blocking => 0,
		notification => 0,
		raw => 0,
		state => undef,
	);
	croak 'no self?' unless $self;
	croak 'no name?' unless $name;
	croak 'no callback?' unless ref $cb eq 'CODE';
	%opts = (%defaults, %opts);
	croak 'a non_blocking notification is not sensible'
		if $opts{non_blocking} and $opts{notification};
	croak "method $name already registered" if $self->{methods}->{$name};
	$self->{methods}->{$name} = { 
		name => $name,
		cb => $cb,
		by_name => $opts{by_name},
		non_blocking => $opts{non_blocking},
		notification => $opts{notification},
		raw => $opts{raw},
		state => $opts{state},
	};
}

sub unregister {
	my ($self, $name) = @_;
	croak 'no self?' unless $self;
	croak 'no name?' unless $name;
	my $method = delete $self->{methods}->{$name};
	croak "method $name already registered" unless $method;
}


sub _handle_request {
	my ($self, $c, $r) = @_;
	say STDERR '    in handle_request' if $self->{debug};
	#print Dumper(\@_);
	my $m = $self->{methods}->{$r->{method}};
	my $id = $r->{id};
	return $self->_error($c, $id, ERR_METHOD, 'Method not found.') unless $m;
	return $self->_error($c, $id, ERR_NOTNOT, 'Method is not a notification.') if !$id and !$m->{notification};

	return $self->_error($c, $id, ERR_REQ, 'Invalid Request: params should be array or object.')
		if ref $r->{params} ne 'ARRAY' and ref $r->{params} ne 'HASH';

	return $self->_error($c, $id, ERR_PARAMS, 'This method expects '.($m->{by_name} ? 'named' : 'positional').' params.')
		if ref $r->{params} ne ($m->{by_name} ? 'HASH' : 'ARRAY');
	
	return $self->_error($c, $id, ERR_BADSTATE, 'This method requires connection state ' . ($m->{state} // 'undef'))
		if $m->{state} and not ($c->state and $m->{state} eq $c->state);

	if ($m->{raw}) {
		my $cb;
		$cb = sub { $c->write(encode_json($_[0])) if $id } if $m->{non_blocking};

		local $@;
		#my @ret = eval { $m->{cb}->($c, $jsonr, $r, $cb)};
		my @ret = eval { $m->{cb}->($c, $r, $cb)};
		return $self->_error($c, $id, ERR_ERR, "Method threw error: $@") if $@;
		#say STDERR 'method returned: ', Dumper(\@ret);

		$c->write(encode_json($ret[0])) if !$cb and $id;
		return
	}

	my $cb;
	$cb = sub { $self->_result($c, $id, \@_) if $id; } if $m->{non_blocking};

	local $@;
	my @ret = eval { $m->{cb}->($c, $r->{params}, $cb)};
	return $self->_error($c, $id, ERR_ERR, "Method threw error: $@") if $@;
	#say STDERR 'method returned: ', Dumper(\@ret);
	
	return $self->_result($c, $id, \@ret) if !$cb and $id;
	return;
}

sub _error {
	my ($self, $c, $id, $code, $message, $data) = @_;
	my $err = "error: $code " . $message // '';
	say STDERR $err if $self->{debug};
	$c->write(encode_json({
		jsonrpc     => '2.0',
		id          => $id,
		error       => {
			code        => $code,
			message     => $message,
			(defined $data ? ( data => $data ) : ()),
		},
	}));
	return 0, $err;
}

sub _result {
	my ($self, $c, $id, $result) = @_;
	$result = $$result[0] if scalar(@$result) == 1;
	#say STDERR Dumper($result) if $self->{debug};
	$c->write(encode_json({
		jsonrpc     => '2.0',
		id          => $id,
		result      => $result,
	}));
	return;
}

#sub DESTROY {
#       my $self = shift;
#       say 'destroying ', $self;
#}

1;

=encoding utf8

=head1 NAME

JSON::RPC2::TwoWay - Transport-independent bidirectional JSON-RPC 2.0

=head1 SYNOPSIS

  $rpc = JSON::RPC2::TwoWay->new();
  $rpc->register('ping', \&handle_ping);

  $con = $rpc->newconnection($owner, $stream);
  $err = $con->serve($stream->read());
  die $err if $err;

=head1 DESCRIPTION

L<JSON::RPC2::TwoWay> is a base class to implement bidirectional (a.k.a. 
twoway) communication using JSON-RPC 2.0 remote procedure calls: both sides
can operate as Clients and Servers simultaneously.  This class is
transport-independent.

=head1 METHODS

=head2 new

$rpc = JSON::RPC2::TwoWay->new();

Class method that returns a new JSON::RPC2::TwoWay object.

Valid arguments are:

=over 4

=item - debug: print debugging to STDERR

=back

=head2 newconnection

my $con = $rpc->newconnection(owner => $owner, write = $write);

Creates a L<JSON::RPC2::TwoWay::Connection> with owner $owner and writer $write.

See L<JSON::RPC2::TwoWay::Connection> for details.

=head2 register

$rpc->register('my_method', sub { ... }, option => ... );

Register a new method to be callable. Calls are passed to the callback.

Valid options are:

=over 4

=item - by_name

When true the arguments to the method will be passed in as a hashref,
otherwise as a arrayref.  (default true)

=item - non_blocking

When true the method callback will receive a callback as its last argument
for passing back the results (default false)

=item - notification

When true the method is a notification and no return value is expected by
the caller.  (Any returned values will be discarded in the handler.)

=item - state

When defined must be a string value defining the state the connection (see
L<newconnection>) must be in for this call to be accepted.

=back

=head2 unregister

$rpc->unregister('my_method')

Unregister a method.

=head1 REGISTERED CALLBACK CALLING CONVENTION

The method callback passed as the second argument of register is called with
2 or 3 arguments: the first argument is the JSON::RPC2::TwoWay::Connection
object on which the request came in.  The second argument is a arrayref or
hashref depending on if the method was registered as by-position or by-name.
The third argument, if present is a result callback that needs to be called
with the results of the method:

  sub mymethod {
     ($c, $i, $cb) = @_;
     $foo = $i->{foo};
  }

  some time later;

  $cb->("you sent $foo");

If the method callback returns a scalar value the JSON-RPC 2.0 result member
value will be a JSON string, number, or null value.  If the method returns a
hashref the result member value will be an object.  If the method returns
multiple values or an arrayref the result member value will be an array.

=head1 SEE ALSO

=over

=item *

L<JSON::RPC2::TwoWay::Connection>

=item *

L<http://www.jsonrpc.org/specification>: JSON-RPC 2.0 Specification

=back

=head1 ACKNOWLEDGEMENT

This software has been developed with support from L<STRATO|https://www.strato.com/>.
In German: Diese Software wurde mit Unterstützung von L<STRATO|https://www.strato.de/> entwickelt.

=head1 AUTHORS

=over 4

=item *

Wieger Opmeer <wiegerop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Wieger Opmeer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

