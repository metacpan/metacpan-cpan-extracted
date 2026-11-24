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
    for my $pkg (qw( Google::Cloud::Iap::V1::Service::IapSettings Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse Google::Iam::V1::IamPolicy::TestIamPermissionsResponse Google::Iam::V1::Policy::Policy )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient;

my $client = Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'get_iap_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'GetIapSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Iap::V1::Service::GetIapSettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Iap::V1::Service::IapSettings'->new();
        return $response;
    };
    
    my $res = $client->get_iap_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Iap::V1::Service::IapSettings', 'Response object class');
    done_testing();
};

subtest 'update_iap_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'UpdateIapSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Iap::V1::Service::UpdateIapSettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Iap::V1::Service::IapSettings'->new();
        return $response;
    };
    
    my $res = $client->update_iap_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Iap::V1::Service::IapSettings', 'Response object class');
    done_testing();
};

subtest 'validate_iap_attribute_expression method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'ValidateIapAttributeExpression', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse'->new();
        return $response;
    };
    
    my $res = $client->validate_iap_attribute_expression();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Iap::V1::Service::ValidateIapAttributeExpressionResponse', 'Response object class');
    done_testing();
};

subtest 'list_tunnel_dest_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.iap.v1.IdentityAwareProxyAdminService', 'Correct service path');
        is($args->{method}, 'ListTunnelDestGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tunnel_dest_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Iap::V1::Service::ListTunnelDestGroupsResponse', 'Response object class');
    done_testing();
};

done_testing();
