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

package Google::Cloud::Spanner::V1;

use strict;
use warnings;
use Moo;
use Google::Spanner::V1::Spanner;
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
    if (!$self->transport) {
        my $token = $auth ? eval { $auth->get_token() } : undef;
        $self->transport(Google::gRPC::Client->new({
            target     => 'spanner.googleapis.com',
            auth_token => $token || '',
        }));
    }
}

sub new_execute_sql_request {
    my ($self, $params) = @_;
    my $msg = Google::Spanner::V1::Spanner::ExecuteSqlRequest->new($params);
    return $msg->serialize();
}

sub parse_partial_result_set {
    my ($self, $bytes) = @_;
    return Google::Spanner::V1::ResultSet::PartialResultSet->parse($bytes);
}

sub create_session {
    my ($self, %params) = @_;
    my $request = Google::Spanner::V1::Spanner::CreateSessionRequest->new(\%params);
    return $self->transport->call({
        service        => 'google.spanner.v1.Spanner',
        method         => 'CreateSession',
        request        => $request,
        response_class => 'Google::Spanner::V1::Spanner::Session',
    });
}

sub execute_sql {
    my ($self, %params) = @_;
    my $request = Google::Spanner::V1::Spanner::ExecuteSqlRequest->new(\%params);
    return $self->transport->call({
        service        => 'google.spanner.v1.Spanner',
        method         => 'ExecuteSql',
        request        => $request,
        response_class => 'Google::Spanner::V1::ResultSet::ResultSet',
    });
}

1;
