#!/usr/bin/perl -w
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
# This example demonstrates how to use hashes instead of objects to do a request
# to the API. In general hashes can be used to call and read data from any
# of the API services.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Example main subroutine.
sub use_hashes {
  my $client = shift;

  # Get all campaigns.
  my $paging = {
    startIndex    => 0,
    numberResults => PAGE_SIZE
  };

  # Paginate through results.
  my $page;
  my $start_index = 0;
  do {
    my $paging = {
      startIndex    => $start_index,
      numberResults => PAGE_SIZE
    };
    # Get a page of campaigns.
    $page = $client->CampaignService()->get({
        serviceSelector => {
          fields     => ["Id", "Name"],
          predicates => [{
              field    => "Status",
              operator => "IN",
              values   => ["ENABLED"]
            }
          ],
          ordering => {
            field     => "Id",
            sortOrder => "ASCENDING"
          },
          paging => $paging
        }
      }
    );

    # Display campaigns.
    if ($page->{entries}) {
      foreach my $campaign (@{$page->{entries}}) {
        printf "Campaign with name \"%s\" and id \"%d\" was found.\n",
          $campaign->{name}, $campaign->{id};
      }
    }
    $start_index = $start_index + PAGE_SIZE;
  } while ($start_index < $page->{totalNumEntries});

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201607"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
use_hashes($client);
