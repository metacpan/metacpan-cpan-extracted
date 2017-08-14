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

package Google::Ads::AdWords::Client;

use strict;
use version;
our $VERSION = qv("4.16.0");

use Google::Ads::AdWords::Constants;
use Google::Ads::AdWords::Deserializer;
use Google::Ads::AdWords::OAuth2ApplicationsHandler;
use Google::Ads::AdWords::OAuth2ServiceAccountsHandler;
use Google::Ads::AdWords::Reports::ReportingConfiguration;
use Google::Ads::AdWords::Serializer;
use Google::Ads::Common::HTTPTransport;
use Google::Ads::Common::Utilities::AdsUtilityRegistry;

use Class::Std::Fast;
use SOAP::WSDL qv("2.00.10");

use constant OAUTH_2_APPLICATIONS_HANDLER => "OAUTH_2_APPLICATIONS_HANDLER";
use constant OAUTH_2_SERVICE_ACCOUNTS_HANDLER =>
  "OAUTH_2_SERVICE_ACCOUNTS_HANDLER";
use constant AUTH_HANDLERS_ORDER =>
  (OAUTH_2_APPLICATIONS_HANDLER, OAUTH_2_SERVICE_ACCOUNTS_HANDLER);

# Class::Std-style attributes. Most values read from adwords.properties file.
# These need to go in the same line for older Perl interpreters to understand.
my %client_id_of : ATTR(:name<client_id> :default<>);
my %user_agent_of : ATTR(:name<user_agent> :default<>);
my %developer_token_of : ATTR(:name<developer_token> :default<>);
my %version_of : ATTR(:name<version> :default<>);
my %alternate_url_of : ATTR(:name<alternate_url> :default<>);
my %die_on_faults_of : ATTR(:name<die_on_faults> :default<0>);
my %validate_only_of : ATTR(:name<validate_only> :default<0>);
my %partial_failure_of : ATTR(:name<partial_failure> :default<0>);
my %reporting_config_of : ATTR(:name<reporting_config> :default<>);
my %include_utilities_of : ATTR(:name<include_utilities> :default<>);

my %properties_file_of : ATTR(:init_arg<properties_file> :default<>);
my %services_of : ATTR(:name<services> :default<{}>);
my %transport_of : ATTR(:name<transport> :default<>);
my %auth_handlers_of : ATTR(:name<auth_handlers> :default<>);
my %__enabled_auth_handler_of : ATTR(:name<__enabled_auth_handler> :default<>);

# Runtime statistics.
my %requests_count_of : ATTR(:name<requests_count> :default<0>);
my %failed_requests_count_of : ATTR(:name<failed_requests_count> :default<0>);
my %operations_count_of : ATTR(:name<operations_count> :default<0>);
my %last_request_stats_of : ATTR(:name<last_request_stats> :default<>);
my %last_soap_request_of : ATTR(:name<last_soap_request> :default<>);
my %last_soap_response_of : ATTR(:name<last_soap_response> :default<>);

# Static module-level variables.

