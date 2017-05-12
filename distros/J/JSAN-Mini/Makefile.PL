use inc::Module::Install::DSL 0.91;

all_from       lib/JSAN/Mini.pm
requires       JSAN::Client 0.21
test_requires  File::Spec   0.80
test_requires  Test::More   0.47
install_script minijsan
