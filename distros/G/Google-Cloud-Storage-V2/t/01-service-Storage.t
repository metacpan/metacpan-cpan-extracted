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
    for my $pkg (qw( Google::Iam::V1::Policy::Policy Google::Protobuf::Empty::Empty Google::Storage::V2::Storage::Bucket Google::Storage::V2::Storage::ListBucketsResponse Google::Storage::V2::Storage::Object )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Storage::V2::StorageClient;

my $client = Google::Cloud::Storage::V2::StorageClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'delete_bucket method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
        is($args->{method}, 'DeleteBucket', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storage::V2::Storage::DeleteBucketRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_bucket();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'get_bucket method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
        is($args->{method}, 'GetBucket', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storage::V2::Storage::GetBucketRequest', 'Request object');
        
        my $response = 'Google::Storage::V2::Storage::Bucket'->new();
        return $response;
    };
    
    my $res = $client->get_bucket();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storage::V2::Storage::Bucket', 'Response object class');
    done_testing();
};

subtest 'create_bucket method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
        is($args->{method}, 'CreateBucket', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storage::V2::Storage::CreateBucketRequest', 'Request object');
        
        my $response = 'Google::Storage::V2::Storage::Bucket'->new();
        return $response;
    };
    
    my $res = $client->create_bucket();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storage::V2::Storage::Bucket', 'Response object class');
    done_testing();
};

subtest 'list_buckets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
        is($args->{method}, 'ListBuckets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storage::V2::Storage::ListBucketsRequest', 'Request object');
        
        my $response = 'Google::Storage::V2::Storage::ListBucketsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_buckets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storage::V2::Storage::ListBucketsResponse', 'Response object class');
    done_testing();
};

subtest 'lock_bucket_retention_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
        is($args->{method}, 'LockBucketRetentionPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storage::V2::Storage::LockBucketRetentionPolicyRequest', 'Request object');
        
        my $response = 'Google::Storage::V2::Storage::Bucket'->new();
        return $response;
    };
    
    my $res = $client->lock_bucket_retention_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storage::V2::Storage::Bucket', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
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

subtest 'move_object method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storage.v2.Storage', 'Correct service path');
        is($args->{method}, 'MoveObject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storage::V2::Storage::MoveObjectRequest', 'Request object');
        
        my $response = 'Google::Storage::V2::Storage::Object'->new();
        return $response;
    };
    
    my $res = $client->move_object();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storage::V2::Storage::Object', 'Response object class');
    done_testing();
};

done_testing();
