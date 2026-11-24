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
    for my $pkg (qw( Google::Cloud::Compute::V1beta::Compute::FirewallPoliciesListAssociationsResponse Google::Cloud::Compute::V1beta::Compute::FirewallPolicy Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation Google::Cloud::Compute::V1beta::Compute::FirewallPolicyList Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule Google::Cloud::Compute::V1beta::Compute::Operation Google::Cloud::Compute::V1beta::Compute::Policy Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1beta::FirewallPoliciesClient;

my $client = Google::Cloud::Compute::V1beta::FirewallPoliciesClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::DeleteFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicy'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicy', 'Response object class');
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

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::GetIamPolicyFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Policy', 'Response object class');
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

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::InsertFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::ListFirewallPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyList', 'Response object class');
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

subtest 'move method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'Move', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::MoveFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->move();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::PatchFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Operation', 'Response object class');
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

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::SetIamPolicyFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1beta.FirewallPolicies', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsFirewallPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

done_testing();
