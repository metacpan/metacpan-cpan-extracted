package Finance::GDAX::API;
our $VERSION = '0.07';
use 5.20.0;
use warnings;
use JSON;
use Moose;
use REST::Client;
use MIME::Base64;
use Digest::SHA qw(hmac_sha256_base64);
use Finance::GDAX::API::URL;
use namespace::autoclean;

has 'debug' => (is  => 'rw',
		isa => 'Bool',
		default => 1,
    );
has 'key' => (is  => 'rw',
	      isa => 'Str',
	      default => sub {$ENV{GDAX_API_KEY} || ''},
	      lazy    => 1,
    );
has 'secret' => (is  => 'rw',
		 isa => 'Str',
		 default => sub {$ENV{GDAX_API_SECRET} || ''},
		 lazy    => 1,
    );
has 'passphrase' => (is  => 'rw',
		     isa => 'Str',
		     default => sub {$ENV{GDAX_API_PASSPHRASE} || ''},
		     lazy    => 1,
    );
has 'method' => (is  => 'rw',
		 isa => 'Str',
		 default => 'POST',
    );
has 'path' => (is  => 'rw',
	       isa => 'Str',
    );
has 'body' => (is  => 'rw',
	       isa => 'Ref',
    );
has 'timestamp' => (is  => 'ro',
		    isa => 'Int',
		    default => sub { time },
    );
has 'timeout' => (is  => 'rw',
		  isa => 'Int',
    );

has 'error' => (is  => 'ro',
		isa => 'Str',
		writer => '_set_error',
    );
has 'response_code' => (is  => 'ro',
			isa => 'Int',
			writer => '_set_response_code',
    );
has '_body_json' => (is  => 'ro',
		     isa => 'Maybe[Str]',
		     writer => '_set_body_json',
    );

sub send {
    my $self = shift;
    my $client = REST::Client->new;
    my $url    = Finance::GDAX::API::URL->new(debug => $self->debug);
    
    $url->add($self->path);
    
    $client->addHeader('CB-ACCESS-KEY',        $self->key);
    $client->addHeader('CB-ACCESS-SIGN',       $self->signature);
    $client->addHeader('CB-ACCESS-TIMESTAMP',  $self->timestamp);
    $client->addHeader('CB-ACCESS-PASSPHRASE', $self->passphrase);
    $client->addHeader('Content-Type',         'application/json');

    my $method = $self->method;
    $client->setTimetout($self->timeout) if $self->timeout;
    $self->_set_error('');
    if ($method =~ /^(GET|DELETE)$/) {
	$client->$method($url->get);
    }
    elsif ($method eq 'POST') {
	$client->$method($url->get, $self->body_json);
    }

    my $content = JSON->new->decode($client->responseContent);
    $self->_set_response_code($client->responseCode);
    if ($self->response_code >= 400) {
	$self->_set_error( $$content{message} || 'no error message returned' );
    }
    return $content;
}

sub signature {
    my $self = shift;
    my $json = JSON->new;
    my $data = $self->timestamp
	.$self->method
	.$self->path;
    $data .= $self->body_json if $self->body;
    my $digest = hmac_sha256_base64($data, decode_base64($self->secret));
    while (length($digest) % 4) {
     	$digest .= '=';
    }
    return $digest;
}

sub body_json {
    my $self = shift;
    return $self->_body_json if defined $self->_body_json;
    $self->_set_body_json(JSON->new->encode($self->body));
    return $self->_body_json;;
}

sub external_secret {
    my ($self, $filename, $fork) = @_;
    return unless $filename;
    my @valid_attributes = ('key', 'secret', 'passphrase');
    my @input;
    if ($fork) {
	chomp(@input = `$filename`);
    }
    else {
	open FILE, "<", $filename or die "Cannot open $filename: $!";
	chomp(@input = <FILE>);
	close FILE;
    }
    foreach (@input) {
	my ($key, $val) = split /:/;
	next if !$key;
	next if /^\s*\#/;
	unless (grep /^$key$/, @valid_attributes) {
	    die "Bad attribute found in $filename ($key)";
	}
	$self->$key($val);
    }
    return 1;
}

