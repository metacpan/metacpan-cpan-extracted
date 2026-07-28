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
    for my $pkg (qw( Google::Cloud::Compute::V1::Compute::BackendBucket Google::Cloud::Compute::V1::Compute::BackendBucketAggregatedList Google::Cloud::Compute::V1::Compute::BackendBucketList Google::Cloud::Compute::V1::Compute::BackendBucketListUsable Google::Cloud::Compute::V1::Compute::Operation Google::Cloud::Compute::V1::Compute::Policy Google::Cloud::Compute::V1::Compute::TestPermissionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Compute::V1::BackendBucketsClient;

my $client = Google::Cloud::Compute::V1::BackendBucketsClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'add_signed_url_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'AddSignedUrlKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::AddSignedUrlKeyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_signed_url_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'aggregated_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'AggregatedList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::AggregatedListBackendBucketsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::BackendBucketAggregatedList'->new();
        return $response;
    };
    
    my $res = $client->aggregated_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::BackendBucketAggregatedList', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_signed_url_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'DeleteSignedUrlKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::DeleteSignedUrlKeyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_signed_url_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::BackendBucket'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::BackendBucket', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::GetIamPolicyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::InsertBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListBackendBucketsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::BackendBucketList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::BackendBucketList', 'Response object class');
    done_testing();
};

subtest 'list_usable method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'ListUsable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::ListUsableBackendBucketsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::BackendBucketListUsable'->new();
        return $response;
    };
    
    my $res = $client->list_usable();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::BackendBucketListUsable', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::PatchBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_edge_security_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'SetEdgeSecurityPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::SetEdgeSecurityPolicyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_edge_security_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::SetIamPolicyBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Policy', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'update method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.compute.v1.BackendBuckets', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Compute::V1::Compute::UpdateBackendBucketRequest', 'Request object');
        
        my $response = 'Google::Cloud::Compute::V1::Compute::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Compute::V1::Compute::Operation', 'Response object class');
    done_testing();
};

done_testing();
