# Copyright 2019, Google LLC
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
# The request message for OperationService.poll_until_done() method.

package Google::Ads::GoogleAds::LongRunning::PollOperationRequest;

use strict;
use warnings;
use base qw(Google::Ads::GoogleAds::BaseEntity);

use Google::Ads::GoogleAds::Utils::GoogleAdsHelper;

sub new {
  my ($class, $args) = @_;
  my $self = {
    name                 => $args->{name},
    pollFrequencySeconds => $args->{pollFrequencySeconds},
    pollTimeoutSeconds   => $args->{pollTimeoutSeconds}};

  # Delete the unassigned fields in this object for a more concise JSON payload
  remove_unassigned_fields($self, $args);

  bless $self, $class;
  return $self;
}

1;

=pod

=head1 NAME

Google::Ads::GoogleAds::LongRunning::PollOperationRequest

=head1 DESCRIPTION

The request message for OperationService.poll_until_done() method.

=head1 ATTRIBUTES

=head2 name

The name of the operation resource.

=head2 pollFrequencySeconds

The poll requests frequency in seconds.

=head2 pollTimeoutSeconds

The maximum duration to wait before timing out in seconds.

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Google LLC

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
