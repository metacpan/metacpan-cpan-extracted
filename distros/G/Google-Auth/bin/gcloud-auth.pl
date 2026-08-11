#!/usr/bin/perl
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
use Getopt::Long;
use Pod::Usage;
use File::Spec;
use JSON::MaybeXS qw(encode_json decode_json);
use Log::Any      qw($log);
use IO::Socket::INET;
use IO::Select;
use URI;

use Google::Auth;
use Google::Auth::ClientId;
use Google::Auth::UserAuthorizer;
use Google::Auth::Stores::FileTokenStore;
use Google::Auth::Exceptions;

my $VERSION = '0.01';

# Default Scopes for GCP
my @DEFAULT_SCOPES = (
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/cloud-platform',
  'https://www.googleapis.com/auth/appengine.admin',
  'https://www.googleapis.com/auth/sqlservice.login',
  'https://www.googleapis.com/auth/compute',
  'https://www.googleapis.com/auth/accounts.reauth'
);

unless (caller) {
  run(@ARGV);
}

sub run {
  my @args = @_;

  my $help    = 0;
  my $man     = 0;
  my $verbose = 0;
  my $client_id_file;
  my $store_dir =
    File::Spec->catdir($ENV{HOME} // '.', '.google-auth-perl', 'tokens');
  my $port       = 0;      # Default auto-assign
  my $timeout    = 300;    # Default 5 minutes for human interaction
  my $no_browser = 0;

  local @ARGV = @args;

  GetOptions(
    'help|?'           => \$help,
    'man'              => \$man,
    'verbose|v'        => \$verbose,
    'client-id-file=s' => \$client_id_file,
    'store-dir=s'      => \$store_dir,
    'port=i'           => \$port,
    'timeout=i'        => \$timeout,
    'no-browser'       => \$no_browser,
  ) or pod2usage(2);

  if ($verbose) {
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr', min_level => 'trace');
  }

  pod2usage(1)             if $help;
  pod2usage(-verbose => 2) if $man;

  my $command = shift @ARGV;

  unless ($command) {
    pod2usage(1);
  }

  if ($command eq 'login') {
    do_login(
      client_id_file => $client_id_file,
      store_dir      => $store_dir,
      port           => $port,
      timeout        => $timeout,
      no_browser     => $no_browser,
    );
  } elsif ($command eq 'application-default') {
    my $subcommand = shift @ARGV;
    unless ($subcommand) {
      die "Error: application-default requires a subcommand (e.g., login)\n";
    }
    if ($subcommand eq 'login') {
      do_adc_login(
        client_id_file => $client_id_file,
        store_dir      => $store_dir,
        port           => $port,
        timeout        => $timeout,
        no_browser     => $no_browser,
      );
    } else {
      die "Unsupported application-default subcommand: $subcommand\n";
    }
  } elsif ($command eq 'print-access-token') {
    do_print_access_token(store_dir => $store_dir,);
  } elsif ($command eq 'revoke') {
    do_revoke(store_dir => $store_dir,);
  } else {
    die "Unsupported command: $command\n";
  }
}

sub _start_listener {
  my ($port) = @_;
  my $listener = IO::Socket::INET->new(
    LocalHost => '127.0.0.1',
    LocalPort => $port || 0,    # Auto-assign if 0
    Proto     => 'tcp',
    Listen    => 1,
    ReuseAddr => 1,
  );
  unless ($listener) {
    $log->errorf('Failed to start loopback listener: %s', $!);
    die "Error: Failed to start loopback listener: $!\n";
  }
  return $listener;
}

sub _wait_for_code {
  my ($listener, $timeout) = @_;
  $timeout //= 5;    # Fallback default

  my $select = IO::Select->new($listener);
  my $client;

  if ($select->can_read($timeout)) {
    $client = $listener->accept();
  } else {
    $log->error('Timeout waiting for authorization code');
    close $listener;
    die "Error: Timeout waiting for authorization code.\n";
  }

  unless ($client) {
    $log->errorf('Failed to accept connection: %s', $!);
    close $listener;
    die "Error: Failed to accept connection: $!\n";
  }

  my $request = '';
  while (<$client>) {
    $request .= $_;
    last if $_ =~ /^\r\n$/;    # End of headers
  }

  $log->tracef('Received request: %s', $request);

  my $code;
  if ($request =~ /^GET\s+([^\s]+)/) {
    my $uri    = URI->new("http://127.0.0.1$1");
    my %params = $uri->query_form;
    $code = $params{code};
  }

  if ($code) {
    $log->info('Authorization code received successfully');
    print $client
"HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\n\r\nSuccess! You can close this window.\r\n";
    close $client;
    close $listener;
    return $code;
  } else {
    $log->error('Failed to get authorization code from callback');
    print $client
"HTTP/1.1 400 Bad Request\r\nConnection: close\r\nContent-Type: text/plain\r\n\r\nError: No code received.\r\n";
    close $client;
    close $listener;
    die "Error: Failed to get authorization code.\n";
  }
}

sub do_login {
  my (%options) = @_;
  $log->info('Command: login initiated');
  $log->trace('Entering do_login');

  my $client_id_file = $options{client_id_file};
  my $store_dir      = $options{store_dir};

  my $client_id;
  if ($client_id_file && -f $client_id_file) {
    $client_id = Google::Auth::ClientId->from_file($client_id_file);
  } else {
    $log->info('Using default Gcloud Client ID');
    $client_id = Google::Auth::ClientId->new(
      id     => '32555940559.apps.googleusercontent.com',
      secret => 'ZmssLNjJy2998hD4CTg2ejr2',
    );
  }
  my $token_store =
    Google::Auth::Stores::FileTokenStore->new(store_dir => $store_dir);

  my $listener;
  my $redirect_uri;

  my $use_oob = $options{no_browser};
  unless ($use_oob || $options{port}) {
    if ($^O eq 'linux' && !$ENV{DISPLAY} && !$ENV{WAYLAND_DISPLAY}) {
      $log->info(
        'No DISPLAY detected on Linux, defaulting to out-of-band flow');
      $use_oob = 1;
    }
  }

  my $code_verifier;
  if ($use_oob) {
    $redirect_uri = 'https://sdk.cloud.google.com/authcode.html';
    my @chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '.', '_', '~');
    $code_verifier = join('', map { $chars[rand @chars] } 1 .. 64);
  } else {
    $listener = _start_listener($options{port});
    my $port = $listener->sockport();
    $log->debugf('Loopback listener started on port %d', $port);
    $redirect_uri = "http://127.0.0.1:$port/";
  }

  my %auth_args = (
    client_id    => $client_id,
    scope        => \@DEFAULT_SCOPES,
    token_store  => $token_store,
    callback_uri => $redirect_uri,
  );
  $auth_args{code_verifier} = $code_verifier if $code_verifier;

  my $auth = Google::Auth::UserAuthorizer->new(%auth_args);

  my %auth_options;
  $auth_options{additional_parameters} = {token_usage => 'remote'}
    if $use_oob;

  my @state_chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9');
  my $state       = join('', map { $state_chars[rand @state_chars] } 1 .. 32);
  $auth_options{state} = $state;

  my $auth_url = $auth->get_authorization_url(%auth_options);

  print "\nGo to the following link in your browser:\n\n    $auth_url\n\n";

  my $code;
  if ($use_oob) {
    print "Enter authorization code: ";
    $code = <STDIN>;
    chomp $code if $code;
  } else {
    $log->info('Waiting for authorization code...');
    $code = _wait_for_code($listener, $options{timeout});
  }

  if ($code) {
    $log->info('Exchanging code for credentials...');

    my $user_id = 'default';    # TODO: use email if available

    eval {
      $auth->get_and_store_credentials_from_code(
        user_id  => $user_id,
        code     => $code,
        base_url => $redirect_uri,
      );
    };
    if ($@) {
      $log->errorf('Failed to exchange code: %s', $@);
      die "Error: Failed to exchange code: $@\n";
    }

    $log->info('Login successful. Credentials saved.');
    print "Login successful.\n";
  }

  $log->trace('Leaving do_login');
}

