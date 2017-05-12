#!env perl

use strict;use warnings;
use IPC::Transit;

#note that this code will not work exactly as written, because it needs
#to run on two different boxes.


my ($sender_public_key, $sender_private_key) = IPC::Transit::gen_key_pair();
my ($receiver_public_key, $receiver_private_key) = IPC::Transit::gen_key_pair();


$IPC::Transit::my_hostname = 'sender.hostname.com';
$IPC::Transit::my_keys->{public} = $sender_public_key;
$IPC::Transit::my_keys->{private} = $sender_private_key;
$IPC::Transit::public_keys->{'receiver.hostname.com'} = $receiver_public_key;


IPC::Transit::send(
    message => {foo => 'bar'},
    qname => 'some_qname',
    destination => 'receiver.hostname.com',
    encrypt => 1
);

exit;

#teleport over to the receiver, magically using keys generated above

$IPC::Transit::my_hostname = 'receiver.hostname.com';
$IPC::Transit::my_keys->{public} = $receiver_public_key;
$IPC::Transit::my_keys->{private} = $receiver_private_key;
$IPC::Transit::public_keys->{'sender.hostname.com'} = $sender_public_key;

my $message = IPC::Transit::receiver(
    qname => 'some_qname'
);

if($message->{'.ipc_transit_meta'}->{encrypt_source} ne 'sender.hostname.com') {
    die 'something bad happened, $message is not to be trusted';
}
