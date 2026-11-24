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
    for my $pkg (qw( Google::Cloud::Retail::V2::Catalog::AttributesConfig Google::Cloud::Retail::V2::Catalog::CompletionConfig Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Retail::V2::CatalogServiceClient;

my $client = Google::Cloud::Retail::V2::CatalogServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_catalogs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'ListCatalogs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_catalogs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse', 'Response object class');
    done_testing();
};

subtest 'update_completion_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateCompletionConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Catalog::CompletionConfig'->new();
        return $response;
    };
    
    my $res = $client->update_completion_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Catalog::CompletionConfig', 'Response object class');
    done_testing();
};

subtest 'update_attributes_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateAttributesConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->update_attributes_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'remove_catalog_attribute method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'RemoveCatalogAttribute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->remove_catalog_attribute();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

done_testing();
