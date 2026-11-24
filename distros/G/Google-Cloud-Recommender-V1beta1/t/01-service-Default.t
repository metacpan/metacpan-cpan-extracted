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
    for my $pkg (qw( Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesResponse Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsResponse Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Recommender::V1beta1;

my $client = Google::Cloud::Recommender::V1beta1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_insights method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.recommender.v1beta1.Recommender', 'Correct service path');
        is($args->{method}, 'ListInsights', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_insights();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsResponse', 'Response object class');
    done_testing();
};

subtest 'list_recommenders method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.recommender.v1beta1.Recommender', 'Correct service path');
        is($args->{method}, 'ListRecommenders', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_recommenders();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersResponse', 'Response object class');
    done_testing();
};

subtest 'list_insight_types method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.recommender.v1beta1.Recommender', 'Correct service path');
        is($args->{method}, 'ListInsightTypes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_insight_types();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesResponse', 'Response object class');
    done_testing();
};

done_testing();
