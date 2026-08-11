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
use Capture::Tiny qw(capture);

# 1. Load Log::Any::Test FIRST
use Log::Any::Test;

# 2. Load Log::Any
use Log::Any qw($log);

# 3. Load the Adapter
use Log::Any::Adapter;

# 4. Set the Test adapter before running script
Log::Any::Adapter->set('Test', min_level => 'trace');

# 5. Load modules under test
use Google::Auth;
use File::Temp qw(tempfile);

# Require the script but don't run it immediately
use File::Spec;
use File::Basename;
use Cwd 'abs_path';
my $script_path = abs_path(
  File::Spec->catfile(dirname(__FILE__), '..', 'bin', 'gcloud-auth.pl'));
require $script_path;

# Create dummy client id file
my ($fh, $client_id_file) = tempfile();
print $fh '{"installed":{"client_id":"mock_id","client_secret":"mock_secret"}}';
close $fh;

subtest 'gcloud-auth login script execution (Timeout)' => sub {
  $log->clear();

  my ($stdout, $stderr, @result) = capture {
    local $ENV{DISPLAY} = 'mock_display';
    eval { run('login', '--client-id-file', $client_id_file, '--timeout', 1); };
  };

  # Verify logs captured by Log::Any::Test
  $log->contains_ok(qr/Command: login initiated/, 'Logged login init');
  $log->contains_ok(qr/Entering do_login/,        'Logged entering login');
  $log->contains_ok(qr/Timeout waiting for authorization code/,
    'Logged timeout');

  # Verify it died as expected
  ok($@, 'Script threw exception on timeout');
  like(
    $@,
    qr/Timeout waiting for authorization code/,
    'Die message matches timeout'
  );
};

subtest 'gcloud-auth login script execution (Success)' => sub {
  $log->clear();

  # We need to mock the UserAuthorizer or at least the token exchange
  # But let's see if we can just test the listener part first.
  # To test full success, we need to mock UserRefreshCredentials->get_token()
  # because that makes a real HTTP request to Google.

  # Let's try to use a specific port
  my $port = 19999;    # TODO: pick random unused port if possible

  # Fork a child to simulate the browser redirect
  my $pid = fork();
  die "Cannot fork: $!" unless defined $pid;

  if ($pid == 0) {

    # Child process: wait for listener to start
    sleep 1;

    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
      PeerAddr => '127.0.0.1',
      PeerPort => $port,
      Proto    => 'tcp',
    );

    if ($sock) {
      print $sock
"GET /?code=mock_code_123 HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n";
      close $sock;
    } else {
      warn "Child failed to connect to listener: $!";
    }
    exit 0;
  }

  # Parent process: run the login command
  # We need to mock the credential exchange part of UserAuthorizer/UserRefreshCredentials
  # because it will try to hit Google's token endpoint.

  require Test::MockModule;
  my $mock_auth = Test::MockModule->new('Google::Auth::UserAuthorizer');

  # Mock get_and_store_credentials_from_code to avoid real HTTP call
  $mock_auth->mock(
    'get_and_store_credentials_from_code',
    sub {
      my ($self, %options) = @_;
      is($options{code}, 'mock_code_123', 'Received expected code in mock');
      return 1;    # Success
    });

  my ($stdout, $stderr, @result);
  eval {
    ($stdout, $stderr, @result) = capture {
      run('login', '--client-id-file', $client_id_file, '--port', $port);
    };
  };
  my $err = $@;

  waitpid($pid, 0);

  ok(!$err, 'Login completed without error') or diag($err);

  $log->contains_ok(qr/Authorization code received successfully/,
    'Logged success code receipt');
  $log->contains_ok(qr/Login successful/, 'Logged login success');

  like($stdout, qr/Login successful/, 'Stdout contains success message');
};

subtest 'gcloud-auth adc login script execution (Timeout)' => sub {
  $log->clear();

  my ($stdout, $stderr, @result) = capture {
    local $ENV{DISPLAY} = 'mock_display';
    eval {
      run('application-default', 'login', '--client-id-file',
        $client_id_file, '--timeout', 1);
    };
  };

  $log->contains_ok(qr/Command: application-default login initiated/,
    'Logged adc login init');
  $log->contains_ok(qr/Entering do_adc_login/, 'Logged entering adc login');
  $log->contains_ok(qr/Timeout waiting for authorization code/,
    'Logged timeout');

  ok($@, 'Script threw exception on timeout');
  like(
    $@,
    qr/Timeout waiting for authorization code/,
    'Die message matches timeout'
  );
};

