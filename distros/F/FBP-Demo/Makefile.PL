use inc::Module::Install::DSL 1.04;

all_from       lib/FBP/Demo.pm
requires_from  lib/FBP/Demo.pm
test_requires  Test::More       0.47
test_requires  Test::Script     1.07
test_requires  Test::NoWarnings 1.00
install_script script/fbpdemo
