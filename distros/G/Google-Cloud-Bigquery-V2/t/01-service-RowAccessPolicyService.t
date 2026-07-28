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
    for my $pkg (qw( Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient;

my $client = Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_row_access_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'ListRowAccessPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_row_access_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'get_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'GetRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new();
        return $response;
    };
    
    my $res = $client->get_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy', 'Response object class');
    done_testing();
};

subtest 'create_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'CreateRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new();
        return $response;
    };
    
    my $res = $client->create_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy', 'Response object class');
    done_testing();
};

subtest 'update_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'UpdateRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new();
        return $response;
    };
    
    my $res = $client->update_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy', 'Response object class');
    done_testing();
};

subtest 'delete_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'DeleteRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'batch_delete_row_access_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'BatchDeleteRowAccessPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->batch_delete_row_access_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
