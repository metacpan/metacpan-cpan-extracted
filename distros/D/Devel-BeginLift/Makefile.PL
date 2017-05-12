use inc::Module::Install 0.67;

use ExtUtils::Depends;

name 'Devel-BeginLift';
all_from 'lib/Devel/BeginLift.pm';

requires 'B::Hooks::OP::Check::EntersubForCV' => '0.03';

build_requires 'Test::More';
build_requires 'B::Hooks::OP::Check::EntersubForCV';

configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check::EntersubForCV';

my $pkg = ExtUtils::Depends->new('Devel::Declare', 'B::Hooks::OP::Check::EntersubForCV');

WriteMakefile(
  dist => {
    PREOP => 'pod2text lib/Devel/BeginLift.pm >$(DISTVNAME)/README'
  },
  $pkg->get_makefile_vars,
);
