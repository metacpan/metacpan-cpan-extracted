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

package Google::Auth::ClientId;

use Moo;
use JSON::MaybeXS;
use Google::Auth::Exceptions;

has id => (
  is       => 'ro',
  required => 1,
);

has secret => (
  is       => 'ro',
  required => 1,
);

sub from_hash {
  my ($class, $hash) = @_;

  my $config = $hash->{installed} // $hash->{web};

  if ($config) {
    return $class->new(
      id     => $config->{client_id},
      secret => $config->{client_secret},
    );
  }

  if ($hash->{client_id} && $hash->{client_secret}) {
    return $class->new(
      id     => $hash->{client_id},
      secret => $hash->{client_secret},
    );
  }

  Google::Auth::Error->throw("Invalid format for client ID configuration");
}

sub from_file {
  my ($class, $file) = @_;

  open my $fh, '<', $file or die "Cannot open $file: $!";
  local $/;
  my $json = <$fh>;
  close $fh or die "Cannot close $file: $!";

  my $hash = decode_json($json);
  return $class->from_hash($hash);
}

1;