# Automatically called by Class::Std after the values for all the attributes
# have been populated but before the constuctor returns the new object.
sub START {
  my ($self, $ident) = @_;

  my $default_properties_file =
    Google::Ads::AdWords::Constants::DEFAULT_PROPERTIES_FILE;
  if (not $properties_file_of{$ident} and -e $default_properties_file) {
    $properties_file_of{$ident} = $default_properties_file;
  }

  my %properties = ();
  if ($properties_file_of{$ident}) {

    # If there's a valid properties file to read from, parse it and use the
    # config values to fill in any missing attributes.
    %properties = __parse_properties_file($properties_file_of{$ident});
    $client_id_of{$ident} ||= $properties{clientId};
    $user_agent_of{$ident} ||= $properties{useragent} || $properties{userAgent};
    $developer_token_of{$ident} ||= $properties{developerToken};
    $version_of{$ident}         ||= $properties{version};
    $alternate_url_of{$ident}   ||= $properties{alternateUrl};
    $validate_only_of{$ident}   ||= $properties{validateOnly};
    $partial_failure_of{$ident} ||= $properties{partialFailure};
    $include_utilities_of{$ident} ||=
      $properties{"header.userAgent.includeUtilities"};

    # Construct the ReportingConfiguration.
    $reporting_config_of{$ident} ||=
      Google::Ads::AdWords::Reports::ReportingConfiguration->new({
        skip_header        => $properties{"reporting.skipHeader"},
        skip_column_header => $properties{"reporting.skipColumnHeader"},
        skip_summary       => $properties{"reporting.skipSummary"},
        include_zero_impressions =>
          $properties{"reporting.includeZeroImpressions"},
        use_raw_enum_values => $properties{"reporting.useRawEnumValues"}});

    # SSL Peer validation setup.
    $self->__setup_SSL($properties{CAPath}, $properties{CAFile});
  }

  # We want to provide default values for these  attributes if they weren't
  # set by parameters to new() or the properties file.
  $alternate_url_of{$ident} ||=
    Google::Ads::AdWords::Constants::DEFAULT_ALTERNATE_URL;
  $validate_only_of{$ident} ||=
    Google::Ads::AdWords::Constants::DEFAULT_VALIDATE_ONLY;
  $version_of{$ident} ||= Google::Ads::AdWords::Constants::DEFAULT_VERSION;
  $partial_failure_of{$ident} ||= 0;
  $reporting_config_of{$ident} ||=
    Google::Ads::AdWords::Reports::ReportingConfiguration->new();
  $include_utilities_of{$ident} = 1
    unless defined $include_utilities_of{$ident};

  # Setup of auth handlers
  my %auth_handlers = ();

  my $auth_handler = Google::Ads::AdWords::OAuth2ApplicationsHandler->new();
  $auth_handler->initialize($self, \%properties);
  $auth_handlers{OAUTH_2_APPLICATIONS_HANDLER} = $auth_handler;

  $auth_handler = Google::Ads::AdWords::OAuth2ServiceAccountsHandler->new();
  $auth_handler->initialize($self, \%properties);
  $auth_handlers{OAUTH_2_SERVICE_ACCOUNTS_HANDLER} = $auth_handler;

  $auth_handlers_of{$ident} = \%auth_handlers;

  # Setups the HTTP transport and OAuthHandler this client will use.
  $transport_of{$ident} = Google::Ads::Common::HTTPTransport->new();
  $transport_of{$ident}->client($self);
}

# Automatically called by Class::Std when an unknown method is invoked on an
# instance of this class. It is used to handle creating singletons (local to
# each Google::Ads::AdWords::Client instance) of all the SOAP services. The
# names of the services may change and shouldn't be hardcoded.
sub AUTOMETHOD {
  my ($self, $ident) = @_;
  my $method_name = $_;

  # All SOAP services should end in "Service"; fail early if the requested
  # method doesn't.
  if ($method_name =~ /^\w+Service$/) {
    if ($self->get_services()->{$method_name}) {

      # To emulate a singleton, return the existing instance of the service if
      # we already have it. The return value of AUTOMETHOD must be a sub
      # reference which is then invoked, so wrap the service in sub { }.
      return sub {
        return $self->get_services()->{$method_name};
      };
    } else {
      my $version = $self->get_version();

      # Check to see if there is a module with that name under
      # Google::Ads::AdWords::$version if not we warn and return nothing.
      my $module_name =
        "Google::Ads::AdWords::${version}::${method_name}" .
        "::${method_name}InterfacePort";
      eval("require $module_name");
      if ($@) {
        warn("Module $module_name was not found.");
        return;
      } else {

        # Generating the service endpoint url of the form
        # https://{server_url}/{group_name(cm/job/info/o)}/{version}/{service}.
        my $server_url =
          $self->get_alternate_url() =~ /\/$/
          ? substr($self->get_alternate_url(), 0, -1)
          : $self->get_alternate_url();
        my $service_to_group_name =
          $Google::Ads::AdWords::Constants::SERVICE_TO_GROUP{$method_name};
        if (!$service_to_group_name) {
          die("Service " . $method_name . " is not configured in the library.");
        }
        my $endpoint_url =
          sprintf(Google::Ads::AdWords::Constants::PROXY_FORMAT_STRING,
          $server_url, $service_to_group_name, $self->get_version(),
          $method_name);

        # If a suitable module is found, instantiate it and store it in
        # instance-specific storage to emulate a singleton.
        my $service_port = $module_name->new({

            # Setting the server endpoint of the service.
            proxy => [$endpoint_url],

            # Associating our custom serializer.
            serializer =>
              Google::Ads::AdWords::Serializer->new({client => $self}),

            # Associating our custom deserializer.
            deserializer =>
              Google::Ads::AdWords::Deserializer->new({client => $self})});

        # Injecting our own transport.
        $service_port->set_transport($self->get_transport());

        if ($ENV{HTTP_PROXY}) {
          $service_port->get_transport()->proxy(['http'], $ENV{HTTP_PROXY});
        }
        if ($ENV{HTTPS_PROXY}) {
          $service_port->get_transport()->proxy(['https'], $ENV{HTTPS_PROXY});
        }

        $self->get_services()->{$method_name} = $service_port;
        return sub {
          return $self->get_services()->{$method_name};
        };
      }
    }
  }
}

