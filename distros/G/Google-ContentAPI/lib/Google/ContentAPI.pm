##############################################################################
# Google::ContentAPI
#
# Add, modify and delete items from the Google Merchant Center platform via
# the Content API for Shopping.
#
# https://developers.google.com/shopping-content/v2/quickstart
#
# Authentication is done via Service Account credentials. For details see:
# https://developers.google.com/shopping-content/v2/how-tos/service-accounts
#
# AUTHOR
#
# Bill Gerrard <bill@gerrard.org>
#
# VERSION HISTORY
#
# + v1.01       03/27/2018 Added config_json, merchant_id options and switched to Crypt::JWT
# + v1.00       03/23/2018 initial release
#
# COPYRIGHT AND LICENSE
#
# Copyright (C) 2018 Bill Gerrard
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.20.2 or,
# at your option, any later version of Perl 5 you may have available.
#
# Disclaimer of warranty: This program is provided by the copyright holder
# and contributors "As is" and without any express or implied warranties.
# The implied warranties of merchantability, fitness for a particular purpose,
# or non-infringement are disclaimed to the extent permitted by your local
# law. Unless required by law, no copyright holder or contributor will be
# liable for any direct, indirect, incidental, or consequential damages
# arising in any way out of the use of the package, even if advised of the
# possibility of such damage.
#
################################################################################

package Google::ContentAPI;

use strict;
use warnings;
use Carp;

use JSON;
use Crypt::JWT qw(encode_jwt);
use REST::Client;
use HTML::Entities;

our $VERSION = '1.02';

sub new {
    my ($class, $params) = @_;
    my $self = {};

    if ($params->{config_file}) {
        $self->{config} = load_google_config($params->{config_file});
    } elsif ($params->{config_json}) {
         $self->{config} = decode_json $params->{config_json};
    } else {
      croak "config_file or config_json not provided in new()";
    }
    $self->{merchant_id} = $self->{config}->{merchant_id}
        || $params->{merchant_id}
        || croak "'merchant_id' not provided in json config in new()";

    $self->{debug} = 1 if $params->{debug};
    $self->{google_auth_token} = get_google_auth_token($self);
    $self->{rest} = init_rest_client($self);

    return bless $self, $class;
}

sub get {
    my $self = shift;
    croak "Odd number of arguments for get()" if scalar(@_) % 2;
    my $opt = {@_};
    my $method = $self->prepare_method($opt);
    return $self->request('GET', $method);
}

sub post {
    my $self = shift;
    croak "Odd number of arguments for post()" if scalar(@_) % 2;
    my $opt = {@_};
    my $method = $self->prepare_method($opt);
    $opt->{body} = encode_json $opt->{body} if $opt->{body};
    return $self->request('POST', $method, $opt->{body});
}

sub delete {
    my $self = shift;
    croak "Odd number of arguments for delete()" if scalar(@_) % 2;
    my $opt = {@_};
    my $method = $self->prepare_method($opt);
    return $self->request('DELETE', $method);
}

sub prepare_method {
  my $self = shift;
  my $opt = shift;

  $opt->{resource} = '' if $opt->{resource} eq 'custom';

  if ($opt->{resource} eq 'products'
        || $opt->{resource} eq 'productstatuses'
        || $opt->{resource} eq 'accountstatuses'
    ) {
    # add merchant ID to request URL for non-batch requests
    $opt->{resource} = $self->{merchant_id} .'/'. $opt->{resource} if $opt->{method} ne 'batch';
    # drop list/insert methods; these are for coding convenience only
    $opt->{method} = '' if $opt->{method} eq 'list';
    $opt->{method} = '' if $opt->{method} eq 'insert';
    # append product ID to end of request URL for get and delete
    $opt->{method} = $opt->{id} if $opt->{method} =~ /get|delete/;
  }

  my $encoded_params = $self->{rest}->buildQuery($opt->{params}) if $opt->{params};

  my $method;
  $method .= '/'. $opt->{resource} if $opt->{resource} ne '';
  $method .= '/'. $opt->{method} if $opt->{method} ne '';
  $method .= $encoded_params if $encoded_params;

  return $method;
}

