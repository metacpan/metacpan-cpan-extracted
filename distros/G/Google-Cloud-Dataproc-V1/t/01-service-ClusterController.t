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
    for my $pkg (qw( Google::Cloud::Dataproc::V1::Clusters::Cluster Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataproc::V1::ClusterControllerClient;

my $client = Google::Cloud::Dataproc::V1::ClusterControllerClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'CreateCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'UpdateCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'StopCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'start_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'StartCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'DeleteCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'GetCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Clusters::Cluster'->new();
        return $response;
    };
    
    my $res = $client->get_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Clusters::Cluster', 'Response object class');
    done_testing();
};

subtest 'list_clusters method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'ListClusters', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_clusters();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse', 'Response object class');
    done_testing();
};

subtest 'diagnose_cluster method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataproc.v1.ClusterController', 'Correct service path');
        is($args->{method}, 'DiagnoseCluster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->diagnose_cluster();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
