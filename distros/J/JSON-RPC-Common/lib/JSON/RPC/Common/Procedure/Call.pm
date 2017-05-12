#!/usr/bin/perl

package JSON::RPC::Common::Procedure::Call;
$JSON::RPC::Common::Procedure::Call::VERSION = '0.11';
use Moose;
# ABSTRACT: JSON RPC Procedure Call base class.

use Try::Tiny;
use JSON::RPC::Common::TypeConstraints qw(JSONValue);
use JSON::RPC::Common::Procedure::Return;

use Carp qw(croak);

use namespace::clean -except => [qw(meta)];

with qw(JSON::RPC::Common::Message);

has return_class => (
	isa => "ClassName",
	is  => "rw",
	default => "JSON::RPC::Common::Procedure::Return",
);

has error_class => (
	isa => "ClassName",
	is  => "rw",
	default => "JSON::RPC::Common::Procedure::Return::Error",
);

has version => (
	isa => "Str",
	is  => "rw",
	predicate => "has_version",
);

has method => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

has id => (
	isa => JSONValue,
	is  => "rw",
	predicate => "has_id",
);

has params => (
	isa => "Ref",
	is  => "rw",
	predicate => "has_params",
);

sub deflate_version {
	return ();
}
sub deflate_method {
	my $self = shift;
	return ( method => $self->method );
}

sub deflate_id {
	my $self = shift;

	if ( $self->has_id ) {
		return ( id => $self->id );
	} else {
		return ();
	}
}

sub deflate_params {
	my $self = shift;

	if ( $self->has_params ) {
		return ( params => $self->params );
	} else {
		return ();
	}
}

sub deflate {
	my $self = shift;

	return {
		$self->deflate_version,
		$self->deflate_method,
		$self->deflate_id,
		$self->deflate_params,
	};
}

sub is_service { 0 }

sub is_notification {
	my $self = shift;
	return not $self->has_id;
}

sub params_list {
	my $self = shift;
	my $p = $self->params;

	if ( ref $p eq 'HASH' ) {
		return %$p;
	} elsif ( ref $p eq 'ARRAY' ) {
		return @$p;
	} else {
		return $p; # FIXME error?
	}
}

sub call {
	my ( $self, $invocant, @args ) = @_;

	die "No invocant provided" unless blessed($invocant);

	my $method = $self->method;

    my $error;
	my @res = try {
	    $invocant->$method( $self->params_list, @args )
	} catch {
	    $error = $_;
	};

	if ($error) {
	    $self->return_error(message => $error);
	}
	else {
	    $self->return_result(@res);
	}
}

sub create_return {
	my ( $self, @args ) = @_;

	$self->return_class->new(
		error_class => $self->error_class,
		( $self->has_id ? ( id => $self->id ) : () ),
		@args,
	);
}

sub return_error {
	my ( $self, @args ) = @_;

	$self->create_return( error => $self->error_class->new_dwim(@args) );
}

sub return_result {
	my ( $self, @res ) = @_;

	my $res = @res == 1 ? $res[0] : \@res;

	$self->create_return( result => $res );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Procedure::Call - JSON RPC Procedure Call base class.

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use JSON::RPC::Common::Procedure::Call;

	my $req = JSON::RPC::Common::Procedure::Call->inflate({ ... });

	warn "HALLO JSONRPC VERSION " . $req->version;

=head1 DESCRIPTION

A JSON-RPC Procedure Call (ed: *rolls eys*, what was wrong with "request"?) is
either a notification or a method invocation in JSON-PRC.

See L<http://json-rpc.org/wiki/specification> for more details.

=head1 ATTRIBUTES

All attributes are read only unless otherwise specified.

=over 4

=item version

=item id

The request ID.

Used to correlate a request to a response.

=item method

The name of the method to invoke.

=item params

Returns a reference to the parameters hash or array.

=item return_class

=item error_class

The classes to instantiate the response objects.

These vary per subclass.

=back

=head1 METHODS

=over 4

=item inflate

A factory constructor. Delegates to C<new> on a subclass based on the protocol
version.

This is the recommended constructor.

=item deflate

Flatten to JSON data

=item new

The actual constructor.

Not intended for normal use on this class, you should use a subclass most of
the time.

Calling C<< JSON::RPC::Common::Procedure::Call->new >> will construct a call
with an undefined version, which cannot be deflated (and thus sent over the
wire). This is still useful for testing your own code's RPC hanlding, so this
is not allowed.

=item params_list

Dereferences C<params> regardless of representation.

Returns a list of positionals or a key/value list.

=item return_result $result

=item return_error %error_params

Create a new L<JSON::RPC::Common::Procedure::Return> with or without an error.

=item is_notification

Whether this request is a notification (a method that does not need a response).

=item is_service

Whether this request is a JSON-RPC 1.1 service method (e.g.
C<system.describe>).

This method is always false for 1.0 and 2.0.

=item call $obj

A convenience method to invoke the call on C<$obj> and create a new return with
the return value.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
