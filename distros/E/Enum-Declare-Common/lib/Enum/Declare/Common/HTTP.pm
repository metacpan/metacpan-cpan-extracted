package Enum::Declare::Common::HTTP;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

our @EXPORT = qw(is_info is_success is_redirect is_client_error is_server_error);
our @EXPORT_OK = @EXPORT;

# ── Status Codes (integer enum with explicit values) ──

enum StatusCode :Type :Export {
	Continue           = 100,
	SwitchingProtocols = 101,
	Processing         = 102,
	EarlyHints         = 103,

	OK                    = 200,
	Created               = 201,
	Accepted              = 202,
	NonAuthoritativeInfo  = 203,
	NoContent             = 204,
	ResetContent          = 205,
	PartialContent        = 206,

	MultipleChoices   = 300,
	MovedPermanently  = 301,
	Found             = 302,
	SeeOther          = 303,
	NotModified       = 304,
	TemporaryRedirect = 307,
	PermanentRedirect = 308,

	BadRequest            = 400,
	Unauthorized          = 401,
	PaymentRequired       = 402,
	Forbidden             = 403,
	NotFound              = 404,
	MethodNotAllowed      = 405,
	NotAcceptable         = 406,
	RequestTimeout        = 408,
	Conflict              = 409,
	Gone                  = 410,
	LengthRequired        = 411,
	PreconditionFailed    = 412,
	PayloadTooLarge       = 413,
	URITooLong            = 414,
	UnsupportedMediaType  = 415,
	RangeNotSatisfiable   = 416,
	ExpectationFailed     = 417,
	ImATeapot             = 418,
	UnprocessableEntity   = 422,
	TooEarly              = 425,
	UpgradeRequired       = 426,
	PreconditionRequired  = 428,
	TooManyRequests       = 429,
	RequestHeaderFieldsTooLarge = 431,
	UnavailableForLegalReasons  = 451,

	InternalServerError     = 500,
	NotImplemented          = 501,
	BadGateway              = 502,
	ServiceUnavailable      = 503,
	GatewayTimeout          = 504,
	HTTPVersionNotSupported = 505,
	InsufficientStorage     = 507,
	NetworkAuthenticationRequired = 511
};

# ── HTTP Methods ──

enum Method :Str :Type :Export {
	GET,
	POST,
	PUT,
	PATCH,
	DELETE,
	HEAD,
	OPTIONS,
	TRACE
};

# ── Helper functions ──

sub is_info         { my $c = shift; $c >= 100 && $c < 200 }
sub is_success      { my $c = shift; $c >= 200 && $c < 300 }
sub is_redirect     { my $c = shift; $c >= 300 && $c < 400 }
sub is_client_error { my $c = shift; $c >= 400 && $c < 500 }
sub is_server_error { my $c = shift; $c >= 500 && $c < 600 }

1;

=head1 NAME

Enum::Declare::Common::HTTP - HTTP status codes, methods, and classification helpers

=head1 SYNOPSIS

    use Enum::Declare::Common::HTTP;

    say OK;              # 200
    say NotFound;        # 404
    say GET;             # "GET"

    if (is_success($code))      { ... }
    if (is_client_error($code)) { ... }

    my $meta = StatusCode();
    say $meta->name(200);    # "OK"

=head1 ENUMS

=head2 StatusCode :Export

Integer enum of standard HTTP status codes (100-511).

=head2 Method :Str :Export

HTTP method strings: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, TRACE.

=head1 FUNCTIONS

=over 4

=item is_info($code) — true for 1xx

=item is_success($code) — true for 2xx

=item is_redirect($code) — true for 3xx

=item is_client_error($code) — true for 4xx

=item is_server_error($code) — true for 5xx

=back

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
