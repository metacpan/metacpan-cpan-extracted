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
    for my $pkg (qw( Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesResponse Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentResponse Google::Cloud::Language::V2::LanguageService::AnnotateTextResponse Google::Cloud::Language::V2::LanguageService::ClassifyTextResponse Google::Cloud::Language::V2::LanguageService::ModerateTextResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Language::V2::LanguageServiceClient;

my $client = Google::Cloud::Language::V2::LanguageServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'analyze_sentiment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.language.v2.LanguageService', 'Correct service path');
        is($args->{method}, 'AnalyzeSentiment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentResponse'->new();
        return $response;
    };
    
    my $res = $client->analyze_sentiment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentResponse', 'Response object class');
    done_testing();
};

subtest 'analyze_entities method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.language.v2.LanguageService', 'Correct service path');
        is($args->{method}, 'AnalyzeEntities', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesResponse'->new();
        return $response;
    };
    
    my $res = $client->analyze_entities();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesResponse', 'Response object class');
    done_testing();
};

subtest 'classify_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.language.v2.LanguageService', 'Correct service path');
        is($args->{method}, 'ClassifyText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Language::V2::LanguageService::ClassifyTextRequest', 'Request object');
        
        my $response = 'Google::Cloud::Language::V2::LanguageService::ClassifyTextResponse'->new();
        return $response;
    };
    
    my $res = $client->classify_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Language::V2::LanguageService::ClassifyTextResponse', 'Response object class');
    done_testing();
};

subtest 'moderate_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.language.v2.LanguageService', 'Correct service path');
        is($args->{method}, 'ModerateText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Language::V2::LanguageService::ModerateTextRequest', 'Request object');
        
        my $response = 'Google::Cloud::Language::V2::LanguageService::ModerateTextResponse'->new();
        return $response;
    };
    
    my $res = $client->moderate_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Language::V2::LanguageService::ModerateTextResponse', 'Response object class');
    done_testing();
};

subtest 'annotate_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.language.v2.LanguageService', 'Correct service path');
        is($args->{method}, 'AnnotateText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest', 'Request object');
        
        my $response = 'Google::Cloud::Language::V2::LanguageService::AnnotateTextResponse'->new();
        return $response;
    };
    
    my $res = $client->annotate_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Language::V2::LanguageService::AnnotateTextResponse', 'Response object class');
    done_testing();
};

done_testing();
