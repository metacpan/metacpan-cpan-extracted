use Test::More tests => 2;
use lib '../lib';

use_ok( 'JSON::RPC::Dispatcher::App' );

JSON::RPC::Dispatcher::App->register_rpc_method_names(qw(foo));
my @methods = JSON::RPC::Dispatcher::App->_rpc_method_names();
is($methods[0], 'foo', 'registering regular methods works');

