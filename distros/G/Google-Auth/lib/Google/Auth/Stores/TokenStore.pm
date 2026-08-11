# Copyright 2026 Google LLC and contributors
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

package Google::Auth::Stores::TokenStore;

use strict;
use warnings;

use Moo;
use Google::Auth::Exceptions;

sub load {
  my ($self, $id) = @_;
  Google::Auth::Error->throw('load must be implemented by subclasses');
}

sub store {
  my ($self, $id, $value) = @_;
  Google::Auth::Error->throw('store must be implemented by subclasses');
}

sub delete {
  my ($self, $id) = @_;
  Google::Auth::Error->throw('delete must be implemented by subclasses');
}

1;
