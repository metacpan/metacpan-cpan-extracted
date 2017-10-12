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
# This example illustrates how to create an account. By default, this account
# will only be visible via the parent AdWords manager account.

use strict;

use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::ManagedCustomer;
use Google::Ads::AdWords::v201710::ManagedCustomerOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub create_account {
  my $client = shift;

  # Create an account object with a currencyCode and a dateTimeZone
  # See https://developers.google.com/adwords/api/docs/appendix/currencycodes
  # and https://developers.google.com/adwords/api/docs/appendix/timezones
  my $account = Google::Ads::AdWords::v201710::ManagedCustomer->new({
      name         => "Managed Account #" . uniqid(),
      currencyCode => "USD",
      dateTimeZone => "America/New_York",
  });

  # Create the operation
  my $operation = Google::Ads::AdWords::v201710::ManagedCustomerOperation->new({
      operator => "ADD",
      operand  => $account
  });

  # Perform the operation. It is possible to create multiple accounts with one
  # request by sending multiple operations.
  my $response =
    $client->ManagedCustomerService->mutate({operations => [$operation],});

  if ($response) {
    my $new_account = $response->get_value();
    print "Account with customer ID ", $new_account->get_customerId(),
      " was created.\n";
  } else {
    print "No account was created.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
create_account($client);

