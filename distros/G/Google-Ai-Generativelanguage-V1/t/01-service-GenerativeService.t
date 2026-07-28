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
    for my $pkg (qw( Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Ai::Generativelanguage::V1::GenerativeServiceClient;

my $client = Google::Ai::Generativelanguage::V1::GenerativeServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'generate_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1.GenerativeService', 'Correct service path');
        is($args->{method}, 'GenerateContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse', 'Response object class');
    done_testing();
};

subtest 'stream_generate_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1.GenerativeService', 'Correct service path');
        is($args->{method}, 'StreamGenerateContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_generate_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse', 'Response object class');
    done_testing();
};

subtest 'embed_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1.GenerativeService', 'Correct service path');
        is($args->{method}, 'EmbedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse'->new();
        return $response;
    };
    
    my $res = $client->embed_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse', 'Response object class');
    done_testing();
};

subtest 'batch_embed_contents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1.GenerativeService', 'Correct service path');
        is($args->{method}, 'BatchEmbedContents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_embed_contents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse', 'Response object class');
    done_testing();
};

subtest 'count_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1.GenerativeService', 'Correct service path');
        is($args->{method}, 'CountTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse', 'Response object class');
    done_testing();
};

done_testing();
