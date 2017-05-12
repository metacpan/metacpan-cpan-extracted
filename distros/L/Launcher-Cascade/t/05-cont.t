#!perl -T
use Test::More tests => 9;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($FATAL);

use Launcher::Cascade::Container;
use Launcher::Cascade::Simple;

my ($value_a, $value_b, $value_c) = (0, 0, 0);
my $A = new Launcher::Cascade::Simple -name => 'A', -launch_hook => sub { $value_a ++ }, -test_hook => sub { $value_a == 1 }, -max_retries => 4;
my $B = new Launcher::Cascade::Simple -name => 'B', -launch_hook => sub { $value_b ++ }, -test_hook => sub { $value_b == 1 }, -max_retries => 4;
my $C = new Launcher::Cascade::Simple -name => 'C', -launch_hook => sub { $value_c ++ }, -test_hook => sub { $value_c == 1 }, -max_retries => 4, -dependencies => [ $A, $B ];

my $container = new Launcher::Cascade::Container -launchers => [ $A, $B, $C ];

ok(!$container->is_success());
ok(!$container->is_failure());
$container->run_session();

ok($container->is_success());
ok(!$container->is_failure());

$_->reset() foreach $container->launchers();

($value_a, $value_b) = (0, 0);
$C->test_hook(sub { if ($value_c == 10) { 1 } else {$_[0]->add_error("\$value_c is $value_c, expected 10");0} });
ok(!$container->is_success());
ok(!$container->is_failure());
$container->run_session();

ok(!$container->is_success());
ok($container->is_failure());
is($C->errors()->[0], "\$value_c is 2, expected 10");
