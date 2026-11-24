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
    for my $pkg (qw( Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse Google::Cloud::Dataqna::V1alpha::Question::Question Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dataqna::V1alpha;

my $client = Google::Cloud::Dataqna::V1alpha->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'suggest_queries method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataqna.v1alpha.AutoSuggestionService', 'Correct service path');
        is($args->{method}, 'SuggestQueries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse'->new();
        return $response;
    };
    
    my $res = $client->suggest_queries();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse', 'Response object class');
    done_testing();
};

subtest 'get_question method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataqna.v1alpha.QuestionService', 'Correct service path');
        is($args->{method}, 'GetQuestion', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataqna::V1alpha::Question::Question'->new();
        return $response;
    };
    
    my $res = $client->get_question();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataqna::V1alpha::Question::Question', 'Response object class');
    done_testing();
};

subtest 'update_user_feedback method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dataqna.v1alpha.QuestionService', 'Correct service path');
        is($args->{method}, 'UpdateUserFeedback', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback'->new();
        return $response;
    };
    
    my $res = $client->update_user_feedback();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dataqna::V1alpha::UserFeedback::UserFeedback', 'Response object class');
    done_testing();
};

done_testing();
