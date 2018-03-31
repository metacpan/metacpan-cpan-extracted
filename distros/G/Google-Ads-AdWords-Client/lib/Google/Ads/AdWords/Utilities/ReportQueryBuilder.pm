# Copyright 2018, Google Inc. All Rights Reserved.
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
# A query builder for building AWQL queries for reporting.

package Google::Ads::AdWords::Utilities::ReportQueryBuilder;

use strict;
use warnings;
use utf8;
use version;
use base qw(Google::Ads::AdWords::Utilities::QueryBuilder);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};
use Google::Ads::Common::Utilities::AdsUtilityRegistry;

use Class::Std::Fast;

my %select_of : ATTR(:name<select> :default<[]>);
my %from_report_of : ATTR(:name<from_report> :default<>);
my %date_range_of : ATTR(:name<date_range> :default<>);
my %start_date_of : ATTR(:name<start_date> :default<>);
my %end_date_of : ATTR(:name<end_date> :default<>);

sub START {
  my ($self) = @_;

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
    "ReportQueryBuilder");

  # If a query builder was specified, then make a copy.
  if ($self->get_query_builder()) {
    push(@{$self->get_select()}, @{$self->get_query_builder()->get_select()});
    $self->set_from_report($self->get_query_builder()->get_from_report());
    $self->set_date_range($self->get_query_builder()->get_date_range());
    $self->set_start_date($self->get_query_builder()->get_start_date());
    $self->set_end_date($self->get_query_builder()->get_end_date());
  }

  return $self;
}

# Adds a provided list of fields as selected fields for the query. Each call to
# this method will replace the list of fields from previous calls.
# Args:
#   fields: The specified list of fields to be added to a SELECT clause.
# Returns: This report query builder.
sub select {
  my ($self, $fields) = @_;
  @{$self->get_select()} = ();
  push(@{$self->get_select()}, @$fields);
  return $self;
}

# Sets a provided report name as the argument to the FROM clause.
# A list of report names can be found at:
# https://developers.google.com/adwords/api/docs/appendix/reports
# Args:
#   report_name: The specified report name.
# Returns: This report query builder.
sub from {
  my ($self, $report_name) = @_;
  $self->set_from_report($report_name);
  return $self;
}

# Sets arguments for the DURING clause using the provided date range or start
# and end dates. Only the date range or start and end date should be
# specified. If both are supplied, an error will be thrown. A valid date range
# string can be found at
# https://developers.google.com/adwords/api/docs/guides/reporting#date_ranges.
# Start and end dates should be in 'YYYYMMDD' format.
# Args:
#   date_range_or_start_date: The specified date range string, e.g. YESTERDAY
#   or the start date in 'YYYYMMDD' format when the end date is specified.
#   end_date: The end date string in 'YYYYMMDD' format.
# Returns: This report query builder.
sub during {
  my ($self, $date_range_or_start_date, $end_date) = @_;

  if (!$date_range_or_start_date) {
    $self->_log_error("Pass in either 1 argument with a date range as a " .
      "string e.g. YESTERDAY or pass in 2 arguments with a start date and an " .
      "end date with the format 'YYYYMMDD'");
  }

  # If the first argument is a number, then it must be a start date. Therefore,
  # an end date must be specified.
  if ($date_range_or_start_date =~ /^\d+$/) {
    if (!$end_date or !($end_date =~ /^\d+$/)) {
      $self->_log_error("Pass in 2 arguments with a start date and an " .
      "end date with the format 'YYYYMMDD'");
    }
    $self->set_start_date($date_range_or_start_date);
    $self->set_end_date($end_date);
  }
  else {
    $self->set_date_range($date_range_or_start_date);
  }
  return $self;
}

# Builds an AWQL query.
# Returns: The AWQL string.
sub build {
  my ($self) = @_;
  if (!$self->get_select() or (scalar @{$self->get_select()} eq 0)) {
    $self->_log_error(
      "Must use select() to specify SELECT clause for valid AWQL first.");
  }
  if (!$self->get_from_report()) {
    $self->_log_error(
      "Must use from() to specify FROM clause for valid AWQL first.");
  }
  my $awql .= sprintf('SELECT %s', join(", ", @{$self->get_select()}));
  $awql .= sprintf(' FROM %s', $self->get_from_report());
  my @where_builder_strings = ();
  foreach my $where_builder (@{$self->get_where_builders()}) {
    push(@where_builder_strings, ($where_builder->build()));
  }
  $awql .=
    (scalar @where_builder_strings > 0)
    ? sprintf(' WHERE %s', join(" AND ", @where_builder_strings))
    : '';
  $awql .=
    ($self->get_date_range())
    ? sprintf(' DURING %s', $self->get_date_range())
    : '';
  $awql .=
    ($self->get_start_date() and $self->get_end_date())
    ? sprintf(' DURING %s,%s', $self->get_start_date(), $self->get_end_date())
    : '';
  return $awql;
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::ReportQueryBuilder

=head1 DESCRIPTION

A query builder for building AWQL queries for reporting.

=head1 ATTRIBUTES

The attributes may be set in new() and accessed using get_ATTRIBUTE
methods:

=head2 select

An array of fields that are selected to be filtered on.

=head2 from_report

The name of the report queried.

=head2 date_range_or_start_date

The date range string in the during clause or the start date in the during
clause when the end_date is specified.

=head2 end_date

The end date of the date range in the during clause.

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::Utilities::ReportQueryBuilder
   client # Required: Google::Ads::AdWords::Client
   query_builder # Optional: the Google::Ads::AdWords::Utilities::QueryBuilder
   # to be copied
 },

=head1 METHODS

=head2 select

Adds the specified list of fields to be added to a SELECT clause.

=head3 Parameters

=over

=item *

A reference to an array of fields selected.

=back

=head3 Returns

A query builder (this instance).

=head2 from

Set the report name to be queried.

=head3 Parameters

=over

=item *

A name of a report.

=back

=head3 Returns

A query builder (this instance).

=head2 during

Sets the values of the DURING clause. If this subroutine is called, either
the first argument is undef or the second and third arguments are undef.

=head3 Parameters

=over

=item *

The specified date range string, e.g., YESTERDAY or when an end date
is specified, this is the start date string in 'YYYYMMDD' format.

=item *

The end date string in 'YYYYMMDD' format.

=back

=head3 Returns

A query builder (this instance).

=head2 build

Builds the AWQL query.

=head3 Returns

A string that is the AWQL query.

=cut
