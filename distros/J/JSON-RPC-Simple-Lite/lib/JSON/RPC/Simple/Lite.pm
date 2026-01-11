package JSON::RPC::Simple::Lite;

use vars '$AUTOLOAD';
use HTTP::Tiny;
use JSON::PP;
use Time::HiRes qw(time);

our $VERSION = '0.1';

sub new {
	my $class = shift();
	my $url   = shift();
	my $opts  = shift();

	my $attrs = {
		'agent'   => 'JSON::RPC::Simple::Lite',
		'timeout' => 45,
	};

	my $self  = {
		"version"     => $version,
		"api_url"     => $url,
		"opts"        => $opts,
		"http"        => HTTP::Tiny->new(%$attrs),
		"breadcrumbs" => [],
	};

	bless $self, $class;

    return $self;
}

sub _call {
	my ($self,$method,@params) = @_;

	my $start = time();
	my $url   = $self->{api_url};
	my $json  = $self->create_request($method,@params);
	my $debug = $self->{opts}->{debug};

	if ($debug) {
		print "RPC URL  : $url\n";
		print "Sending  : " . $json . "\n";
	}

	my $opts = {
		content => $json,
		headers => { 'Content-Type' => 'application/json;charset=UTF-8' },
	};

	my $resp      = $self->{http}->post($url,$opts);
	my $status    = $resp->{status};
	my $json_resp = $resp->{content};

	my $total_ms = int((time() - $start) * 1000);

	$self->{response} = $resp;

	if ($debug) {
		print "Received : " . $json_resp . "\n";
		print "HTTP Code: $status\n";
		print "Query ms : $total_ms\n\n";
	}

	if ($status != 200) {
		#return undef;
	}

	my $ret = {};
	eval {
		$ret = decode_json($json_resp);

		if ($ret->{result}) {
			$ret = $ret->{result};
		}
	};

	# There was an error with decoding the JSON
	if ($@) {
		print $@;
		return undef;
	}

	$self->{breadcrumbs} = [];

	return $ret;
}

sub create_request {
	my ($self,$method,@params) = @_;

	my $hash = {
		"method"  => $method,
		"version" => 1.1,
		"id"      => 1,
		"params"  => \@params,
	};

	my $obj = JSON::PP->new();

	# If we're doing unit testing we need the JSON output to be consistent.
	# Specifying canonical = 1 makes the JSON output in alphabetical order.
	# This adds overhead though, so we only enable it for unit testing.
	if ($ENV{'HARNESS_ACTIVE'}) {
		my $ok = $obj->canonical(1);
	}

	my $json = $obj->encode($hash);

	return $json;
}

sub AUTOLOAD {
	my $self   = shift;
	my $func   = $AUTOLOAD;
	my @params = @_;

	# Remove the class name, we just want the function that was called
	my $str = __PACKAGE__ . "::";
	$func =~ s/$str//;

	push(@{$self->{breadcrumbs}},$func);

	# If there are params it's the final function call
	if (@params) {
		my $method = join(".",@{$self->{breadcrumbs}});
		my $ret = $self->_call($method,@params);

		return $ret;
	}

	return $self;
}

sub curl_call {
	my ($self,$method,@params) = @_;

	my $json = $self->create_request($method,@params);
	my $url  = $self->{api_url};

	#curl -d '{"id":"json","method":"add","params":{"a":2,"b":3} }' -o - http://domain.com
	my $curl = "curl --data '$json' $url";

	return $curl;
}

=head1 NAME

JSON::RPC::Simple::Lite - A simple and lite JSON-RPC client.

=head1 DESCRIPTION

C<JSON::RPC::Simple::Lite> provides a simple interface for JSON-RPC APIs.
It uses C<HTTP::Tiny> for the backend transfer and supports all the
interfaces that library does.

=head1 USAGE

  JSON::RPC::Simple::Lite;

  my $api_url = "https://www.perturb.org/api/json-rpc/";
  my $opts    = { debug => 0 };
  my $json    = JSON::RPC::Simple::Lite->new($api_url, $opts);

  # Direct using _call()
  my $resp = $json->_call($method, @params);

  # OOP style using chaining and AUTOLOAD magic
  my $str = $json->echo_data("Hello world!");
  my $num = $json->math->sum(1, 4);

  # Get the curl command for this call
  my $curl_str = $json->curl_call($method, @params);

=head1 FUNCTIONS

=head2 _call($method, @params)

Call the remote function C<$method> passing it C<@params>. The return value is
the response from the server.

=head2 curl_call($method, @params)

Returns a string that represents a command line Curl call of C<$method>.
This can be useful for debugging and testing.

=head1 OBJECT ORIENTED INTERFACE

C<JSON::RPC::Simple::Lite> allows a pseudo OOP interface using AUTOLOAD.
This allows you to chain calls in different namespaces together which gets
mapped to the correct method name before calling.

  $json->user->email->login($user, $pass); # Maps to method 'user.email.login'

This format can make your code cleaner and easier to read.

B<Note:> This does require that
your final method include B<some> parameter. If your function does not require
any params pass C<undef> or use the explicit C<_call()> method.

=head1 DEBUG

If debug is passed in via the constructor options JSON information will be
printed to C<STDOUT>.

=head1 AUTHORS

Scott Baker - https://www.perturb.org/

=cut

1;
