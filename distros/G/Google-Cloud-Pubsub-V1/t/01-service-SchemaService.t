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
    for my $pkg (qw( Google::Pubsub::V1::Schema::Schema Google::Pubsub::V1::Schema::ValidateMessageResponse Google::Pubsub::V1::Schema::ValidateSchemaResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Pubsub::V1::SchemaServiceClient;

my $client = Google::Cloud::Pubsub::V1::SchemaServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1.SchemaService', 'Correct service path');
        is($args->{method}, 'CreateSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1::Schema::CreateSchemaRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1::Schema::Schema'->new();
        return $response;
    };
    
    my $res = $client->create_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1::Schema::Schema', 'Response object class');
    done_testing();
};

subtest 'validate_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1.SchemaService', 'Correct service path');
        is($args->{method}, 'ValidateSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1::Schema::ValidateSchemaRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1::Schema::ValidateSchemaResponse'->new();
        return $response;
    };
    
    my $res = $client->validate_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1::Schema::ValidateSchemaResponse', 'Response object class');
    done_testing();
};

subtest 'validate_message method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.pubsub.v1.SchemaService', 'Correct service path');
        is($args->{method}, 'ValidateMessage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Pubsub::V1::Schema::ValidateMessageRequest', 'Request object');
        
        my $response = 'Google::Pubsub::V1::Schema::ValidateMessageResponse'->new();
        return $response;
    };
    
    my $res = $client->validate_message();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Pubsub::V1::Schema::ValidateMessageResponse', 'Response object class');
    done_testing();
};

done_testing();
