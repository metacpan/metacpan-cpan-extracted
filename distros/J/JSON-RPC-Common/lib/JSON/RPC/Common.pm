#!/usr/bin/perl

package JSON::RPC::Common;
$JSON::RPC::Common::VERSION = '0.11';
# ABSTRACT: Transport agnostic JSON RPC helper objects

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common - Transport agnostic JSON RPC helper objects

=head1 VERSION

version 0.11

=head1 SYNOPSIS

	# this is a simplistic example
	# you probably want to use L<JSON::RPC::Common::Marshal::Text> instead for
	# something like this.

	use JSON::RPC::Common::Procedure::Call;

	# deserialize whatever json text you have into json data:
	my $req = from_json($request_body);

	# inflate it and get a call object:
	my $call = JSON::RPC::Common::Procedure::Call->inflate($req);

	warn $call->version;

	# this will create a result object of the correct class/version/etc
	# "value" is the return result, regardless of version
	my $res = $call->return_result("value");

	# finally, convert back to json text:
	print to_json($res->deflate);

=head1 DESCRIPTION

This module provides abstractions for JSON-RPC 1.0, 1.1 (both variations) and
2.0 (formerly 1.2) Procedure Call and Procedure Return objects (formerly known
as request and result), along with error objects. It also provides marshalling
objects to convert the model objects into JSON text and HTTP
requests/responses.

This module does not concern itself with the transport layer at all, so the
JSON-RPC 1.1 and the alternative specification, which are very different on
that level are implemented with the same class.

=head1 RANT

While JSON-RPC 1.0 and JSON-RPC 2.0 are beautifully simple, the JSON-RPC 1.1
working draft, is most definitely not. It is a convoluted protocol, and also
demands a lot more complexity from the responders on the server side (server
side introspection (C<system.describe>), strange things relating to positional
vs. named params...).

Unfortunately it appears that JSON-RPC 1.1 is the most popular variant.

Since the client essentially chooses the version of the RPC to be used, for
public APIs I reccomend that all versions be supported, but be aware that a
1.1-WD server "MUST" implement service description in order to be in
compliance.

Anyway, enough bitching. I suggest making your servers 1.0+2.0, and your
clients 2.0.

=head1 CLASSES

There are various classes provided by L<JSON::RPC::Common>.

They are designed for high reusability. All the classes are transport and
representation agnostic except for L<JSON::RPC::Common::Marshal::Text> and
L<JSON::RPC::Common::Marshal::HTTP> which are completely optional.

=head2 L<JSON::RPC::Common::Procedure::Call>

This class and its subclasses implement Procedure Calls (requests) for JSON-RPC
1.0, 1.1WD, 1.1-alt and 2.0.

=head2 L<JSON::RPC::Common::Procedure::Return>

This class and its subclasses implement Procedure Returns (results) for
JSON-RPC 1.0, 1.1WD, 1.1-alt and 2.0.

=head2 L<JSON::RPC::Common::Procedure::Return::Error>

This class and its subclasses implement Procedure Return error objects for
JSON-RPC 1.0, 1.1WD, 1.1-alt and 2.0.

=head2 L<JSON::RPC::Common::Marshal::Text>

A filter object that uses L<JSON> to serialize procedure calls and returns to
JSON text, including JSON-RPC standard error handling for deserialization
failure.

=head2 L<JSON::RPC::Common::Marshal::HTTP>

A subclass of L<JSON::RPC::Common::Marshal::Text> with additional methods for
marshaling between L<HTTP::Request>s and L<JSON::RPC::Common::Procedure::Call>
and L<HTTP::Response> and L<JSON::RPC::Common::Procedure::Return>.

Also knows how to handle JSON-RPC 1.1 C<GET> encoded requests (for all
versions), providing RESTish call semantics.

=head1 TODO

=over 4

=item *

L<JSON::RPC::Common::Handler>, a generic dispatch table based handler, useful
for when you don't want to just blindly call methods on certain objects using
L<JSON::RPC::Common::Procedure::Call/call>.

=item *

L<JSON::RPC::Common::Errors>, a class that will provide dictionaries of error
codes for JSON-RPC 1.1 and 1.1-alt/2.0.

=item *

An object model for JSON-RPC 1.1 service description.

SMD is required by most JSON-RPC 1.1 over HTTP clients.

Since this is generally static, for now you can write one manually, see
L<http://groups.google.com/group/json-rpc/web/simple-method-description-for-json-rpc-example>
for an example

=item *

L<Moose> class to SMD translator

=item *

L<MooseX::Storage> enabled objects can serialize themselves into JSON, and
should DWIM when used. JSON-RPC 1.0 class hints could be used here too.

=item *

Convert to L<Squirrel> for smaller deps and faster load time. Need to find a
solution for roles and type constraints. Neither is relied on heavily.

=back

=head1 SEE ALSO

=head2 On the Intertubes

=over 4

=item JSON-RPC 1.0 specification

L<http://json-rpc.org/wiki/specification>

=item JSON-RPC 1.1 working draft

L<http://json-rpc.org/wd/JSON-RPC-1-1-WD-20060807.html>

=item JSON-RPC 1.1 alternative specification proposal

L<http://groups.google.com/group/json-rpc/web/json-rpc-1-1-alt>

=item JSON-RPC 2.0 specification proposal

L<http://groups.google.com/group/json-rpc/web/json-rpc-1-2-proposal>

=item Simplified encoding of JSON-RPC over HTTP

L<http://groups.google.com/group/json-rpc/web/json-rpc-over-http>

=back

=head2 On the CPAN

L<JSON>, L<JSON::RPC>, L<RPC::JSON>, L<HTTP::Engine>, L<CGI::JSONRPC>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman and others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
