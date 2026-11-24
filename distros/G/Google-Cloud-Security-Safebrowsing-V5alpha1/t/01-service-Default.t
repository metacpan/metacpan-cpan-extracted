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
    for my $pkg (qw( Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsResponse Google::Security::Safebrowsing::V5alpha1::Safebrowsing::HashList Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsResponse Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Security::Safebrowsing::V5alpha1;

my $client = Google::Cloud::Security::Safebrowsing::V5alpha1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'search_hashes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.security.safebrowsing.v5alpha1.SafeBrowsing', 'Correct service path');
        is($args->{method}, 'SearchHashes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesRequest', 'Request object');
        
        my $response = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesResponse'->new();
        return $response;
    };
    
    my $res = $client->search_hashes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesResponse', 'Response object class');
    done_testing();
};

subtest 'get_hash_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.security.safebrowsing.v5alpha1.SafeBrowsing', 'Correct service path');
        is($args->{method}, 'GetHashList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::GetHashListRequest', 'Request object');
        
        my $response = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::HashList'->new();
        return $response;
    };
    
    my $res = $client->get_hash_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::HashList', 'Response object class');
    done_testing();
};

subtest 'list_hash_lists method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.security.safebrowsing.v5alpha1.SafeBrowsing', 'Correct service path');
        is($args->{method}, 'ListHashLists', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsRequest', 'Request object');
        
        my $response = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_hash_lists();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsResponse', 'Response object class');
    done_testing();
};

subtest 'batch_get_hash_lists method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.security.safebrowsing.v5alpha1.SafeBrowsing', 'Correct service path');
        is($args->{method}, 'BatchGetHashLists', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsRequest', 'Request object');
        
        my $response = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_get_hash_lists();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsResponse', 'Response object class');
    done_testing();
};

done_testing();
