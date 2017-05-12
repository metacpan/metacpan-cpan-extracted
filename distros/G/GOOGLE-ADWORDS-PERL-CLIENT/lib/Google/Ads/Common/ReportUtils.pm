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

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Google::Ads::Common::ReportDownloadError;

use File::stat;
use HTTP::Request;
use HTTP::Status qw(:constants);
use LWP::UserAgent;
use MIME::Base64;
use POSIX;
use URI::Escape;
use XML::Simple;

use constant REPORT_DOWNLOAD_URL => "%s/api/adwords/reportdownload?__rd=%s";
use constant ADHOC_REPORT_DOWNLOAD_URL => "%s/api/adwords/reportdownload/%s";
use constant CLIENT_EMAIL_MAX_VERSION => "201101";
use constant XML_ERRORS_MIN_VERSION => "201209";
use constant LWP_DEFAULT_TIMEOUT => 300; # 5 minutes.

sub download_report {
  my ($report_definition, $client, $file_path, $server,
      $return_money_in_micros, $timeout) = @_;

  # Build report downlad url.
  $server = $server ? $server : $client->get_alternate_url();
  $server = $server =~ /\/$/ ? substr($server, 0, -1) : $server;
  my $url;

  if (isdigit($report_definition)) {
    $url = sprintf(REPORT_DOWNLOAD_URL, $server, $report_definition);
  } else {
    # Assuming is a ReportDefinition object
    $url = sprintf(ADHOC_REPORT_DOWNLOAD_URL, $server, $client->get_version());
  }

  my $lwp = LWP::UserAgent->new();

  # Setting HTTP user-agent and gzip compression.
  my $can_accept = HTTP::Message::decodable;
  my $gzip_support = $can_accept =~ /gzip/i;
  $lwp->default_header("Accept-Encoding" => scalar $can_accept);
  $lwp->agent($client->get_user_agent() . ($gzip_support ? " gzip" : ""));

  # Set agent timeout.
  $lwp->timeout($timeout ? $timeout : LWP_DEFAULT_TIMEOUT);

  # Set the authorization headers.
  my @headers = ();

  my $auth_handler = $client->_get_auth_handler();

  if ($auth_handler->isa("Google::Ads::Common::OAuth2BaseHandler")) {
    # In this case we use the client OAuth2
    push @headers, "Authorization" => "Bearer " .
        $auth_handler->get_access_token();
  } else {
    # In this case we use the client login header.
    push @headers, "Authorization" => "GoogleLogin auth=" .
        $auth_handler->__get_auth_token();
  }

  my $current_version = $client->get_version();
  $current_version =~ s/[^0-9]//g;
  if ($client->get_client_id()) {
    if ($client->get_client_id() =~ /@/) {
      if ($current_version > CLIENT_EMAIL_MAX_VERSION) {
        if ($client->get_die_on_faults()) {
          die("Version " . $client->get_version() .
              " has no support for identifying clients by email.");
        } else {
          warn("Version " . $client->get_version() .
               " has no support for identifying clients by email.");
        }
      } else {
        push @headers, "clientEmail" => $client->get_client_id();
      }
    } else {
      push @headers, "clientCustomerId" => $client->get_client_id();
    }
  } elsif ($current_version <= CLIENT_EMAIL_MAX_VERSION &&
           $client->get_email()) {
    push @headers, "clientEmail" => $client->get_email();
  }

  # Set other headers.
  if (defined $return_money_in_micros) {
    push @headers, "returnMoneyInMicros" => $return_money_in_micros ?
         "true" : "false";
  }
  push @headers, "developerToken" => $client->get_developer_token();

  # Read proxy configuration for the enviroment.
  $lwp->env_proxy();

  # Request the report.
  my $request;
  my $format;
  if (isdigit($report_definition)) {
    $request = HTTP::Request->new("GET", $url, \@headers);
  } elsif (ref($report_definition) eq "HASH") {
    push @headers, "Content-Type" => "application/x-www-form-urlencoded";
    $request = HTTP::Request->new("POST", $url, \@headers, "__rdquery=" .
        uri_escape_utf8($report_definition->{query}) . "&__fmt=" .
        uri_escape_utf8($report_definition->{format}));
    $format = $report_definition->{format};
  } else {
    push @headers, "Content-Type" => "application/x-www-form-urlencoded";
    $request = HTTP::Request->new("POST", $url, \@headers, "__rdxml=" .
        uri_escape_utf8("<reportDefinition>" . $report_definition .
                        "</reportDefinition>"));
    $format = $report_definition->get_downloadFormat() . "";
  }

  my $response;
  if ($file_path) {
    ($file_path) = glob($file_path);
    if (!$gzip_support) {
      # If not gzip support then we can stream directly to a file.
      $response = $lwp->request($request, $file_path);
    } else {
      my $mode = ">:utf8";
      if ($format =~ /^GZIPPED|PDF/) {
        # Binary format can't dump as UTF8.
        $mode = ">";
      }
      open(FH, $mode, $file_path) or warn "Can't write to '$file_path': $!";
      $response = $lwp->request($request);
      # Need to decode in a file.
      print FH $response->decoded_content();
      close FH;
    }
  } else {
    $response = $lwp->request($request);
  }
  if ($response->code == HTTP_OK) {
    if ($file_path) {
      open(FILE, "<", $file_path) or return undef;
      my $result = <FILE>;
      close(FILE);
      if (__extract_legacy_error($result)) {
        return undef;
      }
      return stat($file_path)->size;
    } else {
      return $response->decoded_content();
    }
  } elsif ($response->code == HTTP_BAD_REQUEST) {
    my $result = $response->decoded_content();
    if ($current_version >= XML_ERRORS_MIN_VERSION) {
      return __extract_xml_error($result);
    } else {
      __extract_legacy_error($result);
      return undef;
    }
  } else {
    warn("Report download failed with code '" . $response->code .
         "' and message '" . $response->message . ".");
    return undef;
  }
}

