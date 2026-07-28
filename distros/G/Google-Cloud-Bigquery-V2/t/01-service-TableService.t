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
    for my $pkg (qw( Google::Cloud::Bigquery::V2::Table::Table Google::Cloud::Bigquery::V2::Table::TableList Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigquery::V2::TableServiceClient;

my $client = Google::Cloud::Bigquery::V2::TableServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'GetTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::GetTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->get_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'insert_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'InsertTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::InsertTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->insert_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'patch_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'PatchTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->patch_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'update_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'UpdateTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->update_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'delete_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'DeleteTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::DeleteTableRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_tables method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'ListTables', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::ListTablesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::TableList'->new();
        return $response;
    };
    
    my $res = $client->list_tables();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::TableList', 'Response object class');
    done_testing();
};

done_testing();
