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

package Google::Ads::AdWords::Utilities::BatchJobHandlerError;

use strict;
use warnings;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;

# Error type.
my %type_of : ATTR(:name<type> :default<"">);

# Description of the error.
my %description_of : ATTR(:name<description> :default<"">);

##################################################
# Additional information for HTTP errors.
##################################################
my %http_type_of : ATTR(:name<http_type> :default<"">);

# Bad data triggering the error.
my %http_trigger_of : ATTR(:name<http_trigger> :default<"">);

# ONGL path to the field cause of the error.
my %http_field_path_of : ATTR(:name<http_field_path> :default<"">);

my %http_response_code_of : ATTR(:name<http_response_code> :default<"">);

my %http_response_message_of : ATTR(:name<http_response_message> :default<"">);

##################################################
# Additional information for PROCESSING errors.
##################################################
my %processing_errors_of : ATTR(:name<processing_errors> :default<>);

# Always return false in boolean context.
sub as_bool : BOOLIFY {
  return;
}

sub as_str : STRINGIFY {
  my ($self) = @_;
  return sprintf(
    "BatchJobHandlerError {\n  type: %s\n  description: %s\n" .
      "  http_type: %s\n  http_trigger: %s\n  http_field_path: %s\n" .
      "  http_response_code: %s\n  http_response_message: %s\n}",
    $self->get_type(), $self->get_description(),
    $self->get_http_type(),
    $self->get_http_trigger(),
    $self->get_http_field_path(),
    $self->get_http_response_code(),
    $self->get_http_response_message());
}

return 1;

=pod

=head1 NAME

Google::Ads::AdWords::Utilities::BatchJobHandlerError

=head1 DESCRIPTION

Data object that holds the information of an error that occurred during a
batch job upload request.

=head1 ATTRIBUTES

There is a get_ and set_ method associated with each attribute for retrieving or
setting them dynamically.

=head2 type

The type of error that occurred (HTTP, PROCESSING, UPLOAD).
HTTP => Specific to an HTTP request made to the server.
PROCESSING => Check the current job because the job has processing errors.
UPLOAD => A general error happened during upload.

=head2 description

The detailed description of the error.

=head2 http_type

For HTTP errors, the type of HTTP error.

=head2 http_trigger

For HTTP errors, invalid data cause of the error.

=head2 http_field_path

For HTTP errors, ONGL path to the field that caused the error.

=head2 http_response_code

For HTTP errors, the HTTP response code.

=head2 http_response_message

For HTTP errors, the HTTP response message.

=head2 processing_errors

For PROCESSING errors, this contains an array of processing errors of type
BatchJobProcessingError.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Google Inc.

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

