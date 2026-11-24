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
    for my $pkg (qw( Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount Google::Storagetransfer::V1::TransferTypes::TransferJob )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient;

my $client = Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_google_service_account method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storagetransfer.v1.StorageTransferService', 'Correct service path');
        is($args->{method}, 'GetGoogleServiceAccount', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest', 'Request object');
        
        my $response = 'Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount'->new();
        return $response;
    };
    
    my $res = $client->get_google_service_account();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount', 'Response object class');
    done_testing();
};

subtest 'create_transfer_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storagetransfer.v1.StorageTransferService', 'Correct service path');
        is($args->{method}, 'CreateTransferJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest', 'Request object');
        
        my $response = 'Google::Storagetransfer::V1::TransferTypes::TransferJob'->new();
        return $response;
    };
    
    my $res = $client->create_transfer_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storagetransfer::V1::TransferTypes::TransferJob', 'Response object class');
    done_testing();
};

subtest 'update_transfer_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.storagetransfer.v1.StorageTransferService', 'Correct service path');
        is($args->{method}, 'UpdateTransferJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest', 'Request object');
        
        my $response = 'Google::Storagetransfer::V1::TransferTypes::TransferJob'->new();
        return $response;
    };
    
    my $res = $client->update_transfer_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Storagetransfer::V1::TransferTypes::TransferJob', 'Response object class');
    done_testing();
};

done_testing();
