use strict;
use warnings;
use Test::More;
use File::Spec;

# A. Mock Google::Auth
package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default {
    my ($class, %args) = @_;
    return bless \%args, 'Google::Auth::MockCredentials';
}
package Google::Auth::MockCredentials;
sub get_token {
    return 'mock-token';
}

# B. Mock Google::gRPC::Client
package Google::gRPC::Client;
BEGIN { $INC{'Google/gRPC/Client.pm'} = 1; }
sub new {
    my $class = shift;
    my $args = ( @_ == 1 && ref($_[0]) eq 'HASH' ) ? $_[0] : { @_ };
    return bless $args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Fallback Mocks for External Response Classes
BEGIN {
    for my $pkg (qw( Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Networksecurity::V1;

my $client = Google::Cloud::Networksecurity::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_address_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.AddressGroupService', 'Correct service path');
        is($args->{method}, 'ListAddressGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_address_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'list_dns_threat_detectors method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.DnsThreatDetectorService', 'Correct service path');
        is($args->{method}, 'ListDnsThreatDetectors', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_dns_threat_detectors();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse', 'Response object class');
    done_testing();
};

subtest 'list_firewall_endpoints method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.FirewallActivation', 'Correct service path');
        is($args->{method}, 'ListFirewallEndpoints', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_firewall_endpoints();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse', 'Response object class');
    done_testing();
};

subtest 'list_intercept_endpoint_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.Intercept', 'Correct service path');
        is($args->{method}, 'ListInterceptEndpointGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_intercept_endpoint_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'list_mirroring_endpoint_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.Mirroring', 'Correct service path');
        is($args->{method}, 'ListMirroringEndpointGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_mirroring_endpoint_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'list_authorization_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.NetworkSecurity', 'Correct service path');
        is($args->{method}, 'ListAuthorizationPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_authorization_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'list_security_profile_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.SecurityProfileGroupService', 'Correct service path');
        is($args->{method}, 'ListSecurityProfileGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_security_profile_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'list_sacrealms method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.networksecurity.v1.SSERealmService', 'Correct service path');
        is($args->{method}, 'ListSACRealms', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_sacrealms();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse', 'Response object class');
    done_testing();
};

done_testing();
