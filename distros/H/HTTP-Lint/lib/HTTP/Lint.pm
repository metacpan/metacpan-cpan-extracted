use strict;
use warnings;

package HTTP::Lint;

=head1 NAME

HTTP::Lint - Check HTTP messages and transactions for protocol violations

=head1 SYNOPSIS

  use HTTP::Lint qw/http_lint/;
  use HTTP::Request;
  use HTTP::Response;

  my $request = parse HTTP::Request ($q);
  my $response = parse HTTP::Request ($r);

  # Check request
  warn $_ foreach http_lint ($request);

  # Check response, treat warnings as fatal
  foreach http_lint ($response) {
      die $_ if ref $_ eq 'HTTP::Lint::Error';
      warn $_ if ref $_ eq 'HTTP::Lint::Warning';
  }

  # Construct a transaction and check it
  $response->request ($request);
  warn $_ foreach http_lint ($response);

=head1 DESCRIPTION

B<HTTP::Lint> checks for protocol violation and suspicious or
ambigious stuff in HTTP messages and transactions. It produces
errors and warning, loosely corresponsing to MUST and SHOULD
clauses in RFC2616 (HTTP/1.1 specification).

=cut

use Scalar::Util qw/blessed/;
use Exporter qw/import/;
our @EXPORT_OK = qw/http_lint request_lint response_lint transaction_lint/;

# These are only used internally, no need for POD documentation
@HTTP::Lint::Warning::ISA = @HTTP::Lint::Error::ISA
	= ('HTTP::Lint::Message');
sub message	{ [ shift, \@_ ] }
sub error	{ bless message (@_), 'HTTP::Lint::Error'; }
sub warning	{ bless message (@_), 'HTTP::Lint::Warning'; }

=head1 SUBROUTINES

=over 4

=item B<http_lint> [MESSAGE]

Checks an instance of a subclass of L<HTTP::Message>:
a L<HTTP::Response> or a L<HTTP::Request>. If a L<HTTP::Response>
is given, and it contains a valid B<request> associated,
the request is checked too and a transaction check is done to
check whether the response is appropriate for the request.

Result of the call is an array of arrayrefs blessed with
L<HTTP::Lint::Error> or L<HTTP::Lint::Warning> package.
The first element of the message is the message string,
the second one is the arrayref of section numbers that refer
to B<RFC2616>:

  bless [ '418 Response from what is not a teapot',
      [ 666,1,2,3 ] ], 'HTTP::Lint::Error';

You can stringify the message or call the method B<pretty>
to pretty-format the message.

=cut

sub http_lint
{
	my $message = shift;
	my @return;

	return @return unless blessed $message;
	if ($message->isa ('HTTP::Response')) {
		push @return, response_lint ($message);
		if ($message->request) {
			push @return, transaction_lint ($message->request, $message);
			$message = $message->request;
		}
	}
	if ($message->isa ('HTTP::Request')) {
		push @return, request_lint ($message);
	}

	return @return;
}

=item B<request_lint> [REQUEST]

Only check a L<HTTP::Request>.

The return value follows the same rules as of B<http_lint>.

=cut

sub request_lint
{
	my $request = shift;
	my @return;

	# http://www.w3.org/Protocols/HTTP/1.1/rfc2616bis/issues/#i19
	push @return, error $request->method.' request with non-empty body'
		if $request->method =~ /^(GET|HEAD|DELETE)$/
		and $request->content;
	push @return, error 'HTTP/1.1 request without Host header' => 9
		if ($request->protocol || 'HTTP/1.0') eq 'HTTP/1.1'
		and not defined $request->header ('Host');
	push @return, warning 'Missing Accept header' => 14,1
		unless $request->header ('Accept');

	return @return;
}

=item B<response_lint> [REQUEST]

Only check a L<HTTP::Response>.

The return value follows the same rules as of B<http_lint>.

=cut

