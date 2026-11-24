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
    for my $pkg (qw( Google::Cloud::Compute::V1beta::Compute::AcceleratorType Google::Cloud::Compute::V1beta::Compute::AcceleratorTypeAggregatedList Google::Cloud::Compute::V1beta::Compute::AcceleratorTypeList Google::Cloud::Compute::V1beta::Compute::BackendBucketListUsable Google::Cloud::Compute::V1beta::Compute::BackendServiceGroupHealth Google::Cloud::Compute::V1beta::Compute::BackendServicesGetEffectiveSecurityPoliciesResponse Google::Cloud::Compute::V1beta::Compute::CalendarModeAdviceResponse Google::Cloud::Compute::V1beta::Compute::CalendarModeExtensionAdviceResponse Google::Cloud::Compute::V1beta::Compute::CapacityAdviceResponse Google::Cloud::Compute::V1beta::Compute::CapacityHistoryResponse Google::Cloud::Compute::V1beta::Compute::ExchangedPeeringRoutesList Google::Cloud::Compute::V1beta::Compute::FirewallPoliciesListAssociationsResponse Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule Google::Cloud::Compute::V1beta::Compute::GuestAttributes Google::Cloud::Compute::V1beta::Compute::Image Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersGetAvailableAcceleratorTopologiesResponse Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListErrorsResponse Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListManagedInstancesResponse Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListPerInstanceConfigsResp Google::Cloud::Compute::V1beta::Compute::InstanceGroupsListInstances Google::Cloud::Compute::V1beta::Compute::InstanceListReferrers Google::Cloud::Compute::V1beta::Compute::InstancesGetEffectiveFirewallsResponse Google::Cloud::Compute::V1beta::Compute::InterconnectAttachmentGroupsGetOperationalStatusResponse Google::Cloud::Compute::V1beta::Compute::InterconnectsGetDiagnosticsResponse Google::Cloud::Compute::V1beta::Compute::InterconnectsGetMacsecConfigResponse Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesResponse Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse Google::Cloud::Compute::V1beta::Compute::NetworkEndpointGroupsListNetworkEndpoints Google::Cloud::Compute::V1beta::Compute::NodeGroupsListNodes Google::Cloud::Compute::V1beta::Compute::Operation Google::Cloud::Compute::V1beta::Compute::PartnerMetadata Google::Cloud::Compute::V1beta::Compute::Policy Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse Google::Cloud::Compute::V1beta::Compute::Screenshot Google::Cloud::Compute::V1beta::Compute::SecurityPoliciesListPreconfiguredExpressionSetsResponse Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceResponse Google::Cloud::Compute::V1beta::Compute::SerialPortOutput Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceIdentity Google::Cloud::Compute::V1beta::Compute::ShieldedVmIdentity Google::Cloud::Compute::V1beta::Compute::SnapshotsGetEffectiveRecycleBinRuleResponse Google::Cloud::Compute::V1beta::Compute::SslPoliciesListAvailableFeaturesResponse Google::Cloud::Compute::V1beta::Compute::StoragePoolListDisks Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse Google::Cloud::Compute::V1beta::Compute::UrlMapsValidateResponse Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList Google::Cloud::Compute::V1beta::Compute::VmExtensionState Google::Cloud::Compute::V1beta::Compute::VpnGatewaysGetStatusResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1beta;

my $client = Google::Cloud::Compute::V1beta->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.AcceleratorTypes', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AggregatedListAcceleratorTypesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::AcceleratorTypeAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::AcceleratorTypeAggregatedList', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.AcceleratorTypes', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetAcceleratorTypeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::AcceleratorType'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::AcceleratorType', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.AcceleratorTypes', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListAcceleratorTypesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::AcceleratorTypeList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::AcceleratorTypeList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Addresses', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteAddressRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Addresses', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::InsertAddressRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'move method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Addresses', 'Correct service path');
        is($args->{method}, 'Move', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::MoveAddressRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->move();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_labels method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Addresses', 'Correct service path');
        is($args->{method}, 'SetLabels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetLabelsAddressRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_labels();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Addresses', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsAddressRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'calendar_mode method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Advice', 'Correct service path');
        is($args->{method}, 'CalendarMode', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CalendarModeAdviceRpcRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::CalendarModeAdviceResponse'->new();
        return $response;
    };
    
    my $res = $client->calendar_mode();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::CalendarModeAdviceResponse', 'Response object class');
    done_testing();
};

subtest 'calendar_mode_extension method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Advice', 'Correct service path');
        is($args->{method}, 'CalendarModeExtension', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CalendarModeExtensionAdviceRpcRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::CalendarModeExtensionAdviceResponse'->new();
        return $response;
    };
    
    my $res = $client->calendar_mode_extension();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::CalendarModeExtensionAdviceResponse', 'Response object class');
    done_testing();
};

