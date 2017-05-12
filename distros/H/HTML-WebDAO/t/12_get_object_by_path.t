#create customers test
use strict;
use warnings;

use Test::More tests => 26;
#use Test::More qw(no_plan);
use Data::Dumper;
use lib 'contrib';
use lib '../contrib';

BEGIN {
    use_ok('TestLoad');
    use_ok('Test_t');
    use_ok('HTML::WebDAO::Store::Abstract');
    use_ok('HTML::WebDAO::SessionSH');
    use_ok('HTML::WebDAO::Engine');
}

my $ID = "resoler";
ok( ( my $store_ab = new HTML::WebDAO::Store::Abstract:: ), "Create store" );
ok( ( my $session = new HTML::WebDAO::SessionSH:: store => $store_ab ),
    "Create session" );
$session->U_id($ID);

my $eng = new HTML::WebDAO::Engine:: session => $session;

#register alias
$eng->register_class( 'Test_t',                  'testtr' );
$eng->register_class( 'TestLoad',                'test_autoload' );
$eng->register_class( 'HTML::WebDAO::Container', 'poll' );

ok my $test_obj = $eng->_createObj( 'test', 'testtr' ), 'create element';
ok my $container = $eng->_createObj( 'container', 'poll' ), 'create container';
$container->_add_childs($test_obj);
$eng->_add_childs($container);

#check auto load
ok my $container_autoload = $eng->_createObj( 'auto', 'test_autoload' ),
  'create autoload container';
$eng->_add_childs($container_autoload);

my $u1 = '/container/test/test_method';
my @p1 = grep { $_ } @{ $session->call_path($u1) };
ok my $o1 = $eng->_get_object_by_path( \@p1, $session ),
  'non exists method:' . $u1;

my $u2 = '/container/test/test_echo';
my @p2 = grep { $_ } @{ $session->call_path($u2) };
ok my $o2 = $eng->_get_object_by_path( \@p2, $session ), 'exists method:' . $u2;
isa_ok $o2, 'Test_t', 'check type';

my $u3 = '/auto/testtr';
my @p3 = grep { $_ } @{ $session->call_path($u3) };
ok my $o3 = $eng->_get_object_by_path( \@p3 ),
  'exists object by path(without session):' . $u3;
isa_ok $o3, 'Test_t', 'check type';

my $u4 = '/auto/test.html';
my @p4 = grep { $_ } @{ $session->call_path($u4) };
ok my $o4 = $eng->_get_object_by_path( \@p4 ),
  'self controlled objects(without session):' . $u4;
isa_ok $o4, 'TestLoad', 'check type';

my @p5 = grep { $_ } @{ $session->call_path($u4) };
ok my $o5 = $eng->_get_object_by_path( \@p5, $session ),
  'self controlled objects(with session):' . $u4;
isa_ok $o5, 'TestLoad', 'check type';

my $u6 = '/auto/test.html12123';
my @p6 = grep { $_ } @{ $session->call_path($u6) };
ok !( my $o6 = $eng->_get_object_by_path( \@p6, $session ) ),
  'self controlled objects(with session) not found:' . $u6;

my @p7 = grep { $_ } @{ $session->call_path($u6) };
ok !( my $o7 = $eng->_get_object_by_path( \@p7 ) ),
  'self controlled objects(without session) not found:' . $u6;
#test get valide object
my @p8 = grep { $_ } @{ $session->call_path('/auto') };
ok my $o8 = $eng->_get_object_by_path( \@p8 ) ,
  'self object (without session) found:' .'/auto' ;

my $tu1 = '/container/test/test_method';
my $ou1 = $eng->resolve_path($session, $tu1 );
ok !$ou1, 'resolve call by non_exists method';
my $tu2 = '/container/test/test_echo';
my $ou2 = $eng->resolve_path($session, $tu2 );
is $ou2->html , 0, 'check return result';
my $tu3 = '/container/test/';
my $ou3 = $eng->resolve_path($session, $tu3 );
is $ou3->html, 2, 'check default method call';

my $tu4 = '/container/test/test_resonse';
my $ou4 = $eng->resolve_path($session, $tu4 );
is $ou4->html, 'ok', 'check returned response';

#ok  ! $ou1, 'resolve call by non_exists method';

