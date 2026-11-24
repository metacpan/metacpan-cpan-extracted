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
    for my $pkg (qw( Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig Google::Cloud::Recommender::V1::RecommenderService::ListInsightsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Recommender::V1;

my $client = Google::Cloud::Recommender::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_insights method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.recommender.v1.Recommender', 'Correct service path');
        is($args->{method}, 'ListInsights', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Recommender::V1::RecommenderService::ListInsightsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Recommender::V1::RecommenderService::ListInsightsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_insights();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Recommender::V1::RecommenderService::ListInsightsResponse', 'Response object class');
    done_testing();
};

subtest 'update_recommender_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.recommender.v1.Recommender', 'Correct service path');
        is($args->{method}, 'UpdateRecommenderConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Recommender::V1::RecommenderService::UpdateRecommenderConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig'->new();
        return $response;
    };
    
    my $res = $client->update_recommender_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig', 'Response object class');
    done_testing();
};

subtest 'update_insight_type_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.recommender.v1.Recommender', 'Correct service path');
        is($args->{method}, 'UpdateInsightTypeConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Recommender::V1::RecommenderService::UpdateInsightTypeConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig'->new();
        return $response;
    };
    
    my $res = $client->update_insight_type_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig', 'Response object class');
    done_testing();
};

done_testing();
