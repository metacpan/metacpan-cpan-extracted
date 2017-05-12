# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 8;

use_ok('Java::JCR');
use_ok('Java::JCR::Jackrabbit');

use Java::JCR;

my $repository = Java::JCR::Jackrabbit->new;
ok($repository);
isa_ok($repository, 'Java::JCR::Repository');

my $session = $repository->login;
ok($session);
isa_ok($session, 'Java::JCR::Session');

my $user = $session->get_user_id;
is($user, 'anonymous');

my $name = $repository->get_descriptor($Java::JCR::Repository::REP_NAME_DESC);
is($name, 'Jackrabbit');

$session->logout;
