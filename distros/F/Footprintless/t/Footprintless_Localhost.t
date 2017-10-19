use strict;
use warnings;

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout', log_level => 'error' );
};

use Footprintless::Util qw(
    spurt
    temp_file
);
use Test::More tests => 24;

BEGIN { use_ok('Footprintless::Localhost') }

my $localhost = Footprintless::Localhost->new();
ok( $localhost->is_alias('localhost'),    'localhost is alias' );
ok( $localhost->is_alias('127.0.0.1'),    '127.0.0.1 is alias' );
ok( !$localhost->is_loaded('/etc/hosts'), '/etc/hosts not loaded' );
ok( !$localhost->is_loaded('hostname'),   'hostname not loaded' );
ok( !$localhost->is_loaded('hostfqdn'),   'hostfqdn not loaded' );

$localhost->load_etc_hosts();
ok( $localhost->is_loaded('/etc/hosts'), '/etc/hosts is loaded' );
$localhost->load_hostname();
ok( $localhost->is_loaded('hostname'), 'hostname is loaded' );
$localhost->load_hostfqdn();
ok( $localhost->is_loaded('hostfqdn'), 'hostfqdn is loaded' );

$localhost = Footprintless::Localhost->new()->load_all();
ok( $localhost->is_loaded('/etc/hosts'), 'after load_all /etc/hosts is loaded' );
ok( $localhost->is_loaded('hostname'),   'after load_all hostname is loaded' );
ok( $localhost->is_loaded('hostfqdn'),   'after load_all hostfqdn is loaded' );

$localhost = Footprintless::Localhost->new( aliases => ['me'] );
ok( $localhost->is_alias('me'), 'me is alias' );

$localhost = Footprintless::Localhost->new( none => 1 );
ok( !$localhost->is_alias('localhost'), 'none localhost is alias' );
ok( !$localhost->is_alias('127.0.0.1'), 'none 127.0.0.1 is alias' );

my $temp = temp_file();
spurt( <<ETC_HOSTS, $temp->filename() );
127.0.1.2 foo bar
# 127.0.1.1 hip
10.1.1.1 hop
127.3.8.1 qux baz 
ETC_HOSTS
$localhost = Footprintless::Localhost->new( etc_hosts_file => $temp->filename() )->load_all();
ok( $localhost->is_loaded('/etc/hosts'), '127 /etc/hosts is loaded' );
ok( $localhost->is_alias('foo'),         '127 foo localhost is alias' );
ok( $localhost->is_alias('bar'),         '127 bar localhost is alias' );
ok( $localhost->is_alias('qux'),         '127 qux localhost is alias' );
ok( $localhost->is_alias('baz'),         '127 baz localhost is alias' );
ok( !$localhost->is_alias('hip'),        '127 hip localhost is alias' );
ok( !$localhost->is_alias('hop'),        '127 hop localhost is alias' );
ok( $localhost->is_alias('127.3.0.5'),   '127 127.3.0.5' );
ok( !$localhost->is_alias('10.3.0.5'),   '127 10.3.0.5' );

