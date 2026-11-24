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
    for my $pkg (qw( Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse Google::Cloud::Securitycenter::V1::Source::Source Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Securitycenter::V1::SecurityCenterClient;

my $client = Google::Cloud::Securitycenter::V1::SecurityCenterClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'bulk_mute_findings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'BulkMuteFindings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BulkMuteFindingsRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->bulk_mute_findings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_source method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'CreateSource', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateSourceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::Source::Source'->new();
        return $response;
    };
    
    my $res = $client->create_source();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::Source::Source', 'Response object class');
    done_testing();
};

subtest 'get_effective_security_health_analytics_custom_module method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'GetEffectiveSecurityHealthAnalyticsCustomModule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule'->new();
        return $response;
    };
    
    my $res = $client->get_effective_security_health_analytics_custom_module();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule', 'Response object class');
    done_testing();
};

subtest 'list_findings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'ListFindings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_findings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListFindingsResponse', 'Response object class');
    done_testing();
};

subtest 'list_security_health_analytics_custom_modules method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'ListSecurityHealthAnalyticsCustomModules', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_security_health_analytics_custom_modules();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListSecurityHealthAnalyticsCustomModulesResponse', 'Response object class');
    done_testing();
};

subtest 'update_external_system method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'UpdateExternalSystem', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateExternalSystemRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem'->new();
        return $response;
    };
    
    my $res = $client->update_external_system();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::ExternalSystem::ExternalSystem', 'Response object class');
    done_testing();
};

subtest 'update_security_health_analytics_custom_module method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'UpdateSecurityHealthAnalyticsCustomModule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::UpdateSecurityHealthAnalyticsCustomModuleRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule'->new();
        return $response;
    };
    
    my $res = $client->update_security_health_analytics_custom_module();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule', 'Response object class');
    done_testing();
};

subtest 'create_big_query_export method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'CreateBigQueryExport', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::CreateBigQueryExportRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport'->new();
        return $response;
    };
    
    my $res = $client->create_big_query_export();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::BigqueryExport::BigQueryExport', 'Response object class');
    done_testing();
};

subtest 'delete_event_threat_detection_custom_module method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'DeleteEventThreatDetectionCustomModule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::DeleteEventThreatDetectionCustomModuleRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_event_threat_detection_custom_module();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_event_threat_detection_custom_modules method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'ListEventThreatDetectionCustomModules', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_event_threat_detection_custom_modules();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::ListEventThreatDetectionCustomModulesResponse', 'Response object class');
    done_testing();
};

subtest 'get_effective_event_threat_detection_custom_module method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'GetEffectiveEventThreatDetectionCustomModule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::GetEffectiveEventThreatDetectionCustomModuleRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule'->new();
        return $response;
    };
    
    my $res = $client->get_effective_event_threat_detection_custom_module();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule', 'Response object class');
    done_testing();
};

subtest 'batch_create_resource_value_configs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.securitycenter.v1.SecurityCenter', 'Correct service path');
        is($args->{method}, 'BatchCreateResourceValueConfigs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_create_resource_value_configs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Securitycenter::V1::SecuritycenterService::BatchCreateResourceValueConfigsResponse', 'Response object class');
    done_testing();
};

done_testing();
