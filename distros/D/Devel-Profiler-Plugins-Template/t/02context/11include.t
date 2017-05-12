use Test::More tests => 4;

use Devel::Profiler::Test qw(profile_code check_count
                             write_module cleanup_module);

write_module("IncludeOne", <<'END');
package IncludeOne;
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
END

profile_code(<<'END', "single call to INCLUDE");
use lib File::Spec->tmpdir();
use Devel::Profiler::Plugins::Template;
use IncludeOne;
IncludeOne::run();
END

check_count('1 TT::INCLUDE::iterate_test',
            '1 call to [% INCLUDE iterate_test %] found',
            'TT::INCLUDE::iterate_test');

cleanup_module("IncludeOne");

write_module("IncludeMany", <<'END');
package IncludeMany;
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
[% INCLUDE iterate_test %]
[% INCLUDE iterate_test %]
END

profile_code(<<'END', "multiple calls to INCLUDE");
use lib File::Spec->tmpdir();
use Devel::Profiler::Plugins::Template;
use IncludeMany;
IncludeMany::run();
END

check_count('3 TT::INCLUDE::iterate_test',
            '3 calls to [% INCLUDE iterate_test %] found',
            'TT::INCLUDE::iterate_test');

cleanup_module("IncludeMany");
