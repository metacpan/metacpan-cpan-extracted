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
# This utility is a query builder for building AWQL (AdWords Query Language)
# queries. This module shouldn't be instantiated directly or extended.
# Use ReportQueryBuilder if you want to create a query for reporting or
# ServiceQueryBuilder if you want to create a query for services.

package Google::Ads::AdWords::Utilities::QueryBuilder;

use strict;
use warnings;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Class::Std::Fast;

my %client_of : ATTR(:name<client> :default<>);
my %die_on_faults_of : ATTR(:name<die_on_faults> :default<1>);
my %query_builder_of : ATTR(:name<query_builder> :default<>);
my %where_builders_of : ATTR(:name<where_builders> :default<[]>);

sub START {
  my ($self) = @_;

  $self->set_die_on_faults((
      defined($self->get_client()) and $self->get_client()->get_die_on_faults()
    ) ? 1 : 0
  );

  if ($self->get_query_builder()) {
    push(
      $self->get_where_builders(),
      @{$self->get_query_builder()->get_where_builders()});
  }
  return $self;
}

# The specified list of fields to be added to a SELECT clause.
# Returns a query builder.
sub select {
  my ($self, $fields) = @_;
  $self->_log_error(
    "Not implemented: Use ReportQueryBuilder or ServiceQueryBuilder.");
}

# Creates a WHERE builder using a provided field.
# The created WHERE builder.
sub where {
  my ($self, $field) = @_;

  my $where_builder =
    Google::Ads::AdWords::Utilities::QueryBuilder::WhereBuilder->new({
      field                 => $field,
      current_query_builder => $self
    });
  push($self->get_where_builders(), $where_builder);
  return $where_builder;
}

# Log the error based on the configuration for die on faults.
sub _log_error {
  my ($self, $error) = @_;
  if ($self->get_die_on_faults()) {
    die($error);
  } else {
    warn($error);
  }
}

# A WHERE builder for building a WHERE clause in AWQL queries.
# This class should be instantiated through _QueryBuilder.Where. Don't call this constructor directly.
#
# Returns the WHERE builder
package Google::Ads::AdWords::Utilities::QueryBuilder::WhereBuilder;

use strict;
use warnings;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants;
our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Class::Std::Fast;

my %current_query_builder_of : ATTR(:name<current_query_builder> :default<>);
my %field_of : ATTR(:name<field> :default<>);
my %awql_of : ATTR(:name<awql> :default<>);