sub init_rest_client {
    my $self = shift;
    my $r = REST::Client->new();
    $r->setHost('https://www.googleapis.com/content/v2');
    $r->addHeader('Authorization', $self->{google_auth_token});
    $r->addHeader('Content-type', 'application/json');
    $r->addHeader('charset', 'UTF-8');
    return $r;
}

sub request {
    my $self = shift;
    my @command = @_;

    print join (' ', @command) . "\n" if $self->{debug};
    my $rest = $self->{rest}->request(@command);

    unless ($rest->responseCode eq '200') {
        if ($rest->responseCode eq '204' && $command[0] eq 'DELETE') {
          # no-op: delete was successful
        } elsif ($rest->responseCode eq '401') {
            # access token expired, request new token and retry request
            $self->{google_auth_token} = $self->get_google_auth_token();
            $self->{rest} = $self->init_rest_client();
            $rest = $self->{rest}->request(@command);
        } else {
            die("Error processing REST request:\n",
                "Request: ", $rest->getHost , $command[1], "\n",
                "Response Code: ", $rest->responseCode, "\n", $rest->responseContent, "\n");
        }
    }
    print "Request Response: \n". $rest->responseContent if $self->{debug};

    my $response = $rest->responseContent ? decode_json $rest->responseContent : {};
    return { code => $rest->responseCode, response => $response };
}

sub get_google_auth_token {
    my $self = shift;

    my $gapiTokenURI     = 'https://www.googleapis.com/oauth2/v4/token';
    my $gapiContentScope = 'https://www.googleapis.com/auth/content';
    my $time = time();

    # 1) Create JSON Web Token
    # https://developers.google.com/accounts/docs/OAuth2ServiceAccount
    #
    my $jwt = encode_jwt(
        payload => {
            iss => $self->{config}->{client_email},
            scope => $gapiContentScope,
            aud => $gapiTokenURI,
            exp => $time + 3660, # max 60 minutes
            iat => $time
        },
        key => \$self->{config}->{private_key},
        alg => 'RS256'
    );

    # 2) Request an access token
    #
    my $ua = LWP::UserAgent->new();
    my $response = $ua->post($gapiTokenURI, {
        grant_type => encode_entities('urn:ietf:params:oauth:grant-type:jwt-bearer'),
        assertion => $jwt
    });

    print "Request Access Token response:\n". $response->content if $self->{debug};

    unless($response->is_success()) {
        die("Error receiving access token:\n", $response->code, "\n", $response->content, "\n");
    }

    my $data = decode_json $response->content;
    return 'Bearer '. $data->{access_token};
}

sub load_google_config {
  my $json_file = shift;
  open my $fh, '<', $json_file or croak "Error reading config_file '$json_file': $!";
  my $json_text;
  { local $/; $json_text = <$fh>; }
  close $fh;
  return decode_json $json_text;
}

1;

__END__
=head1 NAME

  Google::ContentAPI - Interact with Google's Content API for Shopping

=head1 DESCRIPTION

  Add, modify and delete items from the Google Merchant Center platform via
  the Content API for Shopping.

  Authentication is done via Service Account credentials. See the following for details:
  https://developers.google.com/shopping-content/v2/how-tos/service-accounts

  You will also need to create a Merchant Center Account:
  https://developers.google.com/shopping-content/v2/quickstart

  For convenince, add your Merchant account ID to the *.json file provided by Google.
  Your complete *.json file, after adding your merchant ID, will look something like this:

  {
    "merchant_id": "123456789",
    "type": "service_account",
    "project_id": "content-api-194321",
    "private_key_id": "11b8e20c2540c788e98b49e623ae8167dc3e4a6f",
    "private_key": "-----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----\n",
    "client_email": "google@content-api.iam.gserviceaccount.com",
    "client_id": "999999999",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/google%40content-api.iam.gserviceaccount.com"
  }

