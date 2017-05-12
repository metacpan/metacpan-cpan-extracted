# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 26;

use_ok('Java::JCR');
use_ok('Java::JCR::Jackrabbit');

my $repository = Java::JCR::Jackrabbit->new;
ok($repository);

my $session = $repository->login(
    Java::JCR::SimpleCredentials->new('username', 'password'));
ok($session);
isa_ok($session, 'Java::JCR::Session');

my $root = $session->get_root_node;
ok($root);
isa_ok($root, 'Java::JCR::Node');

my $hello = $root->add_node('hello');
ok($hello);
isa_ok($root, 'Java::JCR::Node');
is($hello->get_name, 'hello');
is($hello->get_path, '/hello');

my $world = $hello->add_node('world');
ok($world);
isa_ok($world, 'Java::JCR::Node');
is($world->get_name, 'world');
is($world->get_path, '/hello/world');

my $message = $world->set_property('message', 'Hello, World!');
ok($message);
isa_ok($message, 'Java::JCR::Property');
is($message->get_name, 'message');
is($message->get_path, '/hello/world/message');

$session->save;

my $node = $root->get_node('hello/world');
ok($node);
isa_ok($node, 'Java::JCR::Node');
is($node->get_path, '/hello/world');

my $property = $node->get_property('message');
ok($property);
isa_ok($property, 'Java::JCR::Property');

my $value = $property->get_string;
ok($value);
is($value, 'Hello, World!');

$root->get_node('hello')->remove;
$session->save;

$session->logout;

