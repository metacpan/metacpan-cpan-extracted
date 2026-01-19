use strict;
use warnings;
use Test::More;

use lib '../lib';
use LightTCP::SSLclient qw(ECONNECT EREQUEST ERESPONSE ETIMEOUT ESSL);

subtest 'constructor with defaults' => sub {
    my $client = LightTCP::SSLclient->new();
    isa_ok($client, 'LightTCP::SSLclient');

    is($client->get_timeout(), 10, 'default timeout is 10');
    is($client->{insecure}, 0, 'default insecure is 0');
    is($client->{cert}, undef, 'default cert is undef');
    is($client->is_verbose(), 0, 'default verbose is 0');
    is($client->get_keep_alive(), 0, 'default keep_alive is 0');
    is($client->get_buffer_size(), 8192, 'default buffer_size is 8192');
};

subtest 'constructor with custom options' => sub {
    my $client = LightTCP::SSLclient->new(
        timeout       => 30,
        insecure      => 1,
        verbose       => 1,
        user_agent    => 'CustomAgent/1.0',
        ssl_protocols => ['TLSv1.3'],
        ssl_ciphers   => 'HIGH:!aNULL',
        keep_alive    => 1,
        buffer_size   => 4096,
    );
    isa_ok($client, 'LightTCP::SSLclient');

    is($client->get_timeout(), 30, 'custom timeout is 30');
    is($client->{insecure}, 1, 'insecure is 1');
    is($client->is_verbose(), 1, 'verbose is 1');
    is($client->get_user_agent(), 'CustomAgent/1.0', 'custom user_agent is set');
    is($client->{ssl_protocols}->[0], 'TLSv1.3', 'ssl_protocols is set');
    is($client->{ssl_ciphers}, 'HIGH:!aNULL', 'ssl_ciphers is set');
    is($client->get_keep_alive(), 1, 'keep_alive is 1');
    is($client->get_buffer_size(), 4096, 'buffer_size is 4096');
};

subtest 'accessor methods' => sub {
    my $client = LightTCP::SSLclient->new();

    is($client->socket(), undef, 'socket() returns undef when not connected');
    is($client->is_connected(), 0, 'is_connected() returns 0 when not connected');
    is($client->get_timeout(), 10, 'get_timeout() returns default');
    is($client->get_user_agent(), 'LightTCP::SSLclient/1.06', 'get_user_agent() returns default');
    is($client->is_verbose(), 0, 'is_verbose() returns default');
    is($client->get_cert(), undef, 'get_cert() returns undef');
    is($client->get_insecure(), 0, 'get_insecure() returns 0');
    is($client->get_keep_alive(), 0, 'get_keep_alive() returns 0');
    is($client->is_keep_alive(), 0, 'is_keep_alive() returns 0');
    is_deeply($client->get_ssl_protocols(), ['TLSv1.2', 'TLSv1.3'], 'get_ssl_protocols() returns default');
    is($client->get_ssl_ciphers(), 'HIGH:!aNULL:!MD5:!RC4', 'get_ssl_ciphers() returns default');
    is($client->get_buffer_size(), 8192, 'get_buffer_size() returns default');
};

subtest 'setter methods' => sub {
    my $client = LightTCP::SSLclient->new();

    is($client->set_timeout(20), 20, 'set_timeout() returns new value');
    is($client->get_timeout(), 20, 'timeout updated');

    is($client->set_insecure(1), 1, 'set_insecure() returns 1');
    is($client->{insecure}, 1, 'insecure set to 1');

    is($client->set_insecure(0), 0, 'set_insecure() returns 0');
    is($client->{insecure}, 0, 'insecure set to 0');

    is($client->set_cert('/path/to/cert'), '/path/to/cert', 'set_cert() returns value');
    is($client->{cert}, '/path/to/cert', 'cert set correctly');

    is($client->set_keep_alive(1), 1, 'set_keep_alive() returns 1');
    is($client->get_keep_alive(), 1, 'keep_alive updated');

    is($client->set_buffer_size(16384), 16384, 'set_buffer_size() returns new value');
    is($client->get_buffer_size(), 16384, 'buffer_size updated');

    is($client->set_buffer_size(0), 8192, 'set_buffer_size() defaults to 8192');
    is($client->get_buffer_size(), 8192, 'buffer_size reset to default');
};

subtest 'error constants are exported' => sub {
    is(ECONNECT, 1, 'ECONNECT = 1');
    is(EREQUEST, 2, 'EREQUEST = 2');
    is(ERESPONSE, 3, 'ERESPONSE = 3');
    is(ETIMEOUT, 4, 'ETIMEOUT = 4');
    is(ESSL, 5, 'ESSL = 5');
};

done_testing();
