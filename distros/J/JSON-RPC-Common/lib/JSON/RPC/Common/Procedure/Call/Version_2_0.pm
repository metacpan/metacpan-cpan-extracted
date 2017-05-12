#!/usr/bin/perl

package JSON::RPC::Common::Procedure::Call::Version_2_0;
$JSON::RPC::Common::Procedure::Call::Version_2_0::VERSION = '0.11';
use Moose;
# ABSTRACT: JSON-RPC 2.0 Procedure Call

use JSON::RPC::Common::TypeConstraints qw(JSONContainer);
use JSON::RPC::Common::Procedure::Return::Version_2_0;

use namespace::clean -except => [qw(meta)];

extends qw(JSON::RPC::Common::Procedure::Call);

has '+version' => (
	# default => "2.0", # broken, Moose::Meta::Method::Accessor gens numbers if looks_like_number
	default => sub { "2.0" },
	# init_arg => "jsonrpc", # illegal inherit arg. bah. it's meaningless, so we don't care
);

has '+params' => (
	isa => JSONContainer,
);

has '+return_class' => (
	default => "JSON::RPC::Common::Procedure::Return::Version_2_0",
);

has '+error_class' => (
	default => "JSON::RPC::Common::Procedure::Return::Version_2_0::Error",
);

sub deflate_version {
	my $self = shift;
	return ( jsonrpc => $self->version );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Procedure::Call::Version_2_0 - JSON-RPC 2.0 Procedure Call

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	use JSON::RPC::Common::Procedure::Call;

	my $req = JSON::RPC::Common::Procedure::Call->inflate({
		jsonrpc => "2.0",
		id      => "oink",
		params  => { foo => "bar" },
	});

=head1 DESCRIPTION

This class implements JSON-RPC Procedure Call objects according to the 2.0
specification proposal:
L<http://groups.google.com/group/json-rpc/web/json-rpc-1-2-proposal>.

JSON RPC 2.0 reinstate notifications, and allow the same format for parameters.

Requests are considered notifications only when the C<id> field is missing, not
when it's null.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
