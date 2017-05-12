use Test::More tests => 2;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

profile_code(<<'END', "make sure Fcntl constants are skipped.");
use Fcntl qw(:flock);
sub foo { LOCK_EX }
foo();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::foo
   Fcntl::constant
END
