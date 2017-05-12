#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More;
use Data::Dumper;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

undef $IPC::Transit::config_dir;
undef $IPC::Transit::config_file;
undef $IPC::Transit::config_dir;
undef $IPC::Transit::config_file;

#the following global assignments are to represent the sending box
$IPC::Transit::my_hostname = 'sender';


ok my $transitd_pid = IPC::Transit::Test::run_daemon('perl bin/remote-transitd');
ok my $transit_gateway_pid = IPC::Transit::Test::run_daemon('plackup --port 9816 bin/remote-transit-gateway.psgi');
sleep 2; #let them spin up a bit
IPC::Transit::send(message => {foo => 'bar'}, qname => $IPC::Transit::test_qname, destination => '127.0.0.1', encrypt => 1);
sleep 2; #let them do their jobs


#the following global assignments are to represent the receiving box
$IPC::Transit::my_hostname = '127.0.0.1';

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
ok $ret->{'.ipc_transit_meta'}->{encrypt_source} eq 'default', 'encrypt_source in .ipc_transit_meta properly is set to sender';
ok $ret->{'.ipc_transit_meta'}->{signed_destination} eq 'default', 'signed_destination in .ipc_transit_meta properly is set to private';


ok IPC::Transit::Test::kill_daemon($transitd_pid);
ok IPC::Transit::Test::kill_daemon($transit_gateway_pid);

done_testing();
