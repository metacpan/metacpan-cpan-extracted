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
    for my $pkg (qw( Google::Cloud::Bigquery::V2::Dataset::Dataset Google::Cloud::Bigquery::V2::Dataset::DatasetList Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigquery::V2::DatasetServiceClient;

my $client = Google::Cloud::Bigquery::V2::DatasetServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'GetDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->get_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'insert_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'InsertDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->insert_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'patch_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'PatchDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->patch_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'update_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'UpdateDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->update_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'delete_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'DeleteDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_datasets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'ListDatasets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::DatasetList'->new();
        return $response;
    };
    
    my $res = $client->list_datasets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::DatasetList', 'Response object class');
    done_testing();
};

subtest 'undelete_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'UndeleteDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->undelete_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

done_testing();
