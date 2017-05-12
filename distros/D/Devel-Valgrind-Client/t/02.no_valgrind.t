# Test calls to the functions don't break if not running under valgrind
use Test::More tests => 2;

use Devel::Valgrind::Client qw(is_in_memcheck count_leaks do_quick_leak_check);

ok !is_in_memcheck();

do_quick_leak_check();
my $h = count_leaks();
is ref $h, "HASH";

