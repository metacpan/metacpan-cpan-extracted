use strict;
use warnings;
use Test::More tests => 34;
use Log::Any;
use Log::Any::Adapter::Util qw(cmp_deeply);

BEGIN { 
    $Log::Any::OverrideDefaultProxyClass = 'Log::Any::Proxy::Test';
}

{

    package Foo;
    use Log::Any qw($log);

    sub log_debug {
        my ( $class, $text ) = @_;
        $log->debug($text) if $log->is_debug();
    }
}
{

    package Bar;
    use Log::Any qw($log);

    sub log_info {
        my ( $class, $text ) = @_;
        $log->info($text) if $log->is_info();
    }
}

require Log::Any::Adapter;

$Baz::log = Log::Any->get_logger( category => 'Baz' );
my $main_log = Log::Any->get_logger();
is( $main_log->adapter, Log::Any->get_logger()->adapter, "memoization - no cat" );
is( $main_log->adapter, Log::Any->get_logger( category => 'main' )->adapter,
    "memoization - cat" );

my $memclass  = 'Log::Any::Adapter::Test';
my $nullclass = 'Log::Any::Adapter::Null';

isa_ok( $Foo::log->adapter, $nullclass, 'Foo::log before set' );
isa_ok( $Bar::log->adapter, $nullclass, 'Bar::log before set' );
isa_ok( $Baz::log->adapter, $nullclass, 'Baz::log before set' );
isa_ok( $main_log->adapter, $nullclass, 'main_log before set' );

my $entry = Log::Any::Adapter->set( { category => qr/Foo|Bar/ }, "+$memclass" );

isa_ok( $Foo::log->adapter, $memclass,  'Foo::log after first set' );
isa_ok( $Bar::log->adapter, $memclass,  'Bar::log after first set' );
isa_ok( $Baz::log->adapter, $nullclass, 'Baz::log after first set' );
isa_ok( $main_log->adapter, $nullclass, 'main_log after first set' );

my $entry2 =
  Log::Any::Adapter->set( { category => qr/Baz|main/ }, "+$memclass" );

isa_ok( $Foo::log->adapter, $memclass, 'Foo::log after second set' );
isa_ok( $Bar::log->adapter, $memclass, 'Bar::log after second set' );
isa_ok( $Baz::log->adapter, $memclass, 'Baz::log after second set' );
isa_ok( $main_log->adapter, $memclass, 'main_log after second set' );

ok( $Foo::log ne $Bar::log, 'Foo::log and Bar::log are different' );
is( $main_log->adapter, Log::Any->get_logger()->adapter, "memoization - no cat" );
is( $main_log->adapter, Log::Any->get_logger( category => 'main' )->adapter,
    "memoization - cat" );

cmp_deeply( $Foo::log->msgs, [], 'Foo::log has empty buffer' );
cmp_deeply( $Bar::log->msgs, [], 'Bar::log has empty buffer' );
cmp_deeply( $main_log->msgs, [], 'Bar::log has empty buffer' );
ok( $Foo::log ne $Bar::log, 'Foo::log and Bar::log are different objects' );

Foo->log_debug('for foo');
Bar->log_info('for bar');
$main_log->error('for main');

$Foo::log->category_contains_ok(
    Foo => qr/for foo/,
    'Foo log appeared in memory'
);

$Bar::log->category_contains_ok(
    Bar => qr/for bar/,
    'Bar log appeared in memory'
);

$main_log->category_contains_ok(
    main => qr/for main/,
    'main log appeared in memory'
);

Log::Any::Adapter->remove($entry);

isa_ok( $Foo::log->adapter, $nullclass, 'Foo::log' );
isa_ok( $Bar::log->adapter, $nullclass, 'Bar::log' );
isa_ok( $Baz::log->adapter, $memclass,  'Baz::log' );
isa_ok( $main_log->adapter, $memclass,  'main_log' );

Log::Any::Adapter->remove($entry2);

isa_ok( $Foo::log->adapter, $nullclass, 'Foo::log' );
isa_ok( $Bar::log->adapter, $nullclass, 'Bar::log' );
isa_ok( $Baz::log->adapter, $nullclass, 'Baz::log' );
isa_ok( $main_log->adapter, $nullclass, 'main_log' );

{
    Log::Any::Adapter->set( { category => 'Foo', lexically => \my $lex },
        "+$memclass" );
    isa_ok( $Foo::log->adapter, $memclass, 'Foo::log in lexical scope' );
}
isa_ok( $Foo::log->adapter, $nullclass, 'Foo::log outside lexical scope' );
