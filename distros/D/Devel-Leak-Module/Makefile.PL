use inc::Module::Install::DSL 1.04;

name           Devel-Leak-Module
all_from       lib/Devel/Leak/Module.pm
test_requires  Test::More   0.47
test_requires  Test::Script 1.07
install_script perlbloat
