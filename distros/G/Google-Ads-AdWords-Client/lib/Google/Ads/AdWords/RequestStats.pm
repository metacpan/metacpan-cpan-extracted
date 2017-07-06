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

package Google::Ads::AdWords::RequestStats;

use strict;
use warnings;
use version;
use Encode qw( encode_utf8 decode_utf8 );

use Class::Std::Fast;

my %client_id_of : ATTR(:name<client_id> :default<>);
my %service_name_of : ATTR(:name<service_name> :default<>);
my %method_name_of : ATTR(:name<method_name> :default<>);
my %response_time_of : ATTR(:name<response_time> :default<0>);
my %request_id_of : ATTR(:name<request_id> :default<>);
my %operations_of : ATTR(:name<operations> :default<0>);
my %is_fault_of : ATTR(:name<is_fault> :default<0>);
my %server_of : ATTR(:name<server> :default<>);
my %fault_message_of : ATTR(:name<fault_message> :default<>);

sub as_str : STRINGIFY {
  my $self          = shift;
  my $client_id     = $self->get_client_id() || "";
  my $server        = $self->get_server() || "";
  my $service       = $self->get_service_name() || "";
  my $method        = $self->get_method_name() || "";
  my $response_time = $self->get_response_time() || "";
  my $request_id    = $self->get_request_id() || "";
  my $operations    = $self->get_operations() || "";
  my $is_fault      = $self->get_is_fault() ? "yes" : "no";
  my $fault_message = $self->get_fault_message() || "";

  # Convert the fault message to one less than 16K characters.
  $fault_message =~ s/\r?\n/ /g;
  my $utf8 = encode_utf8($fault_message);
  my @utf8_chunks = $utf8 =~ /\G(.{1,16000})(?![\x80-\xBF])/sg;
  $fault_message = decode_utf8($_) for @utf8_chunks;

  return " clientCustomerId=${client_id}" . " server=${server}" .
    " service=${service}" . " method=${method}" .
    " responseTime=${response_time}" . " requestId=${request_id}" .
    " operations=${operations}" . " isFault=${is_fault}" .
    " faultMessage=${fault_message}";
}

return 1;

=pod

=head1 NAME

Google::Ads::AdWords::RequestStats

=head1 SYNOPSIS

Class that wraps API request statistics such as number of operations,
request id and others.

=head1 DESCRIPTION

This class holds the data coming from API response headers and others related
to a given request.

=head1 ATTRIBUTES

=head2 client_id

The client id against which the call was made if available.

=head2 server

The server endpoint.

=head2 service_name

The name of the service that was called.

=head2 method_name

The method name of the service that was called.

=head2 response_time

Server side time of the duration of the call.

=head2 request_id

Request id of the call.

=head2 operations

Number of operations in the request.

=head2 is_fault

Whether the request returned as a fault or not.

=head2 fault_message

The stack trace of up to 16K characters if a fault occurs.

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
