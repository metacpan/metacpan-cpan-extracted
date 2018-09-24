#!/usr/bin/perl -w
#
# Copyright 2017, Google Inc. All Rights Reserved.
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
# This example illustrates how to retrieve all languages and carriers available
# for targeting.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_targetable_languages_and_carriers {
  my $client = shift;

  # Get all languages from ConstantDataService.
  my $languages = $client->ConstantDataService()->getLanguageCriterion();
  if ($languages) {
    foreach my $language (@{$languages}) {
      printf "Language name is '%s', ID is %d and code is '%s'.\n",
        $language->get_name(), $language->get_id(),
        $language->get_code();
    }
  }

  # Get all carriers from ConstantDataService.
  my $carriers = $client->ConstantDataService()->getCarrierCriterion();
  if ($carriers) {
    foreach my $carrier (@{$carriers}) {
      printf "Carrier name is '%s', ID is %d and country code is '%s'.\n",
        $carrier->get_name(), $carrier->get_id(),
        $carrier->get_countryCode();
    }
  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_targetable_languages_and_carriers($client);
