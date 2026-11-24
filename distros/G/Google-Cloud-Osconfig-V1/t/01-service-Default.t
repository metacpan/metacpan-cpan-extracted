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
    for my $pkg (qw( Google::Cloud::Osconfig::V1::Inventory::ListInventoriesResponse Google::Cloud::Osconfig::V1::PatchJobs::PatchJob Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Osconfig::V1;

my $client = Google::Cloud::Osconfig::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'execute_patch_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.v1.OsConfigService', 'Correct service path');
        is($args->{method}, 'ExecutePatchJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::V1::PatchJobs::ExecutePatchJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::V1::PatchJobs::PatchJob'->new();
        return $response;
    };
    
    my $res = $client->execute_patch_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::V1::PatchJobs::PatchJob', 'Response object class');
    done_testing();
};

subtest 'create_ospolicy_assignment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.v1.OsConfigZonalService', 'Correct service path');
        is($args->{method}, 'CreateOSPolicyAssignment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_ospolicy_assignment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_inventories method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.v1.OsConfigZonalService', 'Correct service path');
        is($args->{method}, 'ListInventories', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::V1::Inventory::ListInventoriesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::V1::Inventory::ListInventoriesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_inventories();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::V1::Inventory::ListInventoriesResponse', 'Response object class');
    done_testing();
};

subtest 'list_vulnerability_reports method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.osconfig.v1.OsConfigZonalService', 'Correct service path');
        is($args->{method}, 'ListVulnerabilityReports', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_vulnerability_reports();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsResponse', 'Response object class');
    done_testing();
};

done_testing();
