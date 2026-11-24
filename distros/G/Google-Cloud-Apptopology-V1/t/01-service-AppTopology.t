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
    for my $pkg (qw( Google::Cloud::Apptopology::V1::Schema::Domain Google::Cloud::Apptopology::V1::Schema::Schema Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Apptopology::V1::AppTopologyClient;

my $client = Google::Cloud::Apptopology::V1::AppTopologyClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'generate_discovered_resources_topology method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apptopology.v1.AppTopology', 'Correct service path');
        is($args->{method}, 'GenerateDiscoveredResourcesTopology', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_discovered_resources_topology();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse', 'Response object class');
    done_testing();
};

subtest 'get_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apptopology.v1.AppTopology', 'Correct service path');
        is($args->{method}, 'GetSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apptopology::V1::Service::GetSchemaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apptopology::V1::Schema::Schema'->new();
        return $response;
    };
    
    my $res = $client->get_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apptopology::V1::Schema::Schema', 'Response object class');
    done_testing();
};

subtest 'get_domain method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.apptopology.v1.AppTopology', 'Correct service path');
        is($args->{method}, 'GetDomain', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Apptopology::V1::Service::GetDomainRequest', 'Request object');
        
        my $response = 'Google::Cloud::Apptopology::V1::Schema::Domain'->new();
        return $response;
    };
    
    my $res = $client->get_domain();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Apptopology::V1::Schema::Domain', 'Response object class');
    done_testing();
};

done_testing();
