use Test::More tests => 3;

use Devel::Profiler::Test qw(profile_code check_count
                             write_module cleanup_module);

write_module("ProcessInclude", <<'END');
package ProcessInclude;
use Template;
sub run {
  Template->new({POST_CHOMP => 1,
                 POST_CHOMP => 1,
                 TRIM       => 1,})->process(\*DATA, { foo => 'bar' });
}
1;
__DATA__
[% BLOCK iterate_test %]
  [% FOREACH item = foo %]
  [% END %]
[% END %]
[% INCLUDE iterate_test %]
[% PROCESS iterate_test %]
[% INCLUDE iterate_test %]
[% PROCESS iterate_test %]
[% PROCESS iterate_test %]
[% PROCESS iterate_test %]
[% INCLUDE iterate_test %]
[% PROCESS iterate_test %]
END

profile_code(<<'END', "mixed calls to PROCESS and INCLUDE");
use lib File::Spec->tmpdir();
use Devel::Profiler::Plugins::Template;
use ProcessInclude;
ProcessInclude::run();
END

check_count('3 TT::INCLUDE::iterate_test',
            '3 calls to [% INCLUDE iterate_test %] found',
            'TT::INCLUDE::iterate_test');

check_count('5 TT::PROCESS::iterate_test',
            '5 calls to [% PROCESS iterate_test %] found',
            'TT::PROCESS::iterate_test');

cleanup_module("ProcessInclude");
