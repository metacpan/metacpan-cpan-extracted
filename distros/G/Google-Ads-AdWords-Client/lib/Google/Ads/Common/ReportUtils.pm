# Copyright 2011, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::ReportUtils;

use strict;
use utf8;
use version;

use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Reports::ReportingConfiguration;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Google::Ads::Common::ReportDownloadError;
use Google::Ads::Common::ReportDownloadHandler;

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

# Prepares and returns a Google::Ads::Common::ReportDownloadHandler.
sub get_report_handler {
  my ($report_definition, $client, $server, $timeout) = @_;

  my $prepared_data =
    __prepare_request($report_definition, $client, $server, $timeout);

  return Google::Ads::Common::ReportDownloadHandler->new({
      client          => $client,
      __user_agent    => $prepared_data->{lwp},
      __http_request  => $prepared_data->{request},
      download_format => $prepared_data->{format},
  });
}

# Creates and properly configures an LWP::UserAgent and HTTP::Request
# for the specified parameters. Returns a hash with the keys: lwp,
# request, format.
sub __prepare_request {
  my ($report_definition, $client, $server, $timeout) = @_;

  # Build report download url.
  $server = $server ? $server : $client->get_alternate_url();
  $server = $server =~ /\/$/ ? substr($server, 0, -1) : $server;
  my $url;

  $url = sprintf(Google::Ads::AdWords::Constants::ADHOC_REPORT_DOWNLOAD_URL,
    $server, $client->get_version());

  my $lwp = LWP::UserAgent->new();

  # Set agent timeout.
  $lwp->timeout(
      $timeout
    ? $timeout
    : Google::Ads::AdWords::Constants::LWP_DEFAULT_TIMEOUT
  );

  # Set the authorization headers.
  my @headers = ();

  my $auth_handler = $client->_get_auth_handler();

  if ($auth_handler->isa("Google::Ads::Common::OAuth2BaseHandler")) {
    # In this case we use the client OAuth2
    push @headers,
      "Authorization" => "Bearer " . $auth_handler->get_access_token();
  } else {
    my $handler_warning = "The authorization handler is not supported.";
    if ($client->get_die_on_faults()) {
      die($handler_warning);
    } else {
      warn($handler_warning);
    }
  }

  my $current_version = $client->get_version();
  $current_version =~ s/[^0-9]//g;
  if ($client->get_client_id()) {
    push @headers, "clientCustomerId" => $client->get_client_id();
  }

  # Set reporting configuration headers.
  my $reporting_config = $client->get_reporting_config();
  if (
    $reporting_config
    and (defined $reporting_config->get_skip_header()
      or defined $reporting_config->get_skip_column_header()
      or defined $reporting_config->get_skip_summary()
      or defined $reporting_config->get_include_zero_impressions()
      or defined $reporting_config->get_use_raw_enum_values()))
  {
    if (defined $reporting_config->get_skip_header()) {
      push @headers,
        "skipReportHeader" => $reporting_config->get_skip_header()
        ? "true"
        : "false";
    }
    if (defined $reporting_config->get_skip_column_header()) {
      push @headers,
        "skipColumnHeader" => $reporting_config->get_skip_column_header()
        ? "true"
        : "false";
    }
    if (defined $reporting_config->get_skip_summary()) {
      push @headers,
        "skipReportSummary" => $reporting_config->get_skip_summary()
        ? "true"
        : "false";
    }
    if (defined $reporting_config->get_include_zero_impressions()) {
      push @headers, "includeZeroImpressions" =>
        $reporting_config->get_include_zero_impressions() ? "true" : "false";
    }
    if (defined $reporting_config->get_use_raw_enum_values()) {
      push @headers,
        "useRawEnumValues" => $reporting_config->get_use_raw_enum_values()
        ? "true"
        : "false";
    }
  }
  push @headers, "developerToken" => $client->get_developer_token();

  # Read proxy configuration for the enviroment.
  $lwp->env_proxy();

  # Prepare the request.
  my $request;
  my $format;
  if (ref($report_definition) eq "HASH") {
    push @headers, "Content-Type" => "application/x-www-form-urlencoded";
    $request = HTTP::Request->new("POST", $url, \@headers,
      "__rdquery=" . uri_escape_utf8($report_definition->{query}) . "&__fmt=" .
        uri_escape_utf8($report_definition->{format}));
    $format = $report_definition->{format};
  } else {
    push @headers, "Content-Type" => "application/x-www-form-urlencoded";
    $request = HTTP::Request->new(
      "POST", $url,
      \@headers,
      "__rdxml=" .
        uri_escape_utf8(
        "<reportDefinition>" . $report_definition . "</reportDefinition>"
        ));
    $format = $report_definition->get_downloadFormat() . "";
  }

  return {
    lwp     => $lwp,
    request => $request,
    format  => $format
  };
}

sub __extract_xml_error {
  my $ref = XML::Simple->new()->XMLin(shift, ForceContent => 1);

  return Google::Ads::Common::ReportDownloadError->new({
      type       => $ref->{ApiError}->{type}->{content},
      field_path => $ref->{ApiError}->{fieldPath}->{content}
      ? $ref->{ApiError}->{fieldPath}->{content}
      : "",
      trigger => $ref->{ApiError}->{trigger}->{content}
      ? $ref->{ApiError}->{trigger}->{content}
      : ""
    });
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::ReportUtils

=head1 SYNOPSIS

 use Google::Ads::Common::ReportUtils;

 my $response =
     Google::Ads::Common::ReportUtils::get_report_handler($report_definition,
                                                           $client);
 my $result = $response->save($outputfile);
 if (!$result) {
     printf("An error has occurred of type '%s', triggered by '%s'.\n",
            $result->get_type(), $result->get_trigger());
 }

=head1 DESCRIPTION

Google::Ads::Common::ReportUtils a collection of utility methods for working
with reports.

=head1 SUBROUTINES

=head2 get_report_handler

Prepares a new instance of L<Google::Ads::Common::ReportDownloadHandler> using
the specified parameters. The actual download of report contents will not be
invoked by this procedure, but instead will occur when you call one of the
procedures on the returned handler to save the report to a file, get its
contents as a string, etc.

=head3 Parameters

=over

=item *

The report_definition parameter is either:

=over

=item *

A C<ReportDefinition> object to be defined and downloaded on the fly OR

=item *

A hash with an AWQL query and format. i.e.

  { query => 'query',
    format => 'format' }

=back

=item *

The client parameter is an instance of a valid L<Google::AdWords::Client>.

=item *

The server is an optional parameter that can be set to alter the URL from where
the report will be requested.

=item *

The timeout is an optional parameter that can be set to alter the default
time that the http client waits to get a response from the server. If not set,
the default timeout used is
L<Google::Ads::Common::ReportUtils::LWP_DEFAULT_TIMEOUT>.

=back

=head3 Returns

A new L<Google::Ads::Common::ReportDownloadHandler>. See the methods of
L<Google::Ads::Common::ReportDownloadHandler> that support different use
cases for processing the response's contents.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
