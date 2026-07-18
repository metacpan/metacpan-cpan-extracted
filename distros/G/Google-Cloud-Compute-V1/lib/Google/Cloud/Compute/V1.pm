# Copyright (C) 2026 Google LLC
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

package Google::Cloud::Compute::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Auth;
use Carp qw(croak);

our $VERSION = '0.02';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $client = Google::gRPC::Client->new(
        target     => 'compute.googleapis.com:443',
        auth_token => $token,
    );
    $self->transport($client);
}

sub call_rpc {
    my ($self, $method, $request_msg, $response_class) = @_;
    croak 'transport not initialized' unless $self->transport;
    return $self->transport->call_unary($method, $request_msg, $response_class);
}

1;

__END__

=head1 NAME

Google::Cloud::Compute::V1 - Google Cloud Compute Engine V1 API Client

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();
    my $client = Google::Cloud::Compute::V1->new(credentials => $auth);

=head1 DESCRIPTION

Google Cloud Compute Engine V1 API Client over high-performance gRPC transport.

=head1 LICENSE

Apache 2.0

=cut
