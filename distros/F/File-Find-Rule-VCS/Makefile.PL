use inc::Module::Install::DSL 1.00;

all_from      lib/File/Find/Rule/VCS.pm
requires_from lib/File/Find/Rule/VCS.pm
test_requires File::Spec 0.82
test_requires Test::More 0.47