sub do_adc_login {
  my (%options) = @_;
  $log->info('Command: application-default login initiated');
  $log->trace('Entering do_adc_login');

  my $client_id_file = $options{client_id_file};
  my $store_dir      = $options{store_dir};

  my $client_id;
  if ($client_id_file && -f $client_id_file) {
    $client_id = Google::Auth::ClientId->from_file($client_id_file);
  } else {
    $log->info('Using default ADC Client ID');
    $client_id = Google::Auth::ClientId->new(
      id =>
'764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com',
      secret => 'd-FL95Q19q7MQmFpd7hHD0Ty',
    );
  }
  my $token_store =
    Google::Auth::Stores::FileTokenStore->new(store_dir => $store_dir);

  my $listener;
  my $redirect_uri;

  my $use_oob = $options{no_browser};
  unless ($use_oob || $options{port}) {
    if ($^O eq 'linux' && !$ENV{DISPLAY} && !$ENV{WAYLAND_DISPLAY}) {
      $log->info(
        'No DISPLAY detected on Linux, defaulting to out-of-band flow');
      $use_oob = 1;
    }
  }

  my $code_verifier;
  if ($use_oob) {
    $redirect_uri =
      'https://sdk.cloud.google.com/applicationdefaultauthcode.html';
    my @chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '.', '_', '~');
    $code_verifier = join('', map { $chars[rand @chars] } 1 .. 64);
  } else {
    $listener = _start_listener($options{port});
    my $port = $listener->sockport();
    $log->debugf('Loopback listener started on port %d', $port);
    $redirect_uri = "http://127.0.0.1:$port/";
  }

  my %auth_args = (
    client_id    => $client_id,
    scope        => \@DEFAULT_SCOPES,
    token_store  => $token_store,
    callback_uri => $redirect_uri,
  );
  $auth_args{code_verifier} = $code_verifier if $code_verifier;

  my $auth = Google::Auth::UserAuthorizer->new(%auth_args);

  my %auth_options;
  $auth_options{additional_parameters} = {token_usage => 'remote'}
    if $use_oob;

  my @state_chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9');
  my $state       = join('', map { $state_chars[rand @state_chars] } 1 .. 32);
  $auth_options{state} = $state;

  my $auth_url = $auth->get_authorization_url(%auth_options);

  print "\nGo to the following link in your browser:\n\n    $auth_url\n\n";

  my $code;
  if ($use_oob) {
    print "Enter authorization code: ";
    $code = <STDIN>;
    chomp $code if $code;
  } else {
    $log->info('Waiting for authorization code...');
    $code = _wait_for_code($listener, $options{timeout});
  }

  if ($code) {
    $log->info('Exchanging code for credentials...');

    my $creds;
    eval {
      $creds = $auth->get_credentials_from_code(
        code     => $code,
        base_url => $redirect_uri,
      );
    };
    if ($@) {
      $log->errorf('Failed to exchange code: %s', $@);
      die "Error: Failed to exchange code: $@\n";
    }

    $log->info('Code exchanged successfully.');

    my $adc_path = _get_adc_path();
    unless ($adc_path) {
      $log->error('Failed to determine ADC path');
      die "Error: Failed to determine ADC path (HOME or APPDATA not set?)\n";
    }

    $log->debugf('Target ADC path: %s', $adc_path);

    my $adc_data = {
      type          => 'authorized_user',
      client_id     => $creds->client_id,
      client_secret => $creds->client_secret,
      refresh_token => $creds->refresh_token,
    };

    my ($volume, $directories, $file) = File::Spec->splitpath($adc_path);
    my $adc_dir = File::Spec->catpath($volume, $directories, '');
    if (!-d $adc_dir) {
      require File::Path;
      eval { File::Path::make_path($adc_dir) };
      if ($@) {
        $log->errorf('Failed to create ADC directory %s: %s', $adc_dir, $@);
        die "Error: Failed to create ADC directory: $@\n";
      }
    }

    require Fcntl;
    sysopen(my $fh, $adc_path,
      Fcntl::O_CREAT() | Fcntl::O_WRONLY() | Fcntl::O_TRUNC(), 0600)
      or die "Error: Failed to write to $adc_path: $!\n";

    print $fh encode_json($adc_data);
    close($fh) or die "Error: Failed to close $adc_path: $!\n";

    $log->info('ADC Login successful. Credentials saved to ' . $adc_path);
    print "Application Default Credentials saved to $adc_path\n";
  }

  $log->trace('Leaving do_adc_login');
}

