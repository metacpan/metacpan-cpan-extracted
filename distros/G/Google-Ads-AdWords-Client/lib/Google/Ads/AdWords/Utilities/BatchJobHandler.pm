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

package Google::Ads::AdWords::Utilities::BatchJobHandler;

use strict;
use warnings;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Serializer;
use Google::Ads::AdWords::Utilities::BatchJobHandlerError;
use Google::Ads::AdWords::Utilities::BatchJobHandlerStatus;
use Google::Ads::Common::Utilities::AdsUtilityRegistry;
use Google::Ads::SOAP::Deserializer::MessageParser;

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

# For incremental uploads, the size (in bytes) of the body of the request
# must be multiples of 256K.
use constant REQUIRED_CONTENT_LENGTH_INCREMENT => 262144;

my %client_of : ATTR(:name<client> :default<>);

# Upload a list of operations. Returns the BatchJobHandlerStatus.
# If the request fails this returns a BatchJobHandlerError.
# The timeout is an optional parameter that can be set to alter the default
# time that the http client waits to get a response from the server.
# If the timeout is not specified, the default is
# Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT
sub upload_operations {
  my ($self, $operations, $url, $timeout) = @_;

  my $status = Google::Ads::AdWords::Utilities::BatchJobHandlerStatus->new({
    total_content_length => 0,
    resumable_upload_uri => $url
  });
  my $is_last_request = 1;

  return $self->upload_incremental_operations($operations, $status,
    $is_last_request, $timeout);
}

# Upload a list of operations incrementally. Send operations to the upload URL
# as the operations are available. The operations will not be
# executed until the boolean is set indicating that it's the last request.
# This returns the current BatchJobHandlerStatus. Keep track of this
# BatchJobHandlerStatus as you will need to pass it in to the next request
# as the $status.
sub upload_incremental_operations {
  my ($self, $operations, $status, $is_last_request, $timeout) = @_;
  if (!$status) {
    return Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
      type        => "UPLOAD",
      description => "Required: BatchJobHandlerStatus"
    });
  }

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
    "BatchJobHandler");

  my $url                  = $status->get_resumable_upload_uri();
  my $total_content_length = $status->get_total_content_length();
  my $is_first_request     = $total_content_length == 0;
  if (!$url || $url eq '') {
    return Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
      type        => "UPLOAD",
      description => "Required: BatchJobHandlerStatus.resumable_upload_uri"
    });
  }

  # If this is the first request, then take the URI passed in and make a request
  # to that URI for the URI to which the operations will be uploaded. That
  # URI will then be stored in the BatchJobHelperStatus.
  if ($is_first_request) {
    my $response =
      $self->__initialize_upload($url, $self->get_client(), $timeout);
    if (!$response) {
      return $response;
    }
    $url = $response;
    $status->set_resumable_upload_uri($url);
  }

  # The process below follows the Google Cloud Storage guidelines for resumable
  # uploads of unknown size:
  # https://cloud.google.com/storage/docs/concepts-techniques#unknownresumables
  my $upload_request =
    __prepare_upload_request($operations, $url, $self->get_client(), "PUT",
    $timeout);

  # For incremental upload, the headers will need additional arguments, and the
  # content will need to be padded until the bytes are an increment of 256K.
  my $request = $upload_request->{request};
  my $xml     = $request->content();

  $xml = $self->__update_tags($is_first_request, $is_last_request, $xml);

  my $padded_xml = _add_padding($xml);
  $request->content($padded_xml);
  my $content_length = 0;
  {
    use bytes;
    $content_length = length($padded_xml);
  }

  $self->__set_incremental_operations_headers($request, $total_content_length,
    $content_length, $is_last_request);

  # Continue with making the request.
  my $start_time = [gettimeofday()];
  my $response   = $upload_request->{lwp}->request($request);
  $response = $self->__check_response($response, $start_time, 1, 0);
  if (!$response) {
    return $response;
  }
  $total_content_length = $total_content_length + $content_length;
  $status->set_total_content_length($total_content_length);
  return $status;
}

