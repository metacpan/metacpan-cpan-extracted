#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use lib "$FindBin::RealBin/../../../../../lib";

use Test::Most tests => 34;
use YAML::Any qw(Dump);

use Utils;
Utils::init_logger();

my $spreadsheet = Utils::spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

clear();
named();
formulas();
requests();

sub clear {
  my $range = $worksheet->range("A1:Z99");
  lives_ok sub { $range->clear(); }, "Clearing a range should live";
  return;
}

sub named {
  my @values = (
    [ 1, 2, 3 ],
    [ 4, 5, 6 ],
  );
  my $range = $worksheet->range("B3:D5");

  lives_ok sub { $range->add_named(name => "xxx")->submit_requests(); }, "Adding named range should live";
  throws_ok sub { $range->add_named(name => "xxx")->submit_requests(); },
    qr/a named range with that name already exists/, "Creating same named range should fail";

  lives_ok sub { $range = $worksheet->range("xxx"); }, "Using named range should live";
  lives_ok sub { $range->values(values => \@values); }, "Setting named range values should live";
  is_deeply $worksheet->range("B3:D5")->values(), \@values, "Values should be set in named range properly";

  lives_ok sub { $range = $worksheet->range_col("xxx"); }, "Adding named range as a col should live";
  throws_ok sub { $range->range(); }, qr/Unable to translate/, "Using a non-col named range should die";

  lives_ok sub { $range = $worksheet->range_row("xxx"); }, "Adding named range as a row should live";
  throws_ok sub { $range->range(); }, qr/Unable to translate/, "Using a non-row named range should die";

  lives_ok sub { $range = $worksheet->range_cell("xxx"); }, "Adding named range as a cell should live";
  throws_ok sub { $range->range(); }, qr/Unable to translate/, "Using a non-cell named range should die";

  my $col = "A1:A10";
  $range = $worksheet->range($col);
  lives_ok sub { $range->add_named(name => "col")->submit_requests(); }, "Adding col named range should live";
  lives_ok sub { $range = $worksheet->range_col("col"); }, "Creating col named range as a col should live";
  $spreadsheet->cache(5);
  like $worksheet->range("col")->range(), qr/$col$/, "Normalized range should be $col";

  my $row = "A1:J10";
  $range = $worksheet->range($row);
  lives_ok sub { $range->add_named(name => "row")->submit_requests(); }, "Adding row named range should live";
  lives_ok sub { $range = $worksheet->range_row("row"); }, "Creating row named range as a row should live";
  $spreadsheet->cache(5);
  like $worksheet->range("row")->range(), qr/$row$/, "Normalized range should be $row";

  my $named = $spreadsheet->range_group(
    map { $worksheet->range($_); } qw(xxx row col)
  );
  lives_ok sub { $named->delete_named()->submit_requests(); }, "Delete of named ranges should live";

  return;
}

sub formulas {
  my $sum = '=SUM(A1:B1)';
  my @values = (
    [ 1, 1, $sum ],
  );
  my $range = $worksheet->range("A1:C1");
  $range->values(values => \@values);

  is $worksheet->range_cell('C1')->values(), 2, "Returned formula value should be 2";
  is $worksheet->range_cell('C1')->values(
    params => {
      valueRenderOption => 'FORMULA',
    }
  ), $sum, "Returned formula value should be '$sum'";

  lives_ok sub {
    $range->values(
      values => \@values,
      params => {
        includeValuesInResponse => 'true',
      },
    );
  }, "Returning values in response should live";
  is $range->values()->[0]->[2], 2, "Returned formula value should be 2";

  lives_ok sub {
    $range->values(
      values => \@values,
      params => {
        includeValuesInResponse   => 'true',
        responseValueRenderOption => 'FORMULA',
      },
    );
  }, "Returning values in response should live";
  is $range->values()->[0]->[2], $sum, "Returned formula value should be '$sum'";

  lives_ok sub {
    $range->batch_values(values => \@values)->submit_values(
      content => {
        includeValuesInResponse   => 'true',
      },
    );
  }, "Returning batch values in response should live";
  is $range->values()->[0]->[2], 2, "Returned batch formula value should be 2";

  lives_ok sub {
    $range->batch_values(values => \@values)->submit_values(
      content => {
        includeValuesInResponse   => 'true',
        responseValueRenderOption => 'FORMULA',
      },
    );
  }, "Returning batch values in response should live";
  is $range->values()->[0]->[2], $sum, "Returned batch formula value should be '$sum'";

  return;
}

sub requests {
  my $range = $worksheet->range("A1:B2");
  lives_ok sub { $range->bold()->bold(0)->red()->merge_both(); }, "Range format batch should succeed";
  lives_ok sub { $range->submit_requests(); }, "Submitting batch requests should succeed";

  my $requests_response;
  lives_ok sub { $requests_response = $range->requests_response(); }, "Obtaining the request response should suceed";
  is ref($requests_response), 'ARRAY', "Requests response should return an array";
  is scalar @$requests_response, 2, "There should be two responses in the response array";
}

Utils::delete_all_spreadsheets($spreadsheet->sheets());