subtest 'capacity method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Advice', 'Correct service path');
        is($args->{method}, 'Capacity', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CapacityAdviceRpcRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::CapacityAdviceResponse'->new();
        return $response;
    };
    
    my $res = $client->capacity();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::CapacityAdviceResponse', 'Response object class');
    done_testing();
};

subtest 'capacity_history method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Advice', 'Correct service path');
        is($args->{method}, 'CapacityHistory', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CapacityHistoryAdviceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::CapacityHistoryResponse'->new();
        return $response;
    };
    
    my $res = $client->capacity_history();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::CapacityHistoryResponse', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Autoscalers', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchAutoscalerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Autoscalers', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateAutoscalerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_signed_url_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendBuckets', 'Correct service path');
        is($args->{method}, 'AddSignedUrlKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddSignedUrlKeyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_signed_url_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_signed_url_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendBuckets', 'Correct service path');
        is($args->{method}, 'DeleteSignedUrlKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteSignedUrlKeyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_signed_url_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendBuckets', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetIamPolicyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'list_usable method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendBuckets', 'Correct service path');
        is($args->{method}, 'ListUsable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListUsableBackendBucketsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::BackendBucketListUsable'->new();
        return $response;
    };
    
    my $res = $client->list_usable();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::BackendBucketListUsable', 'Response object class');
    done_testing();
};

subtest 'set_edge_security_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendBuckets', 'Correct service path');
        is($args->{method}, 'SetEdgeSecurityPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetEdgeSecurityPolicyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_edge_security_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendBuckets', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetIamPolicyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'get_effective_security_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendServices', 'Correct service path');
        is($args->{method}, 'GetEffectiveSecurityPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetEffectiveSecurityPoliciesBackendServiceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::BackendServicesGetEffectiveSecurityPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->get_effective_security_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::BackendServicesGetEffectiveSecurityPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'get_health method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendServices', 'Correct service path');
        is($args->{method}, 'GetHealth', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetHealthBackendServiceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::BackendServiceGroupHealth'->new();
        return $response;
    };
    
    my $res = $client->get_health();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::BackendServiceGroupHealth', 'Response object class');
    done_testing();
};

subtest 'set_security_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.BackendServices', 'Correct service path');
        is($args->{method}, 'SetSecurityPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetSecurityPolicyBackendServiceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_security_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_resource_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'AddResourcePolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddResourcePoliciesDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_resource_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'bulk_insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'BulkInsert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::BulkInsertDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->bulk_insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'bulk_set_labels method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'BulkSetLabels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::BulkSetLabelsDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->bulk_set_labels();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'create_snapshot method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'CreateSnapshot', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CreateSnapshotDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_snapshot();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_resource_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'RemoveResourcePolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemoveResourcePoliciesDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_resource_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'resize method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'Resize', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ResizeDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->resize();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'start_async_replication method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'StartAsyncReplication', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StartAsyncReplicationDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_async_replication();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_async_replication method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'StopAsyncReplication', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StopAsyncReplicationDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_async_replication();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_group_async_replication method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'StopGroupAsyncReplication', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StopGroupAsyncReplicationDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_group_async_replication();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_kms_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Disks', 'Correct service path');
        is($args->{method}, 'UpdateKmsKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateKmsKeyDiskRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_kms_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_association method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'AddAssociation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddAssociationFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_association();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_packet_mirroring_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'AddPacketMirroringRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddPacketMirroringRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_packet_mirroring_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'AddRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'clone_rules method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'CloneRules', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CloneRulesFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->clone_rules();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_association method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'GetAssociation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetAssociationFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation'->new();
        return $response;
    };
    
    my $res = $client->get_association();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation', 'Response object class');
    done_testing();
};

subtest 'get_packet_mirroring_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'GetPacketMirroringRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetPacketMirroringRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule'->new();
        return $response;
    };
    
    my $res = $client->get_packet_mirroring_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule', 'Response object class');
    done_testing();
};

