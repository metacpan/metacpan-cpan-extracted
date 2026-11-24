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
    for my $pkg (qw( Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersResponse Google::Bigtable::Admin::V2::Instance::AppProfile Google::Bigtable::Admin::V2::Table::Table Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Bigtable::Admin::V2;

my $client = Google::Cloud::Bigtable::Admin::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.admin.v2.BigtableInstanceAdmin', 'Correct service path');
        is($args->{method}, 'CreateInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_memory_layers method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.admin.v2.BigtableInstanceAdmin', 'Correct service path');
        is($args->{method}, 'ListMemoryLayers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersRequest', 'Request object');
        
        my $response = 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_memory_layers();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersResponse', 'Response object class');
    done_testing();
};

subtest 'create_app_profile method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.admin.v2.BigtableInstanceAdmin', 'Correct service path');
        is($args->{method}, 'CreateAppProfile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateAppProfileRequest', 'Request object');
        
        my $response = 'Google::Bigtable::Admin::V2::Instance::AppProfile'->new();
        return $response;
    };
    
    my $res = $client->create_app_profile();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::Admin::V2::Instance::AppProfile', 'Response object class');
    done_testing();
};

subtest 'create_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.bigtable.admin.v2.BigtableTableAdmin', 'Correct service path');
        is($args->{method}, 'CreateTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest', 'Request object');
        
        my $response = 'Google::Bigtable::Admin::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->create_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Bigtable::Admin::V2::Table::Table', 'Response object class');
    done_testing();
};

done_testing();
