#!/usr/bin/env perl
# Copyright 2026 Google LLC and contributors
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

use strict;
use warnings;
use Test::More;
use LWP::UserAgent;
use JSON::PP;

unless ($ENV{AUTHOR_TESTING}) {
  plan(skip_all => 'Author tests not required for installation');
}

unless (-t STDIN) {
  plan(skip_all => 'No human detected (Non-interactive environment / No TTY)');
}

# This test requires real credentials to be available.
# It will check GOOGLE_APPLICATION_CREDENTIALS or well-known paths.

use Google::Auth;

my $creds;

eval {
  $creds =
    Google::Auth->default(['https://www.googleapis.com/auth/cloud-platform']);
};

if ($@) {
  plan(skip_all => "Failed to load credentials: $@");
}

unless ($creds) {
  plan(skip_all => "No credentials found in environment or well-known paths.");
}

diag("Loaded credentials type: " . ref($creds));

my $token;
eval { $token = $creds->get_token(); };

if ($@) {
  fail("Failed to fetch access token: $@");
} else {
  ok($token, "Successfully fetched access token");

  # Verify token validity using tokeninfo endpoint
  my $ua = LWP::UserAgent->new();
  my $res =
    $ua->get("https://oauth2.googleapis.com/tokeninfo?access_token=$token");

  if ($res->is_success) {
    pass("Access token is valid (tokeninfo accepted it)");
    my $info = decode_json($res->decoded_content);
    diag("Token scopes: " . $info->{scope});
    diag("Expires in: " . $info->{expires_in});
  } else {
    fail("Access token invalid or tokeninfo failed: " . $res->status_line);
    diag($res->decoded_content);
  }
}

done_testing();