subtest 'get_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'GetRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule'->new();
        return $response;
    };
    
    my $res = $client->get_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule', 'Response object class');
    done_testing();
};

subtest 'list_associations method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'ListAssociations', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListAssociationsFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::FirewallPoliciesListAssociationsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_associations();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::FirewallPoliciesListAssociationsResponse', 'Response object class');
    done_testing();
};

subtest 'patch_packet_mirroring_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'PatchPacketMirroringRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchPacketMirroringRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_packet_mirroring_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'PatchRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_association method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'RemoveAssociation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemoveAssociationFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_association();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_packet_mirroring_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'RemovePacketMirroringRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemovePacketMirroringRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_packet_mirroring_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'RemoveRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemoveRuleFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_target method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.ForwardingRules', 'Correct service path');
        is($args->{method}, 'SetTarget', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetTargetForwardingRuleRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_target();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'cancel method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FutureReservations', 'Correct service path');
        is($args->{method}, 'Cancel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CancelFutureReservationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->cancel();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'attach_network_endpoints method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.GlobalNetworkEndpointGroups', 'Correct service path');
        is($args->{method}, 'AttachNetworkEndpoints', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AttachNetworkEndpointsGlobalNetworkEndpointGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->attach_network_endpoints();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'detach_network_endpoints method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.GlobalNetworkEndpointGroups', 'Correct service path');
        is($args->{method}, 'DetachNetworkEndpoints', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DetachNetworkEndpointsGlobalNetworkEndpointGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->detach_network_endpoints();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list_network_endpoints method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.GlobalNetworkEndpointGroups', 'Correct service path');
        is($args->{method}, 'ListNetworkEndpoints', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListNetworkEndpointsGlobalNetworkEndpointGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::NetworkEndpointGroupsListNetworkEndpoints'->new();
        return $response;
    };
    
    my $res = $client->list_network_endpoints();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::NetworkEndpointGroupsListNetworkEndpoints', 'Response object class');
    done_testing();
};

subtest 'wait method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.GlobalOperations', 'Correct service path');
        is($args->{method}, 'Wait', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::WaitGlobalOperationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->wait();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_version method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Hosts', 'Correct service path');
        is($args->{method}, 'GetVersion', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetVersionHostRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->get_version();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'deprecate method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Images', 'Correct service path');
        is($args->{method}, 'Deprecate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeprecateImageRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->deprecate();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_from_family method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Images', 'Correct service path');
        is($args->{method}, 'GetFromFamily', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetFromFamilyImageRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Image'->new();
        return $response;
    };
    
    my $res = $client->get_from_family();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Image', 'Response object class');
    done_testing();
};

subtest 'abandon_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'AbandonInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AbandonInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->abandon_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'apply_updates_to_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ApplyUpdatesToInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ApplyUpdatesToInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->apply_updates_to_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'configure_accelerator_topologies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ConfigureAcceleratorTopologies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ConfigureAcceleratorTopologiesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->configure_accelerator_topologies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'create_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'CreateInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CreateInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'DeleteInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_per_instance_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'DeletePerInstanceConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeletePerInstanceConfigsInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_per_instance_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_available_accelerator_topologies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'GetAvailableAcceleratorTopologies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetAvailableAcceleratorTopologiesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersGetAvailableAcceleratorTopologiesResponse'->new();
        return $response;
    };
    
    my $res = $client->get_available_accelerator_topologies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersGetAvailableAcceleratorTopologiesResponse', 'Response object class');
    done_testing();
};

subtest 'list_errors method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ListErrors', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListErrorsInstanceGroupManagersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListErrorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_errors();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListErrorsResponse', 'Response object class');
    done_testing();
};

subtest 'list_managed_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ListManagedInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListManagedInstancesInstanceGroupManagersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListManagedInstancesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_managed_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListManagedInstancesResponse', 'Response object class');
    done_testing();
};

subtest 'list_per_instance_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ListPerInstanceConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListPerInstanceConfigsInstanceGroupManagersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListPerInstanceConfigsResp'->new();
        return $response;
    };
    
    my $res = $client->list_per_instance_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListPerInstanceConfigsResp', 'Response object class');
    done_testing();
};

