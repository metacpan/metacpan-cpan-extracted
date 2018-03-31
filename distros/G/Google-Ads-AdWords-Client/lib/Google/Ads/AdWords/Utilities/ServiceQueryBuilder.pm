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
# A query builder for building AWQL queries for services.

package Google::Ads::AdWords::Utilities::ServiceQueryBuilder;

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
my %order_by_of : ATTR(:name<order_by> :default<[]>);
my %start_index_of : ATTR(:name<start_index> :default<>);
my %page_size_of : ATTR(:name<page_size> :default<>);

sub START {
  my ($self) = @_;

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
    "ServiceQueryBuilder");

  # If a query builder was specified, then make a copy.
  if ($self->get_query_builder()) {
    push(@{$self->get_select()}, @{$self->get_query_builder()->get_select()});
    push(@{$self->get_order_by()},
         @{$self->get_query_builder()->get_order_by()});
    $self->set_start_index($self->get_query_builder()->get_start_index());
    $self->set_page_size($self->get_query_builder()->get_page_size());
  }

  return $self;
}

# Adds a provided list of fields as selected fields for the query in which
# order will be preserved. Calling the select will clear out any previous calls
# to select.
# Args:
#   fields: The specified list of fields to be added to a SELECT clause.
# Returns: This service query builder.
sub select {
  my ($self, $fields) = @_;
  # Remove any duplicate fields.
  my @unique_fields = ();
  foreach my $field (@$fields) {
    if ( !grep (/^$field$/, @unique_fields)) {
      push @unique_fields, $field;
    }
  }
  $self->set_select(\@unique_fields);
  return $self;
}

# Adds the provided field to the order-by list with the provided direction.
# Args:
#   field: The specified field to be added to the order-by list.
#   ascending: If true, the newly created order-by clause will be in ascending
#   order. Otherwise, it will be in descending order.
# Returns: This service query builder.
sub order_by {
  my ($self, $field, $ascending) = @_;
  $ascending = (defined $ascending) ? $ascending : 1;
  my $order_clause = sprintf("%s %s", $field, (($ascending) ? "ASC" : "DESC"));
  push(@{$self->get_order_by()}, $order_clause);
  return $self;
}

# Sets the LIMIT clause using the provided start index and page size.
# Args:
#   start_index: The specified start index for the LIMIT clause.
#   page_size: The page size for the LIMIT clause.
# Returns: This service query builder.
sub limit {
  my ($self, $start_index, $page_size) = @_;
  if ($start_index xor $page_size) {
    $self->_log_error("Both start_index and page_size need to be set.");
  }
  if ($start_index < 0) {
    $self->_log_error(
      sprintf("The start_index %s must be 0 or greater.", $start_index));
  }
  if ($page_size < 1) {
    $self->_log_error(
      sprintf("The page_size %s must be greater than 0.", $page_size));
  }
  $self->set_start_index($start_index);
  $self->set_page_size($page_size);
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
  my $awql .= sprintf('SELECT %s', join(", ", @{$self->get_select()}));
  my @where_builder_strings = ();
  foreach my $where_builder (@{$self->get_where_builders()}) {
    push(@where_builder_strings, ($where_builder->build()));
  }
  $awql .=
    (scalar @where_builder_strings > 0)
    ? sprintf(' WHERE %s', join(" AND ", @where_builder_strings))
    : '';
  $awql .=
    ($self->get_order_by() and (scalar @{$self->get_order_by()} > 0))
    ? sprintf(' ORDER BY %s', join(", ", @{$self->get_order_by()}))
    : '';
  $awql .=
    ($self->get_start_index() and $self->get_page_size())
    ? sprintf(' LIMIT %s, %s', $self->get_start_index(), $self->get_page_size())
    : '';
  return $awql;
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::ServiceQueryBuilder

=head1 DESCRIPTION

A query builder for building AWQL queries for services.

=head1 ATTRIBUTES

The attributes properties may be set in new() and accessed using get_ATTRIBUTE
methods:

=head2 select

An array of fields that are selected to be filtered on.

=head2 order_by

A hash of field names to ASC or DESC by which results will be ordered.

=head2 start_index

The start index of the results to be retunred.

=head2 page_size

The size of each page that to be returned.

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::Utilities::ReportQueryBuilder
   client # Required: Google::Ads::AdWords::Client
   query_builder # Optional: the Google::Ads::AdWords::Utilities::QueryBuilder
   to be copied
 },

=head1 METHODS

=head2 select

Sets the specified list of fields to be added to a SELECT clause.

=head3 Parameters

=over

=item *

A reference to an array of fields selected.

=back

=head3 Returns

A query builder (this instance).

=head2 order_by

Adds the provided field to the order-by list with the provided direction.

=head3 Parameters

=over

=item *

The specified field to be added to the order-by list.

=item *

If true, the newly created order-by clause will be in ascending order.
Otherwise, it will be in descending order.

=back

=head3 Returns

A query builder (this instance).

=head2 limit

Sets the LIMIT clause using the provided start index and page size.

=head3 Parameters

=over

=item *

The specified start index for the LIMIT clause.

=item *

The page size for the LIMIT clause.

=back

=head3 Returns

A query builder (this instance).

=head2 build

Builds the AWQL query.

=head3 Returns

A string that is the AWQL query.

=cut
