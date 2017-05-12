use Test::More tests => 2;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

# make sure the module works
profile_code(<<'END', "profile basic code");
sub bar { 1; }
sub goto_bar { goto &bar; }
goto_bar();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::goto_bar
main::bar
END
