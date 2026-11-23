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

__END__

=encoding UTF-8

=head1 NAME

Google::Auth::Stores::FileTokenStore - Filesystem-backed OAuth 2.0 credential token store

=head1 SYNOPSIS

    use Google::Auth::Stores::FileTokenStore;

    my $store = Google::Auth::Stores::FileTokenStore->new(
        store_dir => "$ENV{HOME}/.config/gcloud-auth-perl",
    );
    $store->store('default', $json_payload);
    my $json = $store->load('default');

=head1 DESCRIPTION

Persists, loads, and deletes serialized OAuth 2.0 user credentials in a local directory.

=head1 METHODS AND ATTRIBUTES

=over 4

=item * B<store_dir>

=item * B<load>

=item * B<store>

=item * B<delete>

=back

=head1 SEE ALSO

L<Google::Auth>, L<Google::Auth::Credentials>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2026 Google LLC and contributors.

Licensed under the Apache License, Version 2.0.

=cut
