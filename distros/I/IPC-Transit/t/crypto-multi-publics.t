#!env perl

use strict;use warnings;

use lib 'lib';
use Test::More;
use Data::Dumper;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

my ($their_public_key, $their_private_key) = IPC::Transit::gen_key_pair();
my ($my_public_key, $my_private_key) = IPC::Transit::gen_key_pair();
my ($another_public_key, undef) = IPC::Transit::gen_key_pair();

undef $IPC::Transit::config_dir;
undef $IPC::Transit::config_file;
undef $IPC::Transit::config_dir;
undef $IPC::Transit::config_file;

#the following global assignments are to represent the sending box
$IPC::Transit::my_hostname = 'sender';
$IPC::Transit::my_keys->{public} = $my_public_key;
$IPC::Transit::my_keys->{private} = $my_private_key;
$IPC::Transit::public_keys->{'127.0.0.1'} = $their_public_key;


ok my $transitd_pid = IPC::Transit::Test::run_daemon('perl bin/remote-transitd');
ok my $transit_gateway_pid = IPC::Transit::Test::run_daemon('plackup --port 9816 bin/remote-transit-gateway.psgi');
sleep 2; #let them spin up a bit
IPC::Transit::send(message => {foo => 'bar'}, qname => $IPC::Transit::test_qname, destination => '127.0.0.1', encrypt => 1);
sleep 2; #let them do their jobs


#the following global assignments are to represent the receiving box
$IPC::Transit::my_hostname = '127.0.0.1';
$IPC::Transit::my_keys->{public} = $their_public_key;
$IPC::Transit::my_keys->{private} = $their_private_key;
#$IPC::Transit::public_keys->{sender} = $my_public_key;
$IPC::Transit::public_keys->{sender} = [$another_public_key,$my_public_key];


ok my $ret = eval {
    local $SIG{ALRM} = sub { die "timed out\n"; };
    alarm 3;
    return IPC::Transit::receive(qname => $IPC::Transit::test_qname);
};
alarm 0;
ok $ret->{foo}, 'foo properly exists';
ok $ret->{foo} eq 'bar', 'foo properly equals bar';
ok $ret->{'.ipc_transit_meta'}, '.ipc_transit_meta properly exists';
ok $ret->{'.ipc_transit_meta'}->{encrypt_source}, 'encrypt_source in .ipc_transit_meta properly exists';
ok $ret->{'.ipc_transit_meta'}->{encrypt_source} eq 'sender', 'encrypt_source in .ipc_transit_meta properly is set to sender';
ok $ret->{'.ipc_transit_meta'}->{signed_destination} eq 'my_private', 'signed_destination in .ipc_transit_meta properly is set to my_private';

ok IPC::Transit::Test::kill_daemon($transitd_pid);
ok IPC::Transit::Test::kill_daemon($transit_gateway_pid);

done_testing();
