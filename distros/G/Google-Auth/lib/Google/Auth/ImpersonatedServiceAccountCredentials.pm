# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Auth::ImpersonatedServiceAccountCredentials;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::Credentials';

use JSON::PP;
use LWP::UserAgent;
use Google::Auth::Exceptions;
use Google::Auth::RetryHelper;
use Log::Any qw($log);

our $VERSION = '0.02';

has base_credentials => (
    is       => 'ro',
    required => 0,
);

has source_credentials => (
    is       => 'ro',
    required => 0,
);

has impersonation_url => (
    is       => 'ro',
    required => 1,
);

has scope => (
    is       => 'ro',
    required => 1,
);

has ua => (
    is      => 'ro',
    default => sub { LWP::UserAgent->new( timeout => 10 ) },
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args = $class->$orig(@args);

    if ( my $json = $args->{json_key} ) {
        $args->{impersonation_url} //= $json->{service_account_impersonation_url};
        $args->{scope}             //= $json->{scopes};
        if ( my $source_creds_info = $json->{source_credentials} ) {
            if ( $source_creds_info->{type} eq 'impersonated_service_account' ) {
                Google::Auth::Error->throw('Source credentials can\'t be of type impersonated_service_account, use delegates to chain impersonation.');
            }
            require Google::Auth::DefaultCredentials;
            $args->{source_credentials} //= Google::Auth::DefaultCredentials->make_creds(
                json_key => $source_creds_info,
            );
        }
    }

    if ( !defined $args->{source_credentials} && !defined $args->{base_credentials} ) {
        Google::Auth::Error->throw('Missing required option: either source_credentials or base_credentials must be provided');
    }

    $args->{source_credentials} //= $args->{base_credentials};

    return $args;
};

sub BUILD {
    my ($self) = @_;

    my $source_creds = $self->source_credentials;
    if ( $source_creds->isa('Google::Auth::ImpersonatedServiceAccountCredentials') ) {
        Google::Auth::Error->throw('Source credentials can\'t be of type impersonated_service_account, use delegates to chain impersonation.');
    }
}

sub fetch_access_token {
    my ( $self, %options ) = @_;

    my $source_creds = $self->source_credentials;
    my $source_token;

    if ( $source_creds->can('get_token') ) {
        $log->tracef('Fetching source credentials token using get_token...');
        $source_token = $source_creds->get_token(%options);
    }
    elsif ( $source_creds->can('access_token') && defined $source_creds->access_token ) {
        $log->tracef('Using cached access_token from source credentials...');
        $source_token = $source_creds->access_token;
    }
    elsif ( $source_creds->can('fetch_access_token') ) {
        $log->tracef('Fetching source credentials token using fetch_access_token...');
        $source_token = $source_creds->fetch_access_token(%options);
    }
    else {
        $log->errorf('Source credentials do not contain a valid token retrieval mechanism');
        Google::Auth::Error->throw('Source credentials do not have a valid access token or fetch_access_token method');
    }

    my $req_body = encode_json({
        scope => ref $self->scope eq 'ARRAY' ? $self->scope : [ $self->scope ]
    });

    my $ua = $self->ua;
    $log->infof('Requesting impersonated access token from %s...', $self->impersonation_url);
    my $response = Google::Auth::RetryHelper->execute_with_retry(sub {
        my $res = $ua->post(
            $self->impersonation_url,
            'Content-Type'  => 'application/json',
            'Authorization' => 'Bearer ' . $source_token,
            'Content'       => $req_body
        );
        if ( !$res->is_success ) {
            $log->warnf('Impersonated token exchange failed: status %s', $res->code);
            Google::Auth::Error->throw('Service account impersonation failed with status ' . $res->code . ': ' . $res->decoded_content);
        }
        return $res;
    }, %options);

    my $res_data = decode_json($response->decoded_content);
    $self->access_token($res_data->{accessToken});
    $self->expires_at($res_data->{expireTime});

    return $res_data->{accessToken};
}

1;
