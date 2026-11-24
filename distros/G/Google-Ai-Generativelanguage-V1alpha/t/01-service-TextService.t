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
    for my $pkg (qw( Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Ai::Generativelanguage::V1alpha::TextServiceClient;

my $client = Google::Ai::Generativelanguage::V1alpha::TextServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'generate_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.TextService', 'Correct service path');
        is($args->{method}, 'GenerateText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse', 'Response object class');
    done_testing();
};

subtest 'embed_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.TextService', 'Correct service path');
        is($args->{method}, 'EmbedText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse'->new();
        return $response;
    };
    
    my $res = $client->embed_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse', 'Response object class');
    done_testing();
};

subtest 'batch_embed_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.TextService', 'Correct service path');
        is($args->{method}, 'BatchEmbedText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_embed_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse', 'Response object class');
    done_testing();
};

subtest 'count_text_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.TextService', 'Correct service path');
        is($args->{method}, 'CountTextTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_text_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse', 'Response object class');
    done_testing();
};

done_testing();