# Update tags.
# The process is that a user sends a list of operations to the Google Cloud
# in smaller groups and then requests that all operations execute in a single
# batch job e.g.
# * HTTP Request 1: 1st list of operations
# * HTTP Request 2: 2nd list of operations
# * HTTP Request 3: Final list of operations
# * Execute all operations.
#
# When the list of operations is serialized with each HTTP request, the
# serialization adds a beginning and ending <mutate> tag. However, the
# AdWords API only want to see the beginning and ending mutate tag in the first
# and last HTTP requests. Those mutate tags are being stripped out of the middle
# requests e.g.
# * HTTP Request 1: <mutate><operations/> <== Take out the </mutate>
# * HTTP Request 2: <operations/> <== Take out the <mutate> and </mutate>
# * HTTP Request 3: <operations/></mutate> <== Take out the <mutate>
# * Execute all operations.
sub __update_tags {
  my ($self, $is_first_request, $is_last_request, $xml) = @_;
  # If this is both the 1st and last request, leave the XML alone.
  if (!($is_first_request && $is_last_request)) {
    # If it's not the last request, then remove the ending </mutate>.
    if (!$is_last_request) {
      my $find = "</mutate>\\s*\$";
      $xml =~ s/$find//;
    }
    # If it's not the first request, then remove everything before <operations>.
    if (!$is_first_request) {
      my $find    = "^.*?<operations";
      my $replace = "<operations";
      $xml =~ s/$find/$replace/;
    }
  }
  return $xml;
}

# Set the headers for the incremental operations requests.
sub __set_incremental_operations_headers {
  my ($self, $request, $total_content_length, $content_length, $is_last_request)
    = @_;
  # Set the Content-Length.
  $request->header("Content-Length" => $content_length);
  # Determine and set the content range.
  my $lower_bound = $total_content_length;
  my $upper_bound = $total_content_length + $content_length - 1;
  # On the last request, specify the total number of bytes
  # e.g. bytes 500-999/1000
  my $total_bytes = ($is_last_request) ? $upper_bound + 1 : "*";
  my $content_range =
    sprintf("bytes %d-%d/%s", $lower_bound, $upper_bound, $total_bytes);
  $request->header("Content-Range" => $content_range);
}

# In the first upload request, take the URI passed in and make a request
# to that URI for the URI to which the operations will be uploaded.
sub __initialize_upload {
  my ($self, $url, $client, $timeout) = @_;

  my $lwp        = LWP::UserAgent->new();
  my $can_accept = HTTP::Message::decodable;
  $lwp->default_header("Accept-Encoding" => scalar $can_accept);

  # Set agent timeout.
  $lwp->timeout(
      $timeout
    ? $timeout
    : Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT
  );

  my @headers = ();
  push @headers, "x-goog-resumable" => "start";
  push @headers, "Content-Length"   => "0";
  push @headers, "Content-Type"     => "application/xml";

  # Read proxy configuration for the enviroment.
  $lwp->env_proxy();

  # Prepare the request.
  my $signed_url = URI->new($url);
  my $request = HTTP::Request->new("POST", $signed_url, \@headers);

  my $start_time = [gettimeofday()];
  my $response   = $lwp->request($request);
  $response = $self->__check_response($response, $start_time, 0, 1);
  if (!$response) {
    return $response;
  }

  return $response->header("Location");
}

# Prepares the HTTP request to upload the operations for the batch job.
# Creates and properly configures an LWP::UserAgent and HTTP::Request
# for the specified operations. Returns a hash with the keys: lwp and
# request.
sub __prepare_upload_request {
  my ($operations, $url, $client, $method, $timeout) = @_;
  my $version    = $client->get_version();
  my $upload_url = URI->new($url);

  # Changing the operations to XML.
  my $batch_job_ops_class =
    "Google::Ads::AdWords::${version}::BatchJobOpsService::mutate";
  eval "require $batch_job_ops_class"
    or return Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
      type => "UPLOAD",
      description =>
        sprintf("Class '%s' expected, but not found.", $batch_job_ops_class)});
  my $batch_job_upload = $batch_job_ops_class->new({operations => $operations});

  # Serialize, and fix the namespace.
  my $xml = $batch_job_upload->serialize();

  my $find = "<mutate";
  my $replace =
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><mutate xmlns:xsi" .
    "=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"" .
    "https://adwords.google.com/api/adwords/cm/$version\"";
  $xml =~ s/$find/$replace/;

  my $lwp = LWP::UserAgent->new();

  # Setting HTTP user-agent and gzip compression.
  my $can_accept = HTTP::Message::decodable;
  $lwp->default_header("Accept-Encoding" => scalar $can_accept);

  # Set agent timeout.
  $lwp->timeout(
      $timeout
    ? $timeout
    : Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT
  );

  # Set the authorization headers.
  my @headers = ();

  # Read proxy configuration for the enviroment.
  $lwp->env_proxy();

  # Prepare the request.
  push @headers, "Content-Type" => "application/xml";
  my $request = HTTP::Request->new($method, $upload_url, \@headers, $xml);

  return {
    lwp     => $lwp,
    request => $request
  };
}

