use Test::More tests => 4;

use Devel::Profiler::Test qw(profile_code check_count
                             write_module cleanup_module);

write_module("ProcessOne", <<'END');
package ProcessOne;
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
[% PROCESS iterate_test %]
END

profile_code(<<'END', "single call to PROCESS");
use lib File::Spec->tmpdir();
use Devel::Profiler::Plugins::Template;
use ProcessOne;
ProcessOne::run();
END

check_count('1 TT::PROCESS::iterate_test',
            '1 call to [% PROCESS iterate_test %] found',
            'TT::PROCESS::iterate_test');

cleanup_module("ProcessOne");


write_module("ProcessMany", <<'END');
package ProcessMany;
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
[% PROCESS iterate_test %]
[% PROCESS iterate_test %]
[% PROCESS iterate_test %]
END

profile_code(<<'END', "multiple calls to PROCESS");
use lib File::Spec->tmpdir();
use Devel::Profiler::Plugins::Template;
use ProcessMany;
ProcessMany::run();
END

check_count('3 TT::PROCESS::iterate_test',
            '3 calls to [% PROCESS iterate_test %] found',
            'TT::PROCESS::iterate_test');

cleanup_module("ProcessMany");

__END__
write_module("TestOutput", <<'END');
package TestOutput;
use Template;
sub run {
  Template->new({POST_CHOMP => 1,
                 POST_CHOMP => 1,
                 TRIM       => 1,})->process(\*DATA,
                                             { story => [ qw(one hot summer in itching down
                                                            four million wasps flew into town)] },
                                             \*STDERR);
}
1;
__DATA__
[% BLOCK iterate_test %]
[% FOREACH word = story %]
[%- word -%]
[% END %]
[% END %]
#[% PROCESS iterate_test +%]
#[% PROCESS iterate_test +%]
#[% PROCESS iterate_test +%]
END

profile_code(<<'END', "make sure PROCESS output is actually produced");
use lib File::Spec->tmpdir();
use Devel::Profiler::Plugins::Template;
use TestOutput;
TestOutput::run();
END

check_count('3 TT::PROCESS::iterate_test',
            '3 calls to [% PROCESS iterate_test %] found',
            'TT::PROCESS::iterate_test');

#cleanup_module("ProcessMany");
