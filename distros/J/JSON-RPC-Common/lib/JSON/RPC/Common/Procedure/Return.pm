#!/usr/bin/perl

package JSON::RPC::Common::Procedure::Return;
$JSON::RPC::Common::Procedure::Return::VERSION = '0.11';
use Moose;
# ABSTRACT: JSON-RPC procedure return class

use Carp qw(croak);

use JSON::RPC::Common::TypeConstraints qw(JSONValue);
use JSON::RPC::Common::Procedure::Return::Error;

use namespace::clean -except => [qw(meta)];

with qw(JSON::RPC::Common::Message);

around new_from_data => sub {
	my $next = shift;
	my ( $class, %args ) = @_;

	if ( defined(my $error = delete $args{error}) ) {
		$args{error} = $class->inflate_error($error, %args);
	}

	return $class->$next(%args);
};

has version => (
	isa => "Str",
	is  => "rw",
	predicate => "has_version",
);

has result => (
	isa => "Any",
	is  => "rw",
	predicate => "has_result",
);

has id => (
	isa => JSONValue,
	is  => "rw",
	predicate => "has_id",
);

has error_class => (
	isa => "ClassName",
	is  => "rw",
	default => "JSON::RPC::Common::Procedure::Return::Error",
);

has error => (
	isa => "JSON::RPC::Common::Procedure::Return::Error",
	is  => "rw",
	predicate => "has_error",
);

sub deflate {
	my $self = shift;

	my $version = $self->version;

	$version = "undefined" unless defined $version;

	croak "Deflating a procedure return of the class " . ref($self) . " is not supported (version is $version)";
}

sub deflate_error {
	my $self = shift;

	if ( my $error = $self->error ) {
		return $error->deflate;
	} else {
		return undef;
	}
}

sub inflate_error {
	my ( $self, $error ) = @_;

	my $error_class = ref $self
		? $self->error_class
		: $self->meta->find_attribute_by_name("error_class")->default;

	$error_class->inflate($error);
}

sub set_error {
	my ( $self, @args ) = @_;

	$self->error( $self->create_error(@args) );
}

sub create_error {
	my ( $self, @args ) = @_;
	$self->error_class->new_dwim(@args);
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Procedure::Return - JSON-RPC procedure return class

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use JSON::RPC::Common::Procedure::Return;

	# create a return from a call, retaining the ID
	my $return = $call->return_result("foo");

	# inflate gets a version specific class
	my $return = JSON::RPC::Common::Procedure::Return->inflate(
		version => "2.0",
		result  => "foo",
		id      => $id,
	);

	# you can specify a return with an error, it's just an attribute
	my $return = JSON::RPC::Common::Procedure::Return->new(
		error => ...,
	);

=head1 DESCRIPTION

This class abstracts JSON-RPC procedure returns (results).

Version specific implementation are provided as well.

=head1 ATTRIBUTES

=over 4

=item id

The ID of the call this is a result for.

Results with no ID are typically error results for parse fails, when the call
ID could never be determined.

=item result

The JSON data that is the result of the call, if any.

=item error

The error, if any. This is a L<JSON::RPC::Common::Procedure::Return::Error>
object (or a version specific subclass).

=item error_class

The error class to use when instantiating errors.

=back

=head1 METHODS

=over 4

=item inflate

=item deflate

Go to and from JSON data.

=item inflate_error

=item deflate_error

Helpers for managing the error sub object.

=item set_error

Calls C<create_error> with it's arguments and sets the error to that.

E.g.

	$res->set_error("foo");
	$res->error->message; # "foo"

=item create_error

Instantiate a new error of class L<error_class> using
L<JSON::RPC::Common::Procedure::Return::Error/new_dwim>.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