# Returns an object containing the result of the batch job. This is retrieved
# via the download URL provided in the batch job. On failure, a
# BatchJobHandlerError will be returned.
sub download_response() {
  my ($self, $url, $timeout) = @_;

  my $download_request = __prepare_download_request($url, $timeout);

  my $request    = $download_request->{request};
  my $start_time = [gettimeofday()];
  my $response   = $download_request->{lwp}->request($request);
  $response = $self->__check_response($response, $start_time);
  if (!$response) {
    return $response;
  }

  # Turn this content into a MutateResult object. The deserializer expects
  # the result to be in a soap envelope, and the XML header is not needed.
  my $decoded_content = $response->decoded_content();
  $decoded_content =~ s/^<\?xml[^>]+\?>//;
  my $xml = sprintf(
    "<soap:Envelope xmlns:soap=" .
      "\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body>%s</soap:Body>"
      . "</soap:Envelope>",
    $decoded_content
  );

  my $parser = Google::Ads::SOAP::Deserializer::MessageParser->new({
      strict      => "1"});
  my $version = $self->get_client()->get_version();
  my $service =
    "Google::Ads::AdWords::${version}::TypeMaps::BatchJobOpsService";
  eval "require $service";
  $parser->class_resolver($service);
  eval { $parser->parse_string($xml, $self->get_client()) };
  if ($@) {
    return Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
        type        => "UPLOAD",
        description => sprintf(
          "Error deserializing message: %s. \nMessage was: \n%s.",
          $@, $xml
        )});
  }
  return $parser->get_data();
}

# Prepares a request to download the contents from the batch job download URL.
# Creates and properly configures an LWP::UserAgent and HTTP::Request
# for the specified operations. Returns a hash with the keys: lwp and
# request.
sub __prepare_download_request {
  my ($url, $timeout) = @_;

  my $lwp        = LWP::UserAgent->new();
  my $can_accept = HTTP::Message::decodable;
  $lwp->default_header("Accept-Encoding" => scalar $can_accept);

  # Set agent timeout.
  $lwp->timeout(
      $timeout
    ? $timeout
    : Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT
  );

  my @headers = ();
  # Read proxy configuration for the enviroment.
  $lwp->env_proxy();

  # Prepare the request.
  my $download_url = URI->new($url);
  my $request = HTTP::Request->new("GET", $download_url, \@headers);

  return {
    lwp     => $lwp,
    request => $request
  };
}

# Checks the response's status code. If OK, then returns the HTTPResponse.
# Otherwise, returns a new BatchJobHandlerError.
sub __check_response {
  my ($self, $response, $start_time, $is_incremental, $is_initial) = @_;
  my $is_successful = 0;
  my $batch_job_error;
  my $return_val;

  if ($response->code == HTTP_OK) {
    $is_successful = 1;
    $return_val    = $response;
  } else {
    if ($response->code == HTTP_BAD_REQUEST) {
      $batch_job_error = $self->__extract_xml_error($response);
    } elsif ($is_initial && $response->code == HTTP_CREATED) {
      # This happens when requesting the resumable upload URL from the
      # upload URL passed back in the batch job. This means that
      # the new resumable upload URL is ready to go.
      $return_val = $response;
      return $return_val;
    } elsif ($is_incremental && $response->code == 308) {
      # This happens when doing an incremental upload. It just means that
      # we are not done uploading, yet.
      $return_val = $response;
      return $return_val;
    } else {
      $batch_job_error =
        Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
          type                  => "HTTP",
          http_response_code    => $response->code,
          http_response_message => $response->message
        });
    }
    $return_val = $batch_job_error;
  }
  return $return_val;
}

# Returns a new BatchJobHandlerError containing the error details of the
# failed HTTP::Response.
sub __extract_xml_error {
  my ($self, $response) = @_;
  my $ref =
    XML::Simple->new()->XMLin($response->decoded_content(), ForceContent => 1);

  return Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
      type                  => "HTTP",
      http_response_code    => $response->code,
      http_response_message => $response->message,
      http_type             => $ref->{ApiError}->{type}->{content},
      http_field_path       => $ref->{ApiError}->{fieldPath}->{content}
      ? $ref->{ApiError}->{fieldPath}->{content}
      : "",
      http_trigger => $ref->{ApiError}->{trigger}->{content}
      ? $ref->{ApiError}->{trigger}->{content}
      : ""
    });
}

