use warnings;
use strict;
use Test::More;
use Test::Exception;
BEGIN {
    my @engines = qw( Cpanel::JSON::XS JSON::XS JSON::PP );
    my %engines = map { $_ => 1 } @engines;
    if ($ENV{JSON_MAYBEXS_ENGINE}) {
        die '$JSON_MAYBEXS_ENGINE is not one of: '.join q{, }, @engines
            if !$engines{$ENV{JSON_MAYBEXS_ENGINE}};
        unshift @INC, sub {
            my (undef, $m) = @_;
            $m =~ s{/}{::}msg;
            $m =~ s{[.]pmc?\z}{}ms;
            return \q{} if $engines{$m} && $ENV{JSON_MAYBEXS_ENGINE} ne $m;
            return;
        }
    }
}
use JSON::MaybeXS qw( decode_json encode_json );
diag 'JSON::MaybeXS has loaded '.JSON::MaybeXS::JSON();

use JSON::RPC2::Client;
use JSON::RPC2::Server;


sub jsonrpc2_ok {
    my ($json_request, $id, $method, $params) = @_;
    my $request = decode_json($json_request);
    is $request->{jsonrpc}, '2.0',
        'jsonrpc';
    if (defined $id) {
        is $request->{id}, $id,
            'id';
    }
    else {
        ok !exists $request->{id},
            'no id';
    }
    is $request->{method}, $method,
        'method';
    if ($params) {
        is_deeply $request->{params}, $params,
            'params';
    } else {
        ok !exists $request->{params};
    }
}

sub fake_result {
    my ($json_request, $result) = @_;
    my $request = decode_json($json_request);
    my $response = {
        jsonrpc     => '2.0',
        id          => $request->{id},
        result      => $result,
    };
    my $json_response = encode_json($response);
    return $json_response;
}


1;