subtest 'patch_per_instance_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'PatchPerInstanceConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchPerInstanceConfigsInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_per_instance_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'recreate_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'RecreateInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RecreateInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->recreate_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'resize_advanced method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ResizeAdvanced', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ResizeAdvancedInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->resize_advanced();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'resume_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'ResumeInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ResumeInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->resume_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_auto_healing_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'SetAutoHealingPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetAutoHealingPoliciesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_auto_healing_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_instance_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'SetInstanceTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetInstanceTemplateInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_instance_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_target_pools method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'SetTargetPools', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetTargetPoolsInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_target_pools();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'start_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'StartInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StartInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'StopInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StopInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'suspend_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'SuspendInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SuspendInstancesInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->suspend_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_per_instance_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroupManagers', 'Correct service path');
        is($args->{method}, 'UpdatePerInstanceConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdatePerInstanceConfigsInstanceGroupManagerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_per_instance_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroups', 'Correct service path');
        is($args->{method}, 'AddInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddInstancesInstanceGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroups', 'Correct service path');
        is($args->{method}, 'ListInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListInstancesInstanceGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupsListInstances'->new();
        return $response;
    };
    
    my $res = $client->list_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupsListInstances', 'Response object class');
    done_testing();
};

subtest 'remove_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroups', 'Correct service path');
        is($args->{method}, 'RemoveInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemoveInstancesInstanceGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_named_ports method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InstanceGroups', 'Correct service path');
        is($args->{method}, 'SetNamedPorts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetNamedPortsInstanceGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_named_ports();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_access_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'AddAccessConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddAccessConfigInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_access_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_network_interface method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'AddNetworkInterface', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddNetworkInterfaceInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_network_interface();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'attach_disk method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'AttachDisk', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AttachDiskInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->attach_disk();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_access_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'DeleteAccessConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteAccessConfigInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_access_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_network_interface method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'DeleteNetworkInterface', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteNetworkInterfaceInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_network_interface();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'detach_disk method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'DetachDisk', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DetachDiskInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->detach_disk();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_effective_firewalls method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetEffectiveFirewalls', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetEffectiveFirewallsInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstancesGetEffectiveFirewallsResponse'->new();
        return $response;
    };
    
    my $res = $client->get_effective_firewalls();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstancesGetEffectiveFirewallsResponse', 'Response object class');
    done_testing();
};

subtest 'get_guest_attributes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetGuestAttributes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetGuestAttributesInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::GuestAttributes'->new();
        return $response;
    };
    
    my $res = $client->get_guest_attributes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::GuestAttributes', 'Response object class');
    done_testing();
};

subtest 'get_partner_metadata method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetPartnerMetadata', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetPartnerMetadataInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::PartnerMetadata'->new();
        return $response;
    };
    
    my $res = $client->get_partner_metadata();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::PartnerMetadata', 'Response object class');
    done_testing();
};

subtest 'get_screenshot method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetScreenshot', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetScreenshotInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Screenshot'->new();
        return $response;
    };
    
    my $res = $client->get_screenshot();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Screenshot', 'Response object class');
    done_testing();
};

subtest 'get_serial_port_output method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetSerialPortOutput', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetSerialPortOutputInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::SerialPortOutput'->new();
        return $response;
    };
    
    my $res = $client->get_serial_port_output();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::SerialPortOutput', 'Response object class');
    done_testing();
};

subtest 'get_shielded_instance_identity method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetShieldedInstanceIdentity', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetShieldedInstanceIdentityInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceIdentity'->new();
        return $response;
    };
    
    my $res = $client->get_shielded_instance_identity();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceIdentity', 'Response object class');
    done_testing();
};

subtest 'get_shielded_vm_identity method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetShieldedVmIdentity', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetShieldedVmIdentityInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::ShieldedVmIdentity'->new();
        return $response;
    };
    
    my $res = $client->get_shielded_vm_identity();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::ShieldedVmIdentity', 'Response object class');
    done_testing();
};

subtest 'get_vm_extension_state method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'GetVmExtensionState', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetVmExtensionStateInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VmExtensionState'->new();
        return $response;
    };
    
    my $res = $client->get_vm_extension_state();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VmExtensionState', 'Response object class');
    done_testing();
};

