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

package Google::Auth::ExternalAccountCredentials::Aws;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::ExternalAccountCredentials';

use Digest::SHA qw(hmac_sha256 hmac_sha256_hex sha256_hex);
use Time::Piece;
use JSON::PP;
use MIME::Base64 qw(encode_base64);
use Google::Auth::Exceptions;
use Log::Any qw($log);

our $VERSION = '0.02';

sub retrieve_subject_token {
    my ($self) = @_;

    my $access_key    = $ENV{AWS_ACCESS_KEY_ID};
    my $secret_key    = $ENV{AWS_SECRET_ACCESS_KEY};
    my $session_token = $ENV{AWS_SESSION_TOKEN};

    if ( !defined $access_key || !defined $secret_key ) {
        $log->errorf('Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY in environment');
        Google::Auth::Error->throw('Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY in environment');
    }

    $log->tracef('Generating AWS Signature V4 request using access key: %s', $access_key);

    my $region = $ENV{AWS_DEFAULT_REGION} // 'us-east-1';
    my $host   = 'sts.amazonaws.com';
    my $method = 'POST';
    my $uri    = '/';
    my $query  = 'Action=GetCallerIdentity&Version=2011-06-15';

    my $t         = gmtime();
    my $amz_date  = $t->strftime('%Y%m%dT%H%M%SZ');
    my $datestamp = $t->strftime('%Y%m%d');

    my %headers = (
        'host'       => $host,
        'x-amz-date' => $amz_date,
    );
    $headers{'x-amz-security-token'} = $session_token if defined $session_token;

    my @sorted_header_names = sort keys %headers;
    my $canonical_headers   = join('', map { $_ . ':' . $headers{$_} . "\n" } @sorted_header_names);
    my $signed_headers      = join(';', @sorted_header_names);

    my $payload_hash = sha256_hex('');

    my $canonical_request = join("\n",
        $method,
        $uri,
        $query,
        $canonical_headers,
        $signed_headers,
        $payload_hash
    );

    my $algorithm        = 'AWS4-HMAC-SHA256';
    my $credential_scope = join('/', $datestamp, $region, 'sts', 'aws4_request');
    my $string_to_sign   = join("\n",
        $algorithm,
        $amz_date,
        $credential_scope,
        sha256_hex($canonical_request)
    );

    my $k_date    = hmac_sha256($datestamp, 'AWS4' . $secret_key);
    my $k_region  = hmac_sha256($region, $k_date);
    my $k_service = hmac_sha256('sts', $k_region);
    my $k_signing = hmac_sha256('aws4_request', $k_service);

    my $signature = hmac_sha256_hex($string_to_sign, $k_signing);

    my $auth_header = "$algorithm Credential=$access_key/$credential_scope, SignedHeaders=$signed_headers, Signature=$signature";
    $headers{Authorization} = $auth_header;

    my @header_array;
    foreach my $k ( sort keys %headers ) {
        push @header_array, { key => $k, value => $headers{$k} };
    }

    my $request_obj = {
        url     => "https://$host/?$query",
        headers => \@header_array,
        method  => $method,
    };

    my $subject_token = encode_base64(encode_json($request_obj), '');
    $subject_token =~ s/\s+//g;
    return $subject_token;
}

1;
