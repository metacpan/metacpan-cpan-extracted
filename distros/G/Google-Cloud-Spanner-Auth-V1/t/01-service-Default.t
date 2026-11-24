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
    for my $pkg (qw( Google::Protobuf::Empty::Empty Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse Google::Spanner::Auth::V1::SpannerUsers::Role Google::Spanner::Auth::V1::SpannerUsers::User )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Spanner::Auth::V1;

my $client = Google::Cloud::Spanner::Auth::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_user method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'CreateUser', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest', 'Request object');
        
        my $response = 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse'->new();
        return $response;
    };
    
    my $res = $client->create_user();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse', 'Response object class');
    done_testing();
};

subtest 'update_user method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'UpdateUser', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest', 'Request object');
        
        my $response = 'Google::Spanner::Auth::V1::SpannerUsers::User'->new();
        return $response;
    };
    
    my $res = $client->update_user();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Auth::V1::SpannerUsers::User', 'Response object class');
    done_testing();
};

subtest 'get_user method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'GetUser', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest', 'Request object');
        
        my $response = 'Google::Spanner::Auth::V1::SpannerUsers::User'->new();
        return $response;
    };
    
    my $res = $client->get_user();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Auth::V1::SpannerUsers::User', 'Response object class');
    done_testing();
};

subtest 'list_users method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'ListUsers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest', 'Request object');
        
        my $response = 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_users();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse', 'Response object class');
    done_testing();
};

subtest 'delete_user method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'DeleteUser', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_user();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_roles method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'ListRoles', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest', 'Request object');
        
        my $response = 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_roles();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse', 'Response object class');
    done_testing();
};

subtest 'get_role method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.auth.v1.UsersService', 'Correct service path');
        is($args->{method}, 'GetRole', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest', 'Request object');
        
        my $response = 'Google::Spanner::Auth::V1::SpannerUsers::Role'->new();
        return $response;
    };
    
    my $res = $client->get_role();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Auth::V1::SpannerUsers::Role', 'Response object class');
    done_testing();
};

done_testing();