subtest 'list_referrers method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'ListReferrers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListReferrersInstancesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InstanceListReferrers'->new();
        return $response;
    };
    
    my $res = $client->list_referrers();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InstanceListReferrers', 'Response object class');
    done_testing();
};

subtest 'list_vm_extension_states method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'ListVmExtensionStates', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesInstancesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_vm_extension_states();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesResponse', 'Response object class');
    done_testing();
};

subtest 'patch_partner_metadata method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'PatchPartnerMetadata', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchPartnerMetadataInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_partner_metadata();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'perform_maintenance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'PerformMaintenance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PerformMaintenanceInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->perform_maintenance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'report_host_as_faulty method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'ReportHostAsFaulty', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ReportHostAsFaultyInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->report_host_as_faulty();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'reset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'Reset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ResetInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->reset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'resume method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'Resume', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ResumeInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->resume();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'send_diagnostic_interrupt method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SendDiagnosticInterrupt', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceResponse'->new();
        return $response;
    };
    
    my $res = $client->send_diagnostic_interrupt();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceResponse', 'Response object class');
    done_testing();
};

subtest 'set_deletion_protection method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetDeletionProtection', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetDeletionProtectionInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_deletion_protection();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_disk_auto_delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetDiskAutoDelete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetDiskAutoDeleteInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_disk_auto_delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_machine_resources method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetMachineResources', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetMachineResourcesInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_machine_resources();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_machine_type method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetMachineType', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetMachineTypeInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_machine_type();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_metadata method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetMetadata', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetMetadataInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_metadata();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_min_cpu_platform method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetMinCpuPlatform', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetMinCpuPlatformInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_min_cpu_platform();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_name method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetName', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetNameInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_name();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_scheduling method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetScheduling', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetSchedulingInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_scheduling();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_service_account method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetServiceAccount', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetServiceAccountInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_service_account();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_shielded_instance_integrity_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetShieldedInstanceIntegrityPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetShieldedInstanceIntegrityPolicyInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_shielded_instance_integrity_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_shielded_vm_integrity_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetShieldedVmIntegrityPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetShieldedVmIntegrityPolicyInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_shielded_vm_integrity_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_tags method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SetTags', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetTagsInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_tags();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'simulate_maintenance_event method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'SimulateMaintenanceEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SimulateMaintenanceEventInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->simulate_maintenance_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'start method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'Start', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StartInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->start();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'start_with_encryption_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'StartWithEncryptionKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StartWithEncryptionKeyInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_with_encryption_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'stop method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'Stop', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::StopInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'suspend method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'Suspend', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SuspendInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->suspend();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_access_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'UpdateAccessConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateAccessConfigInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_access_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_display_device method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'UpdateDisplayDevice', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateDisplayDeviceInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_display_device();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_network_interface method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'UpdateNetworkInterface', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateNetworkInterfaceInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_network_interface();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_shielded_instance_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'UpdateShieldedInstanceConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateShieldedInstanceConfigInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_shielded_instance_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_shielded_vm_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Instances', 'Correct service path');
        is($args->{method}, 'UpdateShieldedVmConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateShieldedVmConfigInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_shielded_vm_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_operational_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InterconnectAttachmentGroups', 'Correct service path');
        is($args->{method}, 'GetOperationalStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetOperationalStatusInterconnectAttachmentGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InterconnectAttachmentGroupsGetOperationalStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->get_operational_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InterconnectAttachmentGroupsGetOperationalStatusResponse', 'Response object class');
    done_testing();
};

subtest 'create_members method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.InterconnectGroups', 'Correct service path');
        is($args->{method}, 'CreateMembers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CreateMembersInterconnectGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_members();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_diagnostics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Interconnects', 'Correct service path');
        is($args->{method}, 'GetDiagnostics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetDiagnosticsInterconnectRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InterconnectsGetDiagnosticsResponse'->new();
        return $response;
    };
    
    my $res = $client->get_diagnostics();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InterconnectsGetDiagnosticsResponse', 'Response object class');
    done_testing();
};

subtest 'get_macsec_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Interconnects', 'Correct service path');
        is($args->{method}, 'GetMacsecConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetMacsecConfigInterconnectRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::InterconnectsGetMacsecConfigResponse'->new();
        return $response;
    };
    
    my $res = $client->get_macsec_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::InterconnectsGetMacsecConfigResponse', 'Response object class');
    done_testing();
};

