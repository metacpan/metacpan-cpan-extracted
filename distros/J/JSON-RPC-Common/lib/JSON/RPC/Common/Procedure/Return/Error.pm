#!/usr/bin/perl

package JSON::RPC::Common::Procedure::Return::Error;
$JSON::RPC::Common::Procedure::Return::Error::VERSION = '0.11';
use Moose;
# ABSTRACT: Base class for JSON-RPC errors

use JSON::RPC::Common::TypeConstraints qw(JSONValue);

use namespace::clean -except => [qw(meta)];

sub new_dwim {
	my ( $class, @args ) = @_;

	if ( @args == 1 ) {
		if ( blessed($args[0]) and $args[0]->isa($class) ) {
			return $args[0];
		}
	}

	$class->inflate(@args);
}

sub inflate {
	my ( $class, @args ) = @_;

	my $data;
	if (@args == 1 and defined $args[0] and (ref($args[0])||'') eq 'HASH') {
		$data = { %{ $args[0] } };
	} else {
		if ( @args % 2 == 1 ) {
			unshift @args, "message";
		}
		$data = { @args };
	}
	my %constructor_args;

	foreach my $arg ( qw(message code) ) {
		$constructor_args{$arg} = delete $data->{$arg} if exists $data->{$arg};
	}

	if ( keys %$data ) {
		$constructor_args{data} = (join(" ", keys %$data) eq 'data' ? $data->{data} : $data);
	}

	$class->new(%constructor_args);
}

has data => (
	isa => JSONValue,
	is  => "rw",
	predicate => "has_data",
);

has message => (
	isa => "Str",
	is  => "rw",
	predicate => "has_message",
);

has code => (
	isa => "Int",
	is  => "rw",
	predicate => "has_code",
);

# FIXME delegate to a dictionary
sub http_status { 500 }

__PACKAGE__->meta->make_immutable();

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Procedure::Return::Error - Base class for JSON-RPC errors

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use JSON::RPC::Common::Procedure::Return::Error;

	my $error = JSON::RPC::Common::Procedure::Return::Error->new(
		message => "foo",
		code => "bah",
	);

	# or construct a return with an error from a call:
	my $return = $call->return_error("foo");

	$return->error->message;

=head1 DESCRIPTION

This is a base class for all version specific error implementations.

=head1 ATTRIBUTES

=over 4

=item code

=item message

=item data

These are the three common JSON-RPC error fields. In JSON-RPC 1.1 C<data> is
known as C<error>, and in 1.0 none of this is specced at all.

See the version specific subclasses for various behaviors.

Code is an integer, and message is a string.

=back

=head1 METHODS

=over 4

=item new_dwim

Convenience constructor used by
L<JSON::RPC::Common::Procedure::Call/return_error>.

Will return an object if that's the argument, and otherwise construct an error.

=item inflate

Create an error object from JSON data (not text).

In order to maximize compatibility this inflation routine is very liberal in
what it accepts.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
