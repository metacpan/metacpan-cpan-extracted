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

package Google::Auth::Stores::FileTokenStore;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::Stores::TokenStore';

use File::Spec;
use File::Path qw(make_path);
use Google::Auth::Exceptions;

has store_dir => (
  is       => 'ro',
  required => 1,
);

sub BUILD {
  my ($self) = @_;
  my $dir = $self->store_dir;
  if (!-d $dir) {
    eval { make_path($dir) };
    if ($@) {
      Google::Auth::Error->throw(
        'Failed to create token store directory ' . $dir . ': ' . $@);
    }
  }
}

sub _file_path {
  my ($self, $id) = @_;

  # Sanitize ID to prevent path traversal?
  # Assuming ID is a simple string like email or user_name
  if ($id =~ /[\/\\]/) {
    Google::Auth::Error->throw(
      'Invalid ID \'' . $id . '\': cannot contain path separators');
  }
  return File::Spec->catfile($self->store_dir, $id . '.json');
}

sub load {
  my ($self, $id) = @_;
  my $path = $self->_file_path($id);

  return unless -f $path;

  open(my $fh, '<:encoding(UTF-8)', $path) or return;    # Or throw?
  local $/;
  my $value = <$fh>;
  close($fh) or Google::Auth::Error->throw("Failed to close $path: $!");

  return $value;
}

sub store {
  my ($self, $id, $value) = @_;
  my $path = $self->_file_path($id);

  require Fcntl;
  sysopen(my $fh, $path,
    Fcntl::O_CREAT() | Fcntl::O_WRONLY() | Fcntl::O_TRUNC(), 0600)
    or Google::Auth::Error->throw("Failed to write to $path: $!");

  # Set binmode for UTF-8 encoding
  binmode($fh, ':encoding(UTF-8)');

  print $fh $value;
  close($fh) or Google::Auth::Error->throw("Failed to close $path: $!");
  return;
}

sub delete {
  my ($self, $id) = @_;
  my $path = $self->_file_path($id);

  if (-f $path) {
    unlink($path)
      or Google::Auth::Error->throw('Failed to delete ' . $path . ': ' . $!);
  }
  return;
}

1;