sub _get_adc_path {
  require Google::Auth::EnvironmentVars;
  my $env = Google::Auth::EnvironmentVars->new();

  my $home = $ENV{HOME};
  if ($^O eq 'MSWin32') {
    $home = $ENV{APPDATA};
  }

  return unless $home;

  if ($^O eq 'MSWin32') {
    return File::Spec->catfile($home, 'gcloud',
      'application_default_credentials.json');
  } else {
    my $config_dir =
      $env->CLOUD_SDK_CONFIG_DIR || File::Spec->catdir($home, '.config');
    return File::Spec->catfile($config_dir, 'gcloud',
      'application_default_credentials.json');
  }
}

sub do_print_access_token {
  my (%options) = @_;
  $log->info('Command: print-access-token initiated');
  $log->trace('Entering do_print_access_token');

  my $store_dir = $options{store_dir};
  my $user_id   = 'default';             # TODO: allow specifying user/account

  require Google::Auth::Stores::FileTokenStore;
  my $token_store =
    Google::Auth::Stores::FileTokenStore->new(store_dir => $store_dir);

  my $json = $token_store->load($user_id);
  unless ($json) {
    $log->error("No credentials found for user $user_id");
    die "Error: No credentials found. Please run 'login' first.\n";
  }

  require JSON::MaybeXS;
  my $creds_data = JSON::MaybeXS::decode_json($json);

  require Google::Auth::UserRefreshCredentials;
  my $creds = Google::Auth::UserRefreshCredentials->new(
    client_id     => $creds_data->{client_id},
    client_secret => $creds_data->{client_secret},
    refresh_token => $creds_data->{refresh_token},
  );

  my $token;
  eval { $token = $creds->get_token(); };
  if ($@) {
    $log->errorf('Failed to fetch access token: %s', $@);
    die "Error: Failed to fetch access token: $@\n";
  }

  if ($token) {
    print "$token\n";
    $log->info('Access token printed successfully');
  } else {
    $log->error('Failed to obtain access token (empty)');
    die "Error: Failed to obtain access token.\n";
  }

  $log->trace('Leaving do_print_access_token');
}