# Add padding (spaces) to the XML until the XML reaches 256K.
sub _add_padding {
  my $xml = shift;

  # Pad the content. Use braces to keep the scope of the bytes contained.
  my $padding = 0;
  {
    use bytes;
    my $remainder = length($xml) % REQUIRED_CONTENT_LENGTH_INCREMENT;
    if ($remainder > 0) {
      $padding =
        length($xml) + (REQUIRED_CONTENT_LENGTH_INCREMENT - $remainder);
    }
  }
  my $padded_xml = sprintf("%-" . $padding . "s", $xml);
  return $padded_xml;
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::BatchJobHandler

=head1 DESCRIPTION

Processes batch job requests through the AdWords API.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY methods:

=over

=item * client

A reference to a Google::Ads::AdWords::Client.

=back

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::Utilities::BatchJobHandler
   client =>  $client, # A ref to a Google::Ads::AdWords::Client object
 },

=head1 METHODS

=head2 upload_operations

Upload a list of operations. Returns the
L<Google::Ads::AdWords::Utilities::BatchJobHandlerStatus>.
If the request fails this returns a
L<Google::Ads::AdWords::Utilities::BatchJobHandlerError>.

=head3 Parameters

=over

=item *

An array of operations to be uploaded to the upload URL.

=item *

A URL to which to upload (POST) the operations.

=item *

The timeout is an optional parameter that can be set to alter the default
time that the http client waits to get a response from the server.
If the timeout is not specified, the default is
Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT

=back

=head3 Returns

The contents of the HTTP response as a string if the request is successful.
Otherwise, this returns a
L<Google::Ads::AdWords::Utilities::BatchJobHandlerError>.

=head3 Exceptions

Returns a L<Google::Ads::AdWords::Utilities::BatchJobHandlerError> if the
batch job fails immediately.

=head2 upload_incremental_operations

Upload a list of operations incrementally. Send operations to the upload URL
as the operations are available. The operations will not be
executed until the boolean is set indicating that it's the last request.
This returns the current
L<Google::Ads::AdWords::Utilities::BatchJobHandlerStatus>. Keep track of this
status as you will need to pass it in to the next request as the
$status.
If the request fails this returns a
L<Google::Ads::AdWords::Utilities::BatchJobHandlerError>.

=head3 Parameters

=over

=item *

An array of operations to be uploaded to the upload URL.

=item *

The current L<Google::Ads::AdWords::Utilities::BatchJobHandlerStatus>.
In the first request, this object must be initialized with the URL to which
the operations will be uploaded. For any uploads following the first upload,
pass in the L<Google::Ads::AdWords::Utilities::BatchJobHandlerStatus>
from the previous upload.

=item *

If this is the last request to be uploadeed, set the value to true.
False values are: 0, '0', '', (), or undef
True values are anything other than the false values e.g. 1

=item *

A URL to which to upload (POST) the operations.

=item *

The timeout is an optional parameter that can be set to alter the default
time that the http client waits to get a response from the server.
If the timeout is not specified, the default is
Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT

=back

=head3 Returns

This returns L<Google::Ads::AdWords::Utilities::BatchJobHandlerStatus> if the
request is successful. Otherwise, this returns a
L<Google::Ads::AdWords::Utilities::BatchJobHandlerError>.

=head3 Exceptions

Returns a L<Google::Ads::AdWords::Utilities::BatchJobHandlerError> if the
batch job fails immediately.

=head2 download_response

Returns an object containing the result of the batch job. This is retrieved
via the download URL provided in the batch job. On failure, a
BatchJobHandlerError will be returned.

=head3 Parameters

=over

=item *

A URL from which to download (GET) the result of processing the operations.

=item *

The timeout is an optional parameter that can be set to alter the default
time that the http client waits to get a response from the server.
If the timeout is not specified, the default is
Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT

=back

=head3 Returns

BatchJobOpsService::mutateResponse object with contents from the
job's download URL

=head3 Exceptions

Returns a L<Google::Ads::AdWords::Utilities::BatchJobHandlerError> if the
batch job fails immediately.

=cut

