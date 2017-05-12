package HTTP::StreamParser;
# ABSTRACT: streaming HTTP parser
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

our $VERSION = '0.101';

=head1 NAME

HTTP::StreamParser - support for streaming HTTP request/response parsing

=head1 VERSION

version 0.101

=head1 SYNOPSIS

 # For requests...
 my $req_parser = HTTP::StreamParser::Request->new;
 $req_parser->subscribe_to_event(
   http_method => sub { print "Method: $_[1]\n" },
   http_uri    => sub { print "URI:    $_[1]\n" },
   http_header => sub { print "Header: $_[1]: $_[2]\n" },
 );
 $req_parser->parse(<<'EOF');
 ...
 EOF

 # ... and responses:
 my $resp_parser = HTTP::StreamParser::Request->new;
 $resp_parser->subscribe_to_event(
   http_code   => sub { print "Code:   $_[1]\n" },
   http_status => sub { print "Status: $_[1]\n" },
   http_header => sub { print "Header: $_[1]: $_[2]\n" },
 );
 $resp_parser->parse(<<'EOF');
 ...
 EOF

=head1 DESCRIPTION

Parses HTTP requests or responses. Generates events. Should be suitable for streaming.
You may be looking for L<HTTP::Parser::XS> instead - it's at least 20x faster than
this module. If you wanted something without XS, there's L<HTTP::Parser>.

Actual implementation is in L<HTTP::StreamParser::Request> or L<HTTP::StreamParser::Response>.

Typically you'd instantiate one of these for each request you want to parse. You'd then
subscribe to the events you're interested in - for example, header information, request method,
etc. - and then start parsing via L</parse>.

=cut

use List::Util qw(min);

use constant BODY_CHUNK_SIZE => 4096;

my $CRLF = "\x0d\x0a";

=head2 new

Instantiates a new parser object.

=cut

sub new {
	my $class = shift;
	my $self = bless +{
		text => '',
	}, $class;
	$self->{state_pending} = [ $self->state_sequence ];
	$self->{state} = shift @{$self->{state_pending}};
	$self
}

=head2 parse

Adds the given data to the pending buffer, and calls the state handler to check
whether we have enough data to do some useful parsing.

=cut

sub parse {
	my $self = shift;
	my $text = shift;
	$self->{text} .= $text;
	$self->handle_state;
}

=head2 parse_state

Sets the current parse state, then calls the state handler.

=cut

sub parse_state {
	my $self = shift;
	my $state = shift;
	$self->{state} = $state;
	$self->handle_state;
}

=head2 next_state

Moves to the next parser state.

=cut

sub next_state {
	my $self = shift;
	my $next_state = shift @{$self->{state_pending}};
	# say "Parse state was " . $self->{state} . " now " . $next_state;
	$self->parse_state($next_state);
}

=head2 handle_state

Call the handler for our current parser state.

=cut

sub handle_state {
	my $self = shift;
	die "Unknown state [" . $self->{state} . "]" unless my $handler = $self->can($self->{state});
	$handler->($self, \$self->{text});
}

{ # Common subset of methods, subclass if you need any others
my %methods = map { $_ => 1 } qw(
	CONNECT COPY DELETE DELTA FILEPATCH GET HEAD LOCK MKCOL
	MOVE OPTIONS PATCH POST PROPFIND PROPPATCH PUT SIGNATURE
	TRACE TRACK UNLOCK
);

=head2 validate_method

Validate the HTTP request method. Currently accepts any of these:

=over 4

=item * CONNECT

=item * COPY

=item * DELETE

=item * DELTA

=item * FILEPATCH

=item * GET

=item * HEAD

=item * LOCK

=item * MKCOL

=item * MOVE

=item * OPTIONS

=item * PATCH

=item * POST

=item * PROPFIND

=item * PROPPATCH

=item * PUT

=item * SIGNATURE

=item * TRACE

=item * TRACK

=item * UNLOCK

=back

=cut

sub validate_method { exists $methods{$_[1]} }
}

=head2 http_method

Parses the HTTP method information.

=cut

sub http_method {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s/^([A-Z]+)(?=\s)//) {
		$self->{method} = $1;
		die "invalid method ". $self->{method} unless $self->validate_method($self->{method});
		$self->invoke_event(http_method => $self->{method});
		$self->next_state;
	}
	return $self
}

=head2 validate_code

Validate whether we have a sensible HTTP status code - currently, any code >= 100 is accepted.

