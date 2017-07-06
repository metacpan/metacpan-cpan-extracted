# Copyright 2015, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::ReportDownloadHandler;

use strict;
use warnings;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Reports::ReportingConfiguration;
use Google::Ads::AdWords::RequestStats;
use Google::Ads::Common::ReportDownloadError;
use Google::Ads::Common::Utilities::AdsUtilityRegistry;

use Class::Std::Fast;

use File::stat;
use HTTP::Request;
use HTTP::Status qw(:constants);
use Log::Log4perl qw(:levels);
use LWP::UserAgent;
use MIME::Base64;
use POSIX;
use Time::HiRes qw(gettimeofday tv_interval);
use URI::Escape;
use XML::Simple;

use constant SCRUBBED_HEADERS => qw(DeveloperToken Authorization);

my %client_of : ATTR(:name<client> :default<>);
my %__user_agent_of : ATTR(:name<__user_agent> :default<>);
my %__http_request_of : ATTR(:name<__http_request> :default<>);
my %download_format_of : ATTR(:name<download_format> :default<>);

# Returns the report contents as a string. If the report fails then returns
# a ReportDownloadError.
sub get_as_string {
  my ($self) = @_;

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
      "ReportDownloaderString");

  my $user_agent = $self->get___user_agent();

  $self->__set_gzip_header();
  my $start_time = [gettimeofday()];

  my $response = $user_agent->request($self->get___http_request());
  $response = $self->__check_response($response, $start_time);
  if (ref $response eq "Google::Ads::Common::ReportDownloadError") {
    return $response;
  }
  return $response->decoded_content();
}

# Saves the report response to a file. If the report fails then returns
# a ReportDownloadError. Otherwise, returns the HTTPResponse.
sub save {
  my ($self, $file_path) = @_;
  if (!$file_path) {
    warn 'No file path provided';
    return undef;
  }

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
      "ReportDownloaderFile");

  my $gzip_support = $self->__set_gzip_header();
  my $request      = $self->get___http_request();
  my $format       = $self->get_download_format();
  my $start_time   = [gettimeofday()];
  my $response;
  ($file_path) = glob($file_path);
  if (!$gzip_support) {
    # If not gzip support then we can stream directly to a file.
    $response = $self->get___user_agent()->request($request, $file_path);
    $response = $self->__check_response($response, $start_time);
  } else {
    my $mode = ">:utf8";
    if ($format =~ /^GZIPPED|PDF/) {
      # Binary format can't dump as UTF8.
      $mode = ">";
    }
    open(FH, $mode, $file_path)
      or warn "Can't write to '$file_path': $!";
    $response = $self->get___user_agent()->request($request);
    $response = $self->__check_response($response, $start_time);
    if (ref $response eq "Google::Ads::Common::ReportDownloadError") {
      return $response;
    }
    # Need to decode in a file.
    print FH $response->decoded_content();
    close FH;
  }
  return $response;
}

# Use this method to process results as a stream. For each chunk of data
# returned, the content_callback will be invoked with two arguments:
#   $data - the chunk of data
#   $response - the HTTP::Response
# If the report fails then returns a ReportDownloadError. Otherwise, returns
# the HTTP::Response object.
sub process_contents {
  my ($self, $content_callback) = @_;

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
      "ReportDownloaderStream");

  # Do not set the gzip header. If it is set then $content_callback will
  # get compressed data and we don't want clients to have to deal with
  # inflating the data.
  my $request    = $self->get___http_request();
  my $user_agent = $self->get___user_agent();
  my $start_time = [gettimeofday()];
  my $response   = $user_agent->request($request, $content_callback);
  $response = $self->__check_response($response, $start_time);
  return $response;
}

# Checks the response's status code. If OK, then returns the HTTPResponse.
# Otherwise, returns a new ReportDownloadError.
sub __check_response {
  my ($self, $response, $start_time) = @_;
  my $is_successful = 0;
  my $report_download_error;
  my $return_val;

  if ($response->code == HTTP_OK) {
    $is_successful = 1;
    $return_val    = $response;
  } else {
    if ($response->code == HTTP_BAD_REQUEST) {
      $report_download_error = $self->__extract_xml_error($response);
    } else {
      $report_download_error = Google::Ads::Common::ReportDownloadError->new({
          response_code    => $response->code,
          response_message => $response->message
      });
    }
    $return_val = $report_download_error;
  }
  # Log request and response information before returning the result.
  $self->__log_report_request_response($response, $is_successful,
    $report_download_error, tv_interval($start_time));
  return $return_val;
}

# Sets the header and updates the user agent for gzip support if the
# environment supports gzip compression.
sub __set_gzip_header {
  my ($self) = @_;
  my $user_agent = $self->get___user_agent();

  my $can_accept = HTTP::Message::decodable;
  my $gzip_support = $can_accept =~ /gzip/i;

  # Setting HTTP user-agent and gzip compression.
  $user_agent->default_header("Accept-Encoding" => scalar $can_accept);

  # Set the header for gzip support.
  $user_agent->agent(
    $self->get_client()->get_user_agent() . ($gzip_support ? " gzip" : ""));
  return $gzip_support;
}

# Returns a new ReportDownloadError containing the error details of the
# failed HTTP::Response.
sub __extract_xml_error {
  my ($self, $response) = @_;
  my $ref =
    XML::Simple->new()->XMLin($response->decoded_content(), ForceContent => 1);

  return Google::Ads::Common::ReportDownloadError->new({
      response_code    => $response->code,
      response_message => $response->message,
      type             => $ref->{ApiError}->{type}->{content},
      field_path       => $ref->{ApiError}->{fieldPath}->{content}
      ? $ref->{ApiError}->{fieldPath}->{content}
      : "",
      trigger => $ref->{ApiError}->{trigger}->{content}
      ? $ref->{ApiError}->{trigger}->{content}
      : ""
    });
}

