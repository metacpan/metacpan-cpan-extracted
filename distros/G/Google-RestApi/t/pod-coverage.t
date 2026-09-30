use strict;
use warnings;

use FindBin;
use File::Find;
use Test::More;

plan skip_all => 'Author test.  Set AUTHOR_TESTING=1 to run.'
  unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

# Methods common across many modules that are inherited, self-evident,
# or documented in a parent class.
my @common_private = qw(
  new api rest_api require_id
  transaction stats reset_stats
);

# Modules with large DSL-style method sets (Request builders, Range
# subclasses) that would be impractical to document individually.
# These are skipped entirely for now.
my %skip = map { $_ => 1 } qw(
  Google::RestApi::SheetsApi4::Request::Spreadsheet
  Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet
  Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range
  Google::RestApi::SheetsApi4::Range::All
  Google::RestApi::SheetsApi4::Range::Cell
  Google::RestApi::SheetsApi4::Range::Col
  Google::RestApi::SheetsApi4::Range::Row
  Google::RestApi::Types
  Google::RestApi::SheetsApi4::Types
  Google::RestApi::Utils
);

# Per-module trust lists for methods that don't need individual POD.
my %trustme = (
  'Google::RestApi' => [qw(reset_stats max_attempts)],
  'Google::RestApi::Auth' => [qw(params headers)],
  'Google::RestApi::Auth::OAuth2Client' => [qw(headers refresh_token userinfo oauth2_client oauth2_webserver authorize_url access_token)],
  'Google::RestApi::Auth::ServiceAccount' => [qw(access_token headers)],
  'Google::RestApi::DriveApi3::File' => [qw(file_id drive)],
  'Google::RestApi::SheetsApi4' => [qw(delete_all_spreadsheets spreadsheets_by_filter)],
  'Google::RestApi::SheetsApi4::Range' => [qw(
    factory append cell_at_offset cell_to_array range_at_offset
    header_name values_response_from_api clear_cached_values
  )],
  'Google::RestApi::SheetsApi4::RangeGroup' => [qw(
    requests_response_from_api refresh_values
    values_response_from_api clear_cached_values sheets_api
  )],
  'Google::RestApi::SheetsApi4::RangeGroup::Tie' => [qw(clear_cached_values)],
  'Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator' => [qw(next)],
  'Google::RestApi::SheetsApi4::Spreadsheet' => [qw(normalize_named)],
  'Google::RestApi::SheetsApi4::Worksheet' => [qw(
    header_row_enabled header_col_enabled resolve_header_range
    resolve_header_range_col resolve_header_range_row
    cells normalize_named worksheet_title range_factory
  )],
  'Google::RestApi::GmailApi1::Attachment' => [],
  'Google::RestApi::DocsApi1::Document' => [],
);

# Find all modules under lib/.
my @modules;
find(sub {
  return unless /\.pm$/;
  my $mod = $File::Find::name;
  $mod =~ s|^.*/lib/||;
  $mod =~ s|/|::|g;
  $mod =~ s|\.pm$||;
  push @modules, $mod;
}, "$FindBin::RealBin/../lib");

for my $mod (sort @modules) {
  SKIP: {
    skip "$mod has DSL-style methods, skipped", 1 if $skip{$mod};

    my @trust = @common_private;
    push @trust, @{ $trustme{$mod} } if $trustme{$mod};

    pod_coverage_ok($mod, { trustme => [map { qr/^\Q$_\E$/ } @trust] });
  }
}

done_testing();
