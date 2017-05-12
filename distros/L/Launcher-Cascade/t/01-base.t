#!perl -T
use strict;

use Test::More tests => 30;
use Launcher::Cascade::Simple;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($FATAL);

my $value = 0;
my $A = new Launcher::Cascade::Simple -name => 'Launcher A', -test_hook => sub { 1 }, -launch_hook => sub { $value = 1 };
my $B = new Launcher::Cascade::Simple -name => 'Launcher B', -test_hook => sub { $value == 1 }, -launch_hook => sub { 1 };
$B->add_dependencies($A);

diag "B depends on A. Nothing run so far";
ok($A->is_ready(), "A is ready");
ok(!$B->is_ready(), "B is not ready");
ok(!$A->is_success(), "A is not successfull");
ok(!$A->is_failure(), "A is not failed either");
ok(!$B->is_success(), "A is not successfull");
ok(!$B->is_failure(), "A is not failed either");

diag "Running";
$A->run();
$B->run();
ok(!$A->is_ready(), "A is not ready");
ok(!$B->is_ready(), "B is not ready");
ok(!$A->is_success(), "A is not successfull");
ok(!$A->is_failure(), "A is not failed either");
ok(!$B->is_success(), "A is not successfull");
ok(!$B->is_failure(), "A is not failed either");

diag("Checking status");
$A->check_status();
$B->check_status();
ok(!$A->is_ready(), "A is not ready");
ok($B->is_ready(), "B is ready");
ok($A->is_success(), "A is successfull");
ok(!$A->is_failure(), "A is not failed");
ok(!$B->is_success(), "B is not successfull");
ok(!$B->is_failure(), "B is not failed either");

diag "Running";
$A->run();
$B->run();
ok(!$A->is_ready(), "A is not ready");
ok(!$B->is_ready(), "B is not ready");
ok($A->is_success(), "A is successfull");
ok(!$A->is_failure(), "A is not failed");
ok(!$B->is_success(), "B is not successfull");
ok(!$B->is_failure(), "B is not failed either");

diag("Checking status");
$A->check_status();
$B->check_status();
ok(!$A->is_ready(), "A is not ready");
ok(!$B->is_ready(), "B is not ready");
ok($A->is_success(), "A is successfull");
ok(!$A->is_failure(), "A is not failed");
ok($B->is_success(), "B is successfull");
ok(!$B->is_failure(), "B is not failed either");