# Protected method to retrieve the proper enabled authorization handler.
sub _get_auth_handler {
  my $self = shift;

  # Check if we have cached the enabled auth_handler.
  if ($self->get___enabled_auth_handler()) {
    return $self->get___enabled_auth_handler();
  }

  my $auth_handlers = $self->get_auth_handlers();

  foreach my $handler_id (AUTH_HANDLERS_ORDER) {
    if ($auth_handlers->{$handler_id}->is_auth_enabled()) {
      $self->set___enabled_auth_handler($auth_handlers->{$handler_id});
      last;
    }
  }

  return $self->get___enabled_auth_handler();
}

# Private method to setup IO::Socket::SSL and Crypt::SSLeay variables
# for certificate and hostname validation.
sub __setup_SSL {
  my ($self, $ca_path, $ca_file) = @_;
  if ($ca_path || $ca_file) {
    $ENV{HTTPS_CA_DIR}  = $ca_path;
    $ENV{HTTPS_CA_FILE} = $ca_file;
    eval {
      require IO::Socket::SSL;
      require Net::SSLeay;
      IO::Socket::SSL::set_ctx_defaults(
        verify_mode         => Net::SSLeay->VERIFY_PEER(),
        SSL_verifycn_scheme => "www",
        ca_file             => $ca_file,
        ca_path             => $ca_path
      );
    };
  }
}

# Private method to parse values in a properties file.
sub __parse_properties_file {
  my ($properties_file) = @_;
  my %properties;

  # glob() to expand any metacharacters.
  ($properties_file) = glob($properties_file);

  if (open(PROP_FILE, $properties_file)) {

    # The data in the file should be in the following format:
    #   key1=value1
    #   key2=value2
    while (my $line = <PROP_FILE>) {
      chomp($line);

      # Skip comments.
      next if ($line =~ /^#/ || $line =~ /^\s*$/);
      my ($key, $value) = split(/=/, $line, 2);
      $properties{$key} = $value;
    }
    close(PROP_FILE);
  } else {
    die("Couldn't open properties file $properties_file for reading: $!\n");
  }
  return %properties;
}

# Protected method to generate the appropriate SOAP request header.
sub _get_header {
  my ($self) = @_;

  # A value of 1 (evaluating to true) occurs when a user explicitly defines 1
  # in the properties file or a user has ommitted the value from the properties
  # file. A value of 0 (evaluating to false) occurs when a user explicitly
  # defines 0 in the properties file.
  my $ads_utilities =
    ($self->get_include_utilities())
    ? sprintf(
    ", %s",
    Google::Ads::Common::Utilities::AdsUtilityRegistry
      ->get_and_reset_ads_utility_registry_string(
      ))
    : "";

  # Set the application name to the default if not provided.
  # Verify that it is ASCII.
  my $application_name =
        ($self->get_user_agent()
          && ($self->get_user_agent() ne "INSERT_USER_AGENT_HERE")
        ? $self->get_user_agent()
        : Google::Ads::AdWords::Constants::DEFAULT_USER_AGENT);
  if ($application_name =~ /[[:^ascii:]]/) {
    my $error_message = sprintf(
      "userAgent [%s] in client must be ASCII.", $application_name);
    if ($self->get_die_on_faults()) {
      die($error_message);
    } else {
      warn($error_message);
    }
  }

  # Always prepend the module identifier to the user agent.
  my $user_agent = sprintf(
    "%s (AwApi-Perl/%s, Common-Perl/%s, SOAP-WSDL/%s, " .
      "libwww-perl/%s, perl/%s%s)",
    $application_name,
    ${Google::Ads::AdWords::Constants::VERSION},
    ${Google::Ads::Common::Constants::VERSION},
    ${SOAP::WSDL::VERSION},
    ${LWP::UserAgent::VERSION},
    $],
    $ads_utilities
  );

  my $headers = {
    userAgent      => $user_agent,
    developerToken => $self->get_developer_token(),
    validateOnly   => $self->get_validate_only(),
    partialFailure => $self->get_partial_failure()};
  my $clientId = $self->get_client_id();

  # $clientId may not be set, in which case we're operating on the account
  # specified by the auth credentials.
  if ($clientId) {
    $headers->{clientCustomerId} = $clientId;
  }

  return $headers;
}

