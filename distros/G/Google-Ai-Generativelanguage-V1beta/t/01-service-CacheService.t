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
    for my $pkg (qw( Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Ai::Generativelanguage::V1beta::CacheServiceClient;

my $client = Google::Ai::Generativelanguage::V1beta::CacheServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_cached_contents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'ListCachedContents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_cached_contents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse', 'Response object class');
    done_testing();
};

subtest 'create_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'CreateCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new();
        return $response;
    };
    
    my $res = $client->create_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent', 'Response object class');
    done_testing();
};

subtest 'get_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'GetCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new();
        return $response;
    };
    
    my $res = $client->get_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent', 'Response object class');
    done_testing();
};

subtest 'update_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'UpdateCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new();
        return $response;
    };
    
    my $res = $client->update_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent', 'Response object class');
    done_testing();
};

subtest 'delete_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'DeleteCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