sub do_revoke {
  my (%options) = @_;
  $log->info('Command: revoke initiated');
  $log->trace('Entering do_revoke');

  my $store_dir = $options{store_dir};
  my $user_id   = 'default';             # TODO: allow specifying user/account

  require Google::Auth::Stores::FileTokenStore;
  my $token_store =
    Google::Auth::Stores::FileTokenStore->new(store_dir => $store_dir);

  my $json = $token_store->load($user_id);
  unless ($json) {
    $log->warn("No credentials found for user $user_id to revoke");
    print "No credentials found to revoke.\n";
    return;
  }

  require JSON::MaybeXS;
  my $creds_data = JSON::MaybeXS::decode_json($json);

  my $refresh_token = $creds_data->{refresh_token};

  if ($refresh_token) {
    $log->info('Revoking refresh token...');

    # Google revocation endpoint
    my $revoke_uri = $ENV{GOOGLE_AUTH_REVOKE_URI}
      // 'https://oauth2.googleapis.com/revoke';

    # We need an LWP::UserAgent or similar.
    # Let's see if we can use Google::Auth::UserRefreshCredentials->ua or just LWP directly.
    # UserRefreshCredentials doesn't expose UA easily without instance.
    # Let's check Google::Auth::RetryHelper or invent one.

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new();

    my $res = $ua->post($revoke_uri, {token => $refresh_token});

    if ($res->is_success) {
      $log->info('Token revocation request successful');
    } else {
      $log->warnf('Token revocation request failed: %s', $res->status_line);

      # We proceed to delete locally anyway? Yes, common practice.
    }
  }

  $log->info('Deleting local credentials...');
  $token_store->delete($user_id);

  print "Credentials revoked.\n";

  $log->trace('Leaving do_revoke');
}

__END__

=head1 NAME

gcloud-auth - CLI utility for Google Cloud Authentication

=head1 SYNOPSIS

gcloud-auth [options] [command]

 Commands:
   login               Log in using your user credentials
   application-default Login for running applications locally
   print-access-token  Print the current access token
   revoke              Revoke credentials and delete local copy

 Options:
   --help              Show brief help message
   --man               Show full documentation

=head1 DESCRIPTION

B<gcloud-auth> provides a CLI interface to manage credentials for Google Cloud Platform,
emulating core parts of the C<gcloud auth> CLI.

=cut