# Sets the type of the WHERE clause as "equal to".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub equal_to {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, '='));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "not equal to".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns:  The query builder that this WHERE builder links to.
sub not_equal_to {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, '!='));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "greater than".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns:  The query builder that this WHERE builder links to.
sub greater_than {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, '>'));
  return $self->get_current_query_builder();
}
# Sets the type of the WHERE clause as "greater than or equal to".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub greater_than_or_equal_to {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, '>='));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "less than".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub less_than {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, '<'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "less than or equal to”.
# Args:
#   value: The value to be used in the WHERE condition.
# Returns:  The query builder that this WHERE builder links to.
sub less_than_or_equal_to {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, '<='));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "starts with".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub starts_with {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, 'STARTS_WITH'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "starts with ignore case".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub starts_with_ignore_case {
  my ($self, $value) = @_;
  $self->set_awql(
    $self->_create_single_value_condition($value, 'STARTS_WITH_IGNORE_CASE'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "contains".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns:  The query builder that this WHERE builder links to.
sub contains {
  my ($self, $value) = @_;
  $self->set_awql($self->_create_single_value_condition($value, 'CONTAINS'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "contains ignore case".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub contains_ignore_case {
  my ($self, $value) = @_;
  $self->set_awql(
    $self->_create_single_value_condition($value, 'CONTAINS_IGNORE_CASE'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "does not contain".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub does_not_contain {
  my ($self, $value) = @_;
  $self->set_awql(
    $self->_create_single_value_condition($value, 'DOES_NOT_CONTAIN'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "does not contain ignore case".
# Args:
#   value: The value to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub does_not_contain_ignore_case {
  my ($self, $value) = @_;
  $self->set_awql(
    $self->_create_single_value_condition(
      $value, 'DOES_NOT_CONTAIN_IGNORE_CASE'
    ));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "in".
# Args:
#   values: The values to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub in {
  my ($self, $values) = @_;
  $self->set_awql($self->_create_multiple_values_condition($values, 'IN'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "in".
# Args:
#   values: The values to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub not_in {
  my ($self, $values) = @_;
  $self->set_awql($self->_create_multiple_values_condition($values, 'NOT_IN'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "contains any".
# Args:
#   values: The values to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub contains_any {
  my ($self, $values) = @_;
  $self->set_awql(
    $self->_create_multiple_values_condition($values, 'CONTAINS_ANY'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "contains none".
# Args:
#   values: The values to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub contains_none {
  my ($self, $values) = @_;
  $self->set_awql(
    $self->_create_multiple_values_condition($values, 'CONTAINS_NONE'));
  return $self->get_current_query_builder();
}

# Sets the type of the WHERE clause as "contains all".
# Args:
#   values: The values to be used in the WHERE condition.
# Returns: The query builder that this WHERE builder links to.
sub contains_all {
  my ($self, $values) = @_;
  $self->set_awql(
    $self->_create_multiple_values_condition($values, 'CONTAINS_ALL'));
  return $self->get_current_query_builder();
}

# Builds the WHERE clause by returning the stored AWQL.
# Returns: The resulting WHERE clause in AWQL format.
sub build {
  my ($self) = @_;
  return $self->get_awql();
}

# Creates a single-value condition with the provided value and operator.
sub _create_single_value_condition {
  my ($self, $value, $operator) = @_;
  # Put a single quote around strings, but leave numbers alone.
  $value = ($value & ~$value) ? sprintf('"%s"', $value) : $value;
  return sprintf("%s %s %s", $self->get_field(), $operator, $value);
}

# Creates a condition with the provided list of values and operator.
sub _create_multiple_values_condition {
  my ($self, $values, $operator) = @_;
  foreach my $value (@{$values}) {
    $value = ($value =~ /^\d+$/) ? $value : sprintf('"%s"', $value);
  }
  return
    sprintf("%s %s [%s]", $self->get_field(), $operator, join(",", @{$values}));
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::QueryBuilder

=head1 DESCRIPTION

This utility is a query builder for building AWQL (AdWords Query
Language) queries. This module shouldn't be instantiated directly or extended.
Use ReportQueryBuilder if you want to create a query for reporting or the
ServiceQueryBuilder if you want to create service queries.

=head1 ATTRIBUTES

The attributes may be set in new() and accessed using get_ATTRIBUTE
methods:

=head2 client

Google::Ads::AdWords::Client is used to find out if we should die on faults.

=head2 die_on_faults

Set to true if we are requested to die on faults in
Google::Ads::AdWords::Client.

=head2 query_builder

Google::Ads::AdWords::Utilities::QueryBuilder is the current builder.

=head2 where_builders

An array of incline package
Google::Ads::AdWords::Utilities::QueryBuilder::WhereBuilder.

=back

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::Utilities::QueryBuilder
   client # Required: Google::Ads::AdWords::Client
   query_builder # Optional: the Google::Ads::AdWords::Utilities::QueryBuilder
   # to be copied
 },

=head1 METHODS

=head2 select

Sets the specified list of fields to be added to a SELECT clause.

=head3 Parameters

=over

=item *

A reference to an array of fields selected. Not implemented.

=back

=head3 Returns

A query builder (this instance).

=head2 where

Set the filters in the WHERE clause for the query.

=head3 Parameters

=over

=item *

The name of the field to be filtered on.

=back

=head3 Returns

A query builder (this instance).

=cut