sub get_oauth_2_handler {
  my ($self) = @_;

  return $self->get_auth_handlers()->{OAUTH_2_APPLICATIONS_HANDLER};
}

sub get_oauth_2_applications_handler {
  my ($self) = @_;

  return $self->get_auth_handlers()->{OAUTH_2_APPLICATIONS_HANDLER};
}

sub get_oauth_2_service_accounts_handler {
  my ($self) = @_;

  return $self->get_auth_handlers()->{OAUTH_2_SERVICE_ACCOUNTS_HANDLER};
}

# Adds a new RequestStats object to the client and updates the aggregated
# stats. It also checks against the MAX_NUM_OF_REQUEST_STATS constant to
# not make the array of lastest stats grow infinitely.
sub _push_new_request_stats {
  my ($self, $request_stats) = @_;

  $self->set_last_request_stats($request_stats);
  $self->set_requests_count($self->get_requests_count() + 1);
  $request_stats->get_is_fault()
    and
    $self->set_failed_requests_count($self->get_failed_requests_count() + 1);
  $self->set_operations_count(
    $self->get_operations_count() + $request_stats->get_operations());
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Client

=head1 SYNOPSIS

  use Google::Ads::AdWords::Client;

  my $client = Google::Ads::AdWords::Client->new();

  my $adGroupId = "12345678";

  my $adgroupad_selector =
      Google::Ads::AdWords::v201702::Types::AdGroupAdSelector->new({
        adGroupIds => [$adGroupId]
      });

  my $page =
      $client->AdGroupAdService()->get({selector => $adgroupad_selector});

  if ($page->get_totalNumEntries() > 0) {
    foreach my $entry (@{$page->get_entries()}) {
      #Do something with the results
    }
  } else {
    print "No AdGroupAds found.\n";
  }

=head1 DESCRIPTION

Google::Ads::AdWords::Client is the main interface to the AdWords API. It takes
care of handling your API credentials, and exposes all of the underlying
services that make up the AdWords API.

Due to internal patching of the C<SOAP::WSDL> module, the
C<Google::Ads::AdWords::Client> module should be loaded before other
C<Google::Ads::> modules. A warning will occur if modules are loaded in the
wrong order.

=head1 ATTRIBUTES

Each of these attributes can be set via Google::Ads::AdWords::Client->new().
Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically. For example, the set_client_id()
allows you to change the value of the client_id attribute and get_client_id()
returns the current value of the attribute.

=head2 client_id

An optional 10 digit client id (with or without dashes) to specify the AdWords
account to act upon.

=head2 user_agent

A user-generated string used to identify your application. If nothing is
specified, "unknown" will be used instead.

=head2 developer_token

A string used to tie usage of the AdWords API to a specific AdWords manager
account.

The value should be a character string assigned to you by Google. You can
apply for a Developer Token by following the instructions at

https://developers.google.com/adwords/api/docs/signingup

=head2 version

The version of the AdWords API to use. Currently C<v201702> is the default
version.

=head2 alternate_url

The URL of an alternate AdWords API server to use.

The default value is C<https://adwords.google.com>

=head2 validate_only

If is set to "true" calls to services will only perform validation, the results
will be either empty response or a SOAP fault with the API error causing the
fault.

The default is "false".

=head2 partial_failure

If true, API will try to commit as many error free operations as possible and
report the other operations' errors. This flag is currently only supported by
the AdGroupCriterionService.

The default is "false".

=head2 reporting_config

The reporting configuration that controls additional options such as excluding
the report header or summary row. Only supported starting with
L<Google::Ads::AdWords::Reports::ReportingConfiguration:MIN_REPORT_CONFIGURATION_VERSION>.

=head2 die_on_faults

By default the client returns a L<SOAP::WSDL::SOAP::Typelib::Fault11> object
if an error has ocurred at the server side, however if this flag is set to true,
then the client will issue a die command on received SOAP faults.

The default is "false".

=head2 requests_count

Number of requests performed with this client so far.

=head2 failed_requests_count

Number of failed requests performed with this client so far.

=head2 operations_count

Number of operations made with this client so far.

=head2 requests_stats

An array of L<Google::Ads::AdWords::RequestStats> containing the statistics of
the last L<Google::Ads::AdWords::Constants:MAX_NUM_OF_REQUEST_STATS> requests.

=head2 last_request_stats

A L<Google::Ads::AdWords::RequestStats> containing the statistics the last
request performed by this client.

=head2 last_soap_request

A string containing the last SOAP request XML sent by this client.

=head2 last_soap_response

A string containing the last SOAP response XML sent by this client.

=head1 METHODS

=head2 new

Initializes a new Google::Ads::AdWords::Client object.

=head3 Parameters

new() takes parameters as a hash reference.
The attributes of this object can be populated in a number of ways:

=over

=item *

If the properties_file parameter is given, then properties are read from the
file at that path and the corresponding attributes are populated.

=item *

If no properties_file parameter is given, then the code checks to see if there
is a file named "adwords.properties" in the home directory of the current user.
If there is, then properties are read from there.

=item *

Any of the L</ATTRIBUTES> can be passed in as keys in the parameters hash
reference. If any attribute is explicitly passed in then it will override any
value for that attribute that might be in a properties file.

=back

=head3 Returns

A new Google::Ads::AdWords::Client object with the appropriate attributes set.

=head3 Exceptions

If a properties_file is passed in but the file cannot be read, the code will
die() with an error message describing the failure.

=head3 Example

 # Basic use case. Attributes will be read from ~/adwords.properties file.
 my $client = Google::Ads::AdWords::Client->new();

 # Most attributes from a custom properties file, but override client_id.
 eval {
   my $client = Google::Ads::AdWords::Client->new({
     properties_file => "/path/to/adwords.properties",
     client_id => "123-456-7890",
   });
 };
 if ($@) {
   # The properties file couldn't be read; handle error as appropriate.
 }

 # Specify all attributes explicitly. The properties file will not override.
 my $client = Google::Ads::AdWords::Client->new({
   client_id => "123-456-7890",
   developer_token => "123xyzabc...",
   user_agent => "My Sample Program",
 });
 $client->get_oauth_2_applications_handler()->set_refresh_token('1/Abc...');

=head2 set_die_on_faults

This module supports two approaches to handling SOAP faults (i.e. errors
returned by the underlying SOAP service).

One approach is to issue a die() with a description of the error when a SOAP
fault occurs. This die() would ideally be contained within an eval { }; block,
thereby emulating try { } / catch { } exception functionality in other
languages.

A different approach is to require developers to explicitly check for SOAP
faults being returned after each AdWords API method. This approach requires a
bit more work, but has the advantage of exposing the full details of the SOAP
fault, like the fault code.

Refer to the object L<SOAP::WSDL::SOAP::Typelib::Fault11> for more detail on
how faults get returned.

The default value is false, i.e. you must explicitly check for faults.

=head3 Parameters

A true value will cause this module to die() when a SOAP fault occurs.

A false value will supress this die(). This is the default behavior.

=head3 Returns

The input parameter is returned.

=head3 Example

 # $client is a Google::Ads::AdWords::Client object.

 # Enable die()ing on faults.
 $client->set_die_on_faults(1);
 eval {
   my $response = $client->AdGroupAdService->mutate($mutate_params);
 };
 if ($@) {
   # Do something with the error information in $@.
 }

 # Default behavior.
 $client->set_die_on_faults(0);
 my $response = $client->AdGroupAdService->mutate($mutate_params);
 if ($response->isa("SOAP::WSDL::SOAP::Typelib::Fault11")) {
   my $code = $response->get_faultcode() || '';
   my $description = $response->get_faultstring() || '';
   my $actor = $response->get_faultactor() || '';
   my $detail = $response->get_faultdetail() || '';

   # Do something with this error information.
 }

=head2 get_die_on_faults

=head3 Returns

A true or false value indicating whether the Google::Ads::AdWords::Client
instance is set to die() on SOAP faults.

=head2 {ServiceName}

The client object contains a method for every service provided by the API.
So for example it can invoked as $client->AdGroupService() and it will return
an object of type
L<Google::Ads::AdWords::v201702::AdGroupService::AdGroupServiceInterfacePort>
when using version v201702 of the API.
For a list of all available services please refer to
http://developers.google.com/adwords/api/docs and for examples on
how to invoke the services please refer to scripts in the examples folder.

=head2 get_oauth_2_applications_handler

Returns the OAuth2 for Web/Installed applications authorization handler
attached to the client, for programmatically setting/overriding its properties.

$client->get_oauth_2_applications_handler()->set_client_id('client-id');
$client->get_oauth_2_applications_handler()->set_client_secret('client-secret');
$client->get_oauth_2_applications_handler()->set_access_token('access-token');
$client->get_oauth_2_applications_handler()->set_refresh_token('refresh-token');
$client->get_oauth_2_applications_handler()->set_access_type('access-type');
$client->get_oauth_2_applications_handler()->set_prompt('prompt');
$client->get_oauth_2_applications_handler()->set_redirect_uri('redirect-url');

Refer to L<Google::Ads::AdWords::OAuth2ApplicationsHandler> for more details.

=head2 get_oauth_2_service_accounts_handler

Returns the OAuth2 authorization handler attached to the client, for
programmatically setting/overriding its specific properties.

$client->get_oauth_2_service_accounts_handler()->set_client_id('email');
$client->get_oauth_2_service_accounts_handler()->set_email_address('email');
$client->get_oauth_2_service_accounts_handler()->
    set_delegated_email_address('delegated-email');
$client->get_oauth_2_service_accounts_handler()->
    set_pem_file('path-to-certificate');
$client->get_oauth_2_service_accounts_handler()->set_display_name('email');

Refer to L<Google::Ads::AdWords::OAuth2ApplicationsHandler> for more details.

=head2 __setup_SSL (Private)

Setups IO::Socket::SSL and Crypt::SSLeay environment variables to work with
SSL certificate validation.

=head3 Parameters

The path to the certificate authorites folder and the path to the certificate
authorites file. Either can be null.

=head3 Returns

Nothing.

=head2 __parse_properties_file (Private)

=head3 Parameters

The path to a properties file on disk. The data in the file should be in the
following format:

 key1=value1
 key2=value2

=head3 Returns

A hash corresponding to the keys and values in the properties file.

=head3 Exceptions

die()s with an error message if the properties file could not be read.

=head2 _get_header (Protected)

Used by the L<Google::Ads::AdWords::Serializer> class to get a valid request
header corresponding to the current credentials in this
Google::Ads::AdWords::Client instance.

=head3 Returns

A hash reference with credentials corresponding to the values needed to be
included in the request header.

=head2 _auth_handler (Protected)

Retrieves the active AuthHandler. All handlers are checked in the order
OAuth2 Applications -> OAuth2 Service Accounts.

=head3 Returns

An implementation of L<Google::Ads::Common::AuthHandlerInterface>.

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
