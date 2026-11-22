# Copyright 2022 Google LLC and contributors
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

package Google::Auth::ComputeEngine;

use strict;
use warnings;

use Moo;

extends 'Google::Auth::Credentials';

use LWP::UserAgent;
use JSON::MaybeXS;
use Google::Auth::Exceptions;
use Google::Auth::RetryHelper;
use Log::Any qw($log);

has ua => (
  is      => 'ro',
  default => sub {
    my $ua = LWP::UserAgent->new(timeout => 2);
    $ua->env_proxy;
    return $ua;
  },
);

has '+project_id' => (
  is      => 'lazy',
  builder => '_build_project_id',
);

has scope => (
  is       => 'ro',
  required => 0,
);

our $_on_gce;

sub _build_project_id {
  my ($self) = @_;

  return $ENV{GOOGLE_CLOUD_PROJECT} if $ENV{GOOGLE_CLOUD_PROJECT};

  my $host = $ENV{GCE_METADATA_HOST} // 'metadata.google.internal';

  $self->ua->no_proxy($host, '169.254.169.254');

  my $url = "http://$host/computeMetadata/v1/project/project-id";

  $log->infof('Fetching project ID from GCE metadata server at %s', $url);

  my $future = $self->transport->request(
    method  => 'GET',
    url     => $url,
    headers => {'Metadata-Flavor' => 'Google'},
  );

  my ($body, $headers);
  my $future_res = eval { ($body, $headers) = $future->get(); 1 };

  if ($future_res) {
    return $body;
  } else {
    my ($err_msg, $cat, $details) = $future->failure;
    $log->warnf('Failed to fetch project ID from GCE metadata server: %s',
      $err_msg);
    return;
  }
}

sub on_gce {
  my ($class, %options) = @_;
  return $_on_gce if defined $_on_gce;

  if ($ENV{GCE_METADATA_HOST}) {
    $_on_gce = 1;
    return $_on_gce;
  }

  my $transport = $options{transport};
  if (!$transport) {
    require Google::Cloud::Transport::Adapter::LWP;
    my $ua = LWP::UserAgent->new(timeout => 1);
    $ua->no_proxy('metadata.google.internal', '169.254.169.254');
    $transport = Google::Cloud::Transport::Adapter::LWP->new(user_agent => $ua);
  }

  my $host   = 'metadata.google.internal';
  my $future = $transport->request(
    method  => 'GET',
    url     => 'http://' . $host . '/computeMetadata/v1/instance/',
    headers => {'Metadata-Flavor' => 'Google'},
  );

  my $future_res = eval { $future->get(); 1 };
  if ($future_res) {
    $_on_gce = 1;
    return $_on_gce;
  }

  $host   = '169.254.169.254';
  $future = $transport->request(
    method  => 'GET',
    url     => 'http://' . $host . '/computeMetadata/v1/instance/',
    headers => {'Metadata-Flavor' => 'Google'},
  );

  $future_res = eval { $future->get(); 1 };
  $_on_gce    = $future_res ? 1 : 0;
  return $_on_gce;
}

sub fetch_access_token {
  my ($self, %options) = @_;

  my $host = $ENV{GCE_METADATA_HOST} // 'metadata.google.internal';

  # Ensure no proxy for metadata server
  $self->ua->no_proxy($host, '169.254.169.254');

  my $url =
    "http://$host/computeMetadata/v1/instance/service-accounts/default/token";

  $log->infof("Fetching access token from GCE metadata server at $url");

  my $response_body = Google::Auth::RetryHelper->execute_with_retry(
    sub {
      my $future = $self->transport->request(
        method  => 'GET',
        url     => $url,
        headers => {'Metadata-Flavor' => 'Google'},
      );

      my ($body, $headers);
      my $future_res = eval { ($body, $headers) = $future->get(); 1 };

      if (!$future_res) {
        my ($err_msg, $cat, $details) = $future->failure;
        my $code       = 0;
        my $error_body = '';
        if (ref($details) eq 'HASH') {
          $code       = $details->{code} // 0;
          $error_body = $details->{body} // '';
        } elsif (eval { $details->can('code') }) {
          $code       = $details->code // 0;
          $error_body = $details->decoded_content // $details->content // '';
        }
        Google::Auth::Error->throw(
          'HTTP request failed with status ' . $code . ': ' . $error_body);
      }
      return $body;
    },
    %options
  );

  my $res_data = decode_json($response_body);
  my $token    = $res_data->{access_token};
  my $expires  = $res_data->{expires_in} // 3600;

  $self->access_token($token);
  $self->expires_at(time() + $expires);

  return $token;
}

1;

