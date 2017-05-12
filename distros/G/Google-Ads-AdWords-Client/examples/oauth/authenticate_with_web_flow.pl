#!/usr/bin/perl
#
# Copyright 2016, Google Inc. All Rights Reserved.
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
#
# This demonstrates how to start up a simple web server and allow a user to log
# into an AdWords account in order to provide access using the OAuth2 web flow.
# To use this example:
# * Start this script, and make note of the PID of the web server.
# * Open a web browser to http://localhost:8080/login
# * Follow the prompts using the email address of the AdWords account
#   where you want to allow access.
# * This script will receive back a code from the OAuth2 server that is then
#   exchanged for an access token and a refresh token.
#   This is the point in your own application where you would save off the
#   refresh token and the customer information in order to allow both continued
#   and offline access for your application.
# * This simple example only displays the refresh token in the browser.
# * When you're done with the example, you can kill the web server with
#   the PID that was provided when the web server was brought online.

use Cwd qw(abs_path);

{
  package ExampleWebServer;

  use strict;
  use lib "../../lib";

  use Google::Ads::AdWords::Client;
  use HTTP::Request;
  use HTTP::Server::Simple::CGI;
  use LWP::UserAgent;

  use base qw(HTTP::Server::Simple::CGI);

  my $client;
  my $auth_handler;
  my %url_to_method = (
    # /login-complete is a callback from the OAuth2 server with a code needed
    # to retrieve the access token and refresh token.
    '/login-complete' => \&resp_login_complete,
    # /login would be called by the user to log in.
    '/login'          => \&resp_login
  );

  # Call the requested method, and display a response.
  sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path    = $cgi->path_info();
    my $handler = $url_to_method{$path};

    if (ref($handler) eq "CODE") {
      $handler->($cgi);
    } else {
      print "HTTP/1.0 404 Not found\r\n";
      print $cgi->header,
        $cgi->start_html('Not found'),
        $cgi->h1('Not found'),
        $cgi->end_html;
    }
  }

  # This starts the OAuth2 authentication process where the user will be
  # prompted to log in with the credentials that have access to their AdWords
  # account. During this process, the user has to confirm that permission is
  # granted for our application to access AdWords using their credentials.
  sub resp_login {
    my $cgi = shift;
    return if !ref $cgi;

    # Get AdWords Client, ~/adwords.properties will be read.
    $client       = Google::Ads::AdWords::Client->new();
    $auth_handler = $client->get_oauth_2_handler();

    # Create an HTTP POST request to call the AdWords login.
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my @headers = ();
    push @headers, "Content_Type"   => "text/xml; charset=utf-8";
    push @headers, "Content-Length" => "0";
    my $request =
      HTTP::Request->new("POST", $auth_handler->get_authorization_url(),
      \@headers);
    my $response = $ua->request($request);

    # The OAuth2 API may want you to redirect to an interface that
    # allows the user to log-in or choose their account. Look for this in the
    # Location field of the header.
    my $location = $response->header("Location");
    if ($location) {
      $request = HTTP::Request->new("POST", $location, \@headers);
      $response = $ua->request($request);
    }
    print $response->as_string();
  }

  # After the user logs in and accepts the OAuth2 prompt, the server will then
  # redirect and call this method. A code will be returned that can be
  # exchanged for an access token and refresh token. In this example,
  # 'offline' mode is being used, which is why we're retrieving the refresh
  # token. If the mode was not 'offline', then only an access token would
  # be returned.
  sub resp_login_complete {
    my $cgi = shift;
    return if !ref $cgi;

    # In the URL, the web flow login process will return a code.
    # That code is exchanged for an access token.
    # Once the access token is ready to go and the customer ID is set,
    # then you can make calls to the API for that user.
    my $code = $cgi->param('code');
    $auth_handler->issue_access_token($code);
    my $refresh_token = $auth_handler->get_refresh_token();

    # Save off the refresh token and the user, so that they can access
    # access their information later or you can run reports later on without
    # having to log in again.
    print sprintf("Refresh Token: %s", $refresh_token);
  }
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Start the example server on port 8080.
my $pid = ExampleWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";