sub response_lint
{
	my $response = shift;
	my @return;

	push @return, error 'Length does not correspond to actual content size' => 4,4
		if defined $response->content_length
		and $response->content_length != length ($response->content);
	push @return, error 'HTTP/1.1 non-close response without given size' => 19,6,2
		if ($response->protocol || 'HTTP/1.0') eq 'HTTP/1.1'
		and not $response->code == 204
		and not $response->code == 304
		and not defined $response->content_length
		and ($response->header ('Transfer-Encoding') || '') ne 'chunked';
	push @return, warning 'Missing media type', 7,2,1
		if $response->content
		and not defined $response->header ('Content-Type');
	push @return, error $response->code.' response with content', 10,2,5
		if $response->content
		and $response->code =~ /^[23]04$/;
	push @return, error 'Location missing for a '.$response->code.' response' => 10,2,2
		if $response->code =~ /^(201|3\d\d)$/
		and not defined $response->header ('Location');
	push @return, error 'WWW-Authenticate header missing for a 401 response' => 14,47
		if $response->code == 401
		and not defined $response->header ('WWW-Authenticate');
	push @return, error 'Proxy-Authenticate header missing for a 407 response' => 10,4,8
		if $response->code == 407
		and not defined $response->header ('Proxy-Authenticate');
	push @return, warning 'Retry-After header missing for a 503 response' => 10,5,4
		if $response->code == 503
		and not defined $response->header ('Retry-After');
	push @return, warning 'Undefined Refresh header is present'
		if defined $response->header ('Refresh');
	push @return, error '405 without allowed methods specified' => 10,4,6
		if $response->code == 405
		and not defined $response->header ('Allow');
	push @return, error 'Partial content lacks correct range specification' => 10,2,7
		if $response->code eq 206
		and not $response->header ('Content-Range')
		and not ($response->header ('Content-Type') || '') eq 'multipart/byteranges';
	push @return, warning 'Missing Date header' => 14,18
		if $response->code =~ /^2\d\d$/
		and not $response->header ('Date');

	return @return;
}

=item B<transaction_lint> [REQUEST] [RESPONSE]

Only check a relation between L<HTTP::Request> and L<HTTP::Response>.

The return value follows the same rules as of B<http_lint>.

=cut

sub transaction_lint
{
	my $request = shift;
	my $response = shift;
	my @return;

	push @return, warning 'HTTP/1.1 response for a HTTP/1.0 request' => 3,1
		if ($request->protocol || 'HTTP/1.0') eq 'HTTP/1.0'
		and ($response->protocol || 'HTTP/1.0') eq 'HTTP/1.1';
	push @return, warning 'Action with side effects conducted for a '.$request->method.' request' => 13,9
		if $request->method =~ /^(GET|HEAD|TRACE|OPTIONS)$/
		and $response->code == 201;
	push @return, error 'HEAD response with non-empty body' => 4,3
		if $request->method eq 'HEAD'
		and $response->content;
	push @return, warning 'TRACE response with wrong content type' => 9,8
		if $request->method eq 'TRACE'
		and ($response->header ('Content-Type') || '') ne 'message/http';
	push @return, error 'Partial content returned despite not being asked for' => 14,35,2
		if $response->code eq 206
		and not defined $request->header ('Range');
	push @return, error 'Server demands length despite being given it' => 10,4,12
		if $response->code eq 411
		and $request->header ('Content-Length');
	push @return, error 'Server complains about bad range without range being requested' => 10,4,17
		if $response->code eq 416
		and not $request->header ('Range');

	return @return;
}

package HTTP::Lint::Message;

use overload fallback => 1,
	'""' => \&pretty;

sub pretty
{
	my $self = shift;
	$self->isa ('HTTP::Lint::Message')
		or die 'Not a HTTP::Lint::Message';
	return (ref $self eq 'HTTP::Lint::Error' ? 'ERROR: ' : 'WARNING: ').
		$self->[0].
		(@{$self->[1]} ? ' [RFC2616: '.join ('.', @{$self->[1]}).']': '');
}

=back

=head1 SEE ALSO

=over

=item *

L<http://www.w3.org/Protocols/rfc2616/rfc2616.html> -- HTTP/1.1 protoocl specification

=item *

L<http://www.w3.org/Protocols/HTTP/1.1/rfc2616bis/issues/> -- Ambigious stuff in RFC2616

=item *

L<HTTP::Message> -- Object representation of a HTTP message

=back

=head1 BUGS

Probably many!

The set of checks is very incomplete and some are likely wrong and produce
false positives.

Contributions, patches and bug reports are more than welcome.

=head1 COPYRIGHT

Copyright 2011, Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Lubomir Rintel C<lkundrak@v3.sk>

=cut

1;
