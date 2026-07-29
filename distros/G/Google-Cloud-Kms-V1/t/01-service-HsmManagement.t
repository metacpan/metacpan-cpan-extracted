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
    for my $pkg (qw( Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Kms::HsmManagementClient;

my $client = Google::Cloud::Kms::HsmManagementClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_single_tenant_hsm_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.kms.v1.HsmManagement', 'Correct service path');
        is($args->{method}, 'ListSingleTenantHsmInstances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_single_tenant_hsm_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse', 'Response object class');
    done_testing();
};

done_testing();
