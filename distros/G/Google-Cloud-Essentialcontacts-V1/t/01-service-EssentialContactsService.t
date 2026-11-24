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
    for my $pkg (qw( Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse Google::Cloud::Essentialcontacts::V1::Service::Contact Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Essentialcontacts::V1::EssentialContactsServiceClient;

my $client = Google::Cloud::Essentialcontacts::V1::EssentialContactsServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_contact method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.essentialcontacts.v1.EssentialContactsService', 'Correct service path');
        is($args->{method}, 'CreateContact', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest', 'Request object');
        
        my $response = 'Google::Cloud::Essentialcontacts::V1::Service::Contact'->new();
        return $response;
    };
    
    my $res = $client->create_contact();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Essentialcontacts::V1::Service::Contact', 'Response object class');
    done_testing();
};

subtest 'compute_contacts method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.essentialcontacts.v1.EssentialContactsService', 'Correct service path');
        is($args->{method}, 'ComputeContacts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse'->new();
        return $response;
    };
    
    my $res = $client->compute_contacts();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse', 'Response object class');
    done_testing();
};

subtest 'send_test_message method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.essentialcontacts.v1.EssentialContactsService', 'Correct service path');
        is($args->{method}, 'SendTestMessage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->send_test_message();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
