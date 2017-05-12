#!/usr/bin/perl

package JSON::RPC::Common::Procedure::Return::Version_2_0::Error;
$JSON::RPC::Common::Procedure::Return::Version_2_0::Error::VERSION = '0.11';
use Moose;
# ABSTRACT: JSON-RPC 2.0 error class.

use JSON::RPC::Common::TypeConstraints qw(JSONValue);

use namespace::clean -except => [qw(meta)];

extends qw(JSON::RPC::Common::Procedure::Return::Error);

has '+message' => (
	required => 1,
);

has '+code' => (
	default => -32603,
);

sub deflate {
	my $self = shift;

	return {
		code    => $self->code,
		message => $self->message,
		( $self->has_data ? ( data => $self->data ) : () ),
	};
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Procedure::Return::Version_2_0::Error - JSON-RPC 2.0 error class.

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	my $return_with_error = $call->return_error("foo");

=head1 DESCRIPTION

This class implements 2.0 error objects.

C<code> and C<message> are mandatory.

See L<JSON::RPC::Common::Procedure::Return::Error>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
