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

package Google::Ads::Common::CaptchaRequiredError;

use strict;
use version;
use base qw(Google::Ads::Common::AuthError);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;

# Class::Std-style attributes. Need to be kept in the same line.
my %token_of : ATTR(:name<token>);
my %image_of : ATTR(:name<image>);
my %url_of : ATTR(:name<url>);

sub as_string : STRINGIFY {
  my $self = shift;
  return sprintf(
    "CaptchaRequiredError {\n  token: %s\n  image: %s\n" .
      "  url: %s\n  message: %s\n  code: %s\n  content: %s\n}",
    $self->get_token(),   $self->get_image(), $self->get_url(),
    $self->get_message(), $self->get_code(),  $self->get_content());
}

1;

=pod

=head1 NAME

Google::Ads::Common::CaptchaRequiredError

=head1 DESCRIPTION

Captures Captcha authorization required error information.

=head1 ATTRIBUTES

Each of these attributes can be set via
Google::Ads::Common::CaptchaRequiredError->new().
Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 token

Captcha challenge token.

=head2 image

Holds the URL to the captcha image.

=head2 url

Holds the URL to unlock the challenge.

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

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
