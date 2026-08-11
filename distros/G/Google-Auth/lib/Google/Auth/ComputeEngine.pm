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

  my $ua   = $self->ua;
  my $host = $ENV{GCE_METADATA_HOST} // 'metadata.google.internal';

  $ua->no_proxy($host, '169.254.169.254');

  my $url = "http://$host/computeMetadata/v1/project/project-id";

  $log->infof('Fetching project ID from GCE metadata server at %s', $url);

  my $response = $ua->get($url, 'Metadata-Flavor' => 'Google');
  if ($response->is_success) {
    return $response->decoded_content;
  } else {
    $log->warnf('Failed to fetch project ID from GCE metadata server: %s',
      $response->status_line);
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

  my $ua = LWP::UserAgent->new(timeout => 1);
  $ua->no_proxy('metadata.google.internal', '169.254.169.254');

  my $host     = 'metadata.google.internal';
  my $response = $ua->get("http://$host/computeMetadata/v1/instance/",
    'Metadata-Flavor' => 'Google');

  if ($response->is_success) {
    $_on_gce = 1;
    return $_on_gce;
  }

  $host     = '169.254.169.254';
  $response = $ua->get("http://$host/computeMetadata/v1/instance/",
    'Metadata-Flavor' => 'Google');

  $_on_gce = $response->is_success ? 1 : 0;
  return $_on_gce;
}

sub fetch_access_token {
  my ($self, %options) = @_;

  my $ua   = $self->ua;
  my $host = $ENV{GCE_METADATA_HOST} // 'metadata.google.internal';

  # Ensure no proxy for metadata server
  $ua->no_proxy($host, '169.254.169.254');

  my $url =
    "http://$host/computeMetadata/v1/instance/service-accounts/default/token";

  $log->infof("Fetching access token from GCE metadata server at $url");

  my $response = Google::Auth::RetryHelper->execute_with_retry(
    sub {
      my $res = $ua->get($url, 'Metadata-Flavor' => 'Google');
      if (!$res->is_success) {
        Google::Auth::Error->throw('HTTP request failed with status ' .
            $res->code . ': ' . $res->decoded_content);
      }
      return $res;
    },
    %options
  );

  my $res_data = decode_json($response->decoded_content);
  my $token    = $res_data->{access_token};
  my $expires  = $res_data->{expires_in} // 3600;

  $self->access_token($token);
  $self->expires_at(time() + $expires);

  return $token;
}

1;