sub save_secrets_to_environment {
    my $self = shift;
    $ENV{GDAX_API_KEY}        = $self->key;
    $ENV{GDAX_API_SECRET}     = $self->secret;
    $ENV{GDAX_API_PASSPHRASE} = $self->passphrase;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API - Build and sign GDAX REST request

=head1 SYNOPSIS

  $req = Finance::GDAX::API->new(
                        key        => 'My API Key',
                        secret     => 'My API Secret Key',
                        passphrase => 'My API Passphrase');

  $req->path('accounts');
  $account_list = $req->send;

  # Use the more specific classes, for example Account:

  $account = Finance::GDAX::API::Account->new(
                        key        => 'My API Key',
                        secret     => 'My API Secret Key',
                        passphrase => 'My API Passphrase');
  $account_list = $account->get_all;
  $account_info = $account->get('89we-wefjbwe-wefwe-woowi');

  # If you use Environment variables to store your secrects, you can
  # omit them in the constructors (see the Attributes below)

  $order = Finance::GDAX::API::Order->new;
  $orders = $order->list(['open','settled'], 'BTC-USD');

=head1 DESCRIPTION

Creates a signed GDAX REST request - you need to provide the key,
secret and passphrase attributes, or specify that they be provided by
the external_secret method.

All Finance::GDAX::API::* modules extend this class to implement their
particular portion of the GDAX API.

This is a low-level implementation of the GDAX API and complete,
except for supporting result paging.

Return values are generally returned as references to arrays, hashes,
arrays of hashes, hashes of arrays and all are documented within each
method.

All REST requests use https requests.

=head1 ATTRIBUTES

=head2 C<debug> (default: 1)

Use debug mode (sandbox) or prouduction. By default requests are done
with debug mode enabled which means connections will be made to the
sandbox API. To do live data, you must set debug to 0.

=head2 C<key>

The GDAX API key. This defaults to the environment variable
$ENV{GDAX_API_KEY}

=head2 C<secret>

The GDAX API secret key. This defaults to the environment variable
$ENV{GDAX_API_SECRET}

=head2 C<passphrase>

The GDAX API passphrase. This defaults to the environment variable
$ENV{GDAX_API_PASSPHRASE}

=head2 C<error>

Returns the text of an error message if there were any in the request.

=head2 C<response_code>

Returns the numeric HTTP status code of the request.

=head2 C<method> (default: POST)

REST method to use when data is submitted. Must be in upper-case.

=head2 C<path>

The URI path for the REST method, which must be set or errors will
result. Leading '/' is not required.

=head2 C<body>

A reference to an array or hash that will be JSONified and represents
the data being sent in the REST request body. This is optional.

=head2 C<timestamp> (default: current unix epoch)

An integer representing the Unix epoch of the request. This defaults
to the current epoch time and will remain so as long as this object
exists.

=head2 C<timeout> (default: none)

Integer time in seconds to wait for response to request.

=head1 METHODS

=head2 C<send>

Sends the GDAX API request, returning the JSON response content as a
perl data structure. Each Finance::GDAX::API::* class documents this
structure (what to expect), as does the GDAX API (which will always be
authoritative).

=head2 C<external_secret> filename, fork?

If you want to avoid hard-coding secrets into your code, this
convenience method may be able to help.

The method looks externally, either to a filename (default) or calls
an executable file to provide the secrets via STDIN.

Either way, the source of the secrets should provide key/value pairs
delimited by colons, one per line:

key:ThiSisMybiglongkey
secret:HerEISmYSupeRSecret
passphrase:andTHisiSMypassPhraSE

There can be comments ("#" beginning a line), and blank lines.

In other words, for exmple, if you cryptographically store your API
credentials, you can create a small callable program that will decrypt
them and provide them, so that they never live on disk unencrypted,
and never show up in process listings:

  my $request = Finance::GDAX::API->new;
  $request->external_secret('/path/to/my_decryptor', 1);

This would assign the key, secret and passphrase attributes for you by
forking and running the 'my_decryptor' program. The 1 designates a
fork, rather than a file read.

This method will die easily if things aren't right.

=head2 C<save_secrets_to_environment>

Another convenience method that can be used to store your secrets into
the volatile environment in which your perl is running, so that
subsequent GDAX API object instances will not need to have the key,
secret and passphrase set.

You may not want to do this! It stores each attribute, "key", "secret"
and "passphrase" to the environment variables "GDAX_API_KEY",
"GDAX_API_SECRET" and "GDAX_API_PASSPHRASE", respectively.

=head1 METHODS you probably don't need to worry about

=head2 C<signature>

Returns a string, base64-encoded representing the HMAC digest
signature of the request, generated from the secrey key.

=head2 C<body_json>

Returns a string, the JSON-encoded representation of the data
structure referenced by the "body" attribute. You don't normally need
to look at this.

=cut

=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

