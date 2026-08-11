# Copyright 2022 Google LLC and contributors
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

use Moo;

has selector => (
  is       => 'ro',
  required => 0,
);

has token => (
  is       => 'ro',
  required => 0,
);

sub apply {
  my ($self, $req_or_headers) = @_;

  if (ref $req_or_headers eq 'HASH') {
    $req_or_headers->{'x-goog-iam-authority-selector'} = $self->selector
      if defined $self->selector;
    $req_or_headers->{'x-goog-iam-authorization-token'} = $self->token
      if defined $self->token;
  } elsif (eval { $req_or_headers->isa('HTTP::Request') }) {
    $req_or_headers->header('x-goog-iam-authority-selector' => $self->selector)
      if defined $self->selector;
    $req_or_headers->header('x-goog-iam-authorization-token' => $self->token)
      if defined $self->token;
  }
}

1;
