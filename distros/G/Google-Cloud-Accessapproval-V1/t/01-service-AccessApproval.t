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
    for my $pkg (qw( Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalServiceAccount Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalSettings Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Accessapproval::V1::AccessApprovalClient;

my $client = Google::Cloud::Accessapproval::V1::AccessApprovalClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_approval_requests method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.accessapproval.v1.AccessApproval', 'Correct service path');
        is($args->{method}, 'ListApprovalRequests', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsMessage', 'Request object');
        
        my $response = 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_approval_requests();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsResponse', 'Response object class');
    done_testing();
};

subtest 'update_access_approval_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.accessapproval.v1.AccessApproval', 'Correct service path');
        is($args->{method}, 'UpdateAccessApprovalSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Accessapproval::V1::Accessapproval::UpdateAccessApprovalSettingsMessage', 'Request object');
        
        my $response = 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalSettings'->new();
        return $response;
    };
    
    my $res = $client->update_access_approval_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalSettings', 'Response object class');
    done_testing();
};

subtest 'get_access_approval_service_account method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.accessapproval.v1.AccessApproval', 'Correct service path');
        is($args->{method}, 'GetAccessApprovalServiceAccount', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalServiceAccountMessage', 'Request object');
        
        my $response = 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalServiceAccount'->new();
        return $response;
    };
    
    my $res = $client->get_access_approval_service_account();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalServiceAccount', 'Response object class');
    done_testing();
};

done_testing();
