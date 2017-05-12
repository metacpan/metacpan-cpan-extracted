# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 11;

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

my $hello = $root->add_node('hello');
ok($hello);

$hello->set_property('multiple', [ qw( foo bar baz quux ) ]);

$session->save;

my $property = $root->get_property('hello/multiple');
ok($property);
isa_ok($property, 'Java::JCR::Property');

my $value = $property->get_values;
ok($property);

my @values = map { $_->get_string } @{ $value };
is_deeply(\@values, [ qw( foo bar baz quux ) ]);

$hello->remove;
$session->save;

$session->logout;