sub __extract_legacy_error {
  my $report_result = shift;
  if ($report_result =~ m/^!!![^|]*\|\|\|([^|]*)\|\|\|([^?]*)\?\?\?/) {
    warn("Report download failed with error " . $2);
    return $2;
  }
  return undef;
}

sub __extract_xml_error {
  my $ref = XML::Simple->new()->XMLin(shift, ForceContent => 1);

  return Google::Ads::Common::ReportDownloadError->new({
    type => $ref->{ApiError}->{type}->{content},
    field_path => $ref->{ApiError}->{fieldPath}->{content} ?
        $ref->{ApiError}->{fieldPath}->{content} : "",
    trigger => $ref->{ApiError}->{trigger}->{content} ?
        $ref->{ApiError}->{trigger}->{content} : ""
  });
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::ReportUtils

=head1 SYNOPSIS

 use Google::Ads::Common::ReportUtils;

 Google::Ads::Common::ReportUtils::download_report($report_definition,
                                                   $client, $path);

=head1 DESCRIPTION

Google::Ads::Common::ReportUtils a collection of utility methods for working
with reports.

=head1 SUBROUTINES

=head2 download_report

Downloads a new instance of an existing report definition. If the file_path
parameter is specified it will be downloaded to the file at that path, otherwise
it will be downloaded to memory and be returned as a string.

=head3 Parameters

=over

=item *

The report_definition parameter is either:
  - the id of a pre-defined report to download
  - a C<ReportDefinition> object to be defined and download on the fly
  - a hash with an AWQL query and format. i.e. { query => 'query',
    format => 'format' }

In the case of a plain id then the regular download endpoint will be used to
download a pre-stored definition, otherwise the versioned download url endpoint
(based on the version of the given C<Client> object) will be used.

=item *

The client parameter is an instance of a valid L<Google::AdWords::Client>.

=item *

The file_path is an optional parameter that if given the subroutine will write
out the report to the given file path.

=item *

The server is an optional parameter that can be set to alter the URL from where
the report will be requested.

=item *

The return_money_in_micros is an optional parameter that can be set to alter
the output of money kind of fields in the report.

=item *

The timeout is an optional parameter that can be set to alter the default
time that the http client waits to get a response from the server. If not set,
the default timeout used is
L<Google::Ads::Common::ReportUtils::LWP_DEFAULT_TIMEOUT>.

=back

=head3 Returns

If a file_path is given, the report gets saved to file and the file size is
returned, if not the report data itself is returned.

=head3 Exceptions

Starting with v201209 of the API a L<Google::Ads::Common::ReportDownloadError>
object will be returned in case of a download error. If not passing a
C<file_path> to dump the report then you must check if the return
isa("Google::Ads::Common::ReportDownloadError").

Prior to v201209 a warn() will be issued if a report download error occurs.

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

=head1 AUTHOR

David Torres E<lt>api.davidtorres at gmail.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
