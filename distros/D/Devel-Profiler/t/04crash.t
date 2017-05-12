use Test::More tests => 2;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

profile_code(<<'END', "check code that crashes Devel::DProf");
sub foo { goto FOO; }
foo();
FOO: 1;
END

check_tree(<<'END', "check crash tree", "-F");
main::foo
END