subtest 'add_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'AddPeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddPeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'cancel_request_remove_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'CancelRequestRemovePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::CancelRequestRemovePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->cancel_request_remove_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list_peering_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'ListPeeringRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListPeeringRoutesNetworksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::ExchangedPeeringRoutesList'->new();
        return $response;
    };
    
    my $res = $client->list_peering_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::ExchangedPeeringRoutesList', 'Response object class');
    done_testing();
};

subtest 'remove_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'RemovePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemovePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'request_remove_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'RequestRemovePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RequestRemovePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->request_remove_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'switch_to_custom_mode method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'SwitchToCustomMode', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SwitchToCustomModeNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->switch_to_custom_mode();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_peering method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Networks', 'Correct service path');
        is($args->{method}, 'UpdatePeering', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdatePeeringNetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_peering();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_nodes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.NodeGroups', 'Correct service path');
        is($args->{method}, 'AddNodes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddNodesNodeGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_nodes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_nodes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.NodeGroups', 'Correct service path');
        is($args->{method}, 'DeleteNodes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteNodesNodeGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_nodes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list_nodes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.NodeGroups', 'Correct service path');
        is($args->{method}, 'ListNodes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListNodesNodeGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::NodeGroupsListNodes'->new();
        return $response;
    };
    
    my $res = $client->list_nodes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::NodeGroupsListNodes', 'Response object class');
    done_testing();
};

subtest 'set_node_template method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.NodeGroups', 'Correct service path');
        is($args->{method}, 'SetNodeTemplate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetNodeTemplateNodeGroupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_node_template();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'advance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Rollouts', 'Correct service path');
        is($args->{method}, 'Advance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AdvanceRolloutRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->advance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'pause method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Rollouts', 'Correct service path');
        is($args->{method}, 'Pause', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PauseRolloutRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->pause();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'DeleteNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'DeleteRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse'->new();
        return $response;
    };
    
    my $res = $client->get_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse', 'Response object class');
    done_testing();
};

subtest 'get_nat_ip_info method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetNatIpInfo', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetNatIpInfoRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse'->new();
        return $response;
    };
    
    my $res = $client->get_nat_ip_info();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse', 'Response object class');
    done_testing();
};

subtest 'get_nat_mapping_info method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetNatMappingInfo', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetNatMappingInfoRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList'->new();
        return $response;
    };
    
    my $res = $client->get_nat_mapping_info();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList', 'Response object class');
    done_testing();
};

subtest 'get_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse'->new();
        return $response;
    };
    
    my $res = $client->get_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse', 'Response object class');
    done_testing();
};

subtest 'get_router_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'GetRouterStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetRouterStatusRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->get_router_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse', 'Response object class');
    done_testing();
};

subtest 'list_bgp_routes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'ListBgpRoutes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListBgpRoutesRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes'->new();
        return $response;
    };
    
    my $res = $client->list_bgp_routes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes', 'Response object class');
    done_testing();
};

subtest 'list_named_sets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'ListNamedSets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListNamedSetsRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets'->new();
        return $response;
    };
    
    my $res = $client->list_named_sets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets', 'Response object class');
    done_testing();
};

subtest 'list_route_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'ListRoutePolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListRoutePoliciesRoutersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies'->new();
        return $response;
    };
    
    my $res = $client->list_route_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies', 'Response object class');
    done_testing();
};

subtest 'patch_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'PatchNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'PatchRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'preview method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'Preview', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PreviewRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse'->new();
        return $response;
    };
    
    my $res = $client->preview();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse', 'Response object class');
    done_testing();
};

subtest 'update_named_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'UpdateNamedSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateNamedSetRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_named_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'update_route_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Routers', 'Correct service path');
        is($args->{method}, 'UpdateRoutePolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::UpdateRoutePolicyRouterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_route_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list_preconfigured_expression_sets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.SecurityPolicies', 'Correct service path');
        is($args->{method}, 'ListPreconfiguredExpressionSets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListPreconfiguredExpressionSetsSecurityPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::SecurityPoliciesListPreconfiguredExpressionSetsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_preconfigured_expression_sets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::SecurityPoliciesListPreconfiguredExpressionSetsResponse', 'Response object class');
    done_testing();
};

