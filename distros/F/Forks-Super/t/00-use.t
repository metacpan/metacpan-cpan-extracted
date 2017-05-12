#! perl -T
#
# test that Forks module loads and that the expected
# functions are exported to the calling package
#
use strict;
use warnings;

use Test::More tests => 10;
BEGIN {
    if (defined $ENV{FORKS_SUPER_DEBUG}) {
	($ENV{FORKS_SUPER_DEBUG}) = $ENV{FORKS_SUPER_DEBUG} =~ /(.*)/;
    }
    use_ok('Forks::Super');
}

diag "Forks::Super $Forks::Super::VERSION on $^O $]";

ok(\&Forks::Super::fork ne \&CORE::fork, 'CORE::fork != default fork');
ok(\&fork eq \&Forks::Super::fork, 'fork exported to default namespace');

ok(\&wait ne \&CORE::wait, 'default wait != CORE::wait');
ok(\&wait eq \&Forks::Super::wait, 'wait exported to default namespace');

ok(\&waitpid ne \&CORE::waitpid, 'default waitpid != CORE::waitpid');
ok(\&waitpid eq \&Forks::Super::waitpid, 
   'waitpid exported to default namespace');

ok(\&waitall eq \&Forks::Super::waitall, 
   'waitall exported to default namespace');

my $test = eval { fork {'__test' => 14} };
ok(!$@ && $test == 14, 'fork invokes Forks::Super::fork, not CORE::fork');

$test = eval { fork '__test' => 14 };
ok(!$@ && $test == 14, 'fork invokes Forks::Super::fork, not CORE::fork');
