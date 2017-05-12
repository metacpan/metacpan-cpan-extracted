use Test::More tests => 8;
use Devel::Profiler::Test qw(profile_code check_tree get_times 
                             write_module cleanup_module);

# setup module file for test below
write_module("Exporting", <<'END');
package Exporting;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(exported);
sub exported { 1; }
1;
END

profile_code(<<'END', "Check that the profiler groks packages");
use Exporting;
exported();
END

check_tree(<<'END', "Check tree for package usage");
Exporting::exported
END

my $setup = 'use Devel::Profiler package_filter => sub { 1 };';

profile_code(<<'END', "Check true package_filter", $setup);
use Exporting;
exported();
END

check_tree(<<'END', "Check tree for package usage");
Exporting::exported
END

$setup = 'use Devel::Profiler package_filter => sub { 0 };';

profile_code(<<'END', "Check false package_filter", $setup);
use Exporting;
exported();
END

check_tree("", "Check tree for package usage");


$setup = 'use Devel::Profiler package_filter => [ sub { 0 }, sub { 1 } ];';

profile_code(<<'END', "Check array of package filters", $setup);
use Exporting;
exported();
END

check_tree("", "Check tree for package usage");

cleanup_module("Exporting");
