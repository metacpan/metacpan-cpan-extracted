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
    for my $pkg (qw( Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient;

my $client = Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'batch_create_metastore_partitions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService', 'Correct service path');
        is($args->{method}, 'BatchCreateMetastorePartitions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_create_metastore_partitions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse', 'Response object class');
    done_testing();
};

subtest 'stream_metastore_partitions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService', 'Correct service path');
        is($args->{method}, 'StreamMetastorePartitions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_metastore_partitions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse', 'Response object class');
    done_testing();
};

done_testing();
