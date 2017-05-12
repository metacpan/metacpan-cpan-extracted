# Copyright 2012, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::ReportDownloadError;

use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;

# Error type.
my %type_of : ATTR(:name<type> :default<"">);

# Bad data triggering the error.
my %trigger_of : ATTR(:name<trigger> :default<"">);

# ONGL path to the field cause of the error.
my %field_path_of : ATTR(:name<field_path> :default<"">);

return 1;

=pod

=head1 NAME

Google::Ads::Common::ReportDownloadError

=head1 DESCRIPTION

Data object that holds the information of an error that occurred during a
report download request.

=head1 ATTRIBUTES

There is a get_ and set_ method associated with each attribute for retrieving or
setting them dynamically.

=head2 type

The type of error ocurred.

=head2 trigger

Invalid data cause of the error.

=head2 field_path

ONGL path to the field that caused the error.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 AUTHOR

David Torres E<lt>api.davidtorres at gmail.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
