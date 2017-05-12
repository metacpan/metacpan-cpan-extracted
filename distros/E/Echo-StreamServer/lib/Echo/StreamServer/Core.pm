package Echo::StreamServer::Core;

use strict;
use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;
use URI;
use JSON;

use Data::Dumper;

use Echo::StreamServer::Settings;

# ======================================================================
# Export the Core API Subroutines (Not Object-Oriented)
# ======================================================================
use Exporter;
our @ISA = qw(Exporter);

# Export the Core API Subroutines.
our @EXPORT = qw(send_request);

our $VERSION = '0.07';

# ======================================================================
# Toggle DEBUG flag to print to STDERR.
# ======================================================================
our $DEBUG = 0;

# ======================================================================
# REST API: Document Format: JSON
# ======================================================================

my $HTTP_HEADERS = HTTP::Headers->new;
$HTTP_HEADERS->header('User-Agent'   => "Echo/StreamServer API (PERL $VERSION)");
$HTTP_HEADERS->header('Accept'       => 'application/json');
$HTTP_HEADERS->header('Content-Type' => 'application/json');

# ======================================================================
# UserAgent: Assume no multi-thread contention on the shared $ua.
# ======================================================================
# TODO: Configure the LWP::UserAgent elsewhere, and set it here.

my $ua = LWP::UserAgent->new;
$ua->timeout($ECHO_TIMEOUT);
$ua->env_proxy;

# ======================================================================
# Build Echo Stream Server REST URL from Settings & method name.
# ======================================================================
sub echo_server_url {
	my ($api_method) = @_;
	return "https://$ECHO_HOST/$ECHO_VERSION/$api_method";
}

# ======================================================================
# URL-encode POST payload as form input.
# ======================================================================
use URI::Escape;

sub urlencode_form_params {
        my ($param_hash_ref) = @_;
        my @params = ();

        foreach my $key (keys(%$param_hash_ref)) {
                my $enc_key = uri_escape($key);
                my $enc_value = uri_escape($param_hash_ref->{$key});
                push(@params, join('=', ($enc_key, $enc_value)));
        }
        return join('&', @params);
}

# ======================================================================
# StreamServer API: Server-Side Exception
# ======================================================================
# Parse the JSON document for the (exception-name, message).
# Returns: A string representing the HTTP $response exception.
# NOTE: This should be wrapped in a die(..), or warn(..) statement.
sub get_server_error {
	my $response = shift;

	# Present JSON (exception-name, message) pair as string.
	my $err_str = $response->status_line;
	eval {
		my $err_hash_ref = decode_json($response->content());
		$err_str = "[" . ($err_hash_ref->{errorCode} or 'fatal_error') . "] "
			. ($err_hash_ref->{'errorMessage'} or 'no message');

		if ($DEBUG) { print STDERR "JSON Error Codes: " . Dumper($err_hash_ref) . "\n"; }
	};
	warn("Echo StreamServer: JSON Error document is invalid!") if ($@);

	return "Echo StreamServer Error: " . $err_str . "\n";
}

# ======================================================================
# REST API: Send a StreamServer API HTTP Request to ECHO.
# ======================================================================
# Returns: The Echo response data, usually JSON data. 
#   When is_xml is a true value, the XML document is returned.
#   Otherwise, is_xml is false, and the JSON document is parsed.
# ======================================================================
sub send_request {
	my ($account_obj, $api_method, $param_hash_ref, $http_post, $is_xml) = @_;

	if ($DEBUG) {
		print STDERR "send_request($account_obj, $api_method, $param_hash_ref, $http_post, $is_xml);\n";
	}

	# ===============================================================
	# Construct %params, i.e. the QUERY_STRING...
	# ===============================================================
	my %params = ();
	if ($param_hash_ref) {
		%params = %$param_hash_ref;
	}

	# Send HTTP Request with query %params.
	# ===============================================================
	my $REST_URL = echo_server_url($api_method);
	my $payload = undef;
	if ($http_post) {
		# POST Request: Create URL-encoded $payload.
		$payload = urlencode_form_params(\%params);
	}
	else {
		# GET Request: Add QUERY_STRING filter params to URI.
		my $uri = URI->new($REST_URL);
		$uri->query_form(\%params);
		$REST_URL = $uri->as_string;
	}
	if ($DEBUG) { print STDERR "send_request: Echo REST URL=$REST_URL\n"; }
	# ===============================================================
	# Catch HTTP Request exceptions...
	# NOTE: The return variable, $resp_document, must be declared
	#       outside the eval { ... }; block, and returned after it!
	# ===============================================================
	# Returns a JSON document to be parsed.
	my $resp_document = '';
	eval {
		my $request = HTTP::Request->new(($payload)? 'POST': 'GET',
					$REST_URL, $HTTP_HEADERS, $payload);
		# TODO: Allow 2-Legged OAuth...
		# Basic Authorization:
		$request->authorization_basic($account_obj->{'appkey'}, $account_obj->{'secret'});

		my $response = $ua->request($request);
		if ($response->is_success) {
			$resp_document = $response->content();
		}
		else {
                        die(get_server_error($response));
		}
	};
	die("$@\n") if ($@);

	# Parse JSON to nested-hash and return.
        unless ($is_xml) {
		$resp_document = decode_json($resp_document);
	}

	return $resp_document;
}


1;
__END__

=head1 Echo StreamServer API

Core REST Features to send Echo StreamServer requests over HTTP

=head1 SYNOPSIS

	use Echo::StreamServer::Settings;

	use Echo::StreamServer::Core;
	$Echo::StreamServer::Core::DEBUG=1;

        # Account as an unblessed hash ref:
       	my $account = { 'appkey' => $ECHO_API_KEY, 'secret' => $ECHO_API_SECRET };

	# Key-Value Store API: Get data for the key "sample".
	my %params = (
                'key' => 'sample',
                'appkey' => $ECHO_API_KEY,
	);
	my $json_hash_ref = send_request($account, 'kvs/get', \%params);

=head1 DESCRIPTION

This is a PERL version of the Echo StreamServer API.
http://aboutecho.com/developers/index.html

    feeds - Feeds API
    items - Items API
    kvs   - Key-Value Store API
    users - User API

Most API methods raise StreamServer exception strings.
This indicates a server-side error, or malformed request.

Echo StreamServer Core API is a REST interface using JSON. It is a I<raw> B<HTTP> client.

=head2 Functions

=over

=item C<send_request>

Send REST request via HTTP B<GET> or B<POST> method when C<$http_post> is a true value.
Both the B<GET> and B<POST> methods send URL-encoded form parameters, according the the StreamServer API method.
Returns the JSON response document parased into a PERL hash.

=back

=head1 LICENSE

(C) Advance Digital 2012

=head1 AUTHOR

Andrew Droffner

=cut

