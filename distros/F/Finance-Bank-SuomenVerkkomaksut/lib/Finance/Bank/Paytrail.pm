package Finance::Bank::Paytrail;
BEGIN {
  $Finance::Bank::Paytrail::AUTHORITY = 'cpan:OKKO';
}
$Finance::Bank::Paytrail::VERSION = '0.010';
use Moose;
use utf8;

use Data::Dumper;
use JSON::XS;
use Net::SSLeay qw/post_https make_headers/;
use Digest::MD5 qw/md5_hex/;
use MIME::Base64;

# These are used when test_transaction() is set to true to signal a test payment is in effect.
has 'test_merchant_id'     => ( is => 'ro', default => '13466' );
has 'test_merchant_secret' => ( is => 'ro', default => '6pKF4jkv97zmqBJ3ZL8gUw5DfT2NMQ' );

=encoding utf-8
=cut

# ABSTRACT: Process payments through JSON API of Paytrail (Suomen Verkkomaksut) in Finland. Payments from all Finnish Banks online: Nordea, Osuuspankki, Sampo, Tapiola, Aktia, Nooa, Paikallisosuuspankit, Säästöpankit, Handelsbanken, S-Pankki, Ålandsbanken, also from Visa, Visa Electron, MasterCard credit cards through Luottokunta, and PayPal, billing through Collector and Klarna.

=head1 NAME

Finance::Bank::Paytrail - Process payments through JSON API of Paytrail (Suomen Verkkomaksut) in Finland. Payments from all Finnish Banks online: Nordea, Osuuspankki, Sampo, Tapiola, Aktia, Nooa, Paikallisosuuspankit, Säästöpankit, Handelsbanken, S-Pankki, Ålandsbanken, also from Visa, Visa Electron, MasterCard credit cards through Luottokunta, and PayPal, billing through Collector and Klarna.

=head1 SYNOPSIS

    use Finance::Bank::Paytrail;

    # Creating a new payment
    my $tx = Finance::Bank::Paytrail->new({merchant_id => 'XXX', merchant_secret => 'YYY'});
    # All content in accordance to http://docs.paytrail.com/ field specs
    $tx->content({
            orderNumber => 1,
            referenceNumber => 13,
            description => 'Order 1',
            currency => 'EUR',
            locale => 'fi_FI',
            urlSet => {success => $c->uri_for('/payment/success').'/',
                       failure => $c->uri_for('/payment/failure').'/',
                       pending => $c->uri_for('/payment/pending').'/',
                       notification => $c->uri_for('/payment/notification').'/',
            },
            orderDetails => {
                includeVat => 1,
                contact => {
                    firstName => 'First',
                    lastName => 'Last',
                    email => 'first@example.com',
                    telephone => '555123',
                    address => {
                        street => 'Street 123',
                        postalCode => '00100',
                        postalOffice => 'Helsinki',
                        country => 'FI',
                    }
                },
                products => [
                    {
                        "title" => 'Product title',
                        "amount" => "1.00",
                        "price" => 123,
                        "vat" => "0.00",
                        "discount" => "0.00",
                        "type" => "1", # 1=normal product row
                    },
                    ],
            },

    });

    # set to 1 when you are developing, 0 in production
    $tx->test_transaction(1);

    my $submit_result = $tx->submit();
    if ($submit_result) {
        print "Please go to ". $tx->url() ." $url to pay your order number ". $tx->order_number().', see you soon.';
    } else {
        die 'Failed to generate payment';
    }

    # Verifying the payment when the user returns or when the notify address receives a request
    my $tx = Finance::Bank::Paytrail->new({merchant_id => 'XXX', merchant_secret => 'YYY'});
    my $checksum_matches = $tx->verify_return({
            ORDER_NUMBER => $c->req->params->{ORDER_NUMBER},
            TIMESTAMP => $c->req->params->{TIMESTAMP},
            PAID => $c->req->params->{PAID},
            METHOD => $c->req->params->{METHOD},
            RETURN_AUTHCODE => $c->req->params->{RETURN_AUTHCODE}
    });
    if ($checksum_matches) {
        # depending on the return address, mark payment as paid (if returned to RETURN_ADDRESS),
        # as pending (if returned to PENDING_ADDRESS) or as canceled (if returned to CANCEL_ADDRESS).
        if ($url eq $return_url) {
            # &ship_products();
        }
    } else {
        print "Checksum mismatch, returning not processed. Please contact our customer service if you believe this to be an error.";
    }

=cut

=head2 merchant_id

The merchant id given to you by Paytrail when you make the contract. Defaults to the test merchant account.

=cut

has 'merchant_id'     => ( is => 'rw', default => '13466' );

=head2 merchant_secret

The merchant secret given to you by Paytrail. Defaults to the test merchant account.

