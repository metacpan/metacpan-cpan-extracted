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
    my ($class, %args) = @_;
    return bless \%args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Main test execution
package main;
use Google::Spanner::V1::Spanner;
use Google::Cloud::Spanner::V1;

my $client = Google::Cloud::Spanner::V1->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'codec methods' => sub {
    my $bytes = Google::Cloud::Spanner::V1->new_execute_sql_request({ sql => 'SELECT 1' });
    ok($bytes, 'Method returned encoded bytes');
    
    my $res_msg = Google::Spanner::V1::ResultSet::PartialResultSet->new({
        values => [ { string_value => "101" } ],
    });
    my $res_bytes = $res_msg->serialize();
    my $res = Google::Cloud::Spanner::V1->parse_partial_result_set($res_bytes);
    ok($res, 'Method returned a parsed response');
    is($res->values->[0]->string_value, '101', 'Response value matches');
    done_testing();
};

done_testing();
