# Copyright 2014, Google Inc. All Rights Reserved.
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

package Google::Ads::AdWords::Reports::ReportingConfiguration;

use strict;
use warnings;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Class::Std::Fast;

my %skip_header_of : ATTR(:name<skip_header> :default<>);
my %skip_column_header_of : ATTR(:name<skip_column_header> :default<>);
my %skip_summary_of : ATTR(:name<skip_summary> :default<>);
my %include_zero_impressions_of :
  ATTR(:name<include_zero_impressions> :default<>);
my %use_raw_enum_values_of : ATTR(:name<use_raw_enum_values> :default<>);

sub as_string : STRINGIFY {
  my ($self, $ident) = @_;
  return sprintf(
    "ReportingConfiguration {\n  skip_header: %s\n" .
      "  skip_column_header: %s\n" . "  skip_summary: %s\n" .
      "  include_zero_impressions: %s\n use raw enum values: %s\n}",
    $self->get_skip_header()              || "<undef>",
    $self->get_skip_column_header()       || "<undef>",
    $self->get_skip_summary()             || "<undef>",
    $self->get_include_zero_impressions() || "<undef>",
    $self->get_use_raw_enum_values()      || "<undef>"
  );
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Reports::ReportingConfiguration

=head1 DESCRIPTION

Represents additional reporting configuration options.


=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * skip_header

Set this to true to request that report output excludes the report header
row containing the report name and date range.

=item * skip_column_header

Set this to true to request that the report output excludes the row
containing column names.

=item * skip_summary

Set this to true to request that report output excludes the report summary
row containing totals.

=item * include_zero_impressions

Set this to true to request that report output includes data with zero
impressions.

=item * use_raw_enum_values

Set this to true to request that report output return enum field values as
enum values instead of display values.

=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::Reports::ReportingConfiguration
   skip_header =>  $some_value, # boolean
   skip_column_header => $some_value, #boolean
   skip_summary =>  $some_value, # boolean
   include_zero_impressions => $some_value, # boolean
   use_raw_enum_values => $some_value, # boolean
 },

=cut