=cut

has 'merchant_secret' => ( is => 'rw', default => '6pKF4jkv97zmqBJ3ZL8gUw5DfT2NMQ' );

=head2 test_transaction

Set to 1 to mark the mode as a test. In that case the test merchant account of Paytrail is used and no real money is transferred. Intended for testing.

=cut

has 'test_transaction' => ( is => 'rw', default => 0 );

=head2 debug

Set to 1 to get debug warnings. Defaults to 0, no debug.

=cut

has 'debug' => ( is => 'rw', default => 0 );

=head2 content

Set the content to be sent to Paytrail API. All content must be in accordance to http://docs.paytrail.com/ field specs, as a Perl data structure.

=cut

has 'content' => ( is => 'rw', default => sub { {}; } );

=head2 submit

Submits the content to Paytrail API. Populates is_success, url, server_response_json, server_response, result_code, error_message, token and order_number.

=cut

sub submit {
    my $self = shift;

    my $user = $self->merchant_id();
    my $pass = $self->merchant_secret();

    # Replace user and password with the test merchant settings if test mode implied
    if ( $self->test_transaction() ) {
        warn 'Paytrail in test_transaction mode.' if ( $self->debug() );
        $user = $self->test_merchant_id();
        $pass = $self->test_merchant_secret();
    }
    else {
        warn 'Paytrail in production mode.' if ( $self->debug() );
    }

    my $json_content = JSON::XS::encode_json( $self->content() );

    if ( $self->debug() ) {
        warn 'Paytrail submitting JSON content ' . $json_content;
        warn 'Paytrail using user ' . $user;

        # $Net::SSLeay::trace = 3;
    }

    my ( $page, $server_response, %headers ) = post_https(
        $self->server(),
        $self->port(),
        $self->path(),
        make_headers(
            'Authorization'              => 'Basic ' . MIME::Base64::encode( "$user:$pass", '' ),
            'X-Verkkomaksut-Api-Version' => $self->api_version(),
        ),
        $json_content,
        'application/json',
    );

    # call server_response() with a copy of the entire unprocessed
    # response, to be stored in case the user needs it in the future.
    $self->server_response_json($page);

    warn 'Paytrail server response ' . Dumper($server_response)    if ( $self->debug() );
    warn 'Paytrail server response headers ' . Dumper( \%headers ) if ( $self->debug() );
    warn 'Paytrail server response content ' . Dumper($page)       if ( $self->debug() );

    # * call is_success() with either a true or false value, indicating
    #   if the transaction was successful or not.
    $server_response =~ m/.*? (\d+) .*/;
    my $server_response_status_code = $1;
    if ( $server_response_status_code eq '200' or $server_response_status_code eq '201' ) {
        $self->is_success(1);
    }
    else {
        $self->is_success(0);

        # * If the transaction was not successful, call error_message()
        #   with either the processor provided error message, or some
        #   error message to indicate why it failed.
        $self->error_message( $server_response . ' ' . $page );
    }

    # * call result_code() with the servers result code (this is
    #   generally one field from the response indicating that it was
    #   successful or a failure, most processors provide many possible
    #   result codes to differentiate different types of success and
    #   failure).
    $self->result_code($server_response_status_code);

    if ( $self->is_success() ) {
        my $json_content = JSON::XS::decode_json( $self->server_response_json() );
        # TODO: What if json is invalid
        $self->server_response( JSON::XS::decode_json($page) );
        $self->url( $json_content->{url} );
        $self->token( $json_content->{token} );
        $self->order_number( $json_content->{orderNumber} );
    }
    return 1;
}

=head2 is_success

Populated when you call submit. Status of the submission.

=cut

has 'is_success' => ( is => 'rw' );

=head2 url

Populated when you call submit. This is the URL the user should go to to make the payment.

=cut

has 'url'          => ( is => 'rw' );

=head2 token

(Nice-to-have) Populated when you call submit and the submission is succesful.

=cut

has 'token'        => ( is => 'rw' );

=head2 order_number

(Nice-to-have) Populated when you call submit and the submission is succesful.

=cut

has 'order_number' => ( is => 'rw' );    # the reply order number

=head2 server_response_json

(Nice-to-have) Populated when you call submit and the submission is succesful.

=cut

has 'server_response_json' => ( is => 'rw' );    # the json string as it came from the server, unprocessed

=head2 server_response

(Nice-to-have) Populated when you call submit. The entire unprocessed response content.

=cut

has 'server_response'      => ( is => 'rw' );    # the response as a perl data structure, decoded from json

=head2 result_code

(Nice-to-have) Populated when you call submit. The HTTP status code of the reply.

=cut
has 'result_code' => ( is => 'rw' );

=head2 error_message

Populated when you call submit and the submission is not succesful. Contains the error message from Paytrail.

