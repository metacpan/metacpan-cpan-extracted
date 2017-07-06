# Copyright 2016, Google Inc. All Rights Reserved.
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

package Google::Ads::AdWords::Utilities::BatchJobHandlerStatus;

use strict;
use warnings;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;

# Total length (in bytes) of the content already uploaded for the job.
my %total_content_length_of : ATTR(:name<total_content_length> :default<"0">);

# The resumable upload URI of the job. If this is the first upload in a series
# of uploads, pass the BatchJob.uploadUrl.
my %resumable_upload_uri_of : ATTR(:name<resumable_upload_uri> :default<"">);

return 1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::BatchJobHandlerStatus

=head1 DESCRIPTION

Data object that holds the information of a batch job's status that occurs
during a batch job upload request.

=head1 ATTRIBUTES

There is a get_ and set_ method associated with each attribute for retrieving or
setting them dynamically.

=head2 total_content_length

Total length (in bytes) of the content already uploaded for the job.

=head2 resumable_upload_uri

The resumable upload URI of the job. If this is the first upload in a series
of uploads, pass the BatchJob.uploadUrl.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Google Inc.

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

