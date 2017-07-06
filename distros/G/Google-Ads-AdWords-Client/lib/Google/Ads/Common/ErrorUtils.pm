# Copyright 2011, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::ErrorUtils;

use strict;
use warnings;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

# Gets the index of the operation that was the source of an ApiError object.
sub get_source_operation_index ($) {
  my ($self, $error) = @_;
  # Starting in v201702, an error now includes a FieldPathElement that can
  # return the index of the error.
  if ($error->can('get_fieldPathElements')) {
    my $field_path_elements = $error->get_fieldPathElements();
    my $first_field_path_element =
      ($field_path_elements && (scalar @{$field_path_elements} > 0))
      ? $field_path_elements->[0]
      : undef;
    if ( $first_field_path_element
      && ($first_field_path_element->get_field() eq "operations")
      && defined $first_field_path_element->get_index())
    {
      return $first_field_path_element->get_index();
    }
  } elsif ($error->get_fieldPath() =~ /^operations\[(\d+)\]/) {
      return $1;
  }
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::ErrorUtils

=head1 SYNOPSIS

 use Google::Ads::Common::ErrorUtils;

 my $index =
    Google::Ads::Common::ErrorUtils::get_source_operation_index($api_error);

 # $index will contain the index of the operation that failed in the request.

=head1 DESCRIPTION

=head1 SUBROUTINES

=head2 get_source_operation_index

Gets the index of the operation that was the source of an error.

=head3 Parameters

The error of type ApiError from which the index will be retrieved.

=head3 Returns

The index of the error or nothing if an invalid error is passed.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
