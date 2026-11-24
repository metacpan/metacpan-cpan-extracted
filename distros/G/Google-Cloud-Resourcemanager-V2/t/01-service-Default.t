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
    for my $pkg (qw( Google::Cloud::Resourcemanager::V2::Folders::Folder Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse Google::Iam::V1::IamPolicy::TestIamPermissionsResponse Google::Iam::V1::Policy::Policy Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Resourcemanager::V2;

my $client = Google::Cloud::Resourcemanager::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_folders method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'ListFolders', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_folders();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse', 'Response object class');
    done_testing();
};

subtest 'search_folders method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'SearchFolders', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse'->new();
        return $response;
    };
    
    my $res = $client->search_folders();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse', 'Response object class');
    done_testing();
};

subtest 'get_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'GetFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V2::Folders::Folder'->new();
        return $response;
    };
    
    my $res = $client->get_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V2::Folders::Folder', 'Response object class');
    done_testing();
};

subtest 'create_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'CreateFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'UpdateFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V2::Folders::Folder'->new();
        return $response;
    };
    
    my $res = $client->update_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V2::Folders::Folder', 'Response object class');
    done_testing();
};

subtest 'move_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'MoveFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->move_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'DeleteFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V2::Folders::Folder'->new();
        return $response;
    };
    
    my $res = $client->delete_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V2::Folders::Folder', 'Response object class');
    done_testing();
};

subtest 'undelete_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'UndeleteFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V2::Folders::Folder'->new();
        return $response;
    };
    
    my $res = $client->undelete_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V2::Folders::Folder', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v2.Folders', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse', 'Response object class');
    done_testing();
};

done_testing();
