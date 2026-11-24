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
    for my $pkg (qw( Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Cloudsecuritycompliance::V1;

my $client = Google::Cloud::Cloudsecuritycompliance::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'generate_framework_audit_scope_report method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.cloudsecuritycompliance.v1.Audit', 'Correct service path');
        is($args->{method}, 'GenerateFrameworkAuditScopeReport', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportRequest', 'Request object');
        
        my $response = 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_framework_audit_scope_report();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse', 'Response object class');
    done_testing();
};

subtest 'update_cm_enrollment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService', 'Correct service path');
        is($args->{method}, 'UpdateCmEnrollment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment'->new();
        return $response;
    };
    
    my $res = $client->update_cm_enrollment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment', 'Response object class');
    done_testing();
};

subtest 'calculate_effective_cm_enrollment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.cloudsecuritycompliance.v1.CmEnrollmentService', 'Correct service path');
        is($args->{method}, 'CalculateEffectiveCmEnrollment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse'->new();
        return $response;
    };
    
    my $res = $client->calculate_effective_cm_enrollment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse', 'Response object class');
    done_testing();
};

subtest 'list_frameworks method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.cloudsecuritycompliance.v1.Config', 'Correct service path');
        is($args->{method}, 'ListFrameworks', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse'->new();
        return $response;
    };
    
    my $res = $client->list_frameworks();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse', 'Response object class');
    done_testing();
};

subtest 'create_framework_deployment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.cloudsecuritycompliance.v1.Deployment', 'Correct service path');
        is($args->{method}, 'CreateFrameworkDeployment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Cloudsecuritycompliance::V1::Deployment::CreateFrameworkDeploymentRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_framework_deployment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_framework_compliance_summaries method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.cloudsecuritycompliance.v1.Monitoring', 'Correct service path');
        is($args->{method}, 'ListFrameworkComplianceSummaries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_framework_compliance_summaries();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse', 'Response object class');
    done_testing();
};

done_testing();
