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
    for my $pkg (qw( Google::Cloud::Apihub::V1::CommonFields::Api Google::Cloud::Apihub::V1::CurateService::Curation Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration Google::Cloud::Apihub::V1::LintingService::StyleGuide Google::Cloud::Apihub::V1::LintingService::StyleGuideContents Google::Cloud::Apihub::V1::PluginService::Plugin Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Apihub::V1;

my $client = Google::Cloud::Apihub::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_api method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.ApiHub', 'Correct service path');
        is($args->{method}, 'CreateApi', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::ApihubService::CreateApiRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::CommonFields::Api'->new();
        return $response;
    };
    
    my $res = $client->create_api();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::CommonFields::Api', 'Response object class');
    done_testing();
};

subtest 'collect_api_data method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.ApiHubCollect', 'Correct service path');
        is($args->{method}, 'CollectApiData', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->collect_api_data();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_curation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.ApiHubCurate', 'Correct service path');
        is($args->{method}, 'CreateCuration', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::CurateService::Curation'->new();
        return $response;
    };
    
    my $res = $client->create_curation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::CurateService::Curation', 'Response object class');
    done_testing();
};

subtest 'list_discovered_api_observations method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.ApiHubDiscovery', 'Correct service path');
        is($args->{method}, 'ListDiscoveredApiObservations', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_discovered_api_observations();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse', 'Response object class');
    done_testing();
};

subtest 'create_host_project_registration method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.HostProjectRegistrationService', 'Correct service path');
        is($args->{method}, 'CreateHostProjectRegistration', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::CreateHostProjectRegistrationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration'->new();
        return $response;
    };
    
    my $res = $client->create_host_project_registration();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::HostProjectRegistrationService::HostProjectRegistration', 'Response object class');
    done_testing();
};

subtest 'get_style_guide method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.LintingService', 'Correct service path');
        is($args->{method}, 'GetStyleGuide', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::LintingService::StyleGuide'->new();
        return $response;
    };
    
    my $res = $client->get_style_guide();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::LintingService::StyleGuide', 'Response object class');
    done_testing();
};

subtest 'get_style_guide_contents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.LintingService', 'Correct service path');
        is($args->{method}, 'GetStyleGuideContents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::LintingService::StyleGuideContents'->new();
        return $response;
    };
    
    my $res = $client->get_style_guide_contents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::LintingService::StyleGuideContents', 'Response object class');
    done_testing();
};

subtest 'get_plugin method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.ApiHubPlugin', 'Correct service path');
        is($args->{method}, 'GetPlugin', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::PluginService::GetPluginRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::PluginService::Plugin'->new();
        return $response;
    };
    
    my $res = $client->get_plugin();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::PluginService::Plugin', 'Response object class');
    done_testing();
};

subtest 'create_api_hub_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.Provisioning', 'Correct service path');
        is($args->{method}, 'CreateApiHubInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_api_hub_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_runtime_project_attachment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apihub.v1.RuntimeProjectAttachmentService', 'Correct service path');
        is($args->{method}, 'CreateRuntimeProjectAttachment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment'->new();
        return $response;
    };
    
    my $res = $client->create_runtime_project_attachment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment', 'Response object class');
    done_testing();
};

done_testing();
