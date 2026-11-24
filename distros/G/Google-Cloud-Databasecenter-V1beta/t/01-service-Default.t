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
    for my $pkg (qw( Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Databasecenter::V1beta;

my $client = Google::Cloud::Databasecenter::V1beta->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'query_products method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.databasecenter.v1beta.DatabaseCenter', 'Correct service path');
        is($args->{method}, 'QueryProducts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse'->new();
        return $response;
    };
    
    my $res = $client->query_products();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse', 'Response object class');
    done_testing();
};

subtest 'aggregate_fleet method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.databasecenter.v1beta.DatabaseCenter', 'Correct service path');
        is($args->{method}, 'AggregateFleet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse'->new();
        return $response;
    };
    
    my $res = $client->aggregate_fleet();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse', 'Response object class');
    done_testing();
};

subtest 'query_database_resource_groups method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.databasecenter.v1beta.DatabaseCenter', 'Correct service path');
        is($args->{method}, 'QueryDatabaseResourceGroups', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse'->new();
        return $response;
    };
    
    my $res = $client->query_database_resource_groups();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse', 'Response object class');
    done_testing();
};

subtest 'aggregate_issue_stats method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.databasecenter.v1beta.DatabaseCenter', 'Correct service path');
        is($args->{method}, 'AggregateIssueStats', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse'->new();
        return $response;
    };
    
    my $res = $client->aggregate_issue_stats();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse', 'Response object class');
    done_testing();
};

subtest 'aggregate_query_stats method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.databasecenter.v1beta.DatabaseCenter', 'Correct service path');
        is($args->{method}, 'AggregateQueryStats', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse'->new();
        return $response;
    };
    
    my $res = $client->aggregate_query_stats();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse', 'Response object class');
    done_testing();
};

subtest 'query_issues method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.databasecenter.v1beta.DatabaseCenter', 'Correct service path');
        is($args->{method}, 'QueryIssues', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse'->new();
        return $response;
    };
    
    my $res = $client->query_issues();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse', 'Response object class');
    done_testing();
};

done_testing();
