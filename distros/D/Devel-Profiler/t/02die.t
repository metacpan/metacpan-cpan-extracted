use Test::More tests => 2;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

# make sure the module works
profile_code(<<'END', "profile basic code");
sub baz { die "ok"; }
sub bar { baz(); }
sub foo { eval { bar(); }; die unless $@ =~ /^ok/; }
foo();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::foo
   main::bar
      main::baz
END
