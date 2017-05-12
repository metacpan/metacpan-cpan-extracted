# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Java::JCR');
use_ok('Java::JCR::Jackrabbit');

my $repository = Java::JCR::Jackrabbit->new;
ok($repository);

my $session = $repository->login(
    Java::JCR::SimpleCredentials->new('username', 'password'));
ok($session);

Java::JCR::Jackrabbit->register_node_types($session, 't/nodetypes.cnd');

my $root = $session->get_root_node;
my $node = $root->add_node('testing', 'test:unstructured');
ok($node);

$root->save;

$node->remove;
$root->save;

$session->logout;
