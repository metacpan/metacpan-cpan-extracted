use strict;
use warnings;
use Test::More 0.88;

use Net::RabbitFoot;
use IPC::Lock::RabbitMQ;
use File::ShareDir;

my $rf = Net::RabbitFoot->new(
#    verbose => 1,
)->load_xml_spec(
    File::ShareDir::dist_dir("AnyEvent-RabbitMQ") . '/fixed_amqp0-8.xml'
);
eval {
    $rf->connect(
        on_close => sub {},
        on_failure => sub {
            die("Connection to RabbitMQ on localhost:5672 failed!\n");
            return;
        },
        host => 'localhost',
        port => 5672,
        user => 'guest',
        pass => 'guest',
        vhost => '/',
    );
    1;
} || plan skip_all => 'Could not start RabbitMQ connection to localhost';

my $object = IPC::Lock::RabbitMQ->new({
    mq => $rf,
});

my $key = "$$.testing";
my $lock;
ok($object && ref $object && ref $object eq 'IPC::Lock::RabbitMQ', 'instantiation');
ok($lock = $object->lock($key), "$key locked $object");
ok(!$object->lock($key), "$key still locked");
ok($lock->unlock(), "$key unlocked");

my $second = IPC::Lock::RabbitMQ->new({
    mq => $rf,
});

my $lock2;
ok($lock2 = $second->lock($key), 'second can lock');
ok(!$object->lock($key), 'first cannot lock');
$lock2 = undef;
ok($lock2 = $object->lock($key), 'First can now lock');

$rf->close;
$rf = undef;

done_testing;