=cut

sub validate_code { $_[1] >= 100 }

=head2 http_code

Parse an HTTP status code.

=cut

sub http_code {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s/^(\d{3})(?=\s)//) {
		$self->{code} = $1;
		die "invalid response code ". $self->{code} unless $self->validate_code($self->{code});
		$self->invoke_event(http_code => $self->{code});
		$self->next_state;
	}
	return $self
}

=head2 http_status

Parse the HTTP status information - this is everything after the code to the end of the line.

=cut

sub http_status {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s/^(.*?)(?=$CRLF)//) {
		$self->{status} = $1;
		$self->invoke_event(http_status => $self->{status});
		$self->next_state;
	}
	return $self
}

=head2 http_uri

Parse URI information. Anything up to whitespace.

=cut

sub http_uri {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s{^(.*)(\s+http/\d+\.\d+$CRLF)}{$2}i) {
		$self->{uri} = $1;
		$self->invoke_event(http_uri => $self->{uri});
		$self->next_state;
	}
	return $self
}

=head2 http_version

Parse HTTP version information. Typically expects HTTP/1.1.

=cut

sub http_version {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s{^(HTTP)/(\d+.\d+)(?=\s)}{}i) {
		$self->{proto} = $1;
		$self->{version} = $2;
		$self->invoke_event(http_version => $self->{proto}, $self->{version});
		$self->next_state;
	}
	return $self
}

{ # Some headers can have multiple values, these can be a mix of comma-separated or split as K: x, K: y
my %multi_valued = map { $_ => 1 } qw(Accept Accept-Encoding Accept-Charset Accept-Language Connection Via TE);

=head2 http_headers

Parse HTTP header lines.

=cut

sub http_headers {
	my $self = shift;
	my $buf = shift;
	while($$buf =~ s{^([^:]+):(?: )*([^$CRLF]+)$CRLF}{}) {
		my $k = $1;
		my $v = $2;
		$self->{remaining} = 0+$v if lc($k) eq 'content-length';
		if(exists $multi_valued{$k}) {
			for (split /\s*,\s*/, $v) {
				$self->invoke_event(http_header => $k => $_);
			}
		} else {
			$self->invoke_event(http_header => $k => $v);
		}
	}
	if($$buf =~ s{^$CRLF}{}) {
		$self->invoke_event(http_body_start =>);
		$self->next_state;
	}
	return $self
}
}

=head2 single_space

Parse a single space character.

Returns $self.

=cut

sub single_space {
	my $self = shift;
	my $buf = shift;
	return $self->next_state if $$buf =~ s{^ }{};
	return $self
}

=head2 newline

Parse the "newline" (CRLF) characters.

Returns $self.

=cut

sub newline {
	my $self = shift;
	my $buf = shift;
	return $self->next_state if $$buf =~ s{^$CRLF}{};
	return $self
}

=head2 http_body

Parse body chunks.

Returns $self.

=cut

sub http_body {
	my $self = shift;
	my $buf = shift;
	while(length $$buf) {
		my $chunk = substr $$buf, 0, min(BODY_CHUNK_SIZE, length($$buf), $self->{remaining} // ()), '';
		$self->{remaining} -= length $chunk if defined $self->{remaining};
		$self->invoke_event(http_body_chunk => $chunk, $self->{remaining});
	}
	$self->invoke_event(http_body_end =>) if 0 == ($self->{remaining} // 1);
	return $self
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<HTTP::Parser::XS> - used by several other modules, fast implementation, pure-Perl fallback,
but doesn't give access to the data until the headers have been parsed and aside from header count and
per-header size limitation, seems not to have any way to deal with oversized requests

=item * L<HTTP::Parser> - parses into L<HTTP::Request>/L<HTTP::Response> objects. Doesn't seem to guard
against large buffers but does have at least some support for streaming.

=item * L<HTTP::MessageParser> - also parses HTTP content

=item * L<Mojo::Message::Request> - part of L<Mojolicious>

=item * L<Mojo::Message::Response> - part of L<Mojolicious>

=item * L<HTTP::Response::Parser> - parses responses...

=item * L<POE::Filter::HTTP::Parser> - seems to be backed by L<HTTP::Parser::XS> / L<HTTP::Parser>

=item * L<HTTP::HeaderParser::XS> - only parses the headers, albeit with some speed

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2013. Licensed under the same terms as Perl itself.
