#!/usr/bin/perl

package JSON::RPC::Common::Procedure::Return::Version_2_0;
$JSON::RPC::Common::Procedure::Return::Version_2_0::VERSION = '0.11';
use Moose;
# ABSTRACT: JSON-RPC 2.0 Procedure Return

use JSON::RPC::Common::Procedure::Return::Version_2_0::Error;

use namespace::clean -except => [qw(meta)];

extends qw(JSON::RPC::Common::Procedure::Return);

has '+version' => (
	# default => "2.0", # broken, Moose::Meta::Method::Accessor gens numbers if looks_like_number
	default => sub { "2.0" },
	# init_arg => "jsonrpc", # illegal inherit arg. bah. it's meaningless, so we don't care
);

has '+error_class' => (
	default => "JSON::RPC::Common::Procedure::Return::Version_2_0::Error",
);

sub deflate {
	my $self = shift;

	return {
		jsonrpc => "2.0",
		( $self->has_error
			? ( error => $self->deflate_error )
			: ( result  => $self->result ) ),
		( $self->has_id ? ( id => $self->id ) : () ),
	};
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Procedure::Return::Version_2_0 - JSON-RPC 2.0 Procedure Return

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	my $return = $call->return_value("foo");

=head1 DESCRIPTION

This class implements procedure returns for JSON::RPC 2.0.

See L<JSON::RPC::Common::Procedure::Return>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
