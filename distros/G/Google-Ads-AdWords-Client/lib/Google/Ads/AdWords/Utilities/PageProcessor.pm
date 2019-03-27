# Copyright 2015, Google Inc. All Rights Reserved.
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
# Description: This is a utility that provides automatic paging of results.

package Google::Ads::AdWords::Utilities::PageProcessor;

use strict;
use warnings;
use utf8;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};
use Google::Ads::Common::Utilities::AdsUtilityRegistry;

use Class::Std::Fast;

my %client_of : ATTR(:name<client> :default<>);
my %service_of : ATTR(:name<service> :default<>);
my %selector_of : ATTR(:name<selector> :default<>);
my %query_of : ATTR(:name<query> :default<>);
my %page_size_of : ATTR(:name<page_size>
  :default<Google::Ads::AdWords::Constants::DEFAULT_PAGE_SIZE>);
my $end_of_page = 0;

# Verify that all the variables are correctly defined.
# Either 'selector' or 'query' needs to be defined.
# Page size needs to be greater than 0.
sub START {
  my ($self) = @_;

  Google::Ads::Common::Utilities::AdsUtilityRegistry->add_ads_utilities(
      "PageProcessor");

  if (!defined($self->get_client())) {
    die("Argument 'client' is required.");
  }
  my $die_on_faults = $self->get_client()->get_die_on_faults();
  if (!defined($self->get_service())) {
    my $service_arg_required = "Argument 'service' is required.";
    if ($die_on_faults) {
      die($service_arg_required);
    } else {
      warn($service_arg_required);
    }
  }
  if ( (!defined($self->get_selector()) && !defined($self->get_query()))
    || (defined($self->get_selector()) && defined($self->get_query())))
  {
    my $query_or_selector_arg_required =
      "Argument 'selector' OR 'query' is required.";
    if ($die_on_faults) {
      die($query_or_selector_arg_required);
    } else {
      warn($query_or_selector_arg_required);
    }
  }
  if ($self->get_page_size() <= 0) {
    my $page_size_arg =
      "Argument 'page_size'=>{$self->get_page_size()} must " .
      "be greater than 0.";
    if ($die_on_faults) {
      die($page_size_arg);
    } else {
      warn($page_size_arg);
    }
  }
}

# Process the entries that were retrieved from the service. For each entry,
# execute the subroutine that was passed in as an argument. Return the results
# of the subroutines as an array of results.
sub process_entries {
  my ($self, $process_entry_subroutine) = @_;
  my @results   = ();
  my $service   = $self->get_service();
  my $selector  = $self->get_selector();
  my $query     = $self->get_query();
  my $page_size = $self->get_page_size();
  # Some services have serviceSelector as the arg while others have selector
  # as the arg to the get subroutine.
  my $selector_arg = 'selector';
  if (
    exists $service->get_class_resolver()->get_typemap->{'get/serviceSelector'})
  {
    $selector_arg = 'serviceSelector';
  }
  # If the query includes a LIMIT clause, extrapolate the offset and the page
  # size because the offset will need to be dynamically increased when
  # processing the pages.
  # Example: query => 'SELECT Id, Name, Status ORDER BY Name LIMIT 0,10'
  my $offset = 0;
  my $page;
  if (defined($query)
    && $query =~ m/${\(Google::Ads::AdWords::Constants::QUERY_LIMIT_REGEX)}/i)
  {
    $query     = $1;
    $offset    = $2;
    $page_size = $3;
  }

  do {
    if (defined($selector)) {
      $page = $service->get({$selector_arg => $selector});
    } else {
      $page =
        $service->query({query => "${query} LIMIT ${offset},${page_size}"});
    }
    if ($page->get_entries()) {
      $end_of_page = 0;
      my @entries =
        ref $page->get_entries() eq 'ARRAY'
        ? @{$page->get_entries()}
        : $page->get_entries();
      # Before the last entry in the page, set a boolean indicating that
      # the end of the page has been reached.
      my $last_entry = pop @entries;
      foreach my $entry (@entries) {
        push(@results, $process_entry_subroutine->($entry));
      }
      $end_of_page = 1;
      push(@results, $process_entry_subroutine->($last_entry));
      my $page_size =
        ref $page->get_entries() eq 'ARRAY' ? @{$page->get_entries()} : 1;
      if (defined($selector)) {
        my $paging = $selector->get_paging();
        $paging->set_startIndex($paging->get_startIndex() + $page_size);
      }
      $offset += $page_size;
    }
  } while ($offset < $page->get_totalNumEntries());
  return @results;
}

# Retrieve all the entries from all the pages as an array of entries.
sub get_entries {
  my ($self) = @_;
  my $processEntrySubroutine = sub {
    my ($entry) = @_;
    return $entry;
  };
  return $self->process_entries($processEntrySubroutine);
}

# Returns a 1 if we have reached the end of a page and 0 otherwise.
sub is_end_of_page {
  return $end_of_page;
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::PageProcessor

=head1 DESCRIPTION

This is a utility that provides automatic paging of results.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY methods:

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::Utilities::PageProcessor
   service =>  $service, # A service e.g.
   Google::Ads::AdWords::v201809::TypeMaps::CampaignService object
   selector => $selector, # A reference to a selector e.g.
   Google::Ads::AdWords::v201809::Selector. When 'selector' is defined,
   'query' cannot be defined.
   query => $query, # A string representing a query e.g.
   SELECT Id, Name, Status ORDER BY Name. When 'query' is defined, 'selector'
   cannot be defined.
   page_size => $page_size, # The size of the page (only used when 'query' is
   defined in the constructor).
   If not defined, the default of
   L<Google::Ads::AdWords::Constants:DEFAULT_PAGE_SIZE> will be used.
 },

=head1 METHODS

=head2 process_entries

Process the entries that were retrieved from the service. For each entry,
execute the subroutine that was passed in as an argument. Return the results
of the subroutines as an array of results.

=head3 Parameters

=over

=item *

A reference to the subroutine that will be executed on each entry.

=back

=head3 Returns

An array of all subroutine results (one per entry).

=head2 get_entries

Returns all the entries from all the pages in an array.

=head3 Returns

An array of entries from all the pages.

=head2 is_end_of_page

Returns whether or not processing has reached the end of a page boundary.

=head3 Returns

Returns a 1 if processing reached the end of a page and 0 otherwise.

=cut
