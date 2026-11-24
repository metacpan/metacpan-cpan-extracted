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
    for my $pkg (qw( Google::Protobuf::Empty::Empty Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse Google::Pubsub::V1beta2::Pubsub::PublishResponse Google::Pubsub::V1beta2::Pubsub::PullResponse Google::Pubsub::V1beta2::Pubsub::Subscription Google::Pubsub::V1beta2::Pubsub::Topic )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Pubsub::V1beta2;

my $client = Google::Cloud::Pubsub::V1beta2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_subscription method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'CreateSubscription', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::Subscription', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::Subscription'->new();
        return $response;
    };
    
    my $res = $client->create_subscription();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::Subscription', 'Response object class');
    done_testing();
};

subtest 'get_subscription method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'GetSubscription', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::Subscription'->new();
        return $response;
    };
    
    my $res = $client->get_subscription();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::Subscription', 'Response object class');
    done_testing();
};

subtest 'list_subscriptions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'ListSubscriptions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_subscriptions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse', 'Response object class');
    done_testing();
};

subtest 'delete_subscription method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'DeleteSubscription', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_subscription();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'modify_ack_deadline method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'ModifyAckDeadline', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->modify_ack_deadline();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'acknowledge method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'Acknowledge', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->acknowledge();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'pull method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'Pull', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::PullRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::PullResponse'->new();
        return $response;
    };
    
    my $res = $client->pull();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::PullResponse', 'Response object class');
    done_testing();
};

subtest 'modify_push_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Subscriber', 'Correct service path');
        is($args->{method}, 'ModifyPushConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->modify_push_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'create_topic method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Publisher', 'Correct service path');
        is($args->{method}, 'CreateTopic', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::Topic', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::Topic'->new();
        return $response;
    };
    
    my $res = $client->create_topic();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::Topic', 'Response object class');
    done_testing();
};

subtest 'publish method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Publisher', 'Correct service path');
        is($args->{method}, 'Publish', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::PublishRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::PublishResponse'->new();
        return $response;
    };
    
    my $res = $client->publish();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::PublishResponse', 'Response object class');
    done_testing();
};

subtest 'get_topic method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Publisher', 'Correct service path');
        is($args->{method}, 'GetTopic', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::GetTopicRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::Topic'->new();
        return $response;
    };
    
    my $res = $client->get_topic();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::Topic', 'Response object class');
    done_testing();
};

subtest 'list_topics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Publisher', 'Correct service path');
        is($args->{method}, 'ListTopics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_topics();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse', 'Response object class');
    done_testing();
};

subtest 'list_topic_subscriptions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Publisher', 'Correct service path');
        is($args->{method}, 'ListTopicSubscriptions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_topic_subscriptions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse', 'Response object class');
    done_testing();
};

subtest 'delete_topic method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1beta2.Publisher', 'Correct service path');
        is($args->{method}, 'DeleteTopic', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_topic();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
