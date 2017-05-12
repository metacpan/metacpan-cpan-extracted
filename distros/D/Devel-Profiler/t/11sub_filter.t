use Test::More tests => 6;
use Devel::Profiler::Test qw(profile_code check_tree get_times 
                             write_module cleanup_module);

my $setup = 'use Devel::Profiler sub_filter => sub { 1 };';

profile_code(<<'END', "Check true sub_filter", $setup);
package Foo;
sub foo { 1; }
foo();
END

check_tree(<<'END', "Check tree for package usage");
Foo::foo
END

$setup = 'use Devel::Profiler sub_filter => sub { 0 };';

profile_code(<<'END', "Check false sub_filter", $setup);
package Foo;
sub foo { 1; }
foo();
END

check_tree('', "Check tree for package usage");


$setup = 'use Devel::Profiler sub_filter => sub { $_[1] =~ /baz/ ? 0 : 1 };';

profile_code(<<'END', "Check sub_filter", $setup);
package Foo;
sub foo { bar(); baz(); }
sub bar { 1; }
sub baz { 1; }
foo();
END

check_tree(<<'END', "Check tree for package usage");
Foo::foo
   Foo::bar
END