subtest 'get_effective_recycle_bin_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Snapshots', 'Correct service path');
        is($args->{method}, 'GetEffectiveRecycleBinRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetEffectiveRecycleBinRuleSnapshotRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::SnapshotsGetEffectiveRecycleBinRuleResponse'->new();
        return $response;
    };
    
    my $res = $client->get_effective_recycle_bin_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::SnapshotsGetEffectiveRecycleBinRuleResponse', 'Response object class');
    done_testing();
};

subtest 'list_available_features method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.SslPolicies', 'Correct service path');
        is($args->{method}, 'ListAvailableFeatures', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListAvailableFeaturesSslPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::SslPoliciesListAvailableFeaturesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_available_features();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::SslPoliciesListAvailableFeaturesResponse', 'Response object class');
    done_testing();
};

subtest 'list_disks method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.StoragePools', 'Correct service path');
        is($args->{method}, 'ListDisks', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListDisksStoragePoolsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::StoragePoolListDisks'->new();
        return $response;
    };
    
    my $res = $client->list_disks();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::StoragePoolListDisks', 'Response object class');
    done_testing();
};

subtest 'expand_ip_cidr_range method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Subnetworks', 'Correct service path');
        is($args->{method}, 'ExpandIpCidrRange', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ExpandIpCidrRangeSubnetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->expand_ip_cidr_range();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_private_ip_google_access method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.Subnetworks', 'Correct service path');
        is($args->{method}, 'SetPrivateIpGoogleAccess', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetPrivateIpGoogleAccessSubnetworkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_private_ip_google_access();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_url_map method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetHttpProxies', 'Correct service path');
        is($args->{method}, 'SetUrlMap', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetUrlMapTargetHttpProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_url_map();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_certificate_map method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetHttpsProxies', 'Correct service path');
        is($args->{method}, 'SetCertificateMap', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetCertificateMapTargetHttpsProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_certificate_map();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_quic_override method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetHttpsProxies', 'Correct service path');
        is($args->{method}, 'SetQuicOverride', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetQuicOverrideTargetHttpsProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_quic_override();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_ssl_certificates method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetHttpsProxies', 'Correct service path');
        is($args->{method}, 'SetSslCertificates', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetSslCertificatesTargetHttpsProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_ssl_certificates();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_ssl_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetHttpsProxies', 'Correct service path');
        is($args->{method}, 'SetSslPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetSslPolicyTargetHttpsProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_ssl_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_health_check method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetPools', 'Correct service path');
        is($args->{method}, 'AddHealthCheck', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddHealthCheckTargetPoolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_health_check();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'add_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetPools', 'Correct service path');
        is($args->{method}, 'AddInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::AddInstanceTargetPoolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_health_check method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetPools', 'Correct service path');
        is($args->{method}, 'RemoveHealthCheck', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemoveHealthCheckTargetPoolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_health_check();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'remove_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetPools', 'Correct service path');
        is($args->{method}, 'RemoveInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::RemoveInstanceTargetPoolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->remove_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_backup method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetPools', 'Correct service path');
        is($args->{method}, 'SetBackup', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetBackupTargetPoolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_backup();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_backend_service method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetSslProxies', 'Correct service path');
        is($args->{method}, 'SetBackendService', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetBackendServiceTargetSslProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_backend_service();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_proxy_header method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.TargetSslProxies', 'Correct service path');
        is($args->{method}, 'SetProxyHeader', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetProxyHeaderTargetSslProxyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_proxy_header();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'invalidate_cache method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.UrlMaps', 'Correct service path');
        is($args->{method}, 'InvalidateCache', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::InvalidateCacheUrlMapRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->invalidate_cache();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'validate method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.UrlMaps', 'Correct service path');
        is($args->{method}, 'Validate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ValidateUrlMapRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::UrlMapsValidateResponse'->new();
        return $response;
    };
    
    my $res = $client->validate();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::UrlMapsValidateResponse', 'Response object class');
    done_testing();
};

subtest 'get_status method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.VpnGateways', 'Correct service path');
        is($args->{method}, 'GetStatus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetStatusVpnGatewayRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::VpnGatewaysGetStatusResponse'->new();
        return $response;
    };
    
    my $res = $client->get_status();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::VpnGatewaysGetStatusResponse', 'Response object class');
    done_testing();
};

done_testing();
