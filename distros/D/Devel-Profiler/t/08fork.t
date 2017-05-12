use Test::More tests => 2;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

profile_code(<<'END', "make sure only the parent gets profiled");
sub foo { bar(); }
sub bar { 1; }
sub baz { bif(); }
sub bif { 1; }
foo();
unless (fork()) {
    baz();
    exit;
} else {
    foo();
}
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::foo
   main::bar
main::foo
   main::bar
END
