#!/usr/bin/perl
use strict;
use Test::More tests => 6;
use Test::Exception;

#######################################################################
# test pluggable implementation
#######################################################################


use lib 't/lib';
use Testproject::Pluggable;
use Froody::Dispatch;

my $client = Froody::Dispatch->config({
  modules =>[qw(Testproject::Pluggable)],
  filters =>[qw(**)]
});

ok(my $ret = $client->call('testproject.object.session_test', session_id => 'fooo'));

is($ret, 'fooo');

use Data::Dumper;
ok ($client->call('froody.reflection.getMethodInfo',
		  method_name => 'testproject.object.session.invalidate'),
    'plugin-registered method found');

our $plugin_invalidate_called;

lives_and {
  $ret = $client->call('testproject.object.session.invalidate', session_id => 'booo');
  is_deeply $ret, {}, 'Per spec, invalidate returns empty hash';
} "can call the session invalidate method";

isa_ok($plugin_invalidate_called->[0], 'Testproject::Pluggable',
       'the plugin method got implementation context');

is($plugin_invalidate_called->[0]->session, 'booo',
   'session got populated for that method as well');
