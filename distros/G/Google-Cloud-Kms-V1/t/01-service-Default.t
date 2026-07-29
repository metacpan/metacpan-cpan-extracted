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
    for my $pkg (qw( Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsResponse Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse Google::Cloud::Kms::V1::Service::ListKeyRingsResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Kms::V1;

my $client = Google::Cloud::Kms::V1->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_key_rings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.KeyManagementService', 'Correct service path');
        is($args->{method}, 'ListKeyRings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::Service::ListKeyRingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::Service::ListKeyRingsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_key_rings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::Service::ListKeyRingsResponse', 'Response object class');
    done_testing();
};

subtest 'create_key_handle method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.Autokey', 'Correct service path');
        is($args->{method}, 'CreateKeyHandle', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::Autokey::CreateKeyHandleRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_key_handle();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_ekm_connections method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.EkmService', 'Correct service path');
        is($args->{method}, 'ListEkmConnections', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_ekm_connections();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsResponse', 'Response object class');
    done_testing();
};

subtest 'update_autokey_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.AutokeyAdmin', 'Correct service path');
        is($args->{method}, 'UpdateAutokeyConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig'->new();
        return $response;
    };
    
    my $res = $client->update_autokey_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig', 'Response object class');
    done_testing();
};

subtest 'get_autokey_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.AutokeyAdmin', 'Correct service path');
        is($args->{method}, 'GetAutokeyConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig'->new();
        return $response;
    };
    
    my $res = $client->get_autokey_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig', 'Response object class');
    done_testing();
};

subtest 'show_effective_autokey_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.AutokeyAdmin', 'Correct service path');
        is($args->{method}, 'ShowEffectiveAutokeyConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse'->new();
        return $response;
    };
    
    my $res = $client->show_effective_autokey_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse', 'Response object class');
    done_testing();
};

subtest 'list_single_tenant_hsm_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.HsmManagement', 'Correct service path');
        is($args->{method}, 'ListSingleTenantHsmInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_single_tenant_hsm_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse', 'Response object class');
    done_testing();
};

done_testing();