=cut

has 'error_message' => ( is => 'rw' );

=head2 verify_return

When the end-user has completed the payment he will return to your specified RETURN_ADDRESS,
CANCEL_ADDRESS or PENDING_ADDRESS. Before you process the returning any further you must
check that the parameters given to this address have the correct checksum.

This method verifies the checksum and returns true or false stating if the checksum matched or did not.

After you know that the checksum matched you can mark the payment as paid (if returned to RETURN_ADDRESS),
as pending (if returned to PENDING_ADDRESS) or canceled (if returned to CANCEL_ADDRESS).

Also your NOTIFY_ADDRESS should call verify_return first to verify the checksum and only if the verification
is passed proceed with the information received.

=cut

sub verify_return {
    my $self                  = shift;
    my $args                  = shift;
    my $type                  = $args->{type} || 'success';
    my $order_number          = $args->{ORDER_NUMBER};
    my $timestamp             = $args->{TIMESTAMP};
    my $paid                  = $args->{PAID};
    my $method                = $args->{METHOD};
    my $their_return_authcode = $args->{RETURN_AUTHCODE};

    # use test_merchant_secret if in test mode, otherwise use the real merchant_secret.
    my $secret = $self->test_transaction() ? $self->test_merchant_secret() : $self->merchant_secret();

    warn 'Paytrail verify_return got ' . Dumper($args) if ( $self->debug() );

    my $our_return_authcode;
    if ( $type eq 'failure' ) {
        warn 'Paytrail: type eq failure.' if ( $self->debug() );
        $our_return_authcode = uc( md5_hex( join( '|', $order_number, $timestamp, $secret ) ) );
    }
    else {
        warn 'Paytrail: type defaulting to success.' if ( $self->debug() );

        # default: type eq 'success'
        $our_return_authcode = uc( md5_hex( join( '|', $order_number, $timestamp, $paid, $method, $secret ) ) );
    }
    warn 'Paytrail: our return authcode: ' . $our_return_authcode     if ( $self->debug() );
    warn 'Paytrail: their return authcode: ' . $their_return_authcode if ( $self->debug() );

    my $result = ( $our_return_authcode eq $their_return_authcode ) ? 1 : 0;
    warn 'Paytrail: verify_return result ' . $result if ( $self->debug() );
    return $result;
}


=head2 return_authcode
    Gives the authcode for payment return. You can use this to link directly to the
    "success" or "failure" return pages without ever going to the bank, or to give a link
    in for example e-mail confirmations.
=cut

sub return_authcode {
    my $self                  = shift;
    my $args                  = shift;
    my $type                  = $args->{type} || 'success';
    my $order_number          = $args->{ORDER_NUMBER};
    my $timestamp             = $args->{TIMESTAMP};
    my $paid                  = $args->{PAID};
    my $method                = $args->{METHOD};
    my $their_return_authcode = $args->{RETURN_AUTHCODE};

    # use test_merchant_secret if in test mode, otherwise use the real merchant_secret.
    my $secret = $self->test_transaction() ? $self->test_merchant_secret() : $self->merchant_secret();

    my $our_return_authcode;
    if ( $type eq 'failure' ) {
        $our_return_authcode = uc( md5_hex( join( '|', $order_number, $timestamp, $secret ) ) );
    }
    else {
        # default: type eq 'success'
        $our_return_authcode = uc( md5_hex( join( '|', $order_number, $timestamp, $paid, $method, $secret ) ) );
    }
    return $our_return_authcode;
}


=head2 port

The port where the submission is sent to. Defaults to 443.

=cut

has port   => ( is => 'rw', default => '443' );

=head2 server

The server host name where the submission is sent to. Defaults to payment.paytrail.com.

=cut

has server => ( is => 'rw', default => 'payment.paytrail.com' );

=head2 path

The URL path where the submission is sent to. Defaults to /api-payment/create.

=cut

has path   => ( is => 'rw', default => '/api-payment/create' );

=head2 api_version

The REST API version of Paytrail. Defaults to 1.

=cut

has 'api_version' => ( is => 'rw', default => '1' );

=head1 SECURITY

Don't allow user to set the test_transaction to true! If the user can set it to true when returning he
will get his payment registered as processed.

Don't allow user to set the 'type' parameter of verify_return.

=head1 SEE ALSO

http://www.paytrail.com/
http://docs.paytrail.com/
http://www.frantic.com/

=head1 AUTHOR

Oskari Okko Ojala E<lt>okko@cpan.orgE<gt>, Frantic Oy http://www.frantic.com/

=head1 COPYRIGHT AND LICENSE

Copyright (C) Oskari Ojala 2011-2014.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl you may have available.

=cut

__PACKAGE__->meta->make_immutable;

1;
