use strict;
use warnings;
use Test::More;
use File::Temp;

use lib '../lib';
use LightTCP::SSLclient;

subtest 'fingerprint_save with save flag' => sub {
    my $client = LightTCP::SSLclient->new();
    my $tempdir = File::Temp->newdir(CLEANUP => 1);

    my $test_fp = 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33';

    my ($err, $errors, $debug, $code) = $client->fingerprint_save($tempdir, 'perminent.test', 443, $test_fp, 1);
    is($err, 1, 'returns 1 when permanently saving');
    is($code, 0, 'error code is 0 on success');

    my $file = "$tempdir/perminent.test.443";
    ok(-f $file, 'permanent file created');

    my $fp = $client->fingerprint_read($tempdir, 'perminent.test', 443);
    is($fp, $test_fp, 'fingerprint saved correctly');

    ok(!-f "$file.new", '.new file removed after permanent save');
};

subtest 'fingerprint_save with errors' => sub {
    my $client = LightTCP::SSLclient->new();
    my $tempdir = '/nonexistent/directory';

    my ($err, $errors, $debug, $code) = $client->fingerprint_save($tempdir, 'error.test', 443, 'test', 1);
    is($err, 1, 'returns 1 even with errors');
    ok(@$errors > 0, 'error message returned');
};

subtest 'fingerprint_save with verbose' => sub {
    my $client = LightTCP::SSLclient->new(verbose => 1);
    my $tempdir = File::Temp->newdir(CLEANUP => 1);

    my ($err, $errors, $debug, $code) = $client->fingerprint_save($tempdir, 'verbose.test', 443, 'test', 0);
    is($err, 1, 'returns 1 when not permanently saving');
    is($code, 0, 'error code is 0 on success');
    ok(@$debug > 0, 'debug messages present when verbose is true');
    ok(!$errors || @$errors == 0, 'no errors');
};

subtest 'fingerprint_save without verbose' => sub {
    my $client = LightTCP::SSLclient->new(verbose => 0);
    my $tempdir = File::Temp->newdir(CLEANUP => 1);

    my ($err, $errors, $debug, $code) = $client->fingerprint_save($tempdir, 'quiet.test', 443, 'test', 0);
    is($err, 1, 'returns 1 when not permanently saving');
    is($code, 0, 'error code is 0 on success');
    is(@$debug, 0, 'no debug messages when verbose is false');
};

subtest 'close method' => sub {
    my $client = LightTCP::SSLclient->new();

    is($client->close(), 1, 'close() returns 1');

    is($client->is_connected(), 0, 'is_connected() returns 0 when not connected');

    $client->{_connected} = 1;

    is($client->is_connected(), 1, 'is_connected() returns 1 when connected');
    is($client->close(), 1, 'close() returns 1');
    is($client->is_connected(), 1, 'is_connected() still 1 because socket was undef');
};

subtest 'keep_alive option' => sub {
    my $client = LightTCP::SSLclient->new();
    is($client->get_keep_alive(), 0, 'keep_alive defaults to 0');

    $client->set_keep_alive(1);
    is($client->get_keep_alive(), 1, 'keep_alive can be set to 1');

    my $client2 = LightTCP::SSLclient->new(keep_alive => 1);
    is($client2->get_keep_alive(), 1, 'keep_alive can be set in constructor');
};

subtest 'buffer_size option' => sub {
    my $client = LightTCP::SSLclient->new();
    is($client->get_buffer_size(), 8192, 'buffer_size defaults to 8192');

    my $client2 = LightTCP::SSLclient->new(buffer_size => 4096);
    is($client2->get_buffer_size(), 4096, 'buffer_size can be set in constructor');
};

done_testing();
