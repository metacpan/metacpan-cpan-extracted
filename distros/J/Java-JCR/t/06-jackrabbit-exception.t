# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 7;

use_ok('Java::JCR');

my $repository = Java::JCR::Jackrabbit->new;
ok($repository);

my $session = $repository->login;
ok($session);

my $root = $session->get_root_node;
ok($root);

# anonymous shouldn't be able to create nodes
eval {
    my $broke = $root->add_node('broke');
    $root->save;
};

my $e = $@;

ok($e);
#diag("Exception: $e");
isa_ok($e, 'Java::JCR::Exception');
ok("$e");

$session->logout;
