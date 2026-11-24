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
    for my $pkg (qw( Google::Ai::Generativelanguage::V1alpha::File::File Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Ai::Generativelanguage::V1alpha::FileServiceClient;

my $client = Google::Ai::Generativelanguage::V1alpha::FileServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.FileService', 'Correct service path');
        is($args->{method}, 'CreateFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse'->new();
        return $response;
    };
    
    my $res = $client->create_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse', 'Response object class');
    done_testing();
};

subtest 'list_files method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.FileService', 'Correct service path');
        is($args->{method}, 'ListFiles', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_files();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse', 'Response object class');
    done_testing();
};

subtest 'get_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.FileService', 'Correct service path');
        is($args->{method}, 'GetFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1alpha::File::File'->new();
        return $response;
    };
    
    my $res = $client->get_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1alpha::File::File', 'Response object class');
    done_testing();
};

subtest 'delete_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1alpha.FileService', 'Correct service path');
        is($args->{method}, 'DeleteFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
