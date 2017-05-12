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
# Unit tests for the Google::Ads::Common::Utilities::AdsUtilityRegistry
# module.

use strict;
use lib qw(lib t t/util);

use File::Temp qw(tempfile);
use Test::Exception;
use Test::MockObject::Extends;
use Test::More (tests => 10);

use_ok("Google::Ads::Common::Utilities::AdsUtilityRegistry");

is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled", "utility registry should contain only Logging/Disabled"
);

Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  "ReportDownloaderFile");

is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled, ReportDownloader/file",
  "utility registry string should have ReportDownloader/file"
);

is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled",
  "utility registry string should be ', Logging/Disabled'"
);

Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  "ReportDownloaderStream");

Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  "ReportDownloaderString");

Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  "ReportDownloaderFile");

Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  "ReportDownloaderFile");

is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled, ReportDownloader/file, ReportDownloader/stream, " .
    "ReportDownloader/string",
  "registry should contain 4 items in alphabetial order"
);

is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled", "utility registry should contain only Logging/Disabled"
);

Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
  "ReportDownloaderStream", "ReportDownloaderString");

is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled, ReportDownloader/stream, ReportDownloader/string",
  "registry should contain 3 items in alphabetial order"
);

Google::Ads::AdWords::Logging::enable_all_logging();
is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Enabled", "utility registry should contain only Logging/Enabled"
);

Google::Ads::AdWords::Logging::disable_all_logging();
is(
  Google::Ads::Common::Utilities::AdsUtilityRegistry
    ->get_and_reset_ads_utility_registry_string,
  "Logging/Disabled", "utility registry should contain only Logging/Disabled"
);

dies_ok {
  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
    "BadUtility");
}
"expected to die";
