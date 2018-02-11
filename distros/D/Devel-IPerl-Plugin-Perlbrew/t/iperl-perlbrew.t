use strict;
use warnings;
BEGIN {
  $ENV{IPERL_PLUGIN_PERLBREW_DEBUG} = $ENV{TEST_VERBOSE};
  $ENV{IPERL_PLUGIN_PERLBREW_CLASS} = 'Test::App::perlbrew';
}
use Test::More;
use Devel::IPerl;
use IPerl;
use lib 't/lib';

my $iperl = new_ok('IPerl');

ok $iperl->load_plugin('Perlbrew');
my $domain = $ENV{PERLBREW_HOME} || '';

can_ok $iperl, qw{perlbrew perlbrew_domain perlbrew_lib_create perlbrew_list
                  perlbrew_list_modules};

is $iperl->perlbrew(), -1, 'no library for app::perlbrew';

my $save = $ENV{PERLBREW_ROOT};

is $iperl->perlbrew('random1'), 1, 'here';
is $iperl->perlbrew('random2'), 1, 'here';
is $iperl->perlbrew('random2'), 0, 'here';

is $ENV{PERLBREW_ROOT}, $save, 'no change';
is $ENV{PERLBREW_HOME}, '/tmp', 'set';

is $iperl->perlbrew_domain, $domain, 'domain from register';
is $iperl->perlbrew_domain('/tmp'), '/tmp', 'domain set';

my @added = grep { m{^\Q$Test::App::perlbrew::PERL5LIB\E$} } @INC;
is @added, 1, "contains path '$Test::App::perlbrew::PERL5LIB'";

my $plugin = new_ok('Devel::IPerl::Plugin::Perlbrew');
is $plugin->name, undef, 'empty default';
is $plugin->name('perl-5.26.0@random'), $plugin, 'chaining';
is $plugin->name, 'perl-5.26.0@random', 'set';
is $plugin->unload, undef, 'empty';
is $plugin->unload(1), $plugin, 'chaining';
is $plugin->unload, 1, 'set';
is $plugin->unload(0)->unload, 0, 'unset';

my $env_set = {
  PERLBREW_TEST_VAR => 1,
  TEST_THIS => 1,
  PERLBREW_TEST_MODE => 'develop',
};
is $plugin->env($env_set), $plugin, 'chaining';
is_deeply $plugin->env, $env_set, 'set';
is $ENV{PERLBREW_TEST_VAR}, undef, 'not set';
is $ENV{PERLBREW_TEST_MODE}, undef, 'not set';
is $ENV{TEST_THIS}, undef, 'not set';

{
  diag "Brew 1" if $ENV{IPERL_PLUGIN_PERLBREW_DEBUG};
  local %ENV = %ENV;
  $ENV{PERLBREW_TEST_MODE} = 'production';
  $plugin->brew;
  is $ENV{PERLBREW_TEST_VAR}, 1, 'now set';
  is $ENV{PERLBREW_TEST_MODE}, 'develop', 'mode now set';
  is $ENV{TEST_THIS}, undef, 'not set';
  $plugin->spoil;
  is $ENV{PERLBREW_TEST_VAR}, undef, 'not set';
  is $ENV{PERLBREW_TEST_MODE}, 'production', 'mode reverted';
}

{
  diag "Brew 2" if $ENV{IPERL_PLUGIN_PERLBREW_DEBUG};
  local %ENV = %ENV;
  $plugin->env($env_set);
  $ENV{PERLBREW_TEST_MODE} = 'production';
  $plugin->brew;
  is $ENV{PERLBREW_TEST_VAR}, 1, 'now set';
  is $ENV{PERLBREW_TEST_MODE}, 'develop', 'mode now set';
  is $ENV{TEST_THIS}, undef, 'not set';
  undef $plugin; # this should also call spoil.
  is $ENV{PERLBREW_TEST_VAR}, undef, 'not set';
  is $ENV{PERLBREW_TEST_MODE}, 'production', 'mode reverted';
}
# constructor tests
$plugin = new_ok('Devel::IPerl::Plugin::Perlbrew', [name => 'foobar']);
$plugin->new(name => 'foo')->new({name => 'bar'})->brew;

# _make_name tests check various constraints
(my $current_perl = $^X) =~ s{.*/perls/([^/]+)/bin/perl}{$1};
is $plugin->_make_name('foo'), join('@', $ENV{PERLBREW_PERL}, 'foo'),
  'make name';
is $plugin->_make_name($ENV{PERLBREW_PERL}), $ENV{PERLBREW_PERL},
  'current perl';

{
  local $ENV{PERLBREW_PERL} = 'perl-5.24.3';
  is $plugin->_make_name('bar'), 'perl-5.24.3@bar', 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), 'perl-5.24.3@bar', 'make name';
  delete $ENV{PERLBREW_PERL};
  ## default to directory
  (local $^X = $^X) =~ s{perls/([^/]+)/bin}{perls/perl-alias/bin};
  is $plugin->_make_name('bar'), 'perl-alias@bar', 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), 'perl-alias@bar', 'make name';
  is $plugin->_make_name('perl-alias'), 'perl-alias',
    'non-numeric "current" perl';
  ## default to perl version
  $^X =~ s{perls/([^/]+)/bin}{p/perl-alias/bin};
  (my $version = $^V->normal) =~ s{^v}{perl-};
  is $plugin->_make_name('bar'), join('@', $version, 'bar'), 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), join('@', $version, 'bar'),
    'make name';
}

is $iperl->perlbrew_lib_create(), -1, 'no lib in lib_create';
is $iperl->perlbrew_lib_create('special'), 1, 'lib_create';
is $iperl->perlbrew_lib_create('test-library'), 0,
  'lib_create dies in App::perlbrew';

is $iperl->perlbrew_list, 0, 'list';

is $iperl->perlbrew_list_modules, 1, 'list_modules';

#
# test the unloading feature.
#
is $iperl->perlbrew('random1', 1), 1, 'here';
@added = grep { m{^\Q$Test::App::perlbrew::PERL5LIB\E$} } @INC;
is @added, 1, "contains path '$Test::App::perlbrew::PERL5LIB'";

eval "use ACME::NotThere; 1;";
is $@, '', 'no errors';

is $iperl->perlbrew('random2', 1), 1, 'here';

is $INC{'ACME/NotThere.pm'}, undef, 'not in %INC';
eval "ACME::NotThere->heres_johnny;";
like $@, qr/heres_johnny/, 'nope';


done_testing;