# Logs the report request, response, and stats.
sub __log_report_request_response {
  my ($self, $response, $is_successful, $error_message, $elapsed_seconds) = @_;

  my $client  = $self->get_client();
  my $request = $self->get___http_request();

  # Always log the request stats to the AdWordsAPI logger.
  my $auth_handler = $client->_get_auth_handler();

  my $request_stats = Google::Ads::AdWords::RequestStats->new({
      server        => $client->get_alternate_url(),
      client_id     => $client->get_client_id(),
      service_name  => $request->uri,
      method_name   => $request->method,
      is_fault      => !$is_successful,
      response_time => int(($elapsed_seconds * 1000) + 0.5),
      fault_message => (!$is_successful) ? $response->message : ""
  });
  $client->_push_new_request_stats($request_stats);
  Google::Ads::AdWords::Logging::get_awapi_logger->info($request_stats);

  # Log the request.
  if ($request) {
    # Log the full request:
    #  To WARN if the request failed OR
    #  To INFO if the request succeeded
    my $request_string = $request->as_string("\n");
    # Remove sensitive information from the log message.
    foreach my $header (SCRUBBED_HEADERS) {
      $request_string =~ s!(\n$header):(.*)\n!$1: REDACTED\n!;
    }
    my $log_message = sprintf(
      "Outgoing request:\n%s",
      $request_string
    );
    Google::Ads::AdWords::Logging::get_soap_logger->log(
      $is_successful ? $INFO : $WARN, $log_message);
  }

  # Log the response.
  if ($response) {
    # Log:
    #  To WARN if the request failed OR
    #  To INFO (status and message only)
    my $response_string = $response->headers_as_string("\n");
    # Remove sensitive information from the log message.
    foreach my $header (SCRUBBED_HEADERS) {
      $response_string =~ s!(\n$header):(.*)\n!$1: REDACTED\n!;
    }
    my $log_message = sprintf(
      "Incoming %s report response with status code %s and message '%s'\n%s" .
      "REDACTED REPORT DATA",
      $is_successful ? 'successful' : 'failed',
      $response->code, $response->message,
      $response_string
    );

    if ($is_successful) {
      Google::Ads::AdWords::Logging::get_soap_logger->info($log_message);
    } else {
      if (ref $error_message eq "Google::Ads::Common::ReportDownloadError") {
        $log_message = $log_message .
          sprintf(
          ": An error has occurred of type '%s', triggered by '%s'",
          $error_message->get_type(),
          $error_message->get_trigger());
      } elsif ($error_message) {
        $log_message = $log_message . ': ' . $error_message;
      }
      Google::Ads::AdWords::Logging::get_soap_logger->logwarn($log_message);
    }
  }
}

1;

=pod

=head1 NAME

Google::Ads::Common::ReportDownloadHandler

=head1 DESCRIPTION

Represents a report response from the AdWords API.


=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY methods:

=over

=item * client

A reference to a Google::Ads::AdWords::Client.

=item * __user_agent (Private)

A reference to an LWP::UserAgent.

=item * __http_request (Private)

A reference to an HTTP::Request.

=item * download_format

The download format of the request.

=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::Common::ReportDownloadHandler
   client =>  $response, # A ref to a Google::Ads::AdWords::Client object
   __user_agent => $user_agent, # A ref to an LWP::UserAgent
   __http_request => $request, # A ref to an HTTP::Request object
   download_format => $download_format, # The download format for the request
 },

=head1 METHODS

=head2 get_as_string

Issues the report request to the AdWords API and returns the report contents
as a string.

=head3 Returns

The report contents as a string if the request is successful. Otherwise, returns
a L<Google::Ads::Common::ReportDownloadError>. Check for failures by evaluating
the return value in a boolean context, where a
L<Google::Ads::Common::ReportDownloadError> will always evaluate to false.

=head3 Exceptions

Returns a L<Google::Ads::Common::ReportDownloadError> if the report request
fails.

=head2 save

Issues the report request to the AdWords API and saves the report contents
to a file.

=head3 Parameters

=over

=item *

The destination file for the report contents.

=back

=head3 Returns

The report contents as a string if the request is successful. Otherwise, returns
a L<Google::Ads::Common::ReportDownloadError>. Check for failures by
evaluating the return value in a boolean context, where a
L<Google::Ads::Common::ReportDownloadError> will always evaluate to false.

=head3 Exceptions

Returns a L<Google::Ads::Common::ReportDownloadError> if the report request
fails.

=head2 process_contents

Issues the report request to the AdWords API and invokes a callback for each
chunk of content received. Use this method to process the report contents as
a stream.

=head3 Parameters

=over

=item *

A content_callback that will be invoked for each chunk of data returned
by the report request. Each invocation will be passed two arguments:

=over

=item *

The chunk of data

=item *

The HTTP::Response

=back

=back

=head3 Returns

An HTTP::Response if the request is successful. Otherwise, returns
a L<Google::Ads::Common::ReportDownloadError>. Check for failures by
evaluating the return value in a boolean context, where a
L<Google::Ads::Common::ReportDownloadError> will always evaluate to false.

=head3 Exceptions

Returns a L<Google::Ads::Common::ReportDownloadError> if the report request
fails.

=cut

