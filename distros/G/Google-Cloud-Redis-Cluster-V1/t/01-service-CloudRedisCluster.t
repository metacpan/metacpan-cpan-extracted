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
    for my $pkg (qw( Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::ListClustersResponse Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::SharedRegionalCertificateAuthority Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Redis::Cluster::V1::CloudRedisClusterClient;

my $client = Google::Cloud::Redis::Cluster::V1::CloudRedisClusterClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_clusters method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.redis.cluster.v1.CloudRedisCluster', 'Correct service path');
        is($args->{method}, 'ListClusters', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::ListClustersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::ListClustersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_clusters();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::ListClustersResponse', 'Response object class');
    done_testing();
};

subtest 'get_shared_regional_certificate_authority method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.redis.cluster.v1.CloudRedisCluster', 'Correct service path');
        is($args->{method}, 'GetSharedRegionalCertificateAuthority', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::GetSharedRegionalCertificateAuthorityRequest', 'Request object');
        
        my $response = 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::SharedRegionalCertificateAuthority'->new();
        return $response;
    };
    
    my $res = $client->get_shared_regional_certificate_authority();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::SharedRegionalCertificateAuthority', 'Response object class');
    done_testing();
};

subtest 'reschedule_cluster_maintenance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.redis.cluster.v1.CloudRedisCluster', 'Correct service path');
        is($args->{method}, 'RescheduleClusterMaintenance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Redis::Cluster::V1::CloudRedisCluster::RescheduleClusterMaintenanceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->reschedule_cluster_maintenance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