=head1 SYNOPSIS

  use Google::ContentAPI;
  use Data::Dumper;

  my $google = Google::ContentAPI->new({
      debug => 0,
      config_file => 'content-api-key.json',
      config_json => $json_text,
      merchant_id => '123456789',
  });

  my ($result, $products, $batch_id, $product_id);

  # get account auth info (merchantId)
  $result = $google->get(
    resource => 'accounts',
    method   => 'authinfo'
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "authinfo: \n". Dumper $result;

  # get status of your merchant center account
  $result = $google->get(
      resource => 'accountstatuses',
      method   => 'get',
      id => $google->{merchant_id} # your merchant ID unless working with multi-client account
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "Account status: \n". Dumper $result;

  # list status of multi-client accounts (MCA)
  # This will fail with response code 403 if the account is not a multi-client account.
  $result = $google->get(
      resource => 'accountstatuses',
      method   => 'list',
      params   => ['maxResults' => 10]
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "Account status: \n". Dumper $result;

  # list products

  $result = $google->get(
      resource => 'products',
      method   => 'list',
      params   => ['includeInvalidInsertedItems' => 'true']
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "Products list: \n". Dumper $result;

  # insert a product

  $result = $google->post(
      resource => 'products',
      method   => 'insert',
      params   => ['dryRun' => 'true'],
      body => {
        contentLanguage => 'en',
        targetCountry => 'US',
        channel => 'online',
        offerId => '333333',
        title => 'Item title',
        description => 'The item description',
        link => 'http://www.google.com',
        imageLink => 'https://www.google.com/images/logo.png',
        availability => 'in stock',
        condition => 'new',
        price => {
            value => '99.95',
            currency => 'USD',
        },
        shipping => [
          {
            country => 'US',
            service => 'Standard Shipping',
            price => {
                value => '7.95',
                currency => 'USD',
            },
          },
        ],
        brand => 'Apple',
        gtin => '333333-67890',
        mpn => '333333',
        googleProductCategory => 'Home & Garden > Household Supplies > Apples',
        productType => 'Home & Garden > Household Supplies > Apples',
        customLabel1 => 'apples'
      }
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";

  # get single product info

  $product_id = '333333';
  $result = $google->get(
      resource => 'products',
      method   => 'get',
      id => 'online:en:US:'. $product_id
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "Products info: \n". Dumper $result;

  # delete a product

  my $del_product_id = '333333';
  $result = $google->delete(
      resource => 'products',
      method   => 'delete',
      id => 'online:en:US:'. $del_product_id,
      #params   => ['dryRun' => 'true']
  );
  print "$result->{code} ". ($result->{code} eq '204' ? 'success' : 'failure') ."\n"; # 204 = delete success

  # batch insert

  $products = [];
  $batch_id = 0;

  foreach my $i ('211203'..'211205') {
      push @$products, {
          batchId => ++$batch_id,
          merchantId => $google->{merchant_id},
          method => 'insert', # insert / get / delete
          #productId => '', # for get / delete
          product => { # for insert
              contentLanguage => 'en',
              targetCountry => 'US',
              channel => 'online',
              offerId => "$i",
              title => "item title $i",
              description => "The item description for $i",
              link => 'http://www.google.com',
              imageLink => 'https://www.google.com/images/logo.png',
              availability => 'in stock',
              condition => 'new',
              price => {
                  value => '10.95',
                  currency => 'USD',
              },
              shipping => [
                {
                  country => 'US',
                  service => 'Standard Shipping',
                  price => {
                      value => '7.95',
                      currency => 'USD',
                  },
                },
              ],
              brand => 'Apple',
              gtin => "${i}-67890",
              mpn => "$i",
              googleProductCategory => 'Home & Garden > Household Supplies > Apples',
              productType => 'Home & Garden > Household Supplies > Apples',
              customLabel1 => 'apples'
          }
      };
  }

  $result = $google->post(
      resource => 'products',
      method   => 'batch',
      #params   => ['dryRun' => 'true'],
      body => { entries => $products }
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";

  # batch get:

  $products = [];
  $batch_id = 0;
  foreach my $product_id ('211203'..'211205') {
      push @$products, {
          batchId => ++$batch_id,
          merchantId => $google->{merchant_id},
          method => 'get', # insert / get / delete
          productId => 'online:en:US:'. $product_id, # for get / delete
      };
  }

  $result = $google->post(
      resource => 'products',
      method   => 'batch',
      #params   => ['dryRun' => 'true'],
      body => { entries => $products }
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print Dumper $result;

  # batch delete:

  $products = [];
  $batch_id = 0;
  foreach my $product_id ('211203'..'211205') {
      push @$products, {
          batchId => ++$batch_id,
          merchantId => $google->{merchant_id},
          method => 'delete', # insert / get / delete
          productId => 'online:en:US:'. $product_id, # for get / delete
      };
  }

  $result = $google->post(
      resource => 'products',
      method   => 'batch',
      #params   => ['dryRun' => 'true'],
      body => { entries => $products }
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";

  # list status of products

  $result = $google->get(
      resource => 'productstatuses',
      method   => 'list',
      params   => [
          'includeInvalidInsertedItems' => 'true',
          'maxResults' => 10
      ]
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "Product status: \n". Dumper $result;

  # get status of a specific product

  $product_id = '333333';
  $result = $google->get(
      resource => 'productstatuses',
      method   => 'get',
      id => 'online:en:US:'. $product_id
  );
  print "$result->{code} ". ($result->{code} eq '200' ? 'success' : 'failure') ."\n";
  print "Product status: \n". Dumper $result;

=head1 METHODS AND FUNCTIONS

=head2 new()

  Create a new Google::ContentAPI object

=head3 debug

  Displays API debug information

=head3 config_file

  Path and filename of external .json config file.
  Either config_file or config_json must be provided. If both config_file
  and config_json are provided, config_file will be used.

=head3 config_json

  Text containing contents of the json config. Useful if you want to
  store the json config in another resource such as a database.
  Either config_file or config_json must be provided. If both config_file
  and config_json are provided, config_file will be used.

=head3 merchant_id

  optional if merchant_id is specificed in json config

=head2 ACCOUNTS

=head3 authinfo

  Returns information about the authenticated user.

=head2 ACCOUNTSTATUSES

=head3 list

  Lists the the status of accounts in a Multi-Client account.
  This will fail with response code 403 if the account is not a multi-client account.

=head3 get

  Retrieves the status of your Merchant Center account.

=head2 PRODUCTS

=head3 custombatch

  Retrieves, inserts, and deletes multiple products in a single request.

=head3 insert

  Uploads a product to your Merchant Center account. If an item with the
  same channel, contentLanguage, offerId, and targetCountry already exists,
  this method updates that entry.

=head3 list

  Lists the products in your Merchant Center account.

=head3 get

  Retrieves a product from your Merchant Center account.

=head3 delete

  Deletes a product from your Merchant Center account.

=head2 PRODUCTSTATUSES

=head3 list

  Lists the the status and issues of products in your Merchant Center Account.

=head3 get

  Retrieves the status and issues of a specific product.

=head1 UNIMPLEMENTED FEATURES

  Certain API methods are not yet implemented (no current personal business need).

  A "custom" resource is available to perform methods that are not implemented by
  this module.

  # get an order from the merchant account
  $result = $google->get(
    resource => 'custom',
    method   => 'merchantId/orders/orderId'
  );

=head1 PREREQUISITES

  JSON
  Crypt::JWT
  REST::Client
  HTML::Entities

=head1 AUTHOR

  Original Author
  Bill Gerrard <bill@gerrard.org>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2018 Bill Gerrard

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.20.2 or,
  at your option, any later version of Perl 5 you may have available.
  Disclaimer of warranty: This program is provided by the copyright holder
  and contributors "As is" and without any express or implied warranties.
  The implied warranties of merchantability, fitness for a particular purpose,
  or non-infringement are disclaimed to the extent permitted by your local
  law. Unless required by law, no copyright holder or contributor will be
  liable for any direct, indirect, incidental, or consequential damages
  arising in any way out of the use of the package, even if advised of the
  possibility of such damage.

=cut
