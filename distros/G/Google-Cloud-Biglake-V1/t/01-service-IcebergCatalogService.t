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
    for my $pkg (qw( Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Biglake::V1::IcebergCatalogServiceClient;

my $client = Google::Cloud::Biglake::V1::IcebergCatalogServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_iceberg_catalog_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.biglake.v1.IcebergCatalogService', 'Correct service path');
        is($args->{method}, 'GetIcebergCatalogConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig'->new();
        return $response;
    };
    
    my $res = $client->get_iceberg_catalog_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig', 'Response object class');
    done_testing();
};

subtest 'list_iceberg_namespaces method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.biglake.v1.IcebergCatalogService', 'Correct service path');
        is($args->{method}, 'ListIcebergNamespaces', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_iceberg_namespaces();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesResponse', 'Response object class');
    done_testing();
};

done_testing();
