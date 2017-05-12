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
# Description: This is a global object that maintains a registry of the
# utilities that have recently been used. This registry of utilities is
# primarily collected to be put in the userAgent of the header when a
# request is sent. The registry is cleared every time the string representation
# of the registry is retrieved.

package Google::Ads::Common::Utilities::AdsUtilityRegistry;

use strict;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};
use Google::Ads::AdWords::Logging;

use Class::Std::Fast;
use Log::Log4perl qw(:levels);

# The Mapping of utility class names to a generic name used by all the client
# libraries. This string will be passed into the user agent.
our %ADS_UTILITIES = (
  BatchJobHandler        => "BatchJobHelper",
  LoggingEnabled         => "Logging/Enabled",
  LoggingDisabled        => "Logging/Disabled",
  PageProcessor          => "PageProcessor",
  ReportDownloaderFile   => "ReportDownloader/file",
  ReportDownloaderStream => "ReportDownloader/stream",
  ReportDownloaderString => "ReportDownloader/string",
);

{
  # This is a globally static variable.
  my %ads_utility_registry = ();

  # Add one or more utilities to the utility registry.
  # Example:
  # Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  #   "ReportDownloaderStream");
  sub add_ads_utilities {
    my ($class, @params) = @_;
    # Verify that the value passed is a key in %ADS_UTILITIES. Don't continue
    # if the value passed in is incorrect. Avoid duplicates with a hash.
    foreach my $param (@params) {
      if (exists $ADS_UTILITIES{$param}) {
        $ads_utility_registry{$ADS_UTILITIES{$param}} = $ADS_UTILITIES{$param};
      } else {
        die sprintf("Parameter incorrect: %s\nChoose from values(s): %s",
          $param, join(", ", (keys %ADS_UTILITIES)));
      }
    }
  }

  # Get the list of non-repeated utilities sorted in alphabetical order.
  sub __get_ads_utilities {
    return sort (keys %ads_utility_registry);
  }

  # Reset the registry of ads utilities.
  sub __reset_ads_utilities {
    %ads_utility_registry = ();
  }

  # This method returns an alphabetical, comma-separated string of non-repeated
  # ads utilities currently registered.
  # This method also clears the utility registry.
  sub get_and_reset_ads_utility_registry_string {
    # Update the logging status.
    my $log_utility =
      (   !Google::Ads::AdWords::Logging::get_awapi_logger()->level()
        || Google::Ads::AdWords::Logging::get_awapi_logger()->level() == $OFF)
      ? "LoggingDisabled"
      : "LoggingEnabled";
    Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
      $log_utility);

    # Retrieve the list and reset the utilities registry.
    my @utilities = __get_ads_utilities();
    __reset_ads_utilities();
    return join(", ", @utilities);
  }
}

1;

=pod

=head1 NAME

Google::Ads::Common::Utilities::AdsUtilityRegsitry

=head1 DESCRIPTION

This is a global object that maintains a registry of the utilities that have
recently been used. This registry of utilities is primarily collected to be put
in the userAgent of the header when a request is sent. The registry is cleared
every time the string representation of the registry is retrieved.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY methods:

=back

=head1 METHODS

=head2 add_ads_utilities

Add one or more utilities to the utility registry. The possible values passed
in are in the keys of
Google::Ads::Common::Utilities::AdsUtilityRegistry::ADS_UTILITIES. The method
will error if one of the values passed in is incorrect.
Example:
Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
   "ReportDownloaderStream");

=head3 Parameters

=over

=item *

One or more strings representing ad utilities. These strings can be found in
the keys of Google::Ads::Common::Utilities::AdsUtilityRegistry::ADS_UTILITIES.

= back

=head2 __get_ads_utilities

(Private) This method returns the list of non-repeated ads utilities in
alphabetical order. Possible values can be found in the values of
Google::Ads::Common::Utilities::AdsUtilityRegistry::ADS_UTILITIES.

=head3 Returns

An array of non-repeated utilities that have been added via add_ads_utilities in
alphabetic order. Possible values can be found in the values of
Google::Ads::Common::Utilities::AdsUtilityRegistry::ADS_UTILITIES.

=head2 __reset_ads_utilities

(Private) This method clears the registry of ads utilities.

=head2 get_and_reset_ads_utility_registry_string

This method returns an alphabetical, comma-separated string of non-repeated ads
utilities currently registered.
This method also clears the registry of ads utilities.

=head3 Returns

Returns an alphabetical, comma-separated string of non-repeated ads utilities
currently registered.

=cut
