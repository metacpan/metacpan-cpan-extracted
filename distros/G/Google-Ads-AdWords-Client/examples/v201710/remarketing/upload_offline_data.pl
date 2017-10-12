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
# This code example shows how to upload offline data for store sales
# transactions.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::ConversionTrackerOperation;
use Google::Ads::AdWords::v201710::Money;
use Google::Ads::AdWords::v201710::MoneyWithCurrency;
use Google::Ads::AdWords::v201710::OfflineCallConversionFeed;
use Google::Ads::AdWords::v201710::OfflineCallConversionFeedOperation;
use Google::Ads::AdWords::v201710::OfflineData;
use Google::Ads::AdWords::v201710::OfflineDataUploadOperation;
use Google::Ads::AdWords::v201710::StoreSalesTransaction;
use Google::Ads::AdWords::v201710::UploadConversion;
use Google::Ads::AdWords::v201710::UserIdentifier;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);
use Digest::SHA qw(sha256_hex);

# Replace with valid values of your account.
# The external upload ID can be any number that you use to keep track of your
# uploads.
my $external_upload_id = 'INSERT_EXTERNAL_UPLOAD_ID';
# Insert the conversion type name that you'd like to attribute this upload to.
my $conversion_name = 'INSERT_CONVERSION_NAME';
# Insert email addresses below for creating user identifiers.
my @email_addresses = ['EMAIL_ADDRESS_1', 'EMAIL_ADDRESS_2'];

# Example main subroutine.
sub upload_offline_data {
  my ($client, $external_upload_id, $conversion_name, $email_addresses) = @_;

  # Create the first offline data for upload.
  # This transaction occurred 7 days ago with amount of 200 USD.
  my ($second, $minute, $hour, $mday, $mon, $year) =
    localtime(time - 60 * 60 * 24 * 7);
  my $transaction_time_1 = sprintf(
    "%d%02d%02d %02d%02d%02d",
    ($year + 1900),
    ($mon + 1),
    $mday, $hour, $minute, $second
  );
  my $transaction_amount_1        = 200000000;
  my $transaction_currency_code_1 = 'USD';
  my $user_identifier_list_1      = [
    _create_user_identifier('HASHED_EMAIL', $email_addresses->[0]),
    _create_user_identifier('STATE',        'New York')];

  my $offline_data_1 = _create_offline_data(
    $transaction_time_1,          $transaction_amount_1,
    $transaction_currency_code_1, $conversion_name,
    $user_identifier_list_1
  );

  # Create the second offline data for upload.
  # This transaction occurred 14 days ago with amount of 450 EUR.
  ($second, $minute, $hour, $mday, $mon, $year) =
    localtime(time - 60 * 60 * 24 * 14);
  my $transaction_time_2 = sprintf(
    "%d%02d%02d %02d%02d%02d",
    ($year + 1900),
    ($mon + 1),
    $mday, $hour, $minute, $second
  );
  my $transaction_amount_2        = 450000000;
  my $transaction_currency_code_2 = 'EUR';
  my $user_identifier_list_2      = [
    _create_user_identifier('HASHED_EMAIL', $email_addresses->[1]),
    _create_user_identifier('STATE',        'California')];

  my $offline_data_2 = _create_offline_data(
    $transaction_time_2,          $transaction_amount_2,
    $transaction_currency_code_2, $conversion_name,
    $user_identifier_list_2
  );

  # Create offline data upload object.
  my $offline_data_upload =
    Google::Ads::AdWords::v201710::OfflineDataUpload->new({
      externalUploadId => $external_upload_id,
      offlineDataList  => [$offline_data_1, $offline_data_2],
      # Optional: You can set the type of this upload.
      uploadType => 'STORE_SALES_UPLOAD_FIRST_PARTY'
    });

  # Create an offline data upload operation.
  my $offline_data_upload_operation =
    Google::Ads::AdWords::v201710::OfflineDataUploadOperation->new({
      operator => 'ADD',
      operand  => $offline_data_upload
    });

  # Upload offline data on the server and print some information.
  my $result =
    $client->OfflineDataUploadService()
    ->mutate({operations => [$offline_data_upload_operation]});
  $offline_data_upload = $result->get_value()->[0];

  printf(
    "Uploaded offline data with external upload ID %d and upload status" .
      " %s\n",
    $offline_data_upload->get_externalUploadId(),
    $offline_data_upload->get_uploadStatus());

  # Print any partial data errors from the response. The order of the partial
  # data errors list is the same as the uploaded offline data list in the
  # request.
  my $i = 0;
  for my $partial_data_error (@{$offline_data_upload->get_partialDataErrors()})
  {
    if ($partial_data_error) {
      printf("Found a partial error for offline data #%d with error " .
          "string: %s\n",
        $i, $partial_data_error->get_errorString());
    }
    $i++;
  }
  return 1;
}

# Creates the offline data from the specified transaction time, transaction
# micro amount, transaction currency, conversion name and user identifier
# list.
sub _create_offline_data {
  my (
    $transaction_time,     $transaction_micro_amount,
    $transaction_currency, $conversion_name,
    $user_identifier_list
  ) = @_;
  my $store_sales_transaction =
    Google::Ads::AdWords::v201710::StoreSalesTransaction->new({
      # For times use the format yyyyMMdd HHmmss [tz].
      # For details, see
      # https://developers.google.com/adwords/api/docs/appendix/codes-formats#date-and-time-formats
      transactionTime => $transaction_time,
      userIdentifiers => $user_identifier_list,
      transactionAmount =>
        Google::Ads::AdWords::v201710::MoneyWithCurrency->new({
          currencyCode => $transaction_currency,
          money        => Google::Ads::AdWords::v201710::Money->new(
            {microAmount => $transaction_micro_amount})})});
  # There is a temporary issue with the WSDL in which there is a
  # namespace conflict. As a workaround, the namespace is explicitly set here.
  $Google::Ads::AdWords::v201710::MoneyWithCurrency::OBJECT_NAMESPACE =
    "https://adwords.google.com/api/adwords/rm/v201710";

  my $offline_data = Google::Ads::AdWords::v201710::OfflineData->new({
    StoreSalesTransaction => $store_sales_transaction
  });
  return $offline_data;
}

# Creates a user identifier from the specified type and value.
sub _create_user_identifier {
  my ($type, $value) = @_;
  # If the user identifier type is a hashed type, also call hash function
  # on the value.
  if ($type =~ /^HASHED_/) {
    $value = sha256_hex($value);
  }

  my $user_identifier = Google::Ads::AdWords::v201710::UserIdentifier->new({
    userIdentifierType => $type,
    value              => $value
  });

  return $user_identifier;
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
upload_offline_data($client, $external_upload_id, $conversion_name,
  \@email_addresses);
