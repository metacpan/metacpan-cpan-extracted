#! perl -T

use strict;
use warnings;

use Test::More tests => 30;
use Test::MockObject;

my $mock = Test::MockObject->new();
$mock->fake_module( 'Pod::Simple::Text',
    VERSION  => sub { 1 },
    map {
        my $sub = $_;
        $mock->set_always( $sub => $sub );
        $sub => sub { shift; $mock->$sub( @_ ) }
    } qw( start_head1 start_item_bullet end_item_bullet handle_text end_head1 )
);

my $module = 'Mail::Action::PodToHelp';
use_ok( $module ) or exit;

my $p2h = bless {}, $module;

can_ok( $module, 'start_head1' );
my $result = $p2h->start_head1( 'args' );
my ($method, $args) = $mock->next_call();

is( $p2h->{_in_head1}, 1,   'start_head1() should set in head1 flag' );
is( $method, 'start_head1', '... calling parent method' );
is( $args->[1], 'args',     '... with args' );
is( $result, 'start_head1', '... returning results' );

for my $testmeth (qw( start_item_bullet end_item_bullet ))
{
    can_ok( $module, $testmeth );
    $p2h->{_show} = 1;
    $result = $p2h->$testmeth( 'args' );
    ($method, $args) = $mock->next_call();
    is( $method, $testmeth, "$testmeth() should call parent" );
    is( $args->[1], 'args', '... with args' );
    is( $result, $testmeth, '... returning results' );
    $p2h->{_show} = 0;

    is( $p2h->$testmeth(),
        undef,              '... unless show flag is disabled' );
}

can_ok( $module, 'show_headings' );
$p2h->show_headings( 'first', 'second' );
is_deeply(
    $p2h->{_show_headings},
    { first => 1, second => 1 },
    'show_headings() should save passed in headings' );

can_ok( $module, 'handle_text' );
$p2h->{_show} = 0;
$result = $p2h->handle_text( '' );
is( $result, undef, 'handle_text() should return without show flag' );
$p2h->{_in_head1} = 1;
$p2h->{_show}     = 0;
$p2h->handle_text( 'first' );
is( $p2h->{_show}, 1, '... setting show flag if handling a showable heading' );

$p2h->{_show} = 0;
$p2h->handle_text( 'second' );
is( $p2h->{_show}, 1, '... any showable heading' );

$p2h->{_show} = 0;
$p2h->handle_text( 'yuckyfoo' );
ok( ! $p2h->{_show}, '... but not for anything else' );

$mock->clear();
$p2h->{_in_head1} = 0;
$p2h->{_show}     = 1;
$result           = $p2h->handle_text( 'text' );
($method, $args)  = $mock->next_call();

is( $method, 'handle_text', '... should call parent if show flag is set' );
is( $args->[1], 'text',     '... passing args' );
is( $result, 'handle_text', '... returning results' );

can_ok( $module, 'end_head1' );
$p2h->{_in_head1} = 1;
$result           = $p2h->end_head1( 'args' );
($method, $args)  = $mock->next_call();

is( $p2h->{_in_head1}, 0, 'end_head1() should unset in head1 flag' );
is( $method, 'end_head1', '... calling parent method' );
is( $args->[1], 'args',   '... passing args' );