subtest 'gcloud-auth adc login script execution (Success)' => sub {
  $log->clear();

  my $port = 20000;    # TODO: pick random unused port if possible

  # Isolate ADC path
  use File::Temp qw(tempdir);
  local $ENV{CLOUDSDK_CONFIG} = tempdir(CLEANUP => 1);

  my $pid = fork();
  die "Cannot fork: $!" unless defined $pid;

  if ($pid == 0) {
    sleep 1;
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
      PeerAddr => '127.0.0.1',
      PeerPort => $port,
      Proto    => 'tcp',
    );
    if ($sock) {
      print $sock
"GET /?code=mock_adc_code_456 HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n";
      close $sock;
    } else {
      warn "Child failed to connect to listener: $!";
    }
    exit 0;
  }

  require Test::MockModule;

  # We might have already required it in previous test, but good to be explicit
  my $mock_auth = Test::MockModule->new('Google::Auth::UserAuthorizer');

  # Mock get_credentials_from_code to return a mock creds object
  $mock_auth->mock(
    'get_credentials_from_code',
    sub {
      my ($self, %options) = @_;
      is($options{code}, 'mock_adc_code_456',
        'Received expected code in ADC mock');

      # Return something that looks like credentials
      require Google::Auth::UserRefreshCredentials;
      return Google::Auth::UserRefreshCredentials->new(
        client_id     => 'mock_client_id',
        client_secret => 'mock_client_secret',
        refresh_token => 'mock_refresh_token',
      );
    });

  my ($stdout, $stderr, @result);
  eval {
    ($stdout, $stderr, @result) = capture {
      run('application-default', 'login', '--client-id-file',
        $client_id_file, '--port', $port);
    };
  };
  my $err = $@;

  waitpid($pid, 0);

  ok(!$err, 'ADC Login completed without error') or diag($err);

  $log->contains_ok(qr/Authorization code received successfully/,
    'Logged success code receipt');
  $log->contains_ok(qr/ADC Login successful/, 'Logged ADC login success');

  like(
    $stdout,
    qr/Application Default Credentials saved to/,
    'Stdout contains success message'
  );

  # Verify file was written
  my $expected_path = File::Spec->catfile($ENV{CLOUDSDK_CONFIG}, 'gcloud',
    'application_default_credentials.json');
  ok(-f $expected_path, 'ADC file was created');

  if (-f $expected_path) {
    open my $fh, '<', $expected_path;
    local $/;
    my $content = <$fh>;
    close $fh;

    my $data = decode_json($content);
    is($data->{type},      'authorized_user', 'ADC type is correct');
    is($data->{client_id}, 'mock_client_id',  'ADC client_id is correct');
  }
};

subtest 'gcloud-auth print-access-token' => sub {
  $log->clear();

  use File::Temp qw(tempdir);
  my $store_dir = tempdir(CLEANUP => 1);

  # Pre-create a token file
  require Google::Auth::Stores::FileTokenStore;
  my $token_store =
    Google::Auth::Stores::FileTokenStore->new(store_dir => $store_dir);

  my $creds_data = {
    client_id     => 'mock_client_id',
    client_secret => 'mock_client_secret',
    refresh_token => 'mock_refresh_token',
  };

  $token_store->store('default', encode_json($creds_data));

  # Mock UserRefreshCredentials to return token without HTTP call
  require Test::MockModule;
  my $mock_creds =
    Test::MockModule->new('Google::Auth::UserRefreshCredentials');
  $mock_creds->mock('get_token', sub { return 'mock_access_token_XYZ'; });

  my ($stdout, $stderr, @result);
  eval {
    ($stdout, $stderr, @result) = capture {
      run('print-access-token', '--store-dir', $store_dir);
    };
  };
  my $err = $@;

  ok(!$err, 'print-access-token completed without error') or diag($err);
  like($stdout, qr/mock_access_token_XYZ/, 'Stdout contains access token');

  $log->contains_ok(qr/Access token printed successfully/, 'Logged success');
};

subtest 'gcloud-auth revoke' => sub {
  $log->clear();

  use File::Temp qw(tempdir);
  my $store_dir = tempdir(CLEANUP => 1);

  require Google::Auth::Stores::FileTokenStore;
  my $token_store =
    Google::Auth::Stores::FileTokenStore->new(store_dir => $store_dir);

  my $creds_data = {
    client_id     => 'mock_client_id',
    client_secret => 'mock_client_secret',
    refresh_token => 'mock_refresh_token',
  };

  $token_store->store('default', encode_json($creds_data));
  ok(-f File::Spec->catfile($store_dir, 'default.json'),
    'Token file exists before revoke');

  # Mock LWP::UserAgent to avoid real HTTP revoke call
  require Test::MockModule;
  my $mock_ua = Test::MockModule->new('LWP::UserAgent');

  # Mock post to return success
  $mock_ua->mock(
    'post',
    sub {
      my ($self, $uri, $params) = @_;
      is(
        $uri,
        'https://oauth2.googleapis.com/revoke',
        'Revocation URI is correct'
      );
      is($params->{token}, 'mock_refresh_token',
        'Correct token sent for revocation');

      require HTTP::Response;
      return HTTP::Response->new(200, 'OK');
    });

  my ($stdout, $stderr, @result);
  eval {
    ($stdout, $stderr, @result) = capture {
      run('revoke', '--store-dir', $store_dir);
    };
  };
  my $err = $@;

  ok(!$err, 'Revoke completed without error') or diag($err);
  like($stdout, qr/Credentials revoked/, 'Stdout contains revocation message');

  $log->contains_ok(qr/Token revocation request successful/, 'Logged success');

  ok(!-f File::Spec->catfile($store_dir, 'default.json'),
    'Token file was deleted');
};

done_testing();
