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
    for my $pkg (qw( Google::Datastore::V1::Datastore::AllocateIdsResponse Google::Datastore::V1::Datastore::BeginTransactionResponse Google::Datastore::V1::Datastore::CommitResponse Google::Datastore::V1::Datastore::LookupResponse Google::Datastore::V1::Datastore::ReserveIdsResponse Google::Datastore::V1::Datastore::RollbackResponse Google::Datastore::V1::Datastore::RunAggregationQueryResponse Google::Datastore::V1::Datastore::RunQueryResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Datastore::V1;

my $client = Google::Cloud::Datastore::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'lookup method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'Lookup', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::LookupRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::LookupResponse'->new();
        return $response;
    };
    
    my $res = $client->lookup();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::LookupResponse', 'Response object class');
    done_testing();
};

subtest 'run_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'RunQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::RunQueryRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::RunQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->run_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::RunQueryResponse', 'Response object class');
    done_testing();
};

subtest 'run_aggregation_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'RunAggregationQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::RunAggregationQueryRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::RunAggregationQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->run_aggregation_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::RunAggregationQueryResponse', 'Response object class');
    done_testing();
};

subtest 'begin_transaction method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'BeginTransaction', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::BeginTransactionRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::BeginTransactionResponse'->new();
        return $response;
    };
    
    my $res = $client->begin_transaction();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::BeginTransactionResponse', 'Response object class');
    done_testing();
};

subtest 'commit method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'Commit', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::CommitRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::CommitResponse'->new();
        return $response;
    };
    
    my $res = $client->commit();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::CommitResponse', 'Response object class');
    done_testing();
};

subtest 'rollback method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'Rollback', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::RollbackRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::RollbackResponse'->new();
        return $response;
    };
    
    my $res = $client->rollback();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::RollbackResponse', 'Response object class');
    done_testing();
};

subtest 'allocate_ids method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'AllocateIds', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::AllocateIdsRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::AllocateIdsResponse'->new();
        return $response;
    };
    
    my $res = $client->allocate_ids();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::AllocateIdsResponse', 'Response object class');
    done_testing();
};

subtest 'reserve_ids method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.datastore.v1.Datastore', 'Correct service path');
        is($args->{method}, 'ReserveIds', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Datastore::V1::Datastore::ReserveIdsRequest', 'Request object');
        
        my $response = 'Google::Datastore::V1::Datastore::ReserveIdsResponse'->new();
        return $response;
    };
    
    my $res = $client->reserve_ids();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Datastore::V1::Datastore::ReserveIdsResponse', 'Response object class');
    done_testing();
};

done_testing();
